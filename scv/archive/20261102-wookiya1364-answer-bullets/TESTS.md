# Test Plan — 답 모양 — 굵은 주제 + 두괄식 개조식 불릿, 다시 쓴 요청은 맨 위

## Overview

답 검사 순수함수가 새 답 모양을 통과시키고 옛 줄글 모양을 잡는지, 다시 쓴 요청 맨 위 판정과 안내 문구가 바뀌었는지 확인한다.

## Test scenarios

### T1. 굵은 주제 + 불릿 답은 통과

- **Setup**: `> **다시 쓴 요청**: …` → `**주제**` → `- 결과임` → `- 풀이함` 답
- **Run**: `scv_answer_lint`
- **Expected**: 위반 없음(예전 `lead-missing` 안 나옴)
- **Pass criterion**: 출력이 빈 문자열

### T2. 긴 줄글 문단은 위반

- **Setup**: 다시 쓴 요청 뒤 불릿 없이 상한 넘는 줄글 문단
- **Run**: `scv_answer_lint`
- **Expected**: `prose-long=` 위반 한 줄
- **Pass criterion**: 출력에 `prose-long=` 포함

### T3. 서술형 불릿은 위반, 물음은 예외

- **Setup**: `- 통과했습니다` 불릿 한 줄, `- 이대로 쓸까요?` 불릿 한 줄
- **Run**: `scv_answer_lint`
- **Expected**: 첫 줄만 `bullet-polite=` 위반
- **Pass criterion**: `bullet-polite=` 정확히 1건

### T4. 다시 쓴 요청이 맨 위가 아니면 위반

- **Setup**: 결론 문단 → 다시 쓴 요청 인용 순서(지금 모양)
- **Run**: `scv_answer_lint` 와 종료 판정
- **Expected**: `rewrite-not-top` 위반, 종료 판정이 맨 위로 옮기라고 안내
- **Pass criterion**: 출력에 `rewrite-not-top`, 안내 문구에 "맨 위"

### T5. 이해 한 줄 없이도 종료 허용

- **Setup**: 등록됨 · 맨 위 다시 쓴 요청 인용 있음 · '이렇게 이해하고 일함' 줄 없음
- **Run**: 종료 판정 함수
- **Expected**: `ok`
- **Pass criterion**: 출력 `ok`

### T6. 안내 문구가 새 모양을 말함

- **Setup**: 기본 설정 프로젝트
- **Run**: 매 턴 훅 출력, `core/contracts/writing.md`
- **Expected**: '굵은 주제', '두괄식', '~함 · ~임', '낯선 말' 문구가 있고 '이렇게 이해하고 일함' 지시가 없음
- **Pass criterion**: grep 4개 문구 일치 · 1개 불일치

### T7. 끄기 스위치 유지

- **Setup**: `SCV_PLAIN_LANGUAGE=off`
- **Run**: 매 턴 훅
- **Expected**: plain language 안내 없음
- **Pass criterion**: 출력에 `[SCV plain language]` 없음

### T8. 코드 블록 안은 검사하지 않음

- **Setup**: 코드 블록 안에 긴 줄글 · '~습니다' 줄
- **Run**: `scv_answer_lint`
- **Expected**: 위반 없음
- **Pass criterion**: 출력이 빈 문자열

## How to run

```bash
bash tests/run.sh && bash core/tests/run-dry.sh >/dev/null && for t in core/tests/test-answer-bullets.sh core/tests/test-writing-guidance.sh; do bash "$t" || exit 1; done
```

## Pass criteria

- T1–T8 통과, 코어 회귀 · codex 사본 코어 시험 통과
- 크기 예산 · 템플릿 다이제스트 검사 통과
