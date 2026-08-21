---
title: "run-dry 배치 가드 — 래퍼 투영에서도 TEMPLATE_VERSION 검사가 돈다"
slug: 20260821-wookiya1364-run-dry-layout-guard
author: "wookiya1364"
created_at: 2026-08-21
status: done
kind: feature
lang: korean
tags: [tests, wrapper, release]
raw_sources:
  - scv/conversations/20260821-141947-run-dry-layout-guard.md
refs: []
supersedes: []
scope:
  - "core/tests/run-dry.sh"
  - "CHANGELOG.md"
invariants:
  - "scv-core 체크아웃(루트 복사본 존재)에서는 여전히 두 TEMPLATE_VERSION 이 같아야 통과"
  - "루트 복사본이 없는 배치(래퍼 루트 투영)에서는 그 한 단언만 '단일 복사본' 으로 통과 — 다른 단언은 그대로"
---

# run-dry 배치 가드

## Summary

0.31.0 의 run-dry [15q] 가 core/TEMPLATE_VERSION 과 ../TEMPLATE_VERSION 을 비교한다.
scv-core 와 내보낸 페이로드에는 루트 복사본이 있지만, Claude 래퍼는 페이로드를
자기 루트에 투영해 run-dry 를 돌리므로 부모 복사본이 없다 — 래퍼의 core-sync
검증이 그 한 줄로 실패해 봇 PR 이 열리지 않았다(Codex 래퍼는 vendor/ 아래에서
돌려 통과). 루트 복사본이 있을 때만 비교하고, 없으면 단일 복사본 배치로 통과한다.

## Goals / Non-Goals

- **Goals**: [15q] 한 단언을 배치 무관하게 만든다. 래퍼 배치(부모에 TEMPLATE_VERSION
  없음)를 흉낸 가드 1건. 0.31.1 패치 릴리스.
- **Non-Goals**: 래퍼 투영 방식 변경, 다른 단언 수정.

## Approach Overview

`PL_ROOT_TV=$(dirname PROTOCOL_ROOT)/../TEMPLATE_VERSION` 가 파일이면 비교, 아니면
pass. 가드: 페이로드를 래퍼처럼 한 디렉터리에 펼쳐(`cp -RL core/. X/w/` — scv-core 의
`core/TEMPLATE_VERSION` 은 `../TEMPLATE_VERSION` 심볼릭 링크라 역참조 필수, 부모에
TEMPLATE_VERSION 없음) run-dry 를 돌리면 FAIL 0.

## Guardrails

- scv-core 안에서의 일치 검사는 유지한다(루트 복사본이 있으면 반드시 같아야 한다).
- 테스트에 git 상태 단언 금지.

## Exit criteria

- TESTS How-to-run exit 0. 0.31.1 릴리스 후 두 래퍼의 core-sync 검증이 통과해 봇 PR 이 열린다.

## Suggested path

1. run-dry [15q] 가드. 2. TESTS(복사본 배치). 3. CHANGELOG. 4. archive → PR → 0.31.1.

## Related Documents

- 선행: `scv/archive/20260821-wookiya1364-plain-answers-enforcement/PLAN.md`

## Risks / Open Questions

- 래퍼 투영에서 돌아가야 하는 단언이 또 생기면 같은 함정이 반복된다 — 테스트는
  저장소 배치가 아니라 페이로드 배치를 전제해야 한다는 교훈을 CHANGELOG 에 남긴다.

## Links

- Raw originals: (frontmatter 참조)
