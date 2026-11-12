# Test Plan — 재지 못한 함수만 다시 재기

## Overview

재는 명령이 "재지 못함"이 나온 함수만 다시 재는지, 처음에 잰 함수는 더 재지 않는지, 계속 못 재면 "재지 못함"으로 남는지 확인한다. 실제 맥 러너에서의 효과는 측정 실행으로 전과 견준다.

## Test scenarios

### T1. 다시 잴지 정하는 순수 함수

- **Setup**: 값만 넣는다.
- **Run**: `pb_remeasure` 에 (재지 못함 · 0번 · 한도 2), (재지 못함 · 2번 · 한도 2), (cpu · 0번 · 한도 2), (재지 못함 · 0번 · 한도 0), (wall-gpu · 0번 · 한도 2).
- **Expected**: 차례로 1 · 0 · 0 · 0 · 0.
- **Pass criterion**: 시험 줄 `OK [S13b remeasure decision]`, 함수 사전 검사가 `OK  catalog:` 로 시작하는 줄을 낸다.

### T2. 한 번 못 재고 다시 재서 잰다

- **Setup**: 가짜 시간 도구 — 함수를 처음 잴 때는 벽시계 0.90초 · CPU 0.30초(비율 3)를 보고하고, 같은 되풀이 수로 다시 잴 때는 벽시계와 CPU 가 같은 값을 보고한다.
- **Run**: 임시 함수 `t_up` 하나를 잰다(기록 파일을 준다).
- **Expected**: 잣대가 `cpu` 다. 기록 파일에 그 함수가 한 번 다시 재였다고 적힌다. 표 아래에 "다시 잰 함수" 줄이 있다.
- **Pass criterion**: 시험 줄 `OK [S13b] measured on the second try` 와 `OK [S13b] the table says which function was measured again`.

### T3. 계속 못 재면 "재지 못함"으로 남는다

- **Setup**: 가짜 시간 도구가 늘 비율 3을 보고한다.
- **Run**: 같은 함수를 잰다.
- **Expected**: 잣대가 `unmeasured` 다. 다시 잰 횟수는 정확히 2번이다.
- **Pass criterion**: 시험 줄 `OK [S13b] still unmeasured after two more tries`.

### T4. 처음에 잰 함수는 더 재지 않는다, 끄면 다시 재지 않는다

- **Setup**: (가) 가짜 도구가 늘 좋은 값(벽시계 0.31초 · CPU 0.30초)을 보고한다 — 진짜 도구는 붐비는 컴퓨터에서 결과가 달라져 쓰지 않는다. (나) 가짜 도구(늘 비율 3)와 `SCV_PB_REMEASURE=0`.
- **Run**: 같은 함수를 잰다.
- **Expected**: (가) 기록 파일이 비어 있다. (나) 잣대는 `unmeasured` 이고 기록 파일이 비어 있다.
- **Pass criterion**: 시험 줄 `OK [S13b] a measured function is not measured again` 과 `OK [S13b] off: no second try`.

### T5. 기존 시험은 그대로

- **Setup**: 재는 명령 시험 넷(a ~ d)과 엮음 고르기 · 느린 함수 시험.
- **Run**: 두 셸에서 돌린다.
- **Expected**: 모두 통과한다. 잰 줄의 칸 수와 표의 끝 줄이 그대로다.
- **Pass criterion**: `test-pure-bench-a.sh` 의 끝 줄이 `0 failed`, 나머지 파일도 종료 코드 0.

### T6. 실제 맥 러너에서 전과 견주기

- **Setup**: 코어 저장소의 측정용 브랜치에 고친 재는 명령을 넣는다.
- **Run**: 7번 조각의 시험을 먼저 돌린 맥 러너 3대에서 임시 함수 셋을 48줄씩 잰다.
- **Expected**: "재지 못함" 줄이 전(0 · 2 · 11)보다 줄어든다.
- **Pass criterion**: 세 러너의 "재지 못함" 줄 수의 합이 전의 합 13보다 작고, 값이 PLAN.md 에 적혀 있다. 러너의 상태는 실행마다 달라 같은 조건이 아니다 — 다시 잰 횟수도 함께 적는다.

## How to run

```bash
bash core/tests/test-pure-bench-a.sh
```

## Pass criteria

- `bash core/tests/test-pure-bench-a.sh` 의 끝 줄이 `0 failed` 로 끝나고 종료 코드 0 — 옛 셸과 새 셸 모두 (T1 ~ T5)
- 함수 사전 검사가 `OK  catalog:` 로 시작하는 줄을 낸다
- T6: "재지 못함" 줄 수의 합이 13보다 작다
- PR 검사의 모든 항목이 `success`

## Related Documents
