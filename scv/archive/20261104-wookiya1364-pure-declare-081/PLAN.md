---
title: 모든 함수에 순수 · 부수효과 선언 — 빠뜨리면 쓰기 거절 · 목록 검사 기준선
slug: 20261104-wookiya1364-pure-declare-081
author: wookiya1364
created_at: 2026-11-04
status: testing
kind: feature
lang: korean
tags: [purity, catalog, guard]
raw_sources:
  - scv/conversations/20261102-182255-writing-style-bullets.md
refs: []
invariants:
  - "기존 @pure · @deterministic 표식과 사전 모양은 그대로(대시보드가 읽음)"
  - "찾지 못하는 언어 · 제외 폴더는 판정하지 않음"
  - "옛 함수만 있는 파일의 다른 편집은 막지 않음"
---

# 모든 함수에 순수 · 부수효과 선언

## Summary

- slay 세션에서 파일 안에서만 쓰는 작은 함수의 역할 주석을 건너뜀(사용자 보고). 목록 검사가 표시 달린 함수만 읽어 빠진 것을 잡지 못함(확인 — pure-catalog 는 표식이 든 함수만 고름).
- 사용자 결정: "절대 있어서는 안 된다" — 모든 함수가 선언을 갖고, 빠뜨리면 쓸 때 막는다.

## Goals / Non-Goals

- **Goals**
  - 선언 두 가지: `@pure`(또는 `@deterministic`) 이름 + 역할 · 종류 · 예 / `@effect` 이름 + `이유:` 한 줄
  - 언어별 함수 찾기(sh · ts/js · py · go)
  - 파일 쓰기 때: 편집 뒤 선언 없는 함수가 편집 전보다 늘면 거절(빠진 이름 제시)
  - 목록 검사: 선언 없는 함수 수가 기준선보다 늘면 실패, 줄면 기준선 내림
  - 규약 · work/codegen 안내 반영, 코어 자신도 같은 규칙
- **Non-Goals**
  - 함수가 정말 순수한지 자동 판정(코어 셸은 기존 순수성 검사 그대로)
  - 지원 밖 언어

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  scv_pd_functions,     // 언어 · 본문 → 함수 이름들
  scv_pd_declared,      // 본문 → 선언된 이름들(@pure · @deterministic · @effect)
  scv_pd_missing,       // 함수 · 선언 → 선언 없는 이름들
  scv_pd_write_verdict, // 편집 전 · 후 빠진 이름 → ok | 거절 이유
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | scv_pd_functions | 파일 본문에서 함수 이름을 찾음 | 언어 · 본문 → 이름 줄들 | 순수 |
| 2 | scv_pd_declared | 선언 주석의 이름을 모음 | 본문 → 이름 줄들 | 순수 |
| 3 | scv_pd_missing | 선언이 없는 함수만 남김 | 함수 · 선언 → 이름 줄들 | 순수 |
| 4 | scv_pd_write_verdict | 편집으로 빠진 이름이 늘었는지 판정 | 전 · 후 빠진 이름 → ok/이유 | 순수 |
| 5 | guard.sh Rule D | 편집 뒤 본문을 만들어 판정 · 거절 | 훅 입력 → 거절/통과 | 부수효과 (입구/출구) |
| 6 | pure-catalog.sh check | 저장소 전체 빠진 수 · 기준선 | 파일들 → 결과 · 기준선 파일 | 부수효과 (입구/출구) |

## Guardrails

- 사전 항목 모양 · 기존 표식 규칙 그대로
- 제외 폴더(tests · vendor · node_modules · dist · build · target · scv)와 시험 파일은 판정 안 함
- 스위치 `SCV_PURE_DECLARE=off`
- 가드 실패 정책 그대로(읽기 실패면 통과)

## Exit criteria

- TESTS.md T1–T6 통과, 전체 점검 · 회귀 통과
- 실제: slay 에서 선언 없는 새 함수를 쓰게 하면 거절되고, 선언을 달면 통과

## Suggested path

1. 함수 · 선언 찾기와 판정 순수 함수 — `scv_pd_functions`, `scv_pd_declared`, `scv_pd_missing`, `scv_pd_write_verdict`
2. 가드 쓰기 검사 — `guard.sh Rule D`
3. 목록 검사 기준선 — `pure-catalog.sh check`
4. 규약 · 안내 · 코어 자신 정리 — 코어의 선언 없는 함수에 선언을 닮
5. 시험 · 실제 재현 — 단위 · 훅 시험과 slay 재현을 돌림

## Risks / Open Questions

- 정규식 함수 찾기는 완전하지 않음(익명 함수 · 클래스 메서드) — 이름 있는 선언만 봄
- 코어 셸 라이브러리의 선언 없는 함수 수가 많을 수 있음 — 기준선으로 시작해 줄여 감
