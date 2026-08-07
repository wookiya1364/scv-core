---
title: "scv/routines/ — 한 문장 프롬프트 유지보수 루틴 레이어"
slug: 20260807-wookiya1364-routines
author: "wookiya1364"
created_at: 2026-08-07
status: planned
kind: feature
lang: ko
epic: 20260807-scv-simplification
tags: [routines, maintenance, automation, action, wrapper-seam]
raw_sources: []
refs:
  - type: reference
    url: "https://www.youtube.com/watch?v=qyPCVqFUyDo"
    note: "Boris Cherny — 일일 유지보수 루틴 20~30개로 앱 유지보수 자동화"
invariants:
  - "루틴 실행은 항상 PR/보고 경유 — 루틴이 permanent 브랜치에 직접 쓰지 않는다"
  - "스케줄링은 호스트 소유 (Claude Code /loop·routines, cron) — Core 는 정의·실행 프로토콜만"
  - "루틴 정의는 과업+가드레일+종료 조건 형식 — 절차 나열 금지 (plan-grammar 계획과 동일 문법)"
---

# scv/routines/ — 유지보수 루틴 레이어

## Summary (what & why)

Boris 인터뷰의 핵심 실천("한 문장 프롬프트 루틴 20~30개가 매일 돌며
유지보수를 자동화")을 SCV 의 프로토콜 구조로 가져온다. 현재 core 에는 반복
실행 개념이 전무하다. SCV 는 이미 루틴의 재료(regression, outdated 후보,
promote 방치, report)를 갖고 있으므로, 루틴 정의 형식과 실행 액션만 얹으면
된다.

## Goals

1. **`scv/routines/` 규약**: 루틴 1개 = md 파일 1개. frontmatter:
   `name / cadence(제안 주기) / guardrails / exit(종료 조건) / report(보고
   여부)` + 본문은 한 문장~한 단락의 과업 서술. hydrate 가
   `routines/README.md`(규약 설명)만 시딩하고 루틴 파일은 사용자/에이전트가
   추가.
2. **`action:routine <name>` 신설** (15번째 액션): 해당 루틴 md 를 읽고
   과업을 수행, 결과를 `action:report` 형식으로 요약(옵션). `action:routine
   --list` 는 정의된 루틴과 제안 주기를 표시. **스케줄링은 하지 않는다** —
   출력 마지막에 호스트별 등록 예시(Claude Code `/loop 1d action:routine
   dead-code`, cron 등)만 안내.
3. **SCV 내장 루틴 템플릿 4종** (`core/template/scv/routines/examples/` 또는
   문서 내 예시):
   - `regression-runner` — action:regression 실행, 실패 시 report
   - `outdated-verifier` — readpath outdated 의 OUTDATED-CANDIDATE 를 현재
     코드와 의미 대조, 판정을 보고 (0.21.0 기능의 자동화 완성)
   - `promote-staleness` — `status: planned` N일 초과 폴더 리마인드
   - `archive-integrity` — INDEX.yaml 재생성·supersedes 링크 검증
4. **코드베이스 루틴 예시 3종** (Boris 직수입, 프로젝트 무관 템플릿):
   dead-code 제거 / abstraction-police(중복 추상화 통합 제안) /
   useless-test 삭제 제안.
5. **wrapper seam**: 새 액션이므로 `core/actions.json` + 두 wrapper 의 명령
   표면 등록 필요 — **재벤더링만으로 안 되는 최초의 변경**. 구현 완료 시
   scv-claude-code/scv-codex 로 handoff 2건 발행(등록 방법 + 액션 계약).
6. team-journal 과 접점: 루틴 실행 결과는 report 규약을 따르고, journal 이
   도입되면 실행 이력이 자동 축적된다 (이 계획은 journal 을 전제하지 않음).

## Non-Goals

- 스케줄러/데몬 구현 (호스트 소유)
- 루틴의 자동 PR 생성 로직 (호스트 에이전트가 기존 pr-helper 흐름 사용)
- 동적 워크플로 오케스트레이션 (호스트 능력)

## Steps

1. routines 규약 문서 + frontmatter 스키마 + hydrate/sync 반영
2. `action:routine` 프로토콜(routine.md) + 헬퍼 스크립트(목록·frontmatter 파싱)
3. 내장 템플릿 4종 + 코드베이스 예시 3종
4. actions.json + 계약 테스트(15개 액션) 갱신, run-dry 확장
5. wrapper handoff 2건 (명령 등록)
6. VERSION/CHANGELOG (0.22.0 웨이브)

## Risks / Open Questions

- 액션 수 계약(현재 "14개 액션이 정확히 1회씩")을 검증하는 wrapper CI 가
  깨질 수 있음 → handoff 에 계약 갱신 포함, 두 wrapper 동시 릴리스.
- 루틴 폭주(같은 제안 반복) → 루틴 정의에 exit/중복 억제 가드레일 필수 +
  report 로 가시화.
