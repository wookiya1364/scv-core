---
title: 진행 기록이 진행 중 단계를 '끝'으로 남기지 않게
slug: 20261110-wookiya1364-progress-state-renumber
author: wookiya1364
created_at: 2026-11-10
status: testing
kind: feature
lang: korean
tags: [turn-check, plan-link, dashboard]
raw_sources: []
refs: []
invariants:
  - "--state done 을 직접 준 progress 는 지금처럼 'N단계 끝'"
  - "Suggested path 번호 밀기(scv_plan_insert_step)는 그대로"
---

# 진행 기록이 진행 중 단계를 '끝'으로 남기지 않게

## Summary

slay 계획 8단계(혼자 전사·마법사 55%)가 '파티 적 세기 측정 시작'인데 대시보드에 완료로 보였다. 원인 둘: 진행 기록의 기본 상태와 턴 끝 막힘 안내문이 늘 '끝'이고, 단계를 끼워도 변경 이력의 진행 줄 번호는 안 밀려 옛 '8단계 끝: 특성 배지'가 새 8단계에 붙었다. 둘 다 고친다.

## Goals / Non-Goals

- **Goals**
  - progress 의 기본 상태를 doing(시작)으로
  - 막힘 안내문이 '끝났으면 done, 아니면 doing' 을 보여 줌
  - append 로 단계를 끼우면 끼운 자리 뒤의 진행 줄 번호도 +1
- **Non-Goals**
  - 대시보드 패널 · 래퍼 코드
  - 이미 쓰인 slay 계획 기록 고치기

## Approach Overview

- `plan-link.sh progress` 의 PSTATE 기본값을 doing 으로. 순수 함수 `scv_tc_progress_entry` 의 기본도 doing.
- `scv_tc_block_msg in-plan` 문구: `--state doing|done` 과 '끝났을 때만 done'.
- 새 순수 함수 `scv_plan_shift_progress <글> <after>`: `## 변경 이력` 의 `- **날짜 진행** — M단계 …` 줄에서 M(숫자, 꼬리 글자 허용) > after 이면 M+1. append(끼우기)에서 이력에 새 사건을 붙이기 전에 부른다. --redo(맨 끝에 붙임)는 밀 것이 없어 그대로.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  scv_plan_insert_step,      // (계획 글, after, 단계) → 단계 번호 민 글
  scv_plan_shift_progress,   // (글, after) → 진행 줄 번호도 민 글
  scv_plan_history_add,      // (글, 사건) → 사건 붙인 글
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | `scv_tc_progress_entry` | 진행 한 줄 — 기본 상태 시작 | (날짜, 단계, 상태, 메모, 꼬리) → 줄 | 순수 |
| 2 | `scv_tc_block_msg` | 막힘 안내문 — 끝/진행 구분 안내 | (종류, 계획, 수, 경로) → 글 | 순수 |
| 3 | `scv_plan_shift_progress` | 끼운 자리 뒤 진행 줄 번호 +1 | (글, after) → 글 | 순수 |
| 4 | `plan-link.sh append/progress` | 파일 읽고 쓰기 | 인자 → PLAN.md | 부수효과 (입구/출구) |

- 부수효과 위치: plan-link.sh 의 read_plan · write_plan 만
- 재사용: scv_plan_insert_step, scv_plan_history_add 그대로

## Guardrails

- `--state done` 을 준 기록은 지금과 같은 글
- 진행 줄이 아닌 이력 줄(추가 · 보류 · 다시 하기 · 기록 없음)은 번호를 바꾸지 않음
- Mac · Linux(bash 3.2) 둘 다

## Exit criteria

- TESTS.md 시나리오 모두 통과, 옛 코드로는 새 시험이 실패
- 전체 시험 실패 0

## Suggested path

1. 시험 먼저 쓰고 지금 코드로 실패 확인 — 기본값 · 안내문 · 번호 밀기 시험 추가
2. 진행 기록 기본을 시작으로, 안내문에 끝/진행 구분 — `scv_tc_progress_entry`, `scv_tc_block_msg`
3. 단계를 끼우면 뒤 진행 줄 번호도 밀기 — `scv_plan_shift_progress`, `plan-link.sh append/progress`
4. 전체 시험(bash 5 · 3.2) · 보관 · PR · 릴리스 — 전체 확인과 배포

## Related Documents

## Risks / Open Questions

- progress 를 --state 없이 불러 '끝'을 기대하던 곳이 있으면 '시작'으로 바뀜 — 시험과 문서에서 찾아 함께 고침
- 대시보드가 같은 단계의 여러 줄 중 무엇을 쓰는지는 패널 쪽 일(이번 범위 밖)

## 변경 이력

- **2026-11-10 진행** — 3단계 끝: 기본값 doing · 안내문 끝/진행 구분 · 끼우기 뒤 진행 줄 번호 밀기 — 새 시험 T27–T31 통과(bash 5 · 3.2), 옛 코드에선 T27 · T29 · T30 · T31 실패
  - 요청: 혼자 전사.마법사 55% 계획에넣었다는데, 왜 완료된거처럼 보이냐? (요청 ceba7c1f)

- **2026-11-10 진행** — 4단계 시작: 전체 시험 실행 중
  - 요청: 혼자 전사.마법사 55% 계획에넣었다는데, 왜 완료된거처럼 보이냐? (요청 ceba7c1f)

- **2026-11-10 진행** — 4단계 시작: 전체 시험 4개씩 실행 중
  - 요청: 혼자 전사.마법사 55% 계획에넣었다는데, 왜 완료된거처럼 보이냐? (요청 ceba7c1f)

- **2026-11-10 기록 없음** — 파일 10개를 바꾼 턴이 계획 기록 없이 끝남
  - 요청: 혼자 전사.마법사 55% 계획에넣었다는데, 왜 완료된거처럼 보이냐? (요청 ceba7c1f)

- **2026-11-10 진행** — 4단계 끝: 전체 시험 92개 통과(4개씩), 새 시험 T27–T31 bash 5 · 3.2 통과
  - 요청: 혼자 전사.마법사 55% 계획에넣었다는데, 왜 완료된거처럼 보이냐? (요청 ceba7c1f)

## Links

- Raw originals: (없음 — 이 대화)
- Related PRs:
