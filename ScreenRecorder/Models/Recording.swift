//
//  Recording.swift
//  ScreenRecorder
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation
import SwiftData

@Model
final class Recording {
    var id: UUID
    var createdAt: Date
    var filename: String
    var fileURL: URL
    var duration: TimeInterval
    var fileSize: Int64
    
    // Forensic verification data
    var sha256Hash: String
    var sha512Hash: String
    var timestampVerificationURL: String?
    var timestampResponse: Data?
    var ntpTimestamp: Date?
    var ntpServer: String?
    
    // Chain of custody
    var chainOfCustodyLog: [CustodyEvent]
    var isOriginalFile: Bool
    var originalFileHash: String?
    
    // Metadata
    var deviceModel: String
    var osVersion: String
    var appVersion: String
    var screenResolution: String
    
    init(
        id: UUID = UUID(),
        createdAt: Date,
        filename: String,
        fileURL: URL,
        duration: TimeInterval = 0,
        fileSize: Int64 = 0,
        sha256Hash: String = "",
        sha512Hash: String = "",
        timestampVerificationURL: String? = nil,
        timestampResponse: Data? = nil,
        ntpTimestamp: Date? = nil,
        ntpServer: String? = nil,
        chainOfCustodyLog: [CustodyEvent] = [],
        isOriginalFile: Bool = true,
        originalFileHash: String? = nil,
        deviceModel: String = "",
        osVersion: String = "",
        appVersion: String = "",
        screenResolution: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.filename = filename
        self.fileURL = fileURL
        self.duration = duration
        self.fileSize = fileSize
        self.sha256Hash = sha256Hash
        self.sha512Hash = sha512Hash
        self.timestampVerificationURL = timestampVerificationURL
        self.timestampResponse = timestampResponse
        self.ntpTimestamp = ntpTimestamp
        self.ntpServer = ntpServer
        self.chainOfCustodyLog = chainOfCustodyLog
        self.isOriginalFile = isOriginalFile
        self.originalFileHash = originalFileHash
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.screenResolution = screenResolution
    }
}

struct CustodyEvent: Codable, Hashable {
    var timestamp: Date
    var action: String
    var details: String
    var userIdentifier: String?
    
    init(timestamp: Date = Date(), action: String, details: String, userIdentifier: String? = nil) {
        self.timestamp = timestamp
        self.action = action
        self.details = details
        self.userIdentifier = userIdentifier
    }
}
