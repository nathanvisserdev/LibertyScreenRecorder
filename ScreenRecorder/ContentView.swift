//
//  ContentView.swift
//  ScreenRecorder
//
//  Created by Nathan Visser on 2025-12-11.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        MacOSContentView()
        #else
        iOSContentView()
        #endif
    }
}

#if os(macOS)
struct MacOSContentView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            RecordingControlView()
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
#else
struct iOSContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                RecordingControlView()
                    .navigationTitle("Record")
            }
            .tabItem {
                Label("Record", systemImage: "record.circle")
            }
            
            NavigationStack {
                RecordingsListView()
                    .navigationTitle("Recordings")
            }
            .tabItem {
                Label("Recordings", systemImage: "list.bullet")
            }
        }
    }
}
#endif

struct SidebarView: View {
    @State private var selection: SidebarItem? = .record
    
    var body: some View {
        List(selection: $selection) {
            NavigationLink(value: SidebarItem.record) {
                Label("Record", systemImage: "record.circle")
            }
            
            NavigationLink(value: SidebarItem.recordings) {
                Label("Recordings", systemImage: "list.bullet")
            }
            
            Section("Information") {
                NavigationLink(value: SidebarItem.about) {
                    Label("About", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Screen Recorder")
        .navigationDestination(for: SidebarItem.self) { item in
            switch item {
            case .record:
                RecordingControlView()
            case .recordings:
                RecordingsListView()
            case .about:
                AboutView()
            }
        }
    }
}

enum SidebarItem: Hashable {
    case record
    case recordings
    case about
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Forensic Screen Recorder")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0")
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Features")
                        .font(.headline)
                    
                    FeatureRow(
                        icon: "checkmark.seal.fill",
                        title: "Cryptographic Verification",
                        description: "SHA-256 and SHA-512 hashes generated for each recording"
                    )
                    
                    FeatureRow(
                        icon: "clock.badge.checkmark",
                        title: "Timestamp Verification",
                        description: "NTP and RFC 3161 timestamp authority verification"
                    )
                    
                    FeatureRow(
                        icon: "doc.text.fill",
                        title: "Chain of Custody",
                        description: "Complete audit trail from creation to export"
                    )
                    
                    FeatureRow(
                        icon: "lock.shield.fill",
                        title: "Forensically Sound",
                        description: "Court-admissible evidence with integrity verification"
                    )
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Legal Compliance")
                        .font(.headline)
                    
                    Text("This application creates screen recordings with forensic verification features suitable for legal proceedings. All recordings include cryptographic hashes, timestamp verification, and chain-of-custody logging to ensure authenticity and integrity.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(30)
        }
        .frame(maxWidth: 600)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Recording.self, inMemory: true)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
