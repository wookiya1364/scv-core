---
title: 회귀 시험 — 같은 시험은 한 번만, 여러 개를 동시에
slug: 20261101-wookiya1364-regression-dedupe-parallel
author: wookiya1364
created_at: 2026-11-01
status: planned
kind: refactor
lang: korean
tags: [regression, performance, tests]
raw_sources:
  - scv/conversations/20261101-003000-pure-function-catalog-reuse.md
refs:
  - type: link
    url: scv/archive/20261101-wookiya1364-pure-function-catalog/PLAN.md
invariants:
  - "계획마다 통과 · 실패 판정과 출력 모양(FAILED_SLUGS 등)은 그대로다"
  - "--no-memo 를 주면 예전처럼 계획마다 하나씩 돈다"
  - "supersedes · obsolete 건너뛰기는 그대로다"
---

# 회귀 시험 — 같은 시험은 한 번만, 여러 개를 동시에

## Summary

보관 전 회귀 시험이 49분을 돌고도 끝나지 않았다(확인, 2026-11-01). 보관된 계획 92개가 같은 시험을 각자 적어 두어, 실행 250번 중 서로 다른 시험은 73개뿐이다(약 3.4배). 이미 '전체 묶음 3가지는 한 번만' 기억 장치가 있지만 시험 파일 하나를 부르는 줄(예: 모델 프롬프팅 시험 13번)은 대상이 아니다. 시험 파일 하나를 부르는 줄은 전부 한 번만 돌리고, 그 시험들을 먼저 여러 개 동시에 돌린 뒤 계획별 판정에 결과를 나눠 준다.

## Goals / Non-Goals

- **Goals**
  - 계획들의 실행 줄 중 '시험 파일 하나를 bash 로 부르는 줄'(뒤에 리디렉션 · `|| 실패` 꼬리 허용)을 모아 같은 줄은 한 번만 돈다.
  - 그 한 번씩을 회귀 시작 때 여러 개 동시에 돈다(코어 수, `run-focused` 와 같은 방식 — `# scv-test: serial` 표시가 있는 시험은 혼자).
  - 계획마다의 판정 · 출력은 그대로 — 공유 시험이 실패하면 그것을 적은 모든 계획이 실패.
  - 전후 시간을 잰다(이 저장소 전체 회귀).
- **Non-Goals**
  - 시험 하나하나를 빠르게 만들기.
  - 시험 파일 하나를 부르지 않는 줄(조립된 명령 · 파이프)의 병렬화 — 계획 안 순서대로 그대로 돈다.

## Approach Overview

- 기존 기억 장치(키 3개)를 일반화한다: 줄을 '시험 줄 키'로 바꾸는 순수함수가 키를 내면 기억 대상.
- 회귀 시작: 모든 계획의 실행 블록 → 키 모으기 → 겹친 것 빼기 → 동시 실행(결과 코드 기록) → 계획 루프는 키가 있는 줄을 `( exit 코드 )` 로 바꿔 나머지만 돈다(지금의 다시 쓰기 방식 그대로).
- 동시 실행의 시간 한도 · 깨끗한 환경은 지금 `run_scenario_clean` 을 그대로 쓴다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readBlocks,          // 보관 폴더 → 계획별 실행 블록 (입구, 부수효과)
  lineKey,             // 실행 줄 → 시험 줄 키 또는 빈 값
  collectKeys,         // 블록들 → 겹치지 않는 키 목록
  runKeysParallel,     // 키 목록 → 키별 종료 코드 (부수효과 — 시험 실행)
  rewriteBlock,        // 블록 + 키별 코드 → 기억된 줄을 바꾼 블록
  runBlocks,           // 블록들 → 계획별 판정 (부수효과)
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | readBlocks | 계획마다 실행 블록을 읽는다 | 보관 폴더 → 블록들 | 부수효과 (입구) |
| 2 | lineKey | 시험 파일 하나를 부르는 줄이면 키를 낸다 | 줄 → 키 · 빈 값 | 순수 |
| 3 | collectKeys | 모든 블록의 키를 겹치지 않게 모은다 | 블록들 → 키 목록 | 순수 |
| 4 | runKeysParallel | 키마다 한 번, 여러 개 동시에 돌린다 | 키 목록 → 키별 코드 | 부수효과 |
| 5 | rewriteBlock | 기억된 줄을 그 코드로 바꾼다 | 블록 + 코드 → 블록 | 순수 |
| 6 | runBlocks | 남은 블록을 계획마다 돌려 판정한다 | 블록들 → 판정 | 부수효과 (출구) |

- 부수효과 위치: 1 · 4 · 6.
- 재사용: 지금의 `run_scenario_clean` · `run_with_timeout` · 다시 쓰기 방식. 키 3개짜리 기억은 2 · 5 로 흡수.

## Guardrails

- 계획 판정이 바뀌면 안 된다 — 같은 보관 폴더에서 전후 FAILED_SLUGS · 계획별 통과/실패가 같아야 한다.
- 시험이 서로 밟는 파일(공용 임시 파일)이 있으면 그 시험은 `serial` 표시로 혼자 — 표시 규칙은 run-focused 와 같게.
- `--no-memo` 는 예전 동작.

## Exit criteria

- All TESTS.md scenarios pass
- 이 저장소 전체 회귀가 끝까지 돌고, 시간이 숫자로 남는다(전: 49분 넘게 미완).

## Suggested path

1. 줄 → 키 순수함수와 키 모으기 — `lineKey`, `collectKeys`
2. 시작 때 동시 실행 · 코드 기록, serial 표시 존중 — `runKeysParallel`
3. 블록 다시 쓰기를 일반 키로 — `rewriteBlock`
4. 계획 루프는 그대로, 기억 통계 줄 — `runBlocks`
5. 시험 · 전후 시간 측정 — 시험을 쓰고 전체 회귀를 돌려 잰다

## Risks / Open Questions

- 동시 실행 중 서로 영향을 주는 시험이 숨어 있을 수 있다 — 전후 판정 비교로 잡는다.
- 맥 로컬 코어 수만큼 돌리면 무거운 시험들이 겹쳐 개별 시간 한도에 걸릴 수 있다 — 한도 초과는 지금처럼 실패로 보고.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
