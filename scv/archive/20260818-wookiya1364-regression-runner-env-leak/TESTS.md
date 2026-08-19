# Test Plan — 회귀 러너의 autosync 가드 누수 — 시나리오는 깨끗한 환경에서 돈다

## Overview

러너가 시나리오를 깨끗한 환경에서 실행하는지, 그러면서 러너 자신의 재진입
방지·사용자 env 통과·다른 계약이 전부 무손상인지를 검증한다. 픽스처는 실제
hydrate된 임시 프로젝트에 가짜 아카이브 슬러그를 심어 러너를 실제로 돌린다
(스텁 금지 — test-sync-dirty.sh 관례). 마지막으로 이 저장소의 진짜 아카이브
계약(sync-autopilot)이 러너 안에서 통과하는지 직접 확인한다.

## Test scenarios

### T1. 시나리오 환경에 러너의 내부 플래그가 없다

- **Setup**: hydrate된 픽스처 프로젝트의 scv/archive/에 가짜 슬러그를 만들고,
  그 TESTS.md의 `## How to run`이 `SCV_AUTOSYNC_RUNNING`의 부재를 검사하게 한다
  (`[[ -z "${SCV_AUTOSYNC_RUNNING:-}" ]]`).
- **Run**: 픽스처 프로젝트에서 러너 실행.
- **Expected**: 해당 슬러그 PASS.
- **Pass criterion**: 러너 요약에 FAILED_SLUGS: 0.

### T2. 사용자가 직접 설정한 환경변수는 시나리오에 전달된다

- **Setup**: 가짜 슬러그의 `## How to run`이 `USER_CANARY=9f3a`와
  `SCV_AUTOSYNC=off`의 존재를 검사한다.
- **Run**: `USER_CANARY=9f3a SCV_AUTOSYNC=off` 환경으로 러너 실행.
- **Expected**: 해당 슬러그 PASS — 제거되는 것은 러너의 내부 플래그뿐이다.
- **Pass criterion**: FAILED_SLUGS: 0.

### T3. 러너 자신의 autosync는 계약대로 수렴한다 (재진입 방지 유지)

- **Setup**: 스탬프가 낡은(2.0.0) 픽스처 프로젝트 + 무해한 가짜 슬러그.
- **Run**: 같은 픽스처에서 러너를 2회 실행.
- **Expected**: 1차 실행 stderr에 새로고침 보고가 정확히 1회(헬퍼 중복 없음),
  스탬프 수렴. 2차 실행에는 새로고침 보고 없음(무동작).
- **Pass criterion**: 1차 'refreshed' 보고 1회 + 2차 0회 + 스탬프가 payload
  버전과 일치.

### T4. 진짜 계약이 러너 안에서 통과한다 — sync-autopilot

- **Setup**: 이 저장소(scv-core) 자체. 별도 픽스처 없음.
- **Run**: `regression.sh --only 20260818-wookiya1364-sync-autopilot --quiet`
- **Expected**: PASS — 러너 안에서만 붉던 계약이 복원된다.
- **Pass criterion**: 러너 요약에 PASSED_SLUGS: 1, FAILED_SLUGS: 0.

### T5. --ci 비대화·판정 계약 불변

- **Setup**: (a) 전부 통과하는 가짜 슬러그 픽스처, (b) 실패하는 가짜 슬러그 픽스처.
- **Run**: 각 픽스처에서 `--ci`로 러너 실행 (stdin 차단).
- **Expected**: (a) exit 0, (b) exit 2 — 어느 쪽도 질문·대기 없음.
- **Pass criterion**: 종료 코드 일치 + 입력 대기로 인한 타임아웃 없음.

### T6. 스위트·라이브러리 무수정 증명

- **Setup**: 없음.
- **Run**: `bash core/tests/test-autosync.sh` (깨끗한 환경, 단독 실행).
- **Expected**: 21/21 — 이 플랜이 스위트나 scvroot.sh를 건드리지 않았음을
  동작으로 증명한다.
- **Pass criterion**: passed: 21 / failed: 0.

## How to run

```bash
bash core/tests/test-regression-env.sh
```

## Pass criteria

- T1~T6 전부 통과.
- 누적 회귀(무인자)가 11/11 (Exit criteria의 직접 확인 — T4가 그 핵심 슬러그).
- 기존 스위트 전체(35개) 무손상.

## Related Documents
