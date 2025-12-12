# System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE LAYER                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────┐  ┌──────────────────┐  ┌─────────────────┐ │
│  │ ContentView       │  │ Recording        │  │ Recordings      │ │
│  │ (Main UI)         │  │ Control View     │  │ List View       │ │
│  │                   │  │                  │  │                 │ │
│  │ • macOS Sidebar   │  │ • Start Button   │  │ • List Display  │ │
│  │ • iOS Tabs        │  │ • Stop Button    │  │ • Delete        │ │
│  │ • Navigation      │  │ • Timer Display  │  │ • Selection     │ │
│  └───────────────────┘  └──────────────────┘  └─────────────────┘ │
│                                                                     │
│                         ┌──────────────────┐                        │
│                         │ Recording        │                        │
│                         │ Detail View      │                        │
│                         │                  │                        │
│                         │ • Video Player   │                        │
│                         │ • Verification   │                        │
│                         │ • Export         │                        │
│                         └──────────────────┘                        │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      BUSINESS LOGIC LAYER                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │            ScreenRecordingManager (@MainActor)                │ │
│  │                                                               │ │
│  │  • Start/Stop Recording                                       │ │
│  │  • Platform Detection (macOS/iOS)                            │ │
│  │  • Duration Tracking                                          │ │
│  │  • Error Handling                                             │ │
│  │  • Forensic Data Coordination                                 │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌─────────────────────┐  ┌─────────────────────┐                 │
│  │ Cryptographic       │  │ Timestamp           │                 │
│  │ Hash Service        │  │ Verification        │                 │
│  │ (Actor)             │  │ Service (Actor)     │                 │
│  │                     │  │                     │                 │
│  │ • SHA-256          │  │ • NTP Sync         │                 │
│  │ • SHA-512          │  │ • TSA Tokens       │                 │
│  │ • Verify Integrity │  │ • Multiple Servers │                 │
│  │ • Create Manifest  │  │ • Proof Creation   │                 │
│  └─────────────────────┘  └─────────────────────┘                 │
│                                                                     │
│  ┌─────────────────────────────────────────────┐                   │
│  │ Chain of Custody Service (Actor)            │                   │
│  │                                              │                   │
│  │ • Event Logging                              │                   │
│  │ • Integrity Verification                     │                   │
│  │ • JSON Export                                │                   │
│  │ • Chronological Tracking                     │                   │
│  └─────────────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      PLATFORM SERVICES LAYER                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────────┐    ┌──────────────────────────┐     │
│  │ macOS                    │    │ iOS                      │     │
│  ├──────────────────────────┤    ├──────────────────────────┤     │
│  │                          │    │                          │     │
│  │ ScreenCaptureKit         │    │ ReplayKit                │     │
│  │ • SCStream               │    │ • RPScreenRecorder       │     │
│  │ • SCStreamConfiguration  │    │ • Sample Buffers         │     │
│  │ • SCContentFilter        │    │ • Audio/Video Mix        │     │
│  │ • Up to 60 FPS           │    │ • System Integration     │     │
│  │ • Retina Resolution      │    │ • Native Resolution      │     │
│  │                          │    │                          │     │
│  └──────────────────────────┘    └──────────────────────────┘     │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │              Common Platform Services                       │  │
│  │                                                             │  │
│  │  AVFoundation  │  CryptoKit  │  Network  │  SwiftData     │  │
│  │  • AVAssetWriter  • SHA-256    • NTP       • Persistence  │  │
│  │  • Video Encoding • SHA-512    • TCP/UDP   • Queries      │  │
│  │  • H.264 Codec    • Hashing    • URLs      • Models       │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      DATA PERSISTENCE LAYER                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    SwiftData Models                         │  │
│  │                                                             │  │
│  │  ┌────────────────────────────────────────────────┐        │  │
│  │  │ Recording (@Model)                             │        │  │
│  │  │                                                 │        │  │
│  │  │ • Basic Info (filename, URL, duration)          │        │  │
│  │  │ • Forensic Data (hashes, timestamps)            │        │  │
│  │  │ • Chain of Custody (events array)               │        │  │
│  │  │ • Device Metadata (model, OS, resolution)       │        │  │
│  │  └────────────────────────────────────────────────┘        │  │
│  │                                                             │  │
│  │  ┌────────────────────────────────────────────────┐        │  │
│  │  │ CustodyEvent (Codable)                         │        │  │
│  │  │                                                 │        │  │
│  │  │ • Timestamp                                     │        │  │
│  │  │ • Action                                        │        │  │
│  │  │ • Details                                       │        │  │
│  │  │ • User Identifier                               │        │  │
│  │  └────────────────────────────────────────────────┘        │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         FILE SYSTEM LAYER                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Documents/Recordings/                                              │
│  ├── recording_1234567890.mp4          (Video file)                │
│  ├── recording_1234567890.manifest.json (Cryptographic data)       │
│  └── recording_1234567890.custody_log.json (Audit trail)           │
│                                                                     │
│  Forensic Export Package/                                           │
│  ├── recording_1234567890.mp4                                      │
│  ├── recording_1234567890.manifest.json                            │
│  ├── recording_1234567890.custody_log.json                         │
│  └── README.txt                         (Verification instructions) │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════
                        EXTERNAL SERVICES
═══════════════════════════════════════════════════════════════════════

