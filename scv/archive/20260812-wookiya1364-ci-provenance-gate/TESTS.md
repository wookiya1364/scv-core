# Test Plan — 계획 없는 구현 PR 을 CI 가 막는다 (프로버넌스 게이트)

## Overview

검증할 것은 두 가지다. 첫째, 게이트가 **막아야 할 것을 실제로 막는가** — 계획
없이 코드만 바꾼 PR. 둘째, 게이트가 **막지 말아야 할 것을 통과시키는가** —
릴리스 체인 PR, 봇 동기화 PR, 문서만 고친 PR. 두 번째가 깨지면 릴리스 전체가
멈추므로 면제 경로를 먼저, 더 촘촘히 본다.

게이트는 PR 컨텍스트에 의존하므로 환경변수와 변경 파일 목록을 주입하는 방식으로
테스트한다. `check-provenance.sh` 는 GitHub API 를 부르지 않고 주어진 입력만
읽어야 하며, T10 이 그 성질을 직접 검사한다.

## Test scenarios

### T1. 계획 없는 코드 변경 PR 은 실패한다

- **Setup**: 임시 저장소. `BASE_REF=develop`, `HEAD_REF=feat/x`,
  `PR_TITLE="feat: add refund button"`. 변경 목록 = `M\tsrc/refund.ts`.
  추가된 `scv/archive/*/PLAN.md` 없음.
- **Run**: `bash core/scripts/check-provenance.sh`
- **Expected**: exit 1. 출력에 `/scv:work` 와 `[no-plan:` 두 복구 방법이 모두
  나온다.
- **Pass criterion**: exit code 가 1 이고, stdout/stderr 에 `/scv:work` 문자열과
  `[no-plan:` 문자열이 각각 1 회 이상 포함된다.

### T2. 계획을 추가한 코드 변경 PR 은 통과한다

- **Setup**: T1 과 같되 변경 목록에
  `A\tscv/archive/20260812-wookiya1364-x/PLAN.md` 를 더하고, 그 파일을 PROMOTE.md
  §4 템플릿대로(title/slug/author/created_at/status/tags 포함, `status: planned`)
  실제로 만든다. `raw_sources: []` 인라인 flow 형식으로 쓴다.
- **Run**: `bash core/scripts/check-provenance.sh`
- **Expected**: exit 0.
- **Pass criterion**: exit code 0. flow 스타일 `raw_sources: []` 때문에 실패하지
  않는다 — 이게 확인 5 의 회귀 방지선이다.

### T3. 릴리스 체인 PR 은 면제된다 (develop→stage, stage→main)

- **Setup**: 두 번 돌린다. (a) `BASE_REF=stage`, `HEAD_REF=develop`.
  (b) `BASE_REF=main`, `HEAD_REF=stage`. 두 경우 모두 변경 목록에 코드 파일을
  포함시키고 아카이브 계획은 **넣지 않는다** (실제 릴리스 PR 이 그렇다).
- **Run**: `bash core/scripts/check-provenance.sh` (각각)
- **Expected**: 두 번 다 exit 0.
- **Pass criterion**: 두 실행 모두 exit code 0. 이게 실패하면 릴리스 체인이
  멈추므로 다른 어떤 시나리오보다 우선한다.

### T4. core-sync 봇 PR 은 면제된다

- **Setup**: `BASE_REF=develop`, `HEAD_REF=chore/core-v0.25.0`. 변경 목록에
  벤더 트리 파일(`vendor/scv-core/core/scripts/help.sh` 등)을 넣고 계획은 없음.
- **Run**: `bash core/scripts/check-provenance.sh`
- **Expected**: exit 0.
- **Pass criterion**: exit code 0. `chore/core-` 로 시작하는 소스 브랜치는
  이유를 묻지 않고 통과한다.

### T5. 문서만 고친 PR 은 면제된다

- **Setup**: `BASE_REF=develop`, `HEAD_REF=docs/typo`. 변경 목록 =
  `M\tREADME.md`, `M\tdocs/release.md`, `M\tCHANGELOG.md`. 계획 없음.
- **Run**: `bash core/scripts/check-provenance.sh`
- **Expected**: exit 0.
- **Pass criterion**: exit code 0.

### T6. scv/ 안만 고친 PR 은 면제된다

- **Setup**: `BASE_REF=develop`, `HEAD_REF=chore/scv-tidy`. 변경 목록 =
  `M\tscv/DECISIONS.md`, `A\tscv/raw/note.md`. 계획 추가 없음.
- **Run**: `bash core/scripts/check-provenance.sh`
- **Expected**: exit 0.
- **Pass criterion**: exit code 0.

### T7. `[no-plan: 이유]` 예외는 통과, 빈 대괄호는 불통과

- **Setup**: 세 번 돌린다. 셋 다 `BASE_REF=develop`, 변경 목록에 코드 파일,
  계획 없음. 제목만 다르다.
  (a) `PR_TITLE="fix: [no-plan: 롤백 핫픽스, 원 계획은 20260811-...]"`
  (b) `PR_TITLE="fix: [no-plan:]"`
  (c) `PR_TITLE="fix: [no-plan]"`
