# Test Plan — 답 · 중간 보고를 설정 언어로

## Overview

한 줄 규칙 턴의 언어 줄, 도구 뒤 알림, 여러 언어 판정을 본다. korean 판정은 지금과 같아야 한다.

## Test scenarios

### T1. 한 줄 규칙 턴에도 설정 언어 줄
- **Run**: 규칙을 이미 실은 세션에서 사람 턴 훅을 다시 부름(korean · japanese · 설정 없음).
- **Pass criterion**: korean 은 `[SCV 언어]` 줄, japanese 는 `[SCV language] … japanese` 줄, 설정 없음은 언어 줄 없음.

### T2. 여러 언어 판정
- **Run**: japanese 설정에 영어 줄 · 일본어 줄, chinese 설정에 영어 줄 · 중국어 줄, korean 설정은 기존 예, english 설정.
- **Pass criterion**: 다른 언어 줄만 1로 셈, 설정 언어 줄은 0. english 는 아무것도 세지 않음.

### T3. 도구 뒤 알림
- **Run**: 이번 턴에 글 없음 / 마지막 글이 영어 / 마지막 글이 설정 언어인 기록으로 도구 뒤 훅을 부름.
- **Pass criterion**: 앞 둘은 알림(영어 글이면 교정 문구), 셋째는 아무것도 없음. 사용자가 이 턴에 다른 언어로 쓰면 없음.

## How to run

```bash
bash core/tests/test-lang-enforce.sh
```

관련 시험: `core/tests/test-rules-once.sh` · `core/tests/test-help-budget.sh` · `core/tests/test-hook-dedupe.sh` · `core/tests/test-purity.sh` · `core/tests/test-pure-catalog.sh`.

## Pass criteria

- T1–T3 와 기존 언어 시험 모두 ok, 종료 코드 0 (mac · linux).
- 매 턴 글 예산 안.
