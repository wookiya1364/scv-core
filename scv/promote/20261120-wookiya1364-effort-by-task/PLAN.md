---
title: 질의에 맞는 effort 추천 · 캐시 미스를 피하는 새 세션 제안
slug: 20261120-wookiya1364-effort-by-task
author: wookiya1364
created_at: 2026-11-20
status: planned
kind: feature
lang: korean
tags: [effort, prompt-cache, session]
raw_sources:
  - scv/conversations/20261119-125432-rewrite-gap-other-session.md
refs:
  - type: link
    url: https://platform.claude.com/docs/en/build-with-claude/effort
  - type: link
    url: https://platform.claude.com/docs/en/build-with-claude/cache-diagnostics
invariants:
  - "SCV 는 세션 effort 를 스스로 바꾸지 않는다 — 추천 · 묻기까지만"
  - "같은 조건의 추천은 다시 묻지 않는다(0.89.0 의 한 번만 묻기 그대로)"
---

# 질의에 맞는 effort 추천 · 캐시 미스를 피하는 새 세션 제안

## Summary

지금 SCV 는 모델별 권장 effort 한 값만 보고 세션당 한 번 묻는다(0.89.0). 공식 effort 문서는 "질의의 난이도에 맞춰 effort 를 달리하라(단순한 질의는 low, 에이전트 코딩 · 복잡한 추론은 high)"고 권하면서도, "캐시를 쓰는 대화 안에서는 요청 전체의 effort 값을 자주 바꾸지 말라 — 캐시가 깨진다"고 한다. 캐시 진단 문서도 요청 설정(output_config)이 다르면 캐시를 비교할 수 없다고 적는다. 이 계획은 일의 종류가 크게 바뀔 때만 공식 문서 문장을 근거로 effort 를 추천하고, 바뀐 일이 크면 이 세션의 effort 를 바꾸는 대신 알맞은 effort 의 새 세션을 제안해 이 세션의 캐시를 지킨다.

실측(대화 Turn 28): 긴 실제 세션 3,740 응답 중 큰 캐시 미스 13번(대화 요약 8 · 1시간 넘게 쉼 3 · 모델 변경 1 · 그 밖 1), 이 세션 1,180 응답 중 8번. SCV 훅 글은 뒤에 붙기만 해 미스 원인이 아님.

## Goals / Non-Goals

- **Goals**
  - Claude Code 에서 effort 를 바꾼 다음 턴에 캐시가 깨지는지 실제로 잰다(이 결과가 2 · 4 단계의 설계를 정함).
  - 사람 요청을 일의 종류(짧은 대화 · 보통 코딩 · 긴 계획 구현 · 깊은 조사 등)로 가르고, 모델별 권장 effort 를 공식 문서 문장(원문 그대로, 원문 대조 검사)으로 정한다.
  - 종류가 크게 바뀔 때만 추천한다 — 같은 조건은 다시 묻지 않는다.
  - 바뀐 일이 크고(예: 긴 계획 구현) 이 세션 맥락이 크면, effort 를 바꾸는 대신 알맞은 effort 의 새 세션을 제안한다. 작은 일은 지금 effort 그대로.
  - 기존 세션 기록으로 '이렇게 했다면'(추천 횟수 · 새 세션 제안 횟수 · 피한 캐시 미스)을 잰다.
- **Non-Goals**
  - 세션 effort 를 SCV 가 직접 바꾸기.
  - 매 질의마다 추천하기(사용자 결정: 종류가 바뀔 때만).
  - API 의 캐시 진단(diagnostics) 호출 — SCV 는 API 요청을 만들지 않는다.

## Approach Overview

1. 측정: 헤드리스 `claude -p` 로 같은 대화를 이어 가며 effort 를 그대로 둔 턴과 바꾼 턴의 캐시 읽기 · 새로 쓰기 토큰을 견준다(여러 번).
2. 판정: 사람 요청 글과 맥락 신호(진행 중 계획 · 실행 중 작업 · 요청 길이)로 일의 종류를 가르는 순수 함수, 종류 → 모델별 권장 effort 를 공식 문장 표(EFFORT.tsv 를 넓힘)에서 찾는 순수 함수.
3. 추천 · 제안: 종류가 바뀌었고 권장값이 지금 effort 와 다르면 한 번 묻는다. 1번 측정에서 effort 변경이 캐시를 깨면, 바뀐 일이 큰 경우 새 세션 제안을 첫 보기로 둔다(새 세션 도구는 호스트 프로필이 알려 줌 — 코어 글은 호스트 이름 없이).

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readTurn,        // 요청 글 · 진행 중 계획 · 지금 effort · 모델 · 맥락 크기
  taskKind,        // 요청 글 · 신호 → 일의 종류
  recommendEffort, // 모델 · 일의 종류 · 공식 표 → 권장 effort · 근거 문장
  decideOffer,     // 지금 effort · 권장 · 이전 종류 · 맥락 크기 · 물은 조건 → 묻지 않음 | effort 바꾸기 | 새 세션
  emitOffer,       // 결정 → 매 턴 글 한 줄 (출력)
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | `readTurn` | 이번 턴 신호를 읽음 | 훅 입력 · 상태 파일 → 값들 | 부수효과 (입구) |
| 2 | `taskKind` | 요청 글과 신호로 일의 종류를 가름 | 글 · 신호 → 종류 | 순수 |
| 3 | `recommendEffort` | 모델 · 종류로 공식 표에서 권장값과 근거 문장을 찾음 | 모델 · 종류 · 표 → 값 · 문장 | 순수 |
| 4 | `decideOffer` | 묻지 않음 · effort 바꾸기 · 새 세션 중 하나 | 값들 → 결정 | 순수 |
| 5 | `emitOffer` | 결정을 매 턴 글 한 줄로 · 물은 조건 기록 | 결정 → 출력 · 기록 | 부수효과 (출구) |

- 부수효과 위치: 1 · 5.
- 재사용: 0.89.0 의 권장 effort 묻기(`_effort_block` · `.effort-asked` · EFFORT.tsv · check.sh 원문 대조), 계획 판정(effort-class.sh).

### 합성 설계 체크리스트 (Composition checklist)

| # | 물음 | 답 | 근거 |
|---|---|---|---|
| 1 | 각 단계가 요소 단위 단항 순수 함수인가 | 2 · 3 · 4 는 값 → 값 | 계획 단계 표 |
| 7 | 부수효과가 파이프라인 양 끝에만 있는가 | 예 — 1 읽기, 5 출력 · 기록 | 계획 단계 표 |
| 그 밖 | 3 · 2 · 4 · 5 · 6 · 8 · 9 · 10 | 해당 없음 | 순회 · 캐시 · 비동기 없음 |

## Guardrails

- SCV 는 effort 를 바꾸지 않는다 — 추천 · 묻기 · 새 세션 제안까지.
- 근거 문장은 공식 문서 원문 그대로, 원문 대조 검사(check.sh)를 통과해야 한다.
- 매 턴 안내 글은 늘리지 않는다 — 추천은 종류가 바뀐 턴에만 한 줄.
- 코어 글에 호스트 · 도구 이름을 쓰지 않는다(새 세션 도구는 호스트 프로필 값).
- 다른 프로젝트 이름을 공개 저장소에 넣지 않는다.

## Exit criteria

- TESTS.md 시나리오 통과(맥 · 리눅스 · 코덱스 사본), 전체 실행 통과.
- 1번 측정 결과가 수치로 남음(effort 변경 전후 캐시 읽기 · 새로 쓰기).
- 기존 세션 기록으로 '이렇게 했다면' 추천 · 새 세션 제안 횟수를 잼.

## Suggested path

1. Claude Code 에서 effort 를 바꾼 다음 턴의 캐시 읽기 · 새로 쓰기를 헤드리스로 여러 번 잰다 — 측정 결과로 새 세션 제안이 필요한지 정함
2. 일의 종류를 가르는 판정을 만든다 — `readTurn`, `taskKind`
3. 공식 문장 표를 일의 종류별로 넓히고 권장값을 찾는다 — `recommendEffort`
4. 추천 · 새 세션 제안 결정과 한 줄 안내 — `decideOffer`, `emitOffer`
5. 기존 세션 기록으로 '이렇게 했다면'을 잰다 — 추천 · 제안 횟수와 피한 캐시 미스를 수치로
6. 시험 · 전체 실행(맥 · 리눅스 · 코덱스 사본) — 시험으로 확인

## Related Documents

- 측정 기록: 대화 Turn 27–28.

## Risks / Open Questions

- Claude Code 의 effort 변경이 메시지별(캐시 유지)인지 요청 전체(캐시 깨짐)인지 아직 모름 — 1단계가 정함.
- 일의 종류 판정이 틀리면 엉뚱한 추천 — 같은 조건은 한 번만 묻고, 기존 기록으로 판정을 재 봄.

## Links

- Raw originals: (listed in frontmatter)
- Wrap-up: [`WRAPUP.md`](./WRAPUP.md)
- Related PRs:
