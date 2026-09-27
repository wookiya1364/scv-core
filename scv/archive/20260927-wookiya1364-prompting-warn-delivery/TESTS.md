# Test Plan — 모델별 프롬프팅 — 가이드 경고가 모델에게 닿게 한다

## Overview

순수부(경고 문장 · 보존 필터)는 전수 검사, 흐름은 임시 저장소에서 help → 멈춤 훅 → 세션 시작 훅(재개) → 매 턴 훅 순서로 본다.

## Test scenarios

### T1. 순수부

- **Run**: 경고 문장에 상세 줄이 들여 써 붙는다(안 읽음만), 상세 줄 없으면 이전과 같다. 보존 필터: 가이드 블록만 남김 ·
  규약 지문 경고 제거 · 섞인 경우 · 빈 입력.
- **Pass criterion**: `OK [T15]` 전수 통과.

### T2. 재개를 건너 경고가 닿는다

- **Run**: help load → 표시 없이 멈춤 훅 → 세션 시작 훅(source resume) → 매 턴 훅 출력.
- **Expected**: 매 턴 훅 출력에 가이드 경고와 원문 경로 · 표시 명령 줄. 같은 흐름에서 규약 지문 경고는 사라진다.
- **Pass criterion**: `OK [T16]`.

### T3. 기존 검사 전부

- **Run**: 코어 테스트 전부 · 코덱스 벤더 사본(격리)에서 코어 테스트 전부.
- **Pass criterion**: 초록(기존 사본 전용 현상 제외 — test-guidance 한 건).

## How to run

```bash
bash core/tests/test-model-prompting.sh && bash core/tests/test-help-budget.sh
```

## Pass criteria

- T1 ~ T3 초록. 설치본 헤드리스 두 턴 실측에서 2턴 훅 주입에 가이드 경고가 보인다.

## Related Documents

- `core/contracts/purity.md`
