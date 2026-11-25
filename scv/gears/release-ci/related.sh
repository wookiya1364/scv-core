#!/usr/bin/env bash
# related.sh — 바뀐 파일과 관련된 시험만 고른다(릴리스 전 로컬 검사). 전체 검사는 깃허브가 한 번만 돈다.
# 고르는 법: 바뀐 시험 파일 + 바뀐 파일의 이름을 글에 담은 시험. 시간을 재는 시험(serial 표시)은 뺀다 — 이 컴퓨터의 부하에 흔들린다.
# 쓰는 법: bash scv/gears/release-ci/related.sh [<기준 가지>=origin/develop] → 시험 경로를 한 줄씩(없으면 아무것도 내지 않음)
base="${1:-origin/develop}"
changed="$( { git diff --name-only "$base"...HEAD 2>/dev/null; git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } | LC_ALL=C sort -u )"
[ -n "$changed" ] || exit 0
tests="$(ls core/tests/test-*.sh tests/test-*.sh 2>/dev/null)"
{
  printf '%s\n' "$changed" | grep -E '^(core/tests|tests)/test-[^/]*\.sh$'
  printf '%s\n' "$changed" | grep -vE '^(core/tests|tests)/|^scv/|\.md$' | while IFS= read -r f; do
    b="$(basename "$f")"; [ -n "$b" ] || continue
    printf '%s\n' "$tests" | xargs grep -lF -- "$b" 2>/dev/null
  done
} | LC_ALL=C sort -u | while IFS= read -r t; do
  [ -f "$t" ] || continue
  head -n 30 "$t" | grep -Eq '^# scv-test: (serial|aggregate)([[:space:]]|$)' && continue
  printf '%s\n' "$t"
done
