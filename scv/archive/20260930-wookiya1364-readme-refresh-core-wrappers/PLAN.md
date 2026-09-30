---
title: README 최신화 — 코어와 두 래퍼의 첫 화면 안내를 지금 기능에 맞추고, 낡았다고 표시된 옛 자료 21건을 검토한다
slug: 20260930-wookiya1364-readme-refresh-core-wrappers
author: wookiya1364
created_at: 2026-09-30
status: done
kind: feature
lang: korean
tags: [readme, docs, wrappers, raw-lifecycle, check-script]
raw_sources:
  - scv/conversations/archive/20260930-002143-readme-refresh-core-wrappers.md
refs: []
invariants:
  - "README 에 적는 명령 · 설정 · 기능은 지금 저장소에 실제로 있는 것만"
  - "영 · 한 · 일 세 언어판은 같은 절 구조와 같은 명령 · 설정 목록"
  - "래퍼 README 에 릴리스 버전 번호를 적지 않는다 — 맨 위 배지가 최신 릴리스를 읽는다"
  - "클로드 래퍼 README 에 코덱스 전용 문법을 쓰지 않는다 (tests/test-core-contract.sh)"
  - "사용이 끝난 옛 자료(scv/raw/stale/)의 본문은 고치지 않는다 — 판정은 검토표에만"
  - "검토를 마치지 않은 옛 자료는 다시 사용 표시(consume)하지 않는다"
---

# README 최신화 — 코어와 두 래퍼의 첫 화면 안내를 지금 기능에 맞추고, 낡았다고 표시된 옛 자료 21건을 검토한다

## Summary

세 저장소(scv-core · scv-claude-code · scv-codex)의 첫 화면 README 는 2026-08-25 이후 그대로라, 그 뒤 릴리스
(코어 37 · 클로드 33 · 코덱스 31번)에서 생긴 기능이 빠져 있다. 구조는 유지하고 틀린 사실을 고치며 빠진 주요 기능을
절로 더한다. 같은 계획에서, 계획을 만들 때마다 반복되는 "사용이 끝난 옛 자료가 그 뒤 바뀐 파일을 가리킨다" 경고 21건을
자료마다 지금 코드와 대조해 판정을 남기고, 검토를 마친 자료만 이 계획으로 다시 사용 표시해 끈다.

## Goals / Non-Goals

- **Goals**
  - README 12개를 지금 기능에 맞춘다: 세 저장소 첫 화면 `README.md` · `README.ko.md` · `README.ja.md`(9개) +
    코덱스 `plugins/scv/README.md` · `.ko.md` · `.ja.md`(3개).
  - 빠진 주요 기능을 소개한다(근거: 2026-08-25 이후 보관 계획 38개). 저장소별 필수 주제는 아래 표.
  - 두 래퍼 README 에 업데이트 방법을 넣는다 — 클로드: `/plugin marketplace update scv-claude-code` → `/reload-plugins`,
    코덱스: `codex plugin marketplace upgrade scv-codex` → `codex plugin add scv@scv-codex`.
  - 설정은 자주 쓰는 몇 개만 싣고, 나머지는 설정 예시 파일(`scv/scv_settings.example.json`)로 연결한다.
  - README 검사 스크립트 하나를 코어 `tools/` 에 두고 코어 CI 에 연결한다 — 적힌 명령 · 설정이 실제로 있는지,
    필수 주제가 있는지, 세 언어판 구조 · 목록이 같은지, (래퍼) 버전 번호가 없는지 본다.
  - 옛 자료 21건(부록 A): 자료마다 가리키는 바뀐 파일에 관한 주장을 지금 코드와 대조 → 검토표(유효 · 일부 낡음 ·
    대체됨 + 근거 · 대체한 계획) → 검토를 마친 자료만 이 계획 slug 로 `readpath.sh consume`(ref_commit 재기록).
- **Non-Goals**
  - README 전면 재작성 · 홍보 문구 개편
  - 템플릿 · 어댑터 안의 README(`template/scv/*/README.md`, `adapter/README.md`)
  - 옛 자료 본문 수정 · 삭제, `AGING` 으로만 표시된 7건(바뀐 파일을 가리키지 않음)
  - 릴리스 — README 는 `promote.yml -f release=false` 로 main 까지만 올린다
  - 두 래퍼 CI 연결은 이 계획의 완료 조건이 아니다 — 다음 코어 배포 뒤 후속(Suggested path 7)

### 저장소별 필수 주제 (검사 스크립트가 세 언어판 모두에서 찾는 표식)

