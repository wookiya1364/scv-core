---
title: 답 모양 — 굵은 주제 + 두괄식 개조식 불릿, 다시 쓴 요청은 맨 위
slug: 20261102-wookiya1364-answer-bullets
author: wookiya1364
created_at: 2026-11-02
status: testing
kind: feature
lang: korean
tags: [writing, answer-shape]
raw_sources:
  - scv/conversations/20261102-182255-writing-style-bullets.md
refs: []
invariants:
  - "선택 창 규칙(결정은 선택 창으로) 유지"
  - "비교가 필요할 때 단위 표 사용 유지"
  - "SCV_PLAIN_LANGUAGE=off 로 끌 수 있음 유지"
---

# 답 모양 — 굵은 주제 + 두괄식 개조식 불릿, 다시 쓴 요청은 맨 위

## Summary

사용자가 답을 빨리 이해하지 못한다 — 낯선 말 · 맥락 없는 새 말 · 줄글 문단 때문. 답을 '굵은 주제 → 첫 불릿에 결과(두괄식)
→ 개조식 풀이'로 바꾸고, 다시 쓴 요청을 답 맨 위로 올린다. 지금 답 검사는 목록으로 시작하면 위반으로 잡아 오히려 줄글을 민다.

## Goals / Non-Goals

- **Goals**
  - 답 모양: 굵은 주제 줄 → 바로 밑 첫 불릿은 결과(두괄식) → 다음 불릿들이 풀이
  - 불릿 끝맺음은 개조식 '~함 · ~임'(질문 문장만 예외)
  - 낯선 말 금지 — 새 말은 처음 나온 줄에서 풀어 쓰고, 사용자가 쓴 말을 그대로 씀
  - 다시 쓴 요청을 답 맨 위 인용 하나로 — '이렇게 이해하고 일함' 줄은 겹쳐서 없앰
  - 답 검사: '목록 시작 = 위반' 폐지, 긴 줄글 문단 · '~습니다' 불릿 · 맨 위 아닌 다시 쓴 요청을 위반으로
  - SCV가 답에 넣는 낯선 이름(단위 표 · 원칙 태그 등)을 쉬운 이름으로
- **Non-Goals**
  - 낯선 단어를 기계로 판별 — 불가, 지시로만
  - 단위 표 폐지 — 비교에는 표 유지
  - README 길이 숫자 변경

## Approach Overview

1. 글 모양 규약(`core/contracts/writing.md`) 규칙 1을 새 답 모양으로, 낯선 말 규칙 추가. 본문은 여기 한 곳.
2. 매 턴 안내(`on-user-prompt.sh` plain language)와 각 규약의 'Plain language first' 절이 새 모양을 말하고 규약을 가리킴.
3. 다시 쓴 요청 보임 규칙(`prompt-refine.md`, `lib/model-prompting.sh` 판정 · 안내 문구): 맨 위 인용 하나.
4. 답 검사(`lib/help-state.sh scv_answer_lint`): lead-missing 폐지, 새 위반 추가.
5. 원칙 태그 · 단위 표 이름 정리(`rewrite-principle.md` 등).
6. 코어 릴리스 → 두 래퍼 동기화 · 릴리스.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  answer_blocks,     // 답 본문 → 덩어리 목록(주제 · 불릿 · 문단 · 표 · 인용)
  check_rewrite_top, // 덩어리 목록 → 위반(다시 쓴 요청이 맨 위 아님)
  check_prose,       // 덩어리 목록 → 위반(긴 줄글 문단)
  check_bullet_end,  // 덩어리 목록 → 위반('~습니다' 등 서술형 불릿)
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | answer_blocks | 답을 덩어리로 나눔(코드 블록 제외) | 답 글 → 덩어리 줄들 | 순수 |
| 2 | check_rewrite_top | 첫 덩어리가 다시 쓴 요청 인용인지 봄 | 덩어리 → 위반 줄 | 순수 |
| 3 | check_prose | 불릿 · 표 아닌 문단이 상한 넘는지 봄 | 덩어리 → 위반 줄 | 순수 |
| 4 | check_bullet_end | 불릿 끝이 서술형인지 봄(물음 예외) | 덩어리 → 위반 줄 | 순수 |
| 5 | 종료 훅 | 위반을 다음 턴 경고로 실음 | 위반 → 경고 파일 | 부수효과 (출구) |

- 부수효과 위치: 종료 훅이 답을 읽고 경고 파일을 씀 — 기존 자리 그대로
- 재사용: `scv_answer_lint` 의 코드 블록 건너뛰기 · 결정표 추천 칸 검사, `scv_drift_decide` 경고 경로

## Guardrails

- 결정은 선택 창으로 — 규칙 · 검사 그대로
- 검사는 경고(다음 턴 규약 다시 싣기)로만 — 턴을 막는 것은 기존 다시 쓴 요청 판정뿐
- 숫자(줄글 문단 상한)는 `lib/writing.sh` 한 곳에
- 크기 예산(help.md · 매 턴 줄)과 템플릿 다이제스트 지킴
- 맥 · 리눅스 같은 결과(글자 수는 글자로 셈)
- 끄기 스위치(`SCV_PLAIN_LANGUAGE=off`) 유지

## Exit criteria

- All TESTS.md scenarios pass
- 이 계획의 대화 기록 다음 턴부터 실제 답이 새 모양으로 나옴(긴 세션에서 확인 — 사용자)
- 코어 회귀 · codex 사본 코어 시험 통과, 두 래퍼 릴리스

## Suggested path

1. 글 모양 규약 · 매 턴 안내 · 각 규약 절 개정 — 새 답 모양과 낯선 말 규칙을 한 곳에 쓰고 가리킴
2. 답 검사 덩어리 나누기와 세 위반 — `answer_blocks`, `check_rewrite_top`, `check_prose`, `check_bullet_end`
3. 다시 쓴 요청 맨 위 판정 · 안내 문구 변경, 이해 한 줄 제거 — `check_rewrite_top`
4. 원칙 태그 · 단위 표 이름 정리 — 답에 들어가는 SCV 말을 쉬운 이름으로
5. 시험 · 크기 예산 · 다이제스트 · 회귀 — 경고 연결은 `종료 훅`

## Related Documents

- `core/contracts/writing.md`, `core/contracts/rewrite-principle.md`, `core/protocols/help/prompt-refine.md`
- `core/scripts/lib/help-state.sh`, `core/scripts/lib/model-prompting.sh`, `core/template/hooks/on-user-prompt.sh`, `core/template/hooks/on-stop.sh`

## Risks / Open Questions

- 이해 한 줄을 없애면 '맨 위 한 줄' 판정(v0.65.0)과 그 시험이 바뀜 — 다시 쓴 요청 판정으로 합침
- 개조식 검사는 근사 — '~습니다' 등 서술형 어미만 잡고, 오탐 비용은 다음 턴 규약 다시 싣기 한 번
- 영어 답에는 개조식 어미 검사가 맞지 않음 — 한국어 답에만 적용

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
