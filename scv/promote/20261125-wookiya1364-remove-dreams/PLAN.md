---
title: dreams 걷어내기 — 기능 · 안내 글 · 대시보드 칸 · 보고서 파일
slug: 20261125-wookiya1364-remove-dreams
author: wookiya1364
created_at: 2026-11-25
status: in_progress
kind: retirement
lang: korean
tags: [dreams, retirement, per-turn-text]
raw_sources:
  - scv/conversations/20261124-200447-dashboard-gears-ask-mode.md
refs: []
invariants:
  - "dreams 를 한 번도 쓰지 않은 프로젝트의 매 턴 훅 출력은 지우기 전과 같다(자동 실행 한 줄만 없어진다)"
  - "다른 액션 22개의 이름과 동작은 그대로다"
  - "다른 프로젝트에 이미 만들어진 보고서 파일은 건드리지 않는다"
---

# dreams 걷어내기 — 기능 · 안내 글 · 대시보드 칸 · 보고서 파일

## Summary

dreams(지난 세션을 돌아보고 요청 쓰는 법을 코칭하는 보고서)는 실익이 없다는 사용자 판단(2026-11-25)으로 걷어낸다. 명령, 매 턴 훅의 자동 실행, 세션 시작 훅의 안내, 규약 글, 설정 키, 시험, 문서의 언급, 대시보드의 드림 칸을 지우고, 이 프로젝트에 쌓인 보고서 파일 57개도 지운다. 릴리스는 이 계획에 넣지 않는다 — 다음 릴리스에 다른 일과 묶는다.

## Goals / Non-Goals

- **Goals**
  - 본체에서 dreams 액션 · 스크립트 · 라이브러리 · 규약 · 훅 구간 · 설정 키 · 시험 · 문서 언급을 지운다(액션 23 → 22).
  - 대시보드에서 드림 칸과 그 코드 · 시험을 지운다.
  - 이 프로젝트의 scv/dreams 보고서 파일을 지운다 — 지우기 전에 목록을 사용자에게 보인다.
- **Non-Goals**
  - 릴리스(사용자 결정 2026-11-25: 릴리스는 빼고).
  - 두 래퍼의 dreams 명령 · 스킬 지우기 — 래퍼는 릴리스된 본체를 싣기 때문에, 본체를 릴리스할 때 맞춤 작업으로 함께 지운다(Risks 에 적음).
  - 다른 프로젝트의 scv/dreams 폴더.
  - 보관된 옛 계획 · 결정 기록 안의 dreams 언급(기록은 고치지 않는다).

## Approach Overview

- 지울 것을 먼저 목록으로 뽑는다: 본체에서 dreams · 드림이 든 파일 25개(스크립트 2 · 규약 1 · 훅 3 · 시험 6 · 설정 · 액션 목록 · 문서).
- 통째로 지우는 파일: `core/scripts/dreams.sh`, `core/scripts/lib/dreams.sh`, `core/protocols/dreams.md`, `core/tests/test-dreams.sh`.
- 구간만 지우는 파일: 매 턴 훅과 세션 시작 훅의 dreams 구간, 가드의 액션 이름 목록, 액션 목록(`core/actions.json`), 설정 예시와 스위치, 도움말의 한 줄, 시험 시간표, 다른 시험 속의 언급, 문서.
- 액션 수가 박힌 곳(23)을 22 로 고친다.
- 대시보드: 드림 칸의 모델 · 화면 · 시험을 지운다(코드는 scv-mods 저장소).
- 보고서 파일: 목록을 보여 주고 확인받은 뒤 지운다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  listDreamsFootprint,   // 저장소 → dreams 가 걸린 파일과 줄
  removeDreams,          // 목록 → 지운 저장소
  verifyNoDreams,        // 저장소 → 남은 언급 0 · 시험 통과
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | `listDreamsFootprint` | dreams 가 걸린 파일과 줄을 뽑는다 | 저장소 → 목록 | 부수효과 (입구) |
| 2 | `removeDreams` | 목록대로 파일과 구간을 지운다 | 목록 → 지운 저장소 | 부수효과 (출구) |
| 3 | `verifyNoDreams` | 남은 언급을 세고 관련 시험을 돌린다 | 저장소 → 0건 · 통과 | 부수효과 (입구) |

- 부수효과 위치: 셋 다 저장소를 읽거나 쓴다 — 새 순수 함수는 없다(지우는 계획).
- 재사용: 순수 함수 사전 만들기(`core/scripts/pure-catalog.sh build`) — 지운 함수가 사전에서 빠진다.

### 합성 설계 체크리스트 (Composition checklist)

| # | 물음 | 답 | 근거 |
|---|---|---|---|
| 7 | 부수효과가 파이프라인 양 끝에만 있는가 | 지우는 일이라 가운데 계산이 없다 | 위 표 |
| 그 밖 | 1 · 2 · 3 · 4 · 5 · 6 · 8 · 9 · 10 | 해당 없음 | 새 함수 · 순회 · 비동기가 없고, 매 턴 훅에서는 구간이 줄어든다 |

## Guardrails

- 다른 액션과 그 시험은 건드리지 않는다. 액션 수가 박힌 곳만 고친다.
- 훅 템플릿을 바꾸므로 템플릿 지문(`core/TEMPLATE_DIGEST`)과 순수 함수 사전을 다시 만든다.
- 보고서 파일은 사용자가 목록을 본 뒤에만 지운다.
- 보관된 계획 · 결정 기록은 고치지 않는다.
- 맥(기본 셸 3.2 포함) · 리눅스 둘 다. 공개 저장소에 다른 프로젝트 이름을 넣지 않는다.

## Exit criteria

- TESTS.md 의 모든 시나리오 통과.
- 본체(core · docs · README)에서 dreams · 드림 검색 0건.
- 대시보드에 드림 칸이 없다 — 화면 사진으로 보인다.
- 이 프로젝트의 scv/dreams 에 보고서 파일 0개.
- 깃허브 검사 통과 뒤 develop 에 병합(릴리스 없음).

## Suggested path

1. 지울 것 목록을 뽑아 계획 폴더에 적는다 — `listDreamsFootprint`
2. 본체에서 파일과 구간을 지우고 액션 수 · 지문 · 사전을 맞춘다 — `removeDreams`
3. 대시보드에서 드림 칸과 그 코드 · 시험을 지운다 — 드림 칸이 없는 화면을 사진으로 남긴다
4. 이 프로젝트의 보고서 파일 목록을 사용자에게 보이고, 확인받은 뒤 지운다 — 지운 뒤 0개인 것을 보인다
5. 남은 언급을 세고 관련 시험을 돌린 뒤 깃허브 검사를 받는다 — `verifyNoDreams`

## Related Documents

## Risks / Open Questions

- 두 래퍼에는 dreams 명령과 스킬이 남는다 — 본체를 릴리스할 때 래퍼 맞춤(액션 수가 바뀌면 맞춤 봇이 멈추므로 손으로)에서 함께 지워야 한다. 그때까지 설치본에는 dreams 가 그대로 있다.
- 이미 dreams 를 쓰던 프로젝트의 scv/dreams 폴더와 설정 키는 남는다 — 지워도 되고 두어도 해가 없다.

## Links

- Raw originals: (listed in frontmatter)
- Wrap-up: [`WRAPUP.md`](./WRAPUP.md)
- Related PRs:
