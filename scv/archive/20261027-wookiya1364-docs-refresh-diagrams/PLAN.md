---
title: 코어 · 래퍼 · 모드 문서 최신화 — 빠진 기능 채우기 + 루프 · 구조 · 미러 그림
slug: 20261027-wookiya1364-docs-refresh-diagrams
author: wookiya1364
created_at: 2026-10-27
status: done
kind: feature
lang: korean
tags: [docs, readme, mermaid, remotion, mirror]
raw_sources:
  - scv/conversations/20261022-165947-scv-mods-install-command.md
refs: []
invariants:
  - "문서 · 그림 · 문서 검사만 바꾼다 — 스크립트 · 훅 · 명령 동작은 그대로"
  - "세 언어(영 · 한 · 일) README 는 같은 내용 · 같은 그림을 싣는다"
---

# 코어 · 래퍼 · 모드 문서 최신화 — 빠진 기능 채우기 + 루프 · 구조 · 미러 그림

## Summary

지금까지 만든 기능이 코어 · 두 래퍼(claude · codex) · 모드 문서 어디에 있는지 맞추고, 예전에 있던 그림을
되살린다. 구조와 흐름은 머메이드로 README 에 바로 그리고, 루프 · 구조 · 미러 사용법은 React(Remotion)
애니메이션 GIF 로 보여 준다. 사용자가 "문서가 최신이 아니고, 예전의 애니메이션 · 머메이드가 빠져 아쉽다"고
말했고(대화 Turn 64), 조사에서 그 말이 맞는 것을 확인했다.

조사에서 확인한 빈 곳(2026-10-27):

| 빈 곳 | 지금 (확인) |
|---|---|
| 코어 구조 문서 | 2026-09-21 이후 손대지 않음 — 드림 · 모드 · 채널 · 실체 보여 주기 · 요청 등록 · 판정자가 없음 |
| 실체 보여 주기 · Graft 안내 | 네 저장소 README 어디에도 없음 |
| codex README | 채널 한 줄뿐, 재개 요약(SCV_RESUME_RECAP) 없음 |
| 미러 | 모드 README 에 한 문단만 있고 그림 없음 |
| 그림 | claude README 의 GIF 3개(데모 · 루프 · 구조) 중 루프 · 구조 GIF 와 머메이드 2개가 2026-08-25 README 재작성 때 빠짐. GIF 파일과 Remotion 원본(`demo/`)은 저장소에 남아 있음 |
| 코어 · codex · 모드 README | 그림 없음 |
| 명령 20개 | 두 래퍼 README 표에는 다 있음(빈 곳 아님) |

## Goals / Non-Goals

- **Goals**
  - 기능마다 설명된 문서가 적어도 한 곳 있다: 명령 20개와 늘 켜진 기능(매 턴 자동 라우팅, 재개 요약, 실체 보여 주기, 요청 등록, 드림, 채널, 모드, 미러, 작업 보기의 '하는 일')이 코어 README · 구조 문서와 두 래퍼 README 에 들어간다.
  - 그림 세 장이 README 에 보인다: **루프**(raw → 계획 → 구현 → 보관 → 회귀), **구조**(코어 · 래퍼 · 모드 · 채널), **미러 사용법**(두 컴퓨터, 주소 확인 → 거울 켜기 → 끄기).
  - 각 그림은 머메이드(README 안)와 Remotion GIF 로 함께 있다. 머메이드는 글과 같이 고치기 쉽고, GIF 는 순서를 움직임으로 보여 준다.
  - 빠진 곳을 다시 잡는 문서 검사 하나: 기능 목록과 문서를 대조해 설명이 없는 기능을 이름으로 알려 준다.
- **Non-Goals**
  - 기능 동작 변경(스크립트 · 훅 · 명령).
  - 릴리스 노트 · CHANGELOG 다시 쓰기.
  - 새 문서 사이트(웹사이트) 만들기.

## Approach Overview

