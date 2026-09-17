---
title: "답 모양 검사는 이번 턴의 답만 본다 — 기록 경합 제거"
slug: 20260916-wookiya1364-answer-lint-turn-race
author: "wookiya1364"
created_at: 2026-09-16
status: testing
kind: feature
epic: 20260914-help-turn-cost
lang: korean
tags: [help, stop-hook, answer-shape, lint, transcript, race, drift-log]
raw_sources:
  - scv/raw/stale/20260916-answer-lint-one-turn-lag.md
  - scv/raw/stale/20260916-graph-dependency-decision.md
  - scv/conversations/20260914-092553-install-check-0-47-0.md
refs:
  - type: link
    url: https://code.claude.com/docs/en/hooks
invariants:
  - "지문(echo) 검사의 입력·판정·결과는 바뀌지 않는다 — 대화 파일의 마지막 Turn 블록을 읽는 경로 그대로"
  - "관찰 로그(.help-drift) 의 기존 토큰(시각·turn·echo·lint·reload)과 순서는 그대로 — 끝에 토큰 하나만 덧붙인다"
  - "SCV_ANSWER_LINT=off · SCV_HELP_ECHO=off 이면 0.49.1 과 같은 동작 (읽지도 쓰지도 않음)"
  - "종료 훅은 non-blocking — 어떤 실패도 exit 0, scv/journal/ 밖에 쓰지 않음"
  - "린트는 경고와 재읽기만 한다 — 답을 막거나 고치지 않는다"
scope:
  - "core/template/hooks/on-stop.sh (본문 출처 셋: 호스트 값 → 대화 원본의 이번 턴 → 없음; 원본은 짧게 재시도)"
  - "core/scripts/lib/help-state.sh (순수부: 출처 고르기 · 이번 턴 텍스트 자르기 · 문장 세기 오탐 수정 · 드리프트 줄 src 토큰)"
  - "core/scripts/help-state.sh (stop 하위 명령에 --src 인자)"
  - "core/tests/test-answer-lint-source.sh (신설) · core/tests/test-help-echo.sh (경합 케이스 추가)"
  - "docs/wrapper-integration.md (훅 이음새: last_assistant_message 를 넘기면 쓰고, 없으면 원본으로)"
  - "CHANGELOG.md"
---

# 답 모양 검사는 이번 턴의 답만 본다 — 기록 경합 제거

## Summary

0.50.0 의 답 모양 린트는 턴이 끝날 때 대화 원본(transcript)의 마지막 어시스턴트 텍스트를
읽는다. 그런데 호스트는 원본을 비동기로 적어서, 훅이 먼저 읽으면 **한 턴 전 답**을 본다
(2026-09-16 관찰: 훅 실행 시각과 마지막 답 기록 시각이 같은 초, 두 턴 전 답의 문구가 경고에
걸림). 결과는 엉뚱한 턴의 경고와 불필요한 규약 재읽기(≈6k 토큰). 고치는 법: 호스트가 넘겨주는
"마지막 답 본문" 값을 1순위로 쓰고, 그 값이 없는 호스트에서는 원본에서 **이번 턴의 사용자
메시지 이후**에 적힌 답만 짧게 기다려 가져오며, 그래도 없으면 이번 턴 검사를 건너뛴다(경고
없음). 같은 검사의 오탐 하나(따옴표·괄호 안 마침표를 문장 끝으로 셈)도 함께 고친다.

## Goals / Non-Goals

- **Goals**
  - 린트가 보는 본문이 항상 **이번 턴의 답**이거나, 아니면 **없음**(검사 생략)이다. 낡은 답을 보는 경우는 0.
  - 호스트 값이 없는 래퍼(Codex 등)와 옛 버전에서도 작동 — 원본을 턴 경계로 자르고 짧게 재시도.
  - 관찰 로그 한 줄 끝에 본문 출처(`src=host|transcript|none`)를 남겨 사후 집계로 검증 가능.
  - 따옴표·괄호 안의 마침표는 문장 끝으로 세지 않는다.
- **Non-Goals**
  - 지문(echo) 검사의 변경 — 대화 파일을 읽는 경로라 경합과 무관.
  - 턴 중간에 사용자 메시지가 두 번 들어온 경우의 appended 판정(turn=8 echo=skip 관찰) — 별도 raw 로 남긴다.
  - 린트 규칙 자체의 확장.

## Approach Overview

종료 훅(on-stop.sh)이 본문을 얻는 순서를 셋으로 고정한다.

1. **호스트 값** — stdin JSON 의 `last_assistant_message` 가 비어 있지 않으면 그것. 공식 문서가
   "원본은 늦게 적힐 수 있으니 이 값을 쓰라" 고 명시한다.
2. **원본의 이번 턴** — 값이 없으면 transcript 를 읽되, **마지막 사용자 프롬프트 항목 이후**의
   어시스턴트 텍스트만 취한다(도구 결과 항목은 사용자 프롬프트로 치지 않는다). 비어 있으면
   짧게(기본 4회 × 250ms, 총 1초 상한) 다시 읽는다 — 원본이 곧 따라잡는 경우를 위해.
3. **없음** — 그래도 비어 있으면 이번 턴 린트를 건너뛴다. 경고도 재읽기도 없다. 지문 검사는
   평소대로 돈다.

표식 스크립트(help-state.sh stop)는 `--src` 로 출처를 받아 드리프트 줄 끝에 `src=…` 를 붙인다.
문장 세기는 따옴표(" " ' ' “ ” ‘ ’)와 괄호 안을 먼저 비운 뒤 센다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readStopInput,        // stdin JSON → {hostText, transcriptPath}                (입구, 부수효과)
  pickSource,           // (hostText, transcriptTurnText) → {src, text}          순수
  sliceTurnText,        // (transcript JSONL 텍스트) → 이번 턴의 어시스턴트 텍스트  순수
  waitForTurnText,      // (path, tries, interval) → 텍스트|""                    부수효과(시각·파일)
  lintAnswer,           // (text, cap) → 위반 줄들 — 따옴표·괄호 안 마침표 제외      순수 (기존 + 수정)
  decideDrift,          // (echo, viol, 스위치) → {reload, warn}                  순수 (기존)
  renderDriftLine,      // (now, turn, echo, viol, reload, src) → 한 줄            순수 (끝에 src 추가)
  writeState,           // 표식·경고·드리프트 파일 쓰기                             출구, 부수효과
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readStopInput | stdin JSON → 호스트 값 · 원본 경로 | 부수효과 (입구) |
| 2 | sliceTurnText | 원본 JSONL 본문 → 마지막 사용자 프롬프트 이후 어시스턴트 텍스트 (없으면 "") | 순수 |
| 3 | waitForTurnText | 경로·횟수·간격 → 2 를 반복 호출해 첫 비어 있지 않은 값 | 부수효과 (시각·파일 읽기) |
| 4 | pickSource | 호스트 값 · 원본 턴 텍스트 → {src ∈ host/transcript/none, text} | 순수 |
| 5 | lintAnswer | 텍스트·상한 → 위반 줄들 (따옴표·괄호 안은 비우고 셈) | 순수 (기존 scv_answer_lint 수정) |
| 6 | decideDrift | echo 결과·위반·스위치 → reload·warn | 순수 (기존 그대로) |
| 7 | renderDriftLine | 기존 인자 + src → 한 줄 (`… reload=N src=host`) | 순수 (기존 scv_drift_line 확장) |
| 8 | writeState | 표식·.help-warn·.help-drift | 부수효과 (출구) |

- 부수효과 위치: 1(읽기) · 3(시각·재읽기) · 8(쓰기). 2·4·5·6·7 은 stdin/인자만 받는다.
- 재사용: 5·6·7 은 기존 순수부(scv_answer_lint · scv_drift_decide · scv_drift_line)를 그대로 쓰고 5·7 만 손본다. 지문 검사(scv_echo_check · _turn_record)는 건드리지 않는다.

## Guardrails

- 지문 검사 경로(대화 파일 마지막 Turn 블록 읽기)는 한 줄도 바꾸지 않는다.
- 드리프트 줄의 기존 토큰 순서·이름은 그대로. `src=` 는 맨 끝에만. 옛 줄(src 없음)도 집계 grep 이 그대로 읽힌다.
- 재시도 상한은 1초를 넘지 않는다 — 종료 훅이 턴을 늦추면 안 된다. 호스트 값이 있으면 재시도 0회.
- 본문이 없으면 "위반 없음" 이 아니라 "검사 생략"(src=none, lint=0, reload=0) — 없는 답을 통과로 세지 않는다.
- 스위치 둘이 모두 off 면 파일을 읽지도 쓰지도 않는다 (기존 t5d 검사 유지).
- 새 외부 의존 없음 — jq 는 이미 있는 조건(없으면 조용히 생략)을 그대로.

