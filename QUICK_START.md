# Quick Start Guide

## Welcome to Forensic Screen Recorder

This app creates legally verifiable screen recordings for use as evidence in legal proceedings.

## First Launch

### macOS

1. **Launch the app**
2. **Grant Screen Recording permission:**
   - System dialog will appear
   - Open System Settings > Privacy & Security > Screen Recording
   - Enable "ScreenRecorder"
   - Restart the app

### iOS

1. **Launch the app**
2. **Grant permissions when prompted:**
   - Screen recording access (handled automatically)
   - Microphone access (optional)

## Recording Your Screen

### Start Recording

1. Click/tap the **"Start Recording"** button
2. The timer will begin counting
3. The red indicator shows recording is active
4. Perform the actions you want to capture

### Stop Recording

1. Click/tap the **"Stop Recording"** button
2. The app will automatically:
   - Generate cryptographic hashes
   - Verify timestamp with NTP servers
   - Create chain of custody log
   - Save forensic manifest
3. Your recording is ready!

## Viewing Recordings

### macOS
- Click "Recordings" in the sidebar
- Select any recording to view details
- Click play icon to watch

### iOS
- Tap "Recordings" tab at bottom
- Tap any recording to view details
- Use built-in video player

## Verifying a Recording

1. Open a recording's detail view
2. Click/tap **"Verify"** button
3. The app will:
   - Recalculate the file's hash
   - Compare with original hash
   - Show verification result

✅ **Green checkmark** = File is authentic and unmodified  
⚠️ **Red X** = File has been altered

## Exporting for Legal Use

### Export Forensic Package

1. Open recording details
2. Click/tap **"Export Forensic Package"**
3. Package includes:
   - Original video file
   - Cryptographic hashes (manifest.json)
   - Chain of custody log (custody_log.json)
   - Verification instructions (README.txt)

### What to Do With Exported Files

1. **Store securely** on write-protected media
2. **Create backups** in multiple locations
3. **Document who accesses** the files
4. **Keep all files together** (don't separate video from logs)
5. **Verify regularly** that files remain intact

## Understanding Forensic Features

### 🔐 Cryptographic Hashes
- **What:** Unique digital fingerprint of your video
- **Why:** Proves file hasn't been tampered with
- **How:** SHA-256 and SHA-512 algorithms

### ⏰ Timestamp Verification
- **What:** Proof of when recording was created
- **Why:** Establishes timeline of events
- **How:** NTP time servers provide trusted time

### 📋 Chain of Custody
- **What:** Log of everything that happens to the file
- **Why:** Shows proper evidence handling
- **How:** Automatic logging of all operations

### ✓ Integrity Verification
- **What:** Check if file has been modified
- **Why:** Ensures authenticity
- **How:** Compare current hash to original

## Tips for Legal Use

### ✅ DO:
- Record continuously without pausing
- Export forensic package immediately
- Store original files securely
- Document the context of your recording
- Verify files regularly
- Keep all related files together

### ❌ DON'T:
- Edit or modify recordings
- Store only on one device
- Delete supporting log files
- Share without maintaining chain of custody
- Wait to export forensic package

## Common Questions

### Q: Can I edit my recording?
**A:** No. Any editing would invalidate the forensic verification. Record it right the first time.

### Q: What if verification fails?
**A:** If the hash doesn't match, the file has been modified. This doesn't mean the content changed - even minor metadata changes affect the hash. Always preserve originals.

### Q: Do I need internet for recording?
**A:** Recording works offline, but timestamp verification requires internet to contact NTP servers.

### Q: How long can I record?
**A:** Limited only by available storage space. Monitor your device's storage.

### Q: Are these recordings admissible in court?
**A:** The app creates technically sound recordings, but admissibility depends on jurisdiction and circumstances. Consult legal counsel.

## File Locations

### macOS
Recordings saved to:
```
~/Library/Containers/[AppID]/Data/Documents/Recordings/
```

### iOS
Recordings saved to:
```
App Documents/Recordings/
```
(Accessible through Files app)

## Getting Help

### Technical Issues

**Recording won't start:**
- Check permissions in System Settings (macOS) or Settings (iOS)
- Restart the app
- Check available storage space

**Verification fails:**
- Ensure file hasn't been moved or renamed
- Check that .manifest.json file exists
- Verify file hasn't been edited

**Poor quality recording:**
- Close unnecessary apps
- Check available memory
- Ensure sufficient CPU resources

### Legal Questions

For questions about using recordings in legal proceedings:
1. Consult with legal counsel
2. Review FORENSIC_COMPLIANCE.md document
3. Understand your jurisdiction's evidence rules

## Advanced Features

### Hash Verification (Manual)

You can verify files manually:

**macOS/Linux:**
```bash
shasum -a 256 recording.mp4
```

**Windows:**
```bash
certutil -hashfile recording.mp4 SHA256
```

Compare output with hash in manifest.json file.

### Chain of Custody Review

Open the custody_log.json file to see:
- Every operation performed on the file
- Timestamps for each action
- Who performed each action
- Details about what happened

### Forensic Manifest

The manifest.json contains:
- File metadata
- Cryptographic hashes (SHA-256, SHA-512)
- Timestamp verification data
- Device information
- Screen resolution
- App version

## Upgrading

When a new version is available:
1. Export all important recordings first
2. Update the app
3. Verify existing recordings still work
4. Note app version in your documentation

## Privacy & Security

### What Data is Collected?
- Device model and OS version (stored locally)
- Recording metadata (stored locally)
- NTP time requests (minimal data, anonymous)

### Where is Data Stored?
- All recordings and logs stored locally on your device
- No cloud storage or transmission
- You control all files

### Who Can Access Your Recordings?
- Only you, unless you share them
- App does not transmit recordings anywhere
- Export packages are for your use

## Best Practices Summary

1. ✅ Grant all necessary permissions
2. ✅ Test recording before important captures
3. ✅ Record continuously without editing
4. ✅ Export forensic package immediately
5. ✅ Store on multiple devices/locations
6. ✅ Verify recordings regularly
7. ✅ Document context and circumstances
8. ✅ Maintain chain of custody
9. ✅ Consult legal counsel when needed
10. ✅ Keep app updated

## Support

For additional help, see:
- README.md - Technical documentation
- BUILD_GUIDE.md - Build instructions
- FORENSIC_COMPLIANCE.md - Legal compliance details

---

**Remember:** This app is a tool for creating forensically sound recordings. You are responsible for legal compliance and proper evidence handling in your jurisdiction.
