# Test Plan — 후속 다섯 — 문구 앵커, 경계 계약 한 곳, 재실행 시간 초과 안내

## Overview

세 변경을 각각 고정한다. 문구 앵커(3)는 가드 검사가 여섯 앵커를 여전히 그 줄로 잡고, 문구가 사라지거나 두 줄에 나타나면
붉어지는지로. 경계 계약(4)은 계약 문서의 세 요소와 세 프로토콜의 포인터, 옛 문장 0건, 검사 (b) 기준선 0건으로. 재실행
메시지(5)는 시간 초과 픽스처의 stderr 로. 마지막으로 전체 검사와 릴리스 세 곳.

## Test scenarios

### T1. 3 — 문구 앵커: 여섯 앵커가 같은 줄을 가리키고, 어긋남을 잡는다

- **Setup**: `core/contracts/guard.md` `guard:exceptions` 블록(형식 `path:"문구" — reason` 6줄), `tests/test-guard-consistency.sh`.
- **Run**: `bash tests/test-guard-consistency.sh` — [2] 위반 0, [3] 앵커 6 모두 일치. 그다음 사본에서 (i) 앵커 문구 하나를 지우면 [3] 이
  "no longer there", (ii) 같은 문구를 다른 줄에 하나 더 넣으면 [3] 이 "ambiguous" 로 붉어지는지(검사 파일 안의 자가검사 또는 임시 사본).
  (iii) promote.md 앞쪽에 빈 줄 3개를 넣은 사본에서도 [2][3] 통과(줄 번호 무관).
- **Expected**: 본검사 4/4, (i)(ii) 붉음, (iii) 초록.
- **Pass criterion**: `bash tests/run.sh` 통과 + (i)(ii)(iii) 결과 일치.

### T2. 4 — 경계 계약 한 곳, 포인터 셋, 기준선 0

- **Setup**: `core/contracts/boundaries.md`(신설), `core/protocols/{codegen,work,regression}.md`, `core/tests/run-dry.sh`,
  `core/tests/fixtures/rule-constitution/{duplicate-allowlist,duplicate-baseline}.txt`.
- **Run**: 계약 문서에 세 경계(범위 밖 파일 · 보관 TESTS 본문 + 폐기 3필드 · ARCHIVED_AT) grep. 세 프로토콜에 `contracts/boundaries.md`
  참조 1개 이상. 옛 문장 "Never delete or move files outside the scope" · "Never modify the body of an archived TESTS.md" 는 프로토콜에서
  0건(계약에만). codegen 의 "the test is the spec" 문장은 그대로 1건. run-dry 통과(1252 는 포인터 검사로). rule-constitution 본검사에서
  기준선 0건·허용목록 7건, 자가검사 통과.
- **Expected**: 참조 3/3, 옛 문장 0건, run-dry 초록, (b) "후보 N건 (허용 N건 제외), 기준선 이하" 에 기준선 파일은 주석만.
- **Pass criterion**: `bash core/tests/run-dry.sh && bash core/tests/test-rule-constitution.sh && bash core/tests/test-rule-constitution.sh --self-test` 통과 + grep 일치.

### T3. 5 — 재실행 시간 초과를 이름 붙여 알린다

- **Setup**: `core/scripts/pr-helper.sh`, `core/tests/test-attachments-scope.sh` T2 에 픽스처: How-to-run 이 `sleep 5` 인 보관 슬러그,
  `SCV_ATTACHMENTS_RERUN_TIMEOUT=1`, `--no-create`(PR 생성 없음) 또는 dry-run 이 재실행을 막으므로 실제 재실행 경로를 타는 호출.
- **Run**: pr-helper stderr 에 `re-run timed out after 1s` 와 `SCV_ATTACHMENTS_RERUN_TIMEOUT` 가 있는지. 일반 실패(exit 2 인 명령)는
  `re-run exited 2`. `timeout` 명령이 없는 호스트는 그 항목을 건너뛴다(검사가 표시). 측정 기록: 이 저장소 계획(open-items-followup)의
  실행 명령 단독 소요 시간 — 600초 초과 여부.
- **Expected**: 시간 초과 문구 1건, 종료 코드 문구 1건, 두 경우 모두 pr-helper 는 계속 진행(exit 0).
- **Pass criterion**: `bash core/tests/test-attachments-scope.sh` 통과.

### T4. 전체 검사

- **Setup**: 위 전부.
- **Run**: How to run.
- **Expected**: 로컬(맥) 초록, PR CI(ubuntu·macos) 초록.
- **Pass criterion**: How to run exit 0.

### T5. 릴리스 세 곳

- **Setup**: PR 병합된 develop. 래퍼 두 체크아웃 최신.
- **Run**: `gh workflow run promote.yml` → 래퍼 핀 PR 병합 → 릴리스 PR(코덱스 노트는 정정된 갱신 명령) → promote.
- **Expected**: 코어 v0.57.0 자산 2개, 래퍼 v0.57.0 · v0.57.0-codex.1 "Latest".
- **Pass criterion**: `gh release view` 세 곳 일치.

## How to run

```bash
bash tests/run.sh && bash core/tests/run-dry.sh && bash core/tests/test-rule-constitution.sh && bash core/tests/test-rule-constitution.sh --self-test && bash core/tests/test-attachments-scope.sh && bash core/tests/test-guard.sh && bash core/tests/test-purity.sh
```

## Pass criteria

- T1~T5 전부 통과. How to run 마지막 명령까지 exit 0.
- `core/tests/test-*.sh` 전부 초록(로컬) + PR CI 초록.
- 릴리스 세 곳 게시.

## Related Documents

- `scv/archive/20260921-wookiya1364-open-items-followup/TESTS.md` — 허용목록·계약 검사의 원형
