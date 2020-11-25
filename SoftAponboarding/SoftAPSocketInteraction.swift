//
// SoftAPSocketInteraction.swift
// Created on 9/9/20
//
// Copyright (c) 2020, Arlo Technologies, Inc.
// All rights reserved.
//
//
// This software is the confidential and proprietary information of
// Arlo Technologies, Inc. ("Confidential Information"). You shall not
// disclose such Confidential Information and shall use it only in
// accordance with the terms of the license agreement you entered into
// with Arlo.
//
// @author Jorge Ferrini
//
// 

import Foundation
import RxSwift

class InputStreamTest: InputStream {
    let id: String = "hhhhhhhh"
}

class OutputStreamTest: OutputStream {
    let id: String = "jksjsksk"
}

typealias StreamStatus = BehaviorSubject<ArloDeviceConnection.StreamStatus>

final class SoftAPSocketInteraction: NSObject {
    
    private let encryptor: Encryptor?
    private let events = PublishSubject<SoftApSocketEvent>()
    
    private var inputStream: InputStream?
    private var inputStreamStatus: StreamStatus?
    private var outputStream: OutputStream?
    private var outputStreamStatus: StreamStatus?
    
    private let maxMessageLength = 4096 // Subject to changes.
    private let disposeBag = DisposeBag()
    private let socket: SoftAPSocket
    
    init(with socket: SoftAPSocket, using encryptor: Encryptor) {
        self.socket = socket
        self.encryptor = encryptor
    }
}

private extension SoftAPSocketInteraction {
    enum Intervals {
        static let throttle: RxTimeInterval = .milliseconds(500)
        static let timeout: RxTimeInterval  = .seconds(5)
    }
    enum LogTags {
        static let common        = "SoftAPSocketConnection"
        static let encodingError = "Stream encoding error"
        static let decodingError = "Stream decoding error"
        static let streamError   = "Stream Error"
        static let streamMessage = "Stream Message"
    }
}

extension SoftAPSocketInteraction: DeviceConnectionInteraction {
    var eventsStream: Observable<SoftApSocketEvent> {
        return events.asObservable().observeOn(MainScheduler.instance)
    }

    func connect() -> Observable<ArloDeviceConnection.StreamStatus>? {
        guard inputStream == nil, outputStream == nil else {
            print("Socket connected already, multiple connections not allowed within this class")
            return nil
        }
        
        inputStreamStatus = StreamStatus(value: .uninitialized)
        outputStreamStatus = StreamStatus(value: .uninitialized)
        
        open(forSocket: socket)
        
        guard let inputStatus = inputStreamStatus,
            let outputStatus = outputStreamStatus,
            let timeoutSequence = connectionTimeout(for: inputStatus, and: outputStatus) else {
            print("Can't initialize the in/output stream status")
            return nil
        }
        
        timeoutSequence
            .filter { $0 == .timeout }
            .take(1)
            .subscribe(onNext: {[weak self] _ in
                self?.prepareForReconnection()
                print("Sequence timeout reconnection needed")
            }).disposed(by: disposeBag)
        
        return Observable
            .of(inputStatus, outputStatus, timeoutSequence)
            .merge()
            .debounce(Intervals.throttle, scheduler: MainScheduler.instance)
    }
    
    func disconnect() {
        close()
    }

    func execute(command: ConnectionCommand) {
        guard (try? inputStreamStatus?.value() ?? .closed) == .open else {
            print("\(LogTags.encodingError) can't send message output stream is not open")
            return
        }
        
        let executableCommand = command.executable
        //encryptOutgoing(command: &executableCommand) // Not ready on FW yet.
        
        let rawMessage = executableCommand.description
        let composedMessage = "L:\(rawMessage.count) \(rawMessage)"
        secureLog(message: composedMessage, forType: command)
        
        let encodedDataArray = [UInt8]("\(composedMessage)\n".utf8)
        outputStream?.write(encodedDataArray, maxLength: encodedDataArray.count)
    }
    
    /// Execute command and wait for response from device
    /// - Parameter command: Type of command that has to be executed to the device
    /// - Returns: Single RxSwift Sequence that will return the response from the device when command is executed
    func executeAndReturnResponse(command: ConnectionCommand) -> Single<SoftApSocketEvent> {
        return Single<SoftApSocketEvent>.create { [weak self] single in
            guard let sself = self else {
                single(.error(DeviceInteractionError.instanceDestroyed))
                return Disposables.create()
            }
            sself.outputStreamStatus?
                .subscribe(onNext: { status in
                    guard status == .open else {
                        single(.error(DeviceInteractionError.notOpenConnection))
                        return
                    }
                    sself.eventsStream.monitorMessage(by: command)
                        .bindCommandResult(into: single)
                        .disposed(by: sself.disposeBag)
                    sself.execute(command: command)
                }, onError: { error in
                    single(.error(error))
                }).disposed(by: sself.disposeBag)
            return Disposables.create()
        }
    }
    
