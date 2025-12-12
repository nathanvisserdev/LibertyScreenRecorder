//
//  ScreenRecordingManager.swift
//  ScreenRecorder
//
//  Created by Nathan Visser on 2025-12-11.
//

import Foundation
import AVFoundation
import ReplayKit
import SwiftUI

#if os(macOS)
import ScreenCaptureKit
#endif

@MainActor
class ScreenRecordingManager: ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var lastError: String?
    
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    private var currentOutputURL: URL?
    
    #if os(macOS)
    private var streamOutput: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var stream: SCStream?
    #else
    private var recorder = RPScreenRecorder.shared()
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    #endif
    
    private let hashService = CryptographicHashService()
    private let timestampService = TimestampVerificationService()
    private let custodyService = ChainOfCustodyService()
    
    // MARK: - Recording Control
    
    func startRecording() async throws -> URL {
        guard !isRecording else {
            throw RecordingError.alreadyRecording
        }
        
        // Create output file
        let filename = "recording_\(Date().timeIntervalSince1970).mp4"
        let outputURL = try createOutputURL(filename: filename)
        currentOutputURL = outputURL
        
        // Log start of recording
        await custodyService.logEvent(
            action: "RECORDING_START",
            details: "Screen recording initiated",
            fileURL: outputURL
        )
        
        #if os(macOS)
        try await startMacOSRecording(outputURL: outputURL)
        #else
        try await startiOSRecording(outputURL: outputURL)
        #endif
        
        isRecording = true
        recordingStartTime = Date()
        startTimer()
        
        return outputURL
    }
    
    func stopRecording() async throws -> Recording {
        guard isRecording else {
            throw RecordingError.notRecording
        }
        
        guard let outputURL = currentOutputURL,
              let startTime = recordingStartTime else {
            throw RecordingError.noActiveRecording
        }
        
        stopTimer()
        
        #if os(macOS)
        try await stopMacOSRecording()
        #else
        try await stopiOSRecording()
        #endif
        
        isRecording = false
        
        // Log completion
        await custodyService.logEvent(
            action: "RECORDING_COMPLETE",
            details: "Screen recording completed successfully",
            fileURL: outputURL
        )
        
        // Generate forensic data
        let recording = try await createForensicRecording(
            fileURL: outputURL,
            startTime: startTime,
            duration: recordingDuration
        )
        
        recordingDuration = 0
        currentOutputURL = nil
        recordingStartTime = nil
        
        return recording
    }
    
    // MARK: - macOS Recording
    
    #if os(macOS)
    private func startMacOSRecording(outputURL: URL) async throws {
        // Get available content
        let availableContent = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        
        guard let display = availableContent.displays.first else {
            throw RecordingError.noDisplayAvailable
        }
        
        // Configure stream
        let streamConfig = SCStreamConfiguration()
        streamConfig.width = display.width * 2 // Retina resolution
        streamConfig.height = display.height * 2
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 60) // 60 FPS
        streamConfig.queueDepth = 5
        streamConfig.showsCursor = true
        
        // Create filter
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        // Setup AVAssetWriter
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: streamConfig.width,
            AVVideoHeightKey: streamConfig.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 10_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = true
        
        if writer.canAdd(input) {
            writer.add(input)
        }
        
        self.videoInput = input
        self.streamOutput = writer
        
        // Create and start stream
        let stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
        
        try await stream.addStreamOutput(
            StreamOutput(assetWriter: writer, input: input),
            type: .screen,
            sampleHandlerQueue: .global()
        )
        
        try await stream.startCapture()
        self.stream = stream
    }
    
    private func stopMacOSRecording() async throws {
        if let stream = stream {
            try await stream.stopCapture()
            self.stream = nil
        }
        
        videoInput?.markAsFinished()
        
        if let writer = streamOutput {
            await writer.finishWriting()
            self.streamOutput = nil
            self.videoInput = nil
        }
    }
    
    // Helper class for macOS stream output
    private class StreamOutput: NSObject, SCStreamOutput {
        let assetWriter: AVAssetWriter
        let input: AVAssetWriterInput
        
        init(assetWriter: AVAssetWriter, input: AVAssetWriterInput) {
            self.assetWriter = assetWriter
            self.input = input
        }
        
        func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
            guard type == .screen else { return }
            
            if assetWriter.status == .unknown {
                let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                assetWriter.startWriting()
                assetWriter.startSession(atSourceTime: timestamp)
            }
            
            if assetWriter.status == .writing,
               input.isReadyForMoreMediaData {
                input.append(sampleBuffer)
            }
        }
    }
    #endif
    
    // MARK: - iOS Recording
    
    #if os(iOS)
    private func startiOSRecording(outputURL: URL) async throws {
        guard recorder.isAvailable else {
            throw RecordingError.recorderUnavailable
        }
        
        // Setup asset writer
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: UIScreen.main.bounds.width * UIScreen.main.scale,
            AVVideoHeightKey: UIScreen.main.bounds.height * UIScreen.main.scale
        ]
        
        let vInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        vInput.expectsMediaDataInRealTime = true
        
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0,
            AVEncoderBitRateKey: 128000
        ]
        
        let aInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        aInput.expectsMediaDataInRealTime = true
        
        if writer.canAdd(vInput) {
            writer.add(vInput)
        }
        if writer.canAdd(aInput) {
            writer.add(aInput)
        }
        
        self.assetWriter = writer
        self.videoInput = vInput
        self.audioInput = aInput
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            recorder.startCapture(handler: { [weak self] sampleBuffer, sampleType, error in
                guard let self = self else { return }
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let writer = self.assetWriter else { return }
                
                if writer.status == .unknown {
                    let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    writer.startWriting()
                    writer.startSession(atSourceTime: timestamp)
                    continuation.resume()
                }
                
                if writer.status == .writing {
                    switch sampleType {
                    case .video:
                        if self.videoInput?.isReadyForMoreMediaData == true {
                            self.videoInput?.append(sampleBuffer)
                        }
                    case .audioMic, .audioApp:
                        if self.audioInput?.isReadyForMoreMediaData == true {
                            self.audioInput?.append(sampleBuffer)
                        }
                    @unknown default:
                        break
                    }
                }
            }, completionHandler: { error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
            })
        }
    }
    
    private func stopiOSRecording() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            recorder.stopCapture { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        
        if let writer = assetWriter {
            await writer.finishWriting()
            self.assetWriter = nil
            self.videoInput = nil
            self.audioInput = nil
        }
    }
    #endif
    
    // MARK: - Forensic Data Generation
    
    private func createForensicRecording(
        fileURL: URL,
        startTime: Date,
        duration: TimeInterval
    ) async throws -> Recording {
        
        // Generate cryptographic hashes
        await custodyService.logEvent(
            action: "HASH_GENERATION_START",
            details: "Generating cryptographic hashes",
            fileURL: fileURL
        )
        
        let hashes = try await hashService.generateHashes(for: fileURL)
        
        await custodyService.logEvent(
            action: "HASH_GENERATION_COMPLETE",
            details: "SHA-256: \(hashes.sha256)",
            fileURL: fileURL
        )
        
        // Get verified timestamp
        await custodyService.logEvent(
            action: "TIMESTAMP_VERIFICATION_START",
            details: "Requesting timestamp verification from NTP",
            fileURL: fileURL
        )
        
        let (ntpTime, ntpServer) = try await timestampService.getVerifiedTimestamp()
        
        await custodyService.logEvent(
            action: "TIMESTAMP_VERIFICATION_COMPLETE",
            details: "NTP timestamp obtained from \(ntpServer)",
            fileURL: fileURL
        )
        
        // Request timestamp token (optional, may fail)
        var tsaURL: String?
        var tsaResponse: Data?
        
        do {
            let (url, response) = try await timestampService.requestTimestampToken(for: hashes.sha256)
            tsaURL = url
            tsaResponse = response
            
            await custodyService.logEvent(
                action: "TSA_TOKEN_RECEIVED",
                details: "Timestamp token received from \(url)",
                fileURL: fileURL
            )
        } catch {
            await custodyService.logEvent(
                action: "TSA_TOKEN_FAILED",
                details: "Failed to obtain timestamp token: \(error.localizedDescription)",
                fileURL: fileURL
            )
        }
        
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Get device metadata
        let deviceModel = getDeviceModel()
        let osVersion = getOSVersion()
        let screenResolution = getScreenResolution()
        
        // Create manifest
        let metadata: [String: Any] = [
            "device_model": deviceModel,
            "os_version": osVersion,
            "screen_resolution": screenResolution,
            "ntp_timestamp": ISO8601DateFormatter().string(from: ntpTime),
            "ntp_server": ntpServer
        ]
        
        let manifestURL = try await hashService.createForensicManifest(
            fileURL: fileURL,
            sha256: hashes.sha256,
            sha512: hashes.sha512,
            metadata: metadata
        )
        
        await custodyService.logEvent(
            action: "MANIFEST_CREATED",
            details: "Forensic manifest created at \(manifestURL.lastPathComponent)",
            fileURL: fileURL
        )
        
        // Get chain of custody log
        let custodyLog = await custodyService.getEvents(for: fileURL)
        
        // Create recording object
        let recording = Recording(
            createdAt: startTime,
            filename: fileURL.lastPathComponent,
            fileURL: fileURL,
            duration: duration,
            fileSize: fileSize,
            sha256Hash: hashes.sha256,
            sha512Hash: hashes.sha512,
            timestampVerificationURL: tsaURL,
            timestampResponse: tsaResponse,
            ntpTimestamp: ntpTime,
            ntpServer: ntpServer,
            chainOfCustodyLog: custodyLog,
            isOriginalFile: true,
            originalFileHash: hashes.sha256,
            deviceModel: deviceModel,
            osVersion: osVersion,
            appVersion: getAppVersion(),
            screenResolution: screenResolution
        )
        
        return recording
    }
    
    // MARK: - Helper Methods
    
    private func createOutputURL(filename: String) throws -> URL {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        
        let recordingsPath = documentsPath.appendingPathComponent("Recordings", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: recordingsPath.path) {
            try FileManager.default.createDirectory(
                at: recordingsPath,
                withIntermediateDirectories: true
            )
        }
        
        return recordingsPath.appendingPathComponent(filename)
    }
    
    private func startTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  let startTime = self.recordingStartTime else { return }
            
            Task { @MainActor in
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func getDeviceModel() -> String {
        #if os(macOS)
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
        return modelCode ?? "Unknown"
        #endif
    }
    
    private func getOSVersion() -> String {
        #if os(macOS)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        #else
        return UIDevice.current.systemVersion
        #endif
    }
    
    private func getScreenResolution() -> String {
        #if os(macOS)
        if let screen = NSScreen.main {
            let size = screen.frame.size
            return "\(Int(size.width))x\(Int(size.height))"
        }
        return "Unknown"
        #else
        let screen = UIScreen.main
        let size = screen.bounds.size
        let scale = screen.scale
        return "\(Int(size.width * scale))x\(Int(size.height * scale))"
        #endif
    }
    
    private func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - Errors

enum RecordingError: LocalizedError {
    case alreadyRecording
    case notRecording
    case noActiveRecording
    case noDisplayAvailable
    case recorderUnavailable
    
    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "Recording is already in progress"
        case .notRecording:
            return "No recording in progress"
        case .noActiveRecording:
            return "No active recording found"
        case .noDisplayAvailable:
            return "No display available for recording"
        case .recorderUnavailable:
            return "Screen recorder is not available"
        }
    }
}
