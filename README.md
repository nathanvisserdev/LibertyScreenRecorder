# Forensic Screen Recorder

A cross-platform screen recording application for macOS and iOS that creates forensically verifiable recordings suitable for legal proceedings.

## Features

### 🔒 Forensic Verification
- **Cryptographic Hashing**: SHA-256 and SHA-512 hashes generated immediately upon recording completion
- **Timestamp Verification**: NTP (Network Time Protocol) verification from trusted time servers
- **RFC 3161 Support**: Optional timestamp authority tokens for legal timestamp proof
- **Chain of Custody**: Complete audit trail from creation to export
- **Integrity Verification**: Real-time verification that files haven't been tampered with

### 📱 Cross-Platform Support
- **macOS**: Full screen capture using ScreenCaptureKit with high-quality recording
- **iOS**: Screen recording using ReplayKit with system integration

### 📊 Forensic Documentation
- Automatic generation of forensic manifest files
- Chain-of-custody JSON logs
- Device metadata capture (model, OS version, screen resolution)
- Exportable forensic packages with README documentation

### ✅ Court Admissibility Features

The recordings created by this application possess the following qualities to be forensically verifiable:

1. **Captured Without Post-Editing**: Direct capture to disk with no intermediate processing
2. **Cryptographic Hash Generated Upon Creation**: SHA-256/512 hashes calculated immediately
3. **Timestamps Verifiable via External Sources**: NTP time synchronization and optional TSA tokens
4. **Original File Preserved**: Chain-of-custody tracking and integrity verification
5. **Supporting Logs Retained**: Complete audit trail of all operations

## System Requirements

- **macOS**: macOS 13.0 or later (for ScreenCaptureKit support)
- **iOS**: iOS 16.0 or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later

## Permissions Required

### macOS
- Screen Recording permission (System Settings > Privacy & Security > Screen Recording)

### iOS
- Screen Recording (handled by ReplayKit)
- Microphone (optional, for audio recording)

## Architecture

### Services

#### CryptographicHashService
Handles all cryptographic operations:
- SHA-256 and SHA-512 hash generation
- File integrity verification
- Forensic manifest creation
- Proof-of-existence generation

#### TimestampVerificationService
Manages timestamp verification:
- NTP time synchronization with multiple fallback servers
- RFC 3161 timestamp authority integration
- Time difference analysis
- Timestamp proof document generation

#### ChainOfCustodyService
Maintains audit trail:
- Event logging for all file operations
- Chronological integrity verification
- Export to JSON format
- Digital signature support

#### ScreenRecordingManager
Core recording functionality:
- Platform-specific screen capture (ScreenCaptureKit for macOS, ReplayKit for iOS)
- Automatic forensic data generation
- Recording state management
- Error handling and recovery

### Data Models

#### Recording
SwiftData model containing:
- Basic file information (URL, size, duration)
- Cryptographic hashes (SHA-256, SHA-512)
- Timestamp verification data
- Chain of custody events
- Device metadata

#### CustodyEvent
Represents a single event in the chain of custody:
- Timestamp
- Action type
- Details
- User identifier

## Usage

### Starting a Recording

```swift
let manager = ScreenRecordingManager()
let outputURL = try await manager.startRecording()
```

### Stopping a Recording

```swift
let recording = try await manager.stopRecording()
// Recording object contains all forensic data
```

### Verifying File Integrity

```swift
let hashService = CryptographicHashService()
let isValid = try await hashService.verifyFileIntegrity(
    fileURL: recording.fileURL,
    expectedSHA256: recording.sha256Hash
)
```

### Exporting Forensic Package

The app automatically exports:
- Original video file
- Forensic manifest (JSON)
- Chain of custody log (JSON)
- README with verification instructions

## File Structure

```
ScreenRecorder/
├── Models/
│   └── Recording.swift              # SwiftData model
├── Services/
│   ├── ScreenRecordingManager.swift # Recording controller
│   ├── CryptographicHashService.swift
│   ├── TimestampVerificationService.swift
│   └── ChainOfCustodyService.swift
├── Views/
│   ├── ContentView.swift            # Main app structure
│   ├── RecordingControlView.swift   # Recording controls
│   ├── RecordingsListView.swift     # List of recordings
│   └── RecordingDetailView.swift    # Detail & verification view
└── Info.plist                       # App permissions
```

## Building

1. Open `ScreenRecorder.xcodeproj` in Xcode
2. Select your target (macOS or iOS)
3. Build and run (⌘R)

