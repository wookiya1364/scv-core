---
title: 단계 보고 — 구현 중 단계가 바뀌면 대시보드에 저절로
slug: 20261102-wookiya1364-step-report
author: wookiya1364
created_at: 2026-11-02
status: testing
kind: feature
lang: korean
tags: [hooks, host-profile, dashboard]
raw_sources:
  - scv/conversations/20261101-003000-pure-function-catalog-reuse.md
refs: []
invariants:
  - "호스트 설정에 단계 보고 도구가 없으면 매 턴 훅 출력은 바이트까지 그대로"
  - "코어는 특정 호스트 · 모드 이름을 담지 않는다(도구 이름은 래퍼 설정에서만)"
---

# 단계 보고 — 구현 중 단계가 바뀌면 대시보드에 저절로

## Summary

대시보드가 0/4 에서 멈춰 보였다 — 단계를 알리라는 지시가 코어에도 래퍼에도 없었다. '언제 알릴지'는 코어 구현 절차와
매 턴 한 줄이, '어떤 도구로'는 래퍼 호스트 설정이 맡는다(선택 창 도구 칸과 같은 방식). 사용자 결정 2026-11-02.

## Goals / Non-Goals

- **Goals**
  - 호스트 설정 칸 `SCV_STEP_TOOL` — 비면 아무 일 없음
  - work · codegen: 단계를 시작 · 끝낼 때, 막혔을 때(이유 한 줄) 그 도구로 알린다
  - 구현 중인 계획(promote 의 `in_progress` · `testing`)이 있을 때만 매 턴 한 줄
  - claude 래퍼 설정에 대시보드 도구 이름, codex 는 비움
- **Non-Goals**
  - 대시보드 모드 코드
  - 도구가 없는 세션에서 무엇이든 하기

## Approach Overview

1. `lib/host-profile.sh` 에 칸을 더하고 선택 도구 칸과 같은 모양 검사를 한다. 계약 `host-profile.md` 표에 한 줄.
2. `lib/step-report.sh`(순수): 계획 목록에서 구현 중인 계획을 고르고, 도구 이름 · 계획 이름으로 안내 한 줄을 만든다.
3. `scripts/step-report.sh line`: 설정을 읽고 promote 폴더의 상태를 모아 위 순수부를 부른다. 매 턴 훅이 선택 창 줄 뒤에 부른다.
4. work · codegen 규약에 '단계 보고' 한 절.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  scv_step_active_plan,   // "계획<TAB>상태" 줄들 → 구현 중인 계획 이름
  scv_step_line,          // 도구 이름 + 계획 이름 → 매 턴 안내 한 줄
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | 읽기 | 호스트 설정 · promote 폴더 상태를 읽는다 | 저장소 → 도구 이름 · 줄들 | 부수효과 (입구) |
| 2 | `scv_step_active_plan` | 구현 중인 계획 하나를 고른다(가장 최근) | 줄들 → 계획 이름 | 순수 |
| 3 | `scv_step_line` | 안내 한 줄을 만든다 | 도구 · 계획 → 한 줄 | 순수 |
| 4 | 출력 | 매 턴 훅에 싣는다 | 한 줄 → 화면 | 부수효과 (출구) |

- 부수효과 위치: 읽기(입구) · 출력(출구)
- 재사용: `lib/host-profile.sh` 의 설정 읽기, 선택 도구 칸의 이름 검사 모양

## Guardrails

- 칸이 비면 매 턴 훅 출력이 바뀌기 전과 바이트까지 같다
- 코어 파일에 호스트 · 모드 이름을 쓰지 않는다(호스트 중립 검사)
- 매 턴 줄은 400바이트 이하, 템플릿 다이제스트 · help 크기 예산을 지킨다

## Exit criteria

- All TESTS.md scenarios pass
- claude 래퍼 설정에 도구 이름이 들어간 릴리스 뒤, 실제 세션에서 대시보드가 단계마다 바뀐다(사용자 확인)

## Suggested path

1. 호스트 설정 칸과 계약 표 — 설정 칸 · 이름 검사를 더함
2. 순수부와 단계 보고 스크립트 — `scv_step_active_plan`, `scv_step_line`
3. 매 턴 훅에 한 줄, work · codegen 에 시점 규칙 — 훅과 규약 문서를 고침
4. 시험 · 크기 예산 · 다이제스트 · 회귀 — 칸 비면 0줄 · 있으면 1줄을 시험으로 고정

## Related Documents

- `core/contracts/host-profile.md`, `core/scripts/choice-gate.sh`, `core/template/hooks/on-user-prompt.sh`

## Risks / Open Questions

- 모드를 안 깐 claude 세션은 칸이 있어도 도구가 없다 — 안내 문구가 "이 세션에 그 도구가 있으면"으로 묶어 아무 일도 없게 한다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
