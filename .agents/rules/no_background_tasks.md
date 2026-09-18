# No Background Tasks

The user explicitly requested that no terminal commands should be run in the background.

**Rule:**
Whenever you need to run a terminal command, do **NOT** use the `run_command` tool in the background or use any tool that executes commands without the user's direct involvement. Instead, format the command nicely in a markdown block, present it to the user, and ask them to copy and run it in their own terminal. Wait for them to provide the output before proceeding.
