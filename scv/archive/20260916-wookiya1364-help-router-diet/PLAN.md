---
title: "매 턴 라우터 다이어트 — 답 모양은 남기고 나머지는 압축, 진단 안내문은 직접 부를 때만"
slug: 20260916-wookiya1364-help-router-diet
author: "wookiya1364"
created_at: 2026-09-16
status: planned
kind: refactor
epic: 20260914-help-turn-cost
lang: korean
tags: [help, router, token-cost, preflight, diagnosis, budget]
raw_sources:
  - scv/raw/stale/20260916-always-on-per-turn-cost-diet.md
  - scv/raw/stale/20260916-graph-dependency-decision.md
  - scv/conversations/20260914-092553-install-check-0-47-0.md
refs: []
invariants:
  - "언어 절·쉬운 말 절·답 모양 절은 라우터에 바이트 그대로 남는다 (run-dry [15p] 공통 문구 · 사용자의 잊음 우려에 대한 답)"
  - "매 턴 기록 계약은 그대로 — 기록 형식(Turn 제목 · protocol: <fingerprint> 줄 · User/Claude Code 블록), 헬퍼 호출, 표식 mark, 지문 규칙"
  - "동작은 바꾸지 않는다 — 진단 내용(의존성·raw·계획 수) 과 brief/full 전환, 사용자가 직접 부른 /scv:help 의 전체 출력은 그대로"
  - "부속 파일(full.md 등)에는 쉬운 말 절·언어 절이 없다 (budget T4)"
  - "훅은 non-blocking, scv/journal/ 밖에 쓰지 않음"
scope:
  - "core/protocols/help.md (라우터: 배경 조사 절 → full.md 로 이동, 나머지 절 압축, Final notes 제거)"
  - "core/protocols/help/full.md (배경 조사 절 수용)"
  - "core/scripts/lib/force-help.sh (scv_force_trim_diagnosis: 진단 본문 + 권장 행동 첫 줄만, Learn more 제거)"
  - "core/tests/test-help-budget.sh (상한 하향 · preflight 진단 크기 검사 추가) · core/tests/test-delegate-effort.sh (절 위치) · core/tests/test-force-help.sh (필요 시)"
  - "core/tests/test-help-router-diet.sh (신설)"
  - "CHANGELOG.md"
---

# 매 턴 라우터 다이어트 — 답 모양은 남기고 나머지는 압축, 진단 안내문은 직접 부를 때만

## Summary

매 턴 실리는 help 라우터는 10.9KB(SKILL.md 기준, 원본 help.md 9,670B)이고 훅 블록·헬퍼 출력을
더한 턴 스택은 ≈12.6KB 다. 0.49 계획이 라우터 4,000B 를 목표로 잡고도 "답 모양 절은 매 턴
남긴다(잊음 우려)" 로 9.4KB 에 멈췄다. 이번엔 그 결정을 존중해 **답 모양·언어·쉬운 말 절은
그대로 두고**, 나머지 절(기록 계약·헬퍼 호출·규약 읽기·배경 조사·마무리)을 압축·이동해
라우터를 ≤ 7,200B 로 만든다(실측 7,115B). 함께, 진단이 바뀐 턴에 preflight 가 싣는 전체
진단(3.3KB) 에서 매번 같은 안내문("Learn more" 0.6KB · hydrate 방법 0.9KB) 을 빼고 진단
본문과 권장 행동 한 줄만 싣는다 — 안내문은 사용자가 직접 /scv:help 를 쳤을 때만 보인다.
동작은 바꾸지 않는다. 상한 검사를 낮춰 잠가 두 달 뒤 다시 자라지 않게 한다.

## Goals / Non-Goals

- **Goals**
  - 라우터 ≤ 7,200B (지금 9,670B; 7,000 목표는 고정 절·문구 바닥에 걸려 7,200 으로 조정). 매 턴 스택 ≤ 9,500B (지금 ≈12.6KB).
  - 변동 턴 preflight ≤ 2,000B (지금 3,266B) — 진단 본문 + 권장 행동 첫 줄.
  - 답 모양·언어·쉬운 말 절과 기록 계약은 바이트/의미 그대로.
  - 상한 검사: BODY 7,500 · TURN 9,500 · FULL 9,000 · TOTAL 32,000 유지.
- **Non-Goals**
  - 답 모양 절을 full.md 로 옮기는 것 (사용자 결정: 매 턴 유지).
  - 매 턴 Skill 호출 자체를 없애는 것(훅이 명령을 대신 싣는 방식) — 계약 변경이 커서 별도.
  - 강제 호출 블록(훅 1,082B) 문구 변경 — 강도 검사와 얽혀 있어 손대지 않는다.
  - 진단 내용 자체의 변경.

## Approach Overview

1. **라우터 압축** (core/protocols/help.md): 배경 조사 절(710B)은 full.md 로 통째 이동(훅이
   스위치 on 일 때 매 턴 같은 규칙을 싣는다). "Never hand the turn back" 은 3문장으로,
   "Run the help script" 는 두 명령과 파싱 줄 목록만, "full protocol once" 는 load/loaded 두
   갈래만, "Every turn" 은 기록 템플릿(지문 줄 포함)·append 명령·한 모양 규칙만, "Final notes" 는
   삭제. 언어·쉬운 말·답 모양 절은 손대지 않는다.
2. **진단 다듬기** (lib/force-help.sh 의 순수 함수): 이미 "Current project diagnosis" 앞을
   버리는 `scv_force_trim_diagnosis` 를 확장해 (a) "Learn more" 블록을 통째로 버리고, (b) "Recommended
   next action" 은 제목과 첫 내용 줄만 남긴다. 사용자가 직접 부른 help.sh 출력은 그대로(훅만
   이 함수를 지난다).
3. **상한 잠금** (test-help-budget.sh): BODY_MAX 10,000→7,500, TURN_MAX 12,000→9,500, FULL_MAX
   8,000→9,000. 새 검사 T13: 훅의 전체 진단(변동 턴)에 "Learn more"·hydrate 명령 줄이 없고 ≤ 2,000B.
4. **검사 이동**: test-delegate-effort 의 절 위치를 full.md 로.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readRouter,           // help.md 파일 → 텍스트                                     (입구, 부수효과 — 검사·측정만)
  sectionSizes,         // 텍스트 → {절 이름: 바이트}                                  순수 (검사용, 기존 awk 한 줄)
  budgetCheck,          // (바이트, 상한, 이름) → 위반 줄                                순수 (기존 scv_help_budget)
  probeDiagnosis,       // help.sh 실행 → 전체 출력                                    (부수효과, 훅)
  trimDiagnosis,        // 전체 출력 → 진단 본문 + 권장 행동 첫 줄 (Learn more 제거)        순수 (기존 scv_force_trim_diagnosis 확장)
  diagMode,             // (표식, 다듬은 진단) → brief|full                              순수 (기존 scv_hstate_diag, 변경 없음)
  emit,                 // 훅 stdout                                                  (출구)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readRouter | 파일 경로 → 텍스트 | 부수효과 (검사의 입구) |
| 2 | sectionSizes | 텍스트 → 절별 바이트 | 순수 |
| 3 | budgetCheck | 바이트·상한·이름 → 위반 줄 (없으면 빈) | 순수 (기존) |
| 4 | probeDiagnosis | 없음 → help.sh 전체 출력 | 부수효과 (훅) |
| 5 | trimDiagnosis | 전체 출력 → 다듬은 진단 | 순수 (기존 함수 확장: Learn more 제거 · 권장 행동 첫 줄만) |
| 6 | diagMode | 표식·다듬은 진단 → brief/full | 순수 (기존, 변경 없음) |
| 7 | emit | 다듬은 진단 또는 한 줄 → stdout | 부수효과 (출구) |

- 부수효과 위치: 1·4(읽기/실행) · 7(출력). 2·3·5·6 은 문자열만 받는다.
- 재사용: 3(scv_help_budget)·5(scv_force_trim_diagnosis)·6(scv_hstate_diag) 은 기존 순수부 — 5 만 확장한다.

## Guardrails

- 언어·쉬운 말·답 모양 절: `git show develop:core/protocols/help.md` 의 해당 절과 바이트 동일 (검사 T2).
- 기록 템플릿의 `protocol: <fingerprint>` 줄과 "Append, never overwrite" 문구, 헬퍼·mark·journal-append 세 명령은 라우터에 남는다 (test-help-echo T2 가 본다).
- 배경 조사 절은 문구 그대로 full.md 로 — 압축하지 않는다 (test-delegate-effort 가 문구를 본다).
- 진단 다듬기는 훅 경로에만. `help.sh` 직접 출력은 바이트 그대로 (T6).
- 권장 행동 블록이 없거나 진단 자체가 없으면(help.sh 실패) 지금처럼 전부 통과시킨다 — 잘라서 빈 진단을 만들지 않는다.
- 상한을 낮출 뿐 올리지 않는다 (FULL 만 배경 조사 절 수용분으로 +1,000).

## Exit criteria

- All TESTS.md scenarios pass
- 코어 검사 전체(48개)·run-dry·루트 계약 러너 녹색.
- 실사용 한 세션: 변동 없는 턴의 스택 ≤ 9.5KB, 변동 턴 preflight 에 "Learn more" 없음 — 훅 출력 크기로 확인.

## Suggested path

1. 검사부터: test-help-router-diet.sh 신설(T1~T7) + budget 상한 하향 → 붉음 확인.
2. help.md 압축·배경 조사 절 이동 → T1·T2·T3·T4 녹색.
3. scv_force_trim_diagnosis 확장 → T6·T7 녹색. test-delegate-effort 위치 갱신.
4. 코어 검사 전체·run-dry → CHANGELOG.

## 성공지표 (Metrics)

| 지표 | baseline (0.50.0, 2026-09-16 실측) | target |
|---|---|---|
| 라우터 help.md | 9,670B | ≤ 7,200B (상한 7,500) — 실측 7,115B |
| 매 턴 스택 (변동 없는 턴: 훅 + 라우터 + 헬퍼) | ≈12.6KB (SKILL.md 기준) / budget T12 ≈11.4KB (help.md 기준) | ≤ 9,500B |
| 변동 턴 preflight 진단 | 3,266B | ≤ 2,000B |
| full.md | 7,151B | ≤ 9,000B |
| 동작 변화 | — | 0 (기존 검사 전부 녹색, 진단 내용 동일) |

## 예외처리 (Edge cases)

- 권장 행동 블록의 첫 내용 줄이 비어 있거나 없음 → 제목만 남기고 넘어간다.
- "Learn more" 가 없는 출력(래퍼가 다른 진단을 붙인 경우) → 그대로 통과.
- 진단 앞에 자동 갱신 보고(stderr 고르기)가 붙는 경우 → 기존 순서(보고 → 진단) 유지.
- 표식 해시는 다듬은 텍스트로 계산되므로 이번 변경 직후 첫 턴은 full 이 한 번 더 뜬다(정상).
- 래퍼가 옛 full.md 를 갖고 있으면 배경 조사 절이 잠시 어디에도 없다 — 스위치 on 이면 훅이 같은 규칙을 매 턴 싣고 있어 동작 공백 없음.

## Related Documents

- scv/raw/20260916-always-on-per-turn-cost-diet.md — 실측·제약 (run-dry [15p], budget T4, 0.49 결정의 path delta)
- scv/archive/20260914-wookiya1364-help-body-diet/PLAN.md — 1차 다이어트(28KB→9.4KB)와 상한 검사의 출발
- scv/archive/20260914-wookiya1364-help-load-once/PLAN.md — 세션당 한 번 규약과 brief/full 진단

## Risks / Open Questions

- 라우터 압축으로 문장이 줄면 모델이 기록 계약을 덜 지킬 가능성 — 0.50.0 의 지문·린트가 잡는다. 실사용 드리프트 로그로 확인.
- 매 턴 Skill 호출을 없애는 더 큰 다이어트(−3~4KB 추가)는 always-on 계약(강제 호출 검사들)과 얽혀 있어 별도 계획으로.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs: #217 (같은 브랜치에 포함)
