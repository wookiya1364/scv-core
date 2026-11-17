# Test Plan — 대시보드 — 함께 하는 단계는 모두 진행 중으로

## Overview

여러 단계의 시작을 알렸을 때 대시보드가 모두 받고 모두 진행 중으로 그리는지, 한 단계가 끝나도 다른 단계가 진행 중으로 남는지,
차례로 하는 계획의 화면은 그대로인지 본다. 대시보드에 단계 알림을 보내고 답 글과 화면 글을 읽는다 — 틀은
`hooks/register.test.tsx` 의 `step-signal` 시험을 따른다.

## Test scenarios

### T1. 두 단계의 시작을 차례로 알리면 둘 다 진행 중이다

- **Setup**: 다섯 단계 계획(진행 중 상태). 1단계를 끝으로 알린다.
- **Run**: 2단계 시작, 이어서 4단계 시작을 알린다. 화면을 그린다.
- **Expected**: 두 알림 모두 받아들여진다. 둘째 답 글에 `진행 중: 2 · 4단계` 가 들어 있다. 화면의 세는 줄은 `완료 1 · 진행 2 · 막힘 0 · 대기 2`, 맨 위 한 줄은 `2 · 4단계 진행 중` 으로 시작하고, `지금 여기` 표시는 2개다.
- **Pass criterion**: 거절 0 · 답 글에 `진행 중: 2 · 4단계` · 세는 줄이 `완료 1 · 진행 2 · 막힘 0 · 대기 2 — 단계를 누르면 자세히` 와 글자까지 같음 · `지금 여기` 2개 — 고치기 전 코드에서는 4단계 시작이 거절되어 실패한다.

### T2. 한 단계가 끝나도 다른 단계는 진행 중으로 남는다

- **Setup**: T1 뒤의 상태(2 · 4단계 진행 중).
- **Run**: 2단계를 끝으로 알린다. 화면을 그린다.
- **Expected**: 답 글이 `진행 2/5` 와 `진행 중: 4단계` 를 말한다. 4단계는 진행 중으로 남고, 아무도 시작을 알리지 않은 3단계는 대기다(진행 중이라고 알린 단계가 있는 동안에는 '끝나지 않은 첫 단계는 진행 중'이라는 짐작을 하지 않는다).
- **Pass criterion**: 답 글에 `2/5` 와 `진행 중: 4단계` · 단계 상태가 차례로 `done · done · waiting · doing · waiting`. 이어서 4단계를 끝으로 알리면 `done · done · doing · done · waiting` — 알린 진행이 없으니 첫 단계 규칙이 돌아온다.

### T3. 이미 끝난 단계에 시작 · 막힘을 보내면 거절한다

- **Setup**: 다섯 단계 계획. 1단계를 끝으로 알린다.
- **Run**: 1단계 시작, 1단계 막힘(이유 있음)을 알린다.
- **Expected**: 둘 다 거절되고 이유가 `1단계는 이미 끝났습니다` 다. 저장된 알림은 바뀌지 않는다.
- **Pass criterion**: 거절 이유 2건에 `1단계는 이미 끝났습니다` · 저장된 알림 1건(1단계 끝).

### T4. 뒤 단계의 막힘도 받는다 — 진행 중인 다른 단계는 그대로

- **Setup**: 다섯 단계 계획. 1단계 끝, 2단계 시작, 4단계 시작.
- **Run**: 4단계를 막힘(이유 `시험 실패`)으로 알린다. 화면을 그린다.
- **Expected**: 받아들여진다. 단계 상태가 `done · doing · waiting · blocked · waiting`. 맨 위 한 줄이 `4단계 막힘 · 2단계 진행 중` 으로 시작한다. 막힌 작업 카드에 이유가 보인다.
- **Pass criterion**: 단계 상태 다섯 개가 위와 같음 · 맨 위 한 줄이 `4단계 막힘 · 2단계 진행 중` 으로 시작 · 화면 글에 `시험 실패`.

