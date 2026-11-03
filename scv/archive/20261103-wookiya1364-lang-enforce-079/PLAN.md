---
title: 설정 언어 강제 — 최종 답 막기 · 턴 중간 교정 · 매 턴 언어 줄
slug: 20261103-wookiya1364-lang-enforce-079
author: wookiya1364
created_at: 2026-11-03
status: testing
kind: feature
lang: korean
tags: [hooks, language, writing]
raw_sources:
  - scv/conversations/20261102-182255-writing-style-bullets.md
refs: []
invariants:
  - "매 턴 스택 12,000B 이하 · 선택 창 줄 400B 이하"
  - "SCV_LANG 이 비면 지금과 똑같이 동작"
  - "코드 블록 · 인용 · 표 · 경로 · 이름은 언어 검사에서 빠짐(0.78.0 규칙 그대로)"
---

# 설정 언어 강제

## Summary

- slay 세션은 SCV_LANG=korean 인데도 긴 작업 중 중간 보고를 영어로 씀(대화 Turn 38, 확인 — 세션 기록에 영어 최대 35줄 감지).
- 원인 세 가지(확인): ① 매 턴 훅에 언어 규칙 줄이 없음 ② 언어 검사는 턴이 끝난 뒤 다음 턴 경고만 하고 막지 않으며, 경고 문구에 언어 이름이 없음 ③ 중간 보고는 이미 화면에 나간 뒤라 되돌릴 수 없음.
- 사용자 결정: "설정한 언어에 맞는 출력을 하도록 강제해야 한다".

## Goals / Non-Goals

- **Goals**
  - 매 턴 훅 첫 줄에 설정 언어로 쓴 언어 규칙 한 줄(중간 보고 포함)
  - 턴 중간 교정: 도구를 쓸 때마다 그 사이 새로 쓴 글을 검사 → 다른 언어 줄이 있으면 바로 교정 문구 주입(claude)
  - 끝낼 때: 최종 답이 어긋나면 막고 고친 부분만 다시 쓰게 함 / 중간 보고만 어긋났으면 막지 않고 다음 턴 경고에 언어 이름을 넣음
  - claude 래퍼 hooks.json 에 새 PostToolUse 등록(코어 릴리스 뒤)
- **Non-Goals**
  - 이미 화면에 나간 문장 되돌리기(불가)
  - 코드 · 경로 · 이름 번역
  - codex 의 턴 중간 교정(도구 뒤 훅 없음 — 1 · 3만 적용)

## Approach Overview

- 판정은 0.78.0 의 `scv_lint_lang_turn`(줄 단위, 코드 · 인용 · 표 제외, 40자 이상 줄만)을 그대로 씀.
- 새 순수 함수가 "언어 → 규칙 줄", "턴 글 + 지난 검사 위치 → 새 글", "어긋난 줄 수 → 교정 문구", "최종 답 · 중간 어긋남 → 막기 / 경고 / 통과"를 맡음.
- 새 훅 하나(도구 뒤)가 원본에서 이번 턴 글을 읽고, 지난 검사 위치를 턴 폴더에 남김. 교정은 같은 턴에 한 번만이 아니라 새 영어 글이 생길 때마다.
- 종료 훅은 지금의 "막기 한 번" 규칙(stop-gates)을 따름 — 언어로 이미 한 번 막았으면 다시 막지 않고 경고로 넘김(무한 반복 방지).

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  scv_lang_rule_line,     // 언어 → 규칙 한 줄
  scv_lang_new_text,      // 턴 글 + 지난 위치 → 새 글 + 새 위치
  scv_lint_lang_turn,     // 새 글 → 어긋난 줄 수 (재사용)
  scv_lang_fix_note,      // 언어 + 줄 수 → 교정 문구
  scv_lang_stop_decide,   // 최종 답 줄 수 + 중간 줄 수 + 이미 막음 → block|warn|ok
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | scv_lang_rule_line | 설정 언어로 쓴 규칙 한 줄을 만듦 | 언어 → 한 줄(빈 언어면 빈 값) | 순수 |
| 2 | scv_lang_new_text | 지난 검사 뒤 새로 쓴 글만 잘라냄 | 턴 글 · 지난 위치 → 새 글 · 새 위치 | 순수 |
| 3 | scv_lint_lang_turn | 다른 언어 줄을 셈(재사용) | 글 · 언어 → lang-mismatch-lines=N | 순수 |
| 4 | scv_lang_fix_note | 언어 이름을 넣은 교정 문구를 만듦 | 언어 · N → 문구 | 순수 |
| 5 | scv_lang_stop_decide | 끝낼 때 막을지 경고할지 정함 | 최종 N · 중간 N · 이미 막음 → block/warn/ok | 순수 |
| 6 | on-lang-check.sh | 도구 뒤 원본 읽고 교정 주입 · 위치 기록 | 훅 입력 → additionalContext | 부수효과 (입구/출구) |
| 7 | on-stop.sh · on-user-prompt.sh | 기존 훅에 5 · 1 연결 | 훅 입력 → 막기 이유 / 매 턴 줄 | 부수효과 (입구/출구) |

