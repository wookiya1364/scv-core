# Test Plan — 답 모양 검사는 이번 턴의 답만 본다 — 기록 경합 제거

## Overview

종료 훅이 린트에 넘기는 본문이 언제나 "이번 턴의 답" 이거나 "없음(생략)" 임을, 호스트 값이 있는 경우·없는 경우·원본이 늦는 경우 셋으로 검증한다. 지문 검사와 스위치 동작이 그대로임을 함께 확인하고, 따옴표 안 마침표 오탐이 사라졌는지 본다. 모든 케이스는 임시 프로젝트 디렉터리에서 실제 on-stop.sh 와 help-state.sh 를 돌린다 (test-help-echo.sh 와 같은 방식).

## Test scenarios

### T1. 호스트 값이 있으면 원본이 낡아도 그 값을 본다
- **Setup**: 표식 mark · 대화 파일에 지문 있는 Turn 추가. 원본 JSONL 에는 **이전 턴** 답(첫 문단 4문장, 위반) 만 있음. stdin JSON 에 `last_assistant_message` = 위반 없는 답.
- **Run**: on-stop.sh
- **Expected**: 드리프트 줄 `lint=0 reload=0 src=host`. 경고 파일 없음.
- **Pass criterion**: 낡은 원본의 위반이 잡히지 않는다.

### T2. 호스트 값이 없고 원본에 이번 턴 답이 있으면 그것을 본다
- **Setup**: stdin JSON 에 `transcript_path` 만. 원본: 사용자 프롬프트 항목 → 어시스턴트 텍스트(위반 4문장).
- **Run**: on-stop.sh
- **Expected**: `lint=1 reload=1 src=transcript`, 경고 파일에 답 모양 경고.
- **Pass criterion**: 이번 턴 답의 위반이 잡힌다.

### T3. 호스트 값이 없고 원본이 늦으면(이번 턴 답이 아직 없음) 검사를 건너뛴다
- **Setup**: 원본: 이전 턴 답(위반) → 이번 턴 사용자 프롬프트 항목, 그 뒤 어시스턴트 텍스트 없음.
- **Run**: on-stop.sh (재시도 창 안에 아무것도 안 적힘)
- **Expected**: `lint=0 reload=0 src=none`, 경고 파일 없음, 표식 protocol 그대로 1.
- **Pass criterion**: 낡은 답을 보지 않고, 없음을 통과로 세지도 않는다. 훅 실행 시간 ≤ 2초.

### T4. 원본이 재시도 창 안에 따라잡으면 그것을 본다
- **Setup**: T3 과 같되, 배경 프로세스가 300ms 뒤 이번 턴 어시스턴트 텍스트(위반)를 원본에 append.
- **Run**: on-stop.sh
- **Expected**: `lint=1 src=transcript`.
- **Pass criterion**: 재시도가 실제로 동작한다.

### T5. 도구 결과 항목은 턴 경계가 아니다
- **Setup**: 원본: 사용자 프롬프트 → 어시스턴트 도구 호출 → 사용자 tool_result 항목 → 어시스턴트 텍스트(이번 턴 답).
- **Run**: on-stop.sh (호스트 값 없음)
- **Expected**: 이번 턴 답이 본문으로 선택된다(`src=transcript`), tool_result 뒤라서 잘리지 않는다.
- **Pass criterion**: 턴 경계는 사람이 쓴 프롬프트 항목만이다.

### T6. 따옴표·괄호 안 마침표는 문장 끝이 아니다
- **Setup**: 첫 문단 = `공유 대화의 결론은 같습니다. "코드는 빌려 쓰고, 그래프는 직접 만든다." 로 정리돼 있었고 저장했습니다.` (문장 2개), 상한 2.
- **Run**: help-state.sh stop 에 본문으로 전달 (호스트 값 경로)
- **Expected**: `lint=0`. 같은 문단에 문장 하나를 더 붙이면 `lint=1` (lead-sentences=3>2).
- **Pass criterion**: 따옴표 안 마침표가 세어지지 않고, 실제 3문장은 여전히 잡힌다.

### T7. 드리프트 줄 형식 — 기존 토큰 그대로, 끝에 src 하나
- **Setup**: T1·T2·T3 의 드리프트 줄.
- **Run**: 정규식 `^[0-9T:+-]+ turn=[0-9]+ echo=[a-z]+ lint=[0-9]+ reload=[01] src=(host|transcript|none)$`
- **Expected**: 세 줄 모두 일치. 0.50.0 형식의 옛 줄(src 없음)도 앞부분 정규식으로 그대로 집계된다.
- **Pass criterion**: 기존 집계가 깨지지 않는다.

### T8. 지문 검사는 출처와 무관하게 그대로
- **Setup**: T1 과 같되 대화 파일의 Turn 에 지문 줄 없음.
- **Run**: on-stop.sh
- **Expected**: `echo=missing reload=1`, 경고는 지문 경고. src 는 host.
- **Pass criterion**: 지문 판정이 이 계획으로 바뀌지 않았다.

### T9. 스위치 off 는 0.49.1 과 같다
- **Setup**: SCV_ANSWER_LINT=off + SCV_HELP_ECHO=off. T2 의 원본.
- **Run**: on-stop.sh
- **Expected**: 드리프트·경고·표식 파일이 생기거나 바뀌지 않음 (cksum 동일). 재시도도 하지 않아 즉시 종료.
- **Pass criterion**: 읽지도 쓰지도 않는다.

### T10. 깨진 입력에도 exit 0
- **Setup**: stdin 이 JSON 이 아님 / transcript_path 가 없는 파일 / jq 없음(PATH 비움).
- **Run**: on-stop.sh
- **Expected**: 모두 exit 0, scv/journal/ 밖에 아무 파일도 생기지 않음.
- **Pass criterion**: non-blocking 보장 유지.

### T11. 기존 검사 회귀 없음
- **Setup**: 없음
- **Run**: `bash core/tests/test-help-echo.sh`
- **Expected**: 62/62 (경합 케이스를 여기에 추가하면 그 수만큼 증가).
- **Pass criterion**: 전부 녹색.

## How to run

```bash
bash core/tests/test-answer-lint-source.sh && bash core/tests/test-help-echo.sh
```

## Pass criteria

- T1~T11 전부 녹색.
- `bash core/tests/run-dry.sh` 와 코어 검사 러너 녹색.
- 실사용 한 세션(5턴 이상) 드리프트 로그에 `src=host` 만 찍히고, 경고가 난 턴의 답 첫 문단에 실제 위반이 있다.

## Related Documents

- core/tests/test-help-echo.sh — 같은 임시 프로젝트 방식의 기존 검사
