# Test Plan — help 규약은 세션당 한 번만 — 매 턴은 기록 계약만, 진단은 변동 시에만 전체

## Overview

"언제 다시 읽는가"가 훅 상태로만 정해지는지, 실패하면 이전 동작으로 떨어지는지, 매 턴 스택이
절반이 되는지를 본다. 훅은 stdin JSON 을 주면 그대로 재현되므로 세션 시뮬레이션이 셸로 된다.

## Test scenarios

### T1. 순수부 — 상태 파싱·되돌림·진단 판정·렌더

- **Run**: `help-state.sh` 의 함수 넷을 문자열로 호출.
- **Expected**: 깨진 JSON → 기본값(session="", protocol=0, diag=""). 세션 다름 → protocol=0 · diag="".
  사건 reset → protocol=0(세션 유지). 진단 해시 같음 → brief + 한 줄에 `diag_at`; 다름 → full + 새
  해시. render→parse 왕복이 항등. `check-purity.sh` 통과, 함수마다 @pure.
- **Pass criterion**: 전부 ✓.

### T2. 새 세션 → load, 같은 세션 → loaded, mark 없이는 안 바뀜

- **Run**: 임시 프로젝트에서 훅에 `{"session_id":"A","prompt":"x"}` → `help.sh --with-context`;
  `help-state.sh mark`; 다시 `--with-context`; 훅에 session B → `--with-context`.
- **Expected**: `PROTOCOL: load` → (mark) → `PROTOCOL: loaded` → (B) `PROTOCOL: load`. mark 를
  부르지 않으면 두 번째도 `load`.
- **Pass criterion**: 순서대로 4개 출력 일치.

### T3. 압축·/clear·재개 → 다시 load

- **Run**: 세션 A 로 mark 한 뒤 되찾기 훅에 `{"source":"compact"}` · `clear` · `resume` 각각.
- **Expected**: 각 사건 뒤 `--with-context` 가 `load`; `session` 필드는 A 그대로.
- **Pass criterion**: 3/3.

### T4. 진단 — 첫 턴 전체, 변동 없으면 한 줄, 바뀌면 전체

- **Run**: 같은 세션으로 훅 3번: 1) 초기 2) 그대로 3) `scv/raw/` 에 파일 하나 추가 뒤.
- **Expected**: 1) `Current project diagnosis` 전체 2) 한 줄(`진단 변동 없음` + 시각) 이고 전체 없음
  3) 전체 다시. 훅 출력에 `SCV: 이 턴의 첫 행동` 지시는 세 번 다 있다.
- **Pass criterion**: 3/3. `test-force-help` 의 기존 단언(첫 턴 전체)은 그대로 통과.

### T5. 실패는 이전 동작으로

- **Run**: 표식 파일을 디렉터리로 만들어 쓰기 불가 · 깨진 내용 · `session_id` 없는 stdin.
- **Expected**: 훅 exit 0, `--with-context` 는 `load`, 진단은 전체. 라우팅 지시는 그대로.
- **Pass criterion**: 3/3.

### T6. 라우터 크기·매 턴 스택·세션 누적

- **Run**: `test-help-budget.sh`(1단계) 를 갱신해 라우터 ≤ 4,000B, 매 턴 스택(훅 brief 턴 + 라우터 +
  `--with-context`) ≤ 9,000B. 10턴 시뮬레이션(같은 세션, 5턴째 compact) 에서 `PROTOCOL: load` 횟수.
- **Expected**: 상한 ✓, load 횟수 2.
- **Pass criterion**: ✓ · 2.

### T7. 앵커 재조준 — 기존 검사 전부 통과

- **Run**: test-help-shape · test-delegate-effort · test-force-help · test-guidance · run-dry ·
  test-profile-and-export · test-host-runtime-materialization · verify-core.
- **Expected**: 전부 통과. run-dry [15p] 의 PLAIN_N ≥ 13 유지(라우터에 언어 절·쉬운 말 절 존재).
  재조준한 단언 목록이 PR 본문에 있다.
- **Pass criterion**: exit 0 전부.

### T8. 실사용 관찰 (수동, 릴리스 뒤)

- **Run**: 세 세션에서 (a) 첫 턴에 full.md Read 1회 (b) /clear 뒤 1회 (c) 진단 변동 없는 턴의 훅
  출력이 한 줄 (d) 짧은 턴 이어붙이기·archive 검색·hydrate 제안 동작 동일.
- **Pass criterion**: (a)~(d) 관찰, 매 턴 스택 실측을 CHANGELOG 에.

## How to run

```bash
bash core/tests/test-help-load-once.sh && bash core/tests/test-help-budget.sh && bash core/tests/test-force-help.sh && bash core/tests/test-help-shape.sh
```

## Pass criteria

- T1~T7 자동 통과, T8 관찰·기록.

## Related Documents

- `scv/promote/20260914-wookiya1364-help-body-diet/TESTS.md` — 1단계 검사(상한 검사의 원형)
