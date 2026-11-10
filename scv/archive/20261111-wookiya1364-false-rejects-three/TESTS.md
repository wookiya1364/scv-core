# Test Plan — 잘못된 거절 셋 고치기

## Overview

막지 말아야 할 세 가지가 통과하는지, 그리고 막아야 할 것은 여전히 막히는지를 함께 본다.
모든 시나리오는 임시 폴더에서 돌고, 기록 폴더 연결은 임시 저장소 둘로 만든다.

## Test scenarios

### T1. 연결된 기록 폴더 — 원자료 파일만 쓴 턴은 통과

- **Setup**: 임시 git 저장소 A 와 B. A 의 `scv/raw` · `scv/journal` 을 B 안 폴더로 연결.
- **Run**: 시작 사진 → `scv/raw/x.md` 와 `scv/journal/.state` 를 씀 → 턴 끝 판정.
- **Expected**: 일로 센 파일 0개, 막지 않음.
- **Pass criterion**: 판정 출력에 막는 글 0건, 종료 코드 0. (고치기 전에는 이 시험이 실패해야 한다 — 재현)

### T2. 연결된 기록 폴더 — 코드 파일도 바꾸면 막힘

- **Setup**: T1 과 같음.
- **Run**: `scv/raw/x.md` 와 `src/a.sh` 를 씀 → 턴 끝 판정.
- **Expected**: 일로 센 파일 1개(`src/a.sh`), 계획 기록이 없으므로 막음.
- **Pass criterion**: 막는 글에 "파일 1개".

### T3. 보통 저장소 — 결과 그대로

- **Setup**: 연결 없는 임시 저장소.
- **Run**: `core/tests/test-turn-plan-check.sh` 전체.
- **Expected**: 고치기 전과 같은 통과 수.
- **Pass criterion**: 종료 코드 0, 통과 수가 develop 과 같음.

### T4. 거름망 — 받은 실제 경로 아래만 뺌

- **Setup**: 없음(순수 함수).
- **Run**: `scv_tc_filter $'/b/rec/raw/x.md\n/b/other/y.sh\nsrc/a.sh' "<기록 폴더 실제 경로>"`.
- **Expected**: `/b/other/y.sh` 와 `src/a.sh` 는 남고 `/b/rec/raw/x.md` 만 빠짐.
- **Pass criterion**: 출력이 정확히 두 줄.

### T5. 실제로 거절됐던 메모 4건은 통과

- **Setup**: 계획 `20261110-wookiya1364-rewrite-by-guide-only` 의 '하지 않음' 항목 7개와, 그 세션에서 거절된 메모 4건 — 세션 기록에 거절 줄이 남은 3건(낱말 문서 · 모양 · 다시)과 같은 일을 적은 메모 1건(안내문 · 문서).
- **Run**: 메모마다 `scv_tc_nongoal_hits`.
- **Expected**: 충돌 0건.
- **Pass criterion**: 네 번 모두 빈 출력(통과 4/4). 고치기 전 코드에서는 0/4.
- **고친 이유(2026-11-11)**: 계획을 쓸 때 "5건"이라고 적었으나 세션 기록에서 확인되는 것은 3건(+1)이었다. 확인되는 것만 시험한다.

### T6. 문서에 적힌 진짜 충돌은 그대로 잡힘

- **Setup**: '하지 않음' 항목 "환불 기능", 메모 "환불 버튼 추가".
- **Run**: `scv_tc_nongoal_hits`.
- **Expected**: 충돌 1줄.
- **Pass criterion**: 출력이 `충돌 · 하지 않기로 함: 환불 기능 ↔ 적으려는 글: 환불 버튼 추가`.

### T7. 절반 경계

- **Setup**: 항목 낱말 4개.
- **Run**: 메모에 그중 2개 / 1개가 들어 있는 두 경우.
- **Expected**: 2개 → 충돌, 1개 → 통과. `scv_tc_overlap_count` 는 "2 4" / "1 4".
- **Pass criterion**: 두 출력이 기대와 같음.

### T8. plan-link progress · append 의 종료 코드

- **Setup**: 임시 계획 폴더(T5 · T6 의 항목을 가진 PLAN.md).
- **Run**: T5 의 메모로 `progress`, T6 의 글로 `progress` 와 `append`.
- **Expected**: T5 메모 → 종료 코드 0 이고 이력에 진행 줄 1개. T6 글 → 종료 코드 3 이고 파일은 안 바뀜.
- **Pass criterion**: 종료 코드와 파일 변화가 기대와 같음.

### T9. 원자료 뿌리가 연결 — 옮기기 성공

- **Setup**: `scv/raw` 가 다른 폴더로 연결된 임시 저장소, 원자료 파일 1개.
- **Run**: `readpath.sh consume <slug> scv/raw/a.md`.
- **Expected**: `MOVED` 줄 1개, 파일이 `scv/raw/stale/a.md` 에 있고 내용이 같음, `scv/readpath.json` 에 slug 가 적힘.
- **Pass criterion**: 종료 코드 0, 세 조건 모두 참.

### T10. 뿌리 아래 하위 폴더가 연결 — 거절 그대로

- **Setup**: `scv/raw/sub` 가 밖을 가리키는 연결.
- **Run**: `readpath.sh consume <slug> scv/raw/sub/a.md`.
- **Expected**: 거절, 아무것도 안 옮김.
- **Pass criterion**: 종료 코드 1, stderr 에 "refusing symlinked path component".

### T11. 연결된 뿌리 — 쓰지 않은 원자료 목록에 보임

- **Setup**: T9 와 같음.
- **Run**: `readpath.sh unused`.
- **Expected**: `scv/raw/a.md` 가 목록에 있음.
- **Pass criterion**: 출력에 그 경로 1줄. (고치기 전에는 빈 출력 — 2026-11-11 확인)

### T12. 보통 원자료 폴더 — 결과 그대로

- **Setup**: 연결 없는 임시 저장소.
- **Run**: `core/tests/test-readpath-lifecycle.sh` 전체.
- **Expected**: 고치기 전과 같은 통과 수.
- **Pass criterion**: 종료 코드 0.

### T13. 순수 함수 목록과 문서

- **Setup**: 없음.
- **Run**: 순수 함수 목록 시험, 계약 · 문서 시험.
- **Expected**: 새 함수 `scv_tc_overlap_count` 가 목록에 있고 예가 실제 출력과 같음.
- **Pass criterion**: 종료 코드 0.

### T14. 전체 시험 — bash 3.2 와 bash 5

- **Setup**: 없음.
- **Run**: 전체 시험을 4개씩 나눠 두 bash 로.
- **Expected**: develop 에서 통과하던 시험이 모두 통과.
- **Pass criterion**: 이 변경 때문에 새로 실패한 시험 0개. (bash 3.2 의 기존 실패 셋은 계획 ②의 몫)

## How to run

```bash
bash core/tests/test-false-rejects.sh && bash core/tests/test-turn-plan-check.sh && bash core/tests/test-plan-link.sh && bash core/tests/test-readpath-lifecycle.sh
```

## Pass criteria

- T1–T14 통과. T1 · T11 은 고치기 전 실패를 먼저 확인한다.
- PR 검사(맥 · 리눅스) 통과.

## Related Documents

- [`PLAN.md`](./PLAN.md)
