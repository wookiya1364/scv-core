---
title: 계획 없는 구현 PR 을 CI 가 막는다 (프로버넌스 게이트)
slug: 20260812-wookiya1364-ci-provenance-gate
author: wookiya1364
created_at: 2026-08-12
status: planned
kind: feature
lang: korean
tags: [ci, governance, provenance]
raw_sources:
  - scv/raw/stale/20260812-wookiya1364-ci-provenance-gate.md
refs: []
invariants:
  - "promote.yml 이 여는 develop→stage, stage→main PR 은 계속 자동 머지된다"
  - "core-sync.yml 이 여는 chore/core-* 봇 PR 은 계속 자동 머지된다"
  - "문서만 고친 PR 은 계속 머지된다"
  - "claude-code 의 branch-flow 잡은 timeout-minutes: 2 안에서 끝난다"
  - "check-frontmatter.sh 의 기존 두 스키마 분리(STANDARD_DOC / PLAN)는 그대로 둔다"
---

# 계획 없는 구현 PR 을 CI 가 막는다 (프로버넌스 게이트)

## Summary

지금 세 저장소에는 "계획 없이 구현만 올라온 PR" 을 막는 장치가 하나도 없다.
계획 문서를 보는 워크플로가 아예 없고, `check-frontmatter.sh` 는 CI 에서 실제
저장소를 검사하지 않으며, 검사 대상 glob 이 `scv/promote/` 하나뿐이라 `/scv:work`
가 아카이브를 먼저 하고 PR 을 여는 정상 경로에서는 볼 것이 없다. 이 계획은
**코드를 바꾸는 PR 은 그 PR 이 추가한 아카이브 계획을 반드시 함께 담아야
머지되도록** 만든다.

## Goals / Non-Goals

- **Goals**
  - 코드를 바꾸는 `→ develop` PR 이 아카이브된 계획 없이 머지되는 경로를 막는다.
  - 그 계획의 frontmatter 가 PLAN 스키마를 통과하는지 같은 게이트에서 검사한다.
  - `check-frontmatter.sh` 가 CI 에서 실제 저장소를 대상으로 돈다.
  - 게이트를 Core 에 한 벌만 두고 두 래퍼는 벤더된 것을 부른다 (중복 개발 없음).
  - 게이트 체크가 **모든 PR 에서 도는 잡** 안에 있어서 `required_status_checks`
    로 필수 지정이 가능하다.
- **Non-Goals**
  - 계획의 **내용** 품질 심사 — 스키마와 존재 여부만 본다.
  - `scv/raw` → `scv/promote` 단계의 강제 — 이 게이트는 아카이브 시점만 본다.
  - GitLab / 기타 호스트 지원 — 이번엔 GitHub Actions 만.

## Approach Overview

Core 에 `core/scripts/check-provenance.sh` 를 새로 만든다. 이 스크립트는 PR 의
변경 목록과 몇 개 환경변수만 받아서 판정하고, 파싱은 기존 `lib/yaml.sh` 와
`check-frontmatter.sh` 를 그대로 재사용한다.

판정 순서 (먼저 걸리는 것이 이깁니다):

1. **면제 — 릴리스 체인.** 타겟 브랜치가 `stage` 또는 `main` 이면 통과.
   `promote.yml` 이 여는 두 PR 이 여기 해당한다.
2. **면제 — 봇 동기화.** 소스 브랜치가 `chore/core-*` 이면 통과.
   `core-sync.yml` 이 여는 PR 이 여기 해당한다.
3. **면제 — 명시적 예외.** PR 제목에 `[no-plan: <이유>]` 가 있으면 통과하고
   그 이유를 잡 요약에 남긴다. 대괄호 안이 비어 있으면 예외로 인정하지 않는다
   — 이유를 적게 만드는 것이 이 형식의 목적이다.
4. **면제 — 코드 변경 없음.** 변경된 파일이 전부 `scv/**`, `*.md`, `LICENSE`,
   `.gitignore`, `.gitattributes` 중 하나면 통과.
5. **본 검사.** 위 어디에도 안 걸리면, 이 PR 이 **추가한**
   `scv/archive/*/PLAN.md` 가 하나 이상 있어야 한다. 없으면 실패하고, 어떻게
   고치는지(`/scv:work <slug>` 또는 `[no-plan: 이유]`)를 함께 출력한다.
6. **스키마 검사.** 추가된 각 `scv/archive/*/PLAN.md` 를
   `check-frontmatter.sh --plan <path>` 로 검사한다. 하나라도 실패하면 실패.

`check-frontmatter.sh` 에는 두 가지를 더한다. 스키마 판정 로직은 이미 그 안에
있으므로 새로 쓰지 않고 진입점만 넓힌다.

- `--plan <path>` — 파일 하나를 PLAN 스키마로 검사하는 진입점.
- 기본 glob 에 `scv/archive/*/PLAN.md` 추가 — 저장소 전체 실행 시 아카이브된
  계획도 검사 대상이 된다.

배치는 세 저장소 모두 `branch-flow.yml` 의 기존 잡 안에 스텝으로 넣는다. 이
워크플로만이 경로 필터 없이 모든 PR 에서 돌고, 그 체크가 이미 세 저장소
`required_status_checks` 에 올라가 있다. 새 워크플로를 만들면 경로 필터 문제와
필수 지정 문제를 다시 풀어야 한다.

호출 경로는 저장소마다 다르다.

