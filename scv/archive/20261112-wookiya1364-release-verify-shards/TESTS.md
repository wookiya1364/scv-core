# Test Plan — 릴리스 검증 나눠 돌리기

## Overview

릴리스 검증을 여섯 조각으로 나눠도 (1) 모든 시험이 꼭 한 번씩 돌고, (2) 조각이 모두 통과해야만 릴리스가 나가며, (3) 재는 시험이 다른 시험과 겹쳐 돌지 않는지 본다.
설정 파일의 모양은 저장소 시험으로, 표시와 나누기는 코어 시험으로 본다. 실제로 빨라졌는지는 릴리스 실행 기록에서 읽는다.

## Test scenarios

### T1. 재는 시험에는 혼자 돈다 표시가 있다

- **Setup**: 코어 시험 폴더의 `test-*.sh`
- **Run**: `bash core/tests/test-run-focused.sh`
- **Expected**: 재는 명령(`pure-bench.sh` · `pipe-arrange.sh`)을 실제로 돌리는 시험 파일은 모두 앞 30줄 안에 `# scv-test: serial` 이 있다. `test-slow-pure-functions.sh` 에도 있다.
- **Pass criterion**: 표시가 빠진 파일 0개. 표시를 하나 지우면 이 시험이 그 파일 이름을 대며 실패한다.

### T2. 표시가 있는 시험은 다른 시험이 다 끝난 뒤 하나씩 돈다

- **Setup**: 이미 있는 실행기 시험(T3)
- **Run**: `bash core/tests/test-run-focused.sh`
- **Expected**: 혼자 도는 시험의 시작이 다른 모든 시험의 끝보다 늦다.
- **Pass criterion**: 겹침 0 (이미 있는 시나리오가 그대로 통과).

### T3. 시간표에 모든 시험이 있고 조각이 고르다

- **Setup**: `core/tests/timings.tsv` · `core/tests/timings-macos.tsv`
- **Run**: `bash tests/test-release-verify.sh`
- **Expected**: 실행기가 모으는 시험(묶음 제외) 가운데 시간표에 없는 것이 0개다. 리눅스 시간표로 여섯에 나눈 조각의 합이 모두 "전체 합 ÷ 6 + 가장 긴 시험" 안이다.
- **Pass criterion**: 빠진 시험 0개 · 가장 무거운 조각 ≤ 평균 + 가장 긴 시험. 시간표에서 한 줄을 지우면 그 이름을 대며 실패한다.

### T4. 릴리스 설정: 여섯 조각이 모든 시험을 한 번씩 돌고, 릴리스는 그것을 기다린다

- **Setup**: `.github/workflows/release.yml`
- **Run**: `bash tests/test-release-verify.sh`
- **Expected**:
  - 조각 작업의 목록이 `[1, 2, 3, 4, 5, 6]` 이고 명령의 `--shard …/6` 과 수가 같다
  - 조각 명령이 PR 검사의 리눅스 조각 명령과 같은 폴더 · 덧붙임(`--dir tests --dir core/tests --also core/tests/run-dry.sh`)을 쓴다
  - 릴리스 작업에 `needs: verify` 가 있다
  - 시험 파일을 하나씩 도는 반복(`for test_file in core/tests/test-*.sh`)이 없다
  - 여섯 조각의 합집합이 실행기가 모으는 시험 전체와 같고 겹침이 없다
  - 조각에 기획서 도구(pnpm · node)가 있다 — 도구가 없으면 건너뛰는 기획서 시험이 릴리스에서는 돈다
  - 릴리스 작업은 꼬리표를 올릴 때만 돈다(설정을 고친 PR 에서는 조각만 미리 돈다)
- **Pass criterion**: 위 일곱 가지 모두 참. 목록을 다섯으로 줄이거나 `needs` 를 지우거나 도구를 빼면 실패한다.

### T5. 실제 릴리스에서 빨라졌다

- **Setup**: 이 PR 의 미리 돌려 보기 실행, 그리고 코어 0.92.1 릴리스 실행
- **Run**: `gh run view <실행> --json jobs` 로 조각마다 걸린 시간을 읽는다
- **Expected**: 조각 여섯이 모두 통과하고, 릴리스 작업은 그 뒤에 시작한다.
- **Pass criterion**: 가장 긴 조각 ≤ 240초 (앞: 한 줄로 1,953초). 코덱스 래퍼의 동기화 로봇이 PR 을 연다.

## How to run

```bash
bash core/tests/test-run-focused.sh && bash tests/test-release-verify.sh
```

## Pass criteria

- T1 ~ T4 가 옛 셸(bash 3.2)과 새 셸(bash 5)에서 통과한다
- 표시를 붙인 시험 셋이 두 셸에서 그대로 통과한다
- T5 는 릴리스 뒤 실행 기록의 숫자로 적는다

## Related Documents

- `core/tests/run-focused.sh` — 조각 실행기
