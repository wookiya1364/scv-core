# Test Plan — 다음 일은 묻지 말고 계속

## Overview

선택 창 규약과 매 턴 안내에 '막힌 것이 없으면 다음 일을 묻지 않는다'가 들어갔는지 자동 테스트로 확인하고, 실제로 '다음?' 창이 줄면서 진짜 결정 창은 남는지를 긴 과제 측정으로 확인한다. 측정 기준은 결과를 보기 전에 여기 고정한다.

## Test scenarios

### T1. 규약에 규칙 8

- **Setup**: core/contracts/choices.md
- **Run**: test-choice-questions.sh
- **Expected**: "When the host names a choice tool" 에 다음 할 일은 결정이 아니라는 규칙과 진짜 결정 세 종류(되돌리기 어려움 · 밖으로 나감 / 취향 · 범위 / 입력 없이 못 나아감)가 있다. 자동 알림 턴에도 적용된다고 적혀 있다.
- **Pass criterion**: 해당 문구 검사 통과.

### T2. 매 턴 안내 줄

- **Setup**: scv_choices_line "AskUserQuestion"
- **Run**: test-choice-questions.sh
- **Expected**: 줄에 '막힌 것 없으면 계속 · 끝났으면 다음 추천을 서술' 요지가 있고, 도구 이름이 없으면 줄이 없다(기존 그대로).
- **Pass criterion**: 문구 검사 통과.

### T3. 매 턴 상한 · 규칙 한 곳

- **Run**: test-help-budget.sh · test-rule-constitution.sh
- **Expected**: 매 턴 스택이 상한 안, 규칙 전문은 규약 한 곳.
- **Pass criterion**: 두 테스트 통과.

### T4. 긴 과제 측정 (켜기 전 · 뒤)

- **Setup**: ~/scv-experiments/longbench 의 6과제. 켜기 전 = develop 플러그인, 켠 뒤 = 이 분기 플러그인. 과제마다 1회씩(6 × 2 = 12판).
- **Run**: drive_lb 로 사람 없이 돌리고(자동 응답은 각 창의 첫 보기), 판마다 확인 창을 센다. 창 분류는 결과를 모른 채 Claude 판정자가 질문 글만 보고 '다음 할 일 고르기' / '진짜 결정' 으로 나눈다.
- **Expected**: 켠 뒤 '다음 할 일 고르기' 창 합이 켜기 전의 절반 이하. 켠 뒤 '진짜 결정' 창 합이 켜기 전의 절반 이상(사라지지 않음). 과제 완료(숨은 테스트) 수가 켜기 전보다 1 넘게 줄지 않는다.
- **Pass criterion**: 세 조건 모두.

## How to run

```bash
bash core/tests/test-choice-questions.sh && bash core/tests/test-help-budget.sh && bash core/tests/test-rule-constitution.sh
```

T4 는 실제 Claude 세션을 돌리므로 CI · 회귀 실행에 넣지 않는다 — `~/scv-experiments/longbench` 장치로 돌리고 결과를 기준 문서와 측정 보고서(scv/raw)에 적는다. 한 판에 주간 사용량이 들므로 돌리기 전 주간 % 를 읽는다.

## Pass criteria

- T1 ~ T3 통과.
- T4 세 조건 모두 충족(못 넘으면 문구를 고쳐 한 번 더, 두 번째도 못 넘으면 멈추고 보고).
