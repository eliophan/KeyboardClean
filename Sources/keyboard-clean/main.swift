import Foundation
import ApplicationServices

final class KeyboardLocker {
    private let allowEscape: Bool
    private let onEscape: () -> Void
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(allowEscape: Bool, onEscape: @escaping () -> Void) {
        self.allowEscape = allowEscape
        self.onEscape = onEscape
    }

    func start() -> Bool {
        let eventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else {
                return Unmanaged.passUnretained(event)
            }

            let locker = Unmanaged<KeyboardLocker>.fromOpaque(refcon).takeUnretainedValue()

            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = locker.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passUnretained(event)
            }

            if type == .keyDown || type == .keyUp || type == .flagsChanged {
                if locker.allowEscape {
                    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                    if keyCode == 53 {
                        locker.onEscape()
                        return Unmanaged.passUnretained(event)
                    }
                }
                return nil
            }

            return Unmanaged.passUnretained(event)
        }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: refcon
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        guard let source = runLoopSource else {
            return false
        }

        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        runLoopSource = nil
        eventTap = nil
    }
}

func printUsage() {
    let text = """
    Usage:
      keyboard-clean [--seconds N] [--allow-escape true|false]

    Defaults:
      --seconds 45
      --allow-escape true

    Notes:
      - Accessibility permission is required for Terminal/iTerm.
      - Press Esc for early unlock when --allow-escape=true.
    """
    print(text)
}

struct Config {
    var seconds: Int = 45
    var allowEscape: Bool = true
}

func parseArgs() -> Config? {
    var config = Config()
    var index = 1
    let args = CommandLine.arguments

    while index < args.count {
        let arg = args[index]

        switch arg {
        case "--help", "-h":
            printUsage()
            exit(0)
        case "--seconds":
            guard index + 1 < args.count, let value = Int(args[index + 1]), value > 0 else {
                fputs("Invalid value for --seconds.\\n", stderr)
                return nil
            }
            config.seconds = value
            index += 1
        case "--allow-escape":
            guard index + 1 < args.count else {
                fputs("Missing value for --allow-escape.\\n", stderr)
                return nil
            }
            let value = args[index + 1].lowercased()
            if value == "true" {
                config.allowEscape = true
            } else if value == "false" {
                config.allowEscape = false
            } else {
                fputs("--allow-escape must be true or false.\\n", stderr)
                return nil
            }
            index += 1
        default:
            fputs("Unknown argument: \(arg)\\n", stderr)
            return nil
        }

        index += 1
    }

    return config
}

guard let config = parseArgs() else {
    printUsage()
    exit(2)
}

var shouldStopEarly = false
let locker = KeyboardLocker(allowEscape: config.allowEscape) {
    shouldStopEarly = true
}

guard locker.start() else {
    fputs(
        "Cannot lock keyboard. Grant Accessibility permission to Terminal/iTerm in System Settings > Privacy & Security > Accessibility.\\n",
        stderr
    )
    exit(1)
}

print("Keyboard locked for \(config.seconds) seconds. Start cleaning now.")
if config.allowEscape {
    print("Press Esc to unlock early.")
}

let deadline = Date().addingTimeInterval(TimeInterval(config.seconds))
var lastPrinted: Int?

while !shouldStopEarly {
    let remaining = Int(ceil(deadline.timeIntervalSinceNow))
    if remaining <= 0 {
        break
    }

    if remaining != lastPrinted && (remaining <= 10 || remaining % 10 == 0) {
        print("Remaining: \(remaining) seconds")
        lastPrinted = remaining
    }

    _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.1))
}

locker.stop()

if shouldStopEarly {
    print("Keyboard unlocked (Esc).")
} else {
    print("Keyboard unlocked.")
}
