#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPAIR_SCRIPT="$SCRIPT_DIR/repair_ios_project_base_config.rb"
ENV_FILE="$PROJECT_ROOT/.env"
LEGACY_ENV_FILE="$PROJECT_ROOT/.env.amap.local"
WORKSPACE_PATH="$PROJECT_ROOT/ios/Runner.xcworkspace"
PROJECT_PATH="$PROJECT_ROOT/ios/Runner.xcodeproj"
DEFAULT_TARGET="lib/main.dart"
DEFAULT_DERIVED_DATA_PATH="$PROJECT_ROOT/build/ios_device_attach"
BUILD_CONFIGURATION="Debug"
SCHEME="Runner"
FLAVOR=""
TARGET_PATH="$DEFAULT_TARGET"
DERIVED_DATA_PATH="$DEFAULT_DERIVED_DATA_PATH"
DEVICE_QUERY=""
DRY_RUN=false
ATTACH_AFTER_LAUNCH=true
DEVICE_TIMEOUT="30"
LAUNCH_TIMEOUT="30"
PROCESS_QUERY_TIMEOUT="20"
LAUNCH_HELPER_PID=""

if [[ ! -f "$ENV_FILE" && -f "$LEGACY_ENV_FILE" ]]; then
  ENV_FILE="$LEGACY_ENV_FILE"
fi

typeset -a TEMP_FILES=()

typeset -a FLUTTER_DEFINE_ARGS=()
typeset -a FLUTTER_ATTACH_ARGS=()
typeset -a IOS_LAUNCH_ARGS=(
  --enable-dart-profiling
  --disable-service-auth-codes
  --enable-checked-mode
  --verify-entry-points
  --vm-service-port=0
)

cleanup() {
  local exit_code=$?
  if [[ -n "$LAUNCH_HELPER_PID" ]] && kill -0 "$LAUNCH_HELPER_PID" 2>/dev/null; then
    kill "$LAUNCH_HELPER_PID" 2>/dev/null || true
    wait "$LAUNCH_HELPER_PID" 2>/dev/null || true
  fi

  local temp_file
  for temp_file in "${TEMP_FILES[@]}"; do
    [[ -f "$temp_file" ]] && rm -f "$temp_file"
  done

  exit "$exit_code"
}

trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run_ios_device_with_attach.sh --device <udid-or-name> [options]

Options:
  --device <udid-or-name>         Required. Flutter-visible iOS device name or UDID.
  --target <path>                 Flutter target entrypoint. Defaults to lib/main.dart.
  --flavor <name>                 Optional Flutter flavor / Xcode scheme name.
  --derived-data-path <path>      Optional Xcode DerivedData output path.
  --dart-define <key=value>       Repeated Flutter dart define passed to config-only build and attach.
  --dart-define-from-file <path>  Repeated define file passed to config-only build and attach.
  --device-timeout <seconds>      Timeout passed to flutter attach. Defaults to 30.
  --attach-arg <arg>              Extra argument forwarded to flutter attach. Repeated.
  --no-attach                     Build, install, and launch only; skip flutter attach.
  --dry-run                       Print commands without executing build/install/launch.
  -h, --help                      Show this help.

Notes:
  - iOS AMap key is read from the project root .env via iOS xcconfig includes.
  - This script avoids flutter run on iOS devices. It uses:
      1) flutter build ios --config-only
      2) repair_ios_project_base_config.rb
      3) xcodebuild install
      4) xcrun devicectl launch
      5) flutter attach
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      DEVICE_QUERY="${2:-}"
      shift 2
      ;;
    --target)
      TARGET_PATH="${2:-}"
      shift 2
      ;;
    --flavor)
      FLAVOR="${2:-}"
      SCHEME="${2:-}"
      shift 2
      ;;
    --derived-data-path)
      DERIVED_DATA_PATH="${2:-}"
      shift 2
      ;;
    --dart-define)
      if [[ "${2:-}" == AMAP_IOS_KEY=* ]]; then
        echo "Ignoring --dart-define ${2:-} for iOS. AMAP_IOS_KEY is read from the project root .env by Xcode." >&2
      else
        FLUTTER_DEFINE_ARGS+=("$1" "${2:-}")
      fi
      shift 2
      ;;
    --dart-define-from-file)
      FLUTTER_DEFINE_ARGS+=("$1" "${2:-}")
      shift 2
      ;;
    --device-timeout)
      DEVICE_TIMEOUT="${2:-}"
      shift 2
      ;;
    --attach-arg)
      FLUTTER_ATTACH_ARGS+=("${2:-}")
      shift 2
      ;;
    --no-attach)
      ATTACH_AFTER_LAUNCH=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      FLUTTER_ATTACH_ARGS+=("$@")
      break
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$DEVICE_QUERY" ]]; then
  echo "--device is required" >&2
  usage >&2
  exit 1
