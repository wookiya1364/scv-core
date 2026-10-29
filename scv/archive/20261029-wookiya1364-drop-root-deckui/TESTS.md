# Test Plan — claude 래퍼의 중복 DeckUI 없애기 — deck 이 코어 사본 안 엔진을 읽게

## Overview

맨 위 DeckUI 투영본을 없앤 뒤에도 claude 의 `/scv:deck` 이 같은 결과를 내는지(바이트 비교), codex · 코어의 deck 이 그대로인지, 동기화 도구의 손대지 않음 검사가 약해지지 않았는지 본다. 대화(117~118턴)에서 나온 요구 하나하나가 시나리오다.

## Test scenarios

### T1. 엔진 위치 — 설정이 없으면 지금 자리

- **Setup**: 래퍼 설정에 엔진 위치 키가 없는 코어 트리(코어 저장소 자체, codex 사본).
- **Run**: 코어 시험에서 엔진 위치 판단을 부른다.
- **Expected**: 코어 루트 아래 `DeckUI` 를 돌려준다.
- **Pass criterion**: 돌려준 경로 = `<코어 루트>/DeckUI`.

### T2. 엔진 위치 — 코어 루트에 엔진이 없고 설정이 있으면 그 자리

- **Setup**: 코어 루트 아래 DeckUI 가 없는 트리(claude 의 플러그인 최상위와 같은 모양)에, 설정으로 코어 루트 기준 상대 경로를 준다. 코어 루트에 엔진이 있으면 그것이 설정보다 앞선다(코어 · codex · claude 의 코어 사본 동작 그대로).
- **Run**: 같은 판단을 부른다.
- **Expected**: 그 경로를 돌려준다.
- **Pass criterion**: 돌려준 경로 = 설정 경로를 코어 루트 기준으로 푼 것.

### T3. 엔진 위치 — 잘못된 설정은 막는다

- **Setup**: 없는 폴더, 연결(심볼릭 링크), 플러그인 밖으로 나가는 경로('..' · 절대 경로).
- **Run**: deck 준비를 부른다.
- **Expected**: 설명이 붙은 오류로 멈추고 아무것도 쓰지 않는다.
- **Pass criterion**: 종료 코드 ≠ 0, 오류 문구에 경로 · 이유, 캐시 폴더 변화 없음.

### T4. claude 래퍼에 맨 위 DeckUI 가 없다

- **Setup**: 동기화를 마친 claude 래퍼 브랜치.
- **Run**: `ls DeckUI`, `git grep -n DeckUI -- . ':!vendor' ':!CHANGELOG*' ':!docs/releases'`.
- **Expected**: 폴더 없음. 남은 줄은 엔진 위치 설정 · deck 스크립트 · 역사 설명뿐.
- **Pass criterion**: 맨 위 `DeckUI/` 없음, 남은 줄 목록을 PR 본문에 그대로 싣는다.

### T5. 투영이 DeckUI 를 다시 만들지 않는다

- **Setup**: claude 래퍼에서 투영 스크립트를 처음부터 다시 돌린다.
- **Run**: `scripts/project-core.sh`(또는 `sync-core.sh --version <ver>`) 실행 뒤 `git status`.
- **Expected**: 맨 위 `DeckUI/` 가 생기지 않고, 다른 투영본(`scripts/` · `template/` · `assets/`)은 그대로.
- **Pass criterion**: `git status` 가 깨끗, `DeckUI/` 없음.

### T6. 손대지 않음 검사는 그대로

- **Setup**: 코어 사본 안 DeckUI 파일 하나를 손으로 바꾼 사본.
- **Run**: claude 의 코어 확인(`verify-core.sh` / 동기화 원자성 시험).
- **Expected**: 바뀐 파일 이름을 대며 실패.
- **Pass criterion**: 실패 + 그 파일 경로가 출력에 있다.

### T7. 같은 계획 → 같은 문서 HTML (설치본, 바이트)

- **Setup**: 바꾸기 전 claude 설치본(0.72.1)으로 보관 계획 하나(예: `scv/archive/20261028-wookiya1364-ci-parallel-tests`)의 문서 deck 을 만들어 기준으로 둔다.
- **Run**: 바꾼 claude 설치본(새 릴리스, 또는 같은 내용의 로컬 설치)으로 같은 계획의 문서 deck 을 만든다.
- **Expected**: 두 HTML 이 같다.
- **Pass criterion**: `cmp` 가 같음(다르면 차이 줄을 보고하고 멈춘다).

### T8. `--slides` 가 만들어진다 (설치본)

- **Setup**: T7 의 바꾼 설치본.
- **Run**: 같은 계획으로 `deck.sh <계획> --slides`.
- **Expected**: 슬라이드 HTML 이 만들어진다(첫 실행이면 렌더러를 한 번 깔아도 됨 — 사용자 결정).
- **Pass criterion**: 종료 0, 출력 파일이 있고 크기 > 0.

### T9. codex · 코어의 deck 은 그대로

- **Setup**: 코어 저장소와 codex 사본(설정에 엔진 위치 없음).
- **Run**: 기존 deck 시험(`test-deck-*.sh`) 전부, codex 사본에서 코어 시험 전부.
- **Expected**: 모두 통과.
- **Pass criterion**: `run-focused: … fail=0`.

### T10. 맥 · 리눅스 · bash 3.2

- **Setup**: 새로 넣거나 바꾼 시험.
- **Run**: 이 맥에서 `/bin/bash`(3.2) 로, CI 에서 우분투 · 맥으로.
- **Expected**: 모두 통과.
- **Pass criterion**: 로컬 3.2 통과 + 코어 · claude CI 통과.

### T11. 세 저장소 운영 릴리스

- **Setup**: 위가 모두 통과.
- **Run**: 코어 → claude · codex 릴리스 절차(메모).
- **Expected**: 세 저장소 최신 릴리스가 새 판.
- **Pass criterion**: `gh release list -L 1` 세 저장소 모두 새 판 Latest.

## How to run

```bash
bash core/tests/run-focused.sh --dir core/tests
```

## Pass criteria

- T1–T10 통과(T7 은 바이트 같음), T11 은 릴리스 뒤 확인.
- 실패가 있으면 그 시험 이름 · 출력으로 보고하고 멈춘다.

## Related Documents

- `PLAN.md`, `FEATURE_ARCHITECTURE.md`
