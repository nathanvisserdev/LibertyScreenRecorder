//
//  RecordingsListView.swift
//  ScreenRecorder
//
//  Created by Nathan Visser on 2025-12-11.
//

import SwiftUI
import SwiftData

struct RecordingsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recording.createdAt, order: .reverse) private var recordings: [Recording]
    
    @State private var selectedRecording: Recording?
    @State private var showingDetails = false
    
    var body: some View {
        Group {
            if recordings.isEmpty {
                emptyState
            } else {
                recordingsList
            }
        }
        .sheet(item: $selectedRecording) { recording in
            RecordingDetailView(recording: recording)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Recordings Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a new recording to begin")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var recordingsList: some View {
        List {
            ForEach(recordings) { recording in
                RecordingRowView(recording: recording)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRecording = recording
                    }
            }
            .onDelete(perform: deleteRecordings)
        }
    }
    
    private func deleteRecordings(at offsets: IndexSet) {
        for index in offsets {
            let recording = recordings[index]
            
            // Delete the file
            try? FileManager.default.removeItem(at: recording.fileURL)
            
            // Delete associated files
            let manifestURL = recording.fileURL.deletingPathExtension().appendingPathExtension("manifest.json")
            try? FileManager.default.removeItem(at: manifestURL)
            
            let custodyURL = recording.fileURL.deletingPathExtension().appendingPathExtension("custody_log.json")
            try? FileManager.default.removeItem(at: custodyURL)
            
            // Delete from database
            modelContext.delete(recording)
        }
    }
}

struct RecordingRowView: View {
    let recording: Recording
    
    var body: some View {
        HStack(spacing: 15) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 80, height: 60)
                .overlay(
                    Image(systemName: "video.fill")
                        .foregroundColor(.secondary)
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(recording.filename)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(formatDuration(recording.duration))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: recording.isOriginalFile ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(recording.isOriginalFile ? .green : .orange)
                    Text(recording.isOriginalFile ? "Verified" : "Modified")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text(formatDate(recording.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatFileSize(recording.fileSize))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    RecordingsListView()
        .modelContainer(for: Recording.self, inMemory: true)
}
