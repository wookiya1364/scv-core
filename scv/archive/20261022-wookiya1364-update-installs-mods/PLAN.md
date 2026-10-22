---
title: SCV 모드 명령 셋 — 인자 없이 업데이트 · 설치 · 삭제
slug: 20261022-wookiya1364-update-installs-mods
author: wookiya1364
created_at: 2026-10-22
status: testing
kind: feature
lang: korean
tags: [mods, claude-code-wrapper]
raw_sources:
  - scv/conversations/20261022-165947-scv-mods-install-command.md
refs:
  - type: link
    url: https://github.com/wookiya1364/scv-mods
invariants:
  - "업데이트 명령(/scv:update)은 지금과 같은 SCV 버전 진단을 그대로 낸다"
  - "프로젝트 파일(scv/ 등)은 바꾸지 않는다 — 플러그인 설치 목록만 바뀐다"
---

# SCV 모드 명령 셋 — 인자 없이 업데이트 · 설치 · 삭제

## Summary

scv-mods(예: scv-hello 대시보드 칸)를 쓰려면 지금은 마켓 추가 · 설치 · 업데이트 명령 두 줄 · 비공개 저장소 인증 · 다시 불러오기를
사람이 기억해야 한다. 인자 없는 명령 셋으로 대신한다: `/scv:mods`(설치된 모드 전부 업데이트 + 목록), `/scv:mods-install` ·
`/scv:mods-remove`(선택 창에서 하나 고름). 사용자 결정(2026-10-22): 처음 안(업데이트 명령에 `mods …` 인자)은 명령이 길고 인자가
불편해 버림.

## Goals / Non-Goals

- **Goals**
  - 코어 명령 목록에 래퍼 몫 명령 셋(mods · mods-install · mods-remove, 명령 19개)과 규약 `protocols/mods*.md`.
  - Claude 래퍼: 세 스킬 + 엔진 `scripts/mods.sh`. 마켓이 없으면 먼저 추가, 전후 버전, 인증 실패 시 할 일, 바뀐 것이 있을 때만
    다시 불러오기 안내. 설치 · 삭제는 선택 창에서 고르는 것이 확인.
  - Codex 래퍼: 같은 이름 세 스킬 — 'Codex 에는 모드가 없음' 한 줄.
  - 마켓 주소는 설정(`SCV_MODS_MARKETPLACE`, 기본 `wookiya1364/scv-mods`)으로 바꿀 수 있다.
- **Non-Goals**
  - 업데이트 명령은 바꾸지 않는다.
  - 모드 자체(scv-mods 저장소)는 바꾸지 않는다.
  - 다시 불러오기를 대신 실행하지 않는다(슬래시 명령이라 셸에서 못 함).

## Approach Overview

코어는 명령 목록 · 규약 · 가드 receipt 목록 · 검사 수만 맞춘다(실행 파일 없음, 업데이트 · 모델 정책과 같은 래퍼 몫).
Claude 래퍼의 엔진은 Claude Code CLI(`claude plugin marketplace add/update`, `install/update/uninstall`, `list --json [--available]`)로만
바꾸고, 결과를 키:값 줄(`RESULT: scv-hello updated 745b604 -> 9a1c2d3`)로 내며 스킬이 쉬운 말로 옮긴다. 새 명령이라 두 동기화
봇이 멈추므로, 0.69.0 때처럼 래퍼 몫을 먼저 커밋하고 손으로 동기화한다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  parseModsRequest,     // (인자들) → { op: list|install|update|remove, mod?, marketplace }
  planModsOps,          // ({요청, 설치 목록 JSON, 마켓 목록 JSON}) → 실행할 CLI 단계 목록
  runModsOps,           // (단계 목록) → 단계별 결과(종료 코드 · 출력)   ← 부수효과
  summarizeModsResult,  // ({요청, 전 목록, 후 목록, 결과}) → 보고 줄들(전후 버전 · 할 일)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 | 하는 일 |
|---|---|---|---|---|
| 1 | readPluginState | (없음) → 설치 목록 · 마켓 목록 JSON | 부수효과 (입구) | 지금 깔린 모드와 마켓을 읽는다 |
| 2 | parseModsRequest | 인자 → 요청 | 순수 | 무엇을 하려는지 정한다 |
| 3 | planModsOps | 요청 + 상태 → 단계 목록 | 순수 | 마켓이 없으면 추가부터, 설치됐으면 업데이트로 바꾸는 등 할 일을 고른다 |
| 4 | runModsOps | 단계 목록 → 결과 | 부수효과 (출구) | Claude Code CLI 를 차례로 돌린다 |
| 6 | printList | 상태 → MOD: 줄 | 부수효과 (입구, 설치 가능 목록 읽기) | /scv:mods 끝과 mods-remove 보기에 목록을 낸다 |
| 5 | summarizeModsResult | 전후 상태 + 결과 → 보고 줄 | 순수 | 전후 버전과, 실패면 원인별 할 일(인증 등)을 적는다 |

- 부수효과 위치: 1(읽기)과 4(CLI 실행)만. 2 · 3 · 5 는 입력만 보고 같은 출력을 낸다 — 가짜 JSON 으로 시험한다.
- 재사용: 업데이트 명령의 진단은 그대로 두고, 같은 엔진을 세 스킬이 나눠 쓴다(인자 없음 = 업데이트+목록, candidates · list = 보기).

## Guardrails

- 업데이트 명령 출력은 한 글자도 다르지 않다(기존 시험 · 기존 사용자 보호).
- 설치 · 삭제는 선택 창에서 고른 뒤에만 한다(고르는 것이 확인). 업데이트 · 목록은 묻지 않는다.
- Claude Code CLI 로만 바꾼다 — `~/.claude/plugins` 파일을 직접 고치지 않는다.
- 인증 실패를 '설치됨'처럼 보고하지 않는다 — CLI 종료 코드와 설치 목록 재확인으로 판정한다.
- 비밀 값(토큰)을 읽거나 출력하지 않는다. 인증은 사용자가 직접 하도록 명령만 알려 준다.
- Mac + Linux, bash 3.2 에서 같은 결과.
- 다시 불러오기를 대신 실행하지 않는다.

## Exit criteria

- All TESTS.md scenarios pass
- 이 맥에서 실제로 `/scv:mods` 한 번으로 업데이트 + 목록이 나온다.
- 코어 0.70.0 · Claude 0.70.0 · Codex 0.70.0-codex.1 릴리스, 릴리스 노트에 사용법.

## Suggested path

1. 코어: actions.json 에 셋(래퍼 몫), 규약 셋, 가드 목록 · 명령 수 검사 · help 목록 · verify-core 19.
2. Claude 래퍼: 엔진 scripts/mods.sh(순수 단계 + 양 끝 CLI), 스킬 셋, 명령 목록 다섯 곳(검증 · 계약 시험 · 모델 정책 · CI 수 · 래퍼 몫 목록), README.
3. Codex 래퍼: 스킬 셋 + 규약 셋('모드 없음'), 검증 · 시험 목록 19, README.
4. 새 코어를 두 래퍼 사본에 넣어 미리 시험 → 코어 릴리스 → 봇 이름 브랜치로 손 동기화 → 래퍼 릴리스.

## Related Documents

- scv-mods README (설치 · 업데이트 절): https://github.com/wookiya1364/scv-mods

## Risks / Open Questions

- 다른 컴퓨터(리눅스)에서는 아직 실제로 돌려 보지 않았다 — 릴리스 뒤 그쪽에서 한 번 확인한다.
- Claude Code CLI 의 JSON 모양이 바뀌면 상태 읽기가 깨질 수 있다 — 읽기 실패 시 '알 수 없음'으로 보고하고 멈춘다.
- 새 명령 셋이라 두 동기화 봇이 멈춘다 — 0.69.0 때 절차(래퍼 몫 먼저 커밋 → 손 동기화)로 처리한다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
