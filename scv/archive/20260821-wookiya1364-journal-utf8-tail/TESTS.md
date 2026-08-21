# Test Plan — 기록 훅의 바이트 자르기가 한글을 반으로

## Overview

긴 한글 답변(3바이트 글자)을 기록했을 때 일지가 유효한 UTF-8 이고 꼬리가 살아
있는지, 기존 기록 계약(비차단·리댁션·작성자 귀속)이 그대로인지 확인한다.

## Test scenarios

### T1. 다국어 긴 답변 — 일지는 유효한 UTF-8, 꼬리 생존 (test-journal [6u])
- **Pass criterion**: `test-journal.sh` 전량 통과

### T2. 스위트
- **Pass criterion**: run-dry · tests/run.sh · core/tests/test-*.sh 전부 exit 0

## How to run

```bash
bash -euo pipefail -c '
fail() { echo "FAIL: $1"; exit 1; }
bash core/tests/test-journal.sh >/dev/null || fail "T1 test-journal"
grep -qF "iconv -c -f UTF-8 -t UTF-8" core/template/hooks/on-stop.sh || fail "T1 on-stop 에 UTF-8 정리 없음"
echo "OK [T1]"
bash core/tests/run-dry.sh >/dev/null || fail "T2 run-dry"
bash tests/run.sh >/dev/null || fail "T2 tests/run.sh"
for t in core/tests/test-*.sh; do bash "$t" >/dev/null || fail "T2 $t"; done
echo "ALL GATES OK"
'
```

## Pass criteria

- 위 블록 exit 0.
