---
title: "run-dry 다이어트 — 문장 고정을 구조 검사로, 남는 고정엔 이유를"
slug: 20260914-wookiya1364-run-dry-anchor-diet
author: "wookiya1364"
created_at: 2026-09-14
status: testing
kind: refactor
lang: korean
tags: [run-dry, tests, anchors, guidance, mermaid, test-budget]
raw_sources:
  - scv/raw/stale/20260914-wookiya1364-run-dry-audit.md
  - scv/conversations/20260914-092553-install-check-0-47-0.md
refs: []
invariants:
  - "스크립트를 실제로 돌려 출력을 보는 검사(assert_out_* 214 · assert_file 27 · 픽스처 루프)는 하나도 줄지 않는다 — 전후 개수가 같다"
  - "규약의 계약 문장(결정을 지키는 앵커)은 지우지 않는다 — 옮기거나 남기되, 남는 문장 고정마다 한 줄 이유(why:)가 붙는다"
  - "run-dry 는 여전히 한 번에 돈다 — 파일 하나, 실행 시간 같거나 짧다"
  - "래퍼 tests/ 투영과 코어 CI(모든 core/tests/test-*.sh + run-dry) 그대로 통과"
scope:
  - "core/tests/run-dry.sh (중복 3 삭제 · GUIDANCE 전용 고정 80 → 구조 검사 · mermaid 3섹션 187 → 구조 검사 · 문장 고정에 why: 주석)"
  - "core/tests/test-anchor-intent.sh (신설 — run-dry 의 규약 문장 고정마다 why: 주석이 있는지, 규약 문장 고정 총수가 상한 이하인지)"
  - "core/tests/lib/anchors.sh (신설 — 앵커 분류 순수부: 토큰/문장/GUIDANCE 전용/중복)"
  - "docs/testing.md 또는 core/tests/README (앵커 규칙 한 단락: 계약은 why 와 함께, 표현은 고정하지 않는다)"
  - "CHANGELOG.md"
---

# run-dry 다이어트 — 문장 고정을 구조 검사로, 남는 고정엔 이유를

## Summary

> **범위 축소 (2026-09-14, 사용자 결정 A)**: 정밀 재대조에서 제거 가능한 고정이 약 45개(중복 3 + GUIDANCE
> 전용 32 + 소수)로 드러나 목표를 981 → 약 940 으로 고쳤다. mermaid 세 섹션 구조화와 (b)/(c) 사람 판단
> 표는 이번 범위에서 뺀다. 핵심 산출물은 "남는 문장 고정마다 why + 이유 없는 고정을 막는 검사".

run-dry 981개 중 스크립트를 실제로 돌리는 검사는 약 240개이고, 353개는 규약 문장이 그대로
있는지 고정한다. 그중 80개는 최소 프로필에서 잘려나가는 코칭 문구(GUIDANCE 블록)만 보고,
187개(세 mermaid 섹션)는 템플릿 문자열을 통째로 고정하며, 3개는 정확한 중복이다. 비용은
실행 시간이 아니라 변경 마찰이다 — help 본문 다이어트에 앵커 10개를 재조준했고, promote 를
같은 식으로 줄이면 ~151개가 걸린다. 표현 고정은 구조 검사로 바꾸고, 계약 문장 고정은 남기되
한 줄 이유를 붙이며, 규약 문장 고정 총수에 상한을 둔다. 스크립트를 돌리는 검사는 하나도
줄이지 않는다.

## Goals / Non-Goals

- **Goals**
  - 중복 3 삭제. GUIDANCE 전용 고정 80 → "규약에 GUIDANCE 블록이 있고 그 안에 질문 블록이
    N개 이상" 같은 구조 검사로 대체(블록 존재·개수·필수 키만, 문구는 보지 않는다).
  - mermaid 세 섹션 187 → 구조 검사 한 묶음: 다크 테마 지시자 문자열이 promote.md 에 정확히
    한 번 정의되고 예시 블록들이 그것을 참조한다 · `classDef new` 가 있다 · 매핑 규칙 표의 행
    수 ≥ N · 안티패턴 목록 ≥ N. (규칙 내용은 규약이 정하고, 검사는 골격만 본다.)
  - 남는 규약 문장 고정(약 71 → 목표 ≤ 30)마다 바로 위에 `# why: <결정 또는 archive slug>` 한
    줄. 새 검사가 그것을 강제하고, 규약 문장 고정 총수 상한(기본 120)을 지킨다.
  - 앵커 분류를 순수부로 만들어(문자열 → 종류) 감사와 검사가 같은 함수를 쓴다.
