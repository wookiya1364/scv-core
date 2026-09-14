# Test Plan — run-dry 다이어트 — 문장 고정을 구조 검사로, 남는 고정엔 이유를

## Overview

검사를 줄이면서 동작 검증은 하나도 잃지 않았는지를 숫자로 본다: 스크립트 실행 검사 수 전후
동일, 규약 문장 고정은 상한 이하이고 전부 이유가 붙었으며, 지운 앵커마다 출처가 표에 있다.
새 lint 가 되돌아감을 막는다.

## Test scenarios

### T1. 스크립트 실행 검사는 한 줄도 줄지 않았다

- **Run**: 변경 전후 run-dry.sh 에서 `assert_out_contains` · `assert_file` · 픽스처 루프의 pass/fail 호출 수를 센다(`scv_anchor_extract` 의 종류별 집계).
- **Expected**: 전후 동일(241 + 루프). run-dry 실행 결과 FAIL 0.
- **Pass criterion**: 개수 일치 · exit 0.

### T2. 중복 0 · GUIDANCE 전용 고정 0

- **Run**: `scv_anchor_dups` 와 `scv_anchor_kind` 로 집계.
- **Expected**: 중복 0, kind=guidance 0. 임시 복제에 중복 하나를 넣으면 lint 가 잡는다.
- **Pass criterion**: 0 · 0 · negative ✓.

### T3. 남는 문장 고정마다 why 가 있고, 총수는 상한 이하

- **Run**: `bash core/tests/test-anchor-intent.sh`.
- **Expected**: 규약 문장 고정 ≤ `SCV_ANCHOR_MAX`(120), 각각 바로 위 줄이 `# why:` 로 시작. 임시 복제에서 why 를 하나 지우면 ✖, 상한을 10 으로 낮추면 ✖.
- **Pass criterion**: ✓ · negative 둘 ✖.

### T4. 구조 검사가 실제 결손을 잡는다

- **Run**: 임시 복제의 promote.md 에서 (a) 다크 테마 지시자 삭제 (b) `classDef new` 삭제 (c) GUIDANCE 닫는 표식 삭제 (d) 질문 블록 하나 삭제.
- **Expected**: run-dry 의 해당 구조 검사가 각각 FAIL.
- **Pass criterion**: 4/4 잡음.

### T5. 처리 표가 완전하다

- **Run**: PR 본문의 앵커 처리 표 vs run-dry diff 에서 사라진 `assert_contains` 줄.
- **Expected**: 사라진 앵커 모두 표에 있고, 각 행에 kind · 처리 · 출처(커밋 또는 archive slug) 또는 "출처 미상—유지".
- **Pass criterion**: 누락 0.

### T6. 회귀 — 코어·래퍼

- **Run**: run-dry · 코어 `test-*.sh` 전부 · `tests/test-host-neutral.sh` · 옆 체크아웃 래퍼 `tests/test-core-contract.sh`(있을 때).
- **Expected**: 전부 통과. 래퍼 투영에 `core/tests/lib/anchors.sh` 가 실려 검사가 SKIP 이 아니라 실제로 돈다.
- **Pass criterion**: exit 0 전부.

### T7. 실행 시간

- **Run**: `time bash core/tests/run-dry.sh` 전후.
- **Expected**: 후 ≤ 전 × 1.05.
- **Pass criterion**: 수치 CHANGELOG 에.

## How to run

```bash
bash core/tests/test-anchor-intent.sh && bash core/tests/run-dry.sh && bash tests/test-host-neutral.sh
```

## Pass criteria

- T1~T4 · T6 자동 통과, T5 는 PR 리뷰에서 확인, T7 수치 기록.

## Related Documents

- `core/tests/test-help-budget.sh` — 상한 검사 골격
