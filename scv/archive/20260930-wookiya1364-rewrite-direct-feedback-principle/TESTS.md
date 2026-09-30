# Test Plan — 다시 쓴 요청에 SCV 원칙을 붙인다

## Overview

등록 결과에 SCV 원칙(정확한 피드백, 단위 표 · 문제 표, 위치를 콕 집은 문제, 표 폭 기준)이 붙는지, 매 답의 인용에는 짧은 표식만
보이는지, 끄면 지금과 같은지, 종료 훅 · 매 턴 안내문 · 저장되는 제출이 그대로인지, 원칙 문구가 한 곳에만 있는지, 도움말의 표 규칙이
원칙과 맞는지를 확인한다. 대화에서 나온 요구가 하나씩 시나리오가 된다(최소 요구 — 빼지 않는다).

## Test scenarios

### T1. 원칙 전문이 등록 결과에 실린다

- **Setup**: 스위치 기본값(설정에 키 없음), SCV_LANG=korean, 요구 항목 목록이 있는 임시 저장소.
- **Run**: 모든 항목이 채워진 제출로 `model-prompting.sh register --model <id>`.
- **Expected**: 출력에 REGISTERED · REWRITE 줄 뒤로 원칙 전문(원칙 파일의 한국어 구역과 같은 글)이 있다.
- **Pass criterion**: 출력의 원칙 부분이 원칙 파일의 한국어 구역과 바이트 단위로 같다.

### T2. 다시 쓴 요청 끝에 짧은 표식

- **Setup**: T1 과 같다.
- **Run**: 같은 등록.
- **Expected**: REWRITE 줄 = 제출한 다시 쓴 요청 + 공백 + 표식(`[SCV 원칙 적용 — 단위 표 · 문제 표]`). 전문은 REWRITE 줄에 없다.
- **Pass criterion**: REWRITE 줄이 기대 문자열과 같다.

### T3. 원칙 전문의 필수 요소

- **Setup**: 원칙 파일의 세 언어 구역.
- **Run**: 구역마다 필수 요소 표식을 찾는다.
- **Expected**: 구역마다 다음이 모두 있다 — 정확한 피드백을 가장 중요하게 여김(이유) · 듣기 좋은 말 대신 사실 · 작은 단위로 나눔 ·
  단위 표 네 칸 이름(단위 · 해결책 · 추천 · 생길 수 있는 문제) · 해결책은 번호를 붙여 모두 · 추천은 하나와 고른 이유(해결책과 다를
  수 있음) · 문제 칸에는 문제 번호 · 문제 표 다섯 칸 이름(번호 · 위치 · 조건 · 깨지는 것 · 확인) · 위치는 파일:줄 · 명령 · 설정
  이름 · 확인/추정 표기 · 뭉뚱그린 말 대신 찾아서 위치(못 찾으면 범위와 방법) · "없음(확인한 범위: …)" · 한 행 약 80칸 폭 기준과
  넘치면 표가 풀린다는 이유 · 긴 설명은 표 아래 번호 메모로.
- **Pass criterion**: 세 구역 모두 요소 누락 0. 요소 하나를 지운 사본에서는 붉음.

### T4. 끄면 지금과 같다

- **Setup**: 설정 `SCV_REWRITE_PRINCIPLE=off`.
- **Run**: T1 과 같은 등록.
- **Expected**: 표식 · 원칙 전문이 없다.
- **Pass criterion**: 출력이 이 기능 전 등록 출력과 바이트 단위로 같다.

### T5. 종료 훅 인용 확인은 그대로

- **Setup**: 표식이 붙은 등록.
- **Run**: (a) REWRITE 줄을 그대로 인용한 답 (b) 인용이 없는 답을 종료 훅 판정에 넣는다.
- **Expected**: (a) 통과 (b) 지금처럼 막힘(같은 턴 한 번).
- **Pass criterion**: 두 결과가 기능 전과 같다.

### T6. 저장되는 제출은 그대로

- **Setup**: T1 과 같다.
- **Run**: 등록 뒤 저장된 제출 파일을 읽는다.
- **Expected**: 표식 · 원칙 문구가 들어 있지 않다.
- **Pass criterion**: 저장된 제출이 기능 전과 같은 내용이다.

### T7. 언어별 원칙

