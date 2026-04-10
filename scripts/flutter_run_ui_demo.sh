#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_XCCONFIG_FILE="$PROJECT_ROOT/ios/Flutter/Amap.local.xcconfig"

export AMAP_ANDROID_KEY=""
export AMAP_IOS_KEY=""
export AMAP_WEB_KEY=""

cat > "$IOS_XCCONFIG_FILE" <<EOF
AMAP_IOS_KEY=
EOF

cd "$PROJECT_ROOT"

flutter run \
  --dart-define=DISABLE_AMAP=true \
  --dart-define=AMAP_ANDROID_KEY= \
  --dart-define=AMAP_IOS_KEY= \
  --dart-define=AMAP_WEB_KEY= \
  "$@"
