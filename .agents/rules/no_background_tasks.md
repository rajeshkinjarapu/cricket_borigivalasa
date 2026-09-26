# Critical Rule: Never Run Background Tasks or Commands Directly

The user strictly forbids running commands or tasks in the background.

## Mandatory Instructions:
1. **NEVER use `run_command`** to run servers, scripts, builds, or tests in the background (no `IsDaemon: true`, no background tasks).
2. **DO NOT execute commands automatically** when the user asks to run, open, test, build, or deploy anything.
3. **Always provide the command as a copyable markdown code block**:
   - Provide the exact command(s) cleanly formatted.
   - Ask the user to copy and run it in their terminal.
   - Wait for the user to provide output or confirm before proceeding.
