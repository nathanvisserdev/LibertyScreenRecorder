//
//  TimestampVerificationService.swift
//  ScreenRecorder
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation
import Network

actor TimestampVerificationService {
    
    // Public NTP servers for time verification
    private let ntpServers = [
        "time.apple.com",
        "time.google.com",
        "time.nist.gov",
        "pool.ntp.org"
    ]
    
    // RFC 3161 Timestamp Authority (free service for testing)
    private let timestampAuthorities = [
        "http://timestamp.digicert.com",
        "http://timestamp.apple.com/ts01",
        "http://timestamp.sectigo.com"
    ]
    
    /// Get verified time from NTP server
    func getVerifiedTimestamp() async throws -> (timestamp: Date, server: String) {
        // Try each NTP server until one succeeds
        for server in ntpServers {
            if let timestamp = try? await queryNTPServer(server) {
                return (timestamp, server)
            }
        }
        
        throw TimestampError.allServersUnavailable
    }
    
    private func queryNTPServer(_ server: String) async throws -> Date {
        // NTP protocol implementation (simplified)
        // In production, consider using a library like TrueTime or ios-ntp
        
        let host = NWEndpoint.Host(server)
        let port = NWEndpoint.Port(integerLiteral: 123) // NTP port
        
        let connection = NWConnection(host: host, port: port, using: .udp)
        
        return try await withCheckedThrowingContinuation { continuation in
            var resumed = false
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    // Send NTP request
                    var request = Data(count: 48)
                    request[0] = 0x1B // NTP client mode, version 3
                    
                    connection.send(content: request, completion: .contentProcessed { error in
                        if let error = error {
                            if !resumed {
                                resumed = true
                                continuation.resume(throwing: error)
                            }
                            return
                        }
                    })
                    
                    // Receive NTP response
                    connection.receive(minimumIncompleteLength: 48, maximumLength: 48) { data, _, _, error in
                        if !resumed {
                            resumed = true
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else if let data = data, data.count >= 48 {
                                // Parse NTP timestamp (bytes 40-43)
                                let seconds = data.withUnsafeBytes { buffer in
                                    buffer.load(fromByteOffset: 40, as: UInt32.self).bigEndian
                                }
                                
                                // NTP epoch is Jan 1, 1900; Unix epoch is Jan 1, 1970
                                let ntpEpochOffset: TimeInterval = 2208988800
                                let timestamp = Date(timeIntervalSince1970: Double(seconds) - ntpEpochOffset)
                                
                                continuation.resume(returning: timestamp)
                            } else {
                                continuation.resume(throwing: TimestampError.invalidResponse)
                            }
                        }
                        connection.cancel()
                    }
                    
                case .failed(let error):
                    if !resumed {
                        resumed = true
                        continuation.resume(throwing: error)
                    }
                    
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
            
            // Timeout after 5 seconds
            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                if !resumed {
                    resumed = true
                    connection.cancel()
                    continuation.resume(throwing: TimestampError.timeout)
                }
            }
        }
    }
    
    /// Request RFC 3161 timestamp token from a Timestamp Authority
    func requestTimestampToken(for hash: String) async throws -> (url: String, response: Data) {
        // Try each timestamp authority
        for tsaURL in timestampAuthorities {
            if let response = try? await requestToken(from: tsaURL, hash: hash) {
                return (tsaURL, response)
            }
        }
        
        throw TimestampError.noTimestampAuthority
    }
    
    private func requestToken(from urlString: String, hash: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw TimestampError.invalidURL
        }
        
        // Create timestamp request (simplified - in production use proper RFC 3161 encoding)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/timestamp-query", forHTTPHeaderField: "Content-Type")
        
        // Create basic timestamp request with hash
        let requestBody = Data(hash.utf8)
        request.httpBody = requestBody
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TimestampError.requestFailed
        }
        
        return data
    }
    
    /// Create a comprehensive timestamp proof document
    func createTimestampProof(
        fileHash: String,
        creationTime: Date,
        ntpTime: Date,
        ntpServer: String,
        tsaURL: String?,
        tsaResponse: Data?
    ) -> [String: Any] {
        var proof: [String: Any] = [
            "file_hash": fileHash,
            "device_time": ISO8601DateFormatter().string(from: creationTime),
            "ntp_time": ISO8601DateFormatter().string(from: ntpTime),
            "ntp_server": ntpServer,
            "time_difference_seconds": ntpTime.timeIntervalSince(creationTime)
        ]
        
        if let tsaURL = tsaURL {
            proof["timestamp_authority"] = tsaURL
        }
        
        if let tsaResponse = tsaResponse {
            proof["tsa_response_size"] = tsaResponse.count
            proof["tsa_response_sha256"] = SHA256.hash(data: tsaResponse).compactMap {
                String(format: "%02x", $0)
            }.joined()
        }
        
        return proof
    }
}

enum TimestampError: LocalizedError {
    case timeout
    case invalidResponse
    case allServersUnavailable
    case noTimestampAuthority
    case invalidURL
    case requestFailed
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "NTP server request timed out"
        case .invalidResponse:
            return "Invalid response from NTP server"
        case .allServersUnavailable:
            return "All NTP servers are unavailable"
        case .noTimestampAuthority:
            return "No timestamp authority available"
        case .invalidURL:
            return "Invalid timestamp authority URL"
        case .requestFailed:
            return "Timestamp authority request failed"
        }
    }
}

// Import CryptoKit for SHA256 in timestamp proof
import CryptoKit
