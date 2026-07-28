#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAYLOAD="$ROOT/core"
grep_payload() {
  grep -R -I -n \
    --exclude-dir=node_modules \
    --exclude-dir=dist \
    --exclude-dir=dist-deck \
    --exclude-dir=coverage \
    --exclude-dir=.vite \
    --exclude-dir=.cache \
    "$@" "$PAYLOAD"
}

forbidden=(
  'Claude'
  'Codex'
  'AskUserQuestion'
  'CLAUDE_PLUGIN_ROOT'
  '$ARGUMENTS'
  '${SCV_ARGS'
  '/scv:'
  '$scv:'
  '.claude'
  '.codex'
)
for token in "${forbidden[@]}"; do
  if grep_payload -F -- "$token"; then
    echo "host leakage found: $token" >&2
    exit 1
  fi
done

if grep_payload -E '\b(opus|sonnet|haiku|gpt-[0-9]|o[0-9]-)'; then
  echo "provider model name leaked into core payload" >&2
  exit 1
fi

echo "host-neutral payload: ok"
