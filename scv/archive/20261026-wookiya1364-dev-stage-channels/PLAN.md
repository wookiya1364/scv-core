---
title: SCV 개발 · 스테이징 채널 — 운영 릴리스 없이 바꿔 끼워 받아 확인
slug: 20261026-wookiya1364-dev-stage-channels
author: wookiya1364
created_at: 2026-10-26
status: testing
kind: feature
lang: korean
tags: [release, channel, wrapper-sync]
raw_sources:
  - scv/conversations/20261022-165947-scv-mods-install-command.md
refs: []
invariants:
  - "운영 채널 그대로 — 브랜치를 붙이지 않고 마켓을 추가하면 지금처럼 운영(main) 버전이 받아진다"
  - "릴리스 절차 그대로 — 코어 릴리스 → 래퍼 동기화 PR → 래퍼 릴리스 순서와 그 검사들이 바뀌지 않는다"
---

# SCV 개발 · 스테이징 채널 — 운영 릴리스 없이 바꿔 끼워 받아 확인

## Summary

지금은 코어와 두 래퍼(claude · codex)에 develop · stage · main 브랜치가 있어도, 사용자가 받아 볼 수 있는 것은 운영(main) 릴리스뿐이다. 그래서 고친 것을 확인하려면 운영 릴리스까지 내야 한다. 명령 하나로 설치된 SCV를 개발 · 스테이징 · 운영 채널 사이에서 바꿔 끼우고, 래퍼의 개발 · 스테이징 브랜치가 코어의 같은 브랜치를 자동으로 따라가게 한다.

## Goals / Non-Goals

- **Goals**
  - 사용자가 명령 하나로 채널을 고른다: 개발(develop) · 스테이징(stage) · 운영(main). 한 번에 하나만 깔린다(바꿔 끼우기).
  - 코어 develop · stage 에 병합되면 두 래퍼의 같은 브랜치가 그 코어를 자동으로 받아, 개발 · 스테이징 채널에서 바로 보인다.
  - 개발 · 스테이징 빌드는 버전 표시가 달라, 지금 어느 채널의 어느 커밋인지 보인다(예: `0.70.5-dev.<커밋 7자리>`).
  - codex 래퍼도 같은 방식이 되는지 확인하고, 되면 같은 명령으로 바꾼다.
- **Non-Goals**
  - 채널 여러 개를 동시에 깔기 — 마켓 이름이 같아 충돌한다(확인, 2026-10-26). 채널별 이름은 이번에 하지 않는다.
  - 운영 릴리스 절차 · 버전 규칙 바꾸기.
  - scv-mods(대시보드 등)의 채널 — 모드는 이번 범위 밖.

## Approach Overview

확인된 사실(2026-10-26, 사용자 설정을 건드리지 않는 임시 설정 폴더에서 실험):
- `claude plugin marketplace add https://github.com/wookiya1364/scv-claude-code.git#stage` 가 성공하고, 목록에 `ref: stage` 로 남는다.
- 같은 이름으로 `#develop` 을 더 넣으면 이름 충돌로 실패한다 → 채널은 지우고 다시 넣는 바꿔 끼우기.
- 래퍼의 `core-sync.yml` 은 코어 **릴리스** 때만(`scv-core-released`) 래퍼 develop 에 동기화 PR 을 연다 → 코어 개발분은 지금 래퍼 develop 에 들어가지 않는다.