- 부수효과 위치: 6 · 7 (원본 transcript 읽기, 턴 폴더에 위치 쓰기, 훅 출력)
- 재사용: `scv_lint_lang_turn`, `scv_turn_slice`, stop-gates 의 "한 번만 막기"

## Guardrails

- SCV_LANG 이 비었거나 english 면 새 동작 없음
- 사용자가 이 턴에 다른 언어를 요청했거나 다른 언어로 썼으면 강제하지 않음(Top-level rules 7조 — 충돌 점검에서 찾음)
- 계획 · 커밋 같은 파일 언어는 SCV_PROMOTE_LANG · lang: 규칙 그대로 — 언어 줄은 사용자에게 보이는 글만 말함
- 매 턴 스택 · 선택 창 줄 예산을 넘기지 않음(test-help-budget)
- 언어로 막는 것은 한 턴에 한 번 — 다시 쓴 답도 어긋나면 경고로 넘김
- 새 훅은 실패해도 아무것도 막지 않음(exit 0)
- 코어에 호스트 이름을 넣지 않음(test-host-neutral)

## Exit criteria

- TESTS.md T1–T7 통과, 전체 점검 · 예산 · 호스트 중립 시험 통과
- 실제 재현(T7): 긴 작업 headless 세션에서 영어 중간 보고 줄 수가 고치기 전보다 줄어듦 — 수치로 보고

## Suggested path

1. 언어 규칙 줄을 매 턴 훅에 넣기 — `scv_lang_rule_line`
2. 새 글 자르기 · 교정 문구 · 도구 뒤 훅 — `scv_lang_new_text`, `scv_lang_fix_note`, `on-lang-check.sh`
3. 끝낼 때 막기 / 경고 판정을 종료 훅에 연결 — `scv_lang_stop_decide`, `on-stop.sh · on-user-prompt.sh`
4. 시험 T1–T6 작성 · 실행 — 단위 · 훅 시험을 돌림
5. 실제 재현 T7 — 긴 작업 세션을 고치기 전후로 돌려 영어 줄 수를 비교함
6. claude 래퍼 hooks.json 등록 — 코어 릴리스 뒤 래퍼에 새 훅을 연결함

## Related Documents

- `core/contracts/writing.md`, `core/contracts/choices.md`(7항 한 번만 막기)

## Risks / Open Questions

- 도구 뒤 훅이 원본을 매번 읽어 느려질 수 있음 — 새 글만 잘라 64KB 상한, 시간은 T6 에서 잼
- 막힌 뒤 다시 쓴 답이 또 나가 "답 두 번" 처럼 보일 수 있음 — "고친 부분만" 문구(0.78.0) 재사용

## Links

- Raw originals: (frontmatter)
