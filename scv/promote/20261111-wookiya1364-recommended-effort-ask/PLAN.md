---
title: 권장 effort 요청 — 모델의 권장 값과 다르면 한 번 묻는다
slug: 20261111-wookiya1364-recommended-effort-ask
author: wookiya1364
created_at: 2026-11-11
status: planned
kind: feature
lang: korean
tags: [prompting, effort, wrapper]
scope:
  - core/scripts/lib/model-prompting.sh
  - core/scripts/model-prompting.sh
  - core/scripts/help.sh
  - core/template/scv/scv_settings.example.json
  - core/tests/test-effort-ask.sh
  - ../scv-claude-code/prompting/EFFORT.tsv
  - ../scv-claude-code/prompting/check.sh
raw_sources:
  - scv/raw/20261110-remaining-work-three-plans.md
  - scv/raw/20261110-linux-session-plans.md
refs: []
invariants:
  - "effort 를 바꾸는 것은 사용자다 — SCV 도 모델도 값을 바꾸지 않는다"
  - "지금 effort 값을 모르면 묻지 않는다 — 값을 지어내지 않는다"
  - "권장 표가 없는 호스트 · 표에 없는 모델에서는 지금과 똑같이 돈다"
  - "다시 쓰기 장치(등록 · 답 맨 위 인용 · 쓰기 문)는 바뀌지 않는다"
  - "코어 파일에 호스트 이름이 들어가지 않는다"
---

# 권장 effort 요청 — 모델의 권장 값과 다르면 한 번 묻는다

## Summary

모델마다 공식 문서가 권하는 effort 값이 있다. 세션의 effort 가 그 값과 다르면, SCV 가 선택 창으로 한 번 "바꾸시겠습니까"를 묻게 한다.
바꾸는 것은 사용자이고, 같은 조건에서는 다시 묻지 않는다. 클로드 코드 래퍼에 먼저 넣는다.
방향과 값은 2026-11-10 리눅스 세션에서 사용자가 정했다.

## Goals / Non-Goals

- **Goals**
  - 래퍼 가이드 폴더에 모델별 권장 effort 표를 둔다(모델 9개, 값 · 조건 · 근거 문장 · 출처).
  - 지금 effort 가 권장과 다르면 매 턴 안내에 "선택 창으로 한 번 물어라"는 줄이 한 번 실린다. 근거 문장이 함께 보인다.
  - 같은 조건(모델 · 지금 값 · 권장 값)에서는 다시 묻지 않는다. 조건이 달라지면 한 번 더 묻는다.
  - 끄는 설정 하나(기본 켬).
  - 지금 값은 호스트가 주는 값을 먼저 쓰고, 도움말도 모델과 함께 effort 를 받을 수 있다.
- **Non-Goals**
  - effort 를 SCV 나 모델이 직접 바꾸는 일
  - 코덱스 래퍼의 effort 요청
  - 일의 무게로 실행 방식을 정하는 기존 장치(`SCV_EFFORT_MODE`) 손보기
  - 다시 쓰기 규칙 · 답 모양 규칙

## Approach Overview

- **권장 표** — 래퍼의 `prompting/EFFORT.tsv`. 한 줄 = 모델 id · 권장 값 · 조건(없으면 `-`) · 근거 문장 · 출처 주소. 리눅스 세션에서 정한 값:
  Fable 5 · 5.1 · 5.2 = high / Opus 4.8 = xhigh / Opus 5 = high / Opus 5.5 = medium / Sonnet 5 = high / Sonnet 5.5 = high / Haiku 5.5 = medium.
  조건이 달린 모델: Opus 4.8(코딩 · 에이전트 일은 xhigh, 그 밖은 high 이상), Sonnet 5.5(high 에서 시작, 잘 정의된 에이전트 코딩은 medium).
  1단계에서 값과 근거 문장을 지금의 공식 문서와 다시 맞춘다. 문서에서 근거 문장을 찾지 못한 모델은 표에 넣지 않는다(그 모델은 묻지 않음).
- **지금 값 읽기** — 코어는 "값을 담은 환경 변수 이름"을 호스트 프로필에서 받는다(코어에 호스트 이름 없음). 래퍼가 그 이름을 알려 준다.
  2026-11-11 실제 실행으로 확인한 것(effort 를 low · xhigh · 지정 없음으로 세 번 실행):
  - 매 턴 훅의 환경과 입력에는 세션의 effort 가 없다. 데스크톱 앱 세션의 환경 변수는 앱이 넣은 값이라 명령줄 실행에는 없고, 물려받은 값은 실제 값과 달랐다(low 로 실행했는데 high).
  - 세션 기록 파일(훅 입력의 기록 경로)에는 답한 줄마다 그 턴의 effort 가 남는다(low → low, xhigh → xhigh, 지정 없음 + Haiku → medium).
  그래서 지금 값은 "세션 기록의 마지막 답에 적힌 값"으로 읽는다. 세션의 첫 턴에는 아직 값이 없어 묻지 않고, 둘째 턴부터 판정한다. 세션 중에 값을 바꾸면 그다음 턴부터 반영된다.
  훅에서 못 읽으면 도움말이 받는 값(`--effort`)을 쓴다. 둘 다 없으면 '모름' → 묻지 않는다.
- **판정과 안내** — 순수 함수가 지금 값 · 권장 줄 · 지난번 물은 조건을 받아 `ask | same | asked | unknown | off` 중 하나를 낸다. `ask` 일 때만 매 턴 안내에 줄이 실린다. 물은 조건은 세션 상태 파일에 적는다.
- **분량** — 묻지 않는 턴은 안내가 0바이트 늘어난다. 묻는 턴의 줄은 분량 한도 시험 안에 든다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  effort_now,              // 호스트 프로필 · 환경 · 도움말 인자 → 지금 값 또는 빈 값   (부수효과: 환경 읽기)
  scv_mp_effort_row,       // 권장 표 글 · 모델 id → "권장<TAB>조건<TAB>근거<TAB>출처" 또는 빈 값
  scv_mp_effort_verdict,   // 스위치 · 지금 값 · 권장 줄 · 지난번 조건 → ask|same|asked|unknown|off
  scv_mp_effort_block,     // 판정 · 지금 값 · 권장 줄 → 안내에 실을 줄(ask 가 아니면 빈 값)
  effort_mark,             // 조건 → 세션 상태 파일                                    (부수효과: 쓰기)
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | `effort_now` | 지금 세션의 effort 값을 얻는다 | 호스트 프로필 · 환경 · 인자 → 값 또는 빈 값 | 부수효과 (입구) |
| 2 | `scv_mp_effort_row` | 권장 표에서 이 모델의 줄을 고른다 | 표 글 · 모델 id → 권장 줄 또는 빈 값 | 순수 |
| 3 | `scv_mp_effort_verdict` | 물을지 말지 정한다 | 스위치 · 지금 값 · 권장 줄 · 지난번 조건 → 판정 | 순수 |
| 4 | `scv_mp_effort_block` | 물으라는 안내 줄을 만든다 | 판정 · 지금 값 · 권장 줄 → 안내 줄 | 순수 |
| 5 | `effort_mark` | 물은 조건을 적어 둔다 | 조건 → 세션 상태 파일 | 부수효과 (출구) |

- 부수효과 위치: 1(환경 읽기) · 5(상태 파일 쓰기).
- 재사용: 매 턴 안내를 싣는 자리(`prompt` 명령)와 세션 상태 폴더, 선택 창 규칙(`contracts/choices.md`)을 그대로 쓴다.

## Guardrails

- 안내 줄은 "사용자에게 물어라"까지다. "값을 바꿔라"는 말을 넣지 않는다.
- 근거 문장은 공식 문서의 문장 그대로다. 요약하거나 지어내지 않는다.
- 코어에는 호스트 이름 · 호스트의 환경 변수 이름을 적지 않는다(호스트 프로필에서 받는다).
- 지금 값이 표의 값 낱말(low · medium · high · xhigh · max)이 아니면 '모름'으로 본다.
- 실제 세션에서 지금 값이 맞게 읽히는 것을 확인하지 못하면 내보내지 않는다 — 멈추고 보고한다.

## Exit criteria

- TESTS.md 의 시나리오 17개 통과
- 실제 클로드 코드 세션에서: effort 를 권장과 다르게 두면 요청이 1번, 권장대로 두면 0번(T15)
- 묻지 않는 턴의 매 턴 안내 크기가 0.88.x 와 바이트 단위로 같음
- 전체 시험 bash 3.2 · bash 5, CI 맥 · 리눅스 통과

## Suggested path

1. 지금 값을 읽는 길을 실제 세션으로 확인하고, 표의 값 · 근거 문장을 공식 문서와 맞춤 — 읽는 길이 없으면 여기서 멈추고 보고한다
2. 권장 표와 표 검사를 래퍼에 넣음 — `scv_mp_effort_row`
3. 판정과 안내 줄 — `scv_mp_effort_verdict`, `scv_mp_effort_block`
4. 지금 값 읽기와 물은 조건 적기를 매 턴 안내에 이음 — `effort_now`, `effort_mark`
5. 도움말이 effort 를 받고, 끄는 설정을 넣음 — `effort_now`
6. 문서 · CHANGELOG · VERSION 0.89.0 · 순수 함수 목록 — 문서와 버전을 맞춘다
7. 실제 세션으로 요청 1번 · 0번을 확인 — 화면에 보이는 대로 적는다

## Related Documents

- [`TESTS.md`](./TESTS.md)
- [`FEATURE_ARCHITECTURE.md`](./FEATURE_ARCHITECTURE.md)

## Risks / Open Questions

- 지금 값은 세션 기록에서 읽으므로 한 턴 늦다: 첫 턴에는 묻지 않고, 값을 바꾼 바로 그 턴에는 옛 값으로 본다.
- 세션 기록의 키 이름은 호스트가 바꿀 수 있다. 못 읽으면 '모름'이 되어 묻지 않는다(조용히 꺼짐) — 래퍼의 시험이 실제 기록 모양을 본다.
- 표의 값은 리눅스 세션에서 정한 것이다. 지금 공식 문서와 다르면 문서를 따르고, 달라진 값은 보고한다.
- 코덱스 래퍼에는 표가 없어 동작이 그대로다(뒤 계획).

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
