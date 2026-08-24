---
title: "회귀 계약 보수 2 — 설정 이사 뒤 성립 불가 6건의 내구성 있는 재표현"
slug: 20260824-wookiya1364-regression-contract-repair-2
author: "wookiya1364"
created_at: 2026-08-24
status: done
kind: refactor
lang: korean
tags: [regression, tests]
raw_sources:
  - scv/raw/stale/20260824-wookiya1364-regression-contract-repair-2.md
refs: []
supersedes: []
scope:
  - "scv/archive/*/PLAN.md"
  - "CHANGELOG.md"
invariants:
  - "옛 6개 슬러그의 TESTS.md·ARCHIVED_AT.md 본문은 바이트 그대로 (frontmatter 3필드만)"
  - "여섯 기능의 회귀 검증은 사라지지 않고 이 슬러그의 TESTS 로 이어진다"
  - "regression-runner-path-leak 는 그대로 살아 있다 — obsolete 슬러그를 --only 로 부르면 러너가 건너뛰어 T2 가 성립한다"
---

# 회귀 계약 보수 2

## Summary

0.32.0 이 설정을 `.env` 에서 `scv/scv_settings.json` 으로 옮기고 `.env.example.scv`
를 없애면서, `.env` 로 스위치를 검사하던 계약 4건이 성립 불가가 됐다. 같은 날의 두
계약(설정 이사·템플릿 지문)은 How-to-run 이 존재하지 않는 테스트 파일 이름을
불러 exit 127 이다. 누적 회귀는 24 실행 / 7 실패였다(0.34.0 작업과 무관).

0818 보수와 같은 방식으로 닫는다: 옛 계약은 frontmatter 3필드로 obsolete 표시(본문
불변), 살아 있어야 할 검증은 이 슬러그의 TESTS 가 **실제 파일 이름**으로 이어받는다.

## Goals / Non-Goals

- **Goals**: 6건 obsolete(obsoleted_by 이 슬러그) — plain-answers-enforcement,
  plain-sentence-cap, slug-scoped-attachments, env-example-autorefresh, settings-json,
  template-refresh. 이 TESTS 가 그 여섯의 살아 있는 검증을 실제 스위트로 다시 적는다.
  누적 회귀 FAILED 0.
- **Non-Goals**: 옛 TESTS 본문 수정, 테스트 파일 추가, path-leak 계약 변경.

## Approach Overview

| 옛 계약 | 성립 불가 이유 | 이어받는 검증 |
|---|---|---|
| plain-answers-enforcement, plain-sentence-cap | `.env` 스위치 검사 | run-dry [15p]/[15q] 앵커·위치·템플릿, test-journal [6p]/[6u](훅 요약·문장 상한·UTF-8) |
| slug-scoped-attachments | `.env.example.scv` 블록 | test-attachments-scope.sh 25 단언 + run-dry pr-helper slug 단언 |
| env-example-autorefresh | 파일·테스트 제거(0.32.0) | 설정 파일 자동 생성·병합(test-settings T13–T17)이 그 역할을 잇는다 |
| settings-json | 없는 파일 이름(pure/file/cleanup, core/tests/run.sh) | test-settings.sh 전량 + tests/run.sh + run-dry |
| template-refresh | 없는 파일 이름(autosync-digest, core/tests/run.sh) | test-template-digest.sh + test-autosync.sh + tests/run.sh + run-dry |

## Guardrails

- 옛 6건은 PLAN.md frontmatter 의 `status: obsolete` · `obsoleted_at` · `obsoleted_by` 만 더한다.
- git 상태 단언 금지. 이 TESTS 는 저장소 트리만으로 판정한다.

## Exit criteria

- 이 TESTS exit 0. `regression.sh` FAILED_SLUGS: 0 (obsolete 6 건너뜀).

## Suggested path

1. 6건 frontmatter 표시. 2. 이 TESTS 실행. 3. 누적 회귀 0 실패 확인 → archive(0.34.0 과 같은 PR).

## Related Documents

- 선행: `scv/archive/20260818-wookiya1364-regression-contract-repair/PLAN.md`

## Risks / Open Questions

- 앞으로 계약을 쓸 때 How-to-run 의 파일 이름은 존재하는 파일이어야 한다 — 0.32.0 두
  계약은 계획 단계의 이름을 그대로 적었다. 보관 직전 TESTS 블록 실행이 그 함정을 잡는다.
