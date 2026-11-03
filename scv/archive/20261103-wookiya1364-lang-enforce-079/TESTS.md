# Test Plan — 설정 언어 강제

## Overview

T1–T6 은 코어 시험 `core/tests/test-lang-enforce.sh` 로, T7 은 실제 긴 작업 재현으로 본다.

## Test scenarios

### T1. 매 턴 언어 줄
- **Setup**: SCV_LANG=korean / 빈 값인 임시 프로젝트
- **Run**: on-user-prompt.sh 실행
- **Expected**: korean → 한국어 규칙 줄(중간 보고 포함 문구) 1개 / 빈 값 → 없음
- **Pass criterion**: grep 개수 1 / 0

### T2. 턴 중간 교정
- **Setup**: 이번 턴 원본에 영어 문장 3줄(각 40자 이상)이 담긴 가짜 transcript
- **Run**: on-lang-check.sh 에 PostToolUse 입력
- **Expected**: additionalContext 에 "한국어" 와 줄 수가 든 교정 문구
- **Pass criterion**: 출력 JSON 에 문구 있음, exit 0

### T3. 같은 글은 두 번 교정하지 않음
- **Setup**: T2 직후 같은 원본
- **Run**: 다시 실행
- **Expected**: 새 글이 없어 출력 없음
- **Pass criterion**: 출력 빈 값

### T4. 최종 답이 어긋나면 막음, 한 번만
- **Setup**: 최종 답에 영어 3줄
- **Run**: on-stop.sh (stop_hook_active=false, 그다음 true)
- **Expected**: 첫 번째 막음(이유에 "한국어" · "고친 부분만"), 두 번째는 막지 않고 다음 턴 경고
- **Pass criterion**: decision block 1회, 경고에 언어 이름

### T5. 통과해야 하는 경우
- **Setup**: 한국어 답 / 코드 블록 · 경로만 영어 / SCV_LANG 빈 값 / 중간만 영어
- **Run**: on-stop.sh
- **Expected**: 막지 않음. 중간만 영어면 다음 턴 경고에 언어 이름
- **Pass criterion**: block 0회

### T6. 실패 · 속도
- **Setup**: transcript 없음 / 깨진 JSON / 1MB transcript
- **Run**: on-lang-check.sh
- **Expected**: exit 0, 막지 않음, 1MB 에서 1초 이하
- **Pass criterion**: exit 0 · 시간 측정값

### T8. 사용자가 다른 언어를 요청하면 강제하지 않음
- **Setup**: 사용자 글 "이번 답은 영어로 써 줘" / 영어로 쓴 사용자 글
- **Run**: 도구 뒤 훅 · 종료 훅
- **Expected**: 교정 없음 · 막지 않음 · 다음 턴 언어 경고 없음(SCV.md Top-level rules 7조 — 사용자에게 양보)
- **Pass criterion**: 출력에 [SCV 언어] 없음

### T7. 실제 재현 (수동, 보고용)
- **Setup**: SCV_LANG=korean 인 장난감 프로젝트, 여러 단계 작업 요청
- **Run**: headless 긴 작업 세션을 고치기 전 / 후 설치본으로 각각 실행
- **Expected**: 영어 중간 보고 줄 수가 줄어듦
- **Pass criterion**: 전후 수치를 보고(통과 판정은 사용자)

## How to run

```bash
bash core/tests/test-lang-enforce.sh && bash core/tests/run-dry.sh >/dev/null && bash core/tests/test-help-budget.sh >/dev/null && bash tests/test-host-neutral.sh >/dev/null && bash tests/run.sh >/dev/null
```

## Pass criteria

- T1–T6 · T8 통과, 전체 점검 · 예산 · 호스트 중립 · 저장소 시험 통과
- T7 전후 수치 보고
