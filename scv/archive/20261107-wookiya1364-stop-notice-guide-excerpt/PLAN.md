---
title: 가이드 발췌본 + 종료 검사 다음 턴 안내
slug: 20261107-wookiya1364-stop-notice-guide-excerpt
author: wookiya1364
created_at: 2026-11-07
status: planned
kind: feature
lang: korean
tags: [model-prompting, stop-hook, tokens]
raw_sources:
  - scv/conversations/20261107-224242-concise-output-style.md
refs:
  - type: pr
    url: https://github.com/wookiya1364/scv-core/pull/464
invariants:
  - "발췌본이 없거나 링크면 예전처럼 원문을 읽는다"
  - "SCV_STOP_MODE=block 이면 0.82 까지와 같은 막기"
  - "검사 규칙(무엇을 어긋남으로 보는지)은 그대로 — 다루는 방식만 바뀐다"
---

# 가이드 발췌본 + 종료 검사 다음 턴 안내

## Summary

실제 세션 기록을 재 보니 두 가지가 토큰과 사용자 피로를 키웠다. (1) 압축 · 세션 시작마다 가이드 원문 약 94KB를 다시 읽는데 그중 65KB가 공통 원문이다. (2) 종료 검사가 답을 막아 다시 쓰게 하면 다시 쓴 답이 인용 · 확인 범위를 되풀이해 같은 답이 두 번 보인다(186턴 중 78턴). 발췌본을 읽게 하고, 종료 검사는 막는 대신 다음 턴 안내로 넘긴다.

## Goals / Non-Goals

- **Goals**
  - 원문 옆에 `excerpt-<원문>` 이 있으면 help 가 그것을 읽게 한다
  - 종료 검사 기본 방식을 notice(막지 않고 다음 사람 턴 첫 안내)로 바꾼다 — `SCV_STOP_MODE=block` 으로 예전 방식
  - 제목형 확인 범위(쌍점 없는 `**확인한 것**` 아래 목록)를 빠진 줄로 보던 오탐을 없앤다
- **Non-Goals**
  - 모델 원문(모델별 가이드) 발췌
  - 검사 규칙 자체(무엇을 어긋남으로 보는지) 변경
  - 래퍼 쪽 발췌 생성 · 검사(래퍼 저장소에서 따로)

## Approach Overview

- help 의 가이드 경로 조립에서 원문 이름을 정한 뒤, 같은 폴더에 `excerpt-<이름>` 이 평범한 파일로 있으면 그 이름으로 바꾼다.
- 종료 훅의 마지막 단계(막는 이유를 JSON 으로 내보내던 곳)에서 방식을 판정해, notice 면 이유를 `[SCV 직전 답]` 줄로 바꿔 이 세션의 다음 턴 안내 파일(`.help-warn`)에 덧붙이고 끝낸다. 매 턴 훅은 이미 그 파일을 한 번 싣고 지운다.
- 확인 범위 줄 판정은 제목형 줄을 칸으로 보고, 그 아래 목록을 칸 내용으로 잇는다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  scv_mp_read_name,   // (원문 이름, 발췌본 있음) → 읽힐 이름
)
flow(
  scv_finish_scan,    // (끝 답, 언어) → 칸 · 내용 줄들
  scv_stop_mode,      // (설정 값) → block | notice
  scv_stop_notice,    // (막는 이유들) → 다음 턴 안내 줄들
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | `scv_mp_read_name` | 발췌본이 있으면 그 이름을 고름 | 원문 이름 · 0/1 → 이름 | 순수 |
| 2 | `scv_finish_scan` | 끝 답에서 확인 범위 칸을 꺼냄(제목형 포함) | 끝 답 · 언어 → 칸 줄들 | 순수 |
| 3 | `scv_stop_mode` | 설정으로 막을지 안내할지 정함 | 설정 값 → block · notice | 순수 |
| 4 | `scv_stop_notice` | 막는 이유를 안내 줄로 바꿈 | 이유들 → 안내 줄들 | 순수 |

- 부수효과 위치: 발췌본 존재 확인(model-prompting.sh guide), 안내 파일 쓰기(on-stop.sh `_scv_emit_block`), 안내 싣고 지우기(on-user-prompt.sh — 기존)
- 재사용: 다음 턴 안내 파일(`.help-warn`) 통로 · 매 턴 훅의 싣고 지우기

## Guardrails

- 원문 사본 · 요구 항목 목록 · 읽음 판단은 건드리지 않는다
- block 방식의 출력은 0.82 와 같아야 한다 — 막힘을 보는 기존 시험 10개를 `SCV_STOP_MODE=block` 으로 그대로 통과
- 안내 파일은 링크를 따라 쓰지 않는다(기존 쓰기 규칙 그대로)
- 맥 · 리눅스 · bash 3.2 에서 같은 결과

## Exit criteria

- All TESTS.md scenarios pass
- 실제 래퍼 가이드 폴더로 help 를 돌리면 `GUIDE_FILE` 이 발췌본을 가리킨다
- 언어가 어긋난 답에 종료 훅이 막는 JSON 을 내지 않고, 다음 턴 매 턴 훅이 `[SCV 직전 답]` 줄을 한 번 싣는다

## Suggested path

1. 발췌본 이름 고르기와 help 연결 — `scv_mp_read_name`
2. 제목형 확인 범위 읽기 — `scv_finish_scan`
3. 종료 방식 판정과 안내 줄 — `scv_stop_mode`, `scv_stop_notice`
4. 막힘을 보는 기존 시험은 block 방식으로 돌리고, 새 시험(T44 · N1–N6)을 더함 — 시험 정리
5. 설정 예시 · 템플릿 지문 · 변경 기록 갱신 — 문서와 지문 맞추기

## Related Documents

## Risks / Open Questions

- notice 방식에서는 어긋난 답이 그 턴에는 그대로 남는다 — 다음 답부터 지키게 된다(사용자 결정: 다시 쓰기 없애기)
- 실제 세션에서 반복이 사라졌는지는 래퍼 릴리스 뒤 slay 세션에서 확인해야 한다
- 코덱스 호스트에서 다음 턴 안내가 같은 방식으로 실리는지 확인 필요

## Links

- Raw originals: (listed in frontmatter)
- Related PRs: https://github.com/wookiya1364/scv-core/pull/464
