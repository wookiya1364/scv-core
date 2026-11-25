# Test Plan — dreams 걷어내기

## Overview

dreams 가 본체와 대시보드에서 빠졌는지, 그러면서 다른 액션과 매 턴 훅이 그대로 도는지 본다.

## Test scenarios

### T1. 본체에 dreams 언급이 없다

- **Setup**: 지운 뒤의 저장소.
- **Run**: core · docs · README 에서 dreams · 드림을 찾는다.
- **Expected**: 0건.
- **Pass criterion**: 검색 결과 줄 수 0.

### T2. 액션 목록이 22개다

- **Setup**: 지운 뒤의 저장소.
- **Run**: 액션 목록과 가드의 액션 이름 목록을 읽는다.
- **Expected**: dreams 가 없고 수가 22.
- **Pass criterion**: 액션 수를 보는 기존 시험이 22 로 통과.

### T3. 매 턴 훅이 dreams 를 띄우지 않는다

- **Setup**: 새 시험 프로젝트.
- **Run**: 매 턴 훅을 돌린 뒤 프로젝트에서 생긴 파일을 본다.
- **Expected**: scv/dreams 폴더가 생기지 않는다.
- **Pass criterion**: 폴더 없음, 훅 종료 코드 0.

### T4. 세션 시작 훅에 dreams 안내가 없다

- **Setup**: 새 시험 프로젝트.
- **Run**: 세션 시작 훅을 돌린다.
- **Expected**: 출력에 dreams · 드림이 없다.
- **Pass criterion**: 검색 0건, 기존 세션 시작 시험 통과.

### T5. 대시보드에 드림 칸이 없다

- **Setup**: 지운 뒤의 대시보드.
- **Run**: 모드의 시험 전체, 그리고 창 화면.
- **Expected**: 드림 칸과 그 버튼이 없다.
- **Pass criterion**: 모드 시험 통과, 드림 칸이 없는 화면 사진.

### T6. 이 프로젝트의 보고서 파일이 없다

- **Setup**: 사용자가 목록을 보고 확인한 뒤.
- **Run**: scv/dreams 의 파일을 센다.
- **Expected**: 0개.
- **Pass criterion**: 파일 수 0.

## How to run

```bash
bash core/tests/test-retired-coach.sh
```

## Pass criteria

- T1–T4 통과(맥 기본 셸 · 새 셸), 관련 시험(세션 시작 · 훅 · 액션 수 · 호스트 이름 · 템플릿 지문 · 순수성) 통과, 깃허브 검사 통과.
- T5 의 화면 사진과 T6 의 파일 수가 기록돼 있다.

## Related Documents
