---
title: "회귀 러너 — 같은 스위트 호출은 한 번만 (suite-gate memoization)"
slug: 20260824-wookiya1364-regression-runner-memo
author: "wookiya1364"
created_at: 2026-08-24
status: done
kind: feature
lang: korean
tags: [regression, runner, performance]
raw_sources:
  - scv/raw/stale/20260824-wookiya1364-regression-runner-memo.md
refs: []
supersedes: []
scope:
  - "core/scripts/regression.sh"
  - "core/tests/test-regression-memo.sh"
  - "core/protocols/regression.md"
  - "CHANGELOG.md"
invariants:
  - "메모이제이션 대상은 정확히 세 호출뿐 — bash core/tests/run-dry.sh · bash tests/run.sh · for t in core/tests/test-*.sh 루프. 그 밖의 줄은 쓰인 그대로 매번 실행"
  - "같은 run 안에서만 재사용 — run 이 끝나면 캐시도 끝난다"
  - "실패한 관문은 실패로 재사용된다 — 통과로 바뀌지 않는다"
  - "--no-memo / SCV_REGRESSION_MEMO=off 면 이전과 바이트 동일한 실행"
---

# 회귀 러너 — 같은 스위트 호출은 한 번만

## Summary

보관 계약 28개 중 22개가 마지막 줄에 스위트 전량을 부른다. 같은 명령의 결과는 한 run
안에서 달라질 수 없으니 한 번만 돌리고 나머지는 종료 코드를 재사용한다. 계약 파일은
손대지 않고 러너만 바뀐다. 회귀 시간이 계약 수에 비례해 늘던 구조가 사라진다.

## Goals / Non-Goals

- **Goals**: 관문 세 호출의 1회 실행 + 재사용(종료 코드), `MEMOIZED_GATES:` 요약 줄,
  `--no-memo`/`SCV_REGRESSION_MEMO=off`, 회귀 가드 `test-regression-memo.sh`.
- **Non-Goals**: 임의 명령의 일반 캐시(사용자 블록의 다른 줄은 절대 건드리지 않음),
  계약 TESTS 재작성.

## Approach Overview

블록을 돌리기 전에 줄 단위로 관문 패턴을 찾아(메인 셸에서) 각 관문을 한 번 실행하고
캐시에 넣는다. 그 뒤 블록의 해당 줄을 `( exit <종료코드> )` 로 치환하되 뒤따르는
리다이렉션·`|| fail …` 는 그대로 둔다 — 계약의 판정 문장은 원문 그대로 작동한다.
캐시는 러너 프로세스 변수라 서브셸로 새지 않도록 준비(prepare)와 치환(rewrite)을
나눈다. 관문 실행 환경은 시나리오와 같다(러너 표시 6개 제거).

## Guardrails

- 관문 셋 외의 줄은 바이트 그대로. 관문 줄도 리다이렉션·`|| fail` 부분은 보존.
- 캐시는 run 단위. 실패는 실패로 재사용.
- 새 계약의 TESTS 는 자기 테스트 파일만 부른다(전체 스위트 금지 — 이 계획이 그 규칙의 첫 준수 사례).

## Exit criteria

- `test-regression-memo.sh` 전량 통과. 실제 저장소 누적 회귀가 메모 켠 채 0 실패로, 이전
  (15분+)보다 확연히 짧게 끝난다(시간을 CHANGELOG 에 실측으로 적는다).

## Suggested path

1. 러너 패치(prepare/rewrite/요약/플래그). 2. 테스트. 3. regression.md 한 단락. 4. 실측 → CHANGELOG.

## Related Documents

- 선행: `scv/archive/20260821-wookiya1364-regression-runner-path-leak/PLAN.md`

## Risks / Open Questions

- 관문 줄 앞에 `cd` 나 env 설정이 있는 계약은 캐시된 결과가 그 문맥을 반영하지 않는다 —
  현재 보관 계약에는 없고, 패턴은 줄 시작 위치로만 잡는다.
