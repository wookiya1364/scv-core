---
title: 지시 다이어트 — 매 턴 글 14.5KB → 9KB, 충돌 3 정리, 검사 3 추가
slug: 20261102-wookiya1364-instruction-diet
author: wookiya1364
created_at: 2026-11-02
status: testing
kind: refactor
lang: korean
tags: [writing, size-budget]
raw_sources:
  - scv/conversations/20261102-182255-writing-style-bullets.md
refs: []
invariants:
  - "0.76.0 릴리스와 동작 · 규칙 뜻이 같다 — 시험이 고정한 행동은 그대로 통과"
  - "선택 창 규칙 · 다시 쓴 요청 맨 위 · 답 모양 검사 유지"
---

# 지시 다이어트 — 매 턴 글 14.5KB → 9KB, 충돌 3 정리, 검사 3 추가

## Summary

지시가 줄지 않고 늘어난다(확인 — 도움말 합계 0.50 30,775 → 0.76 33,022, 전체 규약 · 계약 238K → 315K). 규칙마다 쌓인
'왜 · 날짜 · 실측' 이력과 '여기 보라' 거듭 문장을 걷어 내고, 같은 계획에서 충돌 3곳을 고치고 검사 3개를 더한다.
줄인 뒤에도 0.76.0 과 동작 · 규칙 뜻은 같다(사용자 조건).

## Goals / Non-Goals

- **Goals**
  - 매 턴 실리는 글(훅 약 4.1KB + 도움말 본문 7.5KB + 원칙 전문 2.9KB ≈ 14.5KB)을 9KB 이하로 — 2026-11-02 측정 뒤 사용자 결정
  - ① 쉬운 말 절은 규약마다 한 줄 가리키기(본문은 매 턴 훅과 `contracts/writing.md`) ② 원칙 전문은 세션 첫 등록과 도움말 다시 읽기 때만,
    그 외엔 표식 한 줄 ③ '이 턴의 첫 행동' 안내 줄이기 ④ 도움말 답 모양 절 정리 ⑤ 실체 보여 주기 안내 줄이기
  - 충돌 3: 번호 vs 불릿 경계, 항목 표 vs 해결책 표 쓰임, 앱 마무리 상자 vs 선택 창
  - 검사 3: 답 언어(설정 언어와 답 글자) · 크기 여유(코어에서 상한-100B) · 맥 훅 속도(측정 후 결정)
- **Non-Goals**
  - 규칙 뜻 · 동작 변경
  - 래퍼 고유 파일
  - 결정 기록에 없는 근거 지우기

## Approach Overview

1. 날짜 · 버전이 든 줄을 모아 결정 기록과 대조 — 있는 것만 본문에서 지움.
2. 같은 요구를 다시 쓴 곳을 찾아 한 줄 가리키기로.
3. `contracts/writing.md` 에 번호 · 표 쓰임 한 줄씩, `contracts/choices.md` 에 앱 상자 한 줄.
4. 답 검사에 `lang-mismatch`(설정 언어 korean 인데 코드 블록 · 인용 밖 한글 비율이 낮음).
5. `test-help-budget.sh` 에 코어 여유 검사(코어 저장소에서 합계 > 상한-100 이면 실패).
6. 맥 훅 지연을 여러 번 재 보고 상한을 정함(사용자 결정).

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  answer_text_outside_code,  // 답 → 코드 블록 · 인용 밖 글
  hangul_ratio,              // 글 → 한글 글자 비율(0~100)
  lang_verdict,              // 비율 + 설정 언어 → 위반 줄 | 없음
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | answer_text_outside_code | 코드 블록 · 인용 줄을 뺀 글만 남김 | 답 → 글 | 순수 |
| 2 | hangul_ratio | 글자 중 한글 비율을 셈 | 글 → 정수 | 순수 |
| 3 | lang_verdict | 설정이 korean 이고 비율이 낮으면 위반 | 비율 · 언어 → 위반 줄 | 순수 |
| 4 | 종료 훅 | 위반을 다음 턴 경고로 | 위반 → 경고 파일 | 부수효과 (출구) |

- 부수효과 위치: 종료 훅의 기존 경고 경로 그대로
- 재사용: `scv_answer_lint` 의 코드 블록 건너뛰기, `scv_drift_decide`

## Guardrails

- 0.76.0 과 동작 · 규칙 뜻이 같다 — 기존 시험은 기대값을 바꾸지 않고 통과(문구 고정 시험의 지문만 갱신)
- 지우는 이력은 결정 기록 · 보관 계획에 있는 것만
- 새 검사는 경고만(턴을 막지 않음)
- 맥 · 리눅스 같은 결과, 크기 예산 지킴

## Exit criteria

- All TESTS.md scenarios pass
- 매 턴 글(같은 측정 방식) ≤ 10,500B(0.76.0 14,823B — 사용자 결정 2026-11-02: 9KB 목표는 안내를 약하게 해 10.1KB 에서 멈춤), 도움말 합계 < 33,022
- 코어 회귀 · codex 사본 코어 시험 통과

## Suggested path

1. 이력 · 거듭 문장 걷어 내기, 문구 고정 시험 지문 갱신 — 규약 · 계약 본문을 줄임
2. 충돌 3곳 문구 — 글쓰기 · 선택지 계약에 한 줄씩
3. 답 언어 검사 — `answer_text_outside_code`, `hangul_ratio`, `lang_verdict`, `종료 훅`
4. 크기 여유 검사와 맥 훅 속도 측정 — 시험 상한 정리
5. 시험 · 회귀 · codex 사본 — 동작이 0.76.0 과 같은지 확인

## Related Documents

- `core/contracts/writing.md`, `core/contracts/choices.md`, `core/contracts/rewrite-principle.md`, `core/protocols/help.md`
- `core/scripts/lib/help-state.sh`, `core/tests/test-help-budget.sh`, `core/tests/test-dreams.sh`

## Risks / Open Questions

- 이력을 지우면 '왜'를 찾으러 결정 기록을 열어야 함 — 본문에 결정 이름 한 줄은 남길지 구현 때 판단
- 한글 비율 문턱은 추정값 — 코드 이름이 많은 한국어 답에서 오탐이 없게 낮게 잡음
- 맥 훅 지연은 CI 기계 상태에 따라 흔들림 — 상한은 측정값으로 정함

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
