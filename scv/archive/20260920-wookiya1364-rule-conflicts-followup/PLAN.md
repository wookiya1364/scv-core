---
title: 규칙 충돌 후속 — B~E 해소, 허용목록 두 줄 참조화, pr-helper 재실행 누출
slug: 20260920-wookiya1364-rule-conflicts-followup
author: wookiya1364
created_at: 2026-09-20
status: testing
kind: feature
lang: korean
tags: [rules, constitution, conflicts, recording, pr-helper]
raw_sources:
  - scv/raw/stale/20260920-wookiya1364-regression-runner-lang-leak.md
refs: []
invariants:
  - "우선순위 서술은 SCV.md Top-level rules 한 곳만 — 모든 새 문장은 rule-constitution 검사 (a)(b) 를 통과한다"
  - "어댑터 소유 영역(update·set-models 스킬, 훅 등록)은 이 저장소에서 고치지 않는다 — 핸드오프로 기록"
  - "기존 테스트 전부 통과, 맥·리눅스 동일"
scope:
  - core/protocols/help/full.md
  - core/template/hooks/on-user-prompt.sh
  - core/protocols/work.md
  - core/protocols/sync.md
  - core/contracts/recording.md
  - core/protocols/codegen.md
  - core/protocols/deck.md
  - core/protocols/install-deps.md
  - core/protocols/report.md
  - core/protocols/status.md
  - core/protocols/workspace.md
  - core/protocols/help.md                  # 기존 5개도 포인터 절 (계획서에는 "링크" 로만 적혀 있었음)
  - core/protocols/promote.md
  - core/protocols/handoff.md
  - core/protocols/routine.md
  - core/protocols/regression.md            # 삭감 대화가 있어 포함 (12→13)
  - core/scripts/lib/env.sh
  - core/scripts/regression.sh
  - core/scripts/pr-helper.sh
  - core/tests/test-regression-env.sh
  - core/tests/test-rule-constitution.sh
  - core/tests/fixtures/rule-constitution/**
  - core/TEMPLATE_DIGEST
  - core/contracts/guard.md                 # 줄 번호 앵커 3개 +4 (프로토콜에 ## Recording 절 삽입으로 밀림)
  - core/tests/run-dry.sh                   # 앵커 1개: work.md 옛 문장 → 새 문장
  - core/tests/test-guidance.sh             # 같은 앵커
  - CHANGELOG.md
---

# 규칙 충돌 후속 — B~E 해소, 허용목록 두 줄 참조화, pr-helper 재실행 누출

## Summary

규칙 헌법(0.54.x)은 "어긋나면 누가 이기는가" 를 한 곳에 두었고 충돌 A 를 닫았다. 남은 충돌 B~E 와, 검사가 첫날 잡아
허용목록에 이유와 함께 남긴 두 줄(work 프로토콜), 그리고 실행기와 같은 누출을 타는 pr-helper 의 증거 재실행을 이 계획이
닫는다. 방식은 하나다 — 규칙 본문을 고치되 **우선순위는 적지 않고 Top-level rules 를 참조**하고, 공통 요구(기록 의무)는
계약 문서 한 곳에 두고 프로토콜은 가리키기만 한다(4조). 어댑터 소유 영역(충돌 C 의 업데이트 스킬 문구)은 이 저장소가
아니므로 핸드오프로 기록한다.

## Goals / Non-Goals

- **Goals**
  - **B** — help B0("미완료 대화가 있으면 이어갈지 물어라") 에 예외 한 문장: "새 인자가 미완료 대화들과 주제가 명백히
    다르면 묻지 않고 새로 열고, 그렇게 했다고 한 줄로 알린다." 한 턴 한 형태 규칙과 더 이상 부딪히지 않는다.
  - **C** — 상시 문구(쉬운 말 블록)에 "실행 중인 액션의 단계 규칙이 이 문구보다 먼저다 — 해소 순서는 Top-level rules"
    한 문장. 코어에서 할 수 있는 것은 여기까지. 래퍼 두 곳(업데이트 스킬이 버전을 의무 출력)에는 핸드오프 이슈로
    "출력은 그대로, 문구가 상시 규칙과 어긋난다는 점만 참조형으로 적어 달라" 를 남긴다.
  - **D** — 기록 의무를 계약 문서 `core/contracts/recording.md` 한 곳에 적고(무엇을·어디에·어떤 형식으로·리댁션),
    사용자와 대화가 있는 액션 7개(sync·status·deck·report·codegen·workspace·install-deps) 프로토콜에 가리키는 한 줄.
    help·promote·work·handoff·routine 의 기존 기록 문장도 계약을 가리키게 정리(중복 요구 기준선이 늘지 않게).
  - **E** — sync 의 동의 기준을 한 문장으로: "삭제가 없는 갱신은 자동, 삭제(retired docs)가 있으면 미리보기 + 승인."
    자동 동기화 절과 수동 절이 그 문장 하나를 참조한다.
  - **허용목록 두 줄** — work.md 의 "Guardrails override them" 과 "user's explicit instruction overrides the judgment" 를
    참조형으로(각각 codegen 140행 식, 7조 참조). 허용목록에서 두 줄 제거 → 검사 (a) 여전히 통과.
  - **pr-helper 재실행 누출** — regression.sh 의 `settings_unset_args` 를 lib(env.sh)로 올려 `env_settings_unset_args`
    로 이름 짓고, regression.sh 와 pr-helper.sh 의 재실행이 같은 함수를 쓴다. 검사: 설정 파일 있는 프로젝트에서
    pr-helper 재실행 자식 env 에 SCV_LANG 없음.
- **Non-Goals**
  - 래퍼 저장소 파일 수정(핸드오프만). 하네스(호스트) 지침과의 우선 관계 선언.
  - 규칙 ID·등록부·충돌 감사 루틴(후속 ④). 개념 3(순서 민감성)·5(프리미티브화).
  - 기록 의무의 *자동화*(훅이 대신 쓰기) — 이 계획은 프로토콜 의무와 형식만 정한다.

## Approach Overview

1. **B**: full.md B0 문단 끝에 예외 문장 하나. 판단 기준은 "미완료 대화 제목·슬러그와 새 인자 사이에 공통 낱말이
   없다" 정도의 서술 — 수치는 두지 않는다(수치는 개념 4 의 몫).
2. **C**: on-user-prompt.sh 의 PLAIN 히어독에 문장 하나(템플릿 훅이므로 TEMPLATE_DIGEST 재계산). 핸드오프는 두 래퍼
   저장소에 `gh issue create` — 구현 단계에서 사용자 승인 후 실행, URL 을 ARCHIVED_AT 에 적는다.
3. **D**: 계약 문서 신설. 내용: (1) 사용자 발언이 있는 턴은 기록한다 (2) 어디에 — help 가 연 대화 파일이 있으면 거기,
   없으면 저널 한 줄(`journal-append.sh`) (3) 형식 — Turn 블록 (4) 리댁션 필터 필수 (5) 상태 출력만 있는 턴은 한 줄.
   프로토콜 7개에 "기록은 `core/contracts/recording.md` 를 따른다" 한 줄. 기존 5개의 긴 기록 문장은 그대로 두되
   계약 링크를 덧붙인다(원문 불변 최소).
4. **E**: sync.md 상단 자동 갱신 문단과 Step 0 사이에 "동의 기준" 한 문장, 두 절은 그 문장을 가리킨다.
5. **허용목록**: work.md 두 문장 교체 → `precedence-allowlist.txt` 에서 두 줄 삭제 → 검사 (a) 통과 확인.
6. **누출 공통화**: env.sh 에 `env_settings_unset_args`(순수: 목록 → `-u KEY` 줄들). regression.sh 의 로컬 함수 제거,
   pr-helper.sh 의 재실행(`run-plan-tests.sh` 호출)을 `env "${unset[@]}" bash …` 로 감싼다. test-regression-env T7 과 짝인
   pr-helper 검사 하나(T8: 설정 있는 프로젝트에서 `--no-create --no-push` 로 재실행 → 자식 env 덤프에 SCV_LANG 없음).
7. **충돌 A~E 적용 표 갱신**: 규칙 헌법 계획 TESTS T6 의 표는 보관되어 불변이므로, 이 계획 TESTS 에 "B~E 가 닫힌 뒤
   해소 순서 적용 결과" 표를 새로 둔다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  env_load,                   // 설정 파일 → 환경 + SCV_ENV_LOADED_KEYS                  (효과: 파일 읽기)
  env_settings_unset_args,    // SCV_ENV_LOADED_KEYS → "-u KEY" 줄 목록                   (순수)
  run_child_clean,            // 명령 + unset 인자 → 자식 실행                            (효과: 프로세스)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | env_load | 설정 파일 경로 → export + 새로 내보낸 키 목록 | 부수효과 (입구) |
| 2 | env_settings_unset_args | 키 목록(공백 구분) → `-u\nKEY\n…` | 순수 |
| 3 | run_child_clean (regression.sh · pr-helper.sh 각자의 얇은 호출) | 명령 + 인자 → 자식 프로세스 | 부수효과 (출구) |

- 부수효과 위치: 1 과 3. 2 는 문자열만.
- 재사용: 0.54.0 이 regression.sh 에 둔 `settings_unset_args` 를 그대로 lib 로 옮긴다(이름만 `env_` 접두). 문서 변경(B·C·D·E)은
  파이프라인이 아니라 문장 편집이다 — 검사는 rule-constitution (a)(b) 와 grep 고정.

## Guardrails

- **우선순위를 적지 않는다**: 새 문장은 모두 "Top-level rules 참조" 형태. 검사 (a) 가 게이트다.
- **같은 요구는 한 곳**: 기록 의무 본문은 계약 문서에만. 프로토콜은 한 줄 포인터. 검사 (b) 기준선이 늘면 실패 — 오히려
  help/promote/work/handoff/routine 의 중복이 줄어 기준선을 낮출 수 있으면 낮춘다(리뷰 뒤 갱신).
- **어댑터 소유 영역 불가침**: 래퍼 파일은 건드리지 않는다. 핸드오프는 이슈 생성으로만, 사용자 승인 뒤.
- **원문 최소 수정**: 각 충돌마다 문장 하나~둘. 프로토콜 구조 개편 없음.
- **템플릿 훅 수정 시 지문 재계산**(compute-template-digest). TEMPLATE_VERSION 은 올리지 않는다(스키마 변경 아님).
- **맥·리눅스 동일**: 셸·awk 표준입력 필터만.
- 커밋·푸시·이슈 생성은 사용자 승인 뒤.

## Exit criteria

- All TESTS.md scenarios pass
- 충돌 B·D·E 가 규칙 본문에서 닫혔고, C 는 코어 측 문장 + 두 래퍼 이슈 URL 이 기록됐다.
- 허용목록에 "후속이 참조로 바꿀" 줄이 0개다.
- pr-helper 의 증거 재실행이 설정값을 자식에 넘기지 않는다(검사로 고정).
- rule-constitution 검사 (a)(b) 통과, 기준선 변화는 리뷰된 감소만.
- CHANGELOG 항목, VERSION 상승, 지문 재계산.

## Suggested path

1. 허용목록 두 줄부터(가장 작다): work.md 두 문장 참조화 → 허용목록 삭제 → 검사 (a).
2. 누출 공통화: env.sh 함수 신설 → regression.sh 교체 → pr-helper.sh 적용 → test-regression-env T8.
3. D: 계약 문서 작성 → 7개 프로토콜 포인터 → 기존 5개 링크 → 검사 (b) 기준선 확인.
4. B, E: 문장 하나씩. C: 훅 문장 + 지문 재계산.
5. C 핸드오프: 사용자 승인 후 두 래퍼에 이슈 생성, URL 기록.
6. 전체 검사, CHANGELOG, VERSION.

## Related Documents

- `scv/archive/20260920-wookiya1364-rule-constitution/PLAN.md` — 헌법 조항·해소 순서·검사 (a)(b), 충돌 A~E 원문 위치.
- `scv/conversations/archive/20260920-112254-jev-laya-concepts-scv.md` — 충돌 A~G 확인 기록(Turn 2).

## Risks / Open Questions

- **D 의 범위 해석**: "대화가 있는 액션" 을 7개로 잡았다. status 처럼 읽기만 하는 액션도 사용자가 그 출력을 보고 말을
  덧붙일 수 있어 포함했다 — 과하면 구현 중 사용자와 조정.
- **기존 기록 문장 5개의 중복**: help·promote·work·handoff·routine 이 각자 기록 문장을 길게 갖고 있다. 계약으로 옮기고
  링크만 남기면 기준선이 줄지만 원문 수정이 커진다 — 이번엔 링크만 덧붙이고, 본문 축약은 리뷰에서 결정.
- **C 의 래퍼 측 반영 시점**: 이슈만 남기므로 실제 문구 수정은 래퍼 릴리스 주기를 따른다.
- **구현 중 드러난 것**: (1) `## Recording` 절을 "쉬운 말" 절 *뒤*에 넣어야 한다 — run-dry 가 쉬운 말 절이 언어 선호 절 바로 다음임을
  고정한다. (2) 절 삽입으로 guard 계약의 줄 번호 앵커 3개가 +4 밀렸다 — 줄 번호 앵커는 본질적으로 깨지기 쉽다(후속: 문구 앵커로).
  (3) help.md 는 크기 예산(7200B)이 있어 포인터 한 줄을 최소로 줄였다 — 13개 프로토콜에 같은 한 줄. (4) regression 도 삭감
  대화가 있어 포인터를 넣었다(12→13). (5) VERSION 은 0.55.0 그대로 — Graft 안내와 같은 릴리스.
- **보관 계약이 옛 구절을 고정하고 있었다**: 20260818 regression-contract-repair 의 T3 가 work.md 최소판에 "Guardrails override them" 이
  남아 있음을 grep 한다(보관 TESTS 는 불변). 새 문장이 그 구절을 한 줄 안에 그대로 담되 참조형(Top-level rules 를 가리킴)이 되게
  썼다 — 검사 (a) 는 참조형이면 통과한다. supersedes 로 그 계획 전체를 건너뛰는 것은 과했다(provenance·결정 로그 검사까지 잃는다).
- **B 의 "명백히 다르다" 판정**: 서술 기준이라 모델 판단에 의존. 개념 4(임계값 명문화)에서 수치화 여부를 본다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
- 핸드오프 이슈 (충돌 C, 래퍼 소유 영역): https://github.com/wookiya1364/scv-claude-code/issues/269 · https://github.com/wookiya1364/scv-codex/issues/206
