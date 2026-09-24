---
trigger: always_on
description: Always enforce local CI checks (formatting, analysis, tests) before committing code.
---

# Pre-Commit CI Checks Rule

Before creating any git commit or recommending/executing a commit:

1. **Verify / Apply Code Formatting**:
   Run `fvm dart format --output=none --set-exit-if-changed .`.
   If files need formatting, run `fvm dart format .` and ensure the formatted files are staged.

2. **Run Linter / Static Analysis**:
   Run `fvm flutter analyze`.
   Fix any analyzer errors, warnings, or lints before proceeding.

3. **Run Unit & Widget Tests**:
   Run `fvm flutter test`.
   All tests must pass.

Do not commit code unless all three checks succeed.