┌─────────────────┐         ┌─────────────────────────────────────┐
│ NTP Time        │         │ RFC 3161 Timestamp Authorities      │
│ Servers         │         │                                     │
├─────────────────┤         ├─────────────────────────────────────┤
│                 │         │                                     │
│ time.apple.com  │◄───────►│ timestamp.digicert.com              │
│ time.google.com │         │ timestamp.apple.com                 │
│ time.nist.gov   │         │ timestamp.sectigo.com               │
│ pool.ntp.org    │         │                                     │
│                 │         │ (Optional - may fail gracefully)    │
└─────────────────┘         └─────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════
                        DATA FLOW DIAGRAM
═══════════════════════════════════════════════════════════════════════

START RECORDING
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. User taps "Start Recording"                              │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. ScreenRecordingManager.startRecording()                  │
│    • Create output file URL                                 │
│    • Log "RECORDING_START" custody event                    │
└─────────────────────────────────────────────────────────────┘
     │
     ├──► macOS Path                    iOS Path ◄────┤
     │                                                  │
     ▼                                                  ▼
┌─────────────────────┐                    ┌──────────────────────┐
│ Start ScreenCapture │                    │ Start ReplayKit      │
│ • Get display       │                    │ • Get recorder       │
│ • Configure stream  │                    │ • Setup AVAssetWriter│
│ • Setup AVAssetWriter│                   │ • Start capture      │
│ • Start capture     │                    │                      │
└─────────────────────┘                    └──────────────────────┘
     │                                                  │
     └──────────────────┬───────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Recording in Progress                                    │
│    • Video frames written to disk                           │
│    • Timer updates UI                                       │
│    • User performs actions to capture                       │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
STOP RECORDING
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. User taps "Stop Recording"                               │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. ScreenRecordingManager.stopRecording()                   │
│    • Stop platform capture                                  │
│    • Finalize AVAssetWriter                                 │
│    • Log "RECORDING_COMPLETE" custody event                 │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Generate Cryptographic Hashes                            │
│    CryptographicHashService.generateHashes()                │
│    • Read file data                                         │
│    • Calculate SHA-256                                      │
│    • Calculate SHA-512                                      │
│    • Log "HASH_GENERATION_COMPLETE" custody event           │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. Verify Timestamp                                         │
│    TimestampVerificationService.getVerifiedTimestamp()      │
│    • Query NTP server                                       │
│    • Get verified time                                      │
│    • Calculate time difference                              │
│    • Log "TIMESTAMP_VERIFICATION_COMPLETE" custody event    │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. Request TSA Token (Optional)                             │
│    TimestampVerificationService.requestTimestampToken()     │
│    • Try RFC 3161 timestamp authorities                     │
│    • Store response if successful                           │
│    • Log result (success or failure)                        │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 9. Create Forensic Manifest                                 │
│    CryptographicHashService.createForensicManifest()        │
│    • Collect all metadata                                   │
│    • Write manifest.json                                    │
│    • Log "MANIFEST_CREATED" custody event                   │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 10. Export Chain of Custody                                 │
│     ChainOfCustodyService.exportLog()                       │
│     • Collect all events                                    │
│     • Write custody_log.json                                │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 11. Create Recording Object                                 │
│     • Populate all forensic data                            │
│     • Set isOriginalFile = true                             │
│     • Store original hash                                   │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 12. Save to SwiftData                                       │
│     modelContext.insert(recording)                          │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 13. Show Success Message                                    │
│     • Display recording details                             │
│     • Update UI with new recording                          │
└─────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════
                    VERIFICATION FLOW DIAGRAM
═══════════════════════════════════════════════════════════════════════

USER VERIFIES RECORDING
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. User opens recording detail view                         │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. User taps "Verify" button                                │
└─────────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. CryptographicHashService.verifyFileIntegrity()           │
│    • Read current file                                      │
│    • Calculate current SHA-256 hash                         │
│    • Compare with stored hash                               │
└─────────────────────────────────────────────────────────────┘
     │
     ├──► Hashes Match              Hashes Don't Match ◄────┤
     │                                                        │
     ▼                                                        ▼
┌──────────────────────┐                    ┌───────────────────────┐
│ ✅ VERIFIED          │                    │ ⚠️  MODIFIED          │
│                      │                    │                       │
│ File is authentic    │                    │ File has been altered │
│ No tampering detected│                    │ Cannot be trusted     │
└──────────────────────┘                    └───────────────────────┘
     │                                                        │
     └────────────────────┬───────────────────────────────────┘
                          │
                          ▼
              ┌──────────────────────┐
              │ Display result to    │
              │ user with indicator  │
              └──────────────────────┘


═══════════════════════════════════════════════════════════════════════
                  ACTOR CONCURRENCY MODEL
═══════════════════════════════════════════════════════════════════════

@MainActor
ScreenRecordingManager ◄─── UI Thread
         │                   (ObservableObject)
         │
         ├─────► CryptographicHashService (Actor)
         │                  │
         │                  └─── Thread-safe hash operations
         │
         ├─────► TimestampVerificationService (Actor)
         │                  │
         │                  └─── Thread-safe network operations
         │
         └─────► ChainOfCustodyService (Actor)
                            │
                            └─── Thread-safe logging operations

All actors ensure thread-safety for concurrent operations
while MainActor ensures UI updates on main thread.
```
