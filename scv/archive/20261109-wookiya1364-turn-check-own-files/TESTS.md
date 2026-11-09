# Test Plan — 턴 끝 계획 검사는 이 세션이 고친 파일만 셈

## Overview

턴 끝 검사가 이 세션이 실제로 쓴 파일만 세는지 본다. 다른 세션이 같은 폴더에서 고친 파일로는 막히지 않고, 이 세션이 편집 도구나 셸로 고친 파일은 여전히 막는지 확인한다. 시험은 core/tests/test-turn-plan-check.sh 에 더한다.

## Test scenarios

### T21. 남이 고친 파일만 있으면 통과

- **Setup**: 턴 시작. 이 세션은 그 저장소 파일을 읽기만 함(touch --kind read).
- **Run**: 다른 세션처럼 파일을 직접 고친 뒤 end.
- **Expected**: `TURN_PLAN: pass`
- **Pass criterion**: 막힘 0번

### T22. 편집 도구로 고친 파일은 막힘

- **Setup**: 턴 시작, 계획 없음.
- **Run**: touch --kind write <파일> 뒤 그 파일을 고치고 end.
- **Expected**: `TURN_PLAN: block` 이고 바뀐 파일 줄에 그 파일
- **Pass criterion**: block · 파일 이름 일치

### T23. 셸로 고친 파일은 막힘, 같은 때 남이 고친 파일은 빠짐

- **Setup**: 턴 시작, 계획 없음. 파일 A · B 가 있음.
- **Run**: 남이 B 를 고침 → touch --kind shell → A 를 고침 → end.
- **Expected**: block, 바뀐 파일은 A 만
- **Pass criterion**: TURN_PLAN_FILES 에 A 는 있고 B 는 없음

### T24. 읽기만 한 다른 저장소는 상태에 남지 않음

- **Setup**: 턴 시작. 다른 git 저장소 하나.
- **Run**: touch --kind read <다른 저장소 파일>
- **Expected**: roots 에 다른 저장소가 없음
- **Pass criterion**: roots 줄 수 1 (이 프로젝트만)

### T25. 셸로 커밋한 파일도 내 몫

- **Setup**: 턴 시작, 계획 없음.
- **Run**: touch --kind shell → 파일을 고쳐 커밋 → end.
- **Expected**: block, 바뀐 파일에 그 파일
- **Pass criterion**: block · 파일 이름 일치

### T26. 순수 함수

- **Run**: `scv_tc_tool_kind` · `scv_tc_abs_paths` · `scv_tc_mine_only` 에 예시 값을 넣음
- **Expected**: 명령 있음 → shell, 경로 + 내용 → write, 경로만 → read · 절대 경로 이음 · 교집합만 남음
- **Pass criterion**: 출력이 기대값과 같음

### T1–T20b (기존)

- **Expected**: 새 방식(쓰기를 touch 로 알림)에 맞춘 뒤 모두 그대로 통과

## How to run

```bash
bash core/tests/test-turn-plan-check.sh
```

## Pass criteria

- T1–T26 모두 통과 (bash 5 · bash 3.2)
- 전체 core 시험 통과 (4개씩)
