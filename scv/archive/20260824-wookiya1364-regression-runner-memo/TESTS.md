# TESTS — 회귀 러너 suite-gate memoization

## Overview

가짜 프로젝트에 세는 관문 스텁을 두고 러너를 돌려, 관문은 한 번만 돌고 계약 자체의
단언은 매번 돌며, 실패는 실패로 재사용되고, --no-memo 는 옛 동작이며, 관문이 없는
블록은 바이트 그대로인지 본다. **이 계약은 자기 테스트 파일만 부른다.**

## Test scenarios

### T1. 통과 관문 1회 실행, 계약 단언은 매번 · T2. 실패 관문 재사용 · T3. --no-memo · T4. 루프·tests/run.sh 단위 · T5. 관문 없는 블록 불변

## How to run

```bash
bash core/tests/test-regression-memo.sh
```

## Pass criteria

- 위 명령 exit 0.
