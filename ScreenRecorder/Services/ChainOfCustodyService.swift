//
//  ChainOfCustodyService.swift
//  ScreenRecorder
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation
import CryptoKit

actor ChainOfCustodyService {
    
    private var eventLog: [URL: [CustodyEvent]] = [:]
    
    /// Log a custody event for a file
    func logEvent(action: String, details: String, fileURL: URL, userIdentifier: String? = nil) {
        let event = CustodyEvent(
            timestamp: Date(),
            action: action,
            details: details,
            userIdentifier: userIdentifier ?? getCurrentUser()
        )
        
        if eventLog[fileURL] == nil {
            eventLog[fileURL] = []
        }
        
        eventLog[fileURL]?.append(event)
        
        // Persist to disk
        Task {
            await persistLog(for: fileURL)
        }
    }
    
    /// Get all custody events for a file
    func getEvents(for fileURL: URL) -> [CustodyEvent] {
        return eventLog[fileURL] ?? []
    }
    
    /// Export chain of custody log as JSON
    func exportLog(for fileURL: URL) async throws -> URL {
        let events = eventLog[fileURL] ?? []
        
        let logData: [String: Any] = [
            "file_url": fileURL.path,
            "file_name": fileURL.lastPathComponent,
            "total_events": events.count,
            "events": events.map { event in
                [
                    "timestamp": ISO8601DateFormatter().string(from: event.timestamp),
                    "action": event.action,
                    "details": event.details,
                    "user": event.userIdentifier ?? "Unknown"
                ]
            }
        ]
        
        let jsonData = try JSONSerialization.data(
            withJSONObject: logData,
            options: [.prettyPrinted, .sortedKeys]
        )
        
        let logURL = fileURL
            .deletingPathExtension()
            .appendingPathExtension("custody_log.json")
        
        try jsonData.write(to: logURL)
        
        return logURL
    }
    
    /// Verify chain of custody integrity
    func verifyChainIntegrity(for fileURL: URL) async throws -> ChainVerificationResult {
        let events = eventLog[fileURL] ?? []
        
        guard !events.isEmpty else {
            return ChainVerificationResult(
                isValid: false,
                issues: ["No custody events found"],
                eventCount: 0
            )
        }
        
        var issues: [String] = []
        
        // Check chronological order
        for i in 1..<events.count {
            if events[i].timestamp < events[i-1].timestamp {
                issues.append("Events not in chronological order at index \(i)")
            }
        }
        
        // Check for required events
        let actions = events.map { $0.action }
        
        if !actions.contains("RECORDING_START") {
            issues.append("Missing RECORDING_START event")
        }
        
        if !actions.contains("RECORDING_COMPLETE") {
            issues.append("Missing RECORDING_COMPLETE event")
        }
        
        if !actions.contains("HASH_GENERATION_COMPLETE") {
            issues.append("Missing HASH_GENERATION_COMPLETE event")
        }
        
        // Check time gaps (suspicious if > 1 hour between events)
        for i in 1..<events.count {
            let gap = events[i].timestamp.timeIntervalSince(events[i-1].timestamp)
            if gap > 3600 {
                issues.append("Suspicious time gap of \(Int(gap/60)) minutes between events \(i-1) and \(i)")
            }
        }
        
        return ChainVerificationResult(
            isValid: issues.isEmpty,
            issues: issues,
            eventCount: events.count
        )
    }
    
    /// Create a digital signature of the custody log
    func signCustodyLog(for fileURL: URL, privateKey: P256.Signing.PrivateKey) async throws -> String {
        let events = eventLog[fileURL] ?? []
        
        let logString = events.map { event in
            "\(event.timestamp.timeIntervalSince1970)|\(event.action)|\(event.details)"
        }.joined(separator: "\n")
        
        let data = Data(logString.utf8)
        let signature = try privateKey.signature(for: data)
        
        return signature.rawRepresentation.base64EncodedString()
    }
    
    // MARK: - Private Methods
    
    private func persistLog(for fileURL: URL) async {
        do {
            _ = try await exportLog(for: fileURL)
        } catch {
            print("Failed to persist custody log: \(error)")
        }
    }
    
    private func getCurrentUser() -> String {
        #if os(macOS)
        return NSUserName()
        #else
        return UIDevice.current.name
        #endif
    }
    
    /// Load custody log from disk
    func loadLog(for fileURL: URL) async throws {
        let logURL = fileURL
            .deletingPathExtension()
            .appendingPathExtension("custody_log.json")
        
        guard FileManager.default.fileExists(atPath: logURL.path) else {
            return
        }
        
        let data = try Data(contentsOf: logURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let eventsArray = json?["events"] as? [[String: Any]] else {
            return
        }
        
        var events: [CustodyEvent] = []
        let formatter = ISO8601DateFormatter()
        
        for eventDict in eventsArray {
            guard let timestampString = eventDict["timestamp"] as? String,
                  let timestamp = formatter.date(from: timestampString),
                  let action = eventDict["action"] as? String,
                  let details = eventDict["details"] as? String else {
                continue
            }
            
            let user = eventDict["user"] as? String
            
            let event = CustodyEvent(
                timestamp: timestamp,
                action: action,
                details: details,
                userIdentifier: user
            )
            
            events.append(event)
        }
        
        eventLog[fileURL] = events
    }
}

struct ChainVerificationResult {
    let isValid: Bool
    let issues: [String]
    let eventCount: Int
    
    var summary: String {
        if isValid {
            return "✓ Chain of custody verified (\(eventCount) events)"
        } else {
            return "⚠ Chain of custody issues found:\n" + issues.joined(separator: "\n")
        }
    }
}
