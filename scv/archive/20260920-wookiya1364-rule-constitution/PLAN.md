---
title: 규칙 헌법 — 최상위 불변식과 해소 순서 한 문장
slug: 20260920-wookiya1364-rule-constitution
author: wookiya1364
created_at: 2026-09-20
status: testing
kind: feature
lang: korean
tags: [rules, constitution, template, tests]
raw_sources:
  - scv/conversations/20260920-112254-jev-laya-concepts-scv.md
refs:
  - type: link
    url: https://archerhume.com/posts/jevs-architecture-unmasked/
  - type: link
    url: https://news.hada.io/topic?id=33930
  - type: link
    url: https://news.hada.io/topic?id=33944
invariants:
  - "다른 규칙 원문은 손대지 않는다 — 예외는 Guardrails 에 적힌 4곳만 (우선순위 문장 3곳 + regression 삭감 질문 규칙)"
  - "기존 테스트 전부 통과 (core/tests 전체, run-dry, tests/run.sh)"
  - "SCV.md 병합 정책 유지 — merge-on-markers, PROJECT:LOCAL 과 SCV:WORKSPACE 블록 보존"
scope:
  - core/template/scv/SCV.md
  - core/protocols/codegen.md
  - core/contracts/purity.md
  - core/protocols/regression.md
  - core/tests/test-rule-constitution.sh
  - core/tests/fixtures/rule-constitution/**
  - core/scripts/lib/rule-constitution.sh
  - core/tests/run-dry.sh
  - core/TEMPLATE_DIGEST
  - VERSION
  - CHANGELOG.md
  - core/tests/test-deck-change-map.sh          # 계획 밖 수정 — 작업 중 사용자 요청: 맥 sed -i 호환
  - core/template/hooks/on-session-start.sh      # 계획 밖 수정 — 작업 중 사용자 요청: 맥 awk BOM 인식
  - core/scripts/lib/env.sh                      # 계획 밖 수정 — 회귀 실행기가 설정값을 자식에 흘리던 것
  - core/scripts/regression.sh                   # 계획 밖 수정 — 같은 건
  - core/tests/test-regression-env.sh            # 계획 밖 수정 — 그 회귀 검사 T7
  - core/scripts/archive-index.sh                # 계획 밖 수정 — 보관 색인 재생성을 한 곳으로 (work.sh 에서 추출)
  - core/scripts/work.sh                         # 계획 밖 수정 — 위 스크립트를 부른다
  - scv/archive/20260823-wookiya1364-journal-index/PLAN.md      # 프런트매터 3필드만 — obsolete 표시
  - scv/archive/20260917-wookiya1364-deck-change-map/PLAN.md    # 프런트매터 3필드만 — obsolete 표시
---

# 규칙 헌법 — 최상위 불변식과 해소 순서 한 문장

## Summary

SCV 의 규칙은 프로토콜 3,811줄, Never 항목 15개, 훅·계약·템플릿에 흩어져 있고, 서로
어긋나는 쌍이 여섯 군데 확인됐다(아래 표 A~F). 근본 원인은 **우선순위를 말하는 문장이 세 곳에
국소적으로만 있고 전역 규칙이 없다**는 것이다. 이 계획은 `scv/SCV.md` 의
"Top-level rules (immutable)" 절을 규칙 체계의 최상위 층으로 승격한다 — 흩어진 전역 불변식을
**7개 이하의 조항**으로 모으고, 규칙이 어긋날 때의 **해소 순서를 한 문장**으로 그 자리에만 둔다.
국소 우선순위 문장 3곳은 참조로 바꾸고, 자동 검사 둘로 재발을 막는다. 여기에 **충돌 A 의 해소를 합친다**
(Turn 6 결정): regression 의 "슬러그마다 질문 하나" 규칙을 help 의 "독립 결정은 결정 표 하나" 로 고치고
옛 규칙을 대체한다고 선언한다 — 해소 순서만 두면 지금 텍스트에서는 반대로 판정되는 공백을 이 계획 안에서 닫는다.

## Goals / Non-Goals

- **Goals**
  - 헌법 조항 7개 이하. 조항마다 그것이 나온 기존 규칙 원문 위치를 `출처:` 로 가리킨다.
  - 해소 순서 문장이 `scv/SCV.md` 의 그 절에만 있다. 우선순위를 말하던 다른 3곳은 "해소 순서는
    SCV.md Top-level rules 참조" 한 줄로 바뀐다.
  - 외부 층 조항 하나: 사용자의 명시 지침과 어긋나면 SCV 규칙이 양보하고, 양보한 사실을 한 줄로 밝힌다.
  - 자동 검사 (a): 우선순위 어휘(override / 우선 / precedence / wins / takes priority)를 담은
    규범 문장이 SCV.md 헌법 절 밖에 있으면 참조형이어야 한다. 아니면 실패.
  - 자동 검사 (b): 같은 요구가 두 파일 이상에 적힌 후보(중복 요구)를 세어 기준선(래칫)보다 늘면 실패.
  - 대화에서 확인한 충돌 A~E 각각에 해소 순서를 적용하면 결과가 하나로 정해진다 (TESTS T6 문서 검사).
  - **충돌 A 해소**: regression 삭감이 실패 슬러그들을 공유 근거 + 결정 표 한 장(슬러그별 행, 행마다 3택과 추천)으로
    한 번에 묻는다. 새 문장은 옛 "슬러그마다 질문" 규칙을 대체한다고 명시한다. `--ci` 모드(질문 없음)는 그대로.
- **Non-Goals**
  - 충돌 B~E 의 실제 해소(규칙 본문 수정) — 후속 계획 ②. (A 는 이 계획에 포함, Turn 6 결정.)
  - 개념 2(주장 3등급 문구를 help 답변 형태에 반영)·개념 4(위임 임계값 명문화) — 후속 계획 ③.
  - 규칙 ID·등록부·충돌 감사 루틴 — 후속 계획 ④.
  - 호스트 하네스와의 우선 관계 선언 — SCV 가 통제하지 못한다. Risks 에 미결로 남긴다.

## Approach Overview

1. **헌법 조항 후보 7개** (최종 문구는 구현 중 사용자와 확정 — 추측 금지 조항 자체가 그렇게 요구한다):

   | # | 조항 | 출처 (기존 원문) |
   |---|---|---|
   | 1 | 추측 금지 — 사용자 답 없이 계획 칸을 채우지 않는다 | SCV.md Top-level 1 |
   | 2 | 한 번에 하나 — 한 절 완료 → 확인 → 다음 | SCV.md Top-level 2 |
   | 3 | 보관은 불변 — `scv/archive` 아래 문서 본문은 고치지 않는다. 폐기는 PLAN 프런트매터 3필드로만 | work.md Never, regression.md Never, sync.md Never |
   | 4 | 영수증 없는 쓰기 금지 — 계획 파일 생성과 `scv/` 밖 쓰기는 호스트가 발행한 액션 영수증이 있을 때만 | contracts/guard.md |
   | 5 | 같은 요구는 한 곳에만 — 한 요구를 두 문서가 각각 적지 않는다. 둘째 자리는 참조만 | template/hooks/on-user-prompt.sh 63~65행 주석 |
   | 6 | 검증 없는 완료 선언 금지 — 확인한 것·추정·미검증을 구분해 말한다 | help.md "Facts and estimates never mix", 사용자 전역 지침 |
   | 7 | 사용자 지침에 양보 — 사용자의 명시 지침과 어긋나면 SCV 규칙이 양보하고 그 사실을 한 줄로 밝힌다 | 신설 (이 계획, 대화 Turn 3 결정) |

2. **해소 순서 한 문장** (같은 절에, 조항 뒤에):

   > 규칙이 어긋나면 이 순서로 정한다. (1) 이 절의 조항. (2) 더 좁은 범위에 적용되는 규칙.
   > (3) 지금 실행 중인 액션의 단계 규칙이 상시 문구(훅·안내)보다 먼저. (4) `supersedes` 를
   > 선언한 나중 규칙. 선언 없이 어긋나는 두 규칙은 충돌이며 버그로 다룬다 — 어느 쪽을 따랐는지
   > 한 줄로 밝히고 기록한다.

   법학의 상위법·특별법·신법 원칙, CSS cascade 의 출처·구체성·순서, 언어학 Optimality Theory 의
   "위반 가능하되 엄격히 순위화" 를 SCV 크기로 줄인 것이다. 규칙을 없애는 게 아니라 **결정적으로
   해소되게** 한다.

3. **국소 우선순위 문장 3곳 → 참조**: codegen.md 140행 "PLAN.md Guardrails override the others,
   but never the pipeline rule", purity.md 81행 "계약이 검사보다 우선한다", 그리고 SCV.md 의 현
   Top-level 절 자체. 각각 "우선 관계는 `scv/SCV.md` Top-level rules 의 해소 순서를 따른다" 로.
   이 3곳과 아래 3b 의 regression 규칙이 invariant "다른 규칙 원문은 손대지 않는다" 의 예외 전부다.

3b. **충돌 A 해소 — regression 삭감 질문을 결정 표 하나로**: `core/protocols/regression.md` 의 세 자리를 고친다.
   21행의 Never 항목 "Don't bundle multiple failures into one triage" → "독립된 실패 여럿은 결정 표 하나로 묻는다 —
   슬러그별 행, 행마다 regression / obsolete / flaky 3택과 추천. 답이 슬러그마다 달라도 표 한 장에 담긴다.
   (이 문장은 옛 '슬러그마다 질문 하나' 규칙을 대체한다 — 2.4.0)". 59행의 "the per-slug triage below" 와
   Step 2(70~72행)의 "For each slug ... ask one independent question" 을 표 한 장 형식으로. 삭감 로그·obsolete
   처리(Step 2 의 [1]~[3] 동작)는 그대로 — 묻는 형식만 바뀐다. `work.md` 9c 의 supersede 전파 확인(슬러그마다)은
   다른 상황이므로 이 계획에서 건드리지 않고 Risks 에 적는다.

4. **자동 검사 `core/tests/test-rule-constitution.sh`**: 아래 파이프라인. (a) 는 게이트, (b) 는
   기준선 파일과 비교하는 래칫이다 — 첫날부터 막지 않고, 늘어나는 것만 막는다. 정규식은 그물이지
   울타리가 아니다(purity 계약과 같은 정신). 자기 검사 픽스처 둘: 우선순위 문장을 심은 사본에서
   (a) 가 실패해야 하고, 중복 요구를 심은 사본에서 (b) 의 수가 늘어야 한다.

5. **템플릿 지문 재계산 + CHANGELOG 항목 + 플러그인 VERSION 0.54.0.** TEMPLATE_VERSION 은 올리지 않는다 —
   `docs/release.md` 는 스키마 변경에만 올리라 하고, 내용 변경은 `core/TEMPLATE_DIGEST` 가 잡아 다음 Core
   액션에서 자동 갱신된다 (구현 중 확인, 원래 계획의 "2.4.0 상승" 을 이 규칙에 맞게 고쳤다). merge-on-markers
   이므로 PROJECT:LOCAL / SCV:WORKSPACE 블록은 그대로다.

6. **충돌 A~E 에 해소 순서를 적용한 결과** (TESTS T6 에 기대값으로 고정):

   | 충돌 | 적용 | 지금 텍스트에서의 결과 (하나) | 후속 |
   |---|---|---|---|
   | A help "독립 결정은 표 하나" vs regression "슬러그마다 질문" | 이 계획의 3b 가 regression 규칙을 고치고 대체 선언 → (4) | 결정 표 하나 (슬러그별 행) | 없음 — 이 계획에서 닫힘 (Turn 6 결정) |
   | B help B0 "이어갈지 물어라" vs "한 턴에 질문 하나 또는 표 하나" | (2) | 미완료 대화가 있으면 B0 질문만 하고 멈춘다 | 계획 ②가 "주제가 명백히 다르면 새로 열고 한 줄로 알린다" 예외 추가 |
   | C 상시 훅 "코드 값 금지" vs update 스킬 "버전 포함 보고" | (3) 액션 단계 > 상시 문구 | 버전을 적는다. 순서(요약 먼저)는 그대로 | 없음 — 순서로 끝 |
   | D 훅 "help 안 부르면 논의 소실" vs 예외 "액션 턴은 부르지 않음" | 충돌이 아니라 **빈 규칙** | 해소 순서 적용 대상 아님 — 기록 의무가 없는 액션이 문제 | 계획 ②가 기록 의무를 액션 공통 계약으로 (Turn 3 결정 3) |
   | E 자동 동기화 무확인 vs 수동 sync 승인 필수 | 범위가 겹치지 않음 | 런타임 충돌 없음 — 동의 기준이 둘인 설계 냄새 | 계획 ②가 기준을 한 문장으로 |

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  collect_rule_files,          // 검사 대상 디렉터리 목록 → 파일 경로 목록                 (효과: 디스크 읽기)
  extract_normative_lines,     // 파일 텍스트 → 규범 문장 목록 (never/always/must/금지/반드시/우선…)  (순수)
  find_precedence_statements,  // 규범 문장 → 우선순위 어휘 문장 목록                        (순수)
  assert_single_location,      // 우선순위 문장 + 허용 위치 → pass | fail(위치 목록)            (순수)
)
flow(
  extract_normative_lines,     // (위와 같은 단계 재사용)
  normalize_demand,            // 문장 → 정규화 키 (소문자, 마크다운 제거, 불용어 제거)        (순수)
  find_duplicate_demands,      // 키+파일 쌍 목록 → 두 파일 이상에 나온 키 목록               (순수)
  compare_ratchet,             // 후보 수 + 기준선 수 → pass | fail(증가분)                     (순수)
)
report                         // 두 판정 → 출력 + 종료 코드                                  (효과: stdout, exit)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | collect_rule_files | 디렉터리 목록 → 파일 경로 목록 | 부수효과 (입구, 디스크 읽기) |
| 2 | extract_normative_lines | 텍스트 → `파일\t줄\t문장` 목록 | 순수 |
| 3 | find_precedence_statements | 규범 문장 목록 → 우선순위 어휘 문장 목록 | 순수 |
| 4 | assert_single_location | 우선순위 문장 목록 + 허용 위치 → 판정 | 순수 |
| 5 | normalize_demand | 문장 → 정규화 키 | 순수 |
| 6 | find_duplicate_demands | `키\t파일` 목록 → 중복 키 목록 | 순수 |
| 7 | compare_ratchet | 후보 수 + 기준선 → 판정 | 순수 |
| 8 | report | 판정 둘 → 텍스트 + 종료 코드 | 부수효과 (출구) |

- 부수효과 위치: 1(파일 읽기)과 8(출력·종료 코드)만. 2~7 은 표준입력 문자열만 다룬다.
  `grep`/`awk`/`sed` 는 표준입력 필터로만 쓰고 `# @deterministic` 표식을 단다.
- 재사용: `core/tests/lib/anchors.sh` 의 pass/fail 헬퍼, `tests/test-guard-consistency.sh` 의
  "선언 문서 ↔ 코드" 검사 구조를 그대로 따른다.

## Guardrails

- **원문 불변, 예외 4곳만**: `core/protocols/codegen.md` 140행의 override 문장,
  `core/contracts/purity.md` 81행의 "계약이 검사보다 우선한다" 문장, `core/template/scv/SCV.md`
  Top-level rules 절, 그리고 `core/protocols/regression.md` 의 삭감 질문 규칙(21행·59행·70~72행).
  그 외 어떤 프로토콜·계약·훅 문장도 바꾸지 않는다. 참조 한 줄을 다른
  프로토콜에 추가하는 것도 하지 않는다 — 훅과 하이드레이트가 이미 SCV.md 를 가리킨다.
- **조항 7개 이하**, 각 조항에 `출처:` 필수. 조항이 다른 문서의 문장을 그대로 복제하지 않는다
  (그건 조항 5 위반이다) — 요약하고 출처를 가리킨다.
- **설치 의존 추가 없음**: bash + grep/awk/sed 만. jq 도 쓰지 않는다.
- **SCV.md merge-on-markers 유지**: 프런트매터 `status`, PROJECT:LOCAL, SCV:WORKSPACE 블록에
  손대지 않는다. `test-autosync.sh` 가 이를 본다.
- **검사 (b) 는 래칫**: 기준선 파일 `core/tests/fixtures/rule-constitution/duplicate-baseline.txt`
  에 첫 실행의 후보 목록을 고정한다. 목록이 줄어들면 기준선을 갱신할 수 있고, 늘면 실패다.
  첫날에 기존 중복을 다 고치려 들지 않는다.
- **`scv/archive` 는 건드리지 않는다** (조항 3 이 이 계획 자체에도 적용된다).
- 커밋·푸시는 사용자가 한다.

## Exit criteria

- All TESTS.md scenarios pass
- `scv/SCV.md` Top-level rules 절이 3~7개의 번호 조항 + 출처 + 해소 순서 문단으로 되어 있고,
  다운스트림 프로젝트가 자동 동기화 후 같은 절을 갖는다 (test-autosync 픽스처로 확인).
- 우선순위를 서술하는 자리가 저장소 전체에서 한 곳이고, 나머지 3곳은 참조형이다.
- regression 프로토콜의 삭감 질문이 결정 표 하나이고, 옛 규칙을 대체한다는 선언이 그 문장에 붙어 있다.
  `--ci` 모드 규칙은 바뀌지 않았다.
- `core/tests/test-rule-constitution.sh` 가 원본 저장소에서 통과하고, 자기 검사 픽스처 둘에서
  기대한 대로 실패한다.
- CHANGELOG 에 항목이 있고 `core/TEMPLATE_DIGEST` 가 재계산돼 있다 (TEMPLATE_VERSION 은 릴리스 규칙대로 그대로).

## Suggested path

1. SCV.md 템플릿의 Top-level rules 절을 조항 7개 + 출처 + 해소 순서 문단으로 다시 쓴다. 문구는
   사용자와 한 조항씩 확정한다 (한 번에 하나).
2. codegen.md 140행, purity.md 81행의 우선순위 문장을 참조 한 줄로 바꾼다.
2b. regression.md 21행·59행·70~72행을 결정 표 하나 형식으로 고치고 대체 선언을 붙인다. 표 템플릿은
    help 의 Decisions 표 형식(`# | 슬러그 | 실패 꼬리 | 추천`)을 그대로 쓴다.
3. `core/tests/test-rule-constitution.sh` 를 위 파이프라인대로 쓴다. 우선순위 어휘와 규범 동사
   목록은 스크립트 상단 상수로 둔다. 자기 검사 픽스처 둘을 `core/tests/fixtures/rule-constitution/`
   에 둔다. 첫 실행으로 기준선 파일을 만든다.
4. `core/scripts/compute-template-digest.sh > core/TEMPLATE_DIGEST` 로 지문을 재계산하고, CHANGELOG 항목과
   VERSION(0.54.0)을 쓴다. run-dry 의 앵커 "per-slug 3-way triage" 는 새 제목에 맞게 "3-way triage" 로.
5. `core/tests/*.sh` 전체, `core/tests/run-dry.sh`, `tests/run.sh` 를 돌린다.
6. TESTS T6 표를 눈으로 확인하고 결과를 ARCHIVED_AT 에 남긴다.

## Related Documents

- `core/contracts/guard.md` — "선언 문서 하나를 검사와 문서가 함께 읽는다" 는 같은 설계.
- `core/contracts/purity.md` — 순수부/효과부 경계와 `@deterministic` 표식.
- `tests/test-guard-consistency.sh` — 선언 ↔ 본문 일관성 검사의 본보기.
- `scv/conversations/20260920-112254-jev-laya-concepts-scv.md` — 충돌 A~G 원문 위치와 결정 근거.

## Risks / Open Questions

- **다운스트림 파급**: 템플릿 지문이 바뀌면 모든 프로젝트의 SCV.md 가 다음 Core 액션에서 갱신된다.
  SCV.md 에 커밋되지 않은 수정이 있는 프로젝트는 `DIRTY` 로 거부되고 수동 sync 를 안내받는다.
  의도된 동작이지만 릴리스 노트에 한 줄 적는다.
- **검사 (b) 의 오탐**: "Technical identifiers stay as-is" 처럼 프로토콜마다 의도적으로 반복되는
  문장이 중복 후보로 잡힌다. 래칫이라 첫날은 막지 않지만, 기준선 목록이 길면 신호가 묻힌다.
  후속 계획 ④(등록부)에서 허용 목록으로 다듬는다.
- **어휘 목록의 빈틈**: 우선순위를 다른 말로 적은 문장("이긴다", "먼저다")은 잡지 못할 수 있다.
  검사는 그물이다 — 놓친 것은 사람이 리뷰에서 잡고 어휘 목록에 더한다.
- **조항 7 의 한계**: SCV 는 사용자 지침에 양보한다고 선언할 수 있을 뿐, 호스트 하네스 지침과의
  관계는 통제하지 못한다. 미결로 남긴다.
- **조항 문구는 미확정**: 위 표는 후보다. 구현 중 사용자가 한 조항씩 확정한다.
- **충돌 A 를 이 계획에 합친 대가**: 원문 불변 예외가 3곳에서 4곳으로 늘고, 이 계획이 "순서만 정한다" 는
  순수성을 조금 잃는다. 대신 배송 직후의 판정 공백(순서만 두면 regression 쪽이 이김)이 없다.
  구현체를 보고 판단하기로 했다 (Turn 6) — 어색하면 3b 만 떼어 후속 계획으로 되돌릴 수 있다.
- **계획 밖 수정 둘 (사용자 요청, 작업 중)**: HEAD 에서도 이미 실패하던 테스트 둘을 고쳤다. deck 변경 지도
  테스트는 GNU 전용 `sed -i` 를 `perl -pi` 로, 세션 재개 훅은 BOM 을 16진 대신 8진 이스케이프 + `LC_ALL=C` 로.
  둘 다 맥(BSD sed, awk 20200816)에서만 죽던 것이라 CI(리눅스)는 못 봤다. 훅은 템플릿이라 지문을 다시 계산했다.
- **회귀 17건을 초록으로 (사용자 지시, 보관 전)**: 붉은 17건은 셋으로 갈렸다. ① 실행기가 설정 파일의 값(SCV_LANG 등)을
  자식 검사에 흘려 "설정 없음" 을 전제한 아카이브 계약 10건이 실행기 안에서만 붉었다 — env_load 가 새로 내보낸 키를
  적어 두고 실행기가 자식에서 그 키만 지운다(사용자가 직접 export 한 값은 그대로). test-regression-env T7 이 잠근다.
  ② 옆에 체크아웃된 래퍼 저장소 둘이 낡은 브랜치였다(5건) — 체크아웃을 최신으로 옮겼다(이 저장소 변경 아님).
  ③ 지워진 검사 파일을 가리키는 보관 계약 둘 — 프런트매터 3필드로 obsolete 표시 + 결정 기록(supersedes 누락의 사후 정리).
- **work.md 9c 의 슬러그별 확인은 그대로**: supersede 전파 확인(9c)은 삭감과 다른 상황이라 이 계획에서
  건드리지 않는다. 같은 원리(독립 결정은 표 하나)를 적용할지는 후속 계획 ②에서 본다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
