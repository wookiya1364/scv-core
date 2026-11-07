# Test Plan — 가이드 발췌본 + 종료 검사 다음 턴 안내

## Overview

발췌본이 있으면 help 가 그것을 읽는지, 종료 검사가 기본으로 막지 않고 다음 턴 안내로 넘기는지, block 이면 예전과 같은지, 제목형 확인 범위가 빠진 줄로 잡히지 않는지 본다.

## Test scenarios

### T1. 발췌본을 읽게 함

- **Setup**: 시험 가이드 폴더에 `excerpt-common.md` 를 둔다(모델 원문 발췌본은 없음)
- **Run**: `bash core/tests/test-model-prompting.sh` (T44)
- **Expected**: `GUIDE_FILE` 이 모델 원문 · `excerpt-common.md` 를 가리키고 `common.md` 는 없음. 발췌본이 링크면 원문 `common.md`
- **Pass criterion**: `OK [T44] 3/3`

### T2. 기본은 막지 않고 다음 턴 안내

- **Setup**: 언어 · 확인 범위가 어긋난 끝 답
- **Run**: `bash core/tests/test-stop-notice.sh` (N1 · N2)
- **Expected**: 종료 훅 출력에 `"decision"` 없음, 안내 파일에 `[SCV 직전 답] [SCV 언어]` · `[SCV 직전 답] [SCV 확인 범위]`, 다음 매 턴 훅이 한 번 싣고 지움
- **Pass criterion**: `ok N1` · `ok N2`

### T3. block 이면 예전처럼 막음

- **Setup**: 설정 `SCV_STOP_MODE=block`
- **Run**: `bash core/tests/test-stop-notice.sh` (N3), 막힘을 보는 기존 시험 10개
- **Expected**: `{"decision":"block",...}` 와 '앞 답은 이미 사용자 화면에 있다' 줄, 안내 파일 없음
- **Pass criterion**: `ok N3`, 기존 시험 10개 종료 코드 0

### T4. 지킨 답은 안내 없음

- **Run**: `test-stop-notice.sh` (N4)
- **Pass criterion**: `ok N4`

### T5. 제목형 확인 범위 인정

- **Setup**: `**확인한 것**` · `**확인 못 한 것**` · `**제가 대신 정한 것**` 제목 아래 목록으로 쓴 끝 답
- **Run**: `test-stop-notice.sh` (N5), `test-finish-report.sh`
- **Pass criterion**: `ok N5`, test-finish-report 실패 0

### T6. 순수부

- **Run**: `test-stop-notice.sh` (N6)
- **Pass criterion**: `ok N6`

## How to run

```bash
bash core/tests/test-stop-notice.sh && bash core/tests/test-model-prompting.sh && bash core/tests/test-finish-report.sh
```

## Pass criteria

- 위 세 시험이 모두 종료 코드 0
