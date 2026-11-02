---
title: 폐기 표시를 한 곳으로 — 표시하면 보관 목록도 바로
slug: 20261102-wookiya1364-obsolete-refresh-index
author: wookiya1364
created_at: 2026-11-02
status: testing
kind: refactor
lang: korean
tags: [archive, regression]
raw_sources:
  - scv/conversations/20261101-003000-pure-function-catalog-reuse.md
refs: []
invariants:
  - "보관된 TESTS.md · ARCHIVED_AT.md 는 건드리지 않는다 — PLAN.md 앞머리 세 칸만"
  - "묻는 지점 수는 그대로"
---

# 폐기 표시를 한 곳으로 — 표시하면 보관 목록도 바로

## Summary

회귀의 폐기 표시는 보관 목록(`scv/archive/INDEX.yaml`)을 새로 만들지만, 구현의 대체 선언 폐기 표시(work 9c)는 계획서만
고친다 — 다음 보관 때까지 회귀가 폐기된 계획을 계속 돌릴 수 있다. 폐기 표시를 스크립트 하나로 모아 둘 다 부르게 한다.

## Goals / Non-Goals

- **Goals**
  - 계획서 앞머리 세 칸(`status: obsolete` · `obsoleted_at` · `obsoleted_by`)만 바꾸는 순수함수
  - 스크립트 `obsolete-mark.sh <slug> <by> [<날짜>]` — 계획서를 고치고 보관 목록을 바로 새로 만든다
  - work 9c · regression 폐기 절차가 그 스크립트를 부른다
- **Non-Goals**
  - 보관된 TESTS.md · ARCHIVED_AT.md · 본문 수정
  - 결정 기록 형식 변경

## Approach Overview

1. `lib/obsolete.sh`(순수): 프런트매터 글 + 날짜 + 대체한 계획 → 세 칸만 바꾼 글. 이미 obsolete 면 그대로 돌려준다.
2. `scripts/obsolete-mark.sh`: 읽기 → 순수함수 → 쓰기(바뀐 때만) → `archive-index.sh`.
3. 규약 두 곳(work 9c, regression 폐기 절차)이 손으로 고치는 대신 스크립트를 부른다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  scv_obsolete_frontmatter,   // PLAN.md 글 + 날짜 + 대체한 계획 → 세 칸만 바꾼 글
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | 읽기 | 보관된 계획서를 읽는다 | 경로 → 글 | 부수효과 (입구) |
| 2 | `scv_obsolete_frontmatter` | 앞머리 세 칸만 폐기로 바꾼다 — 이미 폐기면 그대로 | 글 · 날짜 · 대체한 계획 → 글 | 순수 |
| 3 | 쓰기 · 목록 | 바뀐 때만 쓰고 보관 목록을 다시 만든다 | 글 → 파일 · INDEX.yaml | 부수효과 (출구) |

- 부수효과 위치: 읽기(입구), 쓰기 · 목록 다시 만들기(출구)
- 재사용: `scripts/archive-index.sh`(이미 있는 목록 만들기)

## Guardrails

- 세 칸 밖의 바이트는 그대로(앞머리 다른 칸 · 본문)
- 이미 obsolete 인 계획은 다시 쓰지 않는다(날짜 덮어쓰기 금지)
- 맥 · 리눅스 같은 결과

## Exit criteria

- All TESTS.md scenarios pass
- 구현 중 단계마다 대시보드가 바뀐다(사용자 확인)

## Suggested path

1. 폐기 표시 순수함수 — `scv_obsolete_frontmatter`
2. 폐기 표시 스크립트(고치기 + 목록 새로 만들기) — 읽기 · 쓰기 · 목록 다시 만들기를 잇는 입구 · 출구
3. work 9c · regression 폐기 절차가 스크립트를 부름 — 규약 두 곳을 고침
4. 시험 · 회귀 — 목록 즉시 반영 · 바이트 보존 · 두 번 표시 안 함을 시험으로 고정

## Related Documents

- `core/scripts/archive-index.sh`, `core/protocols/work.md` Step 9c, `core/protocols/regression.md`

## Risks / Open Questions

- 앞머리에 `obsoleted_at` 이 이미 있는데 status 가 obsolete 가 아닌 이상한 계획 — 칸이 있으면 값만 바꾼다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
