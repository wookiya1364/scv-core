---
title: 자동 알림은 사람 턴이 아니다 · PR 은 저장소 브랜치 규칙대로 — 자동 입력 판별, PR 대상 브랜치 설정, PR 커밋 범위 점검
slug: 20261001-wookiya1364-auto-turns-pr-base-fixes
author: wookiya1364
created_at: 2026-10-01
status: testing
kind: feature
lang: korean
tags: [hook, prompting, host-profile, pr, release]
raw_sources:
  - scv/conversations/20261001-083005-auto-turns-pr-base-fixes.md
refs: []
invariants:
  - "사람이 쓴 메시지의 흐름(새 턴 표 · 등록 안내 · 종료 판정 · 예약 경고 전달)은 지금과 같다"
  - "자동 입력 머리말이 비어 있으면(기본) 매 턴 훅 · 종료 훅 출력이 지금과 바이트 단위로 같다"
  - "SCV_PR_BASE 가 비어 있으면 PR 도구의 대상 브랜치 결정은 지금과 같다(에픽이면 epic/<slug>, 아니면 origin 기본 브랜치)"
  - "매 턴 스택(test-help-budget T12, 9192B)은 늘지 않는다"
  - "호스트 중립 — 코어 소스 · 검사에 호스트 알림 모양을 적지 않는다(래퍼 호스트 설정이 싣는다), 맥(bash 3.2) · 리눅스 동일"
scope:
  - core/scripts/lib/host-profile.sh
  - core/contracts/host-profile.md
  - core/contracts/host-profile.env.example
  - core/scripts/lib/model-prompting.sh
  - core/scripts/model-prompting.sh
  - core/template/hooks/on-user-prompt.sh
  - core/scripts/pr-helper.sh
  - core/protocols/work.md
  - core/template/scv/scv_settings.example.json
  - core/TEMPLATE_DIGEST
  - core/tests/test-model-prompting.sh
  - core/tests/test-pr-base.sh
  - scv/scv_settings.json
  - VERSION
  - CHANGELOG.md
supersedes: []
---

# 자동 알림은 사람 턴이 아니다 · PR 은 저장소 브랜치 규칙대로

## Summary

사용자 요구(대화 Turn 1~2): 이번 세션에서 찾은 결함 셋을 고치고, 문제가 없으면 SCV 원칙(0.63.0 기능)과 함께 코어 · 두 래퍼
릴리스까지 간다. (1) 매 턴 훅은 비어 있지 않은 모든 입력을 사람 턴으로 본다(`on-user-prompt.sh:122`) — 배경 작업 완료 알림
(`<task-notification>…` 으로 시작, 이번 세션 작업 기록으로 확인)에도 새 턴 표 · 등록 안내 · 도움말 다시 읽기 횟수가 생기고, 종료
훅이 등록 · 인용을 요구한다. (2) PR 도구는 대상 브랜치를 origin 기본 브랜치(main)로 정한다(`pr-helper.sh:543`) — 기능 브랜치는
develop 으로 가야 하는 저장소 규칙과 어긋난다. (3) PR 도구는 보관 폴더만 커밋에 올린다(`pr-helper.sh:554`) — 구현을 먼저 커밋하지
않으면 코드가 빠진 PR 이 열린다(코드로 확인, 재현은 안 함).

## Goals / Non-Goals

