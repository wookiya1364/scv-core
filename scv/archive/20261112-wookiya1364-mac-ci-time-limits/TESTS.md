# Test Plan — 맥 검사의 시간 한도 둘

## Overview

코어 PR 검사의 맥 조각이 7개 · 한도 15분으로 바뀌었는지, 그 수가 어긋나면 시험이 잡는지, 래퍼의 맥 검사 한도가 10분으로 바뀌고 한도를 지키는 시험이 그것을 보는지 확인한다. 실제 러너에서의 시간은 올린 PR 에서 읽는다.

## Test scenarios

### T1. 코어 맥 조각은 7개, 한도 15분

- **Setup**: 코어의 PR 검사 설정.
- **Run**: `bash tests/test-release-verify.sh`
- **Expected**: 맥 조각 작업의 이름 · 조각 목록 · 명령의 조각 수가 모두 7이고 한도가 15분이다.
- **Pass criterion**: `✓ 맥 조각 설정에 문제 없음` 과 `✓ 맥 조각은 일곱 · 한도 15분` 줄.

### T2. 어긋난 설정은 잡는다

- **Setup**: 설정을 세 가지로 바꿔 본다 — 조각 목록만 다섯으로, 명령의 조각 수만 5로, 이름의 조각 수만 5로.
- **Run**: T1 과 같은 실행(시험이 바꿔 본 사본으로 확인한다).
- **Expected**: 세 가지 모두 "조각 수가 어긋난다"로 잡힌다.
- **Pass criterion**: `✓ 맥 조각 목록을 다섯으로 → 잡음` · `✓ 맥 명령의 조각 수를 5로 → 잡음` · `✓ 맥 이름의 조각 수를 5로 → 잡음` 줄.

### T3. 맥 시간표는 7조각으로 고르게 나뉜다

- **Setup**: 맥 시간표(시험 114개 · 합 1,696초).
- **Run**: T1 과 같은 실행.
- **Expected**: 가장 긴 시험(165초)이 조각 평균(242초)보다 짧고, 가장 무거운 조각과 가장 가벼운 조각의 차이가 5초 안이다.
- **Pass criterion**: `맥(PR 검사 7조각)` 으로 시작하는 `✓` 줄 셋, 실행의 마지막 줄 `FAIL=0`.

### T4. 래퍼의 맥 검사는 10분, 리눅스는 6분

- **Setup**: 클로드 래퍼의 검사 설정.
- **Run**: 래퍼 저장소에서 `bash .github/scripts/test-ci-fast-lanes.sh`
- **Expected**: 맥 갈래의 한도가 10분, 리눅스 갈래는 6분이다. 다른 자동 작업의 한도는 그대로다.
- **Pass criterion**: 종료 코드 0. 한도 줄을 예전 값(`timeout-minutes: 6`)으로 되돌리면 종료 코드가 0이 아니다.

### T5. 코어 PR 의 맥 조각 7개가 통과한다

- **Setup**: 이 변경을 올린 코어 PR.
- **Run**: PR 검사.
- **Expected**: `Shard (macos 1/7)` ~ `Shard (macos 7/7)` 이 모두 통과하고 `Contracts (macos-latest)` 가 통과한다.
- **Pass criterion**: 맥 조각 7개의 결과가 모두 `success`, 가장 긴 조각이 600초 미만(예전 한도) — 값을 PLAN.md 에 적는다.

### T6. 래퍼 PR 의 검사가 통과한다

- **Setup**: 이 변경을 올린 래퍼 PR.
- **Run**: PR 검사.
- **Expected**: `Contract (macos-latest)` · `Contract (ubuntu-latest)` 가 통과한다.
- **Pass criterion**: 두 검사의 결과가 `success`.

## How to run

```bash
bash tests/test-release-verify.sh
```

## Pass criteria

- `bash tests/test-release-verify.sh` 의 마지막 줄이 `FAIL=0` 으로 끝나고 종료 코드 0 — 옛 셸과 새 셸 모두 (T1 ~ T3)
- 래퍼의 `bash .github/scripts/test-ci-fast-lanes.sh` 종료 코드 0 (T4)
- 코어 PR 의 맥 조각 7개가 모두 `success` (T5), 래퍼 PR 의 두 검사가 `success` (T6)

## Related Documents
