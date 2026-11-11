#!/usr/bin/env bash
# pure-bench.sh — 순수함수(와 셸에서 띄우는 명령 하나)의 시간 · 메모리 · GPU · 부른 횟수를 잰다.
# 계약 contracts/composition.md · 계획 20261111-wookiya1364-pure-bench-and-gate.
#
# 판단은 lib/pure-bench.sh 의 순수 함수가 하고, 여기는 사전 읽기 · 실행 · 쓰기만 한다.
#
# Usage:
#   pure-bench.sh targets [--catalog DIR] [--only NAME]…
#       사전에서 잴 목록을 낸다: "함수<탭>파일<탭>언어<탭>1배 인자<탭>4배 인자<탭>늘림(1/0)".
#       1배 = 예시를 25번 되풀이, 4배 = 100번. 늘릴 값이 없는 예시는 늘림 0 (늘려 재지 못함).
#
# Exit: 0 통과 · 2 사용법 오류
set -uo pipefail
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CORE_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
# shellcheck source=lib/pure-catalog.sh
source "$SCRIPT_DIR/lib/pure-catalog.sh"
# shellcheck source=lib/pure-bench.sh
source "$SCRIPT_DIR/lib/pure-bench.sh"

# @effect read_catalog
# 이유: 사전 파일을 읽는다 — 파이프라인의 입구(차례 파일은 뺀다)
read_catalog() {
  local f
  for f in "$1"/*.md; do
    [[ -f "$f" && "${f##*/}" != INDEX.md ]] && cat "$f"
  done
  return 0
}

CMD="${1:-}"; [[ $# -gt 0 ]] && shift
CATALOG="$( cd "$CORE_DIR/.." && pwd )/scv/core/catalog/pure"; ONLY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --catalog) CATALOG="${2:-}"; shift 2 ;;
    --only)    ONLY+="${2:-}"$'\n'; shift 2 ;;
    *) echo "pure-bench: 모르는 인자: $1" >&2; exit 2 ;;
  esac
done

case "$CMD" in
  targets)
    [[ -d "$CATALOG" ]] || { echo "pure-bench: 사전 폴더가 없다: $CATALOG" >&2; exit 2; }
    pb_targets "$(read_catalog "$CATALOG")" "${ONLY%$'\n'}" ;;
  *) echo "Usage: pure-bench.sh targets [--catalog DIR] [--only NAME]…" >&2; exit 2 ;;
esac
