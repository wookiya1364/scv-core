---
title: 글쓰기 8가지 — 읽는 사람이 덜 헤매게, 선택 창은 그대로
slug: 20261102-wookiya1364-writing-guidance
author: wookiya1364
created_at: 2026-11-02
status: testing
kind: feature
lang: korean
tags: [writing, docs, answers]
raw_sources:
  - scv/conversations/20261101-003000-pure-function-catalog-reuse.md
refs:
  - type: link
    url: https://newsletter.pragmaticengineer.com/p/becoming-a-better-writer
  - type: link
    url: https://news.hada.io/topic?id=24348
  - type: link
    url: https://news.hada.io/topic?id=7042
  - type: link
    url: https://news.hada.io/topic?id=36367
invariants:
  - "판 하나에서 사용자에게 묻는 선택 창 수는 늘지 않는다"
  - "README 머메이드 그림은 그대로 둔다(이미지 변환은 취소된 결정)"
  - "계획서 틀의 고정 제목(Summary · Guardrails …)은 도구가 읽는 표식이라 바꾸지 않는다"
---

# 글쓰기 8가지 — 읽는 사람이 덜 헤매게, 선택 창은 그대로

## Summary

글쓰기 글 4편(요지: 결론 먼저 · 좁게 묻기 · 개요 먼저 · 휴대폰 기준)에서 추린 8가지를 SCV 규칙과 검사에 넣는다.
사용자가 확인한 개요 그대로이며, 선택 창 수는 늘리지 않는다 — ⑦의 '개요 확인'이 '다 쓴 뒤 확인'을 대신한다.

## Goals / Non-Goals

- **Goals**
  - ① 시험서 통과 기준에 값 · 문구가 없으면 work 머리말이 경고한다(막지 않음)
  - ④ README 검사가 표 칸 40자 초과 · 긴 문단(휴대폰 한 화면 넘는 분량)을 막는다
  - ② 실물 확인은 결과에서 볼 곳을 짚어 묻는다(보기 수 · 횟수는 그대로)
  - ③ 긴 답은 한 문장 → 한 문단 → '자세히'
  - ⑤ 굵게는 문장 · 줄 머리만, ⑥ 번호 목록 · 남은 일에 맡은 사람, ⑧ 제목에 내용
  - ⑦ promote 는 파일을 쓰기 전에 개요를 보이고 확인받는다 — 그 확인이 폴더 승인이다
- **Non-Goals**
  - 계획서 틀 고정 제목 바꾸기(⑧은 제목 옆 한 줄 요지로)
  - README 그림 이미지 변환(취소됨)
  - 새 선택 창 추가

## Approach Overview

1. 계획 lint(work 머리말 `PLAN_LINK` 와 같은 자리)에 `TESTS_VAGUE:` 경고 — 통과 기준 줄에 숫자 · 백틱 · 따옴표가 하나도 없으면.
2. `tools/check-readme.sh` 에 칸 · 문단 길이 판정 — 코드 블록 · 그림 밖 표 칸 > 40자(표시 폭이 아닌 글자 수), 문단 > 6줄.
3. `contracts/show-real.md` 2: 묻는 말은 결과에서 볼 곳을 짚는다(예: "글자가 다 읽히나요?"), 보기는 계속 · 고칠 점 그대로.
4. 글 모양 규칙은 한 곳(`contracts/writing.md` 새 문서)에 두고, help 답 모양 · promote · work · pr-helper 안내는 그 문서를 가리킨다(같은 요구는 한 곳에만 — 최상위 4조).
5. promote Step 5 앞에 '개요 확인'(목표 · 안 하는 것 · 단계 · 확인 방법, 열 줄 안팎)을 두고, 그 답을 폴더 승인으로 쓴다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  pass_criteria_of,   // TESTS 본문 → 통과 기준 줄
  vague_criteria,     // 통과 기준 줄 → 값 · 문구 없는 줄
)
flow(
  table_cells_of,     // README 본문 → 표 칸 (코드 블록 밖)
  long_cells,         // 칸 → 40자 넘는 칸
  long_paragraphs,    // README 본문 → 6줄 넘는 문단
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | `pass_criteria_of` | 시험서에서 통과 기준 줄만 뽑는다 | TESTS 본문 → 줄 | 순수 |
| 2 | `vague_criteria` | 값 · 문구 없는 기준을 고른다 | 줄 → 줄 | 순수 |
| 3 | `table_cells_of` | 코드 블록 밖 표 칸을 뽑는다 | 본문 → 칸 | 순수 |
| 4 | `long_cells` | 40자 넘는 칸을 고른다 | 칸 → 칸 | 순수 |
| 5 | `long_paragraphs` | 6줄 넘는 문단의 첫 줄을 고른다 | 본문 → 줄 | 순수 |
| 6 | 출력 | 경고 · ✖ 줄을 찍는다 | 줄 → 화면 | 부수효과 (출구) |

- 부수효과 위치: 파일 읽기(입구), 출력(출구)
- 재사용: check-readme 의 `prose_of` · `err`, work.sh 의 `PLAN_LINK` 경고 자리

## Guardrails

- 선택 창 수 불변 — promote · work 에서 '묻는 지점' 수가 전후 같다
- 판정 숫자(40자 · 6줄)는 한 곳에만 두고 문서는 그 이름을 가리킨다
- 경고(①)는 막지 않는다 — 옛 시험서가 갑자기 실패하지 않게
- 크기 예산(help.md ≤ 7600 B, 합계 ≤ 33000 B, 매 턴 줄 ≤ 400 B)과 템플릿 다이제스트를 지킨다
- 맥 · 리눅스 같은 결과(글자 수는 바이트가 아닌 글자로 센다)

## Exit criteria

- All TESTS.md scenarios pass
- 세 저장소 지금 README 가 새 길이 규칙을 통과한다(넘으면 그 README 를 짧게 고친다)
- 코어 회귀 · codex 사본 코어 시험 통과

## Suggested path

1. 통과 기준 판정과 work 머리말 경고 — `pass_criteria_of`, `vague_criteria`
2. README 검사에 칸 · 문단 길이 판정, 지금 README 를 통과하게 손질 — `table_cells_of`, `long_cells`, `long_paragraphs`
3. 글 모양 규칙 문서와 각 규약의 가리킴, 실물 확인 묻는 말, promote 개요 확인 — 규약 문서를 고치고 시험으로 고정
4. 시험 · 크기 예산 · 다이제스트 · 회귀 — 묻는 지점 수와 깨진 사본으로 확인

## Related Documents

- `core/contracts/show-real.md`, `core/contracts/choices.md`, `core/protocols/promote.md`, `core/protocols/help.md`, `tools/check-readme.sh`, `core/scripts/work.sh`

## Risks / Open Questions

- 40자 · 6줄은 휴대폰 한 줄 · 한 화면에 맞춘 추정값 — 지금 README 에 걸리는 곳이 많으면 숫자가 아니라 README 를 고친다(사용자 결정: 줄글 금지).
- 영어 칸은 40자가 짧을 수 있다 — 글자 수 기준은 언어별로 다르게 둘 수 있게 판정 함수에 인자로 받는다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
