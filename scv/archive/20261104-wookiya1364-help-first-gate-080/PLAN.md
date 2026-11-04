---
title: 첫 도구를 help 로 고정 — help 전 도구 거절 · 도구 없는 턴 한 번 막기 · 'help → 등록' 한 순서
slug: 20261104-wookiya1364-help-first-gate-080
author: wookiya1364
created_at: 2026-11-04
status: testing
kind: feature
lang: korean
tags: [hooks, guard, help]
raw_sources:
  - scv/conversations/20261102-182255-writing-style-bullets.md
refs: []
invariants:
  - "자동 알림 턴 · 하위 에이전트 · 팀원 세션 · SCV_ALWAYS_ON=off · scv/ 없는 폴더는 지금과 같음"
  - "등록(Rule P) · 계획 영수증(Rule A/B) 판정은 그대로"
  - "코어에 호스트 도구 이름을 넣지 않음 — 통과시킬 도구 이름은 래퍼 프로필에"
---

# 첫 도구를 help 로 고정

## Summary

- slay 세션이 11-03 22:15 KST 이후 열 턴 넘게 help 를 한 번도 부르지 않음(확인 — 스킬 · help.sh 0회). 그 결과 대화 기록 파일이 그 뒤로 갱신되지 않음.
- 원인(확인): 매 턴 'help 먼저'와 '등록 먼저' 두 지시가 모두 첫 행동을 요구하는데, 등록만 검사가 있어 모델이 매번 등록부터 하고 help 를 버림. help 강제는 0.39.0 에 뺐음(답을 통째로 다시 쓰게 해 비쌌음).
- 사용자 결정: "애초에 못 건너뛰게" — 첫 도구에서 막는다(답을 다 쓴 뒤 되돌리지 않음).

## Goals / Non-Goals

- **Goals**
  - help(또는 이 턴에 실린 SCV 액션)가 불리면 이번 턴 표에 'help 부름'을 남김
  - 도구 앞 검사: 사람이 쓴 턴에서 그 표시가 없으면 거절(이유에 help 를 부를 명령)
  - 도구 없이 글만 쓴 턴: 종료 훅이 한 번 막음(앞에서 막을 자리가 없는 유일한 경우)
  - 매 턴 지시를 'help → 등록' 한 순서로 합침
  - claude 래퍼: 모든 도구에 검사, 통과 도구 목록은 프로필 키. codex: 있는 훅(쉘 · 파일 쓰기)에만
- **Non-Goals**
  - help 를 훅이 대신 부르기
  - 도구 없는 턴을 글이 나가기 전에 막기(호스트에 그 자리가 없음)

## Approach Overview

- 표시 쓰기: 가드의 기록 단계(mint)가 SCV 액션 시작을 이미 본다 — help · 다른 SCV 액션이면 `model-prompting.sh helped` 로 이번 턴 표를 적음. codex 는 help.sh 를 쉘로 부르므로 쉘 검사에서 같은 일을 함.
- 판정: `model-prompting.sh help-gate` 가 사람 턴 · 표 · 제외 조건을 보고 거절 이유 또는 빈 값을 냄(순수부는 lib).
- 새 가드 모드 `gate-any`: 판정만 하는 모드. 래퍼가 모든 도구에 건다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  scv_mp_help_needed,   // 턴 표 · help 표 · 자동 턴 · 사람 · 스위치 → 1|0
  scv_mp_help_reason,   // 명령 경로 → 거절 이유 한 줄
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | scv_mp_help_needed | 이번 턴에 help 가 아직 필요한지 정함 | 턴 표 · help 표 · 자동 표 · 사람 · 스위치 → 1/0 | 순수 |
| 2 | scv_mp_help_reason | 거절 이유(부를 명령 포함)를 만듦 | 명령 → 한 줄 | 순수 |
| 3 | model-prompting.sh helped · help-gate | 표 쓰기 · 판정 출력 | 세션 → 파일 / 이유 | 부수효과 (입구/출구) |
| 4 | guard.sh gate-any · mint | 도구 앞 거절 · help 시작 기록 | 훅 입력 → 거절 / 통과 | 부수효과 (입구/출구) |
| 5 | on-stop.sh | 도구 없는 턴 한 번 막기 | 훅 입력 → 막기 이유 | 부수효과 (입구/출구) |
| 6 | on-user-prompt.sh | 'help → 등록' 순서 문구 | 설정 → 매 턴 글 | 부수효과 (입구/출구) |

- 부수효과 위치: 3–6
- 재사용: 턴 표(.help-turn) · 자동 턴 표 · 사람 여부(session) · 한 번만 막기(stop-gates)

## Guardrails

- 제외: 자동 알림 턴 · 하위 에이전트 · 사람 메시지를 받은 적 없는 세션 · SCV_ALWAYS_ON=off · SCV_FORCE_HELP=off · scv/ 없음 · 턴 표 없음
- 가드의 기존 실패 정책 그대로(빈 입력 · JSON 리더 없음이면 통과)
- 코어에 호스트 도구 이름 없음(통과 도구 목록은 래퍼 프로필 `SCV_HELP_FIRST_ALLOW`)
- 매 턴 글 상한 10,800B 안

## Exit criteria

- TESTS.md T1–T8 통과, 전체 점검 · 회귀 · codex 사본 시험 통과
- 실제: claude 장난감 세션 여러 턴에서 턴마다 help 호출 100%

## Suggested path

1. 판정 순수 함수 · help 표 쓰기 · 판정 명령 — `scv_mp_help_needed`, `scv_mp_help_reason`, `model-prompting.sh helped · help-gate`
2. 가드: 기록 단계에서 표 쓰기 · 새 판정 모드 — `guard.sh gate-any · mint`
3. 종료 훅: 도구 없는 턴 한 번 막기 — `on-stop.sh`
4. 매 턴 지시 순서 합치기 — `on-user-prompt.sh`
5. 시험 T1–T7 · 회귀 — 단위 · 훅 시험을 돌림
6. 실제 재현 T8 — 장난감 세션 여러 턴에서 help 호출을 셈
7. 래퍼 등록(claude 모든 도구 · codex 쉘 · 쓰기) — 코어 릴리스 뒤 래퍼에 연결함

## Risks / Open Questions

- 같은 메시지에 help 와 다른 도구를 같이 보내면 순서대로 실행돼 help 가 먼저면 통과(앞이 아니면 그 도구만 거절 — 다시 보내면 됨)
- 도구 없는 턴은 글이 나간 뒤 막힘 — 고친 부분만 다시 쓰게 함(0.78.0 문구)
