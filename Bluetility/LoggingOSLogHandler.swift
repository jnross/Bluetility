//
//  LoggingOSLogHandler.swift
//  Bluetility
//
//  Created by Joseph Ross on 2/18/23.
//  Copyright © 2023 Joseph Ross. All rights reserved.
//

import Foundation
import Logging
import struct Logging.Logger
import os

public struct LoggingOSLogHandler: LogHandler {
    public var logLevel: Logger.Level = .info
    public let label: String
    private let oslogger: OSLog
    
    public init(label: String) {
        self.label = label
        self.oslogger = OSLog(subsystem: label, category: "")
    }

    public init(label: String, log: OSLog) {
        self.label = label
        self.oslogger = log
    }
    
    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
        var combinedPrettyMetadata = self.prettyMetadata
        if let metadataOverride = metadata, !metadataOverride.isEmpty {
            combinedPrettyMetadata = self.prettify(
                self.metadata.merging(metadataOverride) {
                    return $1
                }
            )
        }
        
        var formedMessage = message.description
        if combinedPrettyMetadata != nil {
            formedMessage += " -- " + combinedPrettyMetadata!
        }
        os_log("%{public}@", log: self.oslogger, type: OSLogType.from(loggerLevel: level), formedMessage as NSString)
    }
    
    private var prettyMetadata: String?
    public var metadata = Logger.Metadata() {
        didSet {
            self.prettyMetadata = self.prettify(self.metadata)
        }
    }
    
    /// Add, remove, or change the logging metadata.
    /// - parameters:
    ///    - metadataKey: the key for the metadata item.
    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }
    
    private func prettify(_ metadata: Logger.Metadata) -> String? {
        if metadata.isEmpty {
            return nil
        }
        return metadata.map {
            "\($0)=\($1)"
        }.joined(separator: " ")
    }
}

extension OSLogType {
    static func from(loggerLevel: Logger.Level) -> Self {
        switch loggerLevel {
        case .trace:
            /// `OSLog` doesn't have `trace`, so use `debug`
            return .debug
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            // https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code
            // According to the documentation, `default` is `notice`.
            return .default
        case .warning:
            /// `OSLog` doesn't have `warning`, so use `info`
            return .info
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
}
