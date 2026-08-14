# Test Plan — 승격 대기 판정과 벤더 게이트

## Overview

세 대상을 검증한다. 승격 워크플로의 대기 블록, 새 벤더 게이트, 그리고 그동안 검증이
없던 provenance 게이트다.

세 대상 모두 **문자열 검사로는 잡히지 않는다**. 대기 블록은 두 번 다 문장으로는 맞게
읽혔고 특정 입력에서의 동작만 틀렸다. 게이트는 첫 줄에서 0으로 끝나도 통과 케이스를
전부 통과시킨다. 그래서 전부 동작으로 검사하고, 마지막에 "이 검사가 실제로 무언가를
판정하는가"를 따로 확인한다.

## Test scenarios

### T1. 건너뛴 매트릭스 자리표시자만 있을 때 머지하지 않는다

0.26.0 에서 두 번 손머지를 만든 그 상태다.

- **Setup**: rollup 에 `Contract (<확장 안 된 matrix.os>)` (COMPLETED/SKIPPED) 하나만,
  `mergeStateStatus`= `BLOCKED`. 다음 상태에서 진짜 체크가 **실패**로 도착한다
- **Run**: `promote.yml` 의 `await-mergeable` 블록을 마커 사이에서 잘라내 실행.
  `gh` 와 `sleep` 만 대역
- **Expected**: 머지하지 않고 중단
- **Pass criterion**: 블록이 0이 아닌 값으로 끝난다

> 단언이 **부정형**인 것이 핵심이다. "결국 머지된다"는 픽스처는 옛 코드도 새 코드도
> MERGE 로 끝나 판별력이 없다. 일찍 머지하는 코드는 뒤에 오는 실패를 못 본다.

### T2. 진짜 체크가 도착해 통과하면 승격은 진행된다

- **Setup**: T1 과 같은 시작 상태. 다음 상태에서 `CLEAN` + 전부 SUCCESS
- **Expected**: 머지로 진행
- **Pass criterion**: 블록이 0으로 끝난다

### T3. `BLOCKED` 에서 풀리지 않으면 상한까지 기다린 뒤 실패한다

- **Setup**: 상태가 계속 `BLOCKED`
- **Expected**: 머지하지 않고, PR 은 열린 채로 남긴다
- **Pass criterion**: 블록이 0이 아닌 값으로 끝난다

### T4. `UNSTABLE` 이어도 도는 체크가 없으면 머지한다

`CLEAN` 만 요구했을 때 빠지는 반대쪽 함정이다. 건너뛴 자리표시자가 rollup 을 계속
`UNSTABLE` 로 붙잡으면 필수 체크가 다 통과했는데도 아무것도 머지되지 않는다.

- **Setup**: `mergeStateStatus`=`UNSTABLE`, 실패 없음, 대기 없음
- **Expected**: 머지로 진행
- **Pass criterion**: 블록이 0으로 끝난다

### T5. 실패한 체크는 즉시 체인을 멈춘다

- **Setup**: rollup 에 `conclusion=FAILURE` 하나
- **Expected**: 상한까지 기다리지 않고 중단
- **Pass criterion**: 블록이 0이 아닌 값으로 끝난다

### T6. 두 rollup 모양을 모두 읽는다

check run 은 `status`+`conclusion` 을, commit status 는 `state` 만 들고 온다. 한쪽만
읽으면 CI 의 절반이 안 보인다.

- **Setup**: (a) `state=PENDING` 인 commit status, (b) `state=FAILURE` 인 commit status
- **Expected**: (a) 대기 후 실패, (b) 즉시 중단
- **Pass criterion**: 두 경우 다 머지하지 않는다

### T7. 기타 머지 상태를 올바로 다룬다

- **Setup**: `DIRTY` / `UNKNOWN` / `BEHIND` / 체크가 아예 없는 저장소
- **Expected**: `DIRTY` 즉시 중단 · `UNKNOWN` 은 준비됨으로 보지 않음 ·
  `BEHIND` 는 `update-branch` 호출 후 계속 · 체크 없으면 머지
- **Pass criterion**: 각각 위 동작. `BEHIND` 는 호출 기록으로 확인

### T8. 손으로 벤더링한 PR 이 막힌다

- **Setup**: `chore/release-*` 브랜치가 `vendor/scv-core/` 를 수정. 중첩 배치
  (`plugins/scv/vendor/scv-core/`)도 같이
- **Run**: `check-vendor-provenance.sh`
- **Expected**: 두 배치 모두 거부
- **Pass criterion**: 스크립트가 0이 아닌 값으로 끝난다

### T9. 벤더 게이트의 면제가 전부 통한다

- **Setup**: (a) 봇 브랜치 `chore/core-*`, (b) `stage` 대상, (c) `main` 대상,
  (d) 제목에 `[manual-vendor: <이유>]`
- **Expected**: 전부 통과
- **Pass criterion**: 네 경우 다 0으로 끝난다. 하나라도 막히면 릴리스가 선다

### T10. 이유 없는 표지는 거부한다

- **Setup**: 제목이 `[manual-vendor]` (이유 없음)
- **Expected**: 거부. 이유가 표지의 전부다
- **Pass criterion**: 0이 아닌 값으로 끝난다

### T11. 벤더 게이트가 무관한 PR 을 막지 않는다

- **Setup**: (a) 벤더 트리를 안 건드리는 PR, (b) 이름만 비슷한 경로
  (`docs/vendor-scv-core-notes.md`, `src/vendorer.ts`)
- **Expected**: 둘 다 통과. 규칙은 디렉터리 경계이지 부분 문자열이 아니다
- **Pass criterion**: 0으로 끝난다

### T12. provenance 게이트의 판정이 유지된다

이 게이트에는 지금까지 테스트가 없었다. 판정을 바꾸지 않고 현재 동작을 고정한다.

- **Setup**: (a) 계획 없는 코드 변경, (b) 보관된 계획이 있는 코드 변경,
  (c) 문서만, (d) `scv/` 안만, (e) 릴리스 체인, (f) 봇 브랜치,
  (g) `[no-plan: <이유>]`, (h) 이유 없는 `[no-plan]`
- **Expected**: (a)(h) 거부, 나머지 통과
- **Pass criterion**: 여덟 경우 전부 예상대로

> 픽스처는 **실제 git 저장소**다. 검증 대상에 diff 를 읽는 방식(merge-base 해석,
> 경로 모양)이 포함되므로, 스텁은 git 의 동작이 아니라 내가 이해한 git 을 검증하게
> 된다. 계획서 파일은 frontmatter 스키마까지 갖춰야 한다 — 게이트가 찾은 뒤에
> 검증하므로, 내용이 자리표시자면 "계획 없음"으로 읽힌다.

### T13. 이 검사들이 실제로 무언가를 판정한다

- **Setup**: 대기 블록을 **옛 버전**으로 되돌리고 T1–T7 을 돌린다. 게이트는 통과
  케이스와 별개로 거부 케이스가 실제 거부인지 확인한다
- **Expected**: 옛 대기 블록에서 회귀 케이스(T1)가 **실패**한다. 두 게이트가 각각
  최소 하나를 거부한다
- **Pass criterion**: 옛 코드에서 실패 수 > 0. 첫 줄에서 0으로 끝나는 스크립트는
  통과 케이스를 전부 통과시키므로, 이 확인이 없으면 스위트는 아무것도 판정하지 않는
  게이트를 건강하다고 보고한다

### T14. 마커가 사라지면 조용히 통과하지 않는다

- **Setup**: `promote.yml` 에서 `await-mergeable` 마커를 제거
- **Expected**: 테스트가 시끄럽게 실패한다
- **Pass criterion**: 잘라낸 블록이 비었거나 비정상적으로 짧으면 실패로 보고

### T15. 전체 스위트가 여전히 초록이다

- **Setup**: 변경 전체
- **Run**: `tests/run.sh`, `core/tests/run-dry.sh`, `core/tests/test-*.sh`,
  `tests/test-host-neutral.sh`, `tests/test-guard-consistency.sh`
- **Expected**: 실패 0
- **Pass criterion**: 새 스크립트가 `core/` 호스트 중립성을 깨지 않는다

## How to run

```bash
bash tests/test-promote-wait.sh && bash core/tests/test-provenance-gates.sh
```

## Pass criteria

- T1–T15 전부 통과
- T13 이 핵심이다. 옛 코드에서 실패하지 않는 회귀 테스트는 회귀 테스트가 아니다
- `tests/run.sh` · `core/tests/run-dry.sh` · `core/tests/test-*.sh` 실패 0
- 릴리스 아티팩트에 `core/scripts/check-vendor-provenance.sh` 가 들어간다

## Related Documents

- [`PLAN.md`](./PLAN.md)
