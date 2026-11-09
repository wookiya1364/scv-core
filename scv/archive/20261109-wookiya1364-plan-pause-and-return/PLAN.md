---
title: 계획 밖 요구 — 기존 계획에 넣거나, 보류 후 돌아오기
slug: 20261109-wookiya1364-plan-pause-and-return
author: wookiya1364
created_at: 2026-11-09
status: testing
kind: feature
lang: korean
tags: [plan-lifecycle, dashboard]
raw_sources:
  - scv/conversations/20261109-104617-fold-offplan-into-plan.md
refs: []
invariants:
  - "끝난 단계([x])의 글은 고치지 않는다 — 요건이 바뀌면 '다시 하기' 단계를 새로 붙인다"
  - "기존 상태 값(planned · in_progress · testing · done · obsolete)의 뜻과 패널 표시는 그대로"
  - "supersede 전파(work Step 9c)는 지금처럼 동작한다"
---

# 계획 밖 요구 — 기존 계획에 넣거나, 보류 후 돌아오기

## Summary

계획을 진행하다가 계획에 없던 요구가 나오면, 지금은 새 계획이나 작은 수정으로 따로 처리되어 원래 계획에는 "멈춤"만 남는다. 대시보드를 볼 수 없는 곳(모바일)에서는 왜 멈췄는지 알 수 없다. 같은 목표의 요구는 기존 계획에 넣고, 다른 목표의 요구는 기존 계획을 **보류**로 표시한 뒤 새 계획을 만들어 연결하고, 새 계획이 끝나면 바로 돌아와 충돌 없이 이어서 하게 한다.

## Goals / Non-Goals

- **Goals**
  - 계획 파일(PLAN.md) 하나만 열어도 멈춤 · 이유 · 복귀 지점이 보인다 (GitHub 모바일에서도)
  - 같은 목표의 요구 → 기존 계획에 단계 · 시험 항목 · 이력 한 줄을 더한다
  - 다른 목표의 요구 → 기존 계획 A를 보류로 바꾸고, 새 계획 B에 "끝나면 A로 돌아감"을 적는다
  - 충돌 검사 두 번: B를 만들 때(앞쪽), B가 끝나고 A로 돌아올 때(뒤쪽)
  - 패널(scv-dashboard)이 보류 · 돌아갈 곳을 한국어로 보여 준다
- **Non-Goals**
  - 계획 밖 요구를 훅이 자동으로 감지하는 일 — "같은 목표인가"는 모델이 판단하고 이력에 적는다
  - 래퍼 저장소(scv-claude-code · scv-codex) 릴리스 — 이 계획이 끝난 뒤 따로
  - 끝난 단계를 다시 쓰거나 지우는 일

## Approach Overview

- 상태 값에 `paused`(보류)를 하나 더한다. 보류인 계획은 frontmatter 에 `paused_by`(원인이 된 새 계획) · `resume_at`(재개할 단계 번호)을 갖는다.
- 새 계획은 frontmatter 에 `return_to`(끝나면 돌아갈 계획)를 갖는다.
- PLAN.md 에 `## 변경 이력` 절을 둔다. 한 줄 형식: `- <날짜> · <종류> · <내용> · 이유: <한 줄>`. 종류는 추가 · 보류 · 재개 · 다시 하기.
- 판단 규칙은 work · help 절차 글에 적는다: 진행 중(in_progress · testing) 계획이 있을 때 계획 밖 요구가 오면 같은 목표인지 판단하고, 같으면 넣고 다르면 보류 → 새 계획.
- 기록 · 대조는 스크립트 하나(`plan-link.sh`)가 맡는다. 판단은 모델이, 파일 고치기와 대조는 스크립트가 한다.
- 복귀는 work 보관 직후, supersede 전파(Step 9c) 바로 옆 단계에서 `return_to` 를 보고 실행한다. 여러 겹(C → B → A)이면 한 겹씩 거슬러 돌아간다.
- 패널은 scv-mods 저장소에 있어 PR 이 따로 나간다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
// 보류 → 새 계획 연결
flow(
  readPlans,            // (A 경로, B 경로) → { a, b } frontmatter + 본문
  checkConflictBefore,  // ({ a, b }) → 충돌 목록 (A 남은 단계 · Non-Goals ↔ B Goals)
  markPause,            // ({ a, b, resumeAt }) → a' (paused · paused_by · resume_at · 이력 줄)
  linkReturn,           // ({ a, b }) → b' (return_to · 이력 줄)
  writePlans,           // (a', b') → 파일
)
// 복귀
flow(
  readPlans,            // (B 경로) → { b, a = b.return_to }
  checkConflictAfter,   // ({ a, changedFiles }) → 겹침 목록 (B 가 바꾼 파일 ↔ A 남은 단계 refs)
  markResume,           // ({ a, b }) → a' (in_progress · 이력 줄, paused_by/resume_at 지움)
  writePlans,           // (a') → 파일
)
// 같은 목표 — 기존 계획에 넣기
flow(readPlans, appendStep, writePlans)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | readPlans | 계획 파일을 읽어 frontmatter · 단계 · 이력으로 나눔 | 경로 → 계획 값 | 부수효과 (입구) |
| 2 | checkConflictBefore | B 목표가 A의 남은 단계 · 하지 않기로 한 것과 겹치는지 찾음 | { a, b } → 충돌 목록 | 순수 |
| 3 | markPause | A를 보류로 바꾸고 원인 · 재개 지점 · 이력 한 줄을 붙임 | { a, b, resumeAt } → a' | 순수 |
| 4 | linkReturn | B에 돌아갈 계획과 이력 한 줄을 붙임 | { a, b } → b' | 순수 |
| 5 | checkConflictAfter | B가 바꾼 파일이 A의 남은 단계 대상과 겹치는지 찾음 | { a, changedFiles } → 겹침 목록 | 순수 |
| 6 | markResume | A를 진행 중으로 되돌리고 재개 이력 한 줄을 붙임 | { a, b } → a' | 순수 |
| 7 | appendStep | 같은 목표의 요구를 의존 단계 뒤에 끼우고 이력 한 줄을 붙임 | { a, step, after } → a' | 순수 |
| 8 | writePlans | 고친 계획을 파일에 씀 | 계획 값 → 파일 | 부수효과 (출구) |

