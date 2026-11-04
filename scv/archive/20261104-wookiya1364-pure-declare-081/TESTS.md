# Test Plan — 모든 함수에 순수 · 부수효과 선언

## Overview

T1–T5 는 코어 시험 `core/tests/test-pure-declare.sh`, T6 은 실제 재현.

## Test scenarios

### T1. 함수 찾기
- **Setup**: sh · ts · js · py · go 본문
- **Run**: scv_pd_functions
- **Expected**: 이름 있는 함수 선언을 모두 찾음
- **Pass criterion**: 언어별 기대 목록과 같음

### T2. 선언 없는 새 함수 쓰기 거절
- **Setup**: 선언 없는 함수를 더하는 편집(Write · Edit)
- **Run**: 가드 gate-write
- **Expected**: 거절, 이유에 빠진 함수 이름
- **Pass criterion**: deny

### T3. 선언을 단 편집 통과
- **Setup**: @pure(역할 · 종류 · 예) 또는 @effect(이유) 를 단 새 함수
- **Run**: 가드
- **Expected**: 통과
- **Pass criterion**: 출력 없음

### T4. 옛 함수만 있는 파일 · 제외 폴더 · 스위치
- **Setup**: 선언 없는 옛 함수가 있는 파일의 다른 줄 편집 / tests 폴더 / SCV_PURE_DECLARE=off
- **Run**: 가드
- **Expected**: 모두 통과
- **Pass criterion**: 3/3

### T5. 목록 검사 기준선
- **Setup**: 기준선 2, 선언 없는 함수 3 / 1
- **Run**: pure-catalog.sh check --project
- **Expected**: 3 이면 실패, 1 이면 통과하고 기준선 1
- **Pass criterion**: 종료 코드 · 기준선 파일

### T6. 실제 재현 (보고용)
- **Setup**: 새 코어를 실은 플러그인, slay 같은 프로젝트
- **Run**: 선언 없는 함수를 쓰게 하는 요청
- **Expected**: 거절 뒤 선언을 달고 통과
- **Pass criterion**: 결과 보고

## How to run

```bash
bash core/tests/test-pure-declare.sh && bash core/tests/test-purity.sh >/dev/null && bash core/tests/test-guard.sh >/dev/null && bash core/tests/run-dry.sh >/dev/null && bash tests/run.sh >/dev/null
```

## Pass criteria

- T1–T5 통과, 전체 점검 통과, T6 결과 보고
