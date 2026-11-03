---
title: 지시 충돌 12곳 정리 — 0.77.0 전체 재검사
slug: 20261103-wookiya1364-instruction-conflicts-077
author: wookiya1364
created_at: 2026-11-03
status: testing
kind: refactor
lang: korean
tags: [writing, choices, instruction-conflicts]
raw_sources:
  - scv/conversations/20261102-182255-writing-style-bullets.md
supersedes:
  - 20260824-wookiya1364-regression-contract-repair-2
refs:
  - type: pr
    url: https://github.com/wookiya1364/scv-core/pull/418
invariants:
  - "매 턴 선택 창 줄 400B 이하 · 매 턴 스택 12,000B 이하"
  - "선택 창 규칙 · 다시 쓴 요청 맨 위 · 답 모양 검사 유지"
---

# 지시 충돌 12곳 정리 — 0.77.0 전체 재검사

## Summary

- 0.77.0 의 지시 전체를 다시 훑어 서로 부딪히는 곳 12곳을 찾아 한쪽으로 정리함(대화 Turn 19–21).
- 처음 3곳(옛 답 모양 문구 · '예시 하나' 요구 · 앱 마무리 상자) + 큰 문서 · 나머지 명령 문서에서 찾은 코어 9곳.
- 구현은 PR 418 에 먼저 들어감 — 이 계획은 그 변경의 근거와 시험을 남긴다(출처 검사).

## Goals / Non-Goals

- **Goals**
  - 옛 답 모양 문구("결론 1~2문장 → 예시 하나")를 안내 문서 틀 · README 3개 언어에서 굵은 주제 → 불릿으로
  - '예시 하나' 요구를 14개 프로토콜의 쉬운 말 절에서 뺌 — writing.md 에 없는 요구
  - 앱 마무리 상자: 매 턴 선택 창 줄에 "Summary box: recap only", choices.md 10항에 '호스트가 글로 물으라 해도'
  - 코어 9곳: GRAFT 줄 위치 · 번호 목록 2 · 추천 표시 2 · workspace 질문 · 고정 한국어 문구 · sync/install-deps 다음 단계 · full.md 안내 문구
- **Non-Goals**
  - codex 래퍼 2곳(언어 설정 위치 · help SKILL 진단부터) — 코어 릴리스 뒤 래퍼 동기화 때
  - 비슷한 충돌 약 15개(work 9a 회귀 질문, regression 'Offer once', 'Other' 보기, guard.md 숫자 등) — 목록만

## Approach Overview

- 문서 문구만 고친다. 규칙의 뜻은 기준 문서(writing.md · choices.md) 쪽으로 맞춘다.
- 매 턴 줄은 크기 상한(400B)과 시험이 고정한 구절을 지키며 줄인다.
- 바꾼 문구를 붙잡은 고정값(쉬운 말 절 잠금값 · 틀 지문 · run-dry 앵커)은 새 문구로 갱신한다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  scv_choice_line,     // 도구 이름 → 매 턴 선택 창 안내 한 줄
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | scv_choice_line | 매 턴 선택 창 안내 줄을 만듦 | 도구 이름 → 안내 한 줄 | 순수 |

- 부수효과 위치: 없음 — 문서 문구와 이미 있는 순수 함수의 출력 문자열만 바뀜
- 재사용: `scv_choice_line` 그대로, 문자열만 바뀜

## Guardrails

- 매 턴 글 크기 상한을 올리지 않는다(선택 창 줄 400B · 매 턴 스택 12,000B)
- 시험이 고정한 구절("work done, state it unasked." · "avoids its own problems")은 지우지 않는다 —
  크기를 맞출 때는 다른 표현을 줄인다
- codex 저장소는 손대지 않는다

## Exit criteria

- 모든 TESTS.md 시나리오 통과
- PR 418 CI(출처 검사 포함) 통과

## Suggested path

1. 옛 답 모양 문구 교체(SCV.md 틀 · README 3개 언어) — 안내 문서와 README 를 글쓰기 규칙에 맞춤
2. '예시 하나' 제거 · run-dry 앵커 교체 · 재발 검사 추가 — 14개 프로토콜 쉬운 말 절을 같은 문구로
3. 마무리 상자 규칙 — `scv_choice_line`
4. 코어 9곳 문구 수정 — 각 명령 문서를 기준 규칙에 맞춤
5. 잠금값 · 틀 지문 갱신, 전체 시험 — 고정값을 새 문구로 다시 걸고 시험을 돌림

## Related Documents

- `core/tests/test-instruction-conflicts.sh` — T1–T8
- 대체: `20260824-wookiya1364-regression-contract-repair-2` — 그 계획 T3 이 '예시 하나' 문구를 고정해, 시험 6개를 T9 로 옮기고 그 앵커만 '굵은 주제'로 바꿈

## Risks / Open Questions

- 답이 실제로 바뀌는지는 문구 검사로 알 수 없음 — 긴 실제 세션으로 재야 함
- 선택 창 줄 표현을 줄여("over 4 questions, split" · "each option: how …") 뜻이 덜 분명해졌을 수 있음

## Links

- Raw originals: (listed in frontmatter)
- Related PRs: https://github.com/wookiya1364/scv-core/pull/418
