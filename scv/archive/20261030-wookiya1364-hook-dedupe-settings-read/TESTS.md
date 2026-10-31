# Test Plan — 매 턴 훅 속도 — 같은 판단은 한 번, 설정은 파일당 한 번 읽기

## Overview

이 계획은 출력을 바꾸지 않고 시간만 줄이는 일이다. 그래서 시험의 중심은 "옛 길과 새 길이 같은 입력에서 바이트까지 같은 글을 내는가"이고, 그다음이 "실제로 빨라졌는가"를 숫자로 남기는 것이다. 대화에서 정한 기능 셋(같은 판단 한 번 · 설정 한 번 읽기 · 전후 측정)이 각각 시나리오다.

## Test scenarios

### T1. 훅 출력이 옛 길과 같다 (사람 · 자동 · 스위치 조합)

- **Setup**: 임시 프로젝트 여러 개 — 설정 SCV_SHOW_REAL 켬/끔, SCV_CHOICE_GATE 켬/끔, 호스트 설정에 선택 창 도구 있음/없음, 사람 없는 실행 조건 있음/없음. 입력은 사람 메시지 하나와 자동 알림 하나(호스트 자동 입력 모양), 64KB 넘는 자동 알림 하나.
- **Run**: 바꾸기 전 훅(기준 사본)과 바꾼 훅에 같은 입력을 넣는다.
- **Expected**: 표준출력이 조합마다 같다.
- **Pass criterion**: 모든 조합에서 `cmp` 같음. 하나라도 다르면 조합 이름과 첫 다른 줄을 내고 실패.

### T2. 한 턴에 kind 판단은 한 번

- **Setup**: T1 의 사람 메시지 프로젝트(SCV_SHOW_REAL 켬).
- **Run**: 훅을 xtrace(자식 bash 까지) 로 한 번 돌려 `model-prompting.sh kind` 실행 횟수를 센다.
- **Expected**: 1번(지금 2번).
- **Pass criterion**: 셈 = 1.

### T3. 한 턴에 선택 창 상태 계산은 한 번

- **Setup**: T2 와 같음, 호스트 설정에 선택 창 도구 있음.
- **Run**: 같은 방법으로 `choice-gate.sh` 실행 횟수를 센다.
- **Expected**: 1번(지금 3번).
- **Pass criterion**: 셈 = 1.

### T4. show-real · choice-gate 를 직접 부르면 지금과 같다

- **Setup**: T1 의 조합들.
- **Run**: `show-real.sh line` 을 값을 넘기지 않고 입력만으로 부르고, `choice-gate.sh line|tool|unattended` 를 각각 부른다 — 기준 사본과 바꾼 것.
- **Expected**: 출력이 같다.
- **Pass criterion**: 모두 `cmp` 같음.

### T5. 설정 값이 모든 키에서 옛 길과 같다

- **Setup**: 설정 파일 견본 — 기본 견본, 비어 있는 파일, 없는 파일, 문자열 아닌 값(숫자 · 참/거짓 · 배열 · 객체), 줄바꿈 · 탭 · 따옴표 · `$` · 공백이 든 문자열, 일반 파일에 든 비밀 키, 비밀 파일, 같은 키를 환경 변수로도 준 경우, 심볼릭 링크 설정 파일.
- **Run**: 알려진 모든 키(일반 + 비밀)와 없는 키 하나에 대해 기준 사본의 `settings_get` 과 바꾼 `settings_get` 을 부른다(표준출력 · 표준오류 따로).
- **Expected**: 값과 경고가 같다. 비밀 값은 어느 출력에도 나오지 않는다.
- **Pass criterion**: 모든 키 · 견본에서 표준출력 · 표준오류 `cmp` 같음, 비밀 값 문자열이 출력에 0번.

### T6. 설정 파일 하나는 한 프로세스에서 jq 한 번

- **Setup**: 기본 견본 설정.
- **Run**: 한 bash 프로세스에서 `settings_get` 을 서로 다른 키로 10번 부르며 jq 실행 횟수를 센다(PATH 앞에 세는 jq 껍데기).
- **Expected**: 파일당 1번(일반 + 비밀 = 최대 2번). 지금은 키마다 1번 이상.
- **Pass criterion**: 셈 ≤ 2.

### T7. bash 3.2 에서 돈다

- **Setup**: 맥의 `/bin/bash` (3.2).
- **Run**: T1 · T5 를 `/bin/bash` 로 돌린다.
- **Expected**: 통과.
- **Pass criterion**: 둘 다 종료 0, 비교 같음.

### T8. 훅은 실패해도 막지 않는다

- **Setup**: jq 를 PATH 에서 뺀 환경, 망가진 JSON 설정 파일.
- **Run**: 훅을 돌린다.
- **Expected**: exit 0, 기준 사본과 같은 출력(같은 환경에서).
- **Pass criterion**: 종료 0, `cmp` 같음.

### T9. 훅 1회 시간 전후 (이 맥)

- **Setup**: 저장소 복제본, 조사 때와 같은 측정 스크립트, 같은 입력.
- **Run**: 바꾸기 전 · 뒤 훅을 각 5회 잰다.
- **Expected**: 줄어든다(추정 0.3–0.4초).
- **Pass criterion**: 전후 5회 값과 가운데 값을 보고에 적는다. 줄지 않았으면 단계별 시간을 다시 재서 원인을 적는다(실패로 숨기지 않음).

### T10. CI 전후 (우분투 · 맥)

- **Setup**: 이 계획의 PR.
- **Run**: CI 를 돌린다.
- **Expected**: 모두 통과, 맥 Contracts 시간과 시험 시간 합이 기록된다.
- **Pass criterion**: 필수 검사 전부 통과, 맥 Contracts 시간 · 시험 시간 합 전후(앞 기준: 5분 28초)를 보고에 적는다.

### T11. 기존 시험 그대로 통과

- **Setup**: 코어 저장소, codex 사본.
- **Run**: 설정 · env_load · 실체 보여 주기 · 선택 질문 시험과 전체 회귀.
- **Expected**: 모두 통과.
- **Pass criterion**: `fail=0`.

## How to run

```bash
bash core/tests/test-hook-dedupe.sh && bash core/tests/test-settings.sh && bash core/tests/test-env-load.sh && bash core/tests/test-show-real.sh && bash core/tests/test-choice-questions.sh
```

## Pass criteria

- T1–T8 · T11 통과(바이트 비교 · 횟수 · 호환 · 막지 않음 · 기존 시험).
- T9 · T10 은 숫자를 보고에 남기면 통과 — 목표치는 없고, 줄지 않으면 원인을 적는다.

## Related Documents

- scv/raw/20261030-research-hook-speed.md