- **기능 목록 한 곳.** 코어 명령 목록(`core/actions.json`)에 늘 켜진 기능 몇 개를 더한 기능 목록을 한 곳에 둔다. 문서 검사와 README 의 '기능 한눈에' 표가 이 목록을 함께 쓴다.
- **문서 검사.** 기존 README 검사(`tools/check-readme.sh`, 두 래퍼 CI 가 이미 돌림)를 키운다. 기능 목록과 각 저장소 문서(코어 README 3개 언어 · 구조 문서, claude · codex README 3개 언어, 모드 README)를 대조해 빠진 기능을 이름으로 출력한다. 코어 테스트로 두고, 형제 저장소 경로를 받아 래퍼 · 모드까지 본다.
- **글 채우기.** 코어 구조 문서에 2026-09-21 이후 기능을 넣는다. codex README 에 채널 · 재개 요약을, 네 저장소 README 에 실체 보여 주기 · Graft 안내를 넣는다. 미러는 모드 README 에 '쓰는 법' 절로 넣는다.
- **머메이드.** 루프 · 구조 · 미러(두 컴퓨터 사이 순서도 — `sequenceDiagram`) 세 그림을 코어 · 두 래퍼 · 모드 README 에 맞는 것만 싣는다. 테마 지시문은 SCV 표준 어두운 테마를 쓴다.
- **Remotion GIF.** claude 래퍼의 `demo/` 에 있는 컴포지션(TheLoop · Architecture)을 지금 기능에 맞게 고치고, 미러 컴포지션을 하나 더 만든다. GIF 를 다시 뽑아 그것을 보여 줄 저장소에 넣는다(미러 GIF 는 모드 저장소).
- **세 언어.** 영 · 한 · 일 README 는 같은 절과 같은 그림을 싣는다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readSources,      // 저장소 경로들 → 기능 목록 원문 + 문서 원문들 (입구, 파일 읽기)
  listFeatures,     // 명령 목록 + 늘 켜진 기능 → 기능 이름 · 찾을 말 목록
  findMentions,     // 기능 목록 + 문서 원문 → 기능 × 문서 표(있음/없음)
  findGaps,         // 기능 × 문서 표 + 기능마다 요구 문서 → 빠진 칸 목록
  checkDiagrams,    // 문서 원문 → 그림 목록(머메이드 블록 · GIF 참조) + 빠진 그림
  formatReport,     // 빠진 칸 + 빠진 그림 → 출력 줄 + 종료 코드
  printReport,      // 출력 줄 → 화면 (출구)
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | `readSources` | 코어 · 래퍼 · 모드 저장소에서 기능 목록과 문서 파일을 읽어 온다 | 저장소 경로들 → 원문 묶음 | 부수효과 (입구) |
| 2 | `listFeatures` | 명령 20개와 늘 켜진 기능을 하나의 목록으로 만든다 | 원문 → 기능 목록 | 순수 |
| 3 | `findMentions` | 기능마다 어느 문서에 설명이 있는지 표로 만든다 | 기능 목록 + 문서 원문 → 기능 × 문서 표 | 순수 |
| 4 | `findGaps` | 있어야 할 문서에 설명이 없는 칸만 고른다 | 표 + 요구 문서 → 빠진 칸 | 순수 |
| 5 | `checkDiagrams` | 루프 · 구조 · 미러 그림이 머메이드와 GIF 로 있는지 본다 | 문서 원문 → 빠진 그림 | 순수 |
| 6 | `formatReport` | 빠진 것을 사람이 읽는 줄로 바꾸고 통과/실패를 정한다 | 빠진 칸 + 빠진 그림 → 줄 + 코드 | 순수 |
| 7 | `printReport` | 결과를 화면에 쓰고 그 코드로 끝낸다 | 줄 + 코드 → 출력 | 부수효과 (출구) |

- 부수효과 위치: `readSources`(파일 읽기)와 `printReport`(출력)만. 가운데 단계는 원문만 받아 같은 결과를 돌려준다.
- 재사용: 명령 목록은 코어 `core/actions.json` 을 그대로 읽는다. 머메이드 구문 검사는 DeckUI 의 정적 머메이드 검사(`core/tests/test-deck-static-mermaid.sh` 가 쓰는 것)를 먼저 살핀다.