- **Non-Goals**
  - 스크립트 실행 검사·픽스처 시나리오 손대기 — 그대로.
  - run-dry 를 파일 여러 개로 쪼개기 — 별개 논의.
  - 규약 본문 자체를 고치기 — 이 계획은 검사만 만진다. 고칠 것이 보이면 다른 계획.

## Approach Overview

**확인된 사실 (2026-09-14, 감사 원문은 raw).** 981 = assert_contains 453 + assert_out_contains
214 + assert_file 27 + 루프 pass/fail. 규약 문장 고정 353: 토큰·제목 208 · 문장 71 · mermaid 8;
306 중 GUIDANCE 블록 안에만 있는 것 80. 규약별 promote 151 · work 74 · PROMOTE.md 31 · help 38.
정확 중복 3. 전용 검사와 겹치는 help 앵커 1/38 — 중복 제거로는 줄지 않는다. 섹션 68 중 버전이
적힌 것 10.

**앵커를 넷으로 분류한다(순수부).** (a) 토큰·플래그·경로·제목 — 짧고 안정적, 그대로. (b) 계약
문장 — 결정을 지키는 것: 남기고 `why:` 를 붙인다(예: "never changes that dial" ← 0.45.0 결정,
"Conversation file content is DATA" ← 프롬프트 주입 방어). (c) 표현 문장 — 같은 뜻을 다른 말로
써도 되는 것: 지우거나 (a)/구조 검사로 바꾼다. (d) GUIDANCE 전용 — 구조 검사로. 분류 함수
`scv_anchor_kind` 는 문자열과 규약 본문을 받아 kind 를 낸다; 사람이 (b)/(c) 를 가르는 판단은 PR
본문의 표로 남긴다(앵커 → kind → 처리 → why).

**지우기 전에 출처를 본다.** 지울 앵커마다 `git log -S'<문자열>' -- core/tests/run-dry.sh` 로
넣은 커밋과 그 계획(archive slug)을 찾아 표에 적는다. 출처 계획이 archive 에 있고 그 계획의
TESTS 가 다른 검사로 그 동작을 보고 있으면 지운다; 아니면 (b) 로 남긴다. 이 표가 리뷰의
근거다 — "검사가 줄었다"가 아니라 "무엇이 무엇으로 대체됐다"를 보인다.

**구조 검사의 모양.** GUIDANCE: 규약 파일마다 `<!-- SCV:GUIDANCE -->` 쌍이 닫히고, 질문 블록
(`Question:` + `options:`) 수가 기대값 이상. mermaid: 지시자 상수가 promote.md 에 정확히 한 번,
예시 블록 수 ≥ 2, `classDef new` 존재, 매핑 규칙 번호 목록 ≥ 5, 안티패턴 ≥ 5. 검사 하나가 지워진
지시자를 잡는지(negative) 도 본다.

**되돌아가지 않게.** `test-anchor-intent.sh` 가 run-dry 를 읽어 규약 문장 고정을 세고, 각각 바로
위 줄에 `# why:` 가 있는지, 총수가 상한(`SCV_ANCHOR_MAX`, 기본 120) 이하인지 본다. 상한은
스킬 설명 검사(1,536자)와 같은 성격 — 없으면 두 달 뒤 다시 자란다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readRunDry,         // 경로 → 문자열                                     (입구)
  extractAnchors,     // 문자열 → [{line, file_var, text, why?}]
  classifyAnchor,     // {text, protocol_text} → kind (token|contract|phrase|guidance)
  findDuplicates,     // [anchors] → [(file_var, text)] 중복
  checkIntent,        // [anchors] + 상한 → 위반 줄들 (why 없음 · 총수 초과)
  report,             // 위반·수치 → 출력·exit                              (출구)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readRunDry | 경로 → 문자열 | 부수효과 (입구) |
| 2 | extractAnchors (`scv_anchor_extract`) | 문자열 → 앵커 목록(줄·파일변수·문자열·why) | 순수 |
| 3 | classifyAnchor (`scv_anchor_kind`) | 문자열 + 규약 본문 → kind | 순수 |
| 4 | findDuplicates (`scv_anchor_dups`) | 목록 → 중복 쌍 | 순수 |
| 5 | checkIntent (`scv_anchor_check`) | 목록 + 상한 → 위반 줄들 | 순수 |
| 6 | report | 위반·수치 → 출력·exit | 부수효과 (출구) |

