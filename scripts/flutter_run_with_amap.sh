#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
LEGACY_ENV_FILE="$PROJECT_ROOT/.env.amap.local"
REPAIR_SCRIPT="$SCRIPT_DIR/repair_ios_project_base_config.rb"

if [[ ! -f "$ENV_FILE" && -f "$LEGACY_ENV_FILE" ]]; then
  ENV_FILE="$LEGACY_ENV_FILE"
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $PROJECT_ROOT/.env"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

cd "$PROJECT_ROOT"

repair_ios_project_config() {
  if [[ -x "$REPAIR_SCRIPT" ]]; then
    "$REPAIR_SCRIPT" >/dev/null || true
  fi
}

trap repair_ios_project_config EXIT

flutter run \
  --dart-define=AMAP_ANDROID_KEY="$AMAP_ANDROID_KEY" \
  --dart-define=AMAP_WEB_KEY="$AMAP_WEB_KEY" \
  "$@"