- **Goals**
  - **자동 입력 판별**: 호스트 설정 키 `SCV_AUTO_PROMPT_PREFIXES`(공백으로 나눈 머리말 목록, 기본 빈 값). 입력이 앞 공백을 빼고
    머리말 하나로 시작하면 자동 입력이다. 판별은 모델별 프롬프팅 명령의 `kind` 하위 명령이 한다(호스트 설정을 읽는 곳). 클로드
    래퍼는 릴리스 단계에서 `<task-notification>` 을 싣는다.
  - **자동 입력 턴**: 새 턴 표를 쓰지 않는다(직전 사람 턴의 등록이 그대로 유효 — 파일 쓰기 거절 없음). 등록 안내 · 첫 행동 지시 ·
    진단 · 가이드 안내 · 위임 블록을 싣지 않고, 예약 경고는 지우지 않고 다음 사람 턴으로 미룬다. 도움말 다시 읽기 횟수를 올리지
    않는다. "이번 턴은 자동" 표시(`.help-turn-auto` = 지금 표)를 남긴다.
  - **종료 훅**: 지금 표가 자동 표시와 같으면 등록 · 인용 판정을 건너뛴다(`STOP_GATE: auto`). 다음 사람 턴은 지금처럼 판정한다.
  - **PR 대상 브랜치**: 설정 `SCV_PR_BASE`. 우선순위 — 에픽이면 `epic/<slug>`, 아니면 설정값, 비면 origin 기본 브랜치, 그것도
    없으면 main. 이 저장소 설정은 `develop`.
  - **PR 커밋 범위**: 보관 폴더와 함께 SCV 폴더 전체(작업 기록 · 대화 · 결정 · 색인 — 무시 목록은 git 이 거른다)를 올린다. 그
    밖에 커밋 안 된 변경(구현 코드 등)이 있으면 커밋 · 푸시 전에 멈추고 파일 목록과 할 일을 보인다(exit 1). 결과 폴더 ·
    증적 폴더는 PR 도구가 다루므로 점검에서 뺀다. `--dry-run` 은 멈추지 않고 경고만 낸다.
  - **릴리스 준비**: VERSION 0.63.0, CHANGELOG(SCV 원칙 + 이 세 수정).
- **Non-Goals**
  - 작업 기록에서 자동 입력을 "user" 대신 다른 이름으로 적기 — 지금처럼 적는다(다음 개선 후보).
  - 코덱스 호스트의 자동 입력 머리말 — 코덱스 알림 모양을 모른다(빈 값 유지).
  - PR 도구가 구현 코드를 알아서 커밋하기 — 엉뚱한 파일이 섞일 수 있어 멈추고 알린다.
  - 에픽 흐름의 대상 브랜치 규칙 변경.

## Approach Overview

