# Test Plan — 단계 보고 — 구현 중 단계가 바뀌면 대시보드에 저절로

## Overview

사용자가 원한 것은 구현 중 단계가 바뀔 때 대시보드가 저절로 따라오는 것이다. 칸이 비면 아무것도 바뀌지 않는지, 칸이 있고 구현 중일
때만 한 줄이 나오는지, 규약이 시점을 말하는지를 본다. 실제 대시보드 표시는 릴리스 뒤 사용자가 확인한다.

## Test scenarios

### T1. 칸이 비면 0줄

- **Setup**: 호스트 설정에 단계 보고 칸 없음, 구현 중 계획 1개.
- **Run**: `scripts/step-report.sh line`
- **Expected**: 출력 0줄, 종료 코드 0.
- **Pass criterion**: 출력 바이트 0, 종료 코드 0.

### T2. 칸이 있고 구현 중이면 1줄

- **Setup**: 칸 `SCV_STEP_TOOL=demo_step`, promote 에 `status: in_progress` 계획 1개.
- **Run**: 같은 명령.
- **Expected**: 한 줄, 도구 이름 `demo_step` 와 계획 이름이 들어 있음, 400바이트 이하.
- **Pass criterion**: 줄 수 1, 바이트 ≤ 400.

### T3. 칸이 있어도 구현 중 계획이 없으면 0줄

- **Setup**: 칸 있음, 계획은 모두 `planned`.
- **Pass criterion**: 출력 바이트 0.

### T4. 매 턴 훅에 실리고, 칸이 비면 훅 출력이 그대로

- **Run**: `test-step-report.sh` 가 훅을 칸 없이 · 있게 두 번 돌려 비교.
- **Pass criterion**: 칸 없음 → 단계 줄 0개, 칸 있음 → `[SCV 단계]` 줄 1개.

### T5. 규약이 시점을 말한다

- **Pass criterion**: work · codegen 에 '단계 보고' 절이 각각 1개, 시작 · 끝 · 막힘 세 상태가 모두 적힘.

### T6. 코어 시험 · 크기 예산 · 호스트 중립

- **Run**: `bash tests/run.sh` · `bash core/tests/run-dry.sh`
- **Pass criterion**: 둘 다 실패 0.

## How to run

```bash
bash core/tests/test-step-report.sh && bash tests/run.sh && bash core/tests/run-dry.sh >/dev/null
```

## Pass criteria

- 위 명령 종료 코드 0. 대시보드 실제 표시(1/4 → 2/4 …)는 릴리스 뒤 사용자 확인.
