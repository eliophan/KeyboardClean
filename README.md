# keyboard-clean

A cross-platform CLI to temporarily lock keyboard input while you clean your computer.

## What it does

- Locks keyboard input for a configurable duration.
- Keeps mouse/trackpad active.
- Supports macOS, Linux (X11), and Windows.

## Platform behavior

- macOS: Keyboard lock via event tap, optional early unlock with `Esc`.
- Linux (X11): Disables keyboard devices via `xinput`.
- Windows: Keyboard-only lock via low-level keyboard hook.

## Requirements

### macOS

- macOS 12+
- Swift 5.9+
- Accessibility permission for Terminal/iTerm:
  `System Settings > Privacy & Security > Accessibility`

### Linux

- X11 session (`DISPLAY` is set)
- `xinput` installed

### Windows

- Windows PowerShell or PowerShell 7
- Run in Windows (not WSL)
- If keyboard hook fails, run terminal as Administrator

## Quick install (no clone)

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/eliophan/keyboard-clean/main/install.sh | bash
```

Run after install:

```bash
keyboard-clean 60
```

### Windows

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/eliophan/keyboard-clean/main/install.ps1 | iex"
```

Run after install (open a new terminal first):

```powershell
keyboard-clean 60
```

## Verify installation

```bash
keyboard-clean 10
```

Expected behavior:

- Countdown prints in terminal.
- Keyboard unlocks automatically when timer ends.

## Command reference

### Installed command (recommended)

```bash
keyboard-clean [SECONDS]
```

- Default `SECONDS` is `45`.
- Example: `keyboard-clean 120`

### From source (helper script)

```bash
./scripts/keyboard-clean [SECONDS]
```

### macOS direct binary usage

```bash
swift run keyboard-clean --seconds 60 --allow-escape true
```

Options:

- `--seconds N` (required positive integer if provided)
- `--allow-escape true|false` (macOS only)

### Windows direct usage

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\keyboard-clean-windows.ps1 -Seconds 60
```

## Common examples

### Lock for 2 minutes

```bash
keyboard-clean 120
```

### macOS: disable Esc early unlock

```bash
swift run keyboard-clean --seconds 30 --allow-escape false
```

### Install to custom location (macOS/Linux)

```bash
KEYBOARD_CLEAN_INSTALL_DIR="$HOME/bin" curl -fsSL https://raw.githubusercontent.com/eliophan/keyboard-clean/main/install.sh | bash
```

### Install from a different repo/ref (macOS/Linux)

```bash
KEYBOARD_CLEAN_REPO="owner/repo" KEYBOARD_CLEAN_REF="branch-or-tag" curl -fsSL https://raw.githubusercontent.com/eliophan/keyboard-clean/main/install.sh | bash
```

## Update

### macOS / Linux

Re-run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/eliophan/keyboard-clean/main/install.sh | bash
```

### Windows

Re-run the installer:

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/eliophan/keyboard-clean/main/install.ps1 | iex"
```

## Uninstall

### macOS / Linux

```bash
rm -f "$HOME/.local/bin/keyboard-clean"
```

If you installed to a custom directory, remove that binary there instead.

### Windows

Default install path:

- `%LOCALAPPDATA%\keyboard-clean\keyboard-clean.ps1`
- `%LOCALAPPDATA%\keyboard-clean\keyboard-clean.cmd`

Remove the folder if you no longer need it:

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\keyboard-clean"
```

## Troubleshooting

### `keyboard-clean: command not found`

- Open a new terminal session.
- Ensure install directory is in `PATH`.
- On macOS/Linux default path should include `$HOME/.local/bin`.

### macOS: `Cannot lock keyboard... Accessibility permission`

Grant permission to your terminal app in:

`System Settings > Privacy & Security > Accessibility`

Then re-run the command.

### Linux: `xinput is required` or `DISPLAY is not set`

- Install `xinput`.
- Run inside an X11 desktop session (not headless shell).

### Windows: failed to lock keyboard

- Retry in Administrator terminal.
- Make sure you are running in Windows, not WSL.

## Safety notes

- Keep `--allow-escape true` on macOS unless you explicitly want no early unlock.
- Linux and Windows do not support Esc early unlock while keyboard lock is active.
- Always test with a short duration first (for example `keyboard-clean 10`).
