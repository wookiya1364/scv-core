# Test Plan — 지시 다이어트

## Overview

규약 · 계약을 줄여도 0.76.0 과 동작이 같은지(기존 시험 그대로 통과), 크기가 실제로 줄었는지, 충돌 3곳 문구와 새 검사 3개가 들어갔는지 본다.

## Test scenarios

### T1. 매 턴 글이 줄었다

- **Setup**: 이 계획 적용 뒤 코어, 같은 프롬프트 · 진단 변동 없는 턴
- **Run**: 매 턴 훅 출력 + help.md 본문 + 등록 출력(원칙 다시 싣지 않는 턴) 바이트 합
- **Expected**: 10,500 이하(0.76.0 같은 방식 14,823), 도움말 합계 < 33,022
- **Pass criterion**: 두 값 모두 기준 이하

### T1b. 원칙 전문은 첫 등록과 다시 읽기 때만

- **Setup**: 같은 세션에서 등록 두 번, 그 사이 도움말 다시 읽기 표시 없음 / 있음
- **Run**: register 출력
- **Expected**: 첫 등록과 다시 읽기 뒤 등록은 전문, 그 사이 등록은 표식 한 줄
- **Pass criterion**: 전문 줄 수 두 경우가 다름(전문 · 한 줄)

### T2. 동작이 0.76.0 과 같다

- **Setup**: 기존 코어 시험(문구 고정 지문만 갱신)
- **Run**: `core/tests/test-*.sh` 전부, `tests/run.sh`, `core/tests/run-dry.sh`
- **Expected**: 실패 0, 회귀 967/0
- **Pass criterion**: 종료 코드 0

### T3. 번호 vs 불릿 경계가 적혀 있다

- **Run**: `contracts/writing.md` 검색
- **Expected**: "번호는 답장에서 가리킬 것" 문구
- **Pass criterion**: grep 1건 이상

### T4. 항목 표 vs 해결책 표 쓰임이 적혀 있다

- **Run**: `contracts/writing.md` 검색
- **Expected**: "상태 보고는 항목 표, 풀 문제는 해결책 표" 문구
- **Pass criterion**: grep 1건 이상

### T5. 앱 마무리 상자 규칙이 적혀 있다

- **Run**: `contracts/choices.md` 검색
- **Expected**: 질문은 선택 창, 호스트의 마무리 상자에는 요약만
- **Pass criterion**: grep 1건 이상

### T6. 영어 답은 언어 위반

- **Setup**: 설정 언어 korean, 한글 없는 영어 답
- **Run**: 답 검사
- **Expected**: `lang-mismatch` 위반
- **Pass criterion**: 출력에 `lang-mismatch`

### T7. 코드 많은 한국어 답은 통과

- **Setup**: 코드 블록 · 경로가 많은 한국어 답, 그리고 설정 언어 english 의 영어 답
- **Run**: 답 검사
- **Expected**: 둘 다 `lang-mismatch` 없음
- **Pass criterion**: 출력에 `lang-mismatch` 없음

### T8. 크기 여유 검사

- **Setup**: 코어 저장소에서 합계가 상한-100 초과인 사본
- **Run**: `test-help-budget.sh`
- **Expected**: 여유 부족 실패
- **Pass criterion**: 종료 코드 1, 출력에 "여유"

## How to run

```bash
bash tests/run.sh && bash core/tests/run-dry.sh >/dev/null && for t in core/tests/test-answer-bullets.sh core/tests/test-instruction-diet.sh core/tests/test-help-budget.sh; do bash "$t" || exit 1; done
```

## Pass criteria

- T1–T8 통과, 코어 회귀 · codex 사본 코어 시험 통과
