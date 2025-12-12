# Forensic Compliance & Legal Documentation

## Overview

This document explains how the Forensic Screen Recorder application meets the requirements for forensically verifiable digital evidence that may be admissible in legal proceedings.

## Legal Standards for Digital Evidence

### Federal Rules of Evidence (United States)

Digital evidence must meet several criteria under the Federal Rules of Evidence:

#### Rule 901 - Authentication
Evidence must be authenticated to show it is what it purports to be.

**How this app complies:**
- Cryptographic hashes (SHA-256/512) prove file integrity
- Timestamp verification links evidence to specific time
- Chain of custody documents all handling
- Device metadata provides source authentication

#### Rule 902 - Self-Authentication
Certain evidence can be self-authenticating.

**How this app complies:**
- Digital signatures and hashes provide self-authentication
- Timestamps from trusted third-party sources (NTP, TSA)
- Automated logging reduces human intervention

#### Rule 1001-1008 - Best Evidence Rule
Original document is required when proving content.

**How this app complies:**
- Files are captured directly without processing
- Original file is never modified
- Chain of custody tracks any access
- `isOriginalFile` flag maintained

## Forensic Verification Features

### 1. Captured Without Post-Editing

**Implementation:**
- Screen content is captured directly to video file
- No intermediate processing or editing
- Recording uses platform APIs (ScreenCaptureKit/ReplayKit)
- Direct write to disk in final format

**Evidence:**
- Chain of custody shows no editing events
- Timestamp continuity from start to completion
- File creation matches recording start time

**Code Reference:**
```swift
// ScreenRecordingManager.swift
// Direct capture to AVAssetWriter - no post-processing
let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
```

### 2. Cryptographic Hash Generated Upon Creation

**Implementation:**
- SHA-256 hash calculated immediately after recording stops
- SHA-512 hash also generated for redundancy
- Both hashes stored in Recording model and manifest file
- Hash calculation logged in chain of custody

**Evidence:**
- Hashes stored with timestamp of generation
- Custody log shows "HASH_GENERATION_COMPLETE" event
- Manifest file contains all cryptographic data

**Code Reference:**
```swift
// CryptographicHashService.swift
func generateHashes(for fileURL: URL) async throws -> (sha256: String, sha512: String)
```

**Verification Process:**
```bash
# Anyone can verify file hasn't been altered
shasum -a 256 recording.mp4
# Compare output to hash in manifest
```

### 3. Timestamps Verifiable via Trusted External Sources

**Implementation:**
- NTP (Network Time Protocol) time verification
- Multiple fallback NTP servers (time.apple.com, time.google.com, time.nist.gov)
- RFC 3161 Timestamp Authority tokens (optional)
- Device time compared with verified time

**Evidence:**
- NTP timestamp stored with server identifier
- Time difference recorded for transparency
- TSA response preserved (when available)
- Timestamp proof document generated

**Code Reference:**
```swift
// TimestampVerificationService.swift
func getVerifiedTimestamp() async throws -> (timestamp: Date, server: String)
func requestTimestampToken(for hash: String) async throws -> (url: String, response: Data)
```

**Trust Chain:**
- NTP servers are operated by trusted organizations (Apple, Google, NIST)
- RFC 3161 TSAs provide legally recognized timestamps
- Multiple sources provide redundancy and verification

### 4. Original File Preserved with Chain of Custody

**Implementation:**
- Recording model tracks `isOriginalFile` status
- Original hash stored for comparison
- Complete audit trail of all file operations
- Chronological logging of every event

**Evidence:**
- Chain of custody JSON file with all events
- Timestamps for each operation
- User identifiers for accountability
- Action descriptions and details

**Code Reference:**
```swift
// ChainOfCustodyService.swift
func logEvent(action: String, details: String, fileURL: URL, userIdentifier: String?)
func verifyChainIntegrity(for fileURL: URL) async throws -> ChainVerificationResult
```

**Custody Events Tracked:**
- RECORDING_START
- RECORDING_COMPLETE
- HASH_GENERATION_START
- HASH_GENERATION_COMPLETE
- TIMESTAMP_VERIFICATION_START
- TIMESTAMP_VERIFICATION_COMPLETE
- TSA_TOKEN_RECEIVED / TSA_TOKEN_FAILED
- MANIFEST_CREATED
- Any file access or export operations

### 5. Supporting Logs Retained

**Implementation:**
- Chain of custody log persisted as JSON
- Forensic manifest with all metadata
- Device information captured
- All logs included in forensic export package

**Evidence:**
- custody_log.json with complete audit trail
- manifest.json with cryptographic data
- README.txt with verification instructions
- All files timestamped and cross-referenced

## Forensic Export Package

When a recording is exported for legal purposes, the package includes:

### 1. Original Recording File
- Unmodified video file (.mp4)
- Exact file as recorded
- No compression or transcoding

### 2. Forensic Manifest (JSON)
```json
{
  "filename": "recording_1234567890.mp4",
  "sha256": "abc123...",
  "sha512": "def456...",
  "created_at": "2025-12-11T10:30:00Z",
  "file_size": 15000000,
  "device_model": "MacBook Pro",
  "os_version": "14.0",
  "screen_resolution": "2560x1600",
  "ntp_timestamp": "2025-12-11T10:30:01Z",
  "ntp_server": "time.apple.com"
}
```

### 3. Chain of Custody Log (JSON)
```json
{
  "file_url": "/path/to/recording.mp4",
  "file_name": "recording_1234567890.mp4",
  "total_events": 8,
  "events": [
    {
      "timestamp": "2025-12-11T10:30:00Z",
      "action": "RECORDING_START",
      "details": "Screen recording initiated",
      "user": "username"
    },
    // ... additional events
  ]
}
```

### 4. Verification README
- Instructions for hash verification
- Explanation of forensic features
- Legal notice about authenticity
- Contact information

## Verification Process for Legal Review

### Step 1: Verify File Integrity

```bash
# Calculate hash of video file
shasum -a 256 recording.mp4

# Compare with hash in manifest.json
# Hashes must match exactly
```

**Result:** Proves file has not been altered since creation.

### Step 2: Review Chain of Custody

```bash
# Open custody_log.json
# Check for:
# - Chronological order of events
# - No suspicious time gaps
# - All required events present
# - Consistent user identifiers
```

**Result:** Proves proper handling and no tampering.

### Step 3: Verify Timestamps

```bash
# Compare timestamps:
# - Device time (created_at)
# - NTP time (ntp_timestamp)
# - Time recorded in custody log
# 
# Verify time difference is reasonable (< 5 seconds typically)
```

**Result:** Proves recording was created at claimed time.

### Step 4: Examine Metadata

```bash
# Review device information in manifest.json
# - Device model
# - OS version
# - Screen resolution
# - App version
#
# Verify consistency with expected source
```

**Result:** Authenticates source of recording.

### Step 5: Check for Modifications

```bash
# In Recording object:
# - isOriginalFile should be true
# - originalFileHash should match current hash
#
# In custody log:
# - No EDIT or MODIFY events
# - Only READ and EXPORT events after creation
```

**Result:** Confirms original, unedited file.

## Expert Witness Testimony

If expert testimony is required, the following can be explained:

### Technical Foundation

1. **Cryptographic Hashes:**
   - SHA-256 is a cryptographic hash function
   - Produces unique 256-bit fingerprint
   - Collision probability: ~1 in 2^256 (effectively impossible)
   - Any modification changes hash completely

2. **NTP Timestamp Verification:**
   - Network Time Protocol is internet standard (RFC 5905)
   - Used by global infrastructure for time synchronization
   - Accuracy typically within milliseconds
   - Multiple independent sources provide verification

3. **Chain of Custody:**
   - Automated logging reduces human error
   - Cryptographic timestamps for each event
   - Cannot be retroactively modified without detection
   - Chronological integrity verification

### Admissibility Arguments

**Relevance:** Recording directly depicts events at issue

**Authentication:** Multiple layers of authentication:
- Cryptographic hashes prove integrity
- Timestamps prove timing
- Metadata proves source
- Chain of custody proves proper handling

**Reliability:** 
- Automated capture reduces human bias
- No post-processing or editing
- Industry-standard cryptographic methods
- Redundant verification mechanisms

**Best Evidence:** Original digital file with complete audit trail

## Limitations and Disclaimers

### Technical Limitations

1. **NTP Accuracy:** 
   - Dependent on network conditions
   - Typically accurate within 1-100ms
   - Cannot guarantee atomic clock precision

2. **Timestamp Authority:**
   - Optional feature, may not always succeed
   - Dependent on TSA availability
   - Not required for basic verification

3. **Platform Differences:**
   - macOS and iOS use different capture mechanisms
   - Quality and capabilities vary by platform
   - Document platform used in each case

### Legal Limitations

1. **Jurisdiction Specific:**
   - Evidence rules vary by jurisdiction
   - Some courts may require additional authentication
   - Consult local counsel

2. **Not a Substitute for Proper Procedure:**
   - Still requires proper evidence handling
   - Should be accompanied by testimony
   - Context and circumstances matter

3. **Recording Laws:**
   - User must comply with recording consent laws
   - Some jurisdictions require all-party consent
   - Privacy considerations apply

## Best Practices for Legal Use

### Before Recording

1. Ensure legal right to record
2. Obtain necessary consents
3. Document purpose and circumstances
4. Note date, time, and location

### During Recording

1. Do not edit or pause unnecessarily
2. Minimize application switching
3. Include context in recording
4. Note any technical issues

### After Recording

1. Export forensic package immediately
2. Store on write-protected media
3. Create backup copies
4. Document who has custody

### For Court Submission

1. Provide complete forensic package
2. Include affidavit of creation
3. Document chain of custody
4. Retain original indefinitely
5. Make available for opposing party verification

## Compliance Checklist

Use this checklist for each recording intended for legal use:

- [ ] Recording created without editing
- [ ] SHA-256 and SHA-512 hashes generated
- [ ] Hash values documented and stored
- [ ] NTP timestamp obtained and recorded
- [ ] Device metadata captured
- [ ] Chain of custody log created
- [ ] Forensic manifest generated
- [ ] All files exported as package
- [ ] Original file preserved
- [ ] Backup copies created
- [ ] Verification performed
- [ ] Documentation completed
- [ ] Proper storage implemented
- [ ] Chain of custody maintained

## Contact for Legal Inquiries

For questions regarding forensic verification features or expert testimony, contact:

[Your contact information here]

---

**Document Version:** 1.0  
**Last Updated:** December 11, 2025  
**Next Review:** As needed for legal updates
