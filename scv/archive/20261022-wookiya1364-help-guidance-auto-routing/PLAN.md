---
title: 자동 라우팅에 맞춘 안내 정리
slug: 20261022-wookiya1364-help-guidance-auto-routing
author: wookiya1364
created_at: 2026-10-22
status: testing
kind: refactor
lang: korean
tags: [help, guidance, onboarding]
raw_sources:
  - scv/conversations/20261022-020000-release-0-69-wrappers.md
refs: []
invariants:
  - "SCV_ALWAYS_ON=off 인 프로젝트는 지금처럼 명령(action:help \"…\")으로 들어오라는 안내를 받는다"
  - "진단의 다른 추천(상태 색인 충돌 · 미설치 · raw 변경 · 활성 계획)의 순서와 문구는 그대로"
  - "설정 파일을 덮어쓰는 명령은 어떤 안내에도 나오지 않는다"
---

# 자동 라우팅에 맞춘 안내 정리

## Summary

매 턴 훅이 일반 대화를 help 로 보내 주는데(기본 켬), 진단 · 설치 · 문서 안내는 아직
"`help "…"` 를 직접 치라"고 하거나, 알림 설정이 없다는 이유로 설정 예시를 설정 파일 위에
복사하라는 단계에서 멈춘다. 다른 폴더에 새로 설치한 세션이 바로 이 안내에 막혔다(대화 Turn 3).
새 사용자가 보는 길 전부를 "그냥 하고 싶은 말을 하면 된다"로 맞추고, 각 문구를 테스트로 고정한다.

## Goals / Non-Goals

- **Goals**
  - ① 진단 추천: 알림(NOTIFIER_PROVIDER · 토큰)이 없어도 '설정하라'가 첫 할 일이 되지 않는다. 알림은 선택 줄로 내려가고, 설정 파일이 이미 있으면 덮어쓰는 복사 명령을 내놓지 않는다.
  - ② 준비됨 안내: "만들고 싶은 것을 그냥 말하면 된다"가 첫 줄. 자동 라우팅이 꺼진 프로젝트에서만 명령 입력을 안내한다.
  - ③ 문서 · 메시지: 계획 규약(PROMOTE.md §1.4), raw 안내(raw/README.md), promote 의 "다듬을 것 없음" 메시지, 대화 멈춤 안내(promote-handoff), help 규약의 모드 예시가 "그냥 말하기"를 기본 입구로, 명령은 명시적 선택지로 적는다.
  - ④ 설치 마지막 안내(hydrate.sh): "그냥 말하면 된다"로 바꾸고 영어 오타("your the host agent session")를 고친다.
- **Non-Goals**
  - 매 턴 훅의 라우팅 동작 자체는 바꾸지 않는다.
  - README(코어 · 두 래퍼, 3개 언어)는 이미 맞으므로 손대지 않는다.
  - 기록(CHANGELOG · 지난 릴리스 노트 · archive · 대화)은 고치지 않는다.

## Approach Overview

코어만 고친다 — 두 래퍼는 코어 동기화로 같은 문구를 받는다(래퍼가 `action:` 을 `/scv:` · `$scv:` 로 바꿔 렌더).
진단 스크립트는 추천을 고르는 분기에서 '알림 미설정'을 막는 단계로 쓰지 않고, 추천 뒤 선택 안내 한 줄로 옮긴다.
자동 라우팅 켜짐 여부는 이미 있는 설정 읽기로 판단한다(SCV_ALWAYS_ON, 없으면 on).
문서는 같은 뜻의 짧은 문장으로 바꾸고, 규약 파일 크기 예산(test-help-budget)을 넘지 않게 한다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readProjectState,   // 파일 · 설정 → 상태 값 (입구, 읽기)
  pickNextAction,     // 상태 값 → 추천 종류 (알림 미설정은 추천을 고르지 않음)
  renderNextAction,   // 추천 종류 + 라우팅 켜짐 → 안내 문구
  appendOptionalNotes // 안내 문구 + 알림 상태 → 선택 줄 붙인 문구
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readProjectState | 프로젝트 폴더 → 설치 · 설정 · raw · 계획 상태 | 부수효과 (입구, 읽기만) |
| 2 | pickNextAction | 상태 → 추천 종류 | 순수 |
| 3 | renderNextAction | 추천 종류 · 라우팅 켜짐 → 문구 | 순수 |
| 4 | appendOptionalNotes | 문구 · 알림 상태 → 최종 문구 | 순수 (출력은 echo — 출구) |

- 부수효과 위치: 1(파일 읽기)과 마지막 출력뿐.
- 재사용: 설정 읽기(settings_get), 기존 분기 순서.

## Guardrails

- 설정 파일을 지우거나 덮어쓰는 명령을 안내에 넣지 않는다(설정이 있으면 settings-set 또는 secret 파일 안내).
- SCV_ALWAYS_ON=off 경로의 안내는 명령 입력을 유지한다.
- 기존 테스트가 고정한 문구("Ready — no immediate action" 등)는 유지한다.
- Mac + Linux, bash 3.2 에서 같은 결과.

## Exit criteria

- All TESTS.md scenarios pass
- 코어 전체 테스트 통과(codex 사본 포함), 코어 · 두 래퍼 0.69.1 릴리스

## Suggested path

1. 새 테스트(test-help-guidance.sh)를 먼저 써서 지금 실패를 확인
2. help.sh 추천 분기 · 준비됨 문구 · 선택 줄
3. hydrate.sh 마지막 안내
4. 문서 · 프로토콜 메시지
5. 기존 테스트(run-dry · help-budget · guidance · template-digest) 확인

## Risks / Open Questions

- 규약 파일 크기 예산이 빠듯하면 문장을 줄여야 한다.
- 템플릿 문서를 바꾸면 템플릿 다이제스트 · 동기화 검사가 함께 갱신돼야 할 수 있다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
