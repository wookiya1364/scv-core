# Test Plan — 큰 시험 파일 나누기

## Overview

나눈 조각과 묶음, 목록 건너뛰기를 본다.

## Test scenarios

### T1. 조각 통과 합계 = 원래
- **Run**: 조각을 각각 돌림
- **Expected**: 모두 통과, 통과 줄 합계 선택지 89 · 실체 보여 주기 78
- **Pass criterion**: 개수 일치

### T2. 원래 이름(묶음)은 전부를 돌림
- **Run**: `bash core/tests/test-choice-questions.sh`, `bash core/tests/test-show-real.sh`
- **Expected**: 통과, 같은 개수
- **Pass criterion**: 종료 코드 0

### T3. 전체 시험은 묶음을 건너뜀
- **Run**: run-focused 목록
- **Expected**: 묶음 파일이 목록에 없고 조각은 있음
- **Pass criterion**: grep

## How to run

```bash
bash core/tests/test-choice-questions.sh >/dev/null && bash core/tests/test-show-real.sh >/dev/null && bash core/tests/test-run-focused.sh >/dev/null && bash core/tests/test-regression-dedupe.sh >/dev/null && bash tests/run.sh >/dev/null
```

## Pass criteria

- T1–T3 통과, 전체 시험 · 회귀 통과
