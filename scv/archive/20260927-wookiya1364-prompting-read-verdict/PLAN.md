---
title: 모델별 프롬프팅 — 원문을 읽었는지 · 다시 쓴 요청을 보였는지 결과로 판정한다
slug: 20260927-wookiya1364-prompting-read-verdict
author: wookiya1364
created_at: 2026-09-27
status: in_progress
kind: feature
lang: korean
tags: [model, prompting, help, stop-hook, verdict, drift]
raw_sources:
  - scv/conversations/20260927-160059-per-model-prompting-live-check.md
refs: []
invariants:
  - "경고만 한다 — 답을 막거나 고치지 않는다, 훅은 실패해도 exit 0"
  - "가이드가 없는 모델 · 모르는 모델 · 스위치 off · 짧은 확인 턴에는 아무 경고도 없다"
  - "help 규약 비용 상한(원본 · 코덱스 사본)과 호스트 중립 검사 통과, 맥 · 리눅스 동일"
scope:
  - core/scripts/lib/model-prompting.sh
  - core/scripts/model-prompting.sh
  - core/scripts/help-state.sh
  - core/template/hooks/on-stop.sh
  - core/protocols/help/prompt-refine.md
  - core/tests/test-model-prompting.sh
  - core/TEMPLATE_DIGEST
---

# 모델별 프롬프팅 — 원문을 읽었는지 · 다시 쓴 요청을 보였는지 결과로 판정한다

## Summary

0.59.x 실측(설치본, 헤드리스 한 턴)에서 help 는 `GUIDE: load` 로 그 모델의 원문 두 개를 정확히 알렸지만, 모델은 규칙 문서만
읽고 원문을 열지 않은 채 요청을 다시 썼다(확인). 다시 쓴 요청은 대화 기록에만 있고 답 화면에는 없었다(확인). 모델에게 더
세게 부탁하는 대신 **결과로 판정**한다 — SCV 가 규약 지문을 확인하는 방식과 같다: help 가 원문을 읽으라고 한 턴에 읽음 표시가
없으면, 또 다시 쓴 요청을 기록했는데 답에 인용이 없으면, 멈춤 훅이 다음 턴에 경고 한 줄을 예약한다. 읽음 기록이 없으니 다음
help 는 다시 `load` 를 낸다.

## Goals / Non-Goals

- **Goals**
  - help 가 가이드 결정을 낼 때마다 이번 턴 기록(`.help-guide-turn`: 지문 · 모델 · 결정)을 남긴다.
  - `load` 출력에 정확한 읽음 표시 명령 한 줄 `GUIDE_MARK_CMD:` — 모델이 경로를 짓지 않는다.
  - 멈춤 훅: (1) 결정이 `load` 였는데 이 컨텍스트에서 그 모델의 읽음 기록이 없으면 "원문 안 읽음" 경고 (2) 결정이 `load`/`loaded`
    이고 이번 턴 대화 기록에 다시 쓴 요청 단락이 있는데 답에 인용 블록(`>`)이 없으면 "다시 쓴 요청 안 보임" 경고. 경고는 기존
    `.help-warn` 통로(매 턴 훅이 지시 바로 뒤에 한 번 싣고 지움)에 덧붙인다. 판정 뒤 이번 턴 기록은 지운다.
  - 규약 재표시(`help-state.sh mark`)가 이번 턴 기록의 지문도 새 지문으로 옮긴다(같은 턴에 원문 표시가 먼저인 경우와 같은 처리).
  - 드리프트 관찰 로그에 한 줄(무엇을 판정했는지) — 나중에 "얼마나 자주 안 읽나" 를 센다.
- **Non-Goals**
  - 원문을 끝까지 읽었는지 증명(파일 끝 토큰 등) — 후속 후보.
  - 답을 막거나 고치기, 다시 쓰기 내용의 질 판정.
  - 래퍼 쪽 변경 — 코어만(래퍼는 자동 동기화 · 릴리스).

## Approach Overview

- **입구 기록**: `model-prompting.sh guide` 가 결정을 낸 뒤 `.help-guide-turn` 에 `<지문>\x1f<모델 id>\x1f<결정>` 한 줄(결정 none 이면
  지운다). `load` 면 출력에 `GUIDE_MARK_CMD: bash "<이 스크립트 절대 경로>" mark --model "<id>"`.
- **판정**: `model-prompting.sh stop` 을 멈춤 훅의 드리프트 블록 뒤에서 부른다(stdin = 이번 턴 답 본문 — 멈춤 훅이 이미 고른 것).
  읽는 것: `.help-guide-turn`, `.help-guide`(읽음 기록), 지금 지문, 이번 턴 대화 기록의 마지막 Turn 블록(대화 파일이 표식보다 나중에
  바뀌었을 때만 — `help-state.sh` 의 `_turn_record` 와 같은 기준). 순수 함수가 경고 줄을 정하고, 효과부가 `.help-warn` 에 덧붙인다.
- **지문 기준**: 읽음 기록이 이번 턴 기록의 지문 또는 지금 지문과 같고 모델이 같으면 "읽음". (드리프트 재설정이 멈춤 훅에서 지문을
  먼저 비웠을 수 있으므로 둘 다 본다.)
