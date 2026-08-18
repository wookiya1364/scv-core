---
title: 회귀 계약 보수 — 성립 불가 4건의 내구성 있는 재표현
slug: 20260818-wookiya1364-regression-contract-repair
author: wookiya1364
created_at: 2026-08-18
status: done
kind: refactor
lang: korean
tags: [regression, tests]
raw_sources:
  - scv/raw/stale/20260818-wookiya1364-regression-contract-repair.md
refs: []
supersedes:
  - 20260807-wookiya1364-decision-log-activation
  - 20260811-wookiya1364-implementation-principles
  - 20260812-wookiya1364-plain-language
  - 20260812-wookiya1364-ci-provenance-gate
invariants:
  - "옛 4개 슬러그의 TESTS.md·ARCHIVED_AT.md 본문은 바이트 그대로 (frontmatter 3필드만)"
  - "네 기능의 회귀 검증은 사라지지 않고 이 슬러그의 TESTS 로 이어진다"
---

# 회귀 계약 보수 — 성립 불가 4건의 내구성 있는 재표현

## Summary

누적 회귀에서 영원히 빨간 아카이브 4건을 이 슬러그 하나가 대체한다. 셋은
`git diff HEAD` 로 편집 범위를 단언해서 커밋된 순간부터 거짓이고, 하나는 존재한
적 없는 스크립트를 부른다. 네 기능(결정 로그·구현 원칙·쉬운 말·provenance
게이트)은 전부 살아 있으므로, 검증을 버리지 않고 내구성 있는 형태로 옮긴다.

## Goals / Non-Goals

- **Goals**
  - 이 슬러그의 TESTS 가 네 기능을 커밋 후에도 참인 단언만으로 검증한다
  - 아카이브 시 `supersedes:` 절차가 옛 4건을 `obsolete + obsoleted_by` 로 마킹
  - 누적 회귀가 12/12 판정 가능 상태가 된다 (8 실행 + 4 스킵 + 이 슬러그)
  - 재발 방지: PROMOTE.md 의 TESTS 규칙 한 줄 + tests-smell.sh warn 규칙
- **Non-Goals**
  - 옛 4건의 TESTS.md 본문 수정 (금지 유지)
  - 네 기능 자체의 동작 변경 — 이 계획은 검증 문서만 옮긴다
  - Core 릴리스 — 보수 슬러그는 저장소 로컬. PROMOTE.md·tests-smell 변경만
    다음 릴리스에 자연 편승한다

## Approach Overview

TESTS.md 가 산출물의 전부다. 원본 네 개의 How-to-run 에서 두 부류를 뺀다:
커밋 전 상태 단언(`git diff` 범위 검사 — 이번 사태의 원인)과 슬러그 내부의 전체
스위트 재실행(회귀를 O(n²) 로 만든 주범 — 전체 스위트는 CI 가 이미 돈다).
남는 것이 각 기능의 진짜 계약이다: 파일·구절 존재, guidance-filter 투영 생존,
실존 스위트 호출.

재발 방지 둘: PROMOTE.md TESTS 작성 규칙에 "How-to-run 은 아카이브된 뒤에도
참이어야 한다" 를 명시하고, tests-smell.sh 에 같은 냄새(warn 전용, 기존 헌장
그대로)를 넣는다.

## Guardrails

- 옛 4건은 frontmatter 3필드(`status`/`obsoleted_at`/`obsoleted_by`)만 변한다
- 이 슬러그의 TESTS 는 자기 규칙을 스스로 지킨다: git-diff 단언 없음, 실존 파일만
  참조, 전체 스위트 재실행 없음, 어느 커밋에서 돌려도 같은 판정
- tests-smell.sh 는 warn 전용을 유지한다 — 절대 차단하지 않는다
- PROMOTE.md 문구는 `test-guard-consistency.sh` 구문 스윕을 통과해야 한다

## Exit criteria

- 이 슬러그의 TESTS How-to-run 이 초록이고, **HEAD 를 임의 과거 커밋에 둔 사본
  트리에서도 같은 판정** (내구성의 직접 증명)
- 아카이브 후 옛 4건이 obsolete 로 마킹되고 `regression.sh` 스킵 목록에 잡힌다
- tests-smell.sh 가 옛 4건의 TESTS 를 주면 warn 을 내고, 이 슬러그 것에는 안 낸다
- 전체 스위트 초록 유지

## Suggested path

1. TESTS.md — 네 기능의 내구 재표현 (T1 게이트, T2 결정로그, T3 원칙, T4 쉬운말)
2. tests-smell.sh — `git diff --name-only HEAD` 냄새 + 부재 스크립트 참조 warn
3. PROMOTE.md — TESTS 규칙 한 줄
4. 아카이브 → supersede 절차로 옛 4건 마킹 → 회귀 재실행으로 스킵 확인

## Related Documents

- [`TESTS.md`](./TESTS.md)

## Risks / Open Questions

- 옛 슬러그의 검증 강도가 일부 낮아진다(범위 격리 단언은 대체 불가능해서 제거).
  그 단언이 지키던 것은 이제 merge-time provenance 게이트와 리뷰가 지킨다
- tests-smell 의 부재-스크립트 검사는 상대 경로 해석이 필요해 휴리스틱이다 —
  warn 전용이므로 오탐 비용은 한 줄 출력이다

## Links

- Raw originals: (frontmatter 참조)
- Related PRs:
