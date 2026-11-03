# Test Plan — 지시 충돌 12곳 정리 — 0.77.0 전체 재검사

## Overview

고친 12곳이 한쪽 규칙만 남겼는지(옛 문구 0곳)와 매 턴 줄 크기를 문구 검사로 확인함. 0.77.0 에서는 T1–T8 모두 실패, 수정본에서 모두 통과(확인).

## Test scenarios

### T1. '예시 하나' 요구 0곳
- **Setup**: 저장소 그대로
- **Run**: `core/protocols/*.md` 에서 "one example from the" 를 찾음
- **Expected**: 0곳
- **Pass criterion**: `ok T1` 출력

### T2. 옛 답 모양 문구 0곳
- **Setup**: 저장소 그대로
- **Run**: SCV.md 틀 · README(en · ko · ja)에서 옛 문구를 찾음
- **Expected**: 0곳
- **Pass criterion**: `ok T2` 출력

### T3. 매 턴 선택 창 줄
- **Setup**: 도구 이름 PickTool(가짜 이름 — 코어는 호스트 이름을 쓰지 않음)
- **Run**: `scv_choice_line PickTool`
- **Expected**: "Summary box: recap only." · "work done, state it unasked." 포함, 400B 이하
- **Pass criterion**: `ok T3` 출력

### T4. 규칙 10항 보강
- **Setup**: 저장소 그대로
- **Run**: choices.md 에서 "also when the host itself says to ask in" 을 찾음
- **Expected**: 있음
- **Pass criterion**: `ok T4` 출력

### T5. GRAFT 줄 위치
- **Setup**: 저장소 그대로
- **Run**: work.md · promote.md 에서 "right under the rewritten-request quote" 를 찾음
- **Expected**: 2/2
- **Pass criterion**: `ok T5` 출력

### T6. 번호 목록 규칙
- **Setup**: 저장소 그대로
- **Run**: work.md · report.md 에 "numbers only on" 이 있고 "numbered items" 가 없는지 봄
- **Expected**: 2/2
- **Pass criterion**: `ok T6` 출력

### T7. 질문 정리
- **Setup**: 저장소 그대로
- **Run**: codegen 추천 표시 2곳, workspace 'plain questions' · '보입니다' 없음, sync 드리프트 질문 없음, install-deps "don't auto-run" 없음
- **Expected**: 4/4
- **Pass criterion**: `ok T7` 출력

### T8. 안내 문구 일치
- **Setup**: 저장소 그대로
- **Run**: help.sh 출력 문구 "This directory is not hydrated yet." 가 full.md 에 있고 옛 문구가 없는지 봄
- **Expected**: 일치
- **Pass criterion**: `ok T8` 출력

### T9. 대체한 계획(회귀 계약 보수 2)의 시험 6개 계승
- **Setup**: 저장소 그대로
- **Run**: 그 계획의 실행 블록 그대로, '예시 하나' 앵커만 '굵은 주제'로
- **Expected**: `ALL CONTRACTS OK`
- **Pass criterion**: exit 0

## How to run

```bash
bash core/tests/test-instruction-conflicts.sh && bash -euo pipefail -c '
fail() { echo "FAIL: $1"; exit 1; }
bash core/tests/test-settings.sh >/dev/null || fail "T9 test-settings"
bash core/tests/test-template-digest.sh >/dev/null || fail "T9 test-template-digest"
bash core/tests/test-autosync.sh >/dev/null || fail "T9 test-autosync"
bash core/tests/test-journal.sh >/dev/null || fail "T9 test-journal"
for a in "SCV_PLAIN_LANGUAGE=off" "1–2 sentences" "bold topic" "No code values before the user asks" "SCV_PLAIN_MAX_SENTENCES"; do
  for f in $(grep -l "^## Language preference" core/protocols/*.md); do grep -qF -- "$a" "$f" || fail "T9 앵커 없음: [$a] in $f"; done
done
bash core/tests/test-attachments-scope.sh >/dev/null || fail "T9 test-attachments-scope"
for s in 20260821-wookiya1364-plain-answers-enforcement 20260821-wookiya1364-plain-sentence-cap 20260821-wookiya1364-slug-scoped-attachments 20260818-wookiya1364-env-example-autorefresh 20260823-wookiya1364-settings-json 20260823-wookiya1364-template-refresh; do
  p=scv/archive/$s/PLAN.md
  grep -q "^status: obsolete$" "$p" || fail "T9 $s status"
  grep -q "^obsoleted_by: 20260824-wookiya1364-regression-contract-repair-2$" "$p" || fail "T9 $s obsoleted_by"
done
bash tests/run.sh >/dev/null || fail "T9 tests/run.sh"
echo "ALL CONTRACTS OK"
' && bash core/tests/run-dry.sh >/dev/null && bash core/tests/test-help-budget.sh >/dev/null && bash core/tests/test-choice-questions.sh >/dev/null
```

## Pass criteria

- T1–T9 통과, run-dry · 크기 예산 · 선택 창 시험 통과
