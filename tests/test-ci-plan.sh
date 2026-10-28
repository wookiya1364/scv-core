#!/usr/bin/env bash
# test-ci-plan.sh — 문서 · 버전만 바뀐 PR 만 무거운 시험을 건너뛰는지 본다(T13).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAN="$ROOT/tools/ci-plan.sh"
PASS=0; FAIL=0
ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✖ FAIL: $1"; FAIL=$((FAIL + 1)); }
judge() { (source "$PLAN"; printf '%s' "$1" | ci_docs_only); }
want() {  # <이름> <목록> <기대>
  local got; got="$(judge "$2")"
  [[ "$got" == "$3" ]] && ok "$1 → $3" || fail "$1: got $got, want $3"
}

echo "── [T13] 문서 · 버전 판정 ──"
want "VERSION + CHANGELOG"            $'VERSION\nCHANGELOG.md'            yes
want "docs/ 아래 문서"                 $'docs/release.md\ndocs/a/b.md'     yes
want "README 는 README 검사 대상"       $'README.md'                        no
want "core/ 아래 .md 는 실행되는 규약"   $'core/protocols/help.md'           no
want "워크플로"                         $'.github/workflows/core-ci.yml'    no
want "문서 + 코드 섞임"                 $'docs/a.md\ncore/scripts/x.sh'     no
want "빈 목록은 애매 → 전체"             ''                                  no
want "VERSION 이름만 비슷한 파일"        $'core/VERSION'                     no

echo "── 맥 조각이 필요한가 ──"
mac() { (source "$PLAN"; printf '%s' "$1" | ci_needs_macos); }
wmac() { local got; got="$(mac "$2")"; [[ "$got" == "$3" ]] && ok "맥 $1 → $3" || fail "맥 $1: got $got, want $3"; }
wmac "규약 .md 만"                 $'core/protocols/help.md\nREADME.ko.md'   no
wmac "VERSION + CHANGELOG"         $'VERSION\nCHANGELOG.md'                  no
wmac "셸 스크립트 하나라도"          $'core/protocols/help.md\ncore/scripts/help.sh' yes
wmac "워크플로"                     $'.github/workflows/core-ci.yml'          yes
wmac "JSON 같은 데이터 파일"         $'core/actions.json'                      yes
wmac "빈 목록은 애매 → 맥도"         ''                                        yes

# 순수: 같은 입력 → 같은 출력, 저장소를 건드리지 않는다
a="$(judge $'VERSION\nCHANGELOG.md')"; b="$(judge $'VERSION\nCHANGELOG.md')"
[[ "$a" == "$b" ]] && ok "같은 입력 → 같은 출력" || fail "출력이 바뀜"

# 기준 커밋이 없거나 못 읽으면 전체
out="$(cd "$ROOT" && bash "$PLAN" 2>&1)"
[[ "$out" == $'docs_only=no\nmacos=yes' ]] && ok "기준 커밋 없음 → 전체 + 맥" || fail "기준 없음: $out"
out="$(cd "$ROOT" && bash "$PLAN" 0000000000000000000000000000000000000000 2>&1)"
[[ "$out" == $'docs_only=no\nmacos=yes' ]] && ok "읽지 못하는 기준 → 전체 + 맥" || fail "못 읽는 기준: $out"

echo "test-ci-plan: PASS=$PASS FAIL=$FAIL"
(( FAIL == 0 ))