### T5. 손으로 남은 표시는 뒤 단계를 열지 않는다 — 알린 단계만 연다

- **Setup**: 값만 넣는다 — (가) 계획 문서 표시 `[x] a`, `b`, `[~] c` (나) 같은 계획에 3단계 시작 알림 (다) 계획 문서의 진행 줄이 `3단계 시작` 을 적은 계획.
- **Run**: `mergeMarks` → `deriveStages`.
- **Expected**: (가) `done · doing · waiting` — 지금과 같다. (나) `done · waiting · doing` — 알린 진행이 있으니 표시 없는 2단계는 짐작하지 않는다. (다) `done · waiting · doing`.
- **Pass criterion**: 세 결과가 차례로 `done · doing · waiting` · `done · waiting · doing` · `done · waiting · doing`. 기존 시험 `progress T2c` 가 기대값을 바꾸지 않고 통과.

### T6. 맨 위 한 줄은 이어진 번호를 줄여 말한다

- **Setup**: 값만 넣는다 — 진행 중인 단계가 (가) 5 (나) 5 · 6 (다) 6 · 7 · 8 · 9 · 10 · 11 · 12 · 13 (라) 2 · 4 · 5 · 6 (마) 없음.
- **Run**: `activeSteps` 와 `headline`.
- **Expected**: (가) `5단계 진행 중` (나) `5 · 6단계 진행 중` (다) `6~13단계 진행 중` (라) `2 · 4~6단계 진행 중` (마) 지금과 같은 `시작 전` 또는 `모든 단계 끝`.
- **Pass criterion**: 맨 위 한 줄이 차례로 `5단계 진행 중` · `5 · 6단계 진행 중` · `6~13단계 진행 중` · `2 · 4~6단계 진행 중` · `시작 전` 으로 시작함(글자까지 같음).

### T7. 작업은 가장 늦게 시작해 아직 끝나지 않은 단계에 적힌다

- **Setup**: 값만 넣는다 — 빈 목록에서 시작.
- **Run**: `nextStarted` 에 2단계 시작 → 4단계 시작 → 4단계 끝 → 2단계 막힘을 차례로 넣는다.
- **Expected**: 목록의 마지막(작업이 적힐 단계)이 차례로 2 → 4 → 2 → 없음.
- **Pass criterion**: 네 번의 마지막 값이 2 · 4 · 2 · 없음. 같은 단계의 시작을 두 번 알려도 목록에 한 번만 있음.

### T8. 사용자 차례 · 답 기다림은 진행 중인 단계 모두에 덧칠된다

- **Setup**: 값만 넣는다 — 단계 상태 `done · doing · waiting · doing`.
- **Run**: `applyTurn(…, 'yourTurn')` 과 `applyBlocks(…, [답 기다림])`.
- **Expected**: 차례로 `done · yourTurn · waiting · yourTurn`, `done · blocked · waiting · blocked`.
- **Pass criterion**: 첫 결과가 `done · yourTurn · waiting · yourTurn`, 둘째 결과가 `done · blocked · waiting · blocked` (이 두 함수는 고치지 않는다 — 기존 동작이 여러 단계에도 그대로임을 본다).

### T9. 기존 동작 — 대시보드 시험이 통과한다

- **Setup**: 없음.
- **Run**: 대시보드 시험 전부.
- **Expected**: 실패 0. 기대값을 바꾼 기존 시험은 `step-signal T3` 한 개(뒤 단계의 시작 · 막힘 거절 → 받음, 끝난 단계 거절로 바꿈)다.
- **Pass criterion**: 실패 0 · 기대값을 바꾼 기존 시험 1개.

## How to run

```bash
cd ../scv-mods/marketplace/mods/scv-dashboard && claude plugin test .
```

## Pass criteria

- 위 명령이 종료 코드 0 — 실패 0.
- 고치기 전 코드에서 T1 의 실패 수가 1 이상이었다.

## Related Documents

- 같은 틀의 시험: `../scv-mods/marketplace/mods/scv-dashboard/hooks/register.test.tsx` 의 `step-signal`
