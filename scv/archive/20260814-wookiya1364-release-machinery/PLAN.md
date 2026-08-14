---
title: 승격 대기 판정과 벤더 게이트
slug: 20260814-wookiya1364-release-machinery
author: wookiya1364
created_at: 2026-08-14
status: done
kind: refactor
lang: korean
tags: [ci, release, guard]
raw_sources:
  - scv/raw/stale/20260814-wookiya1364-release-machinery.md
refs: []
invariants:
  - "릴리스 체인(develop→stage→main) PR 은 어떤 게이트도 막지 않는다"
  - "봇 동기화 브랜치는 어떤 게이트도 막지 않는다"
  - "게이트는 벤더링된 사본에서 실행되므로 호스트 토큰을 담지 않는다"
---

# 승격 대기 판정과 벤더 게이트

## Summary

릴리스 기계장치에서 사람이 손으로 때우던 두 곳을 없앤다. 하나는 승격 워크플로가
체크를 기다리는 방식이고, 다른 하나는 벤더링된 Core 를 누가 옮겼는지다. 덤으로,
머지를 막는 게이트인데 테스트가 하나도 없던 `check-provenance.sh` 에 검증을 붙인다.

## Goals / Non-Goals

- **Goals**
  - 승격 워크플로가 필수 체크가 생기기 전에 머지를 시도하지 않는다
  - 손으로 벤더링한 PR 이 머지 시점에 걸린다 — 단, 이유를 달면 통과한다
  - 두 게이트가 실제 저장소 픽스처로 검증된다
- **Non-Goals**
  - 벤더링을 금지하지 않는다. Core 계약이 바뀌면 봇이 못 따라온다
  - 매트릭스 잡이 확장되지 않은 이름으로 보고되는 것 자체는 고치지 않는다.
    GitHub 의 동작이고, 우리가 거기에 의존하지 않으면 된다
  - 이번 릴리스의 승격은 여전히 옛 로직으로 돈다(아래 Risks)

## Approach Overview

**대기 판정.** 자작 판정을 세 번째로 만들지 않는다. 머지를 결정하는 주체가 GitHub
이므로 GitHub 의 `mergeStateStatus` 를 본다. 다만 그 값 하나로는 부족하다 — 건너뛴
매트릭스 자리표시자가 rollup 을 `UNSTABLE` 로 붙잡으면 `CLEAN` 은 영원히 오지
않는다. 세 조건이 동시에 성립할 때만 머지한다: 실패한 체크가 없고, 도는 체크가
없고, GitHub 이 `BLOCKED` 이라 하지 않는다.

`DIRTY`/`DRAFT` 는 900초를 기다릴 이유가 없으므로 즉시 중단한다. `BEHIND` 는
`update-branch` 후 계속한다. `UNKNOWN` 은 판정이 아니라 "아직 계산 안 됨"이므로
대기한다.

**벤더 게이트.** `check-provenance.sh` 의 형제로 `check-vendor-provenance.sh` 를
둔다. 앞의 것은 "무엇이 이 변경을 만들었나"를 묻고, 새것은 "누가 핀을 옮겼나"를
묻는다. `*/vendor/scv-core/` 를 건드리는 PR 은 봇 브랜치이거나, 릴리스 체인이거나,
제목에 이유가 달려야 한다.

**검증.** 워크플로 블록은 마커 사이를 잘라내 그대로 실행한다. 게이트는 실제 git
저장소를 픽스처로 쓴다.

## Guardrails

- 릴리스 체인(`stage`/`main` 대상) PR 은 새 게이트가 절대 막지 않는다. 막으면 모든
  릴리스가 선다
- 봇 동기화 브랜치(`chore/core-*`)도 막지 않는다. 그게 봇의 일이다
- 새 스크립트는 `core/` 안에 들어가므로 호스트 이름을 담을 수 없다. 벤더 경로는
  래퍼마다 깊이가 다르므로 모양(`*/vendor/scv-core/`)으로 맞춘다
- 워크플로 `run:` 블록 주석에 `${{ … }}` 표기를 넣지 않는다. Actions 가 치환한다
- 대기 상한(900초)을 넘겨도 **아무것도 반쯤 승격된 상태로 남기지 않는다**. PR 은
  열린 채로 두고 실패한다
- `check-provenance.sh` 의 판정 로직은 건드리지 않는다. 이번에 붙이는 건 검증뿐이다

## Exit criteria

- TESTS.md 시나리오 전부 통과
- 새 대기 블록 테스트가 **옛 코드에서 실패하고 새 코드에서 통과**한다. 통과만 하는
  테스트는 무엇도 증명하지 않는다
- 두 게이트 각각 최소 하나를 실제로 거부한다(무력화 감지)
- `tests/run.sh`, `core/tests/run-dry.sh`, `core/tests/test-*.sh` 전부 초록
- 벤더링된 아티팩트에 새 스크립트가 들어간다
- 배포 문서(`docs/release.md`)가 새 절차와 일치한다

## Suggested path

1. #115 의 rollup 을 떠서 조기 종료의 실제 입력을 확정한다
2. 대기 블록을 `mergeStateStatus` 기반으로 교체하고 마커로 감싼다
3. 마커 사이를 실행하는 테스트를 쓰고, **옛 블록에 대고 돌려** 실패를 확인한다
4. `check-vendor-provenance.sh` 를 `check-provenance.sh` 형태로 쓴다
5. 두 게이트를 실제 저장소 픽스처로 검증한다
6. 래퍼 워크플로에 스텝을 추가한다 — **Core 벤더링 이후에**
7. `docs/release.md` 와 `core/contracts/guard.md` 를 실제와 맞춘다

## Related Documents

- [`TESTS.md`](./TESTS.md)
- [`FEATURE_ARCHITECTURE.md`](./FEATURE_ARCHITECTURE.md)
- `core/contracts/guard.md` — 세 게이트의 역할 구분

## Risks / Open Questions

- **이번 릴리스는 못 고친다.** `workflow_dispatch` 는 기본 브랜치의 워크플로 파일을
  실행한다. 0.27.0 승격은 여전히 옛 로직으로 돌고, 또 손이 갈 수 있다. 0.28.0 부터
  듣는다
- **래퍼는 한 박자 뒤에 간다.** 새 스크립트가 벤더링되기 전에 래퍼 워크플로에
  스텝을 넣으면 CI 가 "파일 없음"으로 빨개진다. Core → 봇 동기화 → 래퍼 순서
- `mergeStateStatus` 는 GitHub 이 지연 계산한다. 첫 조회가 `UNKNOWN` 을 돌려주는
  것은 정상이고, 재조회가 계산을 촉발한다. 대기 상한 안에서 해소되는지는 실제
  승격에서 확인해야 한다
- 900초 상한은 근거 있는 값이 아니다. 현재 CI 가 그보다 한참 빠르다는 것만 안다

## Links

- Raw originals: (frontmatter 참조)
- Related PRs:
