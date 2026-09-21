---
title: 후속 다섯 — 문구 앵커, 경계 계약 한 곳, 재실행 시간 초과 안내
slug: 20260921-wookiya1364-followup-five
author: wookiya1364
created_at: 2026-09-21
status: testing
kind: feature
lang: korean
tags: [followup, guard, contracts, rule-constitution, pr-helper, release]
raw_sources:
  - scv/conversations/20260921-152000-plugin-0560-apply-check.md
refs: []
invariants:
  - "가드 예외 목록은 여전히 '어떤 줄이 왜 예외인지' 를 한 곳(guard.md)에 적고, 검사가 어긋남을 잡는다 — 앵커 형태만 바뀐다"
  - "세 프로토콜(codegen·work·regression)이 지키는 경계(범위 밖 파일·보관 TESTS 본문·ARCHIVED_AT)는 문장이 옮겨져도 요구가 같다"
  - "pr-helper 의 증거 재실행은 실패해도 PR 생성을 막지 않는다 — 메시지만 정확해진다"
  - "run-dry [11s] 의 계약(프로토콜이 규범을 담는다)은 포인터로 유지"
  - "기존 테스트 전부 통과, 맥·리눅스 동일"
scope:
  # 3. 줄 번호 앵커 → 문구 앵커
  - core/contracts/guard.md
  - tests/test-guard-consistency.sh
  # 4. 경계 계약 한 곳 + 포인터, 검사 (b) 빚 3건 → 0
  - core/contracts/boundaries.md
  - core/protocols/codegen.md
  - core/protocols/work.md
  - core/protocols/regression.md
  - core/tests/run-dry.sh
  - core/tests/fixtures/rule-constitution/**
  # 5. 재실행 시간 초과를 이름 붙여 알린다
  - core/scripts/pr-helper.sh
  - core/tests/test-attachments-scope.sh
  # 기록·장부
  - scv/DECISIONS.md
  - scv/INDEX.tsv
  - scv/readpath.json
  - scv/conversations/**
  - CHANGELOG.md
  - VERSION
---

# 후속 다섯 — 문구 앵커, 경계 계약 한 곳, 재실행 시간 초과 안내

## Summary

0.56.0 을 배송하며 남긴 후속 다섯 중 코어 몫 셋을 닫는다(코덱스 문서 정정은 래퍼 PR #215 로 이미 병합, 대화 기록은
이 계획의 PR 에 실린다). 가드 예외 앵커를 줄 번호에서 문구로 바꿔 문서를 줄여도 어긋나지 않게 하고, 세 프로토콜에 흩어진
경계 문장을 계약 한 곳으로 모아 검사 (b) 의 기준선을 0 으로 만들고, PR 도우미의 증거 재실행이 시간 초과로 끝났을 때 그렇게
말하게 한다. 끝나면 코어 0.57.0 과 래퍼 둘을 릴리스한다.

## 사용자 결정 (2026-09-21, 대화 Turn 4–5)

| # | 후속 | 결정 | 확인한 현재 상태 |
|---|---|---|---|
| 1 | 대화 기록 미커밋 | 이 PR 에 포함 | 세션 파일 1개 미추적 |
| 2 | 코덱스 갱신 명령 문구 | 래퍼 docs 정정 + 게시 본문 편집 | **완료** — scv-codex PR #215 병합, v0.56.0-codex.1 본문 편집 |
| 3 | 줄 번호 앵커 | 문구 앵커로 | guard.md `guard:exceptions` 블록에 `path:line — reason` 6줄; 검사 [2] 는 `rel:line` 일치, [3] 은 그 줄에 문구가 있는지. 오늘 promote.md 를 11줄 줄이자 한 앵커가 어긋남 |
| 4 | 검사 (b) 빚 3건 | 한 곳으로 | "Never modify the body of an archived TESTS.md…"(codegen 50·regression 18·work 26), "Never delete or move files outside the scope"(codegen 53·work 22), "TESTS.md, ARCHIVED_AT.md, and other files are never touched"(regression 114·work 544 — 9c 질문 템플릿 안). run-dry 1252 가 regression 의 첫 문장을 고정 |
| 5 | 재실행 비정상 종료 | 조사, 원인 나오면 수정 | pr-helper 는 `run-plan-tests.sh --timeout 600`(기본, `SCV_ATTACHMENTS_RERUN_TIMEOUT`)으로 재실행하고 0 이 아니면 "exited non-zero" 한 줄. 이 저장소 계획의 실행 명령은 단독으로도 600초를 넘긴다(측정: 아래 Risks) — 원인은 **시간 초과**로 추정, 실행기 exit 124 로 확인 |

## Goals / Non-Goals

- **Goals**
  - guard.md 예외가 `path:"문구" — reason` 꼴이고, 검사 [2] 는 그 파일에서 그 문구를 담은 줄을 예외로, [3] 은 문구가 정확히 한 줄에 있고 그 줄이 검사 어휘에 걸리는지 본다. 프로토콜의 줄 수가 바뀌어도 어긋나지 않는다.
  - `core/contracts/boundaries.md` 한 곳에 경계 셋(범위 밖 파일 삭제·이동 금지, 보관 TESTS 본문 불변 + 폐기는 프런트매터 3필드, ARCHIVED_AT 불변). codegen·work·regression 은 한 줄 포인터. 9c 질문 템플릿의 반복은 허용목록(이유: 두 액션이 같은 질문을 사용자에게 보여준다). 기준선 0건.
  - pr-helper 재실행이 exit 124 면 "re-run timed out after Ns (SCV_ATTACHMENTS_RERUN_TIMEOUT)" 로, 그 외 0 아님이면 종료 코드를 붙여 말한다. 계속 진행하는 동작은 그대로.
  - 코어 0.57.0 → 래퍼 0.57.0 · 0.57.0-codex.1 릴리스. 코덱스 릴리스 노트의 "올리는 법" 은 정정된 명령으로.
- **Non-Goals**
  - 재실행 기본 제한(600초) 변경 — 일반 프로젝트엔 충분하고, 이 저장소는 설정으로 올린다(설정 파일은 로컬).
  - 검사 (b) 어휘·키 알고리즘 변경. 가드 문구 집합(PHRASES) 변경.

## Approach Overview

1. **문구 앵커** — 형식 `core/protocols/promote.md:"Raw originals under" — reason`. 검사: 앵커 파싱을 `:"…"` 로, `anchor_matches <rel> <text>` 는
   같은 파일의 앵커 문구가 `text` 에 포함되면 참. [3]: 문구가 파일에서 정확히 한 줄에 나타나고(`grep -cF`) 그 줄이 PHRASES 에 걸린다.
   0 줄이면 "the excused phrase is no longer there", 2줄 이상이면 "ambiguous — phrase matches N lines". 여섯 앵커를 현재 줄의
   고유 문구로 다시 쓴다. 이 검사는 래퍼에도 벤더링되어 도는 계약 검사라 형식 변경은 guard.md 와 함께 간다.
2. **경계 계약** — `boundaries.md`: 왜(세 프로토콜 복제, 검사 (b) 빚), 무엇을(경계 셋 + 폐기 표시 3필드), 어디서 가리키나, 검사.
   codegen·work 의 Non-negotiable 두 줄 → 한 줄 "Boundaries — what this action never touches — per `core/contracts/boundaries.md`";
   regression 18행 동일. codegen 의 "Never modify the body of TESTS.md during codegen — the test is the spec" 은 다른 요구라 그대로.
   run-dry 1252 → `contracts/boundaries.md` 포인터 검사로 바꾸고 세 프로토콜 모두 검사. 허용목록에 9c 템플릿 키 한 줄, 기준선은 주석만.
3. **재실행 메시지** — pr-helper 256–258: 종료 코드를 받아 124 면 시간 초과 문구(제한 초와 설정 키 이름), 아니면 "exited <rc>".
   test-attachments-scope T2 에 픽스처 하나: How-to-run 이 `sleep 5` 인 슬러그를 `SCV_ATTACHMENTS_RERUN_TIMEOUT=1` 로 돌려 stderr 에
   "timed out after 1s" 가 있는지. `timeout` 명령이 없는 환경이면 건너뛴다(맥은 coreutils 없이 없을 수 있다 — 검사가 스스로 판단).
4. **릴리스** — VERSION 0.57.0 · CHANGELOG · PR → promote → 래퍼 둘(핀 PR → 릴리스 PR → promote). 코덱스 노트는 정정된 갱신 명령.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  block_exceptions,     // guard.md → 앵커 줄들 (효과: 파일 읽기)
  parse_anchor,         // 앵커 줄 → (파일, 문구)            ← 형식 변경
  phrase_lines,         // (파일, 문구) → 일치 줄 번호들 (효과: 파일 읽기)
  judge_anchor,         // 일치 줄 수, 줄 본문 → ok | stale | ambiguous   ← 순수
  report,               // 판정들 → pass/fail 출력 (효과)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | block_exceptions | guard.md → 앵커 줄들 | 부수효과 (입구) |
| 2 | parse_anchor | 앵커 줄 → 파일·문구 | 순수 |
| 3 | phrase_lines | 파일·문구 → 줄 번호들 | 부수효과 (파일 읽기) |
| 4 | judge_anchor | 줄 수·본문 → 판정 | 순수 |
| 5 | report | 판정들 → 출력 | 부수효과 (출구) |

- 부수효과 위치: 1·3(읽기)·5(출력). 2·4 는 문자열만 다룬다.
- 재사용: [2] 의 파일 순회와 PHRASES 매칭은 그대로, `anchor_matches` 만 (파일, 본문) 서명으로.
- pr-helper 메시지는 `rc → 문구` 한 단계(순수)를 인라인로 두되 종료 코드를 변수로 받아 분기.

## Guardrails

- guard.md 의 예외 여섯은 **같은 여섯 줄**을 계속 가리킨다 — 문구를 고를 때 그 줄에만 있는 어구를 쓴다.
- `PHRASES`(가드 검사 어휘)와 `SCAN_DIRS` 는 손대지 않는다.
- boundaries 계약은 문장을 옮길 뿐 요구를 바꾸지 않는다. codegen 의 "the test is the spec" 문장은 남긴다.
- run-dry [11s] 의 다른 assert 들("regression — true regression" 등)은 그대로.
- pr-helper 는 재실행 실패·시간 초과 어느 쪽이든 계속 진행한다(exit 0 유지).
- 맥·리눅스 동일: `grep -cF` 로 문구를 세고, `sed -i` 접미사 없이 쓰지 않는다.

## Exit criteria

- All TESTS.md scenarios pass
- `bash tests/run.sh` · `core/tests/run-dry.sh` · `core/tests/test-*.sh` 전부 초록(맥 로컬 + PR CI ubuntu·macos)
- `test-rule-constitution.sh` (b): 기준선 0건(주석만), 허용목록 7건
- 코어 v0.57.0 + 래퍼 v0.57.0 · v0.57.0-codex.1 "Latest"

## Suggested path

1. 문구 앵커: guard.md 여섯 줄 다시 쓰기 → test-guard-consistency 파서·[2]·[3] → `bash tests/run.sh` (T1).
2. boundaries.md → 세 프로토콜 포인터 → run-dry 1252 교체 → 허용목록 + 기준선 → rule-constitution 본검사·자가검사 (T2).
3. pr-helper 종료 코드 분기 + test-attachments-scope 픽스처 (T3).
4. 결정 로그, VERSION 0.57.0, CHANGELOG, 전체 검사 → PR(대화 파일 포함) → promote → 래퍼 둘 (T4·T5).

## Related Documents

- `scv/archive/20260921-wookiya1364-open-items-followup/PLAN.md` — 이 후속의 출처(오늘 아침 배송)
- `core/contracts/decisions.md` · `core/contracts/recording.md` — 계약 문서의 골격

## Risks / Open Questions

- **시간 초과 가설의 측정**: 계획 실행 명령을 단독으로 돌린 시간을 이 계획의 TESTS T3 에 기록한다. 600초 미만이면 가설이 틀린 것이고, 그때는 종료 코드를 그대로 보고하는 변경만 남긴다.
- **문구 앵커의 고유성**: 문구가 나중에 다른 줄에도 생기면 [3] 이 "ambiguous" 로 알린다 — 그때 문구를 더 길게.
- **래퍼 사본에서의 검사 [2][3]**: 래퍼는 `action:` 을 호스트 표기로 바꾼다. 앵커 문구에 `action:` 을 넣지 않는다.
- **9c 템플릿 허용**: 두 액션이 같은 질문을 보여주는 것은 의도이나, 언젠가 하나로 모으면 허용목록에서 뺀다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs: scv-codex #215 (문서 정정, 병합)