### macOS Specific Setup
The app uses ScreenCaptureKit which requires:
- macOS 13.0 or later
- Screen Recording permission granted
- Code signing enabled

### iOS Specific Setup
The app uses ReplayKit which:
- Works on real devices and simulator
- Requires user permission at runtime
- May have limitations in simulator

## Forensic Package Contents

When exporting a recording, the following files are included:

1. **Video File** (`recording_*.mp4`)
   - Original unmodified recording

2. **Manifest File** (`recording_*.manifest.json`)
   - Cryptographic hashes
   - File metadata
   - Timestamp verification data
   - Device information

3. **Chain of Custody Log** (`recording_*.custody_log.json`)
   - Complete audit trail
   - All operations performed on the file
   - Timestamps for each event
   - User identifiers

4. **README** (`README.txt`)
   - Verification instructions
   - Hash values for manual verification
   - Legal notice
   - Device information

## Verification Process

To verify a recording's authenticity:

1. **Verify Hash**:
   ```bash
   # macOS/Linux
   shasum -a 256 recording.mp4
   
   # Windows
   certutil -hashfile recording.mp4 SHA256
   ```
   Compare with hash in manifest file.

2. **Check Chain of Custody**:
   - Review custody_log.json for any suspicious gaps or modifications
   - Verify chronological order of events
   - Confirm all required events are present

3. **Timestamp Verification**:
   - Compare NTP timestamp with device timestamp
   - Verify time difference is within acceptable range
   - Check TSA token if present

4. **Integrity Check**:
   - Ensure `isOriginalFile` is true
   - Verify no modification events in custody log
   - Confirm file size matches manifest

## Legal Considerations

### Admissibility
This application creates recordings designed to meet legal standards for digital evidence:

- **Authentication**: Cryptographic hashes prove file integrity
- **Reliability**: NTP timestamps verify creation time
- **Chain of Custody**: Complete audit trail maintained
- **Original Evidence**: Files protected from modification

### Best Practices

1. **Export Immediately**: Create forensic package right after recording
2. **Store Securely**: Keep original files on read-only media
3. **Document Everything**: Maintain external notes about recording context
4. **Verify Regularly**: Periodically check file integrity
5. **Preserve Metadata**: Keep all associated JSON files with recordings

### Limitations

- This tool creates technically sound recordings but legal admissibility depends on jurisdiction
- Consult with legal counsel regarding specific requirements
- Some courts may require additional authentication
- Always follow proper evidence handling procedures

## Technical Details

### Hash Algorithms
- **SHA-256**: 256-bit cryptographic hash (64 character hex string)
- **SHA-512**: 512-bit cryptographic hash (128 character hex string)

### NTP Servers
Primary time servers used (with fallback):
- time.apple.com
- time.google.com
- time.nist.gov
- pool.ntp.org

### Timestamp Authorities
RFC 3161 TSA servers attempted:
- timestamp.digicert.com
- timestamp.apple.com
- timestamp.sectigo.com

### Video Encoding
- **Codec**: H.264
- **Container**: MP4
- **macOS**: Up to 60 FPS, Retina resolution
- **iOS**: Native screen resolution and frame rate

## Troubleshooting

### macOS: Screen Recording Permission Denied
1. Go to System Settings > Privacy & Security > Screen Recording
2. Enable permission for ScreenRecorder app
3. Restart the application

### iOS: Recording Fails to Start
1. Ensure ReplayKit is available (check `RPScreenRecorder.shared().isAvailable`)
2. Try closing and reopening the app
3. Check for other apps using screen recording

### Verification Fails
1. Ensure file hasn't been moved or renamed
2. Check that manifest.json exists in the same directory
3. Verify file hasn't been edited or modified

### NTP Timestamp Fails
- Network connectivity required
- Firewall may block NTP (port 123)
- App will still function but without external timestamp verification

## Future Enhancements

- [ ] Blockchain timestamp anchoring
- [ ] GPS location recording (iOS)
- [ ] Witness digital signatures
- [ ] Encrypted storage option
- [ ] Cloud backup with integrity preservation
- [ ] PDF forensic report generation
- [ ] Multiple camera angles (iOS)

## License

Copyright © 2025. All rights reserved.

## Support

For issues, questions, or contributions, please contact the development team.

## Disclaimer

This application is provided as a tool for creating forensically sound recordings. The developers make no guarantees regarding legal admissibility in specific jurisdictions. Users are responsible for ensuring compliance with all applicable laws and regulations regarding recording and evidence handling.
