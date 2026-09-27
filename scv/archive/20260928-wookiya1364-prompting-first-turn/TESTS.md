# Test Plan — 모델별 프롬프팅 — 새 컨텍스트의 첫 턴부터 가이드 원문을 읽게 한다

## Overview

순수부(블록 문장)는 전수 검사, 흐름은 임시 저장소에서 help → 새 세션(초기화) → 매 턴 훅 순서로 본다.

## Test scenarios

### T1. 순수부

- **Run**: 스위치 off · 이미 읽음 · 가이드 경고 예약됨 · 기록 없음 · 기록 none → 빈 값. 기록 있음 · 안 읽음 → 머리 줄(기준 모델 id)과
  두 칸 들여 쓴 원문 경로 · 명령 줄.
- **Pass criterion**: `OK [T18]` 전수 통과.

### T2. 새 세션 첫 턴에 블록이 실린다

- **Run**: help load(기록 생김) → 세션 시작(startup) → 매 턴 훅 / 그 뒤 원문 표시 + 규약 표시 → 매 턴 훅 / 모르는 모델 help → 새 세션 → 매 턴 훅 /
  가이드 경고가 예약된 상태 → 매 턴 훅.
- **Expected**: 첫 경우만 블록(경로 · 명령). 읽은 뒤 · none · 경고 예약 상태에서는 블록 없음(경고 예약 상태는 경고만 한 번).
- **Pass criterion**: `OK [T19]`.

### T3. 기존 검사 · 비용

- **Run**: 코어 테스트 전부 · 코덱스 벤더 사본(격리)에서 코어 테스트 전부.
- **Pass criterion**: 초록(사본의 기존 test-guidance 한 건 제외), T12 매 턴 스택 수치 불변.

## How to run

```bash
bash core/tests/test-model-prompting.sh && bash core/tests/test-help-budget.sh
```

## Pass criteria

- T1 ~ T3 초록. 설치본 실측에서 새 세션 첫 턴에 블록이 보이고 그 턴 판정이 ok.

## Related Documents

- `core/contracts/purity.md`
