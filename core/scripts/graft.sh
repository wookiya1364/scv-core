#!/usr/bin/env bash
# graft.sh — Graft 어댑터의 효과부 (v0.51.0+). Graft 가 있으면 쓰고, 없으면 조용히 생략한다.
#
#   graft.sh status                          GRAFT_STATUS: absent | no-graph | ready | off
#   graft.sh blast [--base <ref>] [--json]   변경의 정적 영향 범위 요약 (ready 일 때만; 아니면 빈 출력)
#   graft.sh ask <task> [--json]             관련 코드 후보 ≤10 (ready 일 때만; 아니면 빈 출력)
#
# 원칙: 설치·init·build·훅·MCP 를 절대 부르지 않는다(사용자의 그래프 상태를 바꾸지 않는다). 모든 실패·타임아웃은
# 빈 출력 + stderr 한 줄, exit 0. 설정: SCV_GRAFT=auto|off · SCV_GRAFT_TIMEOUT(초, 기본 20).
set -uo pipefail
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/graft.sh"
# shellcheck disable=SC1091
[[ -f "$SCRIPT_DIR/lib/settings.sh" ]] && source "$SCRIPT_DIR/lib/settings.sh" 2>/dev/null || true

_get() { declare -F settings_get >/dev/null 2>&1 || return 0; settings_get "$1" 2>/dev/null || true; }
CMD="${1:-status}"; shift || true
TIMEOUT="${SCV_GRAFT_TIMEOUT:-$(_get SCV_GRAFT_TIMEOUT | tr -d '"[:space:]')}"; [[ "$TIMEOUT" =~ ^[0-9]+$ ]] || TIMEOUT=20

has_bin=0; command -v graft >/dev/null 2>&1 && has_bin=1
has_graph=0; [[ -d graft ]] && has_graph=1
STATUS="$(scv_graft_status "$has_bin" "$has_graph" "$(_get SCV_GRAFT)")"

# 시간 제한 실행 — coreutils timeout 이 있으면 그것, 없으면 bash 감시자. 출력은 stdout 으로.
_run() {
  if command -v timeout >/dev/null 2>&1; then timeout "$TIMEOUT" "$@"; return $?; fi
  "$@" & local pid=$!
  ( sleep "$TIMEOUT"; kill "$pid" 2>/dev/null ) & local wd=$!
  wait "$pid" 2>/dev/null; local rc=$?
  kill "$wd" 2>/dev/null; wait "$wd" 2>/dev/null
  return $rc
}
_call() {  # <args…> → JSON on stdout or empty (+ stderr note)
  local out rc
  out="$(_run graft "$@" 2>/dev/null)"; rc=$?
  if (( rc != 0 )); then echo "graft: '$1' failed or timed out (${TIMEOUT}s) — skipped" >&2; return 0; fi
  if ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then echo "graft: '$1' returned no JSON — skipped" >&2; return 0; fi
  printf '%s' "$out"
}

case "$CMD" in
  status) echo "GRAFT_STATUS: $STATUS" ;;
  blast)
    [[ "$STATUS" == "ready" ]] || exit 0
    base=""; json=0
    while [[ $# -gt 0 ]]; do case "$1" in --base) base="${2:-}"; shift 2 ;; --json) json=1; shift ;; *) shift ;; esac; done
    if [[ -z "$base" ]]; then
      if git rev-parse --verify -q origin/main >/dev/null 2>&1; then base="origin/main"; else base="HEAD"; fi
    fi
    out="$(_call blast --base "$base" --depth all --format json)"; [[ -n "$out" ]] || exit 0
    if (( json )); then printf '%s\n' "$out"; else scv_graft_render_blast "$(scv_graft_blast_summary "$out")"; fi ;;
  ask)
    [[ "$STATUS" == "ready" ]] || exit 0
    task=""; json=0
    while [[ $# -gt 0 ]]; do case "$1" in --json) json=1; shift ;; *) task="${task:+$task }$1"; shift ;; esac; done
    [[ -n "$task" ]] || { echo "usage: graft.sh ask <task> [--json]" >&2; exit 0; }
    out="$(_call ask "$task" --json)"; [[ -n "$out" ]] || exit 0
    if (( json )); then printf '%s\n' "$out"; else scv_graft_render_ask "$(scv_graft_ask_summary "$out" 10)"; fi ;;
  -h|--help|help) sed -n '2,9p' "$0" ;;
  *) echo "usage: graft.sh status|blast [--base <ref>] [--json]|ask <task> [--json]" >&2; exit 2 ;;
esac
exit 0
