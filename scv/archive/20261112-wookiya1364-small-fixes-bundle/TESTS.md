# Test Plan — 작은 고침 묶음

## Overview

가장 긴 시험을 넷으로 나눠도 확인하는 것이 줄지 않는지, 시간표로 나눈 조각이 고른지, 계획을 보관한 턴이 막히지 않는지, 첨부 파일의 경로가 계획 기록에 적히지 않는지, 끊김이 나던 시험이 여러 번 돌려도 통과하는지 본다.

## Test scenarios

### T1. 나눈 넷이 나누기 전과 같은 것을 확인한다

- **Setup**: 나누기 전 `core/tests/test-pure-bench.sh` 의 통과 수(이 맥 · 새 셸 196, 옛 셸 192)
- **Run**: `bash core/tests/test-pure-bench.sh` (넷을 차례로 부르는 묶음), 그리고 넷을 하나씩
- **Expected**: 넷의 통과 수 합이 나누기 전과 같고 실패가 없다. 넷은 하나씩 따로 돌려도 통과한다(서로 기대지 않는다).
- **Pass criterion**: 새 셸 합 196 · 옛 셸 합 192 · 실패 0. 가장 긴 파일이 이 맥에서 140초 아래(나누기 전 271초).

### T2. 넷 모두 혼자 돈다 표시가 있고, 묶음은 조각 실행기가 건너뛴다

- **Run**: `bash core/tests/test-run-focused.sh` · `bash tests/test-release-verify.sh`
- **Expected**: 넷 모두 앞 30줄 안에 `# scv-test: serial`, 묶음에는 `# scv-test: aggregate`. 조각 실행기가 모으는 목록에 넷이 있고 묶음은 없다.
- **Pass criterion**: 표시 4 / 4 · 조각의 합집합 = 전체 · 겹침 0.

### T3. 시간표에 모든 시험이 있고 여섯 조각이 고르다

- **Run**: `bash tests/test-release-verify.sh`
- **Expected**: 시간표 둘에 빠진 시험이 0개다. 리눅스 시간표로 나눈 여섯 조각의 합이 모두 "평균 + 가장 긴 시험" 안이고, 가장 긴 시험이 평균의 절반 아래다.
- **Pass criterion**: 빠진 시험 0 · 가장 무거운 조각 − 가장 가벼운 조각 ≤ 5초(시간표의 합 기준).

### T4. 계획을 보관한 턴이 끝에서 막히지 않는다

- **Setup**: 임시 저장소에서 2026-11-12 에 실제로 쓴 모양으로 기록 명령을 돌린다 — 경로를 변수에 담아 · 다른 명령 뒤에 이어서 · 둘째 줄에서
- **Run**: `bash core/tests/test-turn-plan-check.sh`
- **Expected**: 고치기 전 코드로는 세 모양 모두 막힌다(재현 — 도구 앞 훅이 영수증을 남기지 못한다). 고친 뒤에는 통과한다. 실패한 기록 명령 · 손으로 쓴 가짜 줄 · 이름만 적은 명령 · 예전에 보관된 계획만 있는 턴은 지금처럼 막힌다.
- **Pass criterion**: 재현 시나리오(T34)가 고치기 전 0 / 3, 고친 뒤 3 / 3. 가짜 기록 6 / 6 막힘. 이미 있는 시나리오는 모두 그대로 통과.

### T5. 첨부 파일의 경로가 계획 기록에 적히지 않는다

- **Run**: `bash core/tests/test-turn-plan-check.sh`
- **Expected**: 원문에 첨부 파일 경로가 든 요청으로 턴을 시작하고 기록을 남기면, 계획의 "요청:" 줄에 그 경로가 없다. 경로가 아닌 글은 그대로다. 첨부가 없는 요청은 한 글자도 바뀌지 않는다.
- **Pass criterion**: 순수 함수의 예시(첨부 하나 · 둘 · 없음 · 따옴표 없는 꼴)가 모두 맞고, 계획 글에 경로 0번.

### T6. 끊김이 나던 시험이 여러 번 돌려도 통과한다

- **Run**: `bash core/tests/test-journal.sh` 를 붐비는 상태(시험 넷을 함께)에서 다섯 번
- **Expected**: 다섯 번 모두 실패 0. 파일에 `printf … | bash 훅` 꼴이 남아 있지 않다.
- **Pass criterion**: 5 / 5 통과 · 그 꼴 0곳.

## How to run

```bash
bash core/tests/test-run-focused.sh && bash tests/test-release-verify.sh && bash core/tests/test-turn-plan-check.sh && bash core/tests/test-journal.sh
```

## Pass criteria

- T1 ~ T6 이 옛 셸(bash 3.2)과 새 셸(bash 5)에서 통과한다 (T1 의 긴 넷은 셸마다 한 번)
- 순수 검사 · 사전 검사 통과
- 릴리스 뒤 조각 시간은 실행 기록의 숫자로 결과 절에 적는다

## Related Documents

- `core/tests/run-focused.sh` — 조각 실행기