- **Setup**: SCV_LANG 을 korean · english · japanese · (모르는 값)으로 바꿔 가며.
- **Run**: 같은 등록.
- **Expected**: 각 언어의 전문 · 표식, 모르는 값은 영어.
- **Pass criterion**: 네 경우 모두 기대 구역과 같다.

### T8. 원칙 문구는 한 곳에만

- **Setup**: 저장소 전체.
- **Run**: 원칙 전문의 고유 문장(각 언어 구역의 첫 문장 등)을 검색한다.
- **Expected**: 원칙 파일에만 있다. 다시 쓰기 규약 · 도움말은 원칙 파일을 가리킨다.
- **Pass criterion**: 원칙 파일 밖 일치 0, 규약 · 도움말에 원칙 파일 참조가 있다.

### T9. 다시 쓰기 규약의 예외 한 줄

- **Setup**: `core/protocols/help/prompt-refine.md`.
- **Run**: 읽고 크기를 잰다.
- **Expected**: "요구를 더하지 말 것"에 SCV 원칙 예외(원칙 파일을 가리킴)와, 원칙대로 답하고 인용의 표식을 지우지 말라는 안내가 있다.
- **Pass criterion**: 두 표식이 있고, 규약 크기 관련 기존 검사가 통과한다.

### T10. 도움말 표 규칙과 원칙이 부딪히지 않는다 (도움말 답 모양 절은 그대로)

> 2026-10-01 사용자 결정(대화 Turn 9): 도움말 답 모양 절은 2026-09-16 잠금(바이트 그대로)을 지킨다. 표 통일은 다시 쓰기 규약과
> 원칙 파일의 "항목 표 대신" 선언이 맡는다(Top-level rules 해소 순서 4: 대신한다고 밝힌 나중 규칙).

- **Setup**: `core/protocols/help/prompt-refine.md`, 원칙 파일 세 구역, `core/protocols/help.md` 답 모양 절.
- **Run**: 규약 · 원칙 파일의 문구를 읽고, `bash core/tests/test-help-router-diet.sh` 를 돌린다.
- **Expected**: 다시 쓰기 규약이 원칙대로 답하라고 말하고, 원칙 파일 세 구역이 도움말 답의 항목 표 대신 쓸 때 지금 상태(확인)는
  단위 칸, 크기는 추천 칸에 적는다고 선언한다. 도움말 답 모양 절은 바이트 그대로다. 결정 표 규칙도 그대로다.
- **Pass criterion**: 표식이 있고, 라우터 다이어트 검사(답 모양 절 지문 포함)가 통과한다.

### T11. 매 턴 안내문 크기는 그대로

- **Setup**: 기능 전후.
- **Run**: `bash core/tests/test-help-budget.sh`.
- **Expected**: T12(매 턴 스택 합) 수치가 기능 전과 같다.
- **Pass criterion**: 통과 + 수치 동일.

### T12. 두 호스트

- **Setup**: 코덱스 벤더 도구로 만든 임시 사본, 클로드 설치 경로.
- **Run**: 코덱스 사본에서 코어 검사 전부. 클로드 쪽은 설치된 경로의 등록 명령으로 T1 · T2.
- **Expected**: 모두 통과, 두 호스트에서 표식 · 전문이 같게 나온다.
- **Pass criterion**: 실패 0.

### T13. 맥 · 리눅스

- **Setup**: 맥 기본 bash 3.2, 최신 bash, CI 두 OS.
- **Run**: 새 검사 전부. 새 환경 변수를 비운 채로도 한 번.
- **Expected**: 모두 통과. CI 로그 두 OS 에서 새 검사 줄이 각각 보인다.
- **Pass criterion**: 실패 0, 로그 두 줄 확인.

### T14. 기존 검사 전부

- **Setup**: 저장소 전체.
- **Run**: 코어 전체 검사, 클로드 드라이런, 코덱스 인용 검사.
- **Expected**: 모두 통과.
- **Pass criterion**: 실패 0.

## How to run

```bash
bash core/tests/test-model-prompting.sh && bash core/tests/test-help-budget.sh && bash core/tests/test-help-router-diet.sh
```

## Pass criteria

- T1–T14 전부 통과, 맥 · 리눅스 CI 로그에서 새 검사 줄 확인, 코덱스 사본 검사 통과.

## Related Documents

- 대화: `scv/conversations/20260930-213802-rewrite-direct-feedback-principle.md`
