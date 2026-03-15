#!/usr/bin/env bash
# setup.sh — Rylai Project Setup Script
# Usage: cd Rylai && bash setup.sh

set -e

echo ""
echo "╔══════════════════════════════╗"
echo "║       Rylai ❄️               ║"
echo "║  macOS Wallpaper App         ║"
echo "╚══════════════════════════════╝"
echo ""

# ── 1. Check macOS ────────────────────────────────────────────
OS=$(uname -s)
if [ "$OS" != "Darwin" ]; then
    echo "❌ This project requires macOS. Current system: $OS"
    exit 1
fi

# ── 2. Check Homebrew ─────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    echo "📦 Homebrew not found, installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
echo "✅ Homebrew ready"

# ── 3. Check XcodeGen ────────────────────────────────────────
if ! command -v xcodegen &>/dev/null; then
    echo "📦 Installing XcodeGen..."
    brew install xcodegen
fi
echo "✅ XcodeGen $(xcodegen --version 2>/dev/null || echo '') ready"

# ── 4. Check Xcode ────────────────────────────────────────────
if ! command -v xcodebuild &>/dev/null; then
    echo "❌ Xcode not found. Please install Xcode from the App Store first."
    exit 1
fi
XCODE_VER=$(xcodebuild -version 2>/dev/null | head -1)
echo "✅ $XCODE_VER ready"

# ── 5. Generate .xcodeproj ────────────────────────────────────
echo ""
echo "🔨 Generating Rylai.xcodeproj..."
xcodegen generate --spec project.yml

if [ -d "Rylai.xcodeproj" ]; then
    echo "✅ Rylai.xcodeproj generated successfully!"
else
    echo "❌ xcodeproj generation failed. Please check project.yml"
    exit 1
fi

# ── 6. Done ───────────────────────────────────────────────────
echo ""
echo "🎉 All set!"
echo ""
echo "Next steps:"
echo "  1. open Rylai.xcodeproj"
echo "  2. Select My Mac target and click ▶ Run"
echo "  3. A 🖼️ icon will appear in the menu bar — enjoy!"
echo ""
echo "Notes:"
echo "  • A built-in Unsplash API Key is included for quick testing"
echo "  • First launch requires System Events access permission"
echo ""

# Optional: open project in Xcode
read -rp "Open Xcode now? (y/n) " OPEN
if [[ "$OPEN" == "y" || "$OPEN" == "Y" ]]; then
    open Rylai.xcodeproj
fi
