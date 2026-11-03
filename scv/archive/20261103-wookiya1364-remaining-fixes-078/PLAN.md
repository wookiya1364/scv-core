---
title: 남은 문제 6개 정리 — 등록 위치 · 막힌 뒤 답 · 중간 보고 언어 · 가이드 경로 · codex 모델 정책 · 비슷한 충돌
slug: 20261103-wookiya1364-remaining-fixes-078
author: wookiya1364
created_at: 2026-11-03
status: testing
kind: refactor
lang: korean
tags: [hooks, writing, choices, codex]
raw_sources:
  - scv/conversations/20261102-182255-writing-style-bullets.md
refs: []
invariants:
  - "매 턴 선택 창 줄 400B 이하 · 매 턴 스택 12,000B 이하"
  - "저장소 폴더에서의 등록 · 종료 판정 동작은 그대로"
---

# 남은 문제 6개 정리

## Summary

- 0.78.0 릴리스 직전, 오늘 겪거나 찾은 남은 문제 6개를 모두 고친 뒤 한 번에 릴리스하기로 함(사용자 결정, 대화 Turn 32).
- ① 등록이 프로젝트 밖에서 실행돼도 조용히 '턴 ?'으로 저장됨 → 답이 두 번 나감 ② 종료 훅이 막은 뒤 다시 쓰는 답이 앞 답을 통째로 되풀이 ③ 답 언어 검사가 마지막 답만 봐서 중간 보고의 영어를 못 잡음 ④ 훅이 저장된 옛 설치본의 가이드 경로를 보여 줌 ⑤ codex 모델 정책이 옛 위치(.env)에서 읽음 ⑥ 비슷한 충돌 약 15개.

## Goals / Non-Goals

- **Goals**
  - ① 등록: 현재 폴더에 `scv/` 가 없으면 저장하지 않고 오류 한 줄로 끝냄
  - ② 종료 훅이 막을 때 이유 끝에 "앞 답은 이미 화면에 있음 — 고친 부분만" 한 줄
  - ③ 답 언어 검사가 턴 전체 글(중간 보고 포함)을 봄
  - ④ 가이드 경로는 지금 설치본 기준으로 다시 만듦
  - ⑤ codex 모델 정책은 `scv/scv_settings.json` 에서 읽음(codex 저장소)
  - ⑥ 비슷한 충돌을 하나씩 확인해 진짜 충돌만 고치고, 아닌 것은 이유를 남김
- **Non-Goals**
  - 매 턴 글 크기 상한 올리기
  - 새 기능

## Approach Overview

- ① · ③ · ④ 는 스크립트의 판정 · 조립 함수에, ② 는 종료 훅의 막는 이유 조립에 한 줄.
- ⑥ 은 문서 문구만, 기준 문서(writing · choices) 쪽으로 맞춤.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  scv_lang_turn_text,     // 턴 기록 → 언어를 볼 글(중간 보고 포함)
  scv_lint_lang_verdict,  // 언어 · 비율 · 글자 수 → 위반 줄
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | scv_lang_turn_text | 언어 검사에 쓸 글을 턴 전체에서 고름 | 마지막 답 · 턴 글 → 볼 글 | 순수 |
| 2 | scv_lint_lang_verdict | 한국어 설정인데 한글이 적으면 위반 | 언어 · 비율 · 글자 수 → 위반 줄 | 순수 |
| 3 | register 입구 | 프로젝트 폴더인지 확인 | 현재 폴더 → 계속 · 거절 | 부수효과 (입구) |
| 4 | 가이드 경로 조립 | 저장된 경로를 지금 설치본 기준으로 | 저장 경로 · 설치본 뿌리 → 경로 | 순수 |

- 부수효과 위치: register 의 파일 저장, 종료 훅의 출력
- 재사용: `scv_lint_hangul_ratio` · `scv_lint_lang_verdict`(0.77.0) 그대로

## Guardrails

- 매 턴 선택 창 줄 400B · 매 턴 스택 12,000B 를 넘지 않는다
- 저장소 폴더에서 하는 등록 · 시험이 쓰는 등록은 그대로 동작한다
- 보관된 계획의 본문은 고치지 않는다

## Exit criteria

- 모든 TESTS.md 시나리오 통과(문제마다 고치기 전 실패 → 고친 뒤 통과)
- 코어 전체 시험 · 회귀 · codex 사본 코어 시험 통과

## Suggested path

1. ① 등록 입구 확인 — `register 입구`
2. ② 막는 이유에 한 줄 — 종료 훅의 막는 이유 끝에 안내를 붙임
3. ③ 언어 검사 범위 — `scv_lang_turn_text`, `scv_lint_lang_verdict`
4. ④ 가이드 경로 — `가이드 경로 조립`
5. ⑥ 비슷한 충돌 확인 · 수정 — 문서 문구를 기준 규칙에 맞춤
6. ⑤ codex 모델 정책 — codex 저장소의 스크립트와 문서를 설정 파일 기준으로
7. 전체 시험 · 회귀 · codex 사본 — 모든 시험을 돌려 확인

## Risks / Open Questions

- ③ 턴 전체 글에는 도구 출력이 섞이지 않게 해야 함(사용자에게 보인 글만)
- ⑥ 의 '충돌 아님' 판단은 근거를 계획 보관 기록에 남김

## Links

- Raw originals: (listed in frontmatter)
