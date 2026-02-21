# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in mdviewer, please report it responsibly.

### How to Report

**Do not** open a public issue. Instead:

1. Email security concerns to: [security@example.com] (replace with actual email)
2. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 5 business days
- **Fix Timeline**: Based on severity
  - Critical: 7 days
  - High: 30 days
  - Medium: 90 days
  - Low: Next release

### Security Measures

This project implements:

- Code signing for releases
- Dependency scanning with Dependabot
- Secrets scanning with TruffleHog
- Static analysis with SwiftLint
- Memory safety with Swift 6 strict concurrency

### Best Practices for Users

1. Only download from official releases
2. Verify checksums when available
3. Keep the app updated
4. Report suspicious behavior

## Security-Related Configuration

### Code Signing

Releases are signed with Apple Developer ID. To verify:

```bash
codesign -dv --verbose=4 /Applications/md.app
```

### Sandboxing

The app uses macOS app sandboxing with minimal entitlements:

- File read access (user-selected files)
- No network access
- No camera/microphone access
