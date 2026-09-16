# Test Plan — 규약 지문 메아리 — 잊었는지 묻지 않고, 지문과 답 모양으로 잡아 다시 싣는다

## Overview

"규약이 컨텍스트에서 빠졌다"와 "답이 계약을 벗어났다"를 훅이 기계로 감지해 다음 턴에 다시 싣는지,
그리고 그 판정이 모델의 자기 보고에 기대지 않는지를 본다. 훅은 stdin 과 파일로 재현되므로 셸로 된다.

## Test scenarios

### T1. 순수부 — 메아리 판정·린트·재읽기 결정

- **Run**: `scv_echo_check` (ok/missing/mismatch/skip), `scv_answer_lint` (문장 상한·결론 뒤 표·결정표 추천 열·첫 문단 코드값), `scv_drift_decide`.
- **Expected**: protocol=0 → skip; 지문 같음 → ok; 없음 → missing; 다름 → mismatch. 린트: 3문장 결론 → 위반, 추천 열 빈 결정표 → 위반, 첫 문단의 백틱 경로 → 위반, 정상 답 → 0. decide: missing/mismatch 또는 위반 ≥1 → protocol=0 + 경고 줄; ok·0 → 변화 없음. check-purity 통과.
- **Pass criterion**: 전부 ✓.

### T2. mark 가 지문을 만들고 규약을 읽은 자리에만 노출한다

- **Run**: `help-state.sh mark` 두 번; `.help-nonce` 파일; 라우터 help.md · 훅 출력 · `--with-context` 출력.
- **Expected**: 표식 nonce 8자리 16진, 파일과 같음, 두 번째 mark 는 새 값. 라우터·훅 출력·PROTOCOL 줄에 지문이 없다. full.md 끝에 지문 파일을 읽으라는 지시.
- **Pass criterion**: 4/4.

### T3. 메아리 — 적으면 유지, 빠지면 다음 턴 load + 경고

- **Setup**: 세션 A, mark, 대화 파일에 Turn 블록 append.
- **Run**: (a) `protocol: <지문>` 있는 append 뒤 Stop 훅 → 매 턴 훅. (b) 지문 없는 append 뒤. (c) 틀린 지문.
- **Expected**: (a) loaded 유지, 경고 없음. (b)(c) 다음 매 턴 훅 출력에 "[SCV 규약 지문]" 경고 한 줄, `--with-context` 가 load.
- **Pass criterion**: 3/3.

### T4. 답 모양 린트 — 위반이면 다음 턴 경고 + load

- **Run**: Stop 훅 stdin 에 (a) 결론 4문장 답 (b) 추천 열 없는 결정표 답 (c) 정상 답.
- **Expected**: (a)(b) 다음 턴 경고 "[SCV 답 모양]" + load; (c) 아무 것도 없음.
- **Pass criterion**: 3/3.

### T5. 실패·스위치 — 이전 동작

- **Run**: stdin 비움·JSON 아님; `.help-nonce` 삭제; `SCV_HELP_ECHO=off`; `SCV_ANSWER_LINT=off`.
- **Expected**: exit 0, 표식 불변(nonce 무시), 경고 없음, 저널 검사(test-journal) 통과(무효 입력엔 아무 것도 안 씀; `.help-nonce`·`.help-drift` 는 예외 목록).
- **Pass criterion**: 4/4 + test-journal 통과.

### T6. 10턴 시뮬레이션과 드리프트 로그

- **Run**: 10턴 중 4·8턴에 지문 누락, 6턴에 모양 위반.
- **Expected**: load 는 1·5·7·9턴(첫 턴 + 각 위반 다음 턴), 드리프트 로그 10줄에 누락 2·위반 1.
- **Pass criterion**: 정확히 일치.

### T7. 회귀

- **Run**: test-help-load-once · test-help-budget · test-journal · test-session-resume · run-dry · 코어 전부 · 래퍼 벤더링.
- **Pass criterion**: 전부 통과.

### T8. 실사용 관찰 (수동)

- **Run**: 세 세션에서 드리프트 로그를 읽어 "흐려진 턴" 수와 재읽기 횟수를 CHANGELOG 에 기록.

## How to run

```bash
bash core/tests/test-help-echo.sh && bash core/tests/test-help-load-once.sh && bash core/tests/test-journal.sh && bash core/tests/test-help-budget.sh
```

## Pass criteria

- T1~T7 자동 통과, T8 기록.

## Related Documents

- `core/tests/test-help-load-once.sh` — 훅 시뮬레이션 골격
