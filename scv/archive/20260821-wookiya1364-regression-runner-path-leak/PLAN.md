---
title: "회귀 러너의 경로 표시 누수 — 시나리오는 자기 scv 경로를 본다"
slug: 20260821-wookiya1364-regression-runner-path-leak
author: "wookiya1364"
created_at: 2026-08-21
status: done
kind: feature
lang: korean
tags: [regression, runner, env]
raw_sources:
  - scv/conversations/20260821-134035-regression-runner-path-leak.md
refs: []
supersedes: []
scope:
  - "core/scripts/regression.sh"
  - "core/tests/test-regression-env.sh"
  - "CHANGELOG.md"
invariants:
  - "사용자가 export 한 env 는 시나리오에 그대로 전달된다 (SCV_AUTOSYNC=off 포함)"
  - "러너 자신은 자기 경로 표시를 계속 쓴다 — 자식 시나리오에만 빠진다"
  - "제거 대상은 러너 자신의 표시 6개뿐: SCV_AUTOSYNC_RUNNING·SCV_DIR·RAW_DIR·STATE_FILE·PROMOTE_DIR·ARCHIVE_DIR"
---

# 회귀 러너의 경로 표시 누수

## Summary

러너는 시작할 때 `scv_init_paths` 로 자기 경로 표시(`SCV_DIR`·`RAW_DIR`·`STATE_FILE`·
`PROMOTE_DIR`·`ARCHIVE_DIR`)를 export 한다. 그 표시가 자식 시나리오에 상속돼,
임시 프로젝트 안에서 도는 헬퍼(work.sh 등)가 **이 저장소의** 경로를 본다.
어제 보관한 계약(plain-answers-enforcement)의 T6(run-dry [19])이 러너 안에서만
죽은 이유다 — 단독 972/972, 러너 안 실패. 0818 에 고친 `SCV_AUTOSYNC_RUNNING`
누수와 같은 종류이고, 같은 자리(run_scenario_clean)에서 같은 방식(env -u)으로 고친다.

## Goals / Non-Goals

- **Goals**: 러너가 시나리오를 돌릴 때 자기 표시 5개를 더 뺀다. 회귀 가드 1건
  (시나리오 환경에 5개 부재) + 실계약(plain-answers-enforcement)이 러너 안에서 통과.
- **Non-Goals**: scvroot 의 export 제거(한 액션 안의 헬퍼 중복 체크 방지 목적은
  유효 — 0818 결정), 스위트 쪽 자체 정화.

## Approach Overview

`run_scenario_clean` 의 `env -u SCV_AUTOSYNC_RUNNING` 에 `-u SCV_DIR -u RAW_DIR
-u STATE_FILE -u PROMOTE_DIR -u ARCHIVE_DIR` 를 더한다. 러너 프로세스 자신의
변수는 그대로(자기 헬퍼는 계속 쓴다). `test-regression-env.sh` 에 T5 추가: 가짜
슬러그가 다섯 변수 부재를 단언.

## Guardrails

- 제거 대상은 러너 자신의 표시 6개뿐. 사용자 env 는 손대지 않는다.
- 어떤 아카이브 TESTS.md 도 수정하지 않는다.
- 테스트에 git 상태 단언 금지.

## Exit criteria

- TESTS How-to-run exit 0: test-regression-env 전량 + 러너 안에서
  plain-answers-enforcement 실계약 통과(`regression.sh --only`).
- 누적 회귀 FAILED_SLUGS: 0.

## Suggested path

1. regression.sh 한 줄. 2. test-regression-env T5. 3. 실계약 러너 안 재실행. 4. CHANGELOG.

## Related Documents

- 선행: `scv/archive/20260818-wookiya1364-regression-runner-env-leak/PLAN.md`

## Risks / Open Questions

- scvroot 가 앞으로 표시를 더 export 하면 같은 누수가 재발한다 — 목록은 러너와
  scvroot 두 곳에 흩어져 있다. 이번엔 목록을 러너 주석에 적어 두는 데서 그친다.

## Links

- Raw originals: (frontmatter 참조)
- Related PRs:
