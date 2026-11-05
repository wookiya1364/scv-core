# Test Plan — 끝 보고 세 줄 + 근거 목록

## Overview

대화에서 정한 기능마다 시나리오 하나다(최소 요구 — 빼지 않음). 기계가 만드는 근거 목록과 실패 먼저 판정은 실제 기록(2026-11-05 사본)에서
시험판 2판과 같은 숫자를 내야 한다. 기존 검사는 그대로 통과해야 한다. 마지막 T18 은 릴리스 뒤의 실험 판정이다.

## Test scenarios

### T1. 매 턴 안내 한 줄

- **Setup**: SCV_LANG korean · english · 빈 값, 기능 켬 · 끔.
- **Run**: 매 턴 훅 실행.
- **Expected**: korean 은 한국어 한 줄, english 는 영어 한 줄, 빈 값은 영어 한 줄(검사는 언어와 상관없이 돎), 끔이면 없음.
- **Pass criterion**: `[SCV 확인 범위]` 줄 korean 1 · `[SCV verification scope]` 줄 english 1 · 빈 값 1 · 끔 0.

### T2. 일한 턴에 세 줄이 없으면 한 번 막힘

- **Setup**: 원본에 사람 글 → 파일 바꿈 · 명령 실행 → 세 줄 없는 끝 답.
- **Run**: 종료 훅 두 번(두 번째는 계속 중).
- **Expected**: 첫 번째 막힘, 이유에 빠진 줄 이름 셋. 두 번째는 이 이유로 막히지 않음.
- **Pass criterion**: 첫 출력 `"decision":"block"` + '확인 못 한 것' 포함, 두 번째 출력에 이 검사 이유 없음.

### T3. 세 줄이 다 있고 근거가 맞으면 통과

- **Setup**: T2 와 같은 턴, 끝 답에 세 줄 — '확인한 것'은 근거 목록 항목의 쉬운 이름("언어 시험 실행")을 짚음.
- **Run**: 종료 훅.
- **Expected**: 이 검사로 막지 않음.
- **Pass criterion**: 출력에 `[SCV 확인 범위]` 가 없음.

### T4. 짧은 턴은 한 줄로 통과

- **Setup**: SCV 기록 명령 · 선택 창만 쓴 턴. 끝 답 A: '확인 범위: 기록만 함 — 확인 · 결정 없음' 한 줄. 끝 답 B: 아무 줄 없음.
- **Run**: 종료 훅.
- **Expected**: A 통과, B 막힘(한 줄을 요구).
- **Pass criterion**: A 출력에 `[SCV 확인 범위]` 가 없음, B 출력 이유에 `확인 범위 한 줄` 이 있음.

### T5. 도구를 안 쓴 턴은 요구 없음

- **Setup**: 사람 글 → 도구 없이 끝 답.
- **Run**: 종료 훅.
- **Expected**: 이 검사로 막지 않음(help 먼저 검사는 그대로).
- **Pass criterion**: 출력에 `[SCV 확인 범위]` 가 없음.

### T6. '없음'은 이유가 있어야 인정

- **Setup**: 세 줄 중 '확인 못 한 것: 없음' / '확인 못 한 것: 없음 — 바꾼 함수의 모든 갈래를 시험으로 돌림'.
- **Run**: 종료 훅.
- **Expected**: 앞은 막힘, 뒤는 통과.
- **Pass criterion**: 앞 출력 이유에 `'없음'에 이유 없음: 확인 못 한 것`, 뒤 출력에 `[SCV 확인 범위]` 가 없음.

### T7. 근거 없는 '확인한 것'은 막힘

- **Setup**: 이번 턴에 시험 실행이 없는데 '확인한 것: 언어 시험 실행 → 14개 통과, missing.sh 확인'(missing.sh 는 근거 목록에 없음).
- **Run**: 종료 훅.
- **Expected**: 막힘 — 시험 없이 통과를 말함 · 근거 목록에 없는 파일.
- **Pass criterion**: 이유에 `이번 턴 근거 목록에 없는 확인: 통과(이번 턴에 시험 실행 없음) · missing.sh`.

### T8. 근거 목록 판정(시험판에서 드러난 오판 세 가지)

- **Setup**: ① 시험 파일을 grep · sed 로 읽는 명령 ② `bash tests/x.sh | tail` — 끝 코드 0, 출력에 `✖ T10` ③ 뒤에서 돌린 시험 + 다음 알림 `exit code 1`.
- **Run**: `scv_evidence_build`.
- **Expected**: ①은 '실행'(시험 아님), ②는 '시험 · 실패', ③은 '시험 · 실패'.
- **Pass criterion**: 세 항목의 종류 · 결과가 위와 같음. `FAIL=0` 같은 요약 줄은 실패로 보지 않음.

### T9. 실패 먼저

- **Setup**: A: 시험 파일 바꿈 → 통과 실행만. B: 시험 파일 바꿈 → 실패 실행 → 통과 실행.
- **Run**: 종료 훅. A 의 끝 답은 '확인 못 한 것'에 그 시험 이름이 있는 것 · 없는 것 두 가지.
- **Expected**: A-없음은 막힘(시험 이름을 짚음), A-있음은 통과, B 는 요구 없음.
- **Pass criterion**: A-없음 이유에 `고치기 전 실패를 못 본 시험('확인 못 한 것'에 적어라): test-a.sh`, A-있음 · B 출력에 `[SCV 확인 범위]` 가 없음.

