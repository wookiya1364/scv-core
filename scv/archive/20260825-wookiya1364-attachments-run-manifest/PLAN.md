---
title: "첨부는 실행 기록을 따른다 — 이름이 잘려도, PR 은 하나만"
slug: 20260825-wookiya1364-attachments-run-manifest
author: "wookiya1364"
created_at: 2026-08-25
status: done
kind: feature
lang: korean
tags: [attachments, evidence, pr-helper, manifest]
raw_sources:
  - scv/raw/stale/20260825-wookiya1364-attachments-run-manifest.md
refs: []
supersedes: []
scope:
  - "core/scripts/lib/run-manifest.sh"
  - "core/scripts/lib/pr-platform.sh"
  - "core/scripts/run-plan-tests.sh"
  - "core/scripts/collect-artifacts.sh"
  - "core/scripts/pr-helper.sh"
  - "core/protocols/work.md"
  - "core/protocols/codegen.md"
  - "core/tests/test-run-manifest.sh"
  - "CHANGELOG.md"
invariants:
  - "다른 계획의 증적을 절대 붙이지 않는다 — 소속이 확인된 파일만"
  - "실행 기록이 있으면 이름 매칭은 쓰지 않는다 — 기록이 1순위"
  - "기록은 결과 폴더와 운명을 같이한다 — 결과가 지워지면 기록도 사라져, 낡은 기록이 없는 파일을 가리키는 일이 없다"
  - "0건이면 침묵하지 않는다 — 한 줄로 알리고 재실행 경로를 제시한다"
  - "같은 브랜치에 이미 열린 PR 이 있으면 새로 만들지 않고 그 PR 을 갱신한다"
---

## Why

ai_tm_center FE 실사용에서 PR 증적이 빈손으로 나갔다 (raw 참조). Playwright 가
결과 폴더 이름을 잘라 슬러그 전체 부분문자열 매칭이 0건이 됐고, report 경로는
0건을 무경고로 삼켰으며, 사후 보정하려던 pr-helper 재호출은 PR 을 또 만들려 했다.

이름으로 소속을 알아맞히는 구조가 근본 원인이다. 테스트를 돌린 그 순간에는
"이 실행 = 이 계획"을 확실히 안다 — 그때 기록한다.

## What

### 1. 실행 기록 (run manifest) — `core/scripts/lib/run-manifest.sh` 신설

- 위치: `test-results/.scv/<slug>.manifest` (결과 폴더 안 — Playwright 가 다음
  실행에서 결과를 비우면 기록도 함께 사라진다. 의도된 동거: 기록은 절대 결과보다
  오래 살지 않는다).
- `run_manifest_path <slug>`: 경로 계산 (@pure 급 — 인자만 사용).
- `run_manifest_record <slug> <marker-file>`: marker 보다 새로 생긴/갱신된
  `test-results/` 파일 목록을 기록 (자기 자신 `.scv/` 제외).
- `run_manifest_read <slug>`: 기록된 경로 중 **지금 존재하는** 파일만 출력.
  기록 파일이 없거나 유효 항목 0 → 출력 없음(폴백 신호).

### 2. 실행 래퍼 — `core/scripts/run-plan-tests.sh` 신설

`--slug <slug>` 필수. 명령은 `--tests <TESTS.md>` 의 `## How to run` 추출
(기존 `attachment_scope_read_test_command` 재사용) 또는 `-- <cmd…>` 직접 지정.
동작: marker 생성 → 명령 실행(출력 통과, 종료코드 보존) → manifest 기록
(실패해도 기록한다 — 실패 증적도 증적이다) → `manifest: N file(s) for <slug>`
한 줄 요약(stderr).

### 3. 첨부 우선순위 변경 — `collect-artifacts.sh` + `pr-helper.sh`

slug 스코프일 때: ① `run_manifest_read` 결과가 있으면 **그것만** 사용(확장자
필터만 추가 적용) → ② 없으면 기존 이름 부분일치 → ③ 그래도 0건이면:
- `collect-artifacts.sh`: stderr 한 줄 알림 신설 (지금은 무경고 침묵).
- `pr-helper.sh`: 기존 재실행 경로를 `run-plan-tests.sh` 로 교체 — 재실행이
  manifest 를 남기므로 잘린 이름이어도 재실행 후에는 반드시 잡힌다.

### 4. PR 중복 방지 — `pr-helper.sh` + `lib/pr-platform.sh`

`pr_find_open <head-branch>` 신설 (GitHub: `gh pr list --head … --state open`;
GitLab: 해당 API — 실패 시 빈 값 = 기존 동작). pr-helper 는 create 전에 조회해
열린 PR 이 있으면 create 를 건너뛰고 그 PR 번호로 본문 갱신 + 증적 업로드만
수행, `PR updated: <URL>` 출력. 없으면 지금과 동일.

### 5. 프로토콜 — work.md / codegen.md

TESTS 의 `## How to run` 을 실행하는 자리에서 `run-plan-tests.sh` 를 통해
실행하도록 안내 (증적 소속 기록). 첨부 스코프 설명 문단에 기록 1순위 반영.
가이던스 마커(`SCV:GUIDANCE`) 균형 유지.

## Non-Goals

- `regression.sh` 의 슬러그별 실행에 manifest 기록 통합 (회귀는 증적 첨부와
  무관; 다음 기회).
- 시간창(mtime) 기반 매칭 대안 — 기록 방식으로 결정 (사용자 확인).
- GitLab `pr_find_open` 의 완전 검증 (모의 수준; 실환경은 GitHub 우선).
- 새 설정 키 — 없음. 템플릿 변경 없음(digest 불변).

## Suggested path

1. lib/run-manifest.sh + run-plan-tests.sh (+ 자체 테스트 Red→Green)
2. collect-artifacts.sh / pr-helper.sh 우선순위 + 알림 + 재실행 교체
3. pr_find_open + pr-helper 중복 방지
4. 프로토콜 2편 문안
5. test-run-manifest.sh 전체 green → 회귀 → archive → PR

## Guardrails

- 기존 계약 불변: `SCV_ATTACHMENTS_SCOPE=all` 경로, 슬러그 자동 인식 규칙,
  재실행 타임아웃(`SCV_ATTACHMENTS_RERUN_TIMEOUT`), `--no-rerun`, dry-run 의
  ATTACHMENTS_* 출력 형식은 그대로.
- 호스트 중립(core/ 에 호스트 이름 금지), 순수성 계약(@pure 함수는 부수효과
  금지 — 기록/실행 함수는 @pure 로 표시하지 않는다), whitespace 계약.
- 파일 끝 빈 줄 금지 (0.34.1 계약 — 래퍼 전파가 걸린다).

## Exit criteria

- ai_tm_center 재현 조건(잘린 폴더 이름)에서: run-plan-tests.sh 로 돌린 뒤
  pr-helper dry-run 이 해당 파일들을 ATTACHMENTS_FILES 로 나열한다.
- 기록이 없고 이름도 안 맞으면 collect-artifacts 가 stderr 로 알린다.
- 열린 PR 이 있는 브랜치에서 pr-helper 재호출 시 PR 이 늘지 않는다.
- `bash core/tests/test-run-manifest.sh` green + 기존 첨부 계약
  (`test-attachments-scope.sh`) green.
