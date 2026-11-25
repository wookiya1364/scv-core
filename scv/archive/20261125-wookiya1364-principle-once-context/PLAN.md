---
title: 원칙 글도 맥락에 한 번만 — 판정을 지문 비교에서 맥락 표시로
slug: 20261125-wookiya1364-principle-once-context
author: wookiya1364
created_at: 2026-11-25
status: in_progress
kind: feature
lang: korean
tags: [per-turn-text, principle, hooks]
raw_sources:
  - scv/conversations/20261124-200447-dashboard-gears-ask-mode.md
refs: []
invariants:
  - "SCV_RULES_ONCE=off 에서는 원칙 글의 출력이 이 일 전과 바이트까지 같다(지문 비교 그대로)"
  - "SCV_REWRITE_PRINCIPLE=off 에서는 원칙 글을 한 줄도 싣지 않는다"
  - "원칙 글의 내용과 원칙 검사(종료 훅)는 그대로다"
---

# 원칙 글도 맥락에 한 번만 — 판정을 지문 비교에서 맥락 표시로

## Summary

보관한 계획 `20261120-wookiya1364-rules-once-no-caps` 의 마지막 측정(실제 세션 35개 · 사람 턴 1,530개)에서, 매 턴 규칙 글은 한 줄로 줄었지만 함께 붙는 원칙 글(약 2.5 KB)이 한 줄 턴 108개 중 105개에 전부 실리고 있었다. 그래서 턴 전체 글이 줄지 않았다(평균 6.3 → 6.1 KB).

까닭은 판정 근거다. 규칙 글은 0.97.1 에서 "이 맥락에 실었다는 표시"로 판정을 옮겼지만, 원칙 글은 여전히 규약 지문을 견준다. 지문은 종료 검사가 규약을 다시 읽게 할 때마다 바뀌므로, 실제 긴 세션에서는 거의 매 턴 "처음"으로 보인다. 이 계획은 원칙 글의 판정도 맥락 표시로 옮긴다.

## Goals / Non-Goals

- **Goals**
  - 원칙 글 전문은 첫 턴, 대화가 요약 · 비움 · 재개된 뒤 첫 턴, 직전 답에 원칙 경고가 남은 턴에만 싣는다. 그 밖의 턴은 한 줄이다.
  - 대화 초기화(요약 · 비움 · 재개)가 원칙 표시도 지운다.
  - 실제 세션 기록으로 전 · 후 크기를 다시 계산해 숫자로 보인다.
- **Non-Goals**
  - 원칙 글의 내용 바꾸기.
  - 규칙 글 판정, 첫 행동 · 등록 안내 줄이기.
  - 다른 경고(확인 범위 · 글로 물음)가 남은 턴에 원칙 전문을 다시 싣는 일 — 원칙 경고만 본다.

## Approach Overview

- 판정: `_principle_block` 이 세션 턴 폴더의 `.principle-seen` 을 "실었다는 표시"로만 본다(안의 값은 견주지 않는다). 표시가 있고 원칙 경고가 없으면 한 줄, 아니면 전문을 싣고 표시를 쓴다.
- 원칙 경고: 이 세션의 경고 글에 원칙 검사가 남긴 줄(`[SCV 원칙]` 으로 시작)이 있는지를 순수 함수 하나가 가른다.
- 판정 함수는 새로 만들지 않는다 — 규칙 글의 `scv_mp_rules_show`(표시 · 표시 · 경고 → full | short)를 그대로 쓴다.
- 초기화: `help-state.sh reset` 이 지우는 목록에 `.principle-seen` 을 더한다(`.rules-seen` 옆).
- 끄기: `SCV_RULES_ONCE=off` 면 이 일 전의 지문 비교(`scv_mp_principle_show`)로 간다.
- 옛 표시 파일(안에 지문이 든 것)은 "실었다"로 읽는다 — 올린 직후 턴에 전문이 한 번 덜 실릴 뿐이고, 그 맥락에는 원칙 글이 이미 있다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readPrincipleState,          // 세션 턴 폴더 → 실었다는 표시 · 경고 글
  scv_mp_warn_has_principle,   // 경고 글 → 0 | 1
  scv_mp_rules_show,           // 표시 · 표시 · 0|1 → full | short
  emitPrinciple,               // full | short → 전문 또는 한 줄, 표시 쓰기
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | `readPrincipleState` | 이 세션의 원칙 표시와 경고 글을 읽는다 | 세션 턴 폴더 → 표시 · 경고 글 | 부수효과 (입구) |
| 2 | `scv_mp_warn_has_principle` | 경고 글에 원칙 검사가 남긴 줄이 있는지 가른다 | 경고 글 → 0 · 1 | 순수 |
| 3 | `scv_mp_rules_show` | 표시가 있고 경고가 없으면 한 줄, 아니면 전문 | 표시 · 표시 · 0·1 → full · short | 순수 |
| 4 | `emitPrinciple` | 전문이면 원칙 글을 싣고 표시를 쓴다, 아니면 한 줄 | full · short → 출력 · 표시 | 부수효과 (출구) |