- **규약 문서**: `prompt-refine.md` 1단계를 "`GUIDE_MARK_CMD:` 줄을 실행" 으로 — 더 짧아진다(비용 상한 여유).

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readTurnState,        // [효과] .help-guide-turn · .help-guide · 표식 지문 · 이번 턴 대화 블록 · 답 본문(stdin) → 문자열들
  parseTurnRecord,      // 턴 기록 한 줄 → (지문, 모델, 결정)
  wasGuideRead,         // (턴 기록, 읽음 기록, 지금 지문) → 0|1
  hasRewriteRecorded,   // 이번 턴 대화 블록 → 0|1 (Rewritten request / 다시 쓴 요청 단락)
  answerHasQuote,       // 답 본문 → 0|1 (코드 블록 밖 '>' 로 시작하는 줄)
  turnVerdict,          // (결정, 읽음, 기록됨, 인용) → unread · unshown 줄들 | ""
  warnLines,            // (판정, 키) → 경고 문장들
  appendWarn,           // [효과] .help-warn 에 덧붙이고 .help-guide-turn 지움 · 드리프트 한 줄
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readTurnState | 파일 넷 · stdin → 문자열 | 부수효과 (입구) |
| 2 | parseTurnRecord | 한 줄 → 세 필드 | 순수 |
| 3 | wasGuideRead | 기록 둘 · 지문 → 0/1 | 순수 |
| 4 | hasRewriteRecorded | 대화 블록 → 0/1 | 순수 |
| 5 | answerHasQuote | 답 → 0/1 | 순수 |
| 6 | turnVerdict | 넷 → 판정 줄 | 순수 |
| 7 | warnLines | 판정 · 키 → 문장 | 순수 |
| 8 | appendWarn | 문장 → 파일 | 부수효과 (출구) |

- 부수효과 위치: 1 · 8 과 `guide` 의 턴 기록 쓰기, `mark` 의 재표시 옮기기.
- 재사용: `scv_mp_read_parse` · `scv_mp_restamp`(턴 기록에도), 멈춤 훅이 이미 고른 답 본문, `help-state.sh` 의 이번 턴 대화 판별 기준.

## Guardrails

- 경고만 — 답을 막거나 바꾸지 않는다. 경고 줄은 한 턴에 최대 둘.
- 결정이 none 이거나 턴 기록이 없으면(짧은 확인 턴 · help 가 안 불린 턴) 판정하지 않는다.
- 스위치 `SCV_MODEL_PROMPTING=off` 면 턴 기록도 판정도 없다.
- 코어 payload 에 모델 · 호스트 이름 없음. help 규약 합계는 원본 · 코덱스 사본 모두 상한에서 100B 이상 여유.
- 기존 경고(규약 지문 · 답 모양)를 지우지 않는다 — 덧붙인다.

## Exit criteria

- All TESTS.md scenarios pass
- 설치본 헤드리스 실측: 원문을 안 읽은 턴 다음 턴에 경고가 실리고, 그 턴의 help 가 다시 load 를 낸다. 원문을 읽고 표시한 턴은 경고 없음.
- 코덱스 벤더 사본에서 코어 테스트 전부 초록(릴리스 전).

## Suggested path

1. 순수부: `scv_mp_turn_parse` · `scv_mp_was_read` · `scv_mp_rewrite_recorded` · `scv_mp_answer_has_quote` · `scv_mp_turn_verdict` · `scv_mp_warn_lines`.
2. `model-prompting.sh`: `guide` 가 턴 기록 · `GUIDE_MARK_CMD`, 새 `stop` 명령.
3. `help-state.sh mark`: 턴 기록 지문도 옮김. 멈춤 훅: 드리프트 블록 뒤 `model-prompting.sh stop` 호출(같은 답 본문).
4. `prompt-refine.md` 1단계 문구. 테스트.
5. 코덱스 벤더 사본에서 전체 검사 → 코어 릴리스 → 래퍼 동기화 · 릴리스 → 설치본 실측.

## Edge cases (예외처리)

| 조건 | 동작 |
|---|---|
| 턴 기록 없음 · 결정 none | 판정 없음 |
| 같은 턴에 원문 표시 뒤 규약 재표시 | 재표시가 읽음 기록 · 턴 기록 지문을 함께 옮김 → 읽음 |
| 멈춤 훅의 드리프트 재설정이 지문을 먼저 비움 | 턴 기록의 지문으로도 대조 → 오탐 없음 |
| 답 본문을 못 얻음(출처 none) | "안 보임" 판정 생략, "안 읽음" 만 |
| 다시 쓴 요청 단락 없음(짧은 턴 · 다시 쓰기 생략) | "안 보임" 판정 생략 |
| 코드 블록 안의 `>` | 인용으로 세지 않음 |
| .help-warn 이 이미 있음(규약 경고) | 덧붙임 — 2KB 상한은 매 턴 훅이 지킨다 |

## Metrics (성공 지표)

| 지표 | 지금 | 목표 |
|---|---|---|
| 원문을 안 읽은 턴이 다음 턴에 드러나는 비율 | 0% (확인: 실측에서 조용히 넘어감) | 100% |
| 다음 턴 help 가 다시 load 를 내는 비율(안 읽었을 때) | 100% (읽음 기록 없음 — 확인) | 100% 유지 |
| 드리프트 로그에서 안 읽음 · 안 보임 빈도 | 없음 | 셀 수 있음 |

## Related Documents

- `core/protocols/help/prompt-refine.md`
- `scv/archive/20260927-wookiya1364-per-model-prompting/PLAN.md`

## Risks / Open Questions

- **표시만 하고 안 읽는 경우**는 여전히 잡지 못한다 — 표시가 곧 증거다. 파일 끝 토큰으로 "끝까지 읽음" 을 증명하는 것은 후속 후보.
- **경고 피로**: 매 턴 안 읽으면 매 턴 경고. 규약 지문 경고와 같은 성격이라 허용 — 드리프트 로그로 빈도를 본다.
- 코덱스 멈춤 훅 등록 여부는 확인하지 않았다 — 등록돼 있지 않으면 코덱스에서는 판정이 돌지 않는다(조용함).

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
