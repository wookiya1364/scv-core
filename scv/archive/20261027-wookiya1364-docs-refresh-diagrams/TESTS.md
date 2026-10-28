# Test Plan — 코어 · 래퍼 · 모드 문서 최신화 — 빠진 기능 채우기 + 루프 · 구조 · 미러 그림

## Overview

사용자가 요구한 것은 두 가지다. 하나는 지금까지 만든 기능이 코어와 두 래퍼 문서에 빠짐없이 들어가는 것이고,
다른 하나는 사용법, 특히 미러 사용법이 그림(머메이드 + React 애니메이션 GIF)으로 보이는 것이다. 아래 시나리오가
그 두 가지와 '기능 동작은 그대로'라는 지킬 것을 하나씩 확인한다. 문서 검사는 맥과 리눅스에서 같은 결과를 내야 한다.

## Test scenarios

### T1. 명령 20개가 모두 문서에 있다

- **Setup**: 코어 · claude · codex 저장소를 같은 부모 폴더에 둔다.
- **Run**: 문서 검사를 실행한다.
- **Expected**: 코어 명령 목록의 20개 명령(help … channel)이 두 래퍼 README 세 언어와 코어의 '기능 한눈에' 표 각각에 나온다.
- **Pass criterion**: 검사 출력에 빠진 명령 0, 종료 코드 0.

### T2. 늘 켜진 기능이 모두 문서에 있다

- **Setup**: T1 과 같다.
- **Run**: 문서 검사를 실행한다.
- **Expected**: 매 턴 자동 라우팅, 재개 요약, 실체 보여 주기, 요청 등록('이렇게 이해하고 일함' · '다시 쓴 요청'), 드림, 채널, 모드, 작업 보기의 '하는 일', Graft 안내가 코어 README(또는 구조 문서)와 두 래퍼 README 에 설명되어 있다. codex 에 없는 기능(예: 시작 훅 기반 재개)은 '없음'과 이유가 적혀 있으면 통과다.
- **Pass criterion**: 검사 출력에 빠진 기능 0.

### T3. 코어 구조 문서가 2026-09-21 이후 기능을 담는다

- **Setup**: 고친 구조 문서.
- **Run**: 문서 검사의 구조 문서 항목을 확인하고, 사람이 절 목록을 본다.
- **Expected**: 드림 · 모드 · 채널 · 실체 보여 주기 · 요청 등록 · 판정자가 각각 한 절 또는 한 표 줄로 설명되고, 머메이드 그림이 적어도 하나 있다.
- **Pass criterion**: 여섯 기능이 모두 나오고 머메이드 블록 ≥ 1.

### T4. 문서 검사가 빠진 것을 실제로 잡는다

- **Setup**: 임시 사본에서 README 한 곳의 `/scv:channel` 줄을 지운다.
- **Run**: 그 사본으로 문서 검사를 실행한다(`tests/test-check-readme.sh` 의 붉은 경우 — 명령 빠짐 · 한 언어 그림 빠짐).
- **Expected**: `channel` 과 그 문서 이름이 출력되고 실패로 끝난다.
- **Pass criterion**: 종료 코드 ≠ 0, 출력에 빠진 기능 이름과 파일이 있다.

### T5. 루프 · 구조 그림이 머메이드로 보인다

- **Setup**: 고친 README 들.
- **Run**: 머메이드 블록을 구문 검사하고, GitHub 에서 렌더된 화면을 연다.
- **Expected**: 코어 · 두 래퍼 README 에 루프 그림이, 코어 README · 구조 문서에 구조 그림(코어 · 래퍼 · 모드 · 채널)이 있다. 모두 SCV 표준 어두운 테마로 시작하고 렌더 오류가 없다.
- **Pass criterion**: 구문 검사 통과, GitHub 화면에서 그림이 보인다(화면 캡처로 확인).

### T6. 루프 · 구조 · 미러 GIF 를 Remotion 으로 다시 뽑는다

- **Setup**: claude 래퍼의 Remotion 원본.
- **Run**: 세 컴포지션(TheLoop · Architecture · Mirror)을 GIF 로 렌더한다.
- **Expected**: 세 GIF 가 만들어지고, 루프 · 구조 GIF 는 claude README 에 다시 실리며, 미러 GIF 는 모드 README 에 실린다. 그림 속 기능 · 명령은 지금 기능과 맞다(구조 GIF 에 채널 · 모드가 있다).
- **Pass criterion**: 렌더 종료 코드 0, README 참조 경로에 파일이 있다, 각 GIF 의 프레임을 사람이 보고 확인한다.

### T7. 미러 사용법이 그림으로 따라 할 수 있다

- **Setup**: 고친 모드 README.
- **Run**: 미러 '쓰는 법' 절을 연다.
- **Expected**: 두 컴퓨터 사이 순서가 머메이드 순서도와 GIF 로 보인다 — 일하는 세션에서 `/scv-dashboard` 로 주소 확인 → 다른 컴퓨터 앱에서 직접 연 세션에 `/scv-mirror <주소>` → 칸에 상태가 보임 → `/scv-mirror stop` 으로 끔. 같은 세션에서 치면 안 되는 이유(자기 자신에게 보낼 수 없음)와 두 컴퓨터 모두 scv-dashboard 0.2.0 이상이 필요함이 적혀 있다.
- **Pass criterion**: 네 단계와 두 주의점이 모두 있고, 그림 속 명령이 실제 명령과 같다. 사용자가 보고 따라 할 수 있다고 확인한다.

### T8. 세 언어 README 가 같은 절 · 같은 그림을 싣는다

- **Setup**: 코어 · claude · codex README 영 · 한 · 일.
- **Run**: 저장소마다 세 언어의 절 머리 수, 머메이드 블록 수, GIF 참조 수를 비교한다.
- **Expected**: 저장소마다 세 언어의 세 수가 같다.
- **Pass criterion**: 차이 0.

### T9. 기능 동작은 그대로다

- **Setup**: 이번 변경 전체.
- **Run**: 바뀐 파일 목록을 보고, 코어 run-dry 와 두 래퍼 계약 테스트를 돌린다.
- **Expected**: 바뀐 파일은 문서 · 그림 · 문서 검사 · Remotion 원본뿐이다. 기존 테스트가 모두 통과한다.
- **Pass criterion**: 스크립트 · 훅 · 명령 파일 변경 0, 기존 테스트 실패 0.

### T10. 맥과 리눅스에서 같은 결과

- **Setup**: 문서 검사.
- **Run**: 맥(bash 3.2)에서 돌리고, CI 리눅스 결과와 비교한다.
- **Expected**: 같은 출력 · 같은 종료 코드.
- **Pass criterion**: 두 환경 모두 통과.

## How to run

```bash
bash tests/test-check-readme.sh && bash tools/check-readme.sh --profile core . && bash tools/check-readme.sh --profile claude ../scv-claude-code && bash tools/check-readme.sh --profile codex ../scv-codex && bash tools/check-readme.sh --profile mods "${SCV_MODS_DIR:-../scv-mods}"
```

## Pass criteria

- T1 – T10 모두 통과.
- 문서 검사가 빠진 기능 0 · 빠진 그림 0 으로 끝난다.
- 사용자가 루프 · 구조 · 미러 그림(머메이드 렌더 화면과 GIF)을 보고 확인한다.

## Related Documents

- `PLAN.md` — 범위 · 지킬 것 · 완료 조건
