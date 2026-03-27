# cleaning-keyboard

CLI cho macOS để **vô hiệu hóa bàn phím tạm thời** khi lau chùi máy tính.

## Tính năng

- Khóa toàn bộ phím trong một khoảng thời gian (`--seconds`)
- Có thể bật `Esc` để mở khóa khẩn cấp (`--allow-escape true`)
- Không cần cài thư viện ngoài (dùng Swift + ApplicationServices)

## Yêu cầu

- macOS 12+
- Swift 5.9+
- Terminal/iTerm đã được cấp quyền:
  - `System Settings > Privacy & Security > Accessibility`

## Cách dùng

### Chạy trực tiếp

```bash
swift run cleaning-keyboard --seconds 60 --allow-escape true
```

### Dùng script tiện lợi

```bash
./scripts/clean-keyboard 60
```

Mặc định script sẽ khóa 45 giây nếu bạn không truyền số giây.

## Ví dụ

```bash
# Khóa 2 phút
swift run cleaning-keyboard --seconds 120

# Khóa 30 giây, không cho Esc mở sớm
swift run cleaning-keyboard --seconds 30 --allow-escape false
```

## Lưu ý an toàn

- Nên để `--allow-escape true` để có lối thoát khẩn cấp.
- Nếu chưa cấp quyền Accessibility, app sẽ báo lỗi và không khóa bàn phím.
