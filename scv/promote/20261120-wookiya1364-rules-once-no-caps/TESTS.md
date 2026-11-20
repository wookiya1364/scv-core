# Test Plan — 매 턴 규칙 글은 한 번만 · 숫자 길이 상한 없애기

## Overview

숫자 상한이 없어졌는지, 규칙 글이 세션에 한 번만 실리고 지문 변경 · 경고 · 끄기에서는 전문이 실리는지 본다.

## Test scenarios

### T1. 긴 줄글 · 긴 불릿에 문장 수 · 길이 경고가 없다
- **Run**: 줄글 문단 4문장, 불릿 하나에 6문장인 답으로 `scv_answer_lint`.
- **Pass criterion**: 출력에 prose-long · bullet 길이 항목 없음. '~습니다' 결론 줄 같은 다른 어김은 그대로 잡힘.

### T2. 매 턴 안내 · 규약에 숫자 상한 표현이 없다
- **Run**: 훅 출력 · core/protocols · SCV.md 에서 "1–2 sentences" · SCV_PLAIN_MAX_SENTENCES 를 찾음.
- **Pass criterion**: 0건.

### T3. 같은 세션 둘째 턴은 한 줄
- **Setup**: 시험 저장소, 세션 s1, help 표시(지문) 있음.
- **Run**: 사람 턴 두 번 훅 실행.
- **Pass criterion**: 지문이 생긴 뒤 첫 턴은 전문, 다음 턴은 한 줄 알림만 있고 1.5 KB 이상 작음(시험 환경엔 선택 창 · 원칙 글이 없음).

### T4. 지문이 바뀌면 다시 전문
- **Run**: 둘째 턴 뒤 지문을 바꾸고(help-state reset 과 같은 효과) 셋째 턴.
- **Pass criterion**: 셋째 턴에 다섯 덩어리 다시 있음.

### T5. 남은 경고가 있으면 전문
- **Run**: 세션 턴 폴더에 경고 파일을 두고 턴 실행.
- **Pass criterion**: 다섯 덩어리 있음.

### T6. 끄면 예전과 같다
- **Run**: `SCV_RULES_ONCE=off` 로 두 턴.
- **Pass criterion**: 둘째 턴에도 다섯 덩어리 있음.

### T7. 다른 세션은 섞이지 않는다
- **Run**: s1 두 턴 뒤 s2 첫 턴.
- **Pass criterion**: s2 첫 턴은 전문.

## How to run

```bash
bash core/tests/test-rules-once.sh
```

## Pass criteria

- T1–T7 통과(맥 · 리눅스), 관련 시험(답 모양 · 안내 예산 · show-real · 언어 · 확인 범위) 통과, 푸시 전 전체 실행 통과.