판별은 한 곳(모델별 프롬프팅 명령)이 한다 — 호스트 설정을 이미 읽고 있고, 턴 표를 쓰는 곳도 거기다. 매 턴 훅은 입력의 프롬프트를
그 명령의 `kind` 에 넘겨 `auto | human` 만 받는다. `auto` 면 `prompt --auto`(표시만 남김)를 부르고 앞단 블록을 건너뛴다. `human`
이면 지금 흐름 그대로이고, `prompt` 가 지난 자동 표시를 지운다. 종료 훅은 `stop` 안에서 표시와 지금 표를 비교한다. 머리말이 비면
`kind` 는 늘 `human` 이라 모든 출력이 지금과 같다. PR 도구는 대상 브랜치와 "커밋 안 된 변경 중 SCV 폴더 · 보관 폴더 · 결과 폴더
밖의 것"을 순수 함수로 고르고, 효과(스테이징 · 멈춤 · 푸시)는 지금 자리에서 한다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
# 자동 입력 턴
flow(
  scv_mp_prompt_kind,     // (프롬프트, 머리말 목록) → auto | human
)
# PR 도구
flow(
  scv_pr_base_branch,     // (에픽, SCV_PR_BASE, origin 기본) → 대상 브랜치
  scv_pr_stray_changes,   // (git status --porcelain, 허용 경로들) → 멈춰야 할 파일 목록
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | 훅: 입력 · 프롬프트 읽기 | 훅 입력 JSON → 프롬프트 | 부수효과 (입구) |
| 2 | scv_mp_prompt_kind | 프롬프트, 머리말 목록 → auto / human | 순수 |
| 3 | prompt --auto / prompt | 판별 → 자동 표시 쓰기 / 새 표 · 블록 | 부수효과 (출구) |
| 4 | stop: 자동 표시 비교 | 표시, 지금 표 → 판정 건너뜀 여부 | 순수 판단 + 읽기 |
| 5 | scv_pr_base_branch | 에픽, 설정, 기본 → 대상 브랜치 | 순수 |
| 6 | scv_pr_stray_changes | porcelain, 허용 경로 → 멈출 목록 | 순수 |
| 7 | PR 도구: 스테이징 · 멈춤 · 푸시 · 생성 | 판정 → git · gh 동작 | 부수효과 (출구) |

- 부수효과 위치: 훅 입력 읽기, 표시 · 표 파일 쓰기, git 상태 읽기, 스테이징 · 커밋 · 푸시 · gh 호출 — 모두 입구 · 출구.
- 재사용: 턴 표 · 등록 파일 · 종료 판정 함수(`scv_mp_stop_gate`), 호스트 설정 읽기, 설정 읽기(`env_load`), PR 도구의 기존 흐름.

## Guardrails

- 사람 입력 흐름은 그대로 — 모델별 프롬프팅 검사 T20~T31 과 기존 훅 · 가드 검사가 그대로 통과해야 한다.
- 매 턴 스택 수치를 늘리지 않는다 — 판별 · 건너뛰기는 훅 출력을 더하지 않는다.
- 호스트 중립 — 코어 소스 · 검사에 호스트 알림 모양을 적지 않는다. 검사 픽스처는 중립 머리말(예: `<machine-event>`)을 쓴다.
- 엄격 모드 훅의 새 변수에는 기본값을 붙이고, 변수를 비운 채로도 검사한다(교훈 2026-09-28).
- 순수부에 꺾쇠를 글자로 쓰지 않는다 — 순수성 검사가 리다이렉션으로 본다(교훈 2026-09-30).
- PR 도구가 멈출 때는 아무것도 커밋 · 푸시 · 생성하지 않는다.
- 도움말 답 모양 절 · 라우터 다이어트 고정 절은 건드리지 않는다(2026-09-16 잠금).

## Exit criteria

- TESTS.md 전 시나리오 통과, 맥 · 리눅스 CI 로그에서 새 검사 줄을 각각 확인, 코덱스 사본의 코어 검사 전부 통과.
- 코어 0.63.0 태그 · 릴리스, 두 래퍼 동기화 PR 병합, 두 래퍼 CI 에 README 검사 연결(루트 README 실행 조건 포함), 클로드 래퍼
  호스트 설정에 알림 머리말, 두 래퍼 릴리스.
- 설치본 실측: 사람 턴의 등록 결과에 원칙 표식 · 전문이 보이고, 배경 작업 알림 턴에는 등록 요구가 없다.

## Suggested path

1. 호스트 설정 키(기본값 · 계약 문서 · 예시), 순수 판별 함수, `kind` 하위 명령.
2. `prompt --auto` 의 자동 표시, 사람 턴의 표시 지우기, 종료 훅의 건너뛰기.
3. 매 턴 훅: 자동이면 표시만 남기고 앞단 블록 · 횟수 · 예약 경고 소비를 건너뜀.
4. PR 도구: 대상 브랜치 순수 함수 + 설정, 커밋 범위 점검 + SCV 폴더 스테이징, 작업 규약 9d 한 줄.
5. 이 저장소 설정 `SCV_PR_BASE=develop`, 설정 예시 · 템플릿 지문.
6. 검사 — 두 bash, 코덱스 사본, 전체.
7. VERSION 0.63.0 · CHANGELOG → PR → 병합 → 코어 릴리스.
8. 래퍼: 동기화 PR 병합 → README 검사 CI + 클로드 호스트 설정 머리말 → 래퍼 릴리스 → 설치본 실측.

## Related Documents

- 대화: `scv/conversations/20261001-083005-auto-turns-pr-base-fixes.md`
- 앞선 계획: `scv/archive/20260930-wookiya1364-rewrite-direct-feedback-principle/` (같은 릴리스에 실림)

## Risks / Open Questions

- 호스트의 알림 모양이 바뀌면 판별이 안 되어 지금처럼 동작한다 — 안전한 쪽으로 실패(추정).
- 사람이 머리말로 시작하는 글을 직접 붙여 넣으면 자동 턴으로 판별된다 — 드물다(추정). 그 턴은 등록 없이 지나간다.
- PR 도구가 새로 멈추는 경우: 구현을 커밋하지 않고 PR 을 만들던 흐름 — 목록과 할 일을 보여 준다.
- SCV 폴더 전체 스테이징: 무시 목록 밖에 커밋하면 안 되는 파일이 있으면 함께 올라간다 — 기록 계약(SCV 기록은 모두 커밋) 기준이며,
  템플릿 무시 목록이 비밀 파일을 거르는지 구현 때 확인한다.
- 코덱스는 알림 모양을 몰라 판별하지 않는다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
