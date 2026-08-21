# Test Plan — 회귀 러너의 경로 표시 누수

## Overview

러너가 자기 경로 표시를 시나리오에 흘리지 않는지, 사용자 env 는 그대로 전달되는지,
어제 보관한 실계약이 러너 안에서 통과하는지를 확인한다.

## Test scenarios

### T1. 시나리오 환경에 러너의 경로 표시 5개가 없다 (test-regression-env T5)
- **Pass criterion**: `test-regression-env.sh` 전량 통과 (신규 T5 포함)

### T2. 실계약이 러너 안에서 통과한다
- **Run**: `regression.sh --only 20260821-wookiya1364-plain-answers-enforcement --quiet`
- **Pass criterion**: `FAILED_SLUGS: 0`

## How to run

```bash
bash -euo pipefail -c '
fail() { echo "FAIL: $1"; exit 1; }
bash core/tests/test-regression-env.sh >/dev/null || fail "T1 test-regression-env"
grep -qF -- "-u SCV_DIR" core/scripts/regression.sh || fail "T1 러너가 SCV_DIR 를 빼지 않음"
out=$(bash core/scripts/regression.sh --only 20260821-wookiya1364-plain-answers-enforcement --quiet 2>&1 || true)
printf "%s\n" "$out" | grep -q "FAILED_SLUGS: 0" || fail "T2 실계약이 러너 안에서 실패: $(printf "%s\n" "$out" | grep -E "FAIL|✗" | head -3)"
echo "ALL GATES OK"
'
```

## Pass criteria

- 위 블록 exit 0, 누적 회귀 FAILED_SLUGS: 0.
