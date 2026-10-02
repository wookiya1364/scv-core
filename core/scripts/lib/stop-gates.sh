#!/usr/bin/env bash
# lib/stop-gates.sh — 종료 훅의 세 검사(등록 · 원칙 · 선택지)가 검사마다 한 턴에 한 번씩 막게 하는 순수부 (v0.64.2+).
# 효과(훅 입력 · 턴 표 · 전달 기록 읽기, 막기 출력 · 전달 기록 쓰기)는 template/hooks/on-stop.sh.
#
#   scv_gates_delivered <검사> <계속 중 0|1> <턴 표> <전달 기록 한 줄>        → 1(이번 턴에 이미 이유를 전달함) | 0
#   scv_gates_record <턴 표> <전달 기록 한 줄> <계속 중 0|1> <막은 검사들>    → 새 전달 기록 한 줄 | 빈 값(쓰지 않음)
#   scv_gates_reason <등록 이유> <원칙 이유> <선택지 이유>                   → 막는 이유 — 빈 것은 빼고 이 순서로 줄마다 하나
#
# 검사 이름은 prompt · principle · choice, 막은 검사들은 쉼표로 잇는다. 전달 기록은 "<턴 표>\x1f<검사들>" 한 줄이다.
# 계속 중이 아니면(이번 턴의 첫 멈춤 — 종료 훅이 막아서 이어진 멈춤이 아님) 아직 어떤 검사도 이유를 전달하지 않았다.
# 계속 중인데 턴 표가 없거나 기록이 이번 턴 것이 아니면 모든 검사를 '이미 전달'로 본다 — 이 기능 전과 같은 동작(계속 중이면
# 막지 않음)이고, 막는 쪽으로 실패하지 않는다. 기록은 막을 때만 쓴다 — 막지 않은 멈춤은 저널 밖에 아무것도 남기지 않는다.
#
# 꺾쇠 글자는 쓰지 않는다 — 순수성 검사가 리다이렉션으로 본다.

# @pure
# <검사> <계속 중 0|1> <턴 표> <전달 기록 한 줄> → 1 | 0.
scv_gates_delivered() {
  local gate="${1:-}" active="${2:-0}" tok="${3:-}" rec="${4:-}" us=$'\x1f' rtok rlist
  [[ "$active" == "1" ]] || { printf '0'; return 0; }
  [[ -n "$tok" && "$rec" == *"$us"* ]] || { printf '1'; return 0; }
  rtok="${rec%%"$us"*}"; rlist="${rec#*"$us"}"
  [[ "$rtok" == "$tok" ]] || { printf '1'; return 0; }
  case ",$rlist," in
    *",$gate,"*) printf '1' ;;
    *) printf '0' ;;
  esac
}

# @pure
# <턴 표> <전달 기록 한 줄> <계속 중 0|1> <막은 검사들> → 새 기록 한 줄 | 빈 값.
# 막은 검사가 없거나 턴 표가 없으면 쓰지 않는다. 첫 멈춤이면 새로 시작하고, 계속 중이면 이번 턴 기록에 더한다.
scv_gates_record() {
  local tok="${1:-}" rec="${2:-}" active="${3:-0}" blocked="${4:-}" us=$'\x1f' list="" rest g
  [[ -n "$tok" && -n "$blocked" ]] || return 0
  [[ "$active" == "1" && "$rec" == "$tok$us"* ]] && list="${rec#*"$us"}"
  rest="$blocked,"
  while [[ -n "$rest" ]]; do
    g="${rest%%,*}"; rest="${rest#*,}"
    [[ -n "$g" ]] || continue
    case ",$list," in
      *",$g,"*) ;;
      *) list="${list:+$list,}$g" ;;
    esac
  done
  printf '%s%s%s' "$tok" "$us" "$list"
}

# @pure
# <등록 이유> <원칙 이유> <선택지 이유> → 막는 이유. 빈 것은 빼고 이 순서로, 이유마다 한 줄. 모두 비면 빈 값.
scv_gates_reason() {
  local out="" r nl=$'\n'
  for r in "${1:-}" "${2:-}" "${3:-}"; do
    [[ -n "$r" ]] || continue
    out="${out:+$out$nl}$r"
  done
  printf '%s' "$out"
}