## Guardrails

- 문서 · 그림 · 문서 검사 · Remotion 원본만 바꾼다. 스크립트 · 훅 · 명령 동작은 건드리지 않는다.
- 세 언어 README 는 같은 절 · 같은 그림을 싣는다. 한 언어만 고치지 않는다.
- 래퍼 안의 코어 사본(`vendor/`)은 손으로 고치지 않는다. 코어 릴리스 동기화로 들어간다.
- 머메이드는 SCV 표준 어두운 테마 지시문으로 시작한다.
- 그림에 없는 기능을 지어내지 않는다. 그림 속 명령 · 이름은 실제 명령 · 출력 문구와 같아야 한다(예: `/scv-mirror <주소>`, `/scv-mirror stop`).
- PR 은 develop 을 향한다. 래퍼 · 모드 PR 은 각 저장소 규칙(출처 게이트 제목 표시 등)을 따른다.
- 맥 + 리눅스, bash 3.2 에서 문서 검사가 똑같이 돈다.

## Exit criteria

- TESTS.md 의 모든 시나리오가 통과한다.
- 기능마다 설명된 문서가 적어도 한 곳 있고, 문서 검사가 빠진 것 0 으로 끝난다.
- 루프 · 구조 · 미러 그림이 머메이드와 GIF 로 README 에 보이고, GitHub 에서 렌더된다.
- 사용자가 미러 그림만 보고 다른 컴퓨터에서 거울을 켜고 끄는 순서를 따라 할 수 있다(사용자 확인).

## Suggested path

1. 기능 목록을 한 곳에 만들고 문서 검사를 붙여, 지금 빠진 것을 실제로 출력해 본다 — `readSources`, `listFeatures`, `findMentions`, `findGaps`, `formatReport`, `printReport`
2. 그림 검사를 붙인다 — `checkDiagrams`
3. 코어 README 3개 언어 · 구조 문서에 빠진 기능과 머메이드(루프 · 구조)를 넣는다 — 2026-09-21 이후 기능을 글과 그림으로 채운다
4. claude · codex README 3개 언어에 빠진 기능과 머메이드를 넣고, 루프 · 구조 GIF 를 다시 싣는다 — 래퍼 쪽 글과 그림을 채운다
5. Remotion 컴포지션을 지금 기능에 맞게 고치고 미러 컴포지션을 만들어 GIF 를 뽑는다 — 루프 · 구조 · 미러 애니메이션을 만든다
6. 모드 README 에 미러 '쓰는 법' 절(머메이드 순서도 + GIF)을 넣는다 — 미러 사용법을 그림으로 보여 준다
7. 문서 검사 · 기존 테스트를 돌리고, 그림을 사용자에게 보여 확인받는다 — 빠진 것 0 과 렌더 결과를 확인한다

## Related Documents

- `docs/architecture.md` — 코어 구조 문서(이번에 고칠 곳)
- `../scv-claude-code/demo/` — Remotion 원본(TheLoop · Architecture · ScvDemo)
- `../scv-mods/README.md` — 미러 설명(지금 한 문단)

## Risks / Open Questions

- GIF 는 기능이 바뀔 때마다 다시 뽑아야 한다. 머메이드를 함께 두는 이유이기도 하다. 다시 뽑는 법은 문서에 한 줄로 남긴다.
- Remotion 렌더에는 Node · pnpm 과 브라우저 렌더러 내려받기가 필요하다. 이 컴퓨터에서 처음 돌릴 때 시간이 걸릴 수 있다.
- 미러 GIF 를 모드 저장소에 넣으면 저장소가 커진다. 크기를 보고, 크면 프레임 수를 줄인다.
- 문서 검사가 '설명 있음'을 이름이 나오는지로만 보면 한 줄 언급도 통과한다. 늘 켜진 기능은 찾을 말을 기능마다 정해 둔다.
- 코어 README 변경이 래퍼 사본에 들어가는 것은 다음 코어 릴리스 동기화 뒤에 확인된다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
