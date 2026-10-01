#!/usr/bin/env bash
# choice-gate.sh — 고르게 할 때 규칙(contracts/choices.md)의 효과부. 읽기 · 쓰기는 여기서만, 판단은 lib/choices.sh.
#
#   choice-gate.sh line                         매 턴 훅이 부른다: 호스트 설정에 선택지 도구가 있으면 안내 한 줄(없으면 아무것도)
#   choice-gate.sh stop [--active 0|1] < 마지막 답  종료 훅이 부른다: 글로 묻거나 번호로 고르게 하면서 끝났으면
#                                                 CHOICE_GATE: block + CHOICE_REASON: <이유>. 호스트가 이미 계속 중이면
#                                                 CHOICE_GATE: warn — 막지 않고 다음 턴 경고(.help-warn)에 덧붙인다. 그 밖에는 ok.
#
# 입력: 호스트 프로필 SCV_CHOICE_TOOL (래퍼가 준다). 비면 두 하위 명령 모두 이 기능 전과 같다(아무것도 내지 않음 · ok).
# 어떤 실패도 exit 0 — 판정을 못 하면 막지 않는다.
set -u
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" 2>/dev/null && pwd )" || exit 0
# shellcheck source=lib/choices.sh
source "$SCRIPT_DIR/lib/choices.sh" 2>/dev/null || exit 0
# shellcheck source=lib/host-profile.sh
source "$SCRIPT_DIR/lib/host-profile.sh" 2>/dev/null || exit 0
TOOL="${SCV_CHOICE_TOOL:-}"
JOURNAL_DIR="${SCV_JOURNAL_DIR:-scv/journal}"

case "${1:-}" in
  line)
    scv_choice_line "$TOOL"
    ;;
  stop)
    shift
    ACTIVE=0
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --active) ACTIVE="${2:-0}"; shift 2 ;;
        *) shift ;;
      esac
    done
    [[ "$ACTIVE" == "1" ]] || ACTIVE=0
    ANSWER="$(head -c 65536 2>/dev/null || true)"
    _asks=0
    [[ -n "${ANSWER//[[:space:]]/}" ]] && _asks="$(scv_asks_in_text "$(scv_answer_body "$ANSWER")")"
    _gate="$(scv_choice_gate "$_asks" "$TOOL" "$ACTIVE")"
    echo "CHOICE_GATE: $_gate"
    if [[ "$_gate" != "ok" ]]; then
      _why="$(scv_choice_reason "$TOOL")"
      echo "CHOICE_REASON: $_why"
      if [[ "$_gate" == "warn" ]]; then
        mkdir -p "$JOURNAL_DIR" 2>/dev/null && [[ ! -L "$JOURNAL_DIR/.help-warn" ]] \
          && printf '%s\n' "직전 턴: $_why" >> "$JOURNAL_DIR/.help-warn" 2>/dev/null
      fi
    fi
    ;;
  *) echo "usage: choice-gate.sh line | stop [--active 0|1]" >&2 ;;
esac
exit 0
