#!/usr/bin/env bash
# test-check-readme.sh — tools/check-readme.sh 가 지금 README 를 통과시키고, 틀린 README 는 잡는지 본다.
#
# 원본은 건드리지 않는다: README 세 언어판을 임시 폴더에 복사해 한 곳씩 망가뜨리고, README_OVERRIDE_DIR 로
# 그 사본을 읽게 한다(목록 · 링크 대상은 늘 저장소에서 찾는다).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="$ROOT/tools/check-readme.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fail=0

# 1. 지금 README 는 통과한다.
if ! out="$(bash "$CHECK" --profile core "$ROOT" 2>&1)"; then
  echo "✖ baseline: the current README fails its own check:" >&2
  printf '%s\n' "$out" >&2
  exit 1
fi
echo "ok baseline — $out"

fresh_copy() {  # → 새 사본 폴더 경로
  local d
  d="$(mktemp -d "$WORK/case.XXXXXX")"
  cp "$ROOT/README.md" "$ROOT/README.ko.md" "$ROOT/README.ja.md" "$d/"
  printf '%s\n' "$d"
}
append_line() { printf '\n%s\n' "$2" >> "$1"; }                                   # <file> <line>
drop_lines() { grep -vF -- "$2" "$1" > "$1.tmp" || true; mv "$1.tmp" "$1"; }        # <file> <fixed string>
expect_red() {  # <case> <dir> <expected fragment>
  local out rc=0
  out="$(README_OVERRIDE_DIR="$2" bash "$CHECK" --profile core "$ROOT" 2>&1)" || rc=$?
  if (( rc == 0 )); then
    echo "✖ $1: the check passed a broken README" >&2; fail=1
  elif ! grep -qF -- "$3" <<< "$out"; then
    echo "✖ $1: failed, but not for the expected reason ($3):" >&2
    printf '%s\n' "$out" | sed 's/^/    /' >&2; fail=1
  else
    echo "ok $1"
  fi
}

# 2. 망가뜨린 사본은 모두 붉다.
d="$(fresh_copy)"; append_line "$d/README.md" 'See `action:no-such-action-xyz` for details.'
expect_red "unknown action" "$d" "command 'no-such-action-xyz'"

d="$(fresh_copy)"; append_line "$d/README.md" 'Set `SCV_NO_SUCH_SETTING_XYZ=on` to enable it.'
expect_red "unknown setting" "$d" "setting 'SCV_NO_SUCH_SETTING_XYZ'"

d="$(fresh_copy)"; append_line "$d/README.md" 'See [the missing guide](docs/no-such-guide.md).'
expect_red "broken link" "$d" "link target 'docs/no-such-guide.md'"

d="$(fresh_copy)"; drop_lines "$d/README.ko.md" '### 매 턴'
expect_red "language edition lost a section" "$d" "heading structure differs"

d="$(fresh_copy)"; drop_lines "$d/README.ja.md" 'SCV_MODEL_PROMPTING'
expect_red "required topic removed" "$d" "required topic marker missing: SCV_MODEL_PROMPTING"

d="$(fresh_copy)"; append_line "$d/README.md" 'Current release: 0.99.1.'
expect_red "version number written" "$d" "version numbers present"

(( fail )) && exit 1
echo "check-readme: baseline green, 6 broken copies red"