구성:
1. **채널 바꿔 끼우기 명령(코어 스크립트 + 래퍼 스킬)** — 지금 깔린 마켓 상태를 읽고, 목표 채널의 출처(`<git 주소>#<브랜치>`, 운영은 브랜치 없이)를 만든 뒤, 지우기 → 다시 넣기 → 플러그인 업데이트 순서의 명령 목록을 만들어 실행한다. 이미 그 채널이면 아무것도 하지 않는다. 끝에 `/reload-plugins` 를 안내한다.
2. **채널 동기화(코어 → 래퍼)** — 코어 develop · stage 에 push 되면 래퍼로 알림(dispatch)을 보내고, 래퍼는 같은 브랜치에 그 코어 커밋을 vendor 해 검사를 돌린 뒤 반영한다. 버전은 채널 표시를 붙인다.
3. **운영은 손대지 않는다** — main 과 릴리스 체인, `scv-core-released` 경로는 그대로.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
// 채널 바꿔 끼우기
flow(
  readInstalled,     // (claude CLI)            → 깔린 마켓 상태      [부수효과 · 입구]
  channelRef,        // (채널)                  → 브랜치 | 없음
  marketplaceSource, // (git 주소, 브랜치)       → 출처 문자열
  switchPlan,        // (깔린 상태, 목표 출처)    → 명령 목록 | 할 일 없음
  runPlan,           // (명령 목록)              → 결과 줄들          [부수효과 · 출구]
)
// 채널 동기화
flow(
  coreBranchPush,    // (코어 push 이벤트)        → 브랜치, 커밋        [부수효과 · 입구]
  channelVersion,    // (기준 버전, 채널, 커밋)    → 채널 버전 문자열
  vendorAndCommit,   // (래퍼 브랜치, 코어 커밋)   → 반영된 커밋         [부수효과 · 출구]
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | readInstalled | 지금 깔린 SCV 마켓의 이름 · 주소 · 브랜치를 읽는다 | claude CLI 목록 → 깔린 상태 | 부수효과 (입구) |
| 2 | channelRef | 채널 이름을 브랜치로 바꾼다(개발 → develop, 스테이징 → stage, 운영 → 없음) | 채널 → 브랜치 / 없음 | 순수 |
| 3 | marketplaceSource | 마켓 주소에 브랜치를 붙여 추가할 출처를 만든다 | 주소, 브랜치 → 출처 | 순수 |
| 4 | switchPlan | 지금 상태와 목표를 비교해 실행할 명령 순서를 만든다 | 깔린 상태, 목표 출처 → 명령 목록 / 할 일 없음 | 순수 |
| 5 | runPlan | 명령을 차례로 실행하고, 실패하면 그 자리에서 멈춰 알린다 | 명령 목록 → 결과 줄들 | 부수효과 (출구) |
| 6 | coreBranchPush | 코어 develop · stage push 를 받아 래퍼에 알린다 | push 이벤트 → 브랜치, 커밋 | 부수효과 (입구) |
| 7 | channelVersion | 다음 버전에 채널과 커밋을 붙인 버전 표시를 만든다 | 기준 버전, 채널, 커밋 → 버전 문자열 | 순수 |
| 8 | vendorAndCommit | 래퍼 같은 브랜치에 그 코어를 넣고 검사 뒤 반영한다 | 래퍼 브랜치, 코어 커밋 → 반영 커밋 | 부수효과 (출구) |

- 부수효과 위치: 1 · 5(로컬 claude/codex CLI), 6 · 8(GitHub dispatch · 래퍼 저장소 쓰기). 2 · 3 · 4 · 7 은 순수 — 단위 시험 대상.
- 재사용: 래퍼 `core-sync.yml` 의 vendor · 검증 단계, 코어 `release.yml` 의 dispatch 단계(재시도 포함), `mods.sh` 의 `STEP:`/`RESULT:`/`NEXT:` 출력 모양.

## Guardrails

- 운영 채널과 릴리스 절차는 그대로(frontmatter invariants). `scv-core-released` 경로 · main 브랜치 · 릴리스 태그는 건드리지 않는다.
- 사용자 플러그인 폴더(`~/.claude/plugins`)를 손으로 고치지 않는다 — 언제나 `claude plugin …` / `codex plugin …` 명령으로만.
- 시험은 사용자 설정을 건드리지 않는 임시 설정 폴더(`CLAUDE_CONFIG_DIR`)에서.
- 안전 검사 우회 금지. 채널 동기화가 래퍼 브랜치에 반영하기 전에 래퍼 검사를 돌린다.
- Mac + Linux, bash 3.2 에서 같은 결과.
- 새 명령이 늘면 두 동기화 봇이 명령 수 검사에서 멈춘다(지난 0.69.0 경험) — 동기화 때 어댑터 몫을 함께 넣는다.

## Exit criteria

- All TESTS.md scenarios pass
- 이 컴퓨터에서 명령 하나로 개발 채널로 바꾸면, 다음 `/reload-plugins` 뒤 코어 develop 의 최신 커밋이 담긴 SCV가 돈다(버전 표시로 확인).
- 운영으로 되돌리면 브랜치 없는 출처로 돌아오고, 최신 릴리스 버전이 받아진다.

## Suggested path

1. codex 가 브랜치를 붙인 마켓 추가를 지원하는지 임시 폴더에서 실험해 결과를 이 계획서 위험 칸에 적는다 — codex 도 같은 명령으로 바꿀 수 있는지 먼저 확인한다
2. 채널 → 브랜치, 출처, 명령 목록, 버전 표시를 만드는 순수 함수와 단위 시험 — `channelRef`, `marketplaceSource`, `switchPlan`, `channelVersion`
3. 깔린 상태 읽기와 명령 실행, 채널 바꿔 끼우기 명령(코어 스크립트 + 래퍼 스킬) — `readInstalled`, `runPlan`
4. 코어 develop · stage push 알림과 래퍼 채널 동기화 워크플로 — `coreBranchPush`, `vendorAndCommit`
5. 임시 설정 폴더에서 개발 → 운영으로 실제로 바꿔 끼워 보고, 래퍼 develop 의 코어가 코어 develop 과 같은지 확인한다 — 끝까지 실제로 돌려 본다
6. 릴리스 노트와 README 3개 언어에 채널 바꾸는 법을 적는다 — 사용자가 채널을 고르는 법을 안내한다

## Related Documents

- 래퍼 동기화: `../scv-claude-code/.github/workflows/core-sync.yml`, `../scv-codex/.github/workflows/core-sync.yml`
- 코어 릴리스 알림: `.github/workflows/release.yml` (dispatch 단계)

## Risks / Open Questions

- **버전이 같으면 같은 캐시 폴더가 쓰인다(확인, 2026-10-26).** 운영 → `#develop` 으로 바꿔 끼워도 둘 다 0.70.4 라 같은 버전 폴더에 설치됐다 — 채널 버전 표시(단계 7)가 필요하다.
- **마켓 지우기는 설정 항목과 설치된 플러그인까지 지운다(확인).** claude: remove 뒤 설정에서 항목이 사라지고 플러그인 목록이 비어, 다시 넣은 뒤 install 이 필요. 그래서 바꿔 끼우기 = 지우기 → 다시 넣기 → 설치.
- **codex 도 브랜치 지정이 된다(확인, T10).** `codex plugin marketplace add <owner/repo>@<ref>` 또는 `--ref <ref>`. 같은 이름으로 다른 출처를 넣으면 거절 — claude 와 같은 바꿔 끼우기. codex 의 목록 JSON 에는 ref 가 없고 `config.toml` 의 `[marketplaces.<이름>] ref` 에 있다.
- **래퍼 develop 에 코어 개발분을 자동으로 넣으면 릴리스 체인이 바뀐다** — 릴리스 때 동기화 PR 이 빈 PR 이 되어 봇이 멈출 수 있다. 그래서 채널은 래퍼 develop · stage 가 아니라 따로 만드는 `channel/dev` · `channel/stage` 브랜치에서 받는다(경로 변경, 아래).
- **스테이징 채널의 쓰임** — 지금 stage 는 promote 때만 잠깐 지나가 운영과 거의 같다(확인: 셋 다 0.70.4). 스테이징이 의미 있으려면 릴리스 전에 stage 에 머무는 시간이 있어야 한다.

## Path delta (구현 중)

- 채널 브랜치: 계획은 '래퍼 develop · stage 가 코어를 따라감'이었으나, 그러면 릴리스 동기화 PR 이 비어 운영 절차(불변식)가 흔들린다. 래퍼 채널 동기화가 `channel/dev`(래퍼 develop + 코어 develop) · `channel/stage`(래퍼 stage + 코어 stage)를 따로 만든다. 래퍼 develop · stage · main 은 그대로.
- 명령의 주인: 기존 `update` · `mods` 처럼 호스트 플러그인 명령을 쓰는 일이라 `channel` 은 어댑터 몫 액션(코어는 규약 `protocols/channel.md` + 순수부 `lib/channel.sh`, 실행은 래퍼). 코어에 호스트 이름을 박지 않는다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
