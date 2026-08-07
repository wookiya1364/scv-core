---
title: "adoption 단일화 + 표준 문서 7종 제거 (신규 미생성 · sync 삭제)"
slug: 20260807-wookiya1364-adoption-only-doc-removal
author: "wookiya1364"
created_at: 2026-08-07
status: planned
kind: refactor
lang: ko
epic: 20260807-scv-simplification
tags: [hydrate, sync, intake, ablation, simplification, breaking]
raw_sources: []
refs: []
supersedes: []
invariants:
  - "hydrate 유지 파일(SCV.md, PROMOTE.md, REPORTING.md, raw/README.md, WORKSPACE.yaml.example, .env/.gitignore fragment)은 동작 불변"
  - "sync 의 삭제는 반드시 .scv-backup/ 백업 후에만 실행된다 (복구 가능) — 백업 실패 시 삭제 중단 (fail-closed)"
  - "PROJECT:LOCAL 마커 등 사용자 소유 영역 보존 규칙은 그대로"
  - "상태 인덱스 계약(SCV.md, HOST-POINTER, legacy CLAUDE.md/CODEX.md 마이그레이션)은 건드리지 않는다"
---

# adoption 단일화 + 표준 문서 7종 제거

## Summary (what & why)

greenfield(`--new`) 모드와 표준 문서 스캐폴딩을 함께 제거한다. 대상 7종:
`DOMAIN.md` `ARCHITECTURE.md` `DESIGN.md` `AGENTS.md` `TESTING.md`
`INTAKE.md` `RALPH_PROMPT.md`.

근거: (1) 이 문서들은 모델이 코드베이스에서 직접 도출 가능한 사실의 선제
스냅샷이라 존재 가치를 증명한 적이 없고(어블레이션 논리), (2) adoption 이
7종 전부를 `N/A`로 두는 걸 정상 상태로 규정한 순간 "없이 도는 게 기본"임을
SCV 스스로 자인했으며, (3) 스냅샷 문서는 갱신 시 과거 결정을 덮어쓴다 —
보존 가치가 있는 내용(결정)의 올바른 집은 team-journal 계획의
`DECISIONS.md`/journal 이다. INTAKE 는 채울 대상이 사라지므로 함께 제거하고,
RALPH_PROMPT 는 사용자 결정에 따라 기본 시딩에서 완전 제거한다.

## Goals

1. **hydrate**: `--new` 플래그 제거(전달 시 마이그레이션 안내와 함께 exit 1,
   파일 무변경 — fail-closed). 시딩 목록에서 7종 제거. draft/N/A 시딩 분기
   전체 삭제 → hydrate 가 단일 경로가 된다.
2. **sync 삭제 전파** (사용자 결정): 기존 프로젝트에서 sync 실행 시 위 7종이
   존재하면 **`.scv-backup/` 에 백업 후 삭제**하고 `CHANGES` 에
   `DELETED <file> (backed up)` 로 보고한다. 삭제 전 프로토콜(sync.md)이
   host agent 에게 지시: 각 파일에 실질 내용(템플릿 원문과 다른 사용자 작성
   내용)이 있으면 삭제 요약과 함께 "보존할 결정은 DECISIONS.md 로 이관"을
   제안한다 (team-journal 이 같은 릴리스 웨이브에 포함되는 이유).
3. **연쇄 정리** (조사 단계에서 전수 확정, 최소 다음 포함):
   - `check-frontmatter.sh` — STANDARD_DOCS 배열/검사 제거
   - `help.sh`/`help.md` — draft 게이트 진단, INTAKE 권장 흐름, Mode A [2] 제거
   - `promote.md`/`work.md`/`status.md` — INTAKE·표준 문서 참조 제거
   - `SCV.md` 템플릿 — 디렉터리 트리·"Work procedure"의 INTAKE 단계·문서
     안내 표 제거
   - `hydrate.sh`/`sync.sh`/`render-template.sh` 및 테스트 픽스처
   - rloop/Ralph 관련: core 내 RALPH_PROMPT 참조 전수 조사 후 제거 또는
     "사용자가 자유 형식으로 직접 만들 수 있다" 수준의 안내로 대체
4. **버전**: 템플릿 스키마 변경이므로 `TEMPLATE_VERSION` 2.0.0,
   Core `VERSION` 0.22.0 (다른 웨이브 계획들과 동시 릴리스), CHANGELOG 에
   breaking 명시 + 업그레이드 안내(백업 위치 포함).

## Non-Goals

- SCV.md/PROMOTE.md/REPORTING.md/raw/README.md 변경 (유지 파일)
- 상태 인덱스·legacy 마이그레이션 로직 변경
- DECISIONS.md/journal 자체 구현 (team-journal 계획 소관)

## Approach Overview

hydrate 는 삭제만 하면 되므로 단순하다. 핵심 난이도는 sync 의 삭제 전파다:
sync 는 지금까지 추가·병합만 했고 삭제 개념이 없다. `DELETED` 변경 유형을
새로 도입하되 기존 backup_file 인프라를 재사용해 원자적으로(백업 성공 →
삭제) 처리하고, `--dry-run` 은 삭제 예정 목록만 출력한다. REPORTING/TESTING
참조처럼 스크립트가 실제로 읽는 파일이 있는지 조사 단계에서 전수 확인한다
(REPORTING.md 는 report 가 읽으므로 유지 목록에 있음 — TESTING.md 를 읽는
스크립트가 발견되면 계획 개정).

## Steps

1. 조사: 7종 파일명이 등장하는 모든 코드·프로토콜·테스트 전수 목록화
2. hydrate 단순화 + `--new` 에러 처리
3. sync `DELETED`(백업 후 삭제) + dry-run + 프로토콜의 이관 제안 지시
4. 연쇄 정리 (Goals 3 목록)
5. run-dry/테스트 갱신 + 신규 회귀(7종 미생성·sync 삭제·백업 복구·--new 거부)
6. TEMPLATE_VERSION/VERSION/CHANGELOG/README 계약 표

## Risks / Open Questions

- **데이터 손실**: 사용자가 실제 내용을 채운 문서 삭제 → 백업 필수 +
  CHANGES 보고 + 이관 제안으로 완화. 백업 실패 시 삭제 중단.
- 구버전 wrapper 와 신버전 프로젝트 혼용: 구 help 가 INTAKE 를 권할 수 있음
  → 두 wrapper 동시 릴리스로 완화 (0.21.0 과 동일한 주의).
- rloop 등 외부 스킬이 RALPH_PROMPT.md 를 기대할 수 있음 → 릴리스 노트에
  명시.
