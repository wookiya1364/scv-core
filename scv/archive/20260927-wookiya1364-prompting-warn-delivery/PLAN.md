---
title: 모델별 프롬프팅 — 가이드 경고가 모델에게 닿게 한다 (재개에도 남고, 원문 경로 · 표시 명령을 담는다)
slug: 20260927-wookiya1364-prompting-warn-delivery
author: wookiya1364
created_at: 2026-09-27
status: in_progress
kind: fix
lang: korean
tags: [model, prompting, help, stop-hook, warn, session-start]
raw_sources:
  - scv/conversations/20260927-160059-per-model-prompting-live-check.md
refs: []
invariants:
  - "경고만 한다 — 답을 막거나 고치지 않는다, 훅은 실패해도 exit 0"
  - "규약 지문 · 답 모양 경고는 초기화 때 지금처럼 지운다 — 가이드 경고만 남긴다"
  - "help 규약 비용 상한(원본 · 코덱스 사본)과 호스트 중립 검사 통과, 맥 · 리눅스 동일"
scope:
  - core/scripts/lib/model-prompting.sh
  - core/scripts/model-prompting.sh
  - core/scripts/help-state.sh
  - core/tests/test-model-prompting.sh
supersedes: []
---

# 모델별 프롬프팅 — 가이드 경고가 모델에게 닿게 한다

## Summary

0.60.0 설치본 헤드리스 실측(두 턴)에서 판정은 "원문 안 읽음" 을 두 번 다 정확히 잡았지만, 그 경고가 다음 턴의 모델에게
닿지 않았다(확인). 이유 둘: (1) 대화를 이어 붙일 때마다 세션 시작(재개) 훅이 표식을 초기화하면서 예약된 경고 파일을 통째로
지운다. (2) 경고가 "help 출력의 GUIDE_FILE · GUIDE_MARK_CMD 줄을 보라" 고만 하는데, 모델은 help 출력을 걸러 그 줄을 안 봤다.
이 계획은 경고가 매 턴 훅만으로 완결되게 한다.

## Goals / Non-Goals

- **Goals**
  - 초기화(재개 · 압축 · 지우기)가 경고 파일에서 **가이드 경고 블록만 남기고** 나머지(규약 지문 · 답 모양)는 지금처럼 지운다.
  - 가이드 경고 블록이 **읽을 원문 경로와 읽음 표시 명령을 그대로** 담는다 — help 출력 없이도 따라 할 수 있게.
    경로 · 명령은 help 가 실제로 낸 값(이번 턴 기록에 함께 저장)을 쓴다. 멈춤 훅은 다른 실행 위치(벤더 코어)에서 돌아
    경로를 다시 계산하면 틀릴 수 있다.
- **Non-Goals**
  - 모델에게 원문 읽기를 강제 — 경고까지만. 규약 문서 문구 변경 없음(비용 상한 여유 유지).
  - 코덱스 실측(사용자 재로그인 뒤).

## Approach Overview

- **이번 턴 기록**: 첫 줄은 그대로(지문 · 모델 · 결정 · 키). `guide` 가 둘째 줄부터 자기가 낸 `GUIDE_FILE:` · `GUIDE_MARK_CMD:`
  줄을 그대로 덧붙인다(load 일 때만).
- **경고 문장**: `scv_mp_warn_lines` 가 안 읽음 경고 뒤에 그 줄들을 들여 써 붙인다. 안 보임 경고는 그대로.
- **초기화**: `help-state.sh reset` 이 경고 파일을 지우는 대신 순수 함수 `scv_mp_warn_keep` 으로 가이드 경고 블록(`[SCV 가이드]`
  줄과 이어지는 들여 쓴 줄)만 남긴다. 남길 것이 없으면 지금처럼 지운다.

## Guardrails

- 경고 파일은 매 턴 훅이 2048B 까지만 싣는다 — 가이드 경고 블록은 그 안에 들어가야 한다.
- 초기화가 남기는 것은 가이드 경고 블록뿐. 규약 지문 경고가 재개 뒤에 살아남으면 안 된다.
- 순수부 · 효과부 분리(check-purity), 호스트 중립, 맥 · 리눅스 동일.

## Exit criteria

- All TESTS.md scenarios pass
- 설치본 헤드리스 두 턴 실측: 1턴에 원문을 안 읽으면 2턴 훅 주입에 가이드 경고(원문 경로 · 표시 명령 포함)가 보인다.

## Suggested path

1. 순수부: `scv_mp_warn_lines` 에 상세 줄 인자, `scv_mp_warn_keep`.
2. `model-prompting.sh`: `guide` 가 턴 기록에 상세 줄, `stop` 이 상세 줄을 경고에.
3. `help-state.sh reset`: 가이드 경고 블록 보존.
4. 테스트(재개 흐름 포함) → 코덱스 사본 검사 → 릴리스 → 설치본 실측.

## Risks / Open Questions

- 재개 뒤 컨텍스트는 새것이라 "직전 턴에" 라는 표현이 어색할 수 있다 — 행동 지시(원문 읽고 표시)는 그대로 유효하다.
- 모델이 경고를 보고도 안 읽을 수 있다 — 그러면 매 턴 경고가 반복된다(드리프트 로그로 빈도를 본다).

## Related Documents

- `scv/archive/20260927-wookiya1364-prompting-read-verdict/PLAN.md`
- `core/protocols/help/prompt-refine.md`
