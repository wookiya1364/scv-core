# Test Plan — 남은 문제 6개 정리

## Overview

①–④ · ⑥ 은 코어 시험 `test-remaining-fixes.sh` T1–T6 으로, ⑤ 는 코덱스 저장소 시험으로 본다. 고치기 전(develop)에는 T1–T3 이 실패(확인).

## Test scenarios

### T1. 프로젝트 밖 등록 거절
- **Setup**: `scv/` 가 없는 임시 폴더
- **Run**: 그 폴더에서 `model-prompting.sh register`
- **Expected**: `REGISTER: refused — no scv/` 로 시작, 아무것도 저장 안 됨
- **Pass criterion**: `ok T1`

### T2. 막을 때 '고친 부분만' 안내
- **Setup**: 종료 훅
- **Run**: 막는 이유 조립을 확인
- **Expected**: "앞 답은 이미 사용자 화면에 있다 — 고친 부분만" 한 줄
- **Pass criterion**: `ok T2`

### T3. 줄별 언어 검사
- **Setup**: 한국어 설정
- **Run**: `scv_lint_lang_turn` — 중간 보고에 영어 줄 1개 / 코드 · 표 · 백틱만 영어 / 영어 설정
- **Expected**: `lang-mismatch-lines=1` / 빈 값 / 빈 값
- **Pass criterion**: `ok T3`

### T4. 턴 글 전체를 언어 검사에 넘김
- **Setup**: 종료 훅 · help-state
- **Run**: `--lang-text` 연결 확인
- **Expected**: 있음
- **Pass criterion**: `ok T4`

### T5. 가이드 경로를 지금 설치본으로
- **Setup**: 옛 버전 경로가 든 기록
- **Run**: `scv_mp_guide_rebase`
- **Expected**: 새 폴더 · 새 스크립트 경로로 바뀜
- **Pass criterion**: `ok T5`

### T6. 비슷한 충돌 정리
- **Setup**: 저장소 그대로
- **Run**: guard.md 숫자 · channel 행, regression 분석 제안 · 표 되돌림, handoff push 질문, install-deps 섞인 문장
- **Expected**: 6/6
- **Pass criterion**: `ok T6`

## How to run

```bash
bash core/tests/test-remaining-fixes.sh && bash core/tests/run-dry.sh >/dev/null && bash core/tests/test-help-budget.sh >/dev/null && bash core/tests/test-choice-questions.sh >/dev/null && bash tests/run.sh >/dev/null
```

## Pass criteria

- T1–T6 통과, 전체 점검 · 크기 예산 · 선택 창 · 저장소 시험 통과