## Exit criteria

- All TESTS.md scenarios pass
- 기존 검사 test-help-echo 62/62 · 코어 검사 전체 · run-dry 녹색.
- 실사용 관찰: 다음 세션 드리프트 로그에서 `src=host` 가 찍히고, 린트 경고가 걸린 턴의 답에 실제 위반 문구가 있다(엉뚱한 턴 0건).

## Suggested path

1. 순수부 넷을 help-state.sh lib 에 (sliceTurnText · pickSource · 문장 세기 수정 · drift 줄 src) — 검사부터 붉게.
2. help-state.sh stop 에 `--src` 인자.
3. on-stop.sh: 호스트 값 추출 → 없으면 waitForTurnText → pickSource → stop 호출.
4. 검사 파일 신설 + 기존 검사에 경합 케이스 추가 → 녹색.
5. wrapper-integration 문서의 훅 이음새 절과 CHANGELOG.

## 성공지표 (Metrics)

| 지표 | baseline (0.50.0, 2026-09-16 관찰) | target |
|---|---|---|
| 린트가 낡은 답(이전 턴)을 본 비율 | 2턴 중 1턴 (turn=4 사례) | 0 — 드리프트 로그의 src 가 host 또는 transcript 인 줄에서 경고 문구가 그 턴 답에 실재 |
| 엉뚱한 재읽기 비용 | 오탐 1건당 ≈6k 토큰 | 0건 |
| 종료 훅 추가 지연 | 0 | 호스트 값 있을 때 0 · 없을 때 ≤1초 |
| 따옴표 안 마침표 오탐 | 1건 (turn=9) | 0 |

## 예외처리 (Edge cases)

- 호스트 값은 있으나 빈 문자열 → "없음" 으로 보고 원본 경로로 간다.
- 원본에 이번 턴 사용자 프롬프트 항목이 아예 없음(진단 전용 턴·자동 알림) → src=none, 생략.
- 답이 텍스트 없이 도구 호출로만 끝남 → 이번 턴 텍스트 "" → src=none, 생략 (위반 아님).
- 원본 마지막 400줄 안에 이번 턴 프롬프트가 없을 만큼 긴 턴 → 잘린 창 안의 어시스턴트 텍스트만 보되, 프롬프트 경계를 못 찾으면 src=none 으로 안전 쪽.
- 재시도 중 원본 파일이 사라지거나 읽기 실패 → 즉시 src=none, exit 0.
- jq 없음 → 기존대로 조용히 생략 (호스트 값 경로도 jq 로 파싱하므로 python3 폴백은 이번엔 붙이지 않는다 — 기존 조건 유지).
- 스위치 한쪽만 off (린트 off, 지문 on) → 본문을 읽지 않고 지문 검사만, src 토큰은 none.

## Related Documents

- scv/raw/20260916-answer-lint-one-turn-lag.md — 관찰 기록(두 사례·시각)
- scv/archive/20260916-wookiya1364-help-protocol-echo/PLAN.md — 0.50.0 의 린트·지문 설계
- https://code.claude.com/docs/en/hooks — Stop 훅 입력(`last_assistant_message`, 원본 지연 명시)

## Risks / Open Questions

- 호스트 값이 텍스트 블록 여러 개를 어떻게 합치는지(줄바꿈?) 는 미확인 — 린트는 첫 문단만 보므로 영향은 작다. 구현 때 실제 값을 한 번 찍어 확인.
- Codex 래퍼의 종료 훅이 stdin 에 무엇을 넘기는지 미확인 — 원본 경로만 넘긴다면 2단계(턴 경계 + 재시도)가 그쪽의 유일한 경로다.
- 턴 중간 사용자 메시지(mid-turn prompt)로 appended 판정이 흔들리는 관찰은 이 계획 밖 — raw 로 남김.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