| 주제 | 언어와 무관한 표식 | 코어 | 클로드 | 코덱스 |
|---|---|---|---|---|
| 매 턴 함께 (preflight · 매 턴 help) | `SCV_ALWAYS_ON` | ● | ● | ● |
| 쉬운 말 답 · 답 모양 검사 | `SCV_PLAIN_LANGUAGE`, `SCV_ANSWER_LINT` | ● | ● | ● |
| 재개 요약 (압축 · /clear · 재개 뒤) | `SCV_RESUME_RECAP` | ● | ● | – |
| 모델별 프롬프팅 (가이드 원문 · 매 턴 요구 항목 비교 · 등록) | `SCV_MODEL_PROMPTING` | ● | ● | ● |
| 배경 조사 위임 (기본 off) | `SCV_DELEGATE_EFFORT` | ● | ● | – |
| 자체 그래프 · 선택형 Graft | `SCV_GRAPH`, `SCV_GRAFT` | ● | ● | ● |
| 번호식 화면설계서 기획서 · 계획서의 순수함수 파이프라인 절 | `FEATURE_ARCHITECTURE.md` | ● | ● | ● |
| 지난 작업 본문 검색 | `archive-search` (프로토콜 링크) | ● | ● | ● |
| 과정 계기판 | `metrics.sh` | ● | ● | ● |
| 업데이트 방법 | 위 업데이트 명령 | – | ● | ● |

표식의 정확한 모양(명령 이름 · 문구)은 작업 때 실제 파일에서 확인해 고정한다 — 없는 표식을 지어내지 않는다.
작업 때 확정한 것(2026-09-30): 코덱스 플러그인에는 세션 시작 훅(hooks.json 은 PreToolUse · Stop · UserPromptSubmit 뿐)과
배경 조사 에이전트가 없어 재개 요약 · 배경 조사는 코덱스 README 에 적지 않는다. 과정 계기판은 status 에 연결되지 않은 독립
스크립트(`core/scripts/metrics.sh`)라 그 이름을 표식으로 쓴다. 코덱스 플러그인 README(짧은 안내)의 필수 표식은
`SCV_ALWAYS_ON` · `SCV_MODEL_PROMPTING` · 업데이트 명령 둘로 한다. 이 표는 `tools/check-readme.sh` 의 `topics()` 와 같다.

## Approach Overview

- 기능 목록의 근거는 `scv/archive/` 의 20260825 이후 보관 계획 38개(제목 · 본문), 각 래퍼의 스킬 목록, 코어 설정 예시 파일이다.
- README 는 영어판을 먼저 고치고 한 · 일 판을 같은 절 구조로 맞춘다. 절 순서 · 제목 체계는 지금 것을 유지한다.
- 코어 README 는 설계 · 검사 · 내보내기 · 릴리스 절을 지금 구조(매 턴 훅 · 모델별 프롬프팅 · 그래프 · 래퍼 동기화 사슬)에 맞춘다.
  코어 README 는 `tools/export-core.sh` 로 래퍼 안 코어 사본에도 복사되므로, 그 사본은 다음 코어 릴리스 때 바뀐다.
- 검사 스크립트는 저장소 루트와 프로필(core · claude · codex)을 받는다. 호스트 전용 문법은 프로필 데이터로 둔다
  (호스트 중립 검사는 `core/` 만 보므로 `tools/` 는 대상이 아니다 — 확인함).
- 옛 자료 21건은 서로 독립이라 나눠 검토할 수 있다. 검토표는 계획 폴더의 `STALE_REVIEW.md` 에 둔다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

README 검사:

```
flow(
  readReadmes,      // (repoRoot, profile) → { en, ko, ja } 본문
  readInventory,    // (repoRoot, profile) → { skills, settings }
  extractClaims,    // ({ en, ko, ja }) → 언어별 { 명령, 설정, 절 제목, 버전 표기 }
  checkExistence,   // (claims, inventory) → 없는 명령 · 설정
  checkTopics,      // (claims, requiredTopics[profile]) → 빠진 주제
  checkParity,      // (언어별 claims) → 절 · 명령 · 설정 차이
  report,           // (findings) → 출력 줄 + 종료 코드
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readReadmes | 저장소 · 프로필 → 언어판 본문 | 부수효과 (입구: 파일 읽기) |
| 2 | readInventory | 저장소 · 프로필 → 스킬 · 설정 목록 | 부수효과 (입구: 파일 읽기) |
| 3 | extractClaims | 본문 → 언어별 주장 | 순수 |
| 4 | checkExistence | 주장 · 목록 → 없는 것 | 순수 |
| 5 | checkTopics | 주장 · 필수 주제 → 빠진 주제 | 순수 |
| 6 | checkParity | 언어별 주장 → 차이 | 순수 |
| 7 | report | 결과 → 출력 · 종료 코드 | 부수효과 (출구: 출력) |

옛 자료 검토:

```
flow(
  listOutdated,     // () → [자료, 가리키는 바뀐 파일들]           (readpath.sh outdated)
  judgeEach,        // (자료, 바뀐 파일, 지금 코드) → 판정 · 근거     (사람 · 모델 판단)
  buildReviewTable, // (판정들) → STALE_REVIEW.md 행
  pickReviewed,     // (판정들) → 다시 사용 표시할 자료 목록
  consumeReviewed,  // (목록) → readpath.sh consume <slug> <paths>
)
```

- 부수효과 위치: 파일 읽기와 `readpath.sh outdated`(입구), 출력 · 검토표 쓰기 · `readpath.sh consume`(출구).
- 재사용: `readpath.sh outdated` · `consume`(consume 은 이미 stale 에 있는 자료의 slug 를 덧붙이고 ref_commit 을 지금 HEAD 로
  다시 찍는다 — 코드 확인함), 기존 계약 검사(`tests/test-core-contract.sh`) · `tools/validate-core-tree.py`.

## Guardrails

- README · 검사 스크립트 · 코어 CI 연결 · 검토표 · `scv/readpath.json` · 계획 기록 밖의 파일은 바꾸지 않는다.
- 래퍼 README 에 버전 번호를 넣지 않는다. 클로드 README 에 코덱스 전용 문법(`$scv:` 등)을 쓰지 않는다.
- README 에 없는 명령 · 설정 · 기능을 적지 않는다 — 표식은 실제 파일에서 확인한 것만.
- 옛 자료 본문은 그대로 둔다. 판정 전에 consume 하지 않는다(경고만 꺼지고 낡은 내용이 가려진다).
- 검사 스크립트는 맥(bash 3.2 포함) · 리눅스에서 같게 동작한다. `core/` 에 호스트 이름을 넣지 않는다.

## Exit criteria

- All TESTS.md scenarios pass
- 세 저장소 main 의 README(영 · 한 · 일)와 코덱스 플러그인 README 가 새 내용이다 — GitHub 첫 화면에 보인다
- 옛 자료 21건 모두 검토표에 판정과 근거가 있고, 검토를 마친 자료는 경고 목록에서 빠졌다

## Suggested path

1. 기능 목록 정리 → 저장소별 필수 주제의 표식 확정(실제 파일 확인).
2. 검사 스크립트 작성 → 지금 README 에서 붉음(빠진 주제 · 업데이트 방법) 확인.
3. 코어 README(영 → 한 · 일)와 코어 CI 연결.
4. 클로드 래퍼 README, 코덱스 README · 플러그인 README (영 → 한 · 일).
5. 옛 자료 21건 대조 검토 → `STALE_REVIEW.md` → 검토를 마친 자료만 `readpath.sh consume`.
6. 검사 초록 · 기존 검사 통과 → 저장소별 PR → 병합 → `promote.yml -f release=false` → main 의 README 확인.
7. **(후속, 코어 배포 뒤)** 다음 코어 릴리스로 검사 스크립트가 래퍼 동기화에 실려 들어오면, 두 래퍼 CI 에 README 검사를
   연결한다 — 사용자 지시(2026-09-30, "코어 배포되면 래퍼 CI 연결 진행").

## Related Documents

- `STALE_REVIEW.md` (작업 때 생성) — 옛 자료 21건 검토표
- 부록 A — 검토 대상 목록

## Risks / Open Questions

- 필수 주제는 표식으로 잡는다 — 표에 없는 주제가 빠져도 검사는 못 잡는다(표는 보관 계획 제목에서 뽑았다).
- 한 · 일 번역의 뜻이 같은지는 구조 · 목록 일치로만 본다.
- 코어 README 는 래퍼 안 코어 사본에 다음 코어 릴리스 때 반영된다.
- 래퍼 CI 연결(Suggested path 7)은 다음 코어 배포에 달려 있다 — 배포 때 잊지 않도록 여기와 작업 메모에 적는다.
- 옛 자료 검토 분량이 README 작업만큼 클 수 있다(추정).

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:

## 부록 A — 검토 대상 옛 자료 21건 (2026-09-30 `readpath.sh outdated` 의 OUTDATED-CANDIDATE)

1. scv/raw/stale/20260812-wookiya1364-ci-provenance-gate.md
2. scv/raw/stale/20260812-wookiya1364-forced-invocation.md
3. scv/raw/stale/20260813-wookiya1364-deck-redesign.md
4. scv/raw/stale/20260814-wookiya1364-release-machinery.md
5. scv/raw/stale/20260818-wookiya1364-effort-governor.md
6. scv/raw/stale/20260818-wookiya1364-env-example-sync.md
7. scv/raw/stale/20260818-wookiya1364-regression-contract-repair.md
8. scv/raw/stale/20260818-wookiya1364-regression-runner-env-leak.md
9. scv/raw/stale/20260818-wookiya1364-sync-autopilot-guard-fixes.md
10. scv/raw/stale/20260824-wookiya1364-regression-contract-repair-2.md
11. scv/raw/stale/20260824-wookiya1364-settings-always-present.md
12. scv/raw/stale/20260826-wookiya1364-deck-density.md
13. scv/raw/stale/20260826-wookiya1364-deck-screen-spec-format.md
14. scv/raw/stale/20260827-wookiya1364-deck-picture-only.md
15. scv/raw/stale/20260914-wookiya1364-run-dry-audit.md
16. scv/raw/stale/20260916-always-on-per-turn-cost-diet.md
17. scv/raw/stale/20260916-answer-lint-one-turn-lag.md
18. scv/raw/stale/20260916-graft-partial-adoption-shared-conversation.md
19. scv/raw/stale/20260916-graph-dependency-decision.md
20. scv/raw/stale/20260920-wookiya1364-graft-guidance.md
21. scv/raw/stale/20260920-wookiya1364-regression-runner-lang-leak.md
