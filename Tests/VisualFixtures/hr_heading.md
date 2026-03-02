Some introductory paragraph with enough text to establish a clear baseline alignment for the reader.

- Fix approach: Add FileManager existence check before `p.run()`, and log errors if creation fails.
- Workaround: Check `/Applications/SketchyBar.app/Contents/Helpers/` permissions.

---

## Security Considerations

**Environment Variable Exposure in Process Launch:**

Risk: `NotificationManager.setupBinaryPath()` and other functions read `CONFIG_DIR` from process environment. If inherited from a parent shell with malicious env vars, the app may behave unexpectedly.

---

## Another Section

Paragraph after second rule to verify multiple HRs work consistently.
