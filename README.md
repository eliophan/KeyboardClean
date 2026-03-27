# cleaning-keyboard

A macOS CLI to temporarily disable keyboard input while you clean your computer.

## Features

- Blocks all key events for a configurable duration (`--seconds`)
- Optional emergency unlock with `Esc` (`--allow-escape true`)
- No external dependencies (Swift + ApplicationServices)

## Requirements

- macOS 12+
- Swift 5.9+
- Accessibility permission for Terminal/iTerm:
  - `System Settings > Privacy & Security > Accessibility`

## Usage

### Run directly

```bash
swift run cleaning-keyboard --seconds 60 --allow-escape true
```

### Use helper script

```bash
./scripts/clean-keyboard 60
```

If you omit the argument, the script defaults to 45 seconds. On first run, it auto-builds with `swift build` if the binary does not exist.

## Examples

```bash
# Lock for 2 minutes
swift run cleaning-keyboard --seconds 120

# Lock for 30 seconds, disable Esc early unlock
swift run cleaning-keyboard --seconds 30 --allow-escape false
```

## Safety notes

- Keep `--allow-escape true` unless you have another way to recover input.
- If Accessibility permission is missing, the program exits without locking the keyboard.
