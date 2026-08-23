#!/usr/bin/env bash
# settings.sh — SCV 설정을 읽는 단 하나의 입구.
#
# 왜 있나: 지금 설정은 프로젝트 루트 .env 에 있고, 읽는 방법이 자리마다 다르다.
# 어떤 곳은 파일 전체를 환경으로 불러오고, 어떤 곳은 직접 뒤진다. 규칙이 하나가
# 아니라서 한 곳을 고쳐도 다른 곳이 그대로 남는다.
#
# 순수부와 효과부를 가른다.
#   settings_resolve      순수 — 후보 넷을 받아 하나를 고른다. 우선순위가 여기에만 있다
#   settings_lookup_json  결정적 변환 — JSON 텍스트와 키를 받아 값을 낸다. 디스크를 안 만진다
#   settings_get          효과 — 파일을 읽어 위 둘에 넘긴다. 이 함수만 디스크를 만진다
#
# core/tests/test-settings.sh 의 정적 검사가 이 경계를 기계로 강제한다.
#
# 값을 찾는 순서는 언제나 같다:
#   환경변수 → 비밀 설정 → 일반 설정 → 기본값
#
# 환경변수가 맨 위인 이유: 스크립트끼리 값을 넘기는 데 이미 40개 넘게 쓰고 있고
# 테스트도 그 방식으로 돈다. 없애려는 것은 *설정 파일* 이지 환경변수가 아니다.

# ---------------------------------------------------------------- 순수: 우선순위

# settings_resolve <env_val> <secret_val> <plain_val> <default_val>
#
# 넷 중 처음으로 비어 있지 않은 값을 낸다. 넷 다 비어 있으면 빈 문자열.
#
# 이 순서가 이 파일 한 곳에만 적혀 있다는 것이 요점이다. 지금은 자리마다 제각각
# 이고 일부는 순서가 다르다.
#
# 순수하다 — 파일도 시각도 무작위도 네트워크도 만지지 않는다.
settings_resolve() {
  local e="${1:-}" s="${2:-}" p="${3:-}" d="${4:-}"
  if [[ -n "$e" ]]; then printf '%s\n' "$e"; return 0; fi
  if [[ -n "$s" ]]; then printf '%s\n' "$s"; return 0; fi
  if [[ -n "$p" ]]; then printf '%s\n' "$p"; return 0; fi
  printf '%s\n' "$d"
}

# ------------------------------------------------- 결정적 변환: JSON 에서 값 꺼내기

# settings_lookup_json <json_text> <key>
#
# 최상위 키 하나의 값을 문자열로 낸다. 없으면 빈 문자열, exit 0.
# 중첩된 객체·배열은 보지 않는다 — 설정은 평평하다.
#
# 값이 없는 것과 값이 빈 문자열인 것은 둘 다 빈 출력이다. 설정에서 그 둘을 구분할
# 이유가 없고, 구분하려 들면 호출부마다 처리가 갈린다.
#
# 깨진 JSON, 배열, 최상위가 문자열인 경우 — 전부 빈 문자열 + exit 0. 죽지 않는다.
# 설정 하나 때문에 진행 중인 명령이 멈추면 안 된다.
#
# 디스크를 만지지 않는다 — 인자로 받은 텍스트만 본다.
settings_lookup_json() {
  local json="${1:-}" key="${2:-}"
  [[ -n "$json" && -n "$key" ]] || return 0

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r --arg k "$key" '
      if type == "object" then (.[$k] // empty) else empty end
      | if type == "string" then . else tostring end
    ' 2>/dev/null || true
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    SCV_LOOKUP_KEY="$key" python3 -c '
import json, os, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if not isinstance(d, dict):
    sys.exit(0)
v = d.get(os.environ.get("SCV_LOOKUP_KEY", ""))
if v is None:
    sys.exit(0)
if isinstance(v, bool):
    print("true" if v else "false")
elif isinstance(v, (int, float, str)):
    print(v)
' <<< "$json" 2>/dev/null || true
    return 0
  fi

  # 파서가 없다 — 값을 지어내느니 아무것도 내지 않는다. 호출부는 기본값으로 간다.
  return 0
}

# ---------------------------------------------------------------- 효과: 파일 읽기

# _settings_from_env_file <key> [file]
#
# .env 형식 파일에서 키 하나의 값을 읽는다. 1단계에서 쓰는 저장소다 — 2단계에서
# 이 함수만 JSON 읽기로 바뀐다.
#
# 파일을 source 하지 않는다. 사용자의 .env 는 unset 변수를 참조하거나($ 를 담은
# 비밀값 포함) 할 수 있고, nounset 이 켜진 호출부에서 source 하면 스크립트 전체가
# 죽는다 — 그리고 `|| true` 로는 그 죽음을 못 잡는다.
_settings_from_env_file() {
  local key="${1:-}" file="${2:-.env}"
  [[ -n "$key" && -f "$file" ]] || return 0
  # 마지막 정의가 이긴다 — source 했을 때와 같은 규칙.
  sed -n "s/^[[:space:]]*${key}=[[:space:]]*//p" "$file" 2>/dev/null \
    | tail -n 1 \
    | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'\$//" \
    || true
}

# settings_get <key> [default]
#
# 설정 하나를 읽는다. 이것이 유일한 입구다 — 직접 파일을 뒤지지 말 것.
#
# 이 함수만 디스크를 만진다. 우선순위 판단은 순수 함수가 한다.
settings_get() {
  local key="${1:-}" default="${2:-}"
  [[ -n "$key" ]] || return 0

  local from_env="${!key:-}"
  local from_secret="" from_plain=""

  # 1단계: 저장소는 아직 .env 하나다. 2단계에서 여기만 두 JSON 으로 바뀐다.
  from_plain="$(_settings_from_env_file "$key" "${SCV_SETTINGS_ENV_FILE:-.env}")"

  settings_resolve "$from_env" "$from_secret" "$from_plain" "$default"
}

# settings_has <key>
#
# 값이 있으면 0, 없으면 1. 진단 화면처럼 "설정됐는지" 만 궁금한 자리에 쓴다.
settings_has() {
  [[ -n "$(settings_get "${1:-}")" ]]
}
