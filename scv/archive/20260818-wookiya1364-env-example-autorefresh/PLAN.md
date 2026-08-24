---
title: .env.example.scv 자동 최신화 — root 불가침의 명명된 예외
slug: 20260818-wookiya1364-env-example-autorefresh
author: wookiya1364
created_at: 2026-08-18
status: obsolete
obsoleted_at: 2026-08-24
obsoleted_by: 20260824-wookiya1364-regression-contract-repair-2
kind: feature
lang: korean
tags: [sync, autosync, env, migration]
raw_sources:
  - scv/raw/stale/20260818-wookiya1364-env-example-sync.md
refs: []
invariants:
  - ".env 자체는 절대 불가침 — sync 는 어떤 경우에도 읽기만 하고 쓰지 않는다"
  - "HEAD 복원 불가 내용은 DIRTY 거부 — --force 만 오버라이드, 새 백업 메커니즘 금지"
  - "root 의 다른 파일은 계속 불가침 — 예외는 .env.example.scv 단 하나"
  - "미채택·pre-2.x 프로젝트는 autosync 가 손대지 않는다 — 기존 게이트 유지"
---

# .env.example.scv 자동 최신화 — root 불가침의 명명된 예외

## Summary

sync 가 프로젝트 루트의 `.env.example.scv` 를 항상 최신 템플릿으로 갱신한다.
지금은 "root 는 user-owned" 원칙 때문에 이 파일이 sync 의 손 밖에 있어서, 옛날에
hydrate 한 프로젝트는 SCV_EFFORT_MODE 같은 새 옵션의 문서 블록을 영영 못 받는다.
이 파일을 hydrate 가 심은 SCV 소유 파일로 재분류해 단 하나의 명명된 예외로 만들고,
autosync 를 타고 기존 프로젝트에 자동 전파한다. 별도 마이그레이션 명령은 없다.

## Goals / Non-Goals

- **Goals**
  - `/scv:sync` 가 `.env.example.scv` 를 최신 템플릿으로 갱신한다 (없으면 재생성).
  - scv_autosync 경유로 기존 프로젝트가 다음 액션 시작 시 자동으로 받는다.
  - 사용자 수정으로 HEAD 복원이 불가능한 내용은 기존 장치대로 DIRTY 거부한다.
- **Non-Goals**
  - `.env` 병합·마이그레이션 (예시 파일만 다룬다 — `.env` 는 읽기 전용 불가침).
  - `.gitignore.fragment` 등 다른 루트 파일로의 예외 확대.
  - 새 백업·스냅샷 메커니즘 (git 이력이 유일한 복구 경로라는 기존 결정 유지).

## Approach Overview

sync.sh 의 템플릿 패스에 루트 `.env.example.scv` 단계를 추가한다. 소스는
`core/template/.env.example.scv`, 대상은 프로젝트 루트. 기존 파일과 내용이 같으면
무동작, 다르면 HEAD 대조를 거쳐 교체한다 — git 이 복원 못 하는 내용이면 DIRTY 로
이름을 대고 거부하고, `--force <rel_path>` 만 오버라이드한다. 파일이 없으면 최신
템플릿으로 재생성한다. `scv/` 가 심볼링크면 기존 규칙대로 템플릿 패스 전체와 함께
건너뛴다(WARN 하나). 거부가 있으면 TEMPLATE_VERSION 스탬프는 전진하지 않고
PARTIAL 로 보고되어 다음 액션마다 재시도된다 — 기존 스탬프 규칙에 예외를 만들지
않는다. sync.sh 헤더의 소유권 주석("root is user-owned and never touched")을
명명된 예외 한 줄과 함께 개정한다.

## Guardrails

- `.env` 는 어떤 경로로도 쓰지 않는다 — 이 계획의 어느 단계에도 `.env` 쓰기가 없다.
- 예외는 `.env.example.scv` 하나다. 루트의 다른 파일(`.gitignore.fragment` 포함)을
  건드리는 코드를 추가하지 않는다.
- 0.28.0 의 HEAD 대조·DIRTY 거부·`--force` 장치를 그대로 재사용한다. 이 파일만을
  위한 별도 거부 로직·백업 디렉토리·스냅샷을 새로 만들지 않는다.
- `scv/` 심볼링크 스킵 규칙에 예외를 만들지 않는다 — 루트 파일이라는 이유로
  스킵 밖에서 따로 갱신하지 않는다.
- 거부 시 스탬프 미전진(PARTIAL 재시도) 규칙을 바꾸지 않는다 — 이 파일 하나를
  위해 스탬프를 예외 전진시키지 않는다.
- scv_autosync 의 기존 게이트(미채택 프로젝트 제외, pre-2.x 레거시 제외, 하향
  금지, 실패 비차단)를 유지한다.

## Exit criteria

- All TESTS.md scenarios pass
- 0.29.0 이전 TEMPLATE_VERSION 스탬프를 가진 픽스처 프로젝트가 액션 시작
  (autosync 경유) 한 번으로 최신 `.env.example.scv` 를 받는다 — 별도 명령 없이.
- 기존 `core/tests/test-sync-dirty.sh` 와 `core/tests/test-autosync.sh` 가
  무수정으로 계속 통과한다.

## Suggested path

1. `core/scripts/sync.sh` — 템플릿 패스에 루트 `.env.example.scv` 단계 추가
   (HEAD 대조·DIRTY 거부·`--force`·부재 시 재생성·심볼링크 스킵 공유).
2. `core/scripts/sync.sh` 헤더 주석 — 소유권 문구를 명명된 예외 포함으로 개정.
3. `core/tests/test-sync-env-example.sh` — TESTS.md 시나리오를 덮는 신규 스위트.
4. `TEMPLATE_VERSION` 범프 (2.1.0 → 2.2.0) — autosync 전파 트리거.
5. 전체 스위트 실행 + 기존 sync·autosync 스위트 회귀 확인.

## Related Documents

## Risks / Open Questions

- 팀이 `.env.example.scv` 를 커스텀해 커밋한 프로젝트는 다음 sync 에서 덮어써진다.
  git 이력으로 복구 가능하지만, 커스텀을 계속 유지하려면 매번 `--force` 없이는
  DIRTY 가 아니므로 조용히 교체된다 — 릴리스 노트에 한 줄 고지가 필요하다.
- 래퍼(materialized template) 경로에서 이 단계가 동일하게 동작하는지는 래퍼측
  벤더링 후 확인이 필요하다 (계약 변경은 아니므로 자동 벤더링 예상).

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