- **Run**: `bash core/scripts/check-provenance.sh` (각각)
- **Expected**: (a) exit 0. (b) exit 1. (c) exit 1.
- **Pass criterion**: (a) 만 0, (b)(c) 는 1. 이유 없는 예외는 예외가 아니다.

### T8. 추가된 계획의 frontmatter 가 스키마를 어기면 실패한다

- **Setup**: T2 와 같되 계획 파일에서 `author` 키를 지운다.
- **Run**: `bash core/scripts/check-provenance.sh`
- **Expected**: exit 1. 출력에 `missing required key 'author'` 가 나온다.
- **Pass criterion**: exit 1 이고 `author` 를 지목하는 문구가 있다. 판정 문구가
  `check-frontmatter.sh` 의 것과 같아야 한다 — 스키마 판정을 복제하지 않았다는
  증거다.

### T9. check-frontmatter 가 아카이브된 계획도 검사한다

- **Setup**: 임시 프로젝트에 `scv/archive/<slug>/PLAN.md` 를 하나 두고,
  `status` 를 `draft`(표준문서 상태값, PLAN 스키마에서는 무효) 로 만든다.
  `scv/promote/` 는 비워 둔다.
- **Run**: `bash core/scripts/check-frontmatter.sh --project-dir <tmp>`
- **Expected**: exit 1, `invalid status 'draft'`.
- **Pass criterion**: exit 1. 지금 코드로는 `scv/promote/` 만 보므로
  `✓ All frontmatter valid` 로 통과해 버린다 — 이 시나리오가 그 공회전을 잡는다.

### T10. 게이트는 네트워크를 쓰지 않는다 (2 분 제한 보호)

- **Setup**: T2 와 같은 통과 케이스.
- **Run**: `PATH` 에서 `gh` / `curl` / `wget` 를 가린 상태로
  `bash core/scripts/check-provenance.sh`
- **Expected**: exit 0 — 이 셋이 없어도 동일하게 동작한다.
- **Pass criterion**: exit code 0. 네트워크 도구 없이 통과하면 claude-code 의
  `timeout-minutes: 2` 안에서 끝난다는 근거가 된다.

### T11. 세 저장소의 워크플로가 각자 올바른 경로를 부른다

- **Setup**: 세 저장소의 `branch-flow.yml` 을 파싱한다.
- **Run**: 각 파일에서 게이트 스텝의 `run:` 문자열과 `checkout` 의
  `fetch-depth` 를 뽑아 비교한다.
- **Expected**:
  - scv-core → `core/scripts/check-provenance.sh`
  - scv-claude-code → `vendor/scv-core/core/scripts/check-provenance.sh`
  - scv-codex → `plugins/scv/vendor/scv-core/core/scripts/check-provenance.sh`
  - 세 파일 모두 `fetch-depth: 0`
- **Pass criterion**: 세 경로가 각각 실제로 존재하는 파일을 가리키고,
  `fetch-depth: 0` 이 셋 다 있다.

### T12. claude-code 의 중복 사본이 사라졌다

- **Setup**: scv-claude-code 저장소.
- **Run**: `test -e scripts/check-branch-flow.sh` 와
  `branch-flow.yml` 의 `run:` 문자열 확인.
- **Expected**: 자체 사본이 없고, `run:` 이 벤더 경로를 부른다.
- **Pass criterion**: `scripts/check-branch-flow.sh` 가 존재하지 않고,
  `branch-flow.yml` 의 `run:` 에 `vendor/scv-core` 가 들어 있다.

### T13. 실제 PR 에서 머지가 막힌다 (통합)

- **Setup**: 세 저장소 각각에 계획 없이 코드 한 줄만 바꾼 시험용 브랜치를 만들어
  `develop` 로 PR 을 연다.
- **Run**: `gh pr view <n> --json mergeStateStatus,statusCheckRollup`
- **Expected**: 게이트 체크가 `FAILURE`, `mergeStateStatus` 가 `BLOCKED`.
- **Pass criterion**: 세 저장소 모두 `BLOCKED`. 확인 후 시험용 PR 은 닫고
  브랜치를 지운다.

### T14. 실제 PR 에서 정상 경로는 계속 통과한다 (통합)

- **Setup**: 세 저장소 각각에 문서 한 줄만 바꾼 시험용 PR 을 `develop` 로 연다.
- **Run**: `gh pr view <n> --json mergeStateStatus,statusCheckRollup`
- **Expected**: 게이트 체크가 `SUCCESS`, `mergeStateStatus` 가 `CLEAN`.
- **Pass criterion**: 세 저장소 모두 `CLEAN`. 확인 후 닫고 브랜치를 지운다.

## How to run

```bash
bash core/tests/test-provenance.sh
```

## Pass criteria

- T1–T12 가 전부 통과한다 (`test-provenance.sh` 한 번 실행으로 끝난다).
- T3 은 다른 어떤 시나리오보다 먼저 통과해야 한다 — 여기가 깨지면 릴리스 체인이
  멈추므로, 실패 시 게이트를 배포하지 않는다.
- T13 / T14 는 실제 PR 로 한 번 확인하고, 확인 뒤 시험용 PR 과 브랜치를 정리한다.
- 기존 `core/tests/run-dry.sh` 와 `tests/run.sh` 가 회귀 없이 그대로 통과한다.

## Related Documents

- [`PLAN.md`](./PLAN.md)
