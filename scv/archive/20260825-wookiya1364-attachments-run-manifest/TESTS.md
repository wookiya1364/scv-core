# Test Plan — 첨부는 실행 기록을 따른다

## Overview

SCV 가 테스트를 돌린 실행이 만든 파일 목록(run manifest)이 기록되고, 첨부가
기록 → 이름 매칭 → 알림 순서로 동작하며, 잘린 폴더 이름(ai_tm_center 재현)이
기록 경유로 붙고, 같은 브랜치의 열린 PR 이 중복 생성되지 않는지 확인한다.

## Test scenarios

### T1. 기록 왕복 — record 가 새 파일만, read 가 존재하는 것만 (test-run-manifest.sh)
- **Setup**: 임시 프로젝트. `test-results/` 에 기존 파일 1개(다른 슬러그 잘린
  이름), marker 생성 후 잘린 이름 폴더(`…-readi-<해시>-…`)에 새 파일 2개.
- **Run**: `run_manifest_record` → `run_manifest_read`
- **Expected**: 기록에 새 파일 2개만(기존 1개·`.scv/` 자신 제외), read 는 그
  2개 출력. 파일 하나를 지우면 read 는 1개만. 기록 파일 자체가 없으면 출력 없음.

### T2. 실행 래퍼 — 명령 실행·종료코드·기록·요약 (test-run-manifest.sh)
- **Setup**: 가짜 TESTS.md(`## How to run` 에 잘린 이름 폴더로 파일을 만드는
  명령), 실패 명령 케이스 별도.
- **Run**: `run-plan-tests.sh --slug <slug> --tests <TESTS.md>` / `-- <cmd>` /
  실패 명령
- **Expected**: 파일 생성 + manifest 기록 + `manifest: N file(s)` stderr 요약.
  실패 명령은 종료코드 그대로 전달되면서 manifest 는 기록된다.

### T3. collect-artifacts 우선순위 — 기록 1순위·이름 폴백·0건 알림 (test-run-manifest.sh)
- **Setup**: (a) manifest 있음 + 잘린 이름 png/webm, 다른 슬러그 최신 파일 공존
  (b) manifest 없음 + 슬러그 포함 이름 파일 (c) manifest 없음 + 이름 불일치만.
- **Run**: `collect-artifacts.sh passed` (슬러그 해석: 활성 plan 1개)
- **Expected**: (a) 기록된 파일만 — 다른 슬러그 최신이 이겨도 안 나온다
  (b) 기존 이름 매칭 그대로 (c) 출력 없음 + **stderr 한 줄 알림** (현재는 침묵).

### T4. pr-helper dry-run — 기록 경유 첨부와 재실행 래퍼 (test-run-manifest.sh)
- **Setup**: git 저장소 임시 프로젝트, archive/<slug>/PLAN.md + TESTS.md,
  잘린 이름 결과 + manifest. 재실행 케이스: 결과·기록 없음, How-to-run 이
  잘린 이름 파일을 만드는 명령.
- **Run**: `pr-helper.sh --dry-run <slug>` (dry-run 은 재실행 안 함 — 재실행
  검증은 run-plan-tests.sh 직접 호출로 대체)
- **Expected**: dry-run 의 `ATTACHMENTS_FILES:` 에 기록된 파일들이 나열된다.
  재실행 대체 검증: run-plan-tests.sh 실행 후 같은 dry-run 이 0 → N 으로 변한다.

### T5. PR 중복 방지 — 열린 PR 이 있으면 갱신 (test-run-manifest.sh)
- **Setup**: PATH 앞에 가짜 `gh`(`pr list --head` 가 열린 PR 1건 반환, 호출
  기록 남김). pr-helper 를 create 직전 단계까지 진행 가능한 임시 저장소.
- **Run**: `pr-helper.sh <slug>` (가짜 gh, push 생략 옵션)
- **Expected**: `gh pr create` 미호출(호출 기록에 없음), `PR updated:` 출력.
  가짜 gh 가 빈 목록을 주면 기존대로 create 경로.

### T6. 기존 계약 불변 (test-attachments-scope.sh — 기존 파일 그대로)
- **Run**: `bash core/tests/test-attachments-scope.sh`
- **Expected**: 전부 green — scope=all·슬러그 해석·이름 필터·기존 dry-run 계약
  이 이번 변경 후에도 그대로다.

## How to run

```bash
bash core/tests/test-run-manifest.sh && bash core/tests/test-attachments-scope.sh
```

## Pass criteria

- 두 테스트 파일 모두 실패 0.
- T3(c) 알림과 T5 의 `PR updated:` 는 문자열 검증까지 통과.
