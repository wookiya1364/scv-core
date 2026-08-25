# Test Plan — 일반 대화에도 SCV 가 끼어든다

## Overview

SCV_ALWAYS_ON 스위치가 기본 켜짐(off 만 끔)으로 훅 stdout 에 라우팅 블록을
싣고, 쉬운말 스위치와 독립이며, 비 SCV 폴더에서는 침묵하고, 설정 등록부와
예시 파일에 키가 실렸는지 확인한다.

## Test scenarios

### T1. 기본 ON — 키가 없으면 라우팅 블록이 나온다 (test-always-on.sh)
- **Setup**: scv/ 있는 임시 프로젝트, 설정 파일에 키 없음.
- **Run**: 훅 실행 (stdin: `{"prompt":"..."}`)
- **Expected**: stdout 에 `[SCV always-on]` 블록 + Mode 판정 지시 + 끄는 법 한 줄.

### T2. off 만 끈다 (test-always-on.sh)
- **Setup**: 설정 `SCV_ALWAYS_ON=off` / `OFF` / `on` / 이상값 4케이스.
- **Expected**: off·OFF → 블록 없음, on·이상값 → 블록 있음.

### T3. 쉬운말 스위치와 독립 (test-always-on.sh)
- **Setup**: `SCV_PLAIN_LANGUAGE=off` + SCV_ALWAYS_ON 없음.
- **Expected**: 쉬운말 블록 없음, 라우팅 블록은 있음. 반대(always off, plain on)도 성립.

### T4. 비 SCV 폴더는 침묵 (test-always-on.sh)
- **Setup**: scv/ 없는 임시 폴더.
- **Expected**: stdout 비어 있음, exit 0 (기존 계약 그대로).

### T5. 키 등록 — 등록부와 예시 파일 (test-always-on.sh)
- **Expected**: `SCV_PLAIN_KEYS` 에 SCV_ALWAYS_ON 존재, 예시 파일에 `_doc` 항목과
  `"SCV_ALWAYS_ON": "on"` 존재, 비밀 키 목록에는 없음.

### T6. 기존 훅·설정 계약 불변 (기존 파일 그대로)
- **Run**: `bash core/tests/test-journal.sh` · `bash core/tests/test-settings.sh`
- **Expected**: 전부 green (저널 기록·NON-BLOCKING·설정 생성 계약 불변).

## How to run

```bash
bash core/tests/test-always-on.sh && bash core/tests/test-journal.sh && bash core/tests/test-settings.sh
```

## Pass criteria

- 세 테스트 파일 모두 실패 0.