| 저장소 | 스크립트 경로 |
|---|---|
| scv-core | `core/scripts/check-provenance.sh` |
| scv-claude-code | `vendor/scv-core/core/scripts/check-provenance.sh` |
| scv-codex | `plugins/scv/vendor/scv-core/core/scripts/check-provenance.sh` |

변경 목록은 `actions/checkout` 에 `fetch-depth: 0` 을 주고 병합 기준점에서
`git diff --name-status` 로 얻는다. 추가 판정은 `--diff-filter=A` 를 쓴다.

곁다리로, `scv-claude-code/scripts/check-branch-flow.sh` 는 벤더된 사본과
바이트 단위로 같은 죽은 중복이다. `branch-flow.yml` 을 어차피 손대므로 그때
벤더 경로를 부르도록 바꾸고 자체 사본을 지운다.

## Guardrails

- **릴리스 체인을 멈추지 말 것.** `promote.yml` 의 두 PR 과 `core-sync.yml` 의
  봇 PR 은 어떤 경우에도 이 게이트에 걸리면 안 된다. 이게 깨지면 릴리스가
  통째로 막힌다.
- **문서만 고친 PR 을 막지 말 것.** 지금도 그런 PR 은 `check-branch-flow` 하나만
  돌고 머지된다. 그 경로가 유지돼야 한다.
- **파서를 새로 쓰지 말 것.** frontmatter 는 `lib/yaml.sh` 의 `yaml_get` /
  `yaml_get_list` / `yaml_has_key` 만 쓴다. 임시 grep 파서를 쓰면 flow 스타일
  (`raw_sources: []`, 실제 계획 8 개 중 7 개가 이 형식) 에서 거짓 실패가 난다.
  스키마 판정도 `check-frontmatter.sh` 안의 것을 재사용하고 복제하지 않는다.
- **claude-code 의 2 분 제한.** 그 저장소 `branch-flow` 잡은
  `timeout-minutes: 2` 다. 게이트는 git diff 한 번과 파일 몇 개 읽기로 끝나야
  한다. 네트워크 호출을 넣지 말 것.
- **게이트는 경로 필터 없는 잡 안에 있어야 한다.** 그래야 필수 체크로 걸린다.
- **`check-frontmatter.sh` 의 기존 동작을 바꾸지 말 것.** 두 스키마 분리와
  기존 `--project-dir` 동작은 그대로 두고 진입점만 더한다.

## Exit criteria

- TESTS.md 시나리오 전부 통과.
- 세 저장소 각각에서, 계획 없이 코드만 바꾼 시험용 PR 이 **실제로 빨갛게**
  뜨고 머지 버튼이 막힌다 (`mergeStateStatus` 가 `BLOCKED`).
- 같은 세 저장소에서 문서만 고친 PR 과 `promote.yml` 이 여는 PR 은 그대로
  통과한다.
- 이 계획 자신의 PR 이 새 게이트를 통과한다 — 코드를 바꾸고 아카이브된 계획을
  담고 있으므로, 게이트가 제대로 작동하면 통과해야 정상이다.
- 세 저장소 ruleset 의 필수 체크 목록이 게이트를 포함한 뒤에도 열려 있는
  정상 PR 들이 여전히 머지 가능하다.

## Suggested path

1. `core/scripts/check-frontmatter.sh` 에 `--plan <path>` 진입점을 더하고,
   기본 glob 에 `scv/archive/*/PLAN.md` 를 추가한다.
2. `core/scripts/check-provenance.sh` 를 쓴다 (판정 6 단계, `lib/yaml.sh` 재사용).
3. `core/tests/` 에 게이트 단위 테스트를 더한다 — 면제 4 종, 실패 1 종,
   스키마 실패 1 종.
4. scv-core `branch-flow.yml` 에 `fetch-depth: 0` 과 게이트 스텝을 더한다.
5. `core-ci.yml` 의 `contracts` 잡에 저장소 전체 `check-frontmatter.sh` 실행을
   더한다 (지금은 CI 에서 한 번도 안 돈다).
6. 두 래퍼의 `branch-flow.yml` 에 같은 스텝을 벤더 경로로 더한다.
7. claude-code 의 중복 `scripts/check-branch-flow.sh` 를 지우고 벤더 경로로
   바꾼다.
8. 세 저장소에서 실패 케이스와 통과 케이스를 실제 PR 로 한 번씩 확인한다.

## Related Documents

- [`TESTS.md`](./TESTS.md)
- [`scv/raw/stale/20260812-wookiya1364-ci-provenance-gate.md`](../../raw/stale/20260812-wookiya1364-ci-provenance-gate.md) — 측정 기록

## Risks / Open Questions

- **`fetch-depth: 0` 이 clone 시간을 늘린다.** scv-core 는 이력이 짧아 문제
  없을 것으로 보지만, claude-code 의 2 분 제한에 얼마나 먹는지 실제로 재야
  한다. 넘치면 `fetch-depth: 0` 대신 base ref 만 얕게 받는 방식으로 바꾼다.
- **`[no-plan:]` 예외가 습관이 될 수 있다.** 이유를 강제하는 형식이지만 강제는
  형식뿐이다. 한동안 쓰인 횟수를 세어 보고, 잦으면 면제 4 번(코드 변경 없음)
  범위가 너무 좁은 것은 아닌지 다시 본다.
- **fork 에서 온 PR** 은 `fetch-depth: 0` 로도 base 를 못 볼 수 있다. 지금
  세 저장소는 fork PR 을 받지 않지만, 받게 되면 이 경로를 다시 봐야 한다.

## Links

- Raw originals: (frontmatter `raw_sources` 참조)
- Related PRs:
