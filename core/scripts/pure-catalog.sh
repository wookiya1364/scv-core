#!/usr/bin/env bash
# pure-catalog.sh — 순수함수 사전을 만들고, 사전 · 예시 · 중복을 검사한다.
#
# 계약: core/contracts/purity.md "사전 — 만들기 전에 찾아 재사용한다"
#
# 표식(# @pure · # @deterministic)이 붙은 함수는 옆에 역할 · 종류 · 예를 단다. 이 스크립트는
# 그 주석에서 사전(core/catalog/pure/)을 만들고, 다음을 본다:
#   - 빈 칸 · 모르는 종류
#   - 예시를 실제로 돌려 적힌 출력과 같은지
#   - 같은 입력에 같은 출력을 내는 함수 짝(중복 의심)
#   - 사전이 주석과 어긋났는지, 한 파일이 한도를 넘었는지
#
# 판정은 lib/pure-catalog.sh 의 순수함수가 하고, 여기는 읽기 · 함수 불러 보기 · 쓰기만 한다.
#
# Usage:
#   pure-catalog.sh build [--root DIR] [--catalog DIR]   사전을 다시 만든다
#   pure-catalog.sh check [--root DIR] [--catalog DIR]   검사만 한다 (파일을 바꾸지 않는다)
#   --root 에 파일 하나를 주면 그 파일만 본다 (사전 낡음 판정은 전체 기준이라 무시할 것).
#   공통: --base DIR (위치 표시의 기준, 기본 core) · --contract FILE · --limit N (기본 400)
#
# Exit: 0 통과 · 1 위반 · 2 사용법 오류
set -uo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CORE_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
# shellcheck source=lib/pure-catalog.sh
source "$SCRIPT_DIR/lib/pure-catalog.sh"

MODE="${1:-}"; shift || true
case "$MODE" in
  build|check) : ;;
  -h|--help|"") sed -n '2,21p' "$0"; [[ -n "$MODE" ]] && exit 0; exit 2 ;;
  *) echo "pure-catalog.sh: unknown mode: $MODE (build | check)" >&2; exit 2 ;;
esac

ROOT="$CORE_DIR/scripts"; CATALOG="$CORE_DIR/catalog/pure"; BASE="$CORE_DIR"
CONTRACT="$CORE_DIR/contracts/purity.md"; LIMIT=400
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --catalog) CATALOG="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    --contract) CONTRACT="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    *) echo "pure-catalog.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done
if [[ -f "$ROOT" ]]; then ROOT="$( cd "$( dirname "$ROOT" )" && pwd )/$( basename "$ROOT" )"; else ROOT="$( cd "$ROOT" && pwd )" || exit 2; fi
BASE="$( cd "$BASE" && pwd )" || exit 2
ALLOWED_FILE="$CATALOG/duplicates-allowed.tsv"

# ---------------------------------------------------------------- 입구: 읽기

KINDS="$(pc_kinds_from_contract < "$CONTRACT")"
[[ -n "$KINDS" ]] || { echo "✖ 종류 표를 못 찾았다: $CONTRACT" >&2; exit 2; }

ENTRIES=""
while IFS= read -r f; do
  rel="${f#"$BASE"/}"
  ENTRIES+="$(pc_extract_entries "$rel" < "$f")"$'\n'
done < <(find "$ROOT" -type f -name '*.sh' | LC_ALL=C sort)
ENTRIES="$(printf '%s' "$ENTRIES" | awk 'NF')"
COUNT="$(printf '%s' "$ENTRIES" | awk 'NF' | wc -l | tr -d ' ')"
ALLOWED=""; [[ -f "$ALLOWED_FILE" ]] && ALLOWED="$(cat "$ALLOWED_FILE")"

# ---------------------------------------------------------------- 함수 불러 보기

# 공통 입력 묶음 — 빈 값 · 공백 · 줄바꿈 · 탭 · 한글 · 숫자 · 기호 · 버전 · JSON · 표
PC_WORDS=( "" " " "a" $'a\nb' $'\na' $'\t' "한글" "0" "-1" "1.2.3" "{}" "a|b" "  x  " )

# 표식 함수를 한 셸에 다 불러 둔다. lib 은 통째로, 스크립트 안의 함수는 본문만 꺼내 정의한다.
_pc_load() {
  local rel f name line
  while IFS= read -r line; do
    IFS=$'\x1d' read -r rel _ name _ <<< "${line//$'\t'/$'\x1d'}"
    [[ -n "$rel" ]] || continue
    f="$BASE/$rel"
    case "$rel" in
      */lib/*) source "$f" ;;
      *) eval "$(awk -v fn="$name" '$0 ~ "^"fn"\\(\\)[[:space:]]*\\{" {on=1} on {print} on && /^\}$/ {exit}' "$f")" ;;
    esac
  done <<< "$ENTRIES"
}

# _pc_call <함수> <인자 글> → "종료코드<US>출력"
_pc_call() {
  local fn="$1" args="$2" out st
  if [[ "$args" == *"<<<"* ]]; then
    out="$(eval "$fn $args" 2>/dev/null)"; st=$?
  else
    out="$(eval "$fn $args" 2>/dev/null </dev/null)"; st=$?
  fi
  printf '%s\x1f%s' "$st" "$out"
}

# 예시 실행: 맞지 않는 예시를 "함수<탭>파일<탭>예시<탭>적힌<탭>실제" 로 낸다
_pc_run_examples() (
  set +eu +o pipefail
  _pc_load >/dev/null 2>&1
  local file tier name role kind exs ex split args expect status want got line
  while IFS= read -r line; do
    IFS=$'\x1d' read -r file tier name role kind exs <<< "${line//$'\t'/$'\x1d'}"
    [[ -n "$name" && -n "$exs" ]] || continue
    while IFS= read -r ex; do
      [[ -n "$ex" ]] || continue
      split="$(pc_split_example "$ex")" || { printf '%s\t%s\t%s\t→ 가 없다\t\n' "$name" "$file" "$ex"; continue; }
      IFS=$'\x1d' read -r args expect status <<< "${split//$'\t'/$'\x1d'}"
      eval "want=$expect" 2>/dev/null || { printf '%s\t%s\t%s\t기대 출력을 읽을 수 없다\t\n' "$name" "$file" "$ex"; continue; }
      want="$(printf '%s' "$want")"
      got="$(_pc_call "$name" "$args")"
      if [[ "$got" != "$status"$'\x1f'"$want" ]]; then
        printf '%s\t%s\t%s\t%q [%s]\t%q [%s]\n' "$name" "$file" "$ex" "$want" "$status" "${got#*$'\x1f'}" "${got%%$'\x1f'*}"
      fi
    done <<< "${exs//$PC_SEP/$'\n'}"
  done <<< "$ENTRIES"
)

# 지문: 함수마다 "인자수|표준입력|cksum<탭>함수"
_pc_fingerprints() (
  set +eu +o pipefail
  _pc_load >/dev/null 2>&1
  local file tier name role kind exs first args n stdin w i fp q line
  while IFS= read -r line; do
    IFS=$'\x1d' read -r file tier name role kind exs <<< "${line//$'\t'/$'\x1d'}"
    [[ -n "$name" && -n "$exs" ]] || continue
    first="${exs%%$PC_SEP*}"
    args="$(pc_split_example "$first" | cut -f1)"
    stdin=0; [[ "$args" == *"<<<"* ]] && stdin=1
    eval "set -- ${args%%<<<*}" 2>/dev/null || continue
    n=$#; fp=""
    for w in "${PC_WORDS[@]}"; do
      printf -v q '%q' "$w"
      args=""
      for (( i = 0; i != n; i++ )); do args+=" $q"; done
      [[ $stdin -eq 1 ]] && args+=" <<< $q"
      fp+="$(_pc_call "$name" "$args")"$'\x1e'
    done
    printf '%s|%s|%s\t%s\n' "$n" "$stdin" "$(printf '%s' "$fp" | cksum | tr -d ' \t')" "$name"
  done <<< "$ENTRIES"
)

# 짝 확인: 서로의 예시를 넣어 상대의 적힌 출력과 전부 같으면 그 짝을 낸다
_pc_confirm_pairs() (
  set +eu +o pipefail
  _pc_load >/dev/null 2>&1
  local a b same
  _pc_exs_of() { printf '%s\n' "$ENTRIES" | awk -F'\t' -v n="$1" '$3 == n { print $6; exit }'; }
  _pc_behaves_as() {  # <함수> <다른 함수의 예시들> — 전부 같으면 0
    local fn="$1" exs="$2" ex args expect status want
    while IFS= read -r ex; do
      [[ -n "$ex" ]] || continue
      args="$(pc_split_example "$ex")"
      IFS=$'\x1d' read -r args expect status <<< "${args//$'\t'/$'\x1d'}"
      eval "want=$expect" 2>/dev/null || return 1
      [[ "$(_pc_call "$fn" "$args")" == "$status"$'\x1f'"$want" ]] || return 1
    done <<< "${exs//$PC_SEP/$'\n'}"
    return 0
  }
  while IFS=$'\t' read -r a b; do
    [[ -n "$a" ]] || continue
    _pc_behaves_as "$a" "$(_pc_exs_of "$b")" && _pc_behaves_as "$b" "$(_pc_exs_of "$a")" && printf '%s\t%s\n' "$a" "$b"
  done <<< "$1"
)

# ---------------------------------------------------------------- 사전 글

RENDERED="$(pc_render_catalog "$ENTRIES" "$KINDS")"

_pc_files_in_render() { printf '%s\n' "$RENDERED" | sed -n 's/^@@FILE //p'; }
_pc_file_text() { printf '%s\n' "$RENDERED" | awk -v f="$1" '/^@@FILE /{on = (substr($0, 8) == f); next} on'; }

# ---------------------------------------------------------------- 출구: build

if [[ "$MODE" == "build" ]]; then
  mkdir -p "$CATALOG"
  for old in "$CATALOG"/*.md; do
    [[ -e "$old" ]] || continue
    _pc_files_in_render | grep -qxF "$(basename "$old")" || rm -f "$old"
  done
  while IFS= read -r f; do
    _pc_file_text "$f" > "$CATALOG/$f"
  done < <(_pc_files_in_render)
  echo "OK  catalog: ${COUNT}개 함수 → $(_pc_files_in_render | wc -l | tr -d ' ')개 파일 ($CATALOG)"
  exit 0
fi

# ---------------------------------------------------------------- 출구: check

FAILS=0
report() { echo "$1" >&2; FAILS=$((FAILS + 1)); }

BAD="$(pc_validate_entries "$ENTRIES" "$KINDS")"
if [[ -n "$BAD" ]]; then
  while IFS=$'\t' read -r name file why; do report "✖ $file — $name: $why"; done <<< "$BAD"
fi

EXBAD="$(_pc_run_examples)"
if [[ -n "$EXBAD" ]]; then
  while IFS= read -r line; do
    IFS=$'\x1d' read -r name file ex want got <<< "${line//$'\t'/$'\x1d'}"
    report "✖ $file — $name 예시가 틀렸다: $ex"
    [[ -n "$want$got" ]] && echo "      적힌: $want · 실제: $got" >&2
  done <<< "$EXBAD"
fi

CANDIDATES="$(pc_duplicate_pairs "$(_pc_fingerprints)")"
CONFIRMED="$( [[ -n "$CANDIDATES" ]] && _pc_confirm_pairs "$CANDIDATES" )"
DUPS="$(pc_allowed_filter "$CONFIRMED" "$ALLOWED")"
if [[ -n "$DUPS" ]]; then
  while IFS=$'\t' read -r a b c; do
    if [[ "$a" == "!이유없음" ]]; then
      report "✖ 중복 예외에 이유가 없다: $b · $c ($ALLOWED_FILE)"
    else
      report "✖ 중복 의심: $a · $b — 같은 입력에 같은 출력을 낸다. 하나로 합치거나, 다르다면 다른 입력을 예시로 더하라"
    fi
  done <<< "$DUPS"
fi

OVER="$(pc_oversize_files "$RENDERED" "$LIMIT")"
if [[ -n "$OVER" ]]; then
  while IFS=$'\t' read -r f n; do report "✖ 사전 파일이 너무 크다: $f ${n}줄 (한도 $LIMIT) — 그 종류의 함수에 세부 종류를 붙여라"; done <<< "$OVER"
fi

STALE=""
while IFS= read -r f; do
  if [[ ! -f "$CATALOG/$f" ]] || [[ "$(cat "$CATALOG/$f")" != "$(_pc_file_text "$f")" ]]; then STALE+=" $f"; fi
done < <(_pc_files_in_render)
for old in "$CATALOG"/*.md; do
  [[ -e "$old" ]] || continue
  _pc_files_in_render | grep -qxF "$(basename "$old")" || STALE+=" $(basename "$old")"
done
[[ -z "$STALE" ]] || report "✖ 사전이 낡았다:$STALE — 다시 만들기: bash core/scripts/pure-catalog.sh build"

if [[ $FAILS -eq 0 ]]; then
  echo "OK  catalog: ${COUNT}개 함수 · 예시 전부 맞음 · 중복 의심 0 · 사전 최신"
  exit 0
fi
echo "" >&2
echo "→ 위반 ${FAILS}건 (함수 ${COUNT}개 중). 규칙: core/contracts/purity.md" >&2
exit 1
