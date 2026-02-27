#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# VentExpensePro — Build Script
# ──────────────────────────────────────────────────────────────────────────────
#
# Usage:
#   ./build.sh <command>
#
# Commands:
#   clean         Clean build artifacts
#   debug         Build debug APK
#   apk           Build release APK (fat — all ABIs in one)
#   apk-split     Build release APK split per ABI (arm64, arm, x86_64)
#   aab           Build release App Bundle (for Play Store upload)
#   install       Build debug APK and install on connected device
#   icons         Regenerate launcher icons from 1024.png
#   analyze       Run Flutter static analysis
#   test          Run all unit tests
#   all           Build everything (debug APK + split APKs + AAB)
#
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build/app/outputs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}ℹ  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $1${NC}"; }
error()   { echo -e "${RED}❌ $1${NC}"; exit 1; }

header() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  $1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# ── Pre-flight checks ────────────────────────────────────────────────────────
preflight() {
  if ! command -v flutter &> /dev/null; then
    error "Flutter not found in PATH. Please install Flutter first."
  fi

  info "Running flutter pub get..."
  cd "$PROJECT_DIR"
  flutter pub get
}

# ── Commands ─────────────────────────────────────────────────────────────────

cmd_clean() {
  header "🧹 Cleaning build artifacts"
  cd "$PROJECT_DIR"
  flutter clean
  flutter pub get
  success "Clean complete"
}

cmd_debug() {
  header "🔧 Building Debug APK"
  preflight
  flutter build apk --debug
  success "Debug APK → build/app/outputs/flutter-apk/app-debug.apk"
}

cmd_apk() {
  header "📦 Building Release APK (fat)"
  preflight
  check_signing
  flutter build apk --release --obfuscate --split-debug-info=build/debug-info
  success "Release APK → build/app/outputs/flutter-apk/app-release.apk"
}

cmd_apk_split() {
  header "📦 Building Release APKs (split per ABI)"
  preflight
  check_signing
  flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
  echo ""
  success "Split APKs generated:"
  echo "  • app-arm64-v8a-release.apk   (most modern devices)"
  echo "  • app-armeabi-v7a-release.apk  (older 32-bit devices)"
  echo "  • app-x86_64-release.apk       (emulators / Chromebooks)"
  echo ""
  echo "  Location: build/app/outputs/flutter-apk/"
}

cmd_aab() {
  header "🚀 Building Release App Bundle (Play Store)"
  preflight
  check_signing
  flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
  success "App Bundle → build/app/outputs/bundle/release/app-release.aab"
  echo ""
  info "Upload this .aab file to the Google Play Console."
  info "Debug symbols are in build/debug-info/ (upload to Play Console for crash reports)."
}

cmd_install() {
  header "📱 Building & Installing Debug APK"
  preflight

  if ! adb devices | grep -q "device$"; then
    error "No connected device/emulator found. Start one first."
  fi

  flutter build apk --debug
  adb install -r build/app/outputs/flutter-apk/app-debug.apk
  success "Installed on device"
}

cmd_icons() {
  header "🎨 Regenerating Launcher Icons"
  cd "$PROJECT_DIR"
  flutter pub get
  dart run flutter_launcher_icons
  success "Icons regenerated from 1024.png"
}

cmd_analyze() {
  header "🔍 Running Static Analysis"
  cd "$PROJECT_DIR"
  flutter analyze
  success "Analysis complete"
}

cmd_test() {
  header "🧪 Running Tests"
  cd "$PROJECT_DIR"
  flutter test
  success "All tests passed"
}

cmd_all() {
  header "🏗️  Building Everything"
  cmd_debug
  cmd_apk_split
  cmd_aab
  success "All builds complete!"
}

# ── Helpers ──────────────────────────────────────────────────────────────────

check_signing() {
  local keyfile="$PROJECT_DIR/android/key.properties"
  if [ ! -f "$keyfile" ]; then
    warn "android/key.properties not found — release build will use debug signing."
    warn "For Play Store, create key.properties from key.properties.example."
    echo ""
  fi
}

show_help() {
  echo ""
  echo "VentExpensePro Build Script"
  echo ""
  echo "Usage: ./build.sh <command>"
  echo ""
  echo "Commands:"
  echo "  clean         Clean build artifacts and re-fetch dependencies"
  echo "  debug         Build debug APK"
  echo "  apk           Build release APK (fat — all ABIs in one)"
  echo "  apk-split     Build release APK split per ABI"
  echo "  aab           Build release App Bundle (for Play Store)"
  echo "  install       Build debug APK and install on connected device"
  echo "  icons         Regenerate launcher icons"
  echo "  analyze       Run Flutter static analysis"
  echo "  test          Run all unit tests"
  echo "  all           Build everything (debug + split APKs + AAB)"
  echo ""
}

# ── Entrypoint ───────────────────────────────────────────────────────────────

case "${1:-}" in
  clean)     cmd_clean ;;
  debug)     cmd_debug ;;
  apk)       cmd_apk ;;
  apk-split) cmd_apk_split ;;
  aab)       cmd_aab ;;
  install)   cmd_install ;;
  icons)     cmd_icons ;;
  analyze)   cmd_analyze ;;
  test)      cmd_test ;;
  all)       cmd_all ;;
  *)         show_help ;;
esac