fi

resolve_ios_device_field() {
  local query="$1"
  local field="$2"
  flutter devices --machine | ruby -rjson -e '
    query = ARGV[0]
    field = ARGV[1]
    devices = JSON.parse(STDIN.read)
    candidates = devices.select do |device|
      device["targetPlatform"] == "ios" &&
        device["emulator"] != true &&
        [device["id"], device["name"]].compact.any? { |value| value == query || value.start_with?(query) }
    end

    exact_matches = candidates.select do |device|
      [device["id"], device["name"]].compact.include?(query)
    end
    candidates = exact_matches unless exact_matches.empty?

    if candidates.empty?
      abort("No matching attached iOS device found for #{query.inspect}.")
    end
    if candidates.length > 1
      abort("Multiple iOS devices match #{query.inspect}: #{candidates.map { |device| "#{device["name"]} (#{device["id"]})" }.join(", ")}")
    end

    value = candidates.first[field]
    abort("Resolved device is missing #{field}.") if value.nil? || value.to_s.empty?
    puts value
  ' "$query" "$field"
}

add_default_web_key_define() {
  local has_web_key_define=false
  local index=1
  while [[ $index -le ${#FLUTTER_DEFINE_ARGS[@]} ]]; do
    local arg="${FLUTTER_DEFINE_ARGS[$index]}"
    if [[ "$arg" == "--dart-define" ]]; then
      local value="${FLUTTER_DEFINE_ARGS[$((index + 1))]}"
      if [[ "$value" == AMAP_WEB_KEY=* ]]; then
        has_web_key_define=true
        break
      fi
      if [[ "$value" == AMAP_IOS_KEY=* ]]; then
        echo "Ignoring --dart-define ${value} for iOS. AMAP_IOS_KEY is read from the project root .env by Xcode." >&2
      fi
      index=$((index + 2))
      continue
    fi
    index=$((index + 2))
  done

  if [[ "$has_web_key_define" == false && -f "$ENV_FILE" ]]; then
    local web_key
    web_key="$(sed -n 's/^AMAP_WEB_KEY=//p' "$ENV_FILE" | head -n 1)"
    if [[ -n "$web_key" ]]; then
      FLUTTER_DEFINE_ARGS+=(--dart-define "AMAP_WEB_KEY=$web_key")
    fi
  fi
}

run_cmd() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

make_temp_file() {
  local prefix="$1"
  local file
  file="$(mktemp -t "$prefix")"
  TEMP_FILES+=("$file")
  printf '%s\n' "$file"
}

find_built_app_path() {
  find "$DERIVED_DATA_PATH" -type d \
    \( -path "*/InstallationBuildProductsLocation/Applications/*.app" -o -path "*/Build/Products/${BUILD_CONFIGURATION}-iphoneos/*.app" \) \
    | head -n 1
}

find_running_app_pids() {
  local executable_name="$1"
  local app_bundle_name="$2"
  local process_json
  process_json="$(make_temp_file "ios-device-processes")"

  xcrun devicectl device info processes \
    --device "$DEVICE_ID" \
    --timeout "$PROCESS_QUERY_TIMEOUT" \
    --json-output "$process_json" \
    >/dev/null 2>&1 || return 1

  ruby -rjson -e '
    process_json = ARGV[0]
    executable_name = ARGV[1]
    app_bundle_name = ARGV[2]

    running_processes = JSON.parse(File.read(process_json)).dig("result", "runningProcesses") || []
    matching_pids = running_processes.map do |process|
      executable = process["executable"].to_s
      next unless executable.end_with?("/#{app_bundle_name}/#{executable_name}")

      process["processIdentifier"]
    end.compact

    puts matching_pids.join("\n")
  ' "$process_json" "$executable_name" "$app_bundle_name"
}

terminate_running_app_instances() {
  local executable_name="$1"
  local app_bundle_name="$2"
  local running_pids
  running_pids="$(find_running_app_pids "$executable_name" "$app_bundle_name" || true)"

  if [[ -z "$running_pids" ]]; then
    return 0
  fi

  echo "Stopping existing ${app_bundle_name} processes on $DEVICE_NAME..."

  local pid
  while IFS= read -r pid; do
    [[ -z "$pid" ]] && continue
    xcrun devicectl device process signal \
      --device "$DEVICE_ID" \
      --pid "$pid" \
      --signal TERM \
      --timeout 10 \
      >/dev/null 2>&1 || true
  done <<< "$running_pids"

  sleep 2

  running_pids="$(find_running_app_pids "$executable_name" "$app_bundle_name" || true)"
  if [[ -z "$running_pids" ]]; then
    return 0
  fi

  while IFS= read -r pid; do
    [[ -z "$pid" ]] && continue
    xcrun devicectl device process signal \
      --device "$DEVICE_ID" \
      --pid "$pid" \
      --signal KILL \
      --timeout 10 \
      >/dev/null 2>&1 || true
  done <<< "$running_pids"

  sleep 1
}

wait_for_launch_success() {
  local launch_log_path="$1"
  local timeout_seconds="$2"
  local deadline=$((SECONDS + timeout_seconds))

  while (( SECONDS < deadline )); do
    if [[ -f "$launch_log_path" ]]; then
      if grep -q "Launched application with" "$launch_log_path"; then
        return 0
      fi

      if grep -q "ERROR:" "$launch_log_path"; then
        return 1
      fi
    fi

    sleep 1
  done

  return 1
}

wait_for_flutter_device_visibility() {
  local timeout_seconds="$1"
  local deadline=$((SECONDS + timeout_seconds))
  local device_json

  while (( SECONDS < deadline )); do
    device_json="$(flutter devices --machine 2>/dev/null || true)"
    if [[ -n "$device_json" ]] && printf '%s' "$device_json" | ruby -rjson -e '
      query = ARGV[0]
      devices = JSON.parse(STDIN.read)
      found = devices.any? do |device|
        device["targetPlatform"] == "ios" &&
          device["emulator"] != true &&
          [device["id"], device["name"]].compact.any? { |value| value == query }
      end
      exit(found ? 0 : 1)
    ' "$DEVICE_ID"; then
      return 0
    fi
    sleep 2
  done

  return 1
}

add_default_web_key_define

DEVICE_ID="$(resolve_ios_device_field "$DEVICE_QUERY" "id")"
DEVICE_NAME="$(resolve_ios_device_field "$DEVICE_QUERY" "name")"

if [[ ! -f "$WORKSPACE_PATH/contents.xcworkspacedata" && ! -f "$PROJECT_PATH/project.pbxproj" ]]; then
  echo "Missing iOS workspace/project under $PROJECT_ROOT/ios" >&2
  exit 1
fi

if [[ -f "$WORKSPACE_PATH/contents.xcworkspacedata" ]]; then
  BUILD_CONTAINER=(-workspace "$WORKSPACE_PATH")
else
  BUILD_CONTAINER=(-project "$PROJECT_PATH")
fi

typeset -a FLUTTER_CONFIG_ONLY_CMD=(
  flutter build ios
  --config-only
  --debug
  --no-codesign
  --target "$TARGET_PATH"
)
if [[ -n "$FLAVOR" ]]; then
  FLUTTER_CONFIG_ONLY_CMD+=(--flavor "$FLAVOR")
fi
FLUTTER_CONFIG_ONLY_CMD+=("${FLUTTER_DEFINE_ARGS[@]}")

typeset -a XCODEBUILD_CMD=(
  xcodebuild
  "${BUILD_CONTAINER[@]}"
  -scheme "$SCHEME"
  -configuration "$BUILD_CONFIGURATION"
  -destination "id=$DEVICE_ID"
  -derivedDataPath "$DERIVED_DATA_PATH"
  install
)

echo "Using iOS device: $DEVICE_NAME ($DEVICE_ID)"
echo "Preparing Flutter iOS configuration..."
run_cmd "${FLUTTER_CONFIG_ONLY_CMD[@]}"

echo "Repairing Xcode project-level base configurations..."
run_cmd "$REPAIR_SCRIPT"

echo "Building and installing Debug app for device via xcodebuild..."
run_cmd "${XCODEBUILD_CMD[@]}"

if [[ "$DRY_RUN" == true ]]; then
  echo "[dry-run] resolved app path will be searched under $DERIVED_DATA_PATH"
  printf '[dry-run] '
  printf '%q ' xcrun devicectl device process launch --device "$DEVICE_ID" --terminate-existing "<resolved-bundle-id>" "${IOS_LAUNCH_ARGS[@]}"
  printf '\n'
  if [[ "$ATTACH_AFTER_LAUNCH" == true ]]; then
    printf '[dry-run] '
    printf '%q ' flutter attach --device-id "$DEVICE_ID" --device-connection attached --app-id "<resolved-bundle-id>" --target "$TARGET_PATH" --device-timeout "$DEVICE_TIMEOUT"
    printf '%q ' "${FLUTTER_DEFINE_ARGS[@]}" "${FLUTTER_ATTACH_ARGS[@]}"
    printf '\n'
  else
    echo "[dry-run] flutter attach skipped by --no-attach"
  fi
  exit 0
fi

APP_PATH="$(find_built_app_path)"
if [[ -z "$APP_PATH" ]]; then
  echo "Unable to find built .app under $DERIVED_DATA_PATH" >&2
  exit 1
fi

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist")"
BUNDLE_EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_PATH/Info.plist")"
APP_BUNDLE_NAME="$(basename "$APP_PATH")"

terminate_running_app_instances "$BUNDLE_EXECUTABLE" "$APP_BUNDLE_NAME"

echo "Launching $BUNDLE_ID on $DEVICE_NAME..."
LAUNCH_LOG_PATH="$(make_temp_file "ios-device-launch")"
xcrun devicectl device process launch \
  --device "$DEVICE_ID" \
  --terminate-existing \
  --timeout "$LAUNCH_TIMEOUT" \
  --log-output "$LAUNCH_LOG_PATH" \
  "$BUNDLE_ID" \
  "${IOS_LAUNCH_ARGS[@]}" \
  >/dev/null 2>&1 &
LAUNCH_HELPER_PID=$!

if ! wait_for_launch_success "$LAUNCH_LOG_PATH" "$LAUNCH_TIMEOUT"; then
  echo "Timed out waiting for $BUNDLE_ID to launch on $DEVICE_NAME." >&2
  [[ -f "$LAUNCH_LOG_PATH" ]] && tail -n 50 "$LAUNCH_LOG_PATH" >&2
  exit 1
fi

if [[ -n "$LAUNCH_HELPER_PID" ]] && kill -0 "$LAUNCH_HELPER_PID" 2>/dev/null; then
  kill "$LAUNCH_HELPER_PID" 2>/dev/null || true
  wait "$LAUNCH_HELPER_PID" 2>/dev/null || true
fi
LAUNCH_HELPER_PID=""

sleep 2
RUNNING_PIDS="$(find_running_app_pids "$BUNDLE_EXECUTABLE" "$APP_BUNDLE_NAME" || true)"
if [[ -n "$RUNNING_PIDS" ]]; then
  echo "Detected running app process on device:"
  printf '%s\n' "$RUNNING_PIDS"
else
  echo "Launch command reported success for $BUNDLE_ID."
fi

if [[ "$ATTACH_AFTER_LAUNCH" == true ]]; then
  if ! wait_for_flutter_device_visibility "$DEVICE_TIMEOUT"; then
    echo "Flutter did not rediscover $DEVICE_NAME ($DEVICE_ID) in time for automatic attach." >&2
    echo "Retry manually once the device is visible again:" >&2
    printf '  %q ' flutter attach --device-id "$DEVICE_ID" --device-connection attached --app-id "$BUNDLE_ID" --target "$TARGET_PATH" --device-timeout "$DEVICE_TIMEOUT"
    printf '%q ' "${FLUTTER_DEFINE_ARGS[@]}" "${FLUTTER_ATTACH_ARGS[@]}" >&2
    printf '\n' >&2
    exit 1
  fi

  typeset -a ATTACH_CMD=(
    flutter attach
    --device-id "$DEVICE_ID"
    --device-connection attached
    --app-id "$BUNDLE_ID"
    --target "$TARGET_PATH"
    --device-timeout "$DEVICE_TIMEOUT"
  )
  ATTACH_CMD+=("${FLUTTER_DEFINE_ARGS[@]}")
  ATTACH_CMD+=("${FLUTTER_ATTACH_ARGS[@]}")
  echo "Attaching Flutter debugger..."
  run_cmd "${ATTACH_CMD[@]}"
else
  echo "Skipping flutter attach. App is built, installed, and launched."
fi
