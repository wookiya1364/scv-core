---
title: 회귀 러너의 autosync 가드 누수 — 시나리오는 깨끗한 환경에서 돈다
slug: 20260818-wookiya1364-regression-runner-env-leak
author: wookiya1364
created_at: 2026-08-18
status: done
kind: feature
lang: korean
tags: [regression, autosync, env, runner]
raw_sources:
  - scv/raw/stale/20260818-wookiya1364-regression-runner-env-leak.md
refs: []
invariants:
  - "러너 자신의 재진입 방지는 유지 — 한 번의 러너 실행 안에서 헬퍼들의 autosync 중복 체크 금지는 그대로"
  - "아카이브된 TESTS 본문 무수정 — 수정은 러너 쪽에서만"
  - "사용자가 직접 설정한 환경변수는 시나리오에 그대로 전달 — 제거 대상은 러너가 스스로 export한 내부 플래그뿐"
  - "러너의 다른 계약 불변 — --ci 비대화, supersede/obsolete 스킵 그래프, 판정 규칙"
---

# 회귀 러너의 autosync 가드 누수 — 시나리오는 깨끗한 환경에서 돈다

## Summary

회귀 러너는 시작할 때 "문서가 낡았나"를 한 번 확인하고, 같은 실행 안에서 중복
확인을 막으려고 내부 표시(`SCV_AUTOSYNC_RUNNING=1`)를 켠다. 문제는 이 표시가
러너가 실행하는 시험 대상(각 슬러그의 `## How to run`)에까지 상속된다는 것 —
autosync 훅 자체를 검증하는 계약이 러너 안에서만 죽는다 (러너 안 10/11 실패,
깨끗한 환경 21/21). 러너가 시나리오를 실행할 때 그 표시 하나만 지우고 실행한다.

## Goals / Non-Goals

- **Goals**
  - 러너가 실행하는 시나리오의 환경에 `SCV_AUTOSYNC_RUNNING`이 존재하지 않는다.
  - `20260818-wookiya1364-sync-autopilot` 아카이브 계약이 러너 안에서 통과한다
    (누적 회귀 11/11 복원).
  - 신규 스위트로 이 환경 위생 계약을 회귀로 고정한다.
- **Non-Goals**
  - test-autosync.sh 등 스위트 쪽 방어 보강 — 스위트가 호출자의 누수를
    가려버리면 다른 곳의 같은 버그를 뒤늦게 발견하게 되므로 기각 (Risk에 맹점 기록).
  - `core/scripts/lib/scvroot.sh` 수정 — export 지점은 본래 목적대로 둔다.
  - 러너의 다른 동작(스킵 그래프·판정·--ci·트리아지) 변경.

## Approach Overview

`core/scripts/regression.sh`의 시나리오 실행 지점에서, 자식 프로세스의 환경에서
`SCV_AUTOSYNC_RUNNING`만 제거하고(`env -u` 상당) `## How to run`을 실행한다.
러너 프로세스 자신 안의 표시는 그대로라 재진입 방지는 살아 있고, 사용자가 직접
설정한 다른 환경변수(`SCV_AUTOSYNC=off` 포함)는 전부 그대로 상속된다.
비유: 건물 입구의 소독 완료 스티커는 유지하고, 방문객 이마에 붙이는 것만 멈춘다.

## Guardrails

- 수정 파일은 `core/scripts/regression.sh` (와 신규 테스트 스위트) 뿐이다.
  `scvroot.sh`·`test-autosync.sh`·아카이브된 TESTS 본문은 건드리지 않는다.
- 제거하는 환경변수는 `SCV_AUTOSYNC_RUNNING` 단 하나. 사용자 의도의 env
  (`SCV_AUTOSYNC=off` 등)는 시나리오에 그대로 전달한다.
- 러너 실행 자신의 재진입 방지(헬퍼 중복 체크 금지)는 유지한다.
- `--ci` 비대화, supersede/obsolete 스킵 그래프, 성공·실패 판정 규칙 불변.
- flaky 재시도 경로(`--only <slug>` 재귀 호출)에도 같은 위생이 적용되어야 한다.

## Exit criteria

- All TESTS.md scenarios pass
- 누적 회귀(무인자 실행)가 11/11 — `sync-autopilot` 계약이 러너 안에서 통과.
- `bash core/tests/test-autosync.sh` 단독 실행이 무수정으로 계속 21/21.

## Suggested path

1. `core/tests/test-regression-env.sh` — TESTS.md 시나리오를 덮는 신규 스위트
   (TDD Red 확인 후 진행).
2. `core/scripts/regression.sh` — 시나리오 실행 지점에서 자식 환경의
   `SCV_AUTOSYNC_RUNNING` 제거.
3. 누적 회귀 재실행 — 11/11 확인, 기존 스위트 전체 무손상 확인.

## Related Documents

## Risks / Open Questions

- 스위트 맹점(의도된 채택): test-autosync.sh는 여전히 오염 환경에 취약하다.
  미래의 다른 호출자가 같은 플래그를 켠 채 스위트를 부르면 같은 오판이
  재발한다 — 그때는 그 호출자를 고친다.
- 부수 효과: 지금까지는 누수 때문에 시나리오 안의 autosync가 전부 눌려 있었다.
  누수를 걷어내면, 러너의 자체 autosync가 PARTIAL로 끝난 프로젝트에서 각
  시나리오가 새로고침을 재시도할 수 있다 (수렴 후에는 버전 일치로 무동작).
  구현 시 이 경로가 시나리오 출력을 오염시키지 않는지 확인한다.
- `regression.sh`는 payload로 배포되므로 래퍼 전파는 다음 벤더링에 자동 포함.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
