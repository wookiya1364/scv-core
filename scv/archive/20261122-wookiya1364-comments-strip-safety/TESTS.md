# Test Plan — 주석 옮기기 안전

## Overview

셸 읽기가 겹친 따옴표에서 바르게 주석을 찾는지, 지운 뒤 문법이 깨지는 파일은 건드리지 않는지, 사전 쓰기가 실패하면 코드가 원래대로 돌아가는지 본다.

## Test scenarios

### T9. 겹친 따옴표 · 치환 안의 `#`
- **Run**: `x="$(a | tr -d '"[:space:]')"` 뒤에 `echo '(### b)'`, `"${v:-"q"}" # c`, `$( … # in …)` 를 지움.
- **Pass criterion**: 문자열 안 `###` 는 남고, 진짜 주석(`# c`, `# in`)만 지워짐. 지운 글이 `bash -n` 통과.

### T10. 지운 뒤 문법이 깨지면 그 파일은 그대로
- **Run**: 읽기를 속이는 파일(지우면 깨지게 만든 예)을 넣고 옮기기.
- **Pass criterion**: 그 파일은 바이트까지 그대로, 보고 줄에 `skipped=1`.

### T11. 사전 쓰기 실패 시 복원
- **Run**: 사전 쓰기를 실패하게 한 뒤 옮기기. 대상 파일 하나에는 커밋 안 한 편집이 있음.
- **Pass criterion**: 종료 코드 1, 코드 파일 전부 옮기기 전과 같음(커밋 안 한 편집 포함), SOURCE 표시 없음.

### T12. 예시 속 표식 · 칸 이름 · 잃는 항목
- **Run**: 예시에 `@pure g` · `종류: 뭐` 가 든 함수를 옮김. 뽑은 항목이 비게 만든 뒤 옮김.
- **Pass criterion**: 가짜 항목 g 없음, 원래 종류 그대로. 뒤 경우는 exit 1, 코드 그대로, 빠진 함수 이름을 알림.

## How to run

```bash
bash core/tests/test-comments-to-catalog.sh
```

사본 전체 확인(손으로, 결과를 WRAPUP 에 적음): SCV 코어를 임시 폴더에 복제 → `comments-migrate.sh run --root .` → 바뀐 sh 마다 `bash -n`, py 마다 `python3 -m py_compile`.

관련 시험: `core/tests/test-rules-once.sh` · `core/tests/test-lean-loop.sh` · `tests/test-actions.sh` · 순수 · 사전 검사(`tools/` 의 purity · catalog 검사).

## Pass criteria

- T1–T12 모두 ok, 종료 코드 0 (mac · linux).
- 사본 전체: 깨진 sh 0, 깨진 py 0, 옮기기 전 사전 항목이 옮긴 뒤 모두 있음.
