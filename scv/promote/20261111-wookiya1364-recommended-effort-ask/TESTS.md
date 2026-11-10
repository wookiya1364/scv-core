# Test Plan — 권장 effort 요청

## Overview

effort 가 권장과 다를 때만, 한 번만 묻는지 본다. 값을 모르거나 표가 없으면 아무 일도 없어야 한다.
T1–T14 · T16 · T17 은 임시 폴더의 자동 시험, T15 는 실제 세션 확인이다.

## Test scenarios

### T1. 권장 표 검사

- **Setup**: 래퍼의 `prompting/EFFORT.tsv`.
- **Run**: `bash ../scv-claude-code/prompting/check.sh`.
- **Expected**: 모델 줄마다 값이 low · medium · high · xhigh · max 중 하나, 근거 문장과 출처가 비어 있지 않음, 모델 id 가 가이드 색인에 있음.
- **Pass criterion**: 종료 코드 0. 값 낱말을 틀리게 바꾼 사본에서는 종료 코드 1.

### T2. 근거 문장은 공식 문서의 문장 그대로

- **Setup**: 표의 줄마다 출처로 적힌 문서(저장된 가이드 사본 또는 받아 온 공식 문서).
- **Run**: 근거 문장을 그 문서에서 글자 그대로 찾음.
- **Expected**: 모든 줄에서 찾음.
- **Pass criterion**: 못 찾은 줄 0개.

### T3. 다르면 요청 1번

- **Setup**: 모델 `claude-opus-5-5`(권장 medium), 지금 값 high, 새 세션.
- **Run**: 매 턴 안내 명령(`prompt`).
- **Expected**: 안내에 effort 요청 줄 1개 — 지금 값 high · 권장 medium · 근거 문장 · "선택 창으로 한 번 물어라".
- **Pass criterion**: 요청 줄 수 1.

### T4. 같은 조건에서 다시 0번

- **Setup**: T3 바로 뒤, 같은 세션.
- **Run**: `prompt` 를 두 번 더.
- **Expected**: 요청 줄 없음.
- **Pass criterion**: 두 번 모두 요청 줄 수 0.

### T5. 같으면 0번

- **Setup**: 모델 `claude-opus-5-5`, 지금 값 medium, 새 세션.
- **Run**: `prompt`.
- **Expected**: 요청 줄 없음.
- **Pass criterion**: 요청 줄 수 0, 안내 크기가 스위치를 끈 때와 바이트 단위로 같음.

### T6. 표에 없는 모델 0번

- **Setup**: 모델 `some-unknown-model`, 지금 값 low.
- **Run**: `prompt`.
- **Expected**: 요청 줄 없음.
- **Pass criterion**: 요청 줄 수 0.

### T7. 지금 값을 모르면 0번

- **Setup**: 값을 담은 환경 변수 없음, 도움말 인자도 없음. 또 하나: 값이 `banana`.
- **Run**: `prompt`.
- **Expected**: 두 경우 모두 요청 줄 없음.
- **Pass criterion**: 요청 줄 수 0.

### T8. 조건이 달라지면 다시 1번

- **Setup**: T3 → T4 뒤, 지금 값을 low 로 바꿈. 또 하나: 모델을 `claude-fable-5-2`(권장 high)로 바꾸고 지금 값 medium.
- **Run**: `prompt` 를 각각 두 번.
- **Expected**: 첫 번째에 1번, 두 번째에 0번.
- **Pass criterion**: 요청 줄 수가 1 · 0.

### T9. 끄는 설정

- **Setup**: 설정에서 effort 요청을 끔. 조건은 T3.
- **Run**: `prompt`.
- **Expected**: 요청 줄 없음, 상태 파일도 안 생김.
- **Pass criterion**: 요청 줄 수 0, 안내가 0.88.x 와 바이트 단위로 같음.

### T10. 조건이 달린 모델

- **Setup**: 모델 `claude-opus-4-8`(지금 값 high) · `claude-sonnet-5-5`(지금 값 medium).
- **Run**: `prompt`.
- **Expected**: 요청 줄에 표의 조건 글이 함께 실림.
- **Pass criterion**: 요청 줄에 조건 글이 글자 그대로 있음.

### T11. 바꾸는 것은 사용자

- **Setup**: T3 의 요청 줄.
- **Run**: 줄의 글을 봄.
- **Expected**: "사용자가 바꾼다"는 뜻의 말이 있고, 모델에게 값을 바꾸라는 말이 없음.
- **Pass criterion**: 정해 둔 문구가 있음, 금지 문구 0건.

### T12. 분량 한도

- **Setup**: 없음.
- **Run**: 매 턴 안내 분량 시험(`core/tests/test-instruction-diet.sh`)과 도움말 분량 시험.
- **Expected**: 통과.
- **Pass criterion**: 종료 코드 0.

### T13. 도움말이 effort 를 받음

- **Setup**: 없음.
- **Run**: 도움말을 `--model <id> --effort high` 로, 그리고 `--effort` 없이.
- **Expected**: 받은 값이 지금 값으로 쓰임(호스트 값이 없을 때). 없이 부르면 출력이 0.88.x 와 같음.
- **Pass criterion**: 두 출력이 기대와 같음.

### T14. 표가 없는 호스트 — 그대로

- **Setup**: 가이드 폴더에 `EFFORT.tsv` 가 없음(코덱스 래퍼 모양).
- **Run**: `prompt`, 호스트 이름 검사(`tests/test-host-neutral.sh`).
- **Expected**: 요청 줄 없음, 코어에 호스트 이름 0건.
- **Pass criterion**: 요청 줄 수 0, 검사 종료 코드 0.

### T15. 실제 세션

- **Setup**: 새 버전을 설치한 클로드 코드. 모델의 권장 값과 다른 effort 로 세션을 엶.
- **Run**: 요청 한 번. 그다음 effort 를 권장대로 두고 새 세션에서 요청 한 번.
- **Expected**: 첫 세션에서 선택 창(또는 요청 문장)이 1번, 둘째 세션에서 0번. SCV 가 읽은 지금 값이 호스트가 보여 주는 값과 같음(설정 2가지).
- **Pass criterion**: 세션 기록에서 요청 횟수가 1 · 0, 읽은 값이 두 설정 모두 일치.

### T16. 순수 함수 목록

- **Setup**: 없음.
- **Run**: 순수 함수 목록 시험.
- **Expected**: `scv_mp_effort_row` · `scv_mp_effort_verdict` · `scv_mp_effort_block` 이 목록에 있고 예가 실제 출력과 같음.
- **Pass criterion**: 종료 코드 0.

### T17. 전체 시험

- **Setup**: 없음.
- **Run**: 전체 시험을 4개씩 나눠 bash 3.2 · bash 5 로, 래퍼의 시험도.
- **Expected**: 이 변경 때문에 새로 실패한 시험 0개.
- **Pass criterion**: 새 실패 0개, PR 검사(맥 · 리눅스) 통과.

## How to run

```bash
bash core/tests/test-effort-ask.sh && bash core/tests/test-model-prompting.sh && bash core/tests/test-instruction-diet.sh && bash ../scv-claude-code/prompting/check.sh
```

## Pass criteria

- T1–T17 통과. T15 는 실제 세션 기록을 근거로 적는다.
- T15 를 확인하지 못하면 내보내지 않고 보고한다.

## Related Documents

- [`PLAN.md`](./PLAN.md)
