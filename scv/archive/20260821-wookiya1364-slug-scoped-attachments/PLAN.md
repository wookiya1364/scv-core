---
title: "PR·보고 첨부는 이번 슬러그 것만 — SCV_ATTACHMENTS_SCOPE (기본 slug)"
slug: 20260821-wookiya1364-slug-scoped-attachments
author: "wookiya1364"
created_at: 2026-08-21
status: obsolete
obsoleted_at: 2026-08-24
obsoleted_by: 20260824-wookiya1364-regression-contract-repair-2
kind: feature
lang: korean
tags: [attachments, pr, report, playwright]
raw_sources:
  - scv/raw/stale/20260821-wookiya1364-slug-scoped-attachments.md
refs: []
supersedes: []
scope:
  - "core/scripts/pr-helper.sh"
  - "core/scripts/report.sh"
  - "core/scripts/collect-artifacts.sh"
  - "core/scripts/lib/attachment-scope.sh"
  - "core/protocols/work.md"
  - "core/protocols/report.md"
  - "core/template/.env.example.scv"
  - "core/tests/**"
  - "CHANGELOG.md"
invariants:
  - "SCV_ATTACHMENTS_SCOPE=all 이면 지금 동작 그대로 (test-results 전부)"
  - "슬러그 판정은 test-results 아래 상대 경로에 슬러그 문자열이 포함되는지로만 한다"
  - "재실행은 그 계획(archive)의 '## How to run' 블록을 한 번만 — 두 번 돌리지 않는다"
  - "동영상 보관·삭제(orphan 브랜치·retention) 정책과 업로드 경로는 불변"
  - "core/actions.json·액션 15개 불변"
---

# PR·보고 첨부는 이번 슬러그 것만

## Summary

PR 과 Slack/Discord 보고에 붙는 영상·스크린샷이 "이번에 만든 기능"이 아니라
테스트 결과 폴더에 남아 있는 **마지막 실행** 전체다. archive 직전에 누적 회귀를
돌리면 마지막 실행 = 남의 기능 영상이 되어 그대로 올라간다(실측: PR 헬퍼는
`test-results/` 의 .webm/.mp4/.png 를 전부 찾고, 보고는 가장 최근 파일 하나를
집는다). 기본을 **이번 슬러그의 것만** 으로 바꾸고, 전부 붙이고 싶은 팀만 `.env`
로 옛 방식을 켠다.

## Goals / Non-Goals

- **Goals**
  1. `.env` `SCV_ATTACHMENTS_SCOPE=slug|all`, 기본 `slug`. 영상·스크린샷 둘 다 같은 기준.
  2. **PR 헬퍼**: 슬러그 범위에서 test-results 파일을 경로에 슬러그가 포함된 것만
     모은다. 0건이면 그 계획(archive)의 `## How to run` 을 **한 번** 재실행해 이번
     영상을 만든 뒤 다시 모은다; 그래도 0건이면 한 줄 알리고 첨부 없이 진행.
     `--no-rerun` 로 재실행을 끌 수 있다.
  3. **보고(report)**: `--slug <slug>` 옵션. 없으면 슬러그 범위에서 "진행 중 계획이
     딱 하나(scv/promote/*/PLAN.md 가 1개)"면 그 슬러그, 아니면 전부(옛 동작) + 한 줄
     알림. collect-artifacts 는 슬러그 범위일 때 슬러그 파일 중 최신 하나를 고른다.
  4. 공통 로직은 `core/scripts/lib/attachment-scope.sh` 한 곳: 모드 읽기(환경변수
     → `.env`), 경로 필터, 슬러그 추론.
  5. 프로토콜·템플릿: work.md Step 9d 와 report.md 에 한 단락, `.env.example.scv`
     블록, CHANGELOG. 회귀 가드 `core/tests/test-attachments-scope.sh`.

- **Non-Goals**
  - Playwright 출력 폴더 이름 규약 변경, 동영상 업로드 백엔드·보관 정책 변경
  - 슬러그 외 기준(테스트 제목·시간 창)으로 고르기
  - 래퍼 변경(계약 불변 → 자동 벤더링)

## Approach Overview

**슬러그 판정.** per-slug E2E spec 규약(`<testDir>/<FOLDER_NAME>.spec.ts`, v0.16.0+)
덕에 Playwright 의 출력 폴더 이름이 `<FOLDER_NAME>-<title>-<project>/` 로 시작하므로,
`test-results/` 아래 상대 경로에 슬러그 문자열이 포함되면 이번 것이다. 규약을 안 쓰는
프로젝트는 0건 → 재실행 경로가 보완한다.

**모드 읽기.** `SCV_ATTACHMENTS_SCOPE` 환경변수 → 없으면 cwd `.env` 에서 한 줄 sed
(`source` 금지) → 없으면 `slug`. 값은 소문자 비교, `all` 만 옛 동작, 그 밖은 `slug`.

**PR 헬퍼 재실행.** regression.sh 의 `read_test_command` 와 같은 방식으로 archive
TESTS.md 의 `## How to run` 첫 펜스 블록을 뽑아 `bash -c` 로 한 번 실행(타임아웃
`SCV_ATTACHMENTS_RERUN_TIMEOUT`, 기본 600초). 실패해도 PR 은 계속(알림 한 줄).
`--dry-run` 에서는 재실행하지 않고 모은 파일 목록만 `ATTACHMENTS_SCOPE:` /
`ATTACHMENTS_FILES:` 줄로 찍는다(테스트가 이 줄을 본다).

**보고.** report.sh 가 `--slug` 를 받아 `SCV_ATTACHMENTS_SLUG` 로 collect-artifacts
에 넘긴다. collect-artifacts 는 모드가 slug 이고 슬러그가 있으면 경로 필터를 건 뒤
최신 하나를 고른다; 슬러그가 없으면 lib 의 추론(진행 중 계획 1개)을 쓰고, 그래도
없으면 전부(옛 동작) + stderr 한 줄.

## Guardrails

- `all` 모드의 출력은 지금과 바이트 동일(필터 없음, 알림 없음).
- 재실행은 한 번, 타임아웃 있음, 실패해도 PR 생성은 막지 않는다.
- 업로드 백엔드·orphan 브랜치·retention·manifest 형식은 손대지 않는다.
- `.env` 를 `source` 하지 않는다. 호스트 이름 금지. git 상태 단언 금지.
- 액션 카탈로그 불변.

## Exit criteria

- TESTS How-to-run exit 0.
- 실제 사용 확인(수동, 래퍼 배포 후): 회귀 → PR 흐름에서 PR 본문의 영상이 이번
  슬러그 것뿐.
- CHANGELOG + work.md/report.md 한 단락 + `.env.example.scv`.
- 0.32.0 릴리스 → 래퍼 두 곳 핀·릴리스(0.32.0 / 0.32.0-codex.1).

## Suggested path

1. `lib/attachment-scope.sh` (모드·필터·추론) + 단위 테스트.
2. pr-helper.sh 수집 지점에 필터 + 재실행 + dry-run 출력 줄.
3. report.sh `--slug` + collect-artifacts 필터/추론.
4. 프로토콜·템플릿·CHANGELOG. 5. 스위트 → archive → PR → 0.32.0.

## Related Documents

- 원재료: `scv/raw/20260821-wookiya1364-slug-scoped-attachments.md`
- 선행 규약: per-slug E2E spec (`core/protocols/promote.md` Step 5)

## Risks / Open Questions

- 슬러그 문자열이 다른 파일 경로에 우연히 포함될 가능성은 낮다(날짜+작성자+슬러그).
- 재실행이 Playwright 가 아닌 프로젝트에선 영상을 만들지 못한다 — 그땐 0건 알림으로
  끝난다(옛 동작처럼 남의 영상을 붙이지는 않는다).
- 보고의 "진행 중 계획 1개" 추론은 편의일 뿐 — 여럿이면 전부+알림으로 안전하게 떨어진다.

## Links

- Raw originals: (frontmatter 참조)
- Related PRs:
