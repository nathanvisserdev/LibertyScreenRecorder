//
//  RecordingDetailView.swift
//  ScreenRecorder
//
//  Created by Nathan Visser on 2025-12-11.
//

import SwiftUI
import AVKit

struct RecordingDetailView: View {
    let recording: Recording
    @Environment(\.dismiss) private var dismiss
    
    @State private var verificationResult: VerificationResult?
    @State private var isVerifying = false
    @State private var player: AVPlayer?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Video player
                    videoPlayer
                    
                    // Basic info
                    basicInfoSection
                    
                    // Forensic verification
                    forensicSection
                    
                    // Device metadata
                    metadataSection
                    
                    // Chain of custody
                    chainOfCustodySection
                    
                    // Actions
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Recording Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
    }
    
    private var videoPlayer: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .frame(height: 300)
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 300)
                    .overlay(
                        ProgressView()
                    )
            }
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader("Basic Information")
            
            InfoRow(label: "Filename", value: recording.filename)
            InfoRow(label: "Created", value: formatDate(recording.createdAt))
            InfoRow(label: "Duration", value: formatDuration(recording.duration))
            InfoRow(label: "File Size", value: formatFileSize(recording.fileSize))
            InfoRow(label: "Resolution", value: recording.screenResolution)
        }
    }
    
    private var forensicSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                sectionHeader("Forensic Verification")
                Spacer()
                if isVerifying {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button(action: verifyRecording) {
                        Label("Verify", systemImage: "checkmark.shield")
                            .font(.caption)
                    }
                }
            }
            
            // Verification status
            if let result = verificationResult {
                verificationStatusView(result)
            } else {
                Text("Click 'Verify' to check file integrity")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Hashes
            VStack(alignment: .leading, spacing: 10) {
                Text("SHA-256")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(recording.sha256Hash)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                
                Text("SHA-512")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(recording.sha512Hash)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            // Timestamp verification
            if let ntpTime = recording.ntpTimestamp,
               let ntpServer = recording.ntpServer {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(.green)
                        Text("Timestamp Verified")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text("NTP Server: \(ntpServer)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("NTP Time: \(formatDate(ntpTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            // TSA token
            if recording.timestampVerificationURL != nil {
                HStack {
                    Image(systemName: "seal.fill")
                        .foregroundColor(.blue)
                    Text("Timestamp Authority token received")
                        .font(.caption)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private func verificationStatusView(_ result: VerificationResult) -> some View {
        HStack {
            Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.isValid ? .green : .red)
            Text(result.message)
                .font(.subheadline)
        }
        .padding()
        .background((result.isValid ? Color.green : Color.red).opacity(0.1))
        .cornerRadius(8)
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader("Device Metadata")
            
            InfoRow(label: "Device Model", value: recording.deviceModel)
            InfoRow(label: "OS Version", value: recording.osVersion)
            InfoRow(label: "App Version", value: recording.appVersion)
            InfoRow(label: "Original File", value: recording.isOriginalFile ? "Yes" : "No")
        }
    }
    
    private var chainOfCustodySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader("Chain of Custody")
            
            if recording.chainOfCustodyLog.isEmpty {
                Text("No custody events recorded")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(recording.chainOfCustodyLog.enumerated()), id: \.offset) { index, event in
                        CustodyEventRow(event: event, isLast: index == recording.chainOfCustodyLog.count - 1)
                    }
                }
            }
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: exportForensicPackage) {
                Label("Export Forensic Package", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: shareRecording) {
                Label("Share Recording", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .fontWeight(.bold)
    }
    
    // MARK: - Actions
    
    private func setupPlayer() {
        player = AVPlayer(url: recording.fileURL)
    }
    
    private func verifyRecording() {
        isVerifying = true
        
        Task {
            let hashService = CryptographicHashService()
            
            do {
                let isValid = try await hashService.verifyFileIntegrity(
                    fileURL: recording.fileURL,
                    expectedSHA256: recording.sha256Hash
                )
                
                await MainActor.run {
                    verificationResult = VerificationResult(
                        isValid: isValid,
                        message: isValid ? "✓ File integrity verified - no tampering detected" : "⚠ File has been modified"
                    )
                    isVerifying = false
                }
            } catch {
                await MainActor.run {
                    verificationResult = VerificationResult(
                        isValid: false,
                        message: "✗ Verification failed: \(error.localizedDescription)"
                    )
                    isVerifying = false
                }
            }
        }
    }
    
    private func exportForensicPackage() {
        // Export all forensic files as a package
        Task {
            do {
                let hashService = CryptographicHashService()
                let custodyService = ChainOfCustodyService()
                
                // Create export directory
                let exportURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("ForensicExport_\(recording.id.uuidString)")
                
                try FileManager.default.createDirectory(at: exportURL, withIntermediateDirectories: true)
                
                // Copy video file
                let videoExportURL = exportURL.appendingPathComponent(recording.filename)
                try FileManager.default.copyItem(at: recording.fileURL, to: videoExportURL)
                
                // Copy manifest
                let manifestURL = recording.fileURL.deletingPathExtension().appendingPathExtension("manifest.json")
                if FileManager.default.fileExists(atPath: manifestURL.path) {
                    let manifestExportURL = exportURL.appendingPathComponent(manifestURL.lastPathComponent)
                    try FileManager.default.copyItem(at: manifestURL, to: manifestExportURL)
                }
                
                // Export custody log
                let custodyURL = try await custodyService.exportLog(for: recording.fileURL)
                let custodyExportURL = exportURL.appendingPathComponent(custodyURL.lastPathComponent)
                try FileManager.default.copyItem(at: custodyURL, to: custodyExportURL)
                
                // Create README
                let readme = createReadme()
                let readmeURL = exportURL.appendingPathComponent("README.txt")
                try readme.write(to: readmeURL, atomically: true, encoding: .utf8)
                
                // Open export folder
                #if os(macOS)
                NSWorkspace.shared.open(exportURL)
                #else
                // On iOS, use share sheet
                await MainActor.run {
                    let activityVC = UIActivityViewController(
                        activityItems: [exportURL],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootVC = window.rootViewController {
                        rootVC.present(activityVC, animated: true)
                    }
                }
                #endif
                
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
    
    private func shareRecording() {
        #if os(macOS)
        let picker = NSSharingServicePicker(items: [recording.fileURL])
        if let view = NSApp.keyWindow?.contentView {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
        #else
        let activityVC = UIActivityViewController(
            activityItems: [recording.fileURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
    
    private func createReadme() -> String {
        """
        FORENSIC SCREEN RECORDING PACKAGE
        ==================================
        
        Recording ID: \(recording.id.uuidString)
        Created: \(formatDate(recording.createdAt))
        Duration: \(formatDuration(recording.duration))
        
        FILES INCLUDED:
        - \(recording.filename) - Original video recording
        - \(recording.filename).manifest.json - Cryptographic manifest
        - \(recording.filename).custody_log.json - Chain of custody log
        - README.txt - This file
        
        VERIFICATION:
        
        SHA-256 Hash: \(recording.sha256Hash)
        SHA-512 Hash: \(recording.sha512Hash)
        
        To verify file integrity, calculate the SHA-256 hash of the video file
        and compare it to the hash above. Any difference indicates tampering.
        
        macOS/Linux: shasum -a 256 "\(recording.filename)"
        Windows: certutil -hashfile "\(recording.filename)" SHA256
        
        TIMESTAMP VERIFICATION:
        
        NTP Server: \(recording.ntpServer ?? "N/A")
        NTP Timestamp: \(recording.ntpTimestamp.map(formatDate) ?? "N/A")
        Device Time: \(formatDate(recording.createdAt))
        
        DEVICE INFORMATION:
        
        Model: \(recording.deviceModel)
        OS Version: \(recording.osVersion)
        App Version: \(recording.appVersion)
        Screen Resolution: \(recording.screenResolution)
        
        CHAIN OF CUSTODY:
        
        Total Events: \(recording.chainOfCustodyLog.count)
        See custody_log.json for detailed event log.
        
        LEGAL NOTICE:
        
        This recording was created with forensic verification features to ensure
        authenticity and integrity for potential legal proceedings. The cryptographic
        hashes, timestamp verification, and chain of custody log provide evidence
        that the file has not been altered since creation.
        
        For questions or verification assistance, please contact the recording creator.
        """
    }
    
    // MARK: - Formatters
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct CustodyEventRow: View {
    let event: CustodyEvent
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                
                if !isLast {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 2)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.action)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(event.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatTimestamp(event.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct VerificationResult {
    let isValid: Bool
    let message: String
}

#Preview {
    RecordingDetailView(recording: Recording(
        createdAt: Date(),
        filename: "recording_test.mp4",
        fileURL: URL(fileURLWithPath: "/tmp/test.mp4"),
        duration: 125.5,
        fileSize: 15_000_000,
        sha256Hash: "abcd1234efgh5678ijkl9012mnop3456qrst7890uvwx1234yz567890",
        sha512Hash: "abcd1234efgh5678ijkl9012mnop3456qrst7890uvwx1234yz567890abcd1234efgh5678ijkl9012mnop3456qrst7890uvwx1234yz567890",
        deviceModel: "MacBook Pro",
        osVersion: "14.0",
        appVersion: "1.0",
        screenResolution: "2560x1600"
    ))
}
