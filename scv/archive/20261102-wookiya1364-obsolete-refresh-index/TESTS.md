# Test Plan — 폐기 표시를 한 곳으로 — 표시하면 보관 목록도 바로

## Overview

폐기 표시를 하면 보관 목록에 곧바로 반영되는지, 세 칸 밖은 그대로인지, 두 번 표시하지 않는지, 규약 두 곳이 같은 스크립트를 부르는지 본다.

## Test scenarios

### T1. 세 칸만 바뀐다

- **Setup**: 앞머리에 `status: done` 과 다른 칸 3개, 본문이 있는 계획서.
- **Run**: 순수함수에 날짜 `2026-11-02` · 대체한 계획 `new-x` 를 넣는다.
- **Expected**: `status: obsolete`, `obsoleted_at: 2026-11-02`, `obsoleted_by: new-x` 가 생기고 나머지 줄은 바이트까지 같다.
- **Pass criterion**: 바뀐 줄 수 3(diff 기준), 본문 diff 0.

### T2. 이미 폐기면 그대로

- **Setup**: `status: obsolete`, `obsoleted_at: 2026-10-01` 인 계획서.
- **Pass criterion**: 출력이 입력과 바이트까지 같다(`obsoleted_at: 2026-10-01` 유지).

### T3. 스크립트는 목록을 바로 새로 만든다

- **Setup**: 보관 폴더 두 계획, 목록에서 둘 다 `status: done`.
- **Run**: `obsolete-mark.sh <첫 계획> new-x 2026-11-02`
- **Pass criterion**: 목록에서 첫 계획 `status: obsolete` · `obsoleted_by: new-x`, 둘째는 `status: done`, 종료 코드 0.

### T4. 규약 두 곳이 스크립트를 부른다

- **Pass criterion**: work.md Step 9c 와 regression.md 폐기 절차에 `obsolete-mark.sh` 가 각각 1번 이상, work 9c 의 손으로 고치는 줄(`status: done` → `status: obsolete` Edit) 은 없다. 묻는 지점 수 promote 11 · work 10 그대로.

### T5. 코어 시험

- **Pass criterion**: `bash tests/run.sh` 실패 0.

## How to run

```bash
bash core/tests/test-obsolete-mark.sh && bash tests/run.sh
```

## Pass criteria

- 위 명령 종료 코드 0. 대시보드가 단계마다 바뀌는지는 사용자 확인.
