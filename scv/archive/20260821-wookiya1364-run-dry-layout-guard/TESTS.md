# Test Plan — run-dry 배치 가드

## Overview

run-dry 가 (1) scv-core 체크아웃에서 그대로 통과하고 (2) 부모에 TEMPLATE_VERSION 이 없는
복사본 배치(래퍼 투영 흉내)에서도 통과하는지 확인한다.

## Test scenarios

### T1. scv-core 배치 — 기존대로 전부 통과
- **Pass criterion**: `run-dry.sh` FAIL 0

### T2. 단일 복사본 배치 — 부모에 TEMPLATE_VERSION 없음
- **Setup**: 페이로드를 래퍼처럼 한 디렉터리에 펼친다 — `cp -RL core/. X/w/`(심볼릭 링크
  `core/TEMPLATE_VERSION → ../TEMPLATE_VERSION` 을 실파일로 역참조), `X/TEMPLATE_VERSION` 없음
- **Run**: `bash X/w/tests/run-dry.sh`
- **Pass criterion**: FAIL 0, 출력에 `single-copy payload layout`

### T3. 스위트
- **Pass criterion**: `tests/run.sh` · `core/tests/test-*.sh` 전부 exit 0

## How to run

```bash
bash -euo pipefail -c '
fail() { echo "FAIL: $1"; exit 1; }
bash core/tests/run-dry.sh >/dev/null || fail "T1 run-dry (scv-core 배치)"
X=$(mktemp -d); trap "rm -rf $X" EXIT
mkdir -p "$X/w"; cp -RL core/. "$X/w/"; [ ! -e "$X/TEMPLATE_VERSION" ] || fail "T2 setup"
[ -f "$X/w/TEMPLATE_VERSION" ] && [ ! -L "$X/w/TEMPLATE_VERSION" ] || fail "T2 setup: TEMPLATE_VERSION 실파일이어야"
out=$( cd "$X/w" && bash tests/run-dry.sh 2>&1 ) || { printf "%s\n" "$out" | grep -E "^  - " | head -5; fail "T2 run-dry (단일 복사본 배치)"; }
printf "%s\n" "$out" | grep -qF "single-copy payload layout" || fail "T2 단일 복사본 분기 미실행"
echo "OK [T1-T2]"
bash tests/run.sh >/dev/null || fail "T3 tests/run.sh"
for t in core/tests/test-*.sh; do bash "$t" >/dev/null || fail "T3 $t"; done
echo "ALL GATES OK"
'
```

## Pass criteria

- 위 블록 exit 0.
