#!/usr/bin/env bash
#
# Build, install and launch WoltSwiftUI on an iOS simulator — without opening Xcode.
#
#   ./run.sh              build, install, launch  (default)
#   ./run.sh build        build only
#   ./run.sh test         run the test suite
#   ./run.sh logs         tail this app's console output
#   ./run.sh stop         terminate the running app
#   ./run.sh clean        delete build artifacts
#
#   DEVICE="iPhone 17e" ./run.sh     target a different simulator
#
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

SCHEME="WoltSwiftUI"
PROJECT="WoltSwiftUI.xcodeproj"
DEVICE="${DEVICE:-iPhone 17 Pro}"
BUILD_DIR="build"
PRODUCTS="$BUILD_DIR/Build/Products/Debug-iphonesimulator"
APP="$PRODUCTS/$SCHEME.app"
LOG="$BUILD_DIR/last-build.log"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
fail() { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

# Resolve the simulator UDID, booting it if necessary, and bring the Simulator app forward.
boot_simulator() {
  local udid
  udid=$(xcrun simctl list devices available \
    | grep -F "$DEVICE (" \
    | head -1 \
    | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')

  [ -n "$udid" ] || fail "No available simulator named '$DEVICE'. See: xcrun simctl list devices available"

  if ! xcrun simctl list devices | grep -F "$udid" | grep -q Booted; then
    bold "Booting $DEVICE..."
    xcrun simctl boot "$udid"
  fi

  open -a Simulator
  echo "$udid"
}

# The bundle id lives in the built app, so it stays correct if the project setting changes.
bundle_id() {
  [ -d "$APP" ] || fail "$APP not found — run './run.sh build' first."
  plutil -extract CFBundleIdentifier raw "$APP/Info.plist"
}

do_build() {
  bold "Building $SCHEME for $DEVICE..."
  mkdir -p "$BUILD_DIR"
  # Full output goes to the log; the console shows only errors, warnings and the result.
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -derivedDataPath "$BUILD_DIR" \
    build \
    | tee "$LOG" \
    | awk '/(error|warning):/ || /^\*\* (BUILD|TEST)/ { print }'
}

case "${1:-run}" in
  run)
    do_build
    udid=$(boot_simulator)
    id=$(bundle_id)
    bold "Installing $id..."
    xcrun simctl install "$udid" "$APP"
    xcrun simctl launch "$udid" "$id" >/dev/null
    bold "Launched. Check the simulator."
    ;;

  build)
    do_build
    ;;

  test)
    bold "Testing $SCHEME on $DEVICE..."
    mkdir -p "$BUILD_DIR"
    xcodebuild \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -destination "platform=iOS Simulator,name=$DEVICE" \
      -derivedDataPath "$BUILD_DIR" \
      test \
      | tee "$LOG" \
      | awk '/(error|warning):/ || /^Test (Case|Suite)/ || /^\*\* TEST/ { print }'
    ;;

  logs)
    udid=$(boot_simulator)
    bold "Streaming logs (Ctrl-C to stop)..."
    xcrun simctl spawn "$udid" log stream --level debug --style compact \
      --predicate "subsystem CONTAINS '$(bundle_id)' OR processImagePath CONTAINS '$SCHEME'"
    ;;

  stop)
    [ -d "$APP" ] || fail "Nothing to stop — $SCHEME has not been built yet."
    udid=$(boot_simulator)
    if xcrun simctl terminate "$udid" "$(bundle_id)" 2>/dev/null; then
      bold "Stopped."
    else
      bold "Not running."
    fi
    ;;

  clean)
    rm -rf "$BUILD_DIR"
    bold "Removed $BUILD_DIR/"
    ;;

  *)
    # Print the header comment block as usage text.
    awk 'NR>2 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"
    exit 1
    ;;
esac
