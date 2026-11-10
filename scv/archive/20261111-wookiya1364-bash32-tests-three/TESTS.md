# Test Plan — bash 3.2 에서 실패하는 시험 셋 고치기

## Overview

세 시험이 맥 기본 bash(3.2)와 bash 5 양쪽에서 통과하는지, 그리고 고치면서 검사 수가 줄지 않았는지를 본다.

## Test scenarios

### T1. test-graph — bash 3.2

- **Setup**: 없음.
- **Run**: `/bin/bash core/tests/test-graph.sh` (맥 기본 3.2).
- **Expected**: 모든 검사 통과.
- **Pass criterion**: 종료 코드 0. (고치기 전에는 0 이 아님)

### T2. test-guard-consistency — bash 3.2

- **Setup**: 없음.
- **Run**: `/bin/bash tests/test-guard-consistency.sh`.
- **Expected**: 모든 검사 통과.
- **Pass criterion**: 종료 코드 0, 파일에 `mapfile` · `readarray` 0건.

### T3. test-promote-wait — bash 3.2

- **Setup**: 없음.
- **Run**: `/bin/bash tests/test-promote-wait.sh`.
- **Expected**: 모든 검사 통과.
- **Pass criterion**: 종료 코드 0.

### T4. 세 시험 — bash 5

- **Setup**: 없음.
- **Run**: bash 5 로 세 시험.
- **Expected**: 고치기 전과 같이 통과.
- **Pass criterion**: 셋 다 종료 코드 0.

### T5. 검사 수가 줄지 않음

- **Setup**: 고치기 전 bash 5 로 세 시험의 통과 줄 수를 적어 둠.
- **Run**: 고친 뒤 bash 3.2 · bash 5 로 세 시험의 통과 줄 수를 셈.
- **Expected**: 고친 뒤의 수 ≥ 고치기 전의 수.
- **Pass criterion**: 세 시험 모두 조건이 참. 건너뜀 줄 0건.

### T6. 스크립트를 고친 경우 — 그 스크립트의 다른 시험

- **Setup**: 2단계에서 스크립트가 원인으로 나온 경우에만.
- **Run**: 그 스크립트를 부르는 시험을 두 bash 로.
- **Expected**: 통과.
- **Pass criterion**: 종료 코드 0. (스크립트를 고치지 않았으면 "해당 없음"으로 적음)
- **결과(2026-11-11)**: 해당함 — 그래프 스크립트(`core/scripts/lib/graph.sh`)의 빈 배열 펼치기가 원인이었다. 그 스크립트를 부르는 시험은 `test-graph` 하나이고 두 bash 에서 통과했다(전체 105개도 통과).

### T7. 전체 시험

- **Setup**: 없음.
- **Run**: 전체 시험을 4개씩 나눠 두 bash 로.
- **Expected**: 이 변경 때문에 새로 실패한 시험 0개. bash 3.2 의 기존 실패 셋은 이제 통과.
- **Pass criterion**: bash 3.2 실패 목록에 세 시험이 없음.

## How to run

```bash
/bin/bash core/tests/test-graph.sh && /bin/bash tests/test-guard-consistency.sh && /bin/bash tests/test-promote-wait.sh
```

## Pass criteria

- T1–T7 통과(T6 은 해당할 때만).
- PR 검사(맥 · 리눅스) 통과.

## Related Documents

- [`PLAN.md`](./PLAN.md)
