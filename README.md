# cleaning-keyboard

A CLI to temporarily disable keyboard input while you clean your computer.

## Features

- Locks keyboard input for a configurable duration (`--seconds`)
- macOS: optional emergency unlock with `Esc` (`--allow-escape true`)
- Linux (X11): disables keyboard devices via `xinput`
- Windows: blocks user input with PowerShell (`BlockInput`)

## Requirements

### macOS

- macOS 12+
- Swift 5.9+
- Accessibility permission for Terminal/iTerm:
  - `System Settings > Privacy & Security > Accessibility`

### Linux

- X11 session (`DISPLAY` must be set)
- `xinput` installed

### Windows

- Windows PowerShell / PowerShell 7
- Run in a Windows session (not WSL)
- If input lock fails, run terminal as Administrator

## Usage

### Run directly

```bash
swift run cleaning-keyboard --seconds 60 --allow-escape true
```

This direct command is for macOS.

### Use helper script

```bash
./scripts/clean-keyboard 60
```

If you omit the argument, the script defaults to 45 seconds.
- On macOS, it auto-builds with `swift build` if the binary does not exist.
- On Linux, it uses `xinput` to disable and re-enable keyboard devices.
- On Windows, it runs `scripts/clean-keyboard-windows.ps1` with `powershell.exe`.

### Windows direct usage

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\clean-keyboard-windows.ps1 -Seconds 60
```

## Examples

```bash
# Lock for 2 minutes
./scripts/clean-keyboard 120

# macOS only: disable Esc early unlock
swift run cleaning-keyboard --seconds 30 --allow-escape false
```

## Safety notes

- Keep `--allow-escape true` unless you have another way to recover input.
- On Linux, Esc early unlock is not available when all keyboard devices are disabled.
- On Windows, both keyboard and mouse are blocked until timeout.
