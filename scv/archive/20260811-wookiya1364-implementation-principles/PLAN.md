---
title: "구현 원칙 4종 — 재활용·최소구현·모듈분리·장기관점 (work·codegen)"
slug: 20260811-wookiya1364-implementation-principles
author: "wookiya1364"
created_at: 2026-08-11
status: done
kind: feature
lang: ko
tags: [protocols, work, codegen, principles]
raw_sources: []
supersedes: []
scope:
  - "core/protocols/work.md"
  - "core/protocols/codegen.md"
  - "core/tests/**"
  - "CHANGELOG.md"
  - "docs/guidance-ablation.md"
invariants:
  - "4개 원칙은 CONTRACT(마커 밖) — minimal 투영에서 사라지면 원칙이 환경변수로 증발한다"
  - "PLAN 의 Guardrails 가 원칙보다 우선한다 (계획별 무력화 가능)"
  - "core/scripts/ 와 core/actions.json 은 수정하지 않는다"
  - "하위호환 관련 문구는 넣지 않는다 (보류 결정)"
---

# 구현 원칙 4종

## Summary

`action:work` / `action:codegen` 은 "무엇을 만들지"(PLAN)와 "무엇이 통과해야
하는지"(TESTS)는 계약으로 갖고 있지만, **어떻게 만들지에 대한 기본 원칙**은
갖고 있지 않다. `reuse` / `simplest` / `modular` grep 결과 구현 지시 0건이다.
그 결과 매번 계획서 Guardrails 에 같은 말을 반복해서 쓰거나, 아예 빠진다.

사용자가 지정한 4개 원칙을 Core 기본값으로 박는다 — 재활용 우선, 최소 구현,
모듈·관심사 분리, 되돌리기 어려운 결정은 장기 관점. PLAN 의 Guardrails 가
언제나 우선하므로 계획별로 무력화할 수 있다.

**하위호환 관련 원칙은 이번 범위에서 제외한다** (사용자 결정). SCV 자신이
legacy `## Steps` · `.conversations` 마이그레이션 · `CLAUDE.md`/`CODEX.md`
포인터로 후방호환을 광범위하게 유지하고 있어 층위 정리가 먼저 필요하다.

**데드코드 주기 제거는 추가하지 않는다** — 이미
`core/template/scv/routines/examples/dead-code.md`(`cadence: 1d`)가 정확히
그 루틴이다. 안 쓰이고 있을 뿐이므로, 필요하면 프로젝트의 `scv/routines/` 로
복사하면 된다(hydrate 는 README 만 시딩한다).

## Goals / Non-Goals

- **Goals**
  1. `work.md` Step 6 에 4개 원칙을 CONTRACT 로 추가.
  2. `codegen.md` 에도 같은 원칙을 배치 — codegen 은 work Step 6 을 상속하지
     않고 자체 Step 7(Green)/Step 8(Refactor)을 갖는다.
  3. 원칙이 `SCV_GUIDANCE=minimal` 투영에서 생존하도록 회귀 앵커 등록.
  4. PLAN Guardrails 우선 규칙을 문안에 명시.

- **Non-Goals**
  - 하위호환 원칙 (보류 — 별건)
  - 데드코드 루틴 (이미 존재)
  - `core/scripts/` 수정, 새 action, 새 문서 파일

## Approach Overview

**codegen 배치가 이 계획의 유일한 난점이다.** `codegen.md:7` 이 Steps 1–5b 와
8–9e 만 work verbatim 위임이라 선언하고, 6–8 은 자체 TDD 루프다. 따라서:

- 원칙 정본은 `work.md` Step 6 에 둔다.
- `codegen.md` 는 Step 7(Green) 에서 정본을 참조한다. 이미 "case-by-case
  minimal code" 를 갖고 있어 최소구현 원칙과는 결이 같으므로, 중복 서술 대신
  참조 한 줄이 맞다.

