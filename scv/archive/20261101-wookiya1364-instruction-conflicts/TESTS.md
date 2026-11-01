# Test Plan — SCV 지침 충돌 11곳 정리

## Overview

지침 글 수정은 기계가 뜻을 비교할 수 없어, 기계로 잴 수 있는 것만 시험한다: 답 모양 검사의 동작(1번), 바뀐 문구가 실제로 들어갔는지 · 충돌 문구가 빠졌는지(핵심 몇 곳), 기존 시험 전체. 나머지는 충돌 재조사로 확인한다.

## Test scenarios

### T1. 맨 위 줄 뒤 결론 3문장은 잡힌다

- **Setup**: 답 = 맨 위 이해 줄 + 빈 줄 + 세 문장 문단.
- **Run**: scv_answer_lint 본문 2
- **Expected**: `lead-sentences=3>2`
- **Pass criterion**: 지금은 아무것도 안 나옴(2026-11-01 실측) → 고친 뒤 위 줄이 나옴.

### T2. 맨 위 줄 + 바로 붙은 두 문장은 통과

- **Setup**: 맨 위 이해 줄 바로 다음 줄(빈 줄 없음)에 두 문장.
- **Run**: scv_answer_lint 본문 2
- **Expected**: 위반 없음
- **Pass criterion**: 지금은 `lead-sentences=3>2`(실측) → 고친 뒤 빈 출력.

### T3. 영어 맨 위 줄도 같게

- **Setup**: 'Understood as: …' 줄 + 빈 줄 + 세 문장.
- **Expected**: `lead-sentences=3>2`

### T4. 맨 위 줄이 없는 답은 전과 같다

- **Setup**: 기존 test-answer-lint-source 의 모든 경우.
- **Expected**: 결과 변화 없음.

### T5. 보관 검색 끝이 선택 창으로

- **Run**: archive-search 6단계 글에 글로 폴더 이름을 대라는 문장('Tell me which folder')이 없고, 선택 창으로 묻는다는 문장이 있다.
- **Pass criterion**: grep 두 줄 결과.

### T6. 짧은 턴은 파일을 열지 않는다

- **Run**: help.md 첫 절에 'open one' 이 없고, full.md B0 와 recording 계약이 같은 말(일지 한 줄)을 한다.

### T7. promote 금지 목록에 handoff 예외 · codegen 금지 목록이 '묻지 않고는'

- **Run**: 두 금지 목록 줄 grep.

### T8. 최상위 규칙 7 에 해로운 변경 예외, rewrite-principle 에 자기 우선순위 문장 없음

- **Run**: SCV.md 7번 절 grep, rewrite-principle 의 'comes before those words' 류 문장 부재 확인.

### T9. 기존 시험 전체

- **Run**: 코어 시험 전체(맥 · 리눅스 CI).
- **Pass criterion**: 실패 0.

## How to run

```bash
bash core/tests/test-answer-lint-source.sh && bash core/tests/test-rule-constitution.sh && bash core/tests/test-choice-questions.sh && bash core/tests/test-archive-search.sh && bash core/tests/test-guidance.sh && bash core/tests/test-help-guidance.sh
```

## Pass criteria

- T1–T9 통과.
- 충돌 재조사에서 실제 충돌 0(Exit criteria).
