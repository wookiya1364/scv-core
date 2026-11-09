# Test Plan — 진행 기록이 진행 중 단계를 '끝'으로 남기지 않게

## Overview

진행 기록 기본 상태, 막힘 안내문, 단계 끼우기 뒤 진행 줄 번호를 본다. 시험은 core/tests/test-turn-plan-check.sh 에 더한다.

## Test scenarios

### T27. --state 없는 progress 는 '시작'

- **Setup**: 진행 중 계획 p1
- **Run**: `plan-link.sh progress p1 --step 2 --note 측정 중`
- **Expected**: 이력에 `2단계 시작: 측정 중`, `2단계 끝` 없음
- **Pass criterion**: grep 일치

### T28. --state done 은 그대로 '끝'

- **Run**: `progress p1 --step 2 --state done --note 다 함`
- **Expected**: `2단계 끝: 다 함`

### T29. 막힘 안내문이 끝/진행을 나눠 보여 줌

- **Run**: `scv_tc_block_msg in-plan a 3 /p/plan-link.sh`
- **Expected**: 글에 `--state doing` 과 `done` 이 함께 있고 '끝났을 때만' 문구가 있음

### T30. 단계를 끼우면 뒤 진행 줄 번호가 밀림

- **Setup**: 단계 1~3, 이력에 `1단계 끝`, `2단계 끝`, `3단계 시작`, `추가 — 1단계 뒤` 줄
- **Run**: `append p1 --after 1 --step 새것 --why x`
- **Expected**: 이력의 진행 줄이 `1단계 끝` · `3단계 끝` · `4단계 시작`, 다른 이력 줄 글은 그대로, 단계 목록 2번이 새것
- **Pass criterion**: 세 줄 일치 · 추가 줄 그대로

### T31. 순수 함수 예

- **Run**: `scv_plan_shift_progress` 에 진행 줄 `3a단계 막힘` 과 after 2
- **Expected**: `4a단계 막힘`; after 이하 번호는 그대로; 진행 줄이 없는 글은 그대로

## How to run

```bash
bash core/tests/test-turn-plan-check.sh && /bin/bash core/tests/test-turn-plan-check.sh
```

## Pass criteria

- T27–T31 통과(bash 5 · 3.2), 기존 시험 통과, 전체 시험 실패 0