**알려진 마찰**: `core/tests/test-guidance.sh` [6] 은 **커밋되지 않은**
`core/protocols/` 변경이 promote·work 밖이면 실패한다(실측 확인). 이는
guidance-ablation 1단계의 스코프 가드로, 마커 유출 방지가 목적이지 평문 편집을
막으려는 것이 아니다. `codegen.md` 편집은 커밋 전까지 이 검사를 빨갛게 만든다 —
회귀가 아니라 가드의 설계다. TESTS 는 이 사실을 숨기지 않고 판정 기준에 적는다.

## Guardrails

- 4개 원칙 본문은 **마커 밖(CONTRACT)**. 근거 산문만 GUIDANCE.
- 새 GUIDANCE 블록에 `${SCV_CORE_ROOT}/scripts/*.sh` 호출과 **컬럼0**
  frontmatter 키를 넣지 않는다.
- `core/scripts/`, `core/actions.json`, host-profile 은 수정하지 않는다.
- 새 문서 파일을 만들지 않는다 — 0.22.0 의 표준문서 7종 제거 결정을 거스르지
  않는다.
- 하위호환("legacy 경로 제거") 관련 문구를 넣지 않는다.
- 원칙은 **PLAN Guardrails 에 종속**임을 문안에 명시한다 — Core 가 프로젝트
  정책을 덮어쓰지 않는다.
- 기존 heading 문자열을 개명하거나 번호를 재배치하지 않는다.
- 호스트 종속 토큰 금지.

## Exit criteria

- `work.md` Step 6 에 4개 원칙이 있고, 어떤 GUIDANCE 마커 쌍에도 속하지 않는다.
- `codegen.md` 가 그 정본을 참조한다.
- `guidance-filter.sh --lint` OK, `--mode full` 이 원본과 바이트 동일,
  `--mode minimal` 에 4개 원칙 앵커가 전부 생존.
- full/minimal 스크립트 호출 시퀀스 동일.
- `run-dry.sh` · `tests/run.sh` · `test-*.sh` 가 **`test-guidance.sh` [6] 을
  제외하고** 전부 green. [6] 은 codegen.md 미커밋으로 인한 예상된 실패이며,
  커밋 후 해소됨을 확인한다.
- CHANGELOG + 측정표가 `--lint` 실측과 일치.
- archive 시 `path delta:` 가 실제 값으로 기록된다.

## Suggested path

1. `work.md` Step 6 에 4개 원칙 삽입 (CONTRACT) + 근거 산문 (GUIDANCE).
2. `codegen.md` Step 7 에 정본 참조 한 줄 추가.
3. `run-dry.sh` [16] 인근에 원칙 앵커 assert, `test-guidance.sh` work.min.md
   배열에 앵커 등록.
4. 스위트 실행 → [6] 실패만 남는지 확인, 나머지 green 검증.
5. CHANGELOG + `docs/guidance-ablation.md` 측정표 갱신 (`--lint` 실측).
6. archive → DECISIONS 엔트리 (`path delta` 실제 값).

## Related Documents

<!-- 없음 -->

## Risks / Open Questions

- **`test-guidance.sh` [6] 이 커밋 경계를 강제한다.** 이 가드는 promote·work
  외 프로토콜의 미커밋 변경을 전부 실패로 본다. 어블레이션 2단계에서 다른
  프로토콜을 손대는 순간 같은 마찰이 재발한다 — 가드를 "마커 유출 검사"로
  좁힐지는 별건 판단.
- CONTRACT 가 또 늘어 `minimal` 투영이 커진다. 4개 원칙은 짧게 쓰고 근거는
  전부 GUIDANCE 로 보낸다. 재측정 비율을 CHANGELOG 에 보고한다.
- 원칙이 실제로 지켜지는지는 검증 수단이 없다 — 프로토콜에 문장이 존재하는
  것까지만 기계 검증된다. `path delta` 와 같은 한계다.
