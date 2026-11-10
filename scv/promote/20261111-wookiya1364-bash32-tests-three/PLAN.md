---
title: bash 3.2 에서 실패하는 시험 셋 고치기
slug: 20261111-wookiya1364-bash32-tests-three
author: wookiya1364
created_at: 2026-11-11
status: planned
kind: feature
lang: korean
tags: [tests, bash32, mac]
scope:
  - core/tests/test-graph.sh
  - tests/test-guard-consistency.sh
  - tests/test-promote-wait.sh
raw_sources:
  - scv/raw/20261110-remaining-work-three-plans.md
refs: []
invariants:
  - "세 시험이 보는 내용(검사 항목 수와 기대값)은 줄지 않는다"
  - "bash 5 에서의 결과는 그대로다"
---

# bash 3.2 에서 실패하는 시험 셋 고치기

## Summary

맥 기본 bash(3.2)로 돌리면 시험 셋이 실패한다. develop 에서도 같다(2026-11-10 확인).
맥과 리눅스 둘 다에서 돌아야 한다는 규칙에 어긋나므로, 세 시험이 bash 3.2 에서도 통과하게 고친다.

## Goals / Non-Goals

- **Goals**
  - `core/tests/test-graph.sh` · `tests/test-guard-consistency.sh` · `tests/test-promote-wait.sh` 가 bash 3.2 에서 통과
  - 시험이 가리키는 스크립트 자체가 bash 3.2 에서 틀리게 돌면 그 스크립트도 고침
- **Non-Goals**
  - 세 시험이 보는 내용 바꾸기
  - 다른 시험 손보기
  - bash 4 전용 문법을 찾는 새 검사 만들기

## Approach Overview

- 원인이 확인된 것은 하나다: `tests/test-guard-consistency.sh:65` 의 `mapfile`(bash 4 부터 있음). `while read` 로 바꾼다.
- 나머지 둘의 원인은 모른다. 1단계에서 bash 3.2 로 돌려 실패한 줄을 찾는다.
- 원인이 시험 파일에 있으면 시험만, 스크립트에 있으면 스크립트를 고친다. 스크립트를 고치면 그 스크립트의 다른 시험도 두 bash 로 다시 돌린다.
- 고친 것이 시험 파일뿐이면 버전을 올리지 않고 다음 릴리스에 함께 나간다. 스크립트를 고치면 CHANGELOG 에 적는다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

이 계획은 새 함수를 만들지 않는다. 하는 일의 차례만 적는다.

```
flow(
  run_under_bash32,   // 시험 파일 → 실패한 줄과 메시지        (부수효과: 시험 실행)
  locate_cause,       // 실패 메시지 → 원인 줄 (시험 | 스크립트)
  portable_rewrite,   // 원인 줄 → bash 3.2 에서도 도는 같은 뜻의 줄
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | `run_under_bash32` | 시험을 bash 3.2 로 돌려 실패한 곳을 얻는다 | 시험 파일 → 실패 줄 · 메시지 | 부수효과 (입구) |
| 2 | `locate_cause` | 실패가 시험 탓인지 스크립트 탓인지 가른다 | 실패 메시지 → 원인 줄 | 순수 |
| 3 | `portable_rewrite` | 같은 뜻을 bash 3.2 문법으로 다시 쓴다 | 원인 줄 → 고친 줄 | 순수 |

- 부수효과 위치: 1(시험 실행)뿐.
- 재사용: 다른 시험에 이미 있는 `while IFS= read -r` 읽기 모양을 그대로 쓴다.

## Guardrails

- 기대값을 느슨하게 하거나 검사를 건너뛰게 해서 통과시키지 않는다(`bash 버전이 낮으면 건너뜀` 금지).
- bash 5 에서의 통과 수가 줄면 안 된다.
- 고치는 파일은 원인이 있는 파일뿐이다.

## Exit criteria

- TESTS.md 의 시나리오 7개 통과
- 세 시험 각각 `/bin/bash`(3.2)와 bash 5 에서 종료 코드 0
- CI 맥 · 리눅스 통과

## Suggested path

1. 세 시험을 bash 3.2 로 돌려 실패한 줄과 메시지를 모음 — `run_under_bash32`
2. 실패마다 원인이 시험인지 스크립트인지 가름 — `locate_cause`
3. 원인 줄을 bash 3.2 에서도 도는 모양으로 고침 — `portable_rewrite`
4. 세 시험을 두 bash 로 다시 돌리고 통과 수를 고치기 전 bash 5 결과와 견줌 — 검사 수가 줄지 않았는지 본다
5. 전체 시험을 두 bash 로 돌림 — 새로 실패한 것이 없는지 본다

## Related Documents

- [`TESTS.md`](./TESTS.md)
- [`FEATURE_ARCHITECTURE.md`](./FEATURE_ARCHITECTURE.md)

## Risks / Open Questions

- 원인 둘은 아직 모른다. 스크립트 쪽 문제면 범위가 그 스크립트로 넓어진다 — 넓어지면 변경 이력에 적는다.
- 원인이 bash 가 아니라 맥의 다른 도구(BSD sed · date 따위)일 수 있다. 그래도 고칠 대상은 같다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
