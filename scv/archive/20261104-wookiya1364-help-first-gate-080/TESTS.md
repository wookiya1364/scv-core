# Test Plan — 첫 도구를 help 로 고정

## Overview

T1–T7 은 코어 시험 `core/tests/test-help-first.sh` 로, T8 은 실제 재현으로 본다.

## Test scenarios

### T1. help 전 도구 거절
- **Setup**: 사람 턴 표가 있는 임시 프로젝트, help 표 없음
- **Run**: 가드 gate-any 에 쉘 · 쓰기 · 기타 도구 입력
- **Expected**: 거절, 이유에 help 를 부를 명령
- **Pass criterion**: deny 출력

### T2. help 를 부르면 통과
- **Setup**: T1 상태에서 help 스킬 시작(mint) 또는 help.sh 를 부르는 쉘
- **Run**: 다시 gate-any
- **Expected**: 통과. help.sh 를 부르는 쉘 자체도 통과
- **Pass criterion**: 출력 없음

### T3. 다음 턴은 다시 필요
- **Setup**: 새 사람 턴 표
- **Run**: gate-any
- **Expected**: 거절
- **Pass criterion**: deny

### T4. 다른 SCV 액션이 실린 턴 · 통과 도구 목록
- **Setup**: 사용자가 친 SCV 명령(mint) / 프로필 통과 목록의 도구
- **Run**: gate-any
- **Expected**: 통과
- **Pass criterion**: 출력 없음

### T5. 제외
- **Setup**: 자동 알림 턴 / 하위 에이전트 / 사람 없는 세션 / SCV_ALWAYS_ON=off / scv/ 없음
- **Run**: gate-any
- **Expected**: 모두 통과
- **Pass criterion**: 5/5

### T6. 도구 없는 턴
- **Setup**: help 표 없는 사람 턴, 끝 메시지만
- **Run**: 종료 훅(첫 멈춤 · 계속 중)
- **Expected**: 첫 멈춤만 막음, 이유에 help
- **Pass criterion**: block 1회

### T7. 매 턴 지시 순서 · 크기
- **Setup**: 매 턴 훅
- **Run**: 출력
- **Expected**: 'help → 등록' 순서 문구, 매 턴 글 상한 안
- **Pass criterion**: grep · 예산 시험

### T8. 실제 재현 (보고용)
- **Setup**: 새 코어를 실은 claude 플러그인 사본, 장난감 프로젝트
- **Run**: 여러 턴 대화
- **Expected**: 턴마다 help 호출
- **Pass criterion**: 호출 턴 수 / 사람 턴 수 보고

## How to run

```bash
bash core/tests/test-help-first.sh && bash core/tests/run-dry.sh >/dev/null && bash core/tests/test-help-budget.sh >/dev/null && bash core/tests/test-instruction-diet.sh >/dev/null && bash tests/test-host-neutral.sh >/dev/null && bash tests/run.sh >/dev/null
```

## Pass criteria

- T1–T7 통과, 전체 점검 통과, T8 수치 보고
