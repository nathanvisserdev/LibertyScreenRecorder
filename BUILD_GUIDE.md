# Build & Configuration Guide

## Quick Start

### Building for macOS

1. Open the project in Xcode:
   ```bash
   open ScreenRecorder.xcodeproj
   ```

2. Select the macOS scheme from the scheme selector

3. Build and run: `⌘R`

4. Grant Screen Recording permission when prompted

### Building for iOS

1. Open the project in Xcode

2. Select the iOS scheme from the scheme selector

3. Select your target device or simulator

4. Build and run: `⌘R`

## Required Configuration

### Project Settings

The project requires the following capabilities and settings:

#### macOS Target

1. **Minimum Deployment Target**: macOS 13.0
2. **Capabilities Required**:
   - App Sandbox (may need to be disabled for Screen Recording)
   - Hardened Runtime with exceptions:
     - Screen Recording API
3. **Frameworks**:
   - SwiftUI
   - SwiftData
   - ScreenCaptureKit
   - AVFoundation
   - Network (for NTP)
   - CryptoKit

#### iOS Target

1. **Minimum Deployment Target**: iOS 16.0
2. **Capabilities Required**:
   - ReplayKit framework
3. **Frameworks**:
   - SwiftUI
   - SwiftData
   - ReplayKit
   - AVFoundation
   - Network (for NTP)
   - CryptoKit

### Info.plist Keys

Ensure the following keys are in your Info.plist:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to record your screen with forensic verification.</string>

<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio with your screen recordings.</string>
```

For iOS, also add:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to save recordings to your photo library.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs access to save recordings to your photo library.</string>
```

### Code Signing

#### For macOS:
- Enable "Hardened Runtime"
- Add entitlement: `com.apple.security.device.screen-capture`
- For distribution, you'll need:
  - Apple Developer account
  - Notarization for distribution outside App Store

#### For iOS:
- Standard code signing requirements
- May need specific entitlements for enterprise distribution

## Entitlements File

Create a `ScreenRecorder.entitlements` file (if not already present):

### macOS Entitlements:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.device.screen-capture</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

## Testing

### Unit Testing Checklist

- [ ] Hash generation produces consistent results
- [ ] Timestamp verification connects to NTP servers
- [ ] Chain of custody logs are created and persisted
- [ ] File integrity verification works correctly
- [ ] Recordings are saved to correct location

### Manual Testing Checklist

#### macOS:
- [ ] Screen recording permission requested
- [ ] Recording starts and stops successfully
- [ ] Video file is created
- [ ] Manifest and custody log files are generated
- [ ] Hashes match file contents
- [ ] Verification succeeds for unmodified files
- [ ] Verification fails for modified files

#### iOS:
- [ ] ReplayKit permission requested
- [ ] Recording starts and stops successfully
- [ ] Video file is created in Documents
- [ ] All forensic files are generated
- [ ] Export package works correctly

## Deployment

### macOS App Store

1. Archive the app: Product > Archive
2. Validate the archive
3. Submit to App Store Connect
4. Note: Screen recording requires review justification

### macOS Direct Distribution

1. Archive the app
2. Export for distribution outside App Store
3. Notarize with Apple:
   ```bash
   xcrun notarytool submit ScreenRecorder.app --keychain-profile "notary-profile"
   ```
4. Staple the notarization:
   ```bash
   xcrun stapler staple ScreenRecorder.app
   ```

### iOS App Store

1. Archive the app: Product > Archive
2. Validate the archive
3. Submit to App Store Connect
4. Provide privacy policy and usage justification

### TestFlight

1. Archive and upload to App Store Connect
2. Submit for beta review
3. Add external testers
4. Distribute build

## Debugging

### Enable Debug Logging

Add to scheme environment variables:
```
OS_ACTIVITY_MODE = default
```

### Common Issues

**Issue**: Screen recording permission keeps getting requested
**Solution**: Reset privacy settings in System Settings

**Issue**: NTP timestamp fails
**Solution**: Check network connectivity and firewall settings

**Issue**: Video file is empty or corrupted
**Solution**: Ensure sufficient disk space and proper file permissions

## Performance Optimization

### Recording Quality Settings

In `ScreenRecordingManager.swift`, adjust:

```swift
// For lower file sizes (macOS)
streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 30) // 30 FPS

// For higher quality
AVVideoAverageBitRateKey: 20_000_000 // 20 Mbps
```

### Storage Optimization

- Recordings are stored in Documents/Recordings/
- Consider implementing automatic cleanup of old recordings
- Add user settings for quality/size preferences

## Security Considerations

1. **Private Keys**: If using digital signatures, store private keys securely in Keychain
2. **Network**: All network requests (NTP, TSA) use secure connections when available
3. **File Access**: Recordings are stored in app's Documents directory with appropriate permissions
4. **Metadata**: Consider privacy implications of device metadata collection

## Maintenance

### Updating Dependencies

The app uses only Apple frameworks. To update:
1. Update minimum deployment targets
2. Test on new OS versions
3. Check for deprecated APIs

### Adding Features

When adding new features:
1. Update custody log to track new operations
2. Add to forensic manifest if relevant
3. Update verification logic if needed
4. Document in README.md

## Support Resources

- [ScreenCaptureKit Documentation](https://developer.apple.com/documentation/screencapturekit)
- [ReplayKit Documentation](https://developer.apple.com/documentation/replaykit)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [CryptoKit Documentation](https://developer.apple.com/documentation/cryptokit)