- 부수효과 위치: 1(파일 읽기)과 8(파일 쓰기)뿐. `changedFiles` 는 호출하는 쪽이 git 에서 구해 넘긴다.
- 재사용: frontmatter 읽기는 기존 `core/scripts/lib` 의 yaml 읽기를 쓰고, 변경 파일 목록은 `drift-detect.sh` 와 같은 방식(git diff)으로 구한다.

## Guardrails

- 끝난 단계(`[x]`)의 글은 고치지 않는다. 바뀐 요건은 "다시 하기" 단계로 새로 붙인다.
- 기존 상태 값의 뜻 · 패널 표시는 바꾸지 않는다. `paused` 만 더한다.
- 충돌이나 겹침이 하나라도 나오면 스스로 고치지 않고 선택 창으로 묻는다(어느 쪽 요건을 바꿀지).
- supersede 전파(Step 9c)의 동작 · 질문 문구는 그대로 둔다.
- 맥(BSD)과 리눅스(GNU) 모두에서 같은 결과 — `sed -i` · `date` 차이를 피한다.

## Exit criteria

- All TESTS.md scenarios pass
- 보류 · 복귀를 한 번 겪은 계획 파일을 GitHub 에서 열었을 때, 이력만 읽고 "언제 · 왜 멈췄고 · 무엇이 끝나서 · 몇 단계부터 다시 했는지" 답할 수 있다
- 패널에서 보류인 계획이 "보류 · <B 제목> 끝나면 재개"로, B는 "끝나면 <A 제목>으로 돌아감"으로 보인다

## Suggested path

1. 상태 값에 `paused` 를 더하고 frontmatter 검사가 받아들이게 함 — 보류 상태 값을 검사 스크립트에 추가
2. `plan-link.sh` 에 pause · link · resume · append 를 만듦 — `readPlans`, `markPause`, `linkReturn`, `markResume`, `appendStep`, `writePlans`
3. 앞쪽 · 뒤쪽 충돌 대조를 만듦 — `checkConflictBefore`, `checkConflictAfter`
4. work 절차에 판단 규칙과 보관 직후 복귀 단계(Step 9c 옆)를 적고, help 절차에 진행 중 계획이 있을 때의 판단 규칙을 적음 — 절차 글에 규칙 추가
5. PROMOTE.md 에 `paused` · `paused_by` · `resume_at` · `return_to` · `## 변경 이력` 형식을 적음 — 계획 형식 설명 추가
6. 시험 파일 `core/tests/test-plan-link.sh` 를 만들고 맥 · 리눅스에서 돌림 — TESTS.md 시나리오 실행
7. scv-mods 패널: 보류 표시 · 정렬 · 다음 할 일 · 돌아갈 곳 표시 (별도 PR) — 패널 표시 추가

## Related Documents

- [`core/protocols/work.md`](../../../core/protocols/work.md) — Step 9c supersede 전파 (복귀 단계를 붙일 자리)
- [`core/scripts/check-frontmatter.sh`](../../../core/scripts/check-frontmatter.sh) — `PLAN_STATUS`
- `../scv-mods/marketplace/mods/scv-dashboard/hooks/model.ts` — `STATUS_ORDER` · `statusWords` · `nextAction`

## Risks / Open Questions

- 패널은 다른 저장소라 core 릴리스와 패널 릴리스 사이에 `paused` 가 영어 그대로 보이는 기간이 생길 수 있다 — core 를 먼저 내고 패널을 곧바로 내서 줄인다.
- "같은 목표인가" 판단을 모델이 틀릴 수 있다 — 판단 결과를 이력 줄에 남겨 사람이 나중에 바로잡을 수 있게 한다.
- 래퍼 저장소 반영(sync)은 이 계획 밖 — 끝나고 따로.

## 변경 이력

- **2026-11-09 만듦** — 대화 fold-offplan-into-plan 에서 나옴
  - 이유: 모바일에서 계획이 왜 멈췄는지 알 수 없음

- **2026-11-09 이력 문구 바꿈** — 두괄식 · 개조식 · 사건마다 줄바꿈
  - 이유: 사용자 요청(처음 실행 결과를 보고)
  - 패널 돌아갈 곳 줄도 같은 꼴: "끝나면 돌아갈 계획: <제목>" (제목 끝 받침에 따라 '으로/로'가 틀리는 것을 피함)

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
