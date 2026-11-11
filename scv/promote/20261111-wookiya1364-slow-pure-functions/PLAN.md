---
title: 느린 순수함수 고치기 — 입력이 커지면 크게 느려지는 17개
slug: 20261111-wookiya1364-slow-pure-functions
author: wookiya1364
created_at: 2026-11-11
status: planned
kind: refactor
lang: korean
tags: [purity, performance, bench]
scope:
  - core/scripts/lib/plan-link.sh
  - core/scripts/lib/help-state.sh
  - core/scripts/lib/text.sh
  - core/scripts/lib/model-prompting.sh
  - core/scripts/lib/lang-enforce.sh
  - core/scripts/lib/turn-check.sh
  - core/scripts/turn-check.sh
  - core/scripts/lib/pure-catalog.sh
  - core/scripts/lib/metrics.sh
  - core/scripts/lib/regression-memo.sh
  - core/scripts/lib/archive-search.sh
  - core/tests/test-slow-pure-functions.sh
raw_sources:
  - scv/raw/stale/20261111-slow-pure-functions.md
refs: []
invariants:
  - "17개 함수의 답(출력과 끝 코드)은 고치기 전과 글자 하나까지 같다"
  - "순수함수는 계속 순수하다 — 다른 프로그램을 부르지 않고, 파일을 읽거나 쓰지 않는다"
  - "재는 명령의 한도(시간 1.2배 · 입력 4배에 8배)는 바꾸지 않는다"
  - "옛 셸(bash 3.2)과 새 셸(bash 5), 맥과 리눅스에서 같은 답을 낸다"
---

# 느린 순수함수 고치기 — 입력이 커지면 크게 느려지는 17개

## Summary

재는 명령으로 사전의 함수 363개를 재 보니, 입력을 4배로 늘릴 때 8배 넘게 느려지는 함수가 16개 있었다(옛 셸 15개, 새 셸에서만 넘는 것 1개).
가장 심한 것은 계획 충돌 검사 둘이다: 뒤쪽 검사는 4배 입력에 23초가 걸리고, 앞쪽 검사는 60초를 넘겨 끊겼다.
이 16개와, 낱말 수만큼 다른 프로그램을 부르는 함수 1개를 심한 것부터 고친다. 답은 바꾸지 않는다.

## Goals / Non-Goals

- **Goals**
  - 17개 함수를 심한 것부터 고쳐 4배 입력 시간을 줄인다
  - 함수마다 고치기 전과 답이 같은지를 시험으로 지킨다 (옛 본문을 견줄 판으로 남겨 여러 입력에서 맞댄다)
  - 함수마다 앞뒤 시간을 재는 명령으로 재서 표로 남긴다
  - 한도 안으로 들어온 함수는 배수 기준 목록에서 뺀다
  - 빨라지지 않는 함수는 되돌리고 이유를 적는다
- **Non-Goals**
  - 답의 모양이나 뜻을 고치는 일
  - 재는 명령의 한도 숫자나 재는 방법을 고치는 일
  - 17개 밖의 함수를 손보는 일
  - PR · 릴리스 · 래퍼 저장소 작업

## Approach Overview

17개는 모두 셸 함수다(순수 16개, 다른 프로그램을 부르는 것 1개). 코드를 읽어 보니 느려지는 모양은 넷이다.

1. **큰 글 하나에 계속 덧붙이기** — 답 줄을 변수 하나에 이어 붙이면 붙일 때마다 글 전체를 다시 베낀다. 나오는 대로 바로 내보내거나 배열에 모았다가 한 번에 낸다. (충돌 검사 둘, 낱말 나누기)
2. **안쪽 고리에서 같은 일을 되풀이** — 안쪽 고리를 돌 때마다 같은 글을 다시 다듬거나 다시 줄로 나눈다. 고리 밖에서 한 번만 한다. (충돌 검사 둘, 줄마다 한글 비율 재기)
3. **글자 하나씩 돌기** — 글자를 하나씩 꺼내 견준다. 통째 바꾸기나 덩어리 단위 자르기로 바꾼다. (범위 칸 소문자 바꾸기, 명령 줄 쪼개기)
4. **긴 글 통째로 무늬 맞추기 · 통째 바꾸기** — 옛 셸은 여러 바이트 글자가 든 긴 글에서 이 일이 글 길이의 제곱으로 느려진다. 바이트 단위로 해도 답이 같은 곳은 바이트 단위로 하고, 필요한 앞부분만 본다. (인용 줄 판정, 한글 비율, 경로를 파일 이름으로 바꾸기, 따옴표 속 비우기)

2026-11-11 에 뒤쪽 충돌 검사를 임시 폴더에서 시험으로 고쳐 봤다: 4배 입력에서 옛 셸 23061ms → 132ms, 새 셸 41896ms → 155ms, 답 10000줄이 모두 같았다.