    func encryptOutgoing(command: inout ExecutableCommand) {
        guard let encryptor = encryptor else {
            return
        }
        try? command.encrypt(using: encryptor)
    }
    
    func connectionTimeout(for inputStatus: StreamStatus,
                           and outputStatus: StreamStatus) -> Observable<ArloDeviceConnection.StreamStatus>? {
        return Observable
            .of(inputStatus, outputStatus)
            .merge()
            .takeUntil(.inclusive, predicate: { $0 == .open })
            .timeout(Intervals.timeout, scheduler: MainScheduler.instance)
            .catchErrorJustReturn(.timeout)
    }
}

extension SoftAPSocketInteraction: SocketInteraction {
    func open(forSocket socket: SoftAPSocket) {
        print("Opening connection")
        
        Stream.getStreamsToHost(withName: socket.host,
                                port: socket.port,
                                inputStream: &inputStream,
                                outputStream: &outputStream)
        
        guard inputStream != nil, outputStream != nil else {
            print("Cant open inputStream:\(inputStream == nil) outputStream:\(outputStream == nil)")
            return
        }
        
        inputStream?.delegate = self
        outputStream?.delegate = self
        
        inputStream?.schedule(in: .main, forMode: .default)
        outputStream?.schedule(in: .main, forMode: .default)
        
        inputStream?.open()
        outputStream?.open()
    }
    
    func close(wasErrorOcurred: Bool = false) {
        print("Closing socket and shutdown streams")
        
        prepareForReconnection()
        
        inputStreamStatus?.onNext(wasErrorOcurred ? .disconnected : .closed)
        outputStreamStatus?.onNext(wasErrorOcurred ? .disconnected : .closed)
    }
}

extension SoftAPSocketInteraction: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        print("Stream event \(eventCode)")
        
        switch eventCode {
        case .openCompleted where aStream === inputStream:
            inputStreamStatus?.onNext(.open)
        case .openCompleted where aStream === outputStream:
            outputStreamStatus?.onNext(.open)
        case .hasBytesAvailable where aStream === inputStream:
            print("Stream has bytes available")
            guard let inputStream = inputStream else {
                return
            }
            readAvailableBytes(from: inputStream)
        case .hasSpaceAvailable:
            print("Stream has space available")
            print("log here")
        case .errorOccurred:
            guard let error = aStream.streamError as NSError? else {
                print("\(LogTags.streamError): no description provided")
                return
            }
            if aStream === inputStream {
                inputStreamStatus?.onError(error)
            }
            if aStream === outputStream {
                outputStreamStatus?.onError(error)
            }
            print("\(LogTags.streamError): \(error.localizedDescription)")
            close(wasErrorOcurred: true)
        case .endEncountered:
            print("End encountered wasInputStream? \(aStream === inputStream) otherwhise was output")
            close(wasErrorOcurred: true)
        default:
            print("Unknown event rawValue = \(eventCode)")
        }
    }
}

private extension SoftAPSocketInteraction {
    func secureLog(message: String, forType type: ConnectionCommand) {
//        if HMSAppSettings.isQAMode() {
//            Log.debug("\(LogTags.streamMessage): \(message)")
//        } else {
//            Log.debug("Secure Log message of type: \(type) has been sent")
//        }
    }
    
    func prepareForReconnection() {
        inputStream?.close()
        outputStream?.close()
        inputStream?.remove(from: .main, forMode: .default)
        outputStream?.remove(from: .main, forMode: .default)
        inputStream = nil
        outputStream = nil
    }
    
    ///https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/NetworkingTopics/Articles/UsingSocketsandSocketStreams.html#//apple_ref/doc/uid/CH73-SW4
    func readAvailableBytes(from stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxMessageLength)
        while stream.hasBytesAvailable {
            let readBytes = inputStream?.read(buffer, maxLength: maxMessageLength)
            if (readBytes ?? 0) < 0, let error = stream.streamError {
                print("\(LogTags.streamError): \(error.localizedDescription)")
                close(wasErrorOcurred: true)
            }
            // Broadcast message to all subscribers
            if let lenght = readBytes, let message = SoftApMessageComposer.composeIncomingMessage(from: buffer, lenght: lenght) {
                events.onNext(message)
            }
        }
    }
}