- 부수효과 위치: 1(파일 읽기) · 4(출력 · 표시 쓰기). 1 · 4 는 `_principle_block` 안에 있다.
- 재사용: `scv_mp_rules_show`(계획 rules-once-no-caps), 끈 설정에서는 `scv_mp_principle_show`, 초기화는 `help-state.sh reset`.

### 합성 설계 체크리스트 (Composition checklist)

| # | 물음 | 답 | 근거 |
|---|---|---|---|
| 1 | 각 단계가 요소 단위 단항 순수 함수인가 | 예 — `scv_mp_warn_has_principle` 은 글 하나 → 0·1, `scv_mp_rules_show` 는 값 셋 → 모드 | core/scripts/lib/model-prompting.sh 의 두 함수(사전 judge-gate.md 에 예시와 함께) |
| 2 | 단계의 입출력이 밝혀져 있고 입력은 필요한 것만 받는가 | 예 — 판정 둘은 받은 글 · 값만 보고 파일 경로를 모른다 | 같은 두 함수 |
| 7 | 부수효과가 파이프라인 양 끝에만 있는가 | 예 — 표시 · 경고 읽기와 출력 · 표시 쓰기는 `_principle_block` 한 곳, 초기화는 `help-state.sh reset` | core/scripts/model-prompting.sh `_principle_block`, core/scripts/help-state.sh reset 가지 |
| 10 | 자주 도는 곳은 측정한 뒤에 고쳤는가 | 매 턴 도는 곳이다 — 더한 것은 작은 파일 읽기와 글 견주기 한 번. 끝날 때 재는 검사: 달라진 사전 함수 중 한도 넘음 0 | `core/scripts/pure-bench.sh plan-end` |
| 그 밖 | 3 · 4 · 5 · 6 · 8 · 9 | 해당 없음 | 순회 · 지연 평가 · 복사 · 비동기가 없다 |

## Guardrails

- 원칙 글의 내용, 원칙 검사(종료 훅), 규칙 글 판정은 건드리지 않는다.
- `SCV_RULES_ONCE=off` 에서 출력이 이 일 전과 바이트까지 같다.
- 다른 세션의 표시 · 경고를 섞지 않는다(세션 턴 폴더만).
- 매 턴 글 한도 시험(`core/tests/test-instruction-diet.sh`)의 상한은 올리지 않는다 — 줄어드는 쪽이다.
- 맥(기본 셸 3.2 포함) · 리눅스 둘 다. 공개 저장소에 다른 프로젝트 이름을 넣지 않는다.
- 훅 템플릿을 바꾸면 템플릿 지문(`core/TEMPLATE_DIGEST`)을 다시 만든다.

## Exit criteria

- TESTS.md 의 모든 시나리오 통과(맥 기본 셸 · 새 셸 · 리눅스).
- 지문이 바뀐 둘째 턴의 원칙 글이 한 줄이다(바이트 수로 확인).
- 실제 세션 기록 재계산: 한 줄 턴의 매 턴 글 크기 전 · 후 값을 마무리 보고에 적는다.
- 순수 함수 사전 검사 통과, 푸시 전 전체 실행 통과.

## Suggested path

1. 재현 시험 먼저 — 지문이 바뀐 둘째 턴에 원칙 전문이 실려 실패하는 시험을 쓴다 — 고치기 전에 실패하는 것을 본다
2. 원칙 경고 가르기와 판정 옮기기 — `scv_mp_warn_has_principle`, `scv_mp_rules_show`, `readPrincipleState`, `emitPrinciple`
3. 대화 초기화가 원칙 표시도 지우게 한다 — 요약 · 비움 · 재개 뒤 첫 턴에 전문이 다시 실리게 한다
4. 지금 동작을 고정한 기존 시험을 새 동작에 맞춘다 — 지문이 바뀌어도 한 줄, 초기화 뒤에는 전문
5. 실제 세션 기록으로 전 · 후 크기를 다시 계산한다 — 한 줄 턴의 글 크기를 숫자로 낸다
6. 순수 함수 사전 · 관련 시험 · 전체 실행을 맥과 리눅스에서 돌린다 — 두 환경에서 같은 결과인지 본다

## Related Documents

- 측정 근거: `scv/archive/20261120-wookiya1364-rules-once-no-caps/WRAPUP.md` 4 · 6번.

## Risks / Open Questions

- 긴 맥락에서 원칙이 흐려질 수 있다(추정) — 원칙 경고가 남은 턴과 초기화 뒤 첫 턴에 다시 싣는 것으로 막는다. 릴리스 뒤 실제 세션의 원칙 경고 비율을 본다.
- 재계산은 "이렇게 했다면"의 값이다 — 지난 계획에서 재계산 값과 실제 값이 달랐다. 릴리스 뒤 실제 세션으로 다시 잰다.

## Links

- Raw originals: (listed in frontmatter)
- Wrap-up: [`WRAPUP.md`](./WRAPUP.md)
- Related PRs:
