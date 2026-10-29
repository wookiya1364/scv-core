---
title: claude 래퍼의 중복 DeckUI 없애기 — deck 이 코어 사본 안 엔진을 읽게
slug: 20261029-wookiya1364-drop-root-deckui
author: wookiya1364
created_at: 2026-10-29
status: testing
kind: refactor
lang: korean
tags: [wrapper, deck, cleanup]
raw_sources:
  - scv/conversations/20261022-165947-scv-mods-install-command.md
refs: []
invariants:
  - "설치한 claude 플러그인의 /scv:deck 이 같은 계획에서 바이트까지 같은 문서 HTML 을 만들고, --slides 도 만들어진다"
---

# claude 래퍼의 중복 DeckUI 없애기 — deck 이 코어 사본 안 엔진을 읽게

## Summary

claude 래퍼 저장소에는 deck 엔진(DeckUI)이 두 벌 있다 — 코어 사본 안(`vendor/scv-core/core/DeckUI`)과 저장소 맨 위(`DeckUI/`, 528K · 파일 44개, 내용 같음, 확인). 맨 위 것은 `scripts/project-core.sh` 가 옛 경로 호환용으로 만드는 투영본이고, claude 의 `/scv:deck` 이 지금 이것을 읽는다(`scripts/deck-runtime.sh` 의 `SOURCE_DECKUI="$CORE_DIR/DeckUI"`, CORE_DIR = 플러그인 루트, 확인).
codex 래퍼는 이미 코어 사본 안 한 벌만 쓴다(확인).
deck 이 코어 사본 안 엔진을 읽게 바꾸고, 맨 위 투영본과 그것을 위한 특별 취급(동기화 도구 · 시험 · CI 트리거 · 문서)을 걷어낸다. 사용자 요청: "굳이 있어야 해? 삭제해도 된다면 하고 싶은데"(2026-10-29).

## Goals / Non-Goals

- **Goals**
  - claude 래퍼 저장소 · 설치본에서 DeckUI 가 한 벌(코어 사본 안)만 남는다.
  - 설치한 claude 플러그인의 `/scv:deck` 이 지금과 같은 결과를 낸다 — 같은 계획에서 문서 HTML 이 바이트까지 같고, `--slides` 도 만들어진다.
  - 코어 · claude · codex 를 모두 릴리스한다(코어가 바뀌면 codex 도 같은 코어를 싣는다).
- **Non-Goals**
  - 다른 투영본(맨 위 `scripts/` · `template/` · `assets/`) 건드리기 — 사용자 결정으로 이번엔 DeckUI 만.
  - deck 의 출력 · 렌더러 자체를 바꾸기.
  - 예전 버전 런타임 캐시를 그대로 이어 쓰게 보장하기 — 업데이트 뒤 첫 deck 에서 렌더러를 한 번 다시 깔아도 된다(사용자 결정).

## Approach Overview

1. **엔진 위치를 래퍼가 정한다.** 코어의 deck 은 지금 "코어 루트 바로 아래 DeckUI" 만 안다. 래퍼 설정(host profile)이 코어 루트 기준 엔진 위치를 줄 수 있게 하고, 비어 있으면 지금과 같은 자리(코어 루트 아래)를 쓴다 — codex · 코어 자체는 동작이 그대로다. 이미 같은 방식으로 쓰는 키가 있다(`SCV_PROMPTING_GUIDES`: 래퍼마다 코어 루트 기준 상대 경로가 다름).
2. **claude 설정에 위치 한 줄.** claude 래퍼의 `adapter/claude-code.env` 에 코어 사본 안 엔진 위치를 적는다(루트 `host-profile.env` 는 동기화가 만드는 생성물이라 손대지 않는다 — 메모의 0.63.0 교훈).
3. **투영에서 DeckUI 를 뺀다.** `scripts/project-core.sh` 가 맨 위 `DeckUI/` 를 더 만들지 않게, 이미 있는 맨 위 사본은 지운다.
4. **특별 취급 정리.** `scripts/sync-core.sh`(DeckUI 언급 35곳) · `tests/test-sync-core-atomicity.sh`(59곳) · `.github/scripts/test-sync-core-smoke.sh` 에서 맨 위 DeckUI 전용 처리(무시 · 미추적 파일 예외 등)를 걷어내되, 코어 사본이 손대지 않은 그대로인지 보는 검사는 약해지지 않게.
5. **흔적 정리.** `core-contract.yml` 트리거의 `'DeckUI/**'`, `.gitattributes` 의 `DeckUI/**`, PR 양식의 `pnpm -C DeckUI`, 설계 문서(`docs/design/shared-core-wrapper.md`) · `adapter/README.md` 의 맨 위 DeckUI 설명.
6. **설치본으로 확인.** 바꾸기 전 설치본과 바꾼 설치본에서 같은 보관 계획으로 문서 deck 을 만들어 바이트 비교, `--slides` 도 한 번.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  resolveDeckSource,   // (코어 루트, 래퍼 설정) → 엔진 폴더 경로
  ensureRuntime,       // (엔진 폴더) → 런타임 폴더 (캐시 — 부수효과)
  buildDeck,           // (런타임 폴더, 계획 폴더) → deck HTML (파일 쓰기 — 부수효과)
)
flow(
  projectionPaths,     // (코어 사본) → 맨 위로 투영할 경로 목록 (DeckUI 없음)
  verifyProjection,    // (기대 목록, 실제 트리) → 일치 / 어긋난 경로
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | `resolveDeckSource` | 래퍼 설정에 엔진 위치가 있으면 그것, 없으면 코어 루트 아래 DeckUI | 코어 루트 · 설정 값 → 엔진 폴더 경로 | 순수 |
| 2 | `ensureRuntime` | 엔진 폴더로 렌더러 런타임 캐시를 준비(없거나 다르면 새로 깖) | 엔진 폴더 → 런타임 폴더 | 부수효과 (캐시 쓰기) |
| 3 | `buildDeck` | 계획 문서를 deck HTML 로 만든다(바뀌지 않음) | 런타임 · 계획 폴더 → HTML 파일 | 부수효과 (출구) |
| 4 | `projectionPaths` | 코어 사본에서 맨 위로 투영할 경로를 고른다 — DeckUI 는 빠짐 | 코어 사본 목록 → 투영 경로 목록 | 순수 |
| 5 | `verifyProjection` | 투영 · 코어 사본이 기대와 같은지 보고 어긋난 경로를 돌려준다 | 기대 목록 · 실제 트리 → 일치 / 어긋남 | 순수 |

- 부수효과 위치: 런타임 캐시 쓰기(2), deck HTML 쓰기(3), 동기화의 파일 쓰기 · 지우기(투영 실행).
- 재사용: 코어의 기존 `deck-runtime.sh` 캐시 로직(엔진 해시로 이름 짓기)과 `deck.sh` 변환은 그대로 쓴다.

## Guardrails

- 설치한 claude 플러그인의 `/scv:deck` 결과가 바뀌면 안 된다 — 같은 계획 → 같은 문서 HTML(바이트), `--slides` 만들어짐(invariant).
- codex 래퍼의 deck 동작이 바뀌면 안 된다 — 엔진 위치 설정이 비어 있으면 코어는 지금과 똑같이 동작한다.
- 코어 사본(`vendor/scv-core/**`)은 손으로 고치지 않는다 — 코어 변경은 코어 저장소에서, 래퍼에는 동기화로만.
- 루트 `host-profile.env` 는 생성물 — 손대지 않고 `adapter/claude-code.env` 만 고친 뒤 동기화로 만든다.
- 다른 투영본(`scripts/` · `template/` · `assets/`)은 그대로.
- 코어 사본이 손대지 않은 그대로인지 보는 동기화 검사는 약해지지 않는다.
- 맥 + 리눅스 · bash 3.2 에서 똑같이 돈다.
- 안전 검사(출처 · 개인정보 · 벤더 게이트)를 우회하지 않는다.

## Exit criteria

- All TESTS.md scenarios pass
- claude 래퍼 저장소에 맨 위 `DeckUI/` 가 없고, `git grep DeckUI` 의 남은 줄이 코어 사본 · 릴리스 기록 · 엔진 위치 설정뿐이다.
- 업데이트한 claude 설치본에서 보관 계획 하나로 만든 문서 deck 이 바꾸기 전 설치본의 것과 바이트까지 같고, `--slides` 가 만들어진다(실제 실행).
- 코어 · claude · codex 가 운영 릴리스까지 나간다.

## Suggested path

1. 바꾸기 전 설치본(claude 0.72.1)으로 보관 계획 하나의 문서 deck 을 만들어 기준 HTML 로 둔다 — 비교할 기준 결과를 남긴다
2. 코어: 래퍼 설정의 엔진 위치를 읽고, 비면 지금 자리 — `resolveDeckSource`
3. 코어 시험: 설정 있음 · 없음 · 잘못된 경로(밖으로 나가는 경로 · 없는 폴더) — 엔진 위치 판단을 검사한다
4. 코어 PR · 0.72.2(또는 다음 판) 버전 PR · codex 사본 코어 시험 · 코어 릴리스 — 코어를 먼저 낸다
5. claude 동기화 브랜치: 설정 한 줄, 투영에서 DeckUI 빼기, 맨 위 사본 지우기 — `projectionPaths`
6. claude 동기화 도구 · 시험 · CI 트리거 · 문서의 맨 위 DeckUI 처리 정리 — `verifyProjection`
7. claude 래퍼 시험 전부 + CI, 업데이트한 설치본에서 deck 문서 바이트 비교 · `--slides` — `ensureRuntime`, `buildDeck`
8. codex 동기화 · 릴리스, claude 릴리스 — 세 저장소 운영 릴리스를 마친다

## Related Documents

- 메모: 래퍼 릴리스 절차(scv-wrapper-repos-release-after-core)

## Risks / Open Questions

- deck 런타임 캐시 이름이 엔진 해시라 내용이 같으면 그대로 쓰일 수 있다(추정) — 다시 깔려도 된다는 결정이라 막히지 않는다.
- 동기화 도구의 DeckUI 특별 취급(무시 · 미추적 파일 예외)이 예전 설치본의 남은 `node_modules` · `dist-deck` 를 다루려던 것이라(추정), 걷어낸 뒤 예전 저장소 사본에서 동기화가 "모르는 파일" 로 멈출 수 있다 — 시험으로 확인한다.
- 이 컴퓨터에 설치된 claude 는 0.70.4 — 기준 HTML 을 만들려면 먼저 0.72.1 로 올려야 한다(설치본 업데이트는 사용자 동의 뒤).

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
