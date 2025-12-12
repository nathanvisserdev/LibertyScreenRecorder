//
//  CryptographicHashService.swift
//  ScreenRecorder
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation
import CryptoKit

actor CryptographicHashService {
    
    /// Generates SHA-256 and SHA-512 hashes for a file
    func generateHashes(for fileURL: URL) async throws -> (sha256: String, sha512: String) {
        let fileData = try Data(contentsOf: fileURL)
        
        let sha256 = SHA256.hash(data: fileData)
        let sha512 = SHA512.hash(data: fileData)
        
        let sha256String = sha256.compactMap { String(format: "%02x", $0) }.joined()
        let sha512String = sha512.compactMap { String(format: "%02x", $0) }.joined()
        
        return (sha256String, sha512String)
    }
    
    /// Verifies a file against its stored hash
    func verifyFileIntegrity(fileURL: URL, expectedSHA256: String) async throws -> Bool {
        let fileData = try Data(contentsOf: fileURL)
        let sha256 = SHA256.hash(data: fileData)
        let sha256String = sha256.compactMap { String(format: "%02x", $0) }.joined()
        
        return sha256String == expectedSHA256
    }
    
    /// Creates a forensic manifest file with all hashes and metadata
    func createForensicManifest(
        fileURL: URL,
        sha256: String,
        sha512: String,
        metadata: [String: Any]
    ) async throws -> URL {
        let manifestURL = fileURL.deletingPathExtension().appendingPathExtension("manifest.json")
        
        var manifestData: [String: Any] = [
            "filename": fileURL.lastPathComponent,
            "sha256": sha256,
            "sha512": sha512,
            "created_at": ISO8601DateFormatter().string(from: Date()),
            "file_size": try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 ?? 0
        ]
        
        manifestData.merge(metadata) { (_, new) in new }
        
        let jsonData = try JSONSerialization.data(withJSONObject: manifestData, options: [.prettyPrinted, .sortedKeys])
        try jsonData.write(to: manifestURL)
        
        return manifestURL
    }
    
    /// Generates a hash of the hash + timestamp for additional verification
    func generateProofOfExistence(sha256Hash: String, timestamp: Date) -> String {
        let combined = "\(sha256Hash)|\(timestamp.timeIntervalSince1970)"
        let hash = SHA256.hash(data: Data(combined.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