짝을 모두 내는 함수 둘(같은 지문 짝, 양방향 짝)은 답 자체가 입력의 제곱만큼 늘 수 있다. 이런 함수는 8배 한도 안으로 못 들어올 수 있다 — 그때는 시간이 준 만큼만 고치고, 한도를 넘는 이유를 적어 기준 목록에 남긴다.

### 답이 같은지 지키는 방법

고치기 전 본문 17개를 `core/tests/fixtures/slow-pure/reference.sh` 에 `ref_` 이름으로 그대로 옮겨 둔다. 시험은 함수마다 사전의 예시, 그 예시를 25번 · 100번 되풀이한 입력, 손으로 고른 모서리 입력(빈 글, 한 글자, 여러 바이트 글자, 줄 끝이 없는 글)을 두 판에 넣어 출력과 끝 코드를 맞댄다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

이 계획은 새 파이프라인을 만들지 않는다. 이미 있는 파이프라인의 단계(순수함수) 17개의 속만 고친다 — 받는 값과 돌려주는 값은 그대로다.

```
flow(
  ref_답,     // (함수, 입력) → 옛 본문의 답
  새_답,      // (함수, 입력) → 고친 본문의 답
  맞대기,     // (옛 답, 새 답) → 같음 | 다름
  재기,       // (함수) → 한 번 시간 · 4배 입력 시간 · 배수
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | scv_plan_conflict_after | 뒤쪽 충돌 검사 — 바뀐 파일이 남은 단계 글에 나오는지 본다 | 계획 글, 파일 목록 → 겹침 줄들 | 순수 |
| 2 | scv_plan_conflict_before | 앞쪽 충돌 검사 — 새 계획의 목표가 하지 않기로 한 것 · 남은 단계와 겹치는지 본다 | 계획 글 둘 → 충돌 · 겹침 줄들 | 순수 |
| 3 | scv_lint_lang_turn | 한국어 설정인데 영어로 쓴 줄을 센다 | 마지막 답, 턴 글, 언어 → 줄 수 | 순수 |
| 4 | scv_lint_hangul_ratio | 글에서 한글 글자의 비율을 낸다 | 글 → 0 ~ 100 | 순수 |
| 5 | scv_lint_strip_quoted | 따옴표 · 괄호 속을 비운다 | 글 → 글 | 순수 |
| 6 | scv_is_rewrite_quote | 한 줄이 다시 쓴 요청 인용 줄인지 본다 | 줄 → 1 \| 0 | 순수 |
| 7 | scv_mp_answer_shows_rewrite | 답에 다시 쓴 요청 인용이 있는지 본다 | 답, 다시 쓴 요청 → 1 \| 0 | 순수 |
| 8 | scv_mp_scope_forbid | 범위 칸이 변경을 막는 첫머리인지 본다 | 범위 글 → 문구 \| 빈 값 | 순수 |
| 9 | scv_lang_drop_machine | 사람이 쓰지 않은 기계 글 블록을 뺀다 | 글 → 글 | 순수 |
| 10 | scv_tc_words | 글을 맞대기용 낱말들로 나눈다 | 글 → 낱말들 | 순수 |
| 11 | scv_tc_receipt | 명령 글이 계획 기록 명령인지 본다 | 명령 글 → 이름 \| 빈 값 | 순수 |
| 12 | key_of | 폴더 경로를 파일 이름으로 바꾼다 | 경로 → 이름 | 순수 |
| 13 | pc_duplicate_pairs | 지문이 같은 함수 짝을 낸다 | 지문 · 함수 줄들 → 짝 줄들 | 순수 |
| 14 | pc_mutual_pairs | 양쪽 방향이 다 있는 짝을 낸다 | 가 · 나 줄들 → 짝 줄들 | 순수 |
| 15 | scv_mx_aggregate | 지표 줄들을 수 · 합 · 평균 · 가운데 값으로 모은다 | 줄들 → 다섯 칸 | 순수 |
| 16 | scv_reg_split_chain | 한 줄을 &&, \|\|, ; 로 이은 조각들로 나눈다 | 줄 → 조각 줄들 | 순수 |
| 17 | scv_as_count_terms | 한 줄에 검색 낱말이 몇 개 나오는지 센다 | 줄, 낱말들 → 수 | 부수효과 (글자 바꾸는 프로그램을 부름) |

- 부수효과 위치: 17번만 다른 프로그램을 부른다(대소문자 바꾸기). 나머지 16개는 순수하고, 고친 뒤에도 순수해야 한다.
- 재사용: 1 · 2번은 이미 있는 `scv_plan_steps` · `scv_plan_goal_items` · `scv_plan_norm_req` 를 그대로 쓴다. 3번은 4번을 쓴다. 재는 일은 `pure-bench.sh` 를 그대로 쓴다.

### 합성 설계 체크리스트 (Composition checklist)

| # | 물음 | 답 | 근거 |
|---|---|---|---|
| 1 | 각 단계가 요소 단위 단항 순수 함수인가 | 예 (16개) | 위 표 1 ~ 16번 — 받는 값만으로 답을 낸다. 17번은 다른 프로그램을 부른다(`lib/archive-search.sh:140`) |
| 3 | 요소 단위로 먼저 합성한 뒤 순회는 한 번만 하는가 | 지금은 아니오 → 고친다 | `lib/plan-link.sh:343` · `:381` — 바깥 고리마다 안쪽 목록을 다시 줄로 나누고 다시 다듬는다. `lib/help-state.sh:280` — 줄마다 비율 함수를 따로 부른다 |
| 5 | 큰 데이터나 조기 종료가 있으면 지연 평가를 쓰는가 | 일부 | `lib/model-prompting.sh:721` 은 찾으면 바로 끝난다. `lib/text.sh:38` 은 첫 글자만 보면 되는데 글 전체를 다듬는다 → 고친다 |
| 7 | 부수효과가 파이프라인 양 끝에만 있는가 | 예 | 16개는 부수효과가 없다. 17번의 프로그램 부르기는 고리 안에 있다(`lib/archive-search.sh:148`) → 고리 밖 한 번으로 옮긴다 |
| 10 | 핫패스는 측정한 뒤에 최적화했는가 | 예 | 363개를 잰 표(`scv/archive/20261111-wookiya1364-pure-bench-and-gate/BENCH-bash3.md`)에서 한도를 넘은 것만 고친다. 고친 뒤 같은 명령으로 다시 잰다 |
| 그 밖 | 2 · 4 · 6 · 8 · 9 | 해당 없음 | 비동기 단계, 여러 값을 묶어 넘기는 단계, 구조 공유가 필요한 큰 값이 없다 |

## Guardrails

- 답을 바꾸지 않는다. 옛 본문과 한 글자라도 다르면 그 함수는 되돌린다.
- 순수함수 안에서 다른 프로그램(awk · sed · grep 같은 것)을 부르지 않는다. 순수 검사(`check-purity.sh`)가 통과해야 한다.
- 옛 셸(bash 3.2)에서 도는 문법만 쓴다 — 이름으로 찾는 배열(연관 배열), `${var,,}` 같은 것은 쓰지 않는다.
- 빨라졌다는 말은 재는 명령으로 잰 앞뒤 숫자가 있을 때만 한다.
- 배수 기준 목록은 재는 명령이 낸 결과로만 줄인다 — 손으로 지워 통과시키지 않는다.
- 코어 파일에 호스트 이름을 넣지 않는다.

## Exit criteria

- TESTS.md 의 시나리오 7개 통과
- 17개 각각의 앞뒤 시간(한 번 · 4배 입력 · 배수)을 옛 셸과 새 셸에서 잰 표가 계획 폴더에 있다
- 고치지 않거나 되돌린 함수는 이유가 표에 적혀 있다
- 순수 검사 · 사전 검사 · 전체 시험이 옛 셸과 새 셸에서 통과한다

## Suggested path

1. 고치기 전 본문 17개를 견줄 판으로 옮기고, 두 판을 맞대는 시험을 만든다 — 답이 같은지 지키는 그물부터 친다
2. 충돌 검사 둘을 고치고 앞뒤를 잰다 — `scv_plan_conflict_after`, `scv_plan_conflict_before`
3. 글 검사 일곱을 고치고 앞뒤를 잰다 — `scv_lint_lang_turn`, `scv_lint_hangul_ratio`, `scv_lint_strip_quoted`, `scv_is_rewrite_quote`, `scv_mp_answer_shows_rewrite`, `scv_mp_scope_forbid`, `scv_lang_drop_machine`
4. 낱말 · 짝 일곱을 고치고 앞뒤를 잰다 — `scv_tc_words`, `scv_tc_receipt`, `key_of`, `pc_duplicate_pairs`, `pc_mutual_pairs`, `scv_mx_aggregate`, `scv_reg_split_chain`
5. 프로그램을 낱말 수만큼 부르는 함수를 고치고 부른 수를 잰다 — `scv_as_count_terms`
6. 363개 전체를 두 셸에서 다시 재고, 기준 목록 · 사전 · 변경 기록 · 버전을 맞춘다 — 앞뒤 표를 그대로 보인다

## Related Documents

- 고치기 전 전체 표: `scv/archive/20261111-wookiya1364-pure-bench-and-gate/BENCH-bash3.md` · `BENCH-bash5.md`

## Risks / Open Questions

- 짝을 내는 함수 둘은 답이 입력의 제곱만큼 늘어 8배 한도 안으로 못 들어올 수 있다. 그때는 이유를 적고 기준 목록에 남긴다.
- 옛 셸에서 긴 글의 통째 바꾸기가 느린 것은 셸 자체의 성질이다. 바이트 단위로 바꿔도 답이 같은지는 여러 바이트 글자가 든 입력으로 맞대 봐야 안다.
- 재는 값은 컴퓨터가 붐비면 흔들린다. 앞뒤는 번갈아 재는 방식(`compare`)으로 본다.
- 리눅스와 CI 에서는 올릴 때까지 돌려 보지 못한다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
