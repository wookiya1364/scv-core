# Test Plan — 턴 끝 확인이 멈추지 않게

## Overview

긴 세션에서 쌓인 쓴 파일 목록과 큰 커밋 차이로도 턴 끝 확인 · 쓰기 전 확인이 제한 시간 안에 끝나고, 판정은 지금과 같은지 본다. 시험은 합성 자료만 쓴다(다른 프로젝트 이름 · 경로 없음).

## Test scenarios

### T1. 중복 많은 큰 목록으로 '내 파일만' 비교

- **Setup**: 서로 다른 파일 5,000개를 100번씩 되풀이한 목록(50만 줄), 바뀐 경로 2,000개(절반은 목록에 있음).
- **Run**: scv_tc_mine_only 를 부른다.
- **Expected**: 목록에 있는 1,000개만 남는다(순서 · 내용이 옛 함수 결과와 같음).
- **Pass criterion**: 결과 같음, 2초 안.

### T2. 걸러내기 결과가 같고 빠름

- **Setup**: 경로 2,000개, 뺄 규칙 3개(정확히 · 끝 일치 섞어서).
- **Run**: scv_tc_filter.
- **Expected**: 옛 함수와 같은 줄들.
- **Pass criterion**: 결과 같음, 2초 안.

### T3. 쓴 파일 목록에 같은 파일을 다시 쓰지 않음

- **Setup**: 시험 저장소에서 턴 시작 뒤 같은 파일에 쓰기 확인(touch) 50번.
- **Run**: turn-check.sh touch 50번 후 목록 파일을 센다.
- **Expected**: 그 파일 줄은 1개.
- **Pass criterion**: 줄 수 1.

### T4. 큰 상태로 턴 끝 확인이 5초 안에 끝나고 판정 같음

- **Setup**: 시험 저장소, 시작 기준 뒤 커밋으로 2,000개 파일 바뀜, 쓴 파일 목록 50만 줄(중복 포함).
- **Run**: turn-check.sh end.
- **Expected**: 지금과 같은 판정 줄(TURN_PLAN: …), 끝 표시 파일 생김.
- **Pass criterion**: 10초 안 · 판정 같음 · 끝 표시 있음.

### T5. 시간 예산을 넘으면 통과 + 생략 기록 + 끝 표시

- **Setup**: 예산을 아주 작게(설정값) 둔 시험 저장소.
- **Run**: turn-check.sh end.
- **Expected**: 통과, 기록 파일에 '확인 생략' 한 줄, 끝 표시 있음 → 다음 start 가 새 턴으로 시작.
- **Pass criterion**: 세 가지 모두.

### T5a. 종료 훅이 죽어도 다음 턴은 새로 열림, 도중에 온 말은 이어짐

- **Setup**: 시험 저장소에서 턴 시작 → 파일 쓰기.
- **Run**: (가) '멈춤 시작' 표시만 남기고 턴 끝 확인은 돌리지 않음(시간 초과로 죽은 경우) → 새 요청 start. (나) 종료 훅 없이 새 요청 start(일하는 중 온 말). (다) 턴 끝 확인이 막음 → 새 요청 start.
- **Expected**: (가) 새 턴 — 쓴 파일 목록 · 시작 기준 비워짐. (나) 같은 턴 — 요청 글에 '(도중에 온 말)' 덧붙음. (다) 같은 턴.
- **Pass criterion**: 세 경우 모두 기대대로.

### T6. 기존 턴 확인 시험 그대로 통과

- **Run**: 기존 턴 확인 · 오거절 · 마무리 보고 시험.
- **Pass criterion**: 모두 통과(판정 바뀌지 않음).

### T7. 쓰기 전 확인이 큰 상태에서 1초 안

- **Setup**: T4 와 같은 큰 상태, 셸 명령 뒤 대기 사진 있음.
- **Run**: turn-check.sh touch.
- **Pass criterion**: 1초 안(맥 · 리눅스).

## How to run

```bash
bash core/tests/test-turn-check-fast-end.sh && bash core/tests/test-turn-plan-check.sh && bash core/tests/test-false-rejects.sh
```

## Pass criteria

- T1–T7 · T5a 통과, 맥 · 리눅스 둘 다.
- 측정 복사본(로컬, 저장소 밖)으로 턴 끝 확인 5초 안 — 결과는 마무리 보고에 수치로.
- 순수성 검사 · 사전 검사 통과.
