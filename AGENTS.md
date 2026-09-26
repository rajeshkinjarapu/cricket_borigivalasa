# Project Rules & Instructions

## 1. Strictly No Background Tasks / No Direct Command Execution
- **DO NOT run commands in the background** (`run_command` with backgrounding, `IsDaemon`, or long-running processes).
- **DO NOT execute commands automatically** when the user asks to run, open, build, or test the app.
- **Always provide copyable command blocks** directly in the response so the user can run them in their own terminal.
- Wait for user response/output rather than running commands autonomously.

## 2. Git Preferences
- Follow user guidelines specified in `.agents/rules/git_preferences.md`.
