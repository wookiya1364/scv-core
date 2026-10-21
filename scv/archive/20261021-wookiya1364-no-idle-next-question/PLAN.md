---
title: 다음 일은 묻지 말고 계속 — 막힌 것이 없으면 '다음으로 무엇을 할까요?' 창으로 멈추지 않기
slug: 20261021-wookiya1364-no-idle-next-question
author: wookiya1364
created_at: 2026-10-21
status: testing
kind: feature
lang: korean
tags: [choices, unattended]
raw_sources:
  - scv/conversations/20261012-154556-boris-advice-check.md
refs: []
invariants:
  - "진짜 결정(되돌리기 어려운 일 · 밖으로 나가는 일 · 사용자 취향 · 막힌 일)은 여전히 선택 창으로 묻는다"
  - "글로 묻고 끝내는 턴은 지금처럼 멈춤 훅이 막는다"
---

# 다음 일은 묻지 말고 계속

## Summary

실사용 기록에서 확인 창이 늘어난 주원인은 요구가 흐려서가 아니라, 한 단계를 끝낼 때마다 "다음으로 무엇을 할까요?" 창을 띄운 것이었다(긴 세션 하나의 창 225개 중 배경 작업 알림 바로 뒤 115개, 제목 '다음' · '다음 단계' 54개). 선택 창 규약에는 '막힌 것이 없으면 묻지 말고 계속'이라는 예외가 없어, 다음 할 일도 결정으로 다뤄 창으로 묻게 된다. 이 계획은 규약과 매 턴 안내에 그 예외를 더한다.

## Goals / Non-Goals

- **Goals**
  - 맡은 일 안에서 다음 단계가 분명하고 막힌 것이 없으면, 묻지 않고 그 단계를 이어 한다.
  - 맡은 일이 끝났으면, 다음 추천을 물음 없이 한 줄로 적고 턴을 끝낸다(창 없음).
  - 배경 작업 끝 알림처럼 사람이 쓰지 않은 턴에서도 같은 규칙.
- **Non-Goals**
  - 진짜 결정을 묻는 방식(추천 먼저 · 보기마다 해법)은 바꾸지 않는다.
  - 멈춤 훅의 '글 질문 막기'는 바꾸지 않는다.
  - 실체 보여 주기는 이번 계획에서 손대지 않는다(사용자 결정: 켜 둠).

## Approach Overview

- `core/contracts/choices.md` — "When the host names a choice tool" 에 규칙 8을 더한다: 다음 할 일은 그 자체로 결정이 아니다. 진짜 결정은 (a) 되돌리기 어렵거나 밖으로 나가는 일, (b) 사용자 취향 · 범위를 정해야 하는 일, (c) 사용자 입력 없이는 나아갈 수 없는 일. 그 밖에는 계속하거나(맡은 일 안), 다음 추천을 서술로 적는다(맡은 일 끝).
- `core/scripts/lib/choices.sh` — 매 턴 [SCV choices] 줄에 같은 요지를 한 구절로 더한다. 매 턴 스택 상한(test-help-budget) 안.
- 테스트: 새 문구가 규약과 매 턴 줄에 있는지, 매 턴 상한 안인지.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  scv_choices_line,   // 도구 이름 → 매 턴 [SCV choices] 줄(새 구절 포함)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | scv_choices_line (기존 함수) | 도구 이름 → 안내 한 줄 | 순수 |
| 2 | on-user-prompt.sh (기존 훅) | 안내 줄 → 표준출력 | 부수효과 (출구) |

- 부수효과 위치: 훅의 출력뿐. 새 단계는 만들지 않는다.
- 재사용: 기존 함수의 문구만 바꾼다.

## Guardrails

- 진짜 결정(invariants)을 창 없이 진행하게 만드는 문구를 쓰지 않는다 — 공식 가이드도 위험 · 되돌리기 어려운 일의 확인은 남기라고 한다.
- 매 턴 스택 상한(test-help-budget T12)을 넘기지 않는다.
- 규칙 문장은 규약 한 곳에만 전문, 다른 곳은 요지(constitution 규칙).
- Mac + Linux, bash 3.2.

## Exit criteria

- All TESTS.md scenarios pass
- 긴 과제 측정에서 '다음?' 창이 켜기 전의 절반 이하이고, 진짜 결정 창은 남아 있다(TESTS T4 기준).

## Suggested path

1. choices.md 규칙 8 문구.
2. choices.sh 매 턴 줄 구절 + 테스트.
3. 분기 플러그인으로 긴 과제 측정(켜기 전 = 현재 develop, 켠 뒤 = 이 분기).

## Risks / Open Questions

- 모델이 '진짜 결정'까지 묻지 않고 진행할 수 있다 — T4 의 결정 창 유지 기준으로 본다.
- 긴 과제는 과제 지시문이 '커밋 뒤 검토 요청'을 정해 둔 것이 있어(T9 원인 조사), 그 검토 창은 진짜 결정으로 센다.

## Links

- 근거 대화: scv/conversations/20261012-154556-boris-advice-check.md (Turn 3~5)