### T10. 다른 검사와 묶어 한 번

- **Setup**: 영어 줄이 섞이고 세 줄도 빠진 끝 답(korean 설정) — 등록 검사는 시험 저장소에서 등록 상태를 꾸며야 해서 언어 검사로 묶음을 확인함.
- **Run**: 종료 훅.
- **Expected**: 막기 한 번에 이유 둘.
- **Pass criterion**: `"decision"` 한 번, 이유에 `[SCV 언어]` 와 `[SCV 확인 범위]` 가 함께 있음.

### T11. 끄면 이 기능 전과 같음

- **Setup**: 설정 `SCV_FINISH_REPORT=off`.
- **Run**: 종료 훅 — 끔 출력과 이 기능의 라이브러리를 뺀 코어의 출력을 비교. 매 턴 훅 — 같은 저장소에서 끔 출력과 켬 출력에서 안내 한 줄만 뺀 것을 비교.
- **Expected**: 바이트 같음, 근거 목록 파일 없음.
- **Pass criterion**: 두 비교 일치 · `evidence.md` 없음.

### T12. 영어 설정

- **Setup**: SCV_LANG english.
- **Run**: T2 · T3.
- **Expected**: 줄 이름 Verified · Not verified · Decided for you 로 같은 판정.
- **Pass criterion**: T2 · T3 결과가 같음.

### T13. 기존 시험 그대로

- **Run**: `core/tests/` 의 test-answer-lint-source · test-choice-questions-a/b/c · test-delegate-effort · test-force-help · test-guard · test-help-budget · test-help-echo · test-help-first · test-help-shape · test-instruction-conflicts · test-instruction-diet · test-journal · test-lang-enforce · test-model-prompting · test-pure-catalog · test-pure-declare · test-regression-env · test-rewrite-stays-current · test-rule-constitution · test-session-resume · test-show-real-a/b, `tests/test-host-neutral.sh`, `core/scripts/check-purity.sh`, `pure-catalog.sh check`.
- **Pass criterion**: 모두 exit 0.

### T14. 실제 기록 재현

- **Setup**: 이 컴퓨터의 2026-11-05 기록 사본(이 세션 · 맥프로_slay)을 `SCV_FINISH_REPLAY` 폴더에 두고 `expected.txt`(파일 · 시험 바꾼 턴 · 못 본 턴). 공개 저장소에 넣지 않음 — 없으면 SKIP.
- **Run**: 사람 턴마다 원본을 그 턴 끝까지 잘라 근거 목록 · 실패 먼저 판정.
- **Expected**: 얼린 사본에서 이 세션 10턴 중 4 · 맥프로_slay 3턴 중 3. 시험판 2판은 이 세션 10/4(같음) · 맥프로_slay 3/2 — 다른 한 턴(턴 5)은 시험판이 턴 단위로 셈한 탓으로, 그 턴의 art-files.test · map-layout.test 는 실패를 한 번도 보지 않았음(구현이 맞음, PLAN '구현에서 달라진 점').
- **Pass criterion**: 숫자 일치.

### T15. 속도

- **Setup**: 40MB 원본(기존 큰 원본 시험과 같은 방식).
- **Run**: 종료 훅, 기능 켬 · 끔 각 두 번 중 짧은 값.
- **Expected**: 켬 − 끔 ≤ 1초.
- **Pass criterion**: 차이 1초 이하.

### T16. 근거 목록 파일

- **Setup**: 명령에 토큰 모양 글(`Bearer abc…` · `AKIA…`)이 든 턴, 기록 폴더가 심볼릭 링크인 경우.
- **Run**: 종료 훅.
- **Expected**: 파일은 비공개 기록 폴더에만, 토큰은 `[REDACTED]`, 링크면 쓰지 않음.
- **Pass criterion**: 파일 내용 · 위치 · 링크 경우가 위와 같음.

### T17. 코덱스

- **Setup**: 코덱스 원본 모양(코덱스 래퍼 시험 자료).
- **Run**: 근거 목록 · 종료 훅.
- **Expected**: 도구 호출을 못 찾아 근거 목록이 비고 이 검사가 꺼짐(계약 문서에 적음), 훅은 실패하지 않음.
- **Pass criterion**: exit 0, 출력에 `[SCV 확인 범위]` 없음, 근거 목록 빈 값.

### T18. 릴리스 뒤 실험 판정 (구현 완료 뒤)

- **Setup**: 설치 뒤 긴 세션 3개(맥프로_slay 포함).
- **Run**: 근거 목록 · 세 줄 집계(시험판 스크립트 방식).
- **Expected**: 성공 ①~④ 또는 중단 조건 판정.
- **Pass criterion**: 판정 결과와 숫자가 계획 기록 · 결정 기록에 남음.

## How to run

```bash
bash core/tests/test-finish-report.sh
```

## Pass criteria

- T1–T17 통과(T14 는 사본이 없으면 SKIP 허용), 기존 시험(T13) 모두 exit 0.
- T18 은 릴리스 뒤 판정 — 성공이면 계획 보관, 중단 조건이면 세 줄 기본 끄기.

## Related Documents

- `PLAN.md` — 범위 · 지킬 것 · 실험 기준
