# Test Plan — 회귀 시험 — 같은 시험은 한 번만, 여러 개를 동시에

## Overview

같은 시험 줄은 한 번만 돌고, 여러 시험이 동시에 돌며, 계획별 판정은 그대로인지 본다. 임시 보관 폴더(계획 3–4개)와 실행 횟수를 파일에 남기는 가짜 시험으로 결정적으로 잰다.

## Test scenarios

### R1. 같은 시험 줄은 한 번만

- **Setup**: 계획 세 개가 모두 `bash t/count.sh` 를 적는다. count.sh 는 부를 때마다 횟수 파일에 한 줄 더한다.
- **Run**: 회귀.
- **Expected**: 횟수 파일 한 줄. 세 계획 모두 통과.
- **Pass criterion**: 줄 수 1, FAILED_SLUGS: 0.

### R2. 여러 시험이 동시에

- **Setup**: 서로 다른 시험 네 개가 각각 2초 잔다.
- **Run**: 회귀(동시 4).
- **Expected**: 전체가 8초가 아니라 약 2초대.
- **Pass criterion**: 걸린 시간 < 5초.

### R3. 공유 시험이 실패하면 그것을 적은 계획만 모두 실패

- **Setup**: 계획 A · B 가 fail.sh, C 는 ok.sh.
- **Run**: 회귀.
- **Expected**: A · B 실패, C 통과.
- **Pass criterion**: FAILED_SLUGS: 2, 실패 목록이 A · B.

### R4. serial 표시 시험은 혼자

- **Setup**: `# scv-test: serial` 표시 시험이 다른 시험과 같은 순간에 돌면 표시 파일로 알 수 있게.
- **Run**: 회귀.
- **Expected**: 겹침 없음.
- **Pass criterion**: 겹침 표시 0.

### R5. --no-memo 는 예전처럼

- **Setup**: R1.
- **Run**: 회귀 --no-memo.
- **Expected**: 횟수 3.
- **Pass criterion**: 줄 수 3.

### R6. 키가 아닌 줄은 계획 안에서 그대로

- **Setup**: 블록에 `bash t/ok.sh` 와 `grep -q x file` 이 함께.
- **Run**: 회귀.
- **Expected**: grep 줄은 그 계획 안에서 돈다(결과가 판정에 반영).
- **Pass criterion**: grep 이 실패하게 만든 경우 그 계획만 실패.

### R7. 기존 회귀 시험 그대로

- **Setup**: 저장소의 기존 regression 관련 시험.
- **Run**: 그 시험들.
- **Pass criterion**: 전부 통과.

### R8. 이 저장소 전체 회귀 — 끝까지, 시간 기록

- **Setup**: 이 저장소.
- **Run**: 전체 회귀.
- **Expected**: 끝까지 돈다. 계획별 판정이 바뀌기 전과 같다(바뀌기 전은 --no-memo 결과 또는 CI 기록과 비교).
- **Pass criterion**: 끝남 + 시간 숫자 + 판정 비교 차이 0.

## How to run

```bash
bash core/tests/test-regression-dedupe.sh
```

## Pass criteria

- R1–R8 통과.
