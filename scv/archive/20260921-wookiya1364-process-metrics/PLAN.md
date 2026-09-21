---
title: 과정 계기판 — 이 프로젝트의 파일로 SCV 과정을 숫자로 본다
slug: 20260921-wookiya1364-process-metrics
author: wookiya1364
created_at: 2026-09-21
status: testing
kind: feature
lang: korean
tags: [metrics, measurement, archive, decisions, conversations, purity]
raw_sources:
  - scv/conversations/20260921-192248-scv-growth-directions.md
refs: []
invariants:
  - "어떤 파일도 쓰지 않는다 — 읽기 전용, 네트워크 없음, 설정 파일도 건드리지 않는다"
  - "순수부·효과부 계약(core/contracts/purity.md)과 check-purity.sh 를 통과하고, 기존 테스트 전부 통과, 맥(bash 3.2)·리눅스 동일"
scope:
  - core/scripts/metrics.sh
  - core/scripts/lib/metrics.sh
  - core/tests/test-metrics.sh
  - core/tests/fixtures/metrics/**
  - docs/architecture.md
---

# 과정 계기판 — 이 프로젝트의 파일로 SCV 과정을 숫자로 본다

## Summary

SCV 는 과정을 강제하는 장치(가드 훅, 출처 게이트, 규칙 헌법, 기록 계약)는 촘촘한데, 그 과정이
실제로 도움이 됐는지 재는 장치가 없다. 스크립트 하나가 이미 디스크에 있는 파일(아카이브 색인,
계획서, 대화 파일, 결정 로그)만 읽어 지표 네 개를 표 하나로 찍는다. 모든 사용자에게서 모으는
제품 통계가 아니라, 각 프로젝트가 자기 파일로 자기를 재는 계기판이다 — 증명이 아니라 진단.

## Goals / Non-Goals

- **Goals**
  - 지표 네 개를 결정적으로 계산한다: (1) 계획당 대화 턴 수, (2) 계획 승인→보관 리드타임,
    (3) 후속 재발률, (4) 계획서의 순수함수·파이프라인 절 보유율.
  - 각 지표에 **적용 범위(coverage)** 를 함께 찍는다 — "63건 중 20건에 데이터 있음" 처럼.
    데이터가 없는 계획은 0 이 아니라 "없음" 이다.
  - 같은 입력에 같은 출력. 시각·난수·네트워크를 읽지 않는다.
  - 이 저장소(아카이브 63건)에서 실제로 돌아 표가 나온다.
- **Non-Goals**
  - 원격 텔레메트리, 옵트인 수집, 대시보드.
  - 새 로깅 훅. 기록 형식(ARCHIVED_AT, DECISIONS, 대화 파일)은 바꾸지 않는다.
  - status 등 기존 액션에 줄을 더하는 것 — 숫자가 쓸모 있다고 확인된 뒤 후속 계획.
  - TESTS 첫 통과율 — 기존 파일 어디에도 구조적으로 기록되지 않아(확인) 지금은 계산할 수 없다.
    후속 계획에서 보관 기록에 한 줄을 더한 뒤 잰다.
  - 사용자 프로젝트 코드(TS 등)의 순수성 기계 검사 — 별도 계획.

## Approach Overview

효과층 하나가 파일 넷을 읽어 문자열로 넘기고, 순수 함수들이 문자열만 받아 레코드 → 지표 →
표로 바꾸고, 효과층이 표를 찍는다. 조사에서 확인한 데이터 형식과 함정:

- **아카이브 색인** `scv/archive/INDEX.yaml`: 항목마다 `slug`·`title`·`kind`·`status`, 15건에
  `obsoleted_by`. 계획서 프런트매터 `supersedes:` 는 27건에 키가 있으나 대부분 `[]`.
- **계획서** `scv/archive/<slug>/PLAN.md`: `raw_sources:` 아래 대화 파일 경로. 63건 중 20건이
  대화 파일을 가리키고, 그중 18건의 경로는 보관 뒤 `scv/conversations/archive/` 로 옮겨져
  **원래 경로로는 없다** — 경로 해석은 "그대로 → conversations/archive/<basename>" 순.
  `## 순수함수 · 파이프라인` 절은 63건 중 28건에 있다.
- **대화 파일**: `## Turn <N> — <ISO>` 헤딩 수 = 턴 수. `status:` 줄에 뒤따르는 주석이 붙은
  파일이 5건 있다 — 값은 첫 낱말만.
- **결정 로그** `scv/DECISIONS.md`: `## [YYYY-MM-DD HH:MM] <author> — <제목>` 헤더,
  `- verdict:`, `- refs: scv/(promote|archive)/<slug>/PLAN.md`. 승인은 `adopted`(refs 가
  promote 경로), 보관은 `archived`(refs 가 archive 경로). 같은 slug 의 두 시각 차가 리드타임.
  템플릿 행(`[YYYY-MM-DD HH:MM]`)은 버린다.
- **후속 재발**은 구조 신호만 센다: 색인의 `obsoleted_by` 가 가리키는 계획(누군가를 대체한
  계획)과 프런트매터 `supersedes` 가 비어 있지 않은 계획. 제목·슬러그의 낱말은 보지 않는다.
- **시각 산술**은 `date` 를 부르지 않고 `YYYY-MM-DD HH:MM` → 분 정수 변환을 순수 함수로 한다
  (days-from-civil 공식). 맥 bash 3.2 에서 도는 정수 산술만.

출력은 지표당 한 줄의 텍스트 표. 값 · 적용 범위(n/m) · 중앙값(턴 수·리드타임). `--tsv` 로
탭 구분 원자료. 인자·환경은 다른 스크립트와 같은 `SCV_DIR`(기본 `scv`).

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readInputs,              // [효과] SCV_DIR → { index, plans[], conversations[], decisions } 문자열들
  parseIndex,              // INDEX.yaml 텍스트 → 계획 레코드 (slug\tstatus\tobsoleted_by)
  parsePlan,               // PLAN.md 텍스트 → (slug\tconv_paths\tsupersedes_n\thas_purity)
  resolveConvPath,         // 경로 → 후보 경로 목록 (그대로, conversations/archive/<basename>)
  countTurns,              // 대화 파일 텍스트 → 턴 수
  parseDecisions,          // DECISIONS.md 텍스트 → (slug\tverdict\tminutes)
  civilToMinutes,          // "YYYY-MM-DD HH:MM" → 분 정수
  metricTurns,             // 계획 레코드 + 턴 수 → (slug\tturns|none)
  metricLeadTime,          // 결정 레코드 → (slug\tminutes|none)
  metricFollowup,          // 계획 레코드 → (slug\t0|1)
  metricPurity,            // 계획 레코드 → (slug\t0|1)
  aggregate,               // 지표 행들 → 요약 (count, coverage, median)
  renderTable,             // 요약 → 표 텍스트
  print,                   // [효과] 표 → stdout
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readInputs | SCV_DIR → 파일 내용 문자열들 | 부수효과 (입구) |
| 2 | parseIndex | INDEX.yaml 텍스트 → 계획 레코드 줄들 | 순수 |
| 3 | parsePlan | PLAN.md 텍스트 → 계획 링크 레코드 한 줄 | 순수 |
| 4 | resolveConvPath | 경로 문자열 → 후보 경로 줄들 | 순수 (실존 확인은 1번이) |
| 5 | countTurns | 대화 텍스트 → 정수 | 순수 |
| 6 | parseDecisions | DECISIONS 텍스트 → 결정 레코드 줄들 | 순수 |
| 7 | civilToMinutes | "YYYY-MM-DD HH:MM" → 정수 | 순수 |
| 8 | metricTurns · metricLeadTime · metricFollowup · metricPurity | 레코드 → 지표 행 | 순수 |
| 9 | aggregate | 지표 행 → 요약 | 순수 |
| 10 | renderTable | 요약 → 표 텍스트 | 순수 |
| 11 | print | 표 → stdout | 부수효과 (출구) |

- 부수효과 위치: 1번(파일 읽기·실존 확인)과 11번(출력)뿐. 시각·난수·네트워크는 어디에도 없다.
- 재사용: `lib/yaml.sh` 의 `yaml_get`/`yaml_get_list`(프런트매터 읽기). 결정 헤더 파싱은
  `lib/record-index.sh` 가 색인용으로 이미 하므로 형식을 맞추되, 그 함수가 bash 4 확장
  (`${m,,}`)을 쓰므로 여기서는 부르지 않고 형식만 공유한다.

## Guardrails

- 읽기 전용. 어떤 파일도 만들거나 고치지 않는다(`scv/` 아래 포함). 네트워크 없음.
- `date`·`$RANDOM`·`$SECONDS` 를 부르지 않는다 — 출력이 실행 시각에 따라 달라지면 검증이 무너진다.
- bash 3.2 호환: `${var,,}`·연관 배열·`mapfile` 금지. BSD/GNU 차이가 나는 `sed -i`·`date -d` 금지.
- 후속 재발의 정의는 위 구조 신호 둘뿐. 낱말 패턴을 더하지 않는다 — 더하고 싶으면 후속 계획.
- 기록 형식(ARCHIVED_AT · DECISIONS · 대화 파일 · INDEX.yaml)을 바꾸지 않는다.
- 이 저장소의 실제 숫자를 테스트 기대값으로 박지 않는다 — 보관할 때마다 바뀐다.
- 프로토콜·훅·status 액션을 건드리지 않는다.

## Exit criteria

- All TESTS.md scenarios pass
- 이 저장소에서 스크립트가 exit 0 으로 표를 찍고, 두 번 실행한 출력이 바이트 단위로 같다.
- 표에 지표 네 개와 각각의 적용 범위(n/m)가 있고, 데이터 없는 계획은 "없음" 으로 셈에서 빠진다.
- `check-purity.sh` 가 `lib/metrics.sh` 의 `# @pure` 함수 전부를 통과시킨다.

## Suggested path

1. 픽스처를 먼저 만든다: `core/tests/fixtures/metrics/scv/` 에 계획 4건(대화 있음 2·없음 1·
   obsoleted 1, 순수 절 있음 2), 대화 파일 2건(하나는 `archive/` 아래로 옮겨진 경로), 결정 로그
   (adopted 3 · archived 2 · 템플릿 행 1). 기대 표를 손으로 계산해 적는다.
2. `lib/metrics.sh` 에 순수 함수 2~10번을 `# @pure` 표식과 함께 쓴다. 각 함수는 문자열 인자를
   받아 stdout 으로 돌려준다.
3. `metrics.sh` 효과층: 인자 처리, 파일 읽기, 후보 경로 실존 확인, 순수 함수 호출, 출력.
4. `test-metrics.sh`: 픽스처 전수 대조, 반복 실행 동일, 실제 저장소 exit 0 + 동일 출력,
   순수성 검사.
5. `docs/architecture.md` 에 두 줄 — 무엇을 재고 무엇은 재지 않는지.

## Edge cases (예외처리)

| 조건 | 동작 | 출력 |
|---|---|---|
| INDEX.yaml 없음 | exit 0 | stderr 한 줄 `no archive index`, 표 없음 |
| 계획의 대화 파일이 두 후보 경로(그대로 · conversations/archive/) 모두에 없음 | 계속 | 그 계획의 턴 수 = none, 적용 범위 분모에만 |
| 결정 헤더가 템플릿 행 `[YYYY-MM-DD HH:MM]` | 버림 | — |
| 결정 refs 가 promote/archive 경로가 아님 | 계속 | `--tsv` 에 `unmatched` 행 |
| 결정 시각 형식 오류 | 버림 | 그 결정은 리드타임에서 빠짐 |
| adopted 만 있고 archived 없음 | 계속 | 리드타임 none |
| 대화 파일 `status:` 뒤 주석 | 첫 낱말만 값 | — |
| 코드 블록 안의 `## Turn` 유사 문구 | 세지 않음 | — |

## Related Documents

- `core/contracts/purity.md` — 세 층과 검사.
- `scv/archive/20260807-wookiya1364-guidance-ablation/PLAN.md` — 같은 N-of-1 비교 방식의 선례.

## Risks / Open Questions

- **표본이 작다**: 대화 턴 수는 63건 중 20건, 리드타임은 결정 로그에 양쪽 엔트리가 있는 계획만.
  숫자는 진단이지 증명이 아니다 — 표의 적용 범위 열이 그것을 드러낸다.
- **결정 로그의 refs 형식이 손으로 쓰인 시절이 있다**(초기 엔트리) — 매칭 안 되는 행은 조용히
  빼지 말고 `--tsv` 에 `unmatched` 로 남긴다.
- **후속 재발은 과소 집계**된다 — 구조 신호만 보므로 이름으로만 후속인 계획은 안 잡힌다. 의도된
  선택(정밀도 우선).
- 다음 계획 후보: 보관 기록에 TESTS 첫 실행 결과 한 줄 → 첫 통과율. status 액션에 요약 한 줄.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
