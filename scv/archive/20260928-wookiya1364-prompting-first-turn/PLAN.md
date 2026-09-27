---
title: 모델별 프롬프팅 — 새 컨텍스트의 첫 턴부터 가이드 원문을 읽게 한다
slug: 20260928-wookiya1364-prompting-first-turn
author: wookiya1364
created_at: 2026-09-28
status: in_progress
kind: feature
lang: korean
tags: [model, prompting, help, hook, first-turn]
raw_sources:
  - scv/conversations/20260927-160059-per-model-prompting-live-check.md
refs: []
invariants:
  - "안내만 한다 — 답을 막거나 고치지 않는다, 훅은 실패해도 exit 0"
  - "평상시 턴(이미 읽음)의 매 턴 훅 출력은 한 바이트도 늘지 않는다 — 매 턴 비용 상한(원본 · 코덱스 사본) 그대로"
  - "호스트 중립(코어에 모델 · 호스트 이름 없음), 맥 · 리눅스 동일"
scope:
  - core/scripts/lib/model-prompting.sh
  - core/scripts/model-prompting.sh
  - core/template/hooks/on-user-prompt.sh
  - core/tests/test-model-prompting.sh
  - core/TEMPLATE_DIGEST
supersedes: []
---

# 모델별 프롬프팅 — 새 컨텍스트의 첫 턴부터 가이드 원문을 읽게 한다

## Summary

0.60.2 실측에서 모델은 새 대화의 첫 턴에 help 출력의 가이드 줄을 건너뛰었고, 둘째 턴에 매 턴 훅으로 원문 경로와 명령을 받자
그대로 읽었다(확인). 매 턴 훅은 모델이 거르지 못하는 통로다. 그래서 첫 턴에도 같은 통로로 알린다. 훅 입력에는 모델 이름이
없으므로(확인) help 가 마지막으로 본 모델의 원문 경로 · 표시 명령을 기록해 두고 그것을 싣는다.

## Goals / Non-Goals

- **Goals**
  - `model-prompting.sh guide` 가 결정 load/loaded 일 때 `.help-guide-last` 에 모델 id 와 `GUIDE_FILE:` · `GUIDE_MARK_CMD:` 줄을,
    가이드가 없는 모델이면 `none` 을 적는다(컨텍스트에 묶이지 않는 값 — 초기화가 지우지 않는다).
  - 매 턴 훅이 "이 컨텍스트에서 아직 원문을 읽지 않음"(읽음 기록의 지문이 지금 지문과 다름) 이고 기록이 있으면, 지시 바로 뒤에
    "답하기 전에 아래 원문을 끝까지 읽고 아래 명령을 실행하라" 블록(원문 경로 · 명령, 기준 모델 id)을 싣는다.
  - 가이드 경고가 이미 예약돼 있으면 블록을 싣지 않는다(같은 내용 중복 방지). 스위치 off · 기록 none · 기록 없음이면 싣지 않는다.
- **Non-Goals**
  - 프로젝트의 맨 첫 SCV 턴(기록 없음) · 모델을 바꾼 직후 첫 턴 — 모델을 알 방법이 없다. 지금처럼 help 출력 + 다음 턴 경고.
  - 원문 읽기를 강제(도구 차단) — 안내까지만.

## Guardrails

- 읽음이 확인된 턴(평상시)의 훅 출력은 바뀌지 않는다 — `test-help-budget` T12 가 원본 · 코덱스 사본에서 그대로 초록.
- 블록 문구는 기준 모델 id 를 밝히고 "지금 모델이 다르면 help 의 GUIDE 줄을 따르라" 를 붙인다.
- 순수부 · 효과부 분리, 호스트 중립, 맥 · 리눅스 동일.

## Exit criteria

- All TESTS.md scenarios pass
- 설치본 헤드리스 실측: 같은 저장소에서 앞 세션 한 턴 뒤 **새 세션**(이어 붙이기 아님)의 첫 턴 훅 주입에 블록이 보이고,
  그 턴에 모델이 원문을 읽고 표시해 판정이 ok.

## Suggested path

1. 순수부: `scv_mp_first_turn_lines`.
2. `model-prompting.sh`: `guide` 가 `.help-guide-last` 기록, 새 `prompt` 명령(블록 출력).
3. 매 턴 훅: 경고를 싣기 전에 `prompt` 결과를 받아 두고, 경고 뒤에 싣는다.
4. 테스트 → 코덱스 사본 → 릴리스 → 실측.

## Risks / Open Questions

- 모델이 바뀌었는데 기록이 옛 모델이면 옛 모델의 원문을 읽을 수 있다 — 문구가 기준 모델을 밝히고, 다음 턴 판정이 바로잡는다.
- 첫 턴 비용: 컨텍스트마다 한 번 약 0.5KB 더 실린다(첫 턴은 원래 진단 전체가 실리는 턴).

## Related Documents

- `scv/archive/20260927-wookiya1364-prompting-warn-delivery/PLAN.md`
