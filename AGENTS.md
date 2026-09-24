# Agent Rules for Hivemind

## Pre-Commit CI Checks (Mandatory)
Before creating any git commit or pushing changes, ALWAYS execute the local CI verification suite to ensure CI on GitHub Actions will pass:

1. **Code Formatting**:
   ```bash
   fvm dart format --output=none --set-exit-if-changed .
   ```
   If formatting fails, format all files using:
   ```bash
   fvm dart format .
   ```
   and stage the formatted changes.

2. **Static Analysis**:
   ```bash
   fvm flutter analyze
   ```
   Must exit with code 0 and 0 issues found.

3. **Automated Tests**:
   ```bash
   fvm flutter test
   ```
   All unit and widget tests must pass.

**Never commit or push code if any of these three checks fail.**
