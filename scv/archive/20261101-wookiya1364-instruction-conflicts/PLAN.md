---
title: SCV 지침 충돌 11곳 정리
slug: 20261101-wookiya1364-instruction-conflicts
author: wookiya1364
created_at: 2026-11-01
status: testing
kind: refactor
lang: korean
tags: [rules, contracts, protocols]
raw_sources:
  - scv/conversations/20261101-003000-pure-function-catalog-reuse.md
refs: []
invariants:
  - "기존 시험 전부 통과 — 지침 글만 바꾸고 동작은 답 모양 검사 한 곳만 바꾼다"
  - "우선순위 규칙(최상위 규칙의 해결 순서)은 한 곳에만 적힌다"
---

# SCV 지침 충돌 11곳 정리

## Summary

SCV 가 모델에게 주는 지침 안에서 같은 순간에 반대로 요구하는 11곳을, 사용자가 확정한 방향(2026-11-01, 대화 Turn 36 · 선택 창 '추천대로 확정')으로 하나씩 맞춘다. 문구만 낡은 6곳도 함께 정리하고, 기계로 잴 수 있는 1번(첫 문장 검사)에는 시험을 더한다.

## Goals / Non-Goals

- **Goals**
  - 아래 표의 11곳이 각각 한쪽으로 정해지고, 다른 쪽 글이 그 결정을 가리키거나 예외로 적는다.
  - 첫 문장 검사가 맨 위 '이렇게 이해하고 일함' 줄을 건너뛰고 그다음 문단을 센다.
  - 낡은 문구 6곳 정리.
- **Non-Goals**
  - 새 규칙 추가 · 규칙 뜻 바꾸기(표의 방향 밖).
  - 문장 뜻을 비교하는 자동 검사(잘못 걸리기 쉬워 넣지 않음 — 사용자 결정).
  - 래퍼(claude · codex) 저장소 직접 수정 — 릴리스 동기화로 전달.

## Approach Overview

| # | 충돌 | 정한 방향 | 고칠 곳(원문 확인) |
|---|---|---|---|
| 1 | 첫 문장 2개 vs 맨 위 한 줄 | 맨 위 줄은 셈에서 빼고 다음 문단을 셈 | 답 모양 검사(help-state 라이브러리), prompt-refine 5단계에 한 줄 |
| 2 | 코드 값 금지 vs 다시 쓴 요청 인용 | 인용 블록은 예외 | 쉬운 말 절(help 와 각 프로토콜 사본), prompt-refine |
| 3 | 사용자에게 양보(최상위 7) vs 해로운 변경 거부 | 최상위 7에 '해로운 변경은 한 번 묻는다' 예외 | SCV.md 최상위 규칙, rewrite-principle 의 자기 우선순위 문장 |
| 4 | 보관 검색 끝 글 질문 vs 글 질문 금지 | 선택 창으로 | archive-search 6단계, choices 대체 목록 |
| 5 | 실행 결과 확인 vs 한 턴 질문 하나 | 확인 질문 우선, 나머지는 다음 턴 | show-real, help 한 모양 규칙 |
| 6 | 짧은 턴: 파일 열기 vs 안 열기 | 열지 않고 일지 한 줄 | help.md 첫 절(엉뚱한 문장 포함), full.md B0 |
| 7 | 첫 결과 확인 vs 묻지 말고 진행 | 첫 결과 확인을 묻는 예외 목록에 | choices 8, work 5c 확인 지점 |
| 8 | 보관 불변 vs 색인 · 기획서 다시 씀 | 기계가 다시 만드는 파일은 불변 대상 밖 | SCV.md 2, boundaries 3, regression 의 '아무것도 안 건드림' |
| 9 | 한 칸씩 확인 vs 묶어 묻기 | 묶어 묻기 허용, 답 없이 채우기만 금지 | SCV.md 1 |
| 10 | 범위 밖 금지 vs 묻고 진행 | 묻지 않고는 고치지 않음, 지우기 · 옮기기 금지 | codegen 금지 목록 · 7단계, boundaries 1 |
| 11 | 커밋 · 푸시 금지 vs handoff 표시 푸시 | 동의 받은 handoff 표시만 예외 | promote 금지 목록 |

