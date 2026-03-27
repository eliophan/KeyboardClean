#!/usr/bin/env bash
set -euo pipefail

REPO="${KEYBOARD_CLEAN_REPO:-eliophan/keyboard-clean}"
REF="${KEYBOARD_CLEAN_REF:-main}"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${REF}"
INSTALL_DIR="${KEYBOARD_CLEAN_INSTALL_DIR:-$HOME/.local/bin}"

download() {
  local url="$1"
  local out="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$out"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO "$out" "$url"
    return
  fi

  echo "Neither curl nor wget is installed." >&2
  exit 1
}

print_path_hint() {
  case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *)
      echo
      echo "Add this to your shell profile to use keyboard-clean directly:"
      echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
      ;;
  esac
}

mkdir -p "$INSTALL_DIR"

case "$(uname -s)" in
  Darwin)
    if ! command -v swiftc >/dev/null 2>&1; then
      echo "swiftc is required on macOS. Install Xcode Command Line Tools first." >&2
      exit 1
    fi

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' EXIT
    src_file="$tmp_dir/main.swift"
    bin_file="$INSTALL_DIR/keyboard-clean"
    cmd_file="$INSTALL_DIR/keyboard-clean"

    download "$BASE_URL/Sources/keyboard-clean/main.swift" "$src_file"
    swiftc -O -framework ApplicationServices "$src_file" -o "$bin_file"

    cat >"$cmd_file" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

SECONDS_TO_LOCK="${1:-45}"
ALLOW_ESCAPE="${ALLOW_ESCAPE:-true}"

"$(dirname "$0")/keyboard-clean" --seconds "$SECONDS_TO_LOCK" --allow-escape "$ALLOW_ESCAPE"
EOF

    chmod +x "$bin_file" "$cmd_file"

    echo "Installed keyboard-clean to $INSTALL_DIR (macOS mode)."
    print_path_hint
    ;;
  Linux)
    cmd_file="$INSTALL_DIR/keyboard-clean"
    download "$BASE_URL/scripts/keyboard-clean-linux" "$cmd_file"
    chmod +x "$cmd_file"

    echo "Installed keyboard-clean to $INSTALL_DIR (Linux mode)."
    echo "Note: Requires X11 and xinput at runtime."
    print_path_hint
    ;;
  *)
    echo "Unsupported OS for install.sh: $(uname -s)" >&2
    echo "For Windows, use install.ps1 instead." >&2
    exit 1
    ;;
esac

echo
echo "Run: keyboard-clean 60"
