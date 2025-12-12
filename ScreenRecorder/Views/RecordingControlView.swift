//
//  RecordingControlView.swift
//  ScreenRecorder
//
//  Created by Nathan Visser on 2025-12-11.
//

import SwiftUI
import SwiftData

struct RecordingControlView: View {
    @StateObject private var recordingManager = ScreenRecordingManager()
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var lastRecording: Recording?
    
    var body: some View {
        VStack(spacing: 30) {
            // Status indicator
            statusView
            
            // Timer
            if recordingManager.isRecording {
                timerView
            }
            
            // Control button
            controlButton
            
            // Last recording info
            if let recording = lastRecording {
                lastRecordingView(recording)
            }
        }
        .padding(40)
        .frame(maxWidth: 500)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Recording Complete", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
            if let recording = lastRecording {
                Button("View Details") {
                    // Navigate to details view
                }
            }
        } message: {
            if let recording = lastRecording {
                Text("Recording saved successfully\n\(recording.filename)")
            }
        }
    }
    
    private var statusView: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(recordingManager.isRecording ? Color.red : Color.gray)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(color: recordingManager.isRecording ? .red.opacity(0.5) : .clear, radius: 10)
            
            Text(recordingManager.isRecording ? "Recording" : "Ready")
                .font(.title2)
                .fontWeight(.semibold)
        }
    }
    
    private var timerView: some View {
        Text(formatDuration(recordingManager.recordingDuration))
            .font(.system(size: 48, weight: .light, design: .monospaced))
            .foregroundColor(.primary)
    }
    
    private var controlButton: some View {
        Button(action: handleButtonTap) {
            HStack {
                Image(systemName: recordingManager.isRecording ? "stop.circle.fill" : "record.circle")
                    .font(.title)
                Text(recordingManager.isRecording ? "Stop Recording" : "Start Recording")
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(recordingManager.isRecording ? Color.red : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(false)
    }
    
    private func lastRecordingView(_ recording: Recording) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last Recording")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Forensically Verified")
                        .font(.subheadline)
                }
                
                Text("Duration: \(formatDuration(recording.duration))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Hash: \(String(recording.sha256Hash.prefix(16)))...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospaced()
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func handleButtonTap() {
        Task {
            do {
                if recordingManager.isRecording {
                    let recording = try await recordingManager.stopRecording()
                    
                    // Save to SwiftData
                    modelContext.insert(recording)
                    try modelContext.save()
                    
                    lastRecording = recording
                    showingSuccess = true
                } else {
                    _ = try await recordingManager.startRecording()
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    RecordingControlView()
        .modelContainer(for: Recording.self, inMemory: true)
}