낡은 문구 6곳: SCV.md '스스로 우선순위를 말하지 않는다' vs 해결 순서 (4) '대체를 선언' 문구 맞춤 · full.md '[1] 기본' → '추천' · promote 금지 목록의 raw 이동(정해진 consume 예외 빠짐) · regression '실패마다 질문' 잔재 · work '기본 Yes' → '추천' · deck 언어 순서(만드는 쪽마다 다름)를 한 순서로.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

지침 글 수정은 파이프라인이 없다. 코드가 바뀌는 곳은 1번 답 모양 검사 하나다.

```
flow(
  scv_lint_skip_top_line,   // 답 본문 → 맨 위 '이렇게 이해하고 일함' 줄을 뺀 본문
  scv_answer_lint,          // 본문, 상한 → 위반 줄들 (기존 함수 그대로)
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | scv_lint_skip_top_line | 첫 비어 있지 않은 줄이 맨 위 이해 줄이면 그 줄(과 뒤 빈 줄)을 뺀다 | 답 본문 → 본문 | 순수 |
| 2 | scv_answer_lint | 첫 문단 문장 수 · 코드값 · 결정 표 추천 칸 검사 | 본문, 상한 → 위반 줄들 | 순수 |

- 부수효과 위치: help-state 의 stop 처리(본문 읽기 · 기록 쓰기) — 바뀌지 않음.
- 재사용: scv_answer_lint, scv_lint_strip_quoted 그대로. 사전(순수함수 사전) 먼저 찾아 같은 일 하는 함수가 있으면 그걸 쓴다.

## Guardrails

- 표의 방향 밖으로 규칙 뜻을 바꾸지 않는다. 애매하면 멈추고 묻는다.
- 해결 순서(우선순위)는 SCV.md 한 곳에만 적는다 — 다른 글은 가리키기만.
- 맨 위 줄 판별은 영어 'Understood as:' 와 한국어 '이렇게 이해하고 일함:' 둘 다(해석된 언어 따라).
- 맥(bash 3.2 · BSD) · 리눅스 둘 다 통과.
- 쉬운 말 절 사본들은 시험(test-guidance 등)이 같다고 검사하면 모두 같이 바꾼다.

## Exit criteria

- All TESTS.md scenarios pass
- 지침 충돌 조사(앞선 두 읽기 전용 조사와 같은 질문)를 다시 돌려 '실제 충돌' 0 — 새로 나온 것은 따로 보고.
- 코어 시험 전체(회귀 포함) 통과.

## Suggested path

1. 첫 문장 검사에 맨 위 줄 건너뛰기를 넣고 시험부터(빨강 → 초록) — `scv_lint_skip_top_line`, `scv_answer_lint`
2. 최상위 규칙(SCV.md) 1 · 2 · 7 과 해결 순서 문구 고침 — 3 · 8 · 9번과 낡은 문구 1곳 반영
3. 계약 글(choices · show-real · boundaries · rewrite-principle · recording) 고침 — 4 · 5 · 7 · 8 · 10번 반영
4. 프로토콜 글(help · full · prompt-refine · archive-search · work · codegen · promote · regression · deck) 고침 — 2 · 4 · 6 · 10 · 11번과 낡은 문구 반영
5. 시험 전체 · 충돌 재조사 — 남은 충돌 0 확인

## Related Documents

- 대화 기록 Turn 34–36 (raw_sources) — 11곳의 원문 위치와 설명.

## Risks / Open Questions

- 쉬운 말 절이 프로토콜 16곳에 복사돼 있다 — 하나만 바꾸면 사본 일치 시험이 실패할 수 있음(추정).
- 3번 예외 문구가 최상위 7을 약하게 읽히게 할 수 있다 — '사용자가 그래도 고르면 그대로'를 같이 적는다.
- 재조사도 모델 판단이라 새 후보가 나올 수 있음 — 나오면 이 계획 밖으로 보고.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