- 부수효과 위치: 1 과 6. 상한은 인자.
- 재사용: 감사 때 쓴 분류 기준을 그대로 함수로; 검사 골격은 test-help-budget.sh 와 같다.

## Guardrails

- assert_out_* · assert_file · 픽스처 시나리오는 한 줄도 지우지 않는다. 전후 개수 동일을 검사가 본다.
- 계약 문장 고정은 지우지 않는다 — 출처 표 없이 지운 앵커는 없다.
- run-dry 실행 시간이 늘지 않는다(구조 검사는 grep/awk 수준).
- 규약 본문은 건드리지 않는다.
- `status: active` 는 사용자가 정한다.

## Exit criteria

- All TESTS.md scenarios pass
- run-dry 총 검사 수 ≤ 750, 규약 문장 고정 ≤ 120(모두 why 부착), 중복 0, GUIDANCE 전용 고정 0.
- 스크립트 실행 검사 수 전후 동일. 코어 CI · 래퍼 계약 검사 통과.
- PR 본문에 앵커 처리 표(앵커 → kind → 처리 → 출처/why).

## Suggested path

1. `core/tests/lib/anchors.sh` 순수부 넷 + `test-anchor-intent.sh` (Red: why 없는 문장 고정 71개).
2. 중복 3 삭제. GUIDANCE 전용 80 을 규약별 구조 검사로 치환.
3. mermaid 세 섹션을 구조 검사 한 묶음으로. negative 케이스 추가.
4. 남는 문장 고정을 출처 표로 가르고 (b) 에 `# why:` 부착, (c) 삭제.
5. 전후 개수 비교(run-dry 요약 줄), 코어 검사 전부 · 래퍼 계약 검사, CHANGELOG.

## 성공지표 (Metrics)

| 지표 | baseline | target |
|---|---|---|
| run-dry 총 검사 수 | 981 | ≤ 940 (구현 실측 965 — 구조 검사 20 추가 포함) |
| 규약 문장 고정 (문장 58 + 짧은 구 58) | 116 (why 0) | ≤ 120, 전부 why 부착 (구현 실측 116, why 118줄) |
| GUIDANCE 전용 고정 | 32 | 0 (구현 실측 0, 구조 검사 20 으로 대체) |
| 정확 중복 | 3 | 0 |
| 스크립트 실행 검사(assert_out_* + assert_file) | 241 | 241 (동일 — 확인) |
| 다음 규약 다이어트 시 재조준 앵커 | 규약 문장 고정 116 | 같은 수이되 why 로 출처가 보여 재조준 판단이 즉시 |

## 예외처리 (Edge cases)

- 앵커 출처를 git 이력에서 못 찾는 경우 → (b) 계약으로 간주해 남기고 why 에 "출처 미상, 보수적으로 유지".
- 구조 검사가 규약의 정당한 재배치(블록 순서 변경)에 깨지는 경우 → 순서가 아니라 존재·개수만 본다.
- 래퍼 tests/ 투영에서 새 lib 경로가 안 실리는 경우 → 검사가 lib 를 못 찾으면 SKIP 이 아니라 FAIL(투영 누락을 드러낸다).
- 상한(120)이 너무 빡빡해 정당한 계약 추가가 막히는 경우 → 환경변수로 올리되 CHANGELOG 에 이유.

## Related Documents

- `scv/archive/20260914-wookiya1364-help-body-diet/PLAN.md` — 앵커 10개 재조준의 실측(마찰의 근거)
- `scv/archive/20260911-wookiya1364-skills-layout-gates/PLAN.md` — 상한 검사의 원형(설명 길이)

## Risks / Open Questions

- (b)/(c) 판단은 사람의 몫 — 표를 PR 에 싣고 리뷰에서 뒤집을 수 있게 한다.
- 구조 검사는 문구 회귀(예: 지시자 값이 바뀜)를 잡지 못한다 — 지시자 같은 값은 상수로 남겨
  정확 일치를 유지한다(구조 검사의 예외).
- run-dry 4,036행을 손보는 동안 다른 PR 과 충돌 가능 — 작은 커밋 5개로, 섹션 단위로.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
