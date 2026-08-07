---
title: "전면 기록화 — 작성자 귀속 journal + DECISIONS + TODO + 호스트 훅"
slug: 20260804-wookiya1364-team-journal
author: "wookiya1364"
created_at: 2026-08-04
status: planned
kind: feature
lang: ko
epic: 20260807-scv-simplification
tags: [journal, decisions, todo, hooks, attribution, context-persistence]
raw_sources: []
refs: []
invariants:
  - "모든 기록 항목은 작성자(author)가 귀속된다 — 익명 항목 금지"
  - "journal/DECISIONS/TODO 는 append-only — 기존 항목 수정·삭제 금지"
  - "비밀번호·토큰 패턴은 기록 전에 마스킹된다 (redaction 필터 통과 없이 저장 금지)"
  - "훅 등록은 wrapper 소유 — Core 는 스크립트 템플릿과 계약만 제공 (update/set-models 와 같은 경계)"
---

# 전면 기록화 — 작성자 귀속 journal + DECISIONS + TODO + 호스트 훅

## Summary (what & why)

SCV 는 feature 단위 검증(promote→work→archive→regression)은 완결적이지만,
프로젝트 수준 맥락은 남지 않는다: 단일 리포에 결정 전용 기록이 없고
(scv/decisions/ 는 멀티리포 root 전용), 결정에 이르는 대화는 gitignore 된
`.conversations/` 로컬에서 소실되며, 할일은 세션과 함께 사라진다. 여러 명이
의견을 낼 때 누가 낸 것인지도 남지 않는다. 이 계획은 **모든 대화·결정·할일을
작성자 귀속으로 커밋되는 문서에 축적**해, 누구든 작업을 이어받아도 맥락이
유지되게 한다. 방식은 하이브리드: 대화 원문은 journal 에, 결정·할일은
구조화된 DECISIONS/TODO 에.

## Goals

1. **템플릿 3종 추가** (전부 `merge_policy: preserve`, sync 로 기존
   프로젝트에 NEW 자동 전파):
   - `scv/journal/` + `scv/journal/README.md` — 사용 규약
   - `scv/DECISIONS.md` — append-only 결정 로그. 엔트리 스키마는 handoff
     decision 포맷 재사용 + author 필수:
     `## [YYYY-MM-DD HH:MM] <author> — <제목>` / verdict / why / refs / conversation 링크
   - `scv/TODO.md` — 팀 공유 할일. 항목마다 `- [ ] (T-NNN) <내용> — @<author>, YYYY-MM-DD`
2. **author 해석 헬퍼** — `core/scripts/lib/author.sh`:
   `git config user.name` → `$GIT_AUTHOR_NAME` → `$USER` 순 폴백, 파일명용
   슬러그화 함수 포함. promote-helper 의 AUTHOR 시그널도 이 헬퍼로 통일.
3. **journal append 스크립트** — `core/scripts/journal-append.sh`:
   stdin 또는 인자로 받은 턴을 `scv/journal/<YYYYMMDD>-<author>.md` 에
   `### [HH:MM:SS] <speaker>` 블록으로 append. **redaction 필터 내장**
   (password/token/secret/api[_-]?key/Bearer/AKIA… 패턴 → `[REDACTED]`).
   사용자별 파일 분리 = 다인 동시 작업에서 git 충돌 원천 차단.
4. **호스트 훅 템플릿** — `core/template/hooks/`:
   - `on-user-prompt.sh` — Claude Code `UserPromptSubmit` 훅 계약(stdin
     JSON)에서 prompt 를 추출해 journal-append 호출. 자유대화(action:*
     없이 말하는 내용)까지 전부 기록되는 핵심 경로.
   - `on-stop.sh` — `Stop` 훅에서 transcript 경로를 받아 어시스턴트 응답
     요약을 journal 에 append.
   - 등록(설치)은 호스트 종속 → **wrapper 소유**. `docs/wrapper-integration.md`
     에 훅 seam 계약 추가, scv-claude-code / scv-codex 로 handoff 발행.
5. **결정 기록 지점 3곳** 프로토콜 추가 — DECISIONS.md append (author 포함):
   - `promote.md`: 계획 승인 시 — 채택 방향 + **버린 대안**
   - `work.md`: archive 시 — reason 을 한 줄 완료가 아닌 결정 요약으로 승격
   - `regression.md`: obsolete 판정 시 — 왜 폐기인지 (triage 소실 문제 해소)
6. **대화 영속화** — `.gitignore.fragment` 에서 `/scv/.conversations/` 제거,
   경로를 커밋되는 `scv/conversations/` 로 전환. help.md 의 대화 저장이
   redaction 필터를 거쳐 이 경로에 쓰도록 변경. 기존 로컬 `.conversations/`
   마이그레이션 안내(help 가 감지 시 이동 제안).
7. **status 노출** — `action:status` 에 최근 결정 N건·미완료 TODO(작성자별)
   섹션 추가.

## Non-Goals

- CLAUDE.md/AGENTS.md 등 벤더 표준 파일 관리 (SCV.md:137-142 금지 원칙 유지)
- lessons 류를 표준 문서 8종째로 추가 (교훈은 DECISIONS 엔트리 타입으로 흡수)
- graphify 산출물의 정본화
- 훅의 wrapper 측 등록 구현 (본 계획은 Core 쪽 스크립트·계약·handoff 까지)

## Approach Overview

새 action 은 추가하지 않는다 — 기존 액션(help/promote/work/regression/status)
의 프로토콜에 기록 지점을 삽입하고, 실제 쓰기는 Core 스크립트 2개
(journal-append.sh, 결정 append 는 프로토콜이 파일 규약대로 직접 작성)가
담당한다. 따라서 wrapper seam 변경은 훅 계약 문서화뿐이고, 나머지는 Core
단독 + 재벤더링이다. sync 는 top-level `scv/*.md` 를 이미 전파하므로
DECISIONS/TODO 는 무수정 전파되고, journal/README.md 는 raw/README.md 와
같은 방식의 명시 라인 1개를 추가한다.

## Implementation Steps

1. lib/author.sh + 단위 테스트
2. journal-append.sh (redaction 포함) + 단위 테스트
3. 템플릿 3종 + hydrate 반영 + sync 전파 라인
4. gitignore fragment 전환 + help.md 대화 경로 변경 + 마이그레이션 안내
5. 프로토콜 기록 지점 3곳 (promote/work/regression) + status 노출
6. hooks 템플릿 2종 + wrapper-integration.md 훅 seam 계약
7. run-dry 확장 + 신규 테스트 파일 + CHANGELOG/VERSION (0.22.0, adoption-only 와 동시 릴리스)
8. scv-claude-code / scv-codex 훅 등록 handoff 발행

## Sequencing (epic 내 순서 의존)

- **doc-removal 계획과 같은 릴리스 웨이브(0.22.0)에 포함되어야 한다**:
  sync 가 표준 문서 7종을 삭제할 때 "보존할 결정을 DECISIONS.md 로 이관"을
  제안하려면 DECISIONS.md 가 같은 웨이브에 존재해야 한다. 이 계획이
  빠지면 doc-removal 의 이관 제안은 백업 안내로 대체된다.
- routines 계획의 실행 보고는 이 계획의 journal 규약을 따른다 (역의존은
  없음 — journal 없이도 routines 는 report 로 동작).

## Risks / Open Questions

- **비밀 유출**: redaction 은 휴리스틱 — 패턴 밖 비밀은 남을 수 있음.
  journal/README 에 금지사항 명시 + raw 와 동일한 "비밀 커밋 금지" 규약 병행.
- **journal 비대**: 일 단위·사용자 단위 분할로 파일당 크기 제한. 장기적으로
  월 단위 아카이빙은 후속 계획.
- **훅 없는 호스트**: 훅 미등록 환경의 자유대화는 캡처 불가 — 세션 종료 시
  프로토콜(요약 기록)로 부분 보완, 격차는 문서에 명시.
- **TODO 동시 편집 충돌**: append-only + 항목 ID 규율로 완화하되, 충돌 시
  둘 다 보존(union merge) 안내를 README 에 명시.
- transcript 형식(Stop 훅)은 호스트 버전에 따라 변할 수 있음 — on-stop.sh 는
  실패 시 조용히 skip (기록 실패가 세션을 막으면 안 됨, non-blocking).
