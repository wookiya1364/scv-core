# TESTS — 회귀 계약 보수 2

## Overview

옛 6건이 검증하던 것을 실제 파일 이름으로 다시 적는다. 전부 트리 내용만으로 판정한다.

## Test scenarios

### T1. 설정(0.32.0 settings-json 계승) — test-settings.sh 전량
### T2. 템플릿 지문(0.32.0 template-refresh 계승) — test-template-digest.sh + test-autosync.sh
### T3. 쉬운 말(0821 두 계약 계승) — run-dry [15p]/[15q] 앵커 + test-journal
### T4. 첨부 범위(0821 계승) — test-attachments-scope.sh
### T5. obsolete 표시 — 옛 6건 frontmatter 3필드, 본문 불변(ARCHIVED_AT 존재)
### T6. 스위트 — tests/run.sh · run-dry

## How to run

```bash
bash -euo pipefail -c '
fail() { echo "FAIL: $1"; exit 1; }
bash core/tests/test-settings.sh >/dev/null || fail "T1 test-settings"
bash core/tests/test-template-digest.sh >/dev/null || fail "T2 test-template-digest"
bash core/tests/test-autosync.sh >/dev/null || fail "T2 test-autosync"
bash core/tests/test-journal.sh >/dev/null || fail "T3 test-journal"
for a in "SCV_PLAIN_LANGUAGE=off" "1–2 sentences" "one example" "No code values before the user asks" "SCV_PLAIN_MAX_SENTENCES"; do
  for f in $(grep -l "^## Language preference" core/protocols/*.md); do grep -qF -- "$a" "$f" || fail "T3 앵커 없음: [$a] in $f"; done
done
bash core/tests/test-attachments-scope.sh >/dev/null || fail "T4 test-attachments-scope"
for s in 20260821-wookiya1364-plain-answers-enforcement 20260821-wookiya1364-plain-sentence-cap 20260821-wookiya1364-slug-scoped-attachments 20260818-wookiya1364-env-example-autorefresh 20260823-wookiya1364-settings-json 20260823-wookiya1364-template-refresh; do
  p=scv/archive/$s/PLAN.md
  grep -q "^status: obsolete$" "$p" || fail "T5 $s status"
  grep -q "^obsoleted_at: " "$p" || fail "T5 $s obsoleted_at"
  grep -q "^obsoleted_by: 20260824-wookiya1364-regression-contract-repair-2$" "$p" || fail "T5 $s obsoleted_by"
  [ -f scv/archive/$s/TESTS.md ] && [ -f scv/archive/$s/ARCHIVED_AT.md ] || fail "T5 $s 본문 파일"
done
echo "OK [T1-T5]"
bash tests/run.sh >/dev/null || fail "T6 tests/run.sh"
bash core/tests/run-dry.sh >/dev/null || fail "T6 run-dry"
echo "ALL CONTRACTS OK"
'
```

## Pass criteria

- 위 블록 exit 0, 누적 회귀 FAILED_SLUGS: 0.
