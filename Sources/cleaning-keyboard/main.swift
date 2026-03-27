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
    Cách dùng:
      cleaning-keyboard [--seconds N] [--allow-escape true|false]

    Mặc định:
      --seconds 45
      --allow-escape true

    Ghi chú:
      - Yêu cầu cấp quyền Accessibility cho Terminal/iTerm.
      - Nhấn Esc để thoát sớm khi --allow-escape=true.
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
                fputs("Giá trị --seconds không hợp lệ.\\n", stderr)
                return nil
            }
            config.seconds = value
            index += 1
        case "--allow-escape":
            guard index + 1 < args.count else {
                fputs("Thiếu giá trị cho --allow-escape.\\n", stderr)
                return nil
            }
            let value = args[index + 1].lowercased()
            if value == "true" {
                config.allowEscape = true
            } else if value == "false" {
                config.allowEscape = false
            } else {
                fputs("--allow-escape phải là true hoặc false.\\n", stderr)
                return nil
            }
            index += 1
        default:
            fputs("Tham số không hỗ trợ: \(arg)\\n", stderr)
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
    CFRunLoopStop(CFRunLoopGetCurrent())
}

guard locker.start() else {
    fputs(
        "Không thể khóa bàn phím. Hãy cấp quyền Accessibility cho Terminal/iTerm trong System Settings > Privacy & Security > Accessibility.\\n",
        stderr
    )
    exit(1)
}

print("Đã khóa bàn phím trong \(config.seconds) giây. Bắt đầu lau bàn phím ngay bây giờ.")
if config.allowEscape {
    print("Nhấn Esc để mở khóa sớm.")
}

var remaining = config.seconds
let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
    remaining -= 1

    if remaining <= 0 {
        timer.invalidate()
        CFRunLoopStop(CFRunLoopGetCurrent())
        return
    }

    if remaining <= 10 || remaining % 10 == 0 {
        print("Còn lại: \(remaining) giây")
    }
}

RunLoop.current.run()
timer.invalidate()
locker.stop()

if shouldStopEarly {
    print("Đã mở khóa bàn phím (Esc).")
} else {
    print("Đã mở khóa bàn phím.")
}
