# Test Plan — 다시 쓴 요청에 한국어판 STE 목록 적용

## Overview

korean 이면 가이드 안내에 목록이 세션마다 한 번 실리는지, 다른 언어 · off 이면 실리지 않는지, 절차 문서가 목록을 가리키는지 본다.

## Test scenarios

### T1. korean 이면 목록 전문을 한 번 싣는다

- **Run**: `bash core/tests/test-rewrite-ste.sh` (S1 · S2)
- **Expected**: 첫 guide 출력에 `STE:` 와 R1 · R15, 같은 지문의 두 번째 출력은 `STE: (이 세션에 이미 실음` 한 줄
- **Pass criterion**: `ok S1` · `ok S2`

### T2. 다른 언어 · off 이면 싣지 않는다

- **Run**: `bash core/tests/test-rewrite-ste.sh` (S3 · S4)
- **Expected**: SCV_LANG english · SCV_REWRITE_STE=off 이면 `STE` 줄 없음
- **Pass criterion**: `ok S3` · `ok S4`

### T3. 절차 문서가 목록을 가리킨다 · 구역 고르기 순수부

- **Run**: `bash core/tests/test-rewrite-ste.sh` (S5 · S6)
- **Pass criterion**: `── test-rewrite-ste: 6 passed`

## How to run

```bash
bash core/tests/test-rewrite-ste.sh
bash core/tests/test-model-prompting.sh
bash core/tests/test-instruction-conflicts.sh
```

## Pass criteria

모든 명령 exit 0.
