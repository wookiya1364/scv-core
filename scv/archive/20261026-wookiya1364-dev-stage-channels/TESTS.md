# Test Plan — SCV 개발 · 스테이징 채널 — 운영 릴리스 없이 바꿔 끼워 받아 확인

## Overview

사용자가 명령 하나로 개발 · 스테이징 · 운영 채널을 바꿔 끼우고, 래퍼의 개발 · 스테이징 브랜치가 코어의 같은 브랜치를 따라가는지 확인한다. 순수 함수는 단위 시험으로, 실제 바꿔 끼우기는 사용자 설정을 건드리지 않는 임시 설정 폴더에서, 동기화는 래퍼 저장소의 결과로 본다. 운영 채널과 릴리스 절차가 그대로인지도 함께 본다.

## Test scenarios

### T1. 채널 이름이 브랜치로 바뀐다

- **Setup**: 없음
- **Run**: `channelRef` 에 개발 · 스테이징 · 운영 · 모르는 이름을 넣는다
- **Expected**: develop · stage · 없음(운영) · 오류(모르는 이름)
- **Pass criterion**: 네 경우 모두 기대값과 같다

### T2. 출처 문자열이 맞다

- **Setup**: 래퍼 git 주소
- **Run**: `marketplaceSource` 에 브랜치 develop · stage · 없음을 넣는다
- **Expected**: `<주소>#develop`, `<주소>#stage`, `<주소>`(운영은 꼬리 없음)
- **Pass criterion**: 세 문자열이 정확히 같다

### T3. 바꿔 끼우기 명령 순서

- **Setup**: 깔린 상태 = 운영(브랜치 없음)
- **Run**: `switchPlan` 에 목표 개발을 넣고, 다시 같은 채널(운영 → 운영)을 넣는다
- **Expected**: 운영 → 개발은 지우기 → `#develop` 으로 추가 → 플러그인 업데이트 순서. 같은 채널이면 "할 일 없음"
- **Pass criterion**: 명령 목록의 순서와 내용이 같고, 같은 채널은 빈 목록이다

### T4. 채널 버전 표시

- **Setup**: 기준 버전 0.70.4, 커밋 `abc1234`
- **Run**: `channelVersion` 에 개발 · 스테이징 · 운영을 넣는다
- **Expected**: 개발 · 스테이징은 다음 패치에 채널과 커밋이 붙는다(예: `0.70.5-dev.abc1234`), 운영은 기준 버전 그대로
- **Pass criterion**: 세 결과가 기대값과 같고, 개발 버전이 운영 버전보다 앞선다(semver 비교)

### T5. 실제로 개발 채널로 바꿔 끼운다

- **Setup**: 빈 임시 설정 폴더(`CLAUDE_CONFIG_DIR`), 운영 채널 설치
- **Run**: 채널 명령으로 개발로 바꾼다
- **Expected**: `claude plugin marketplace list --json` 에 `ref: develop`, 설치된 SCV 버전에 dev 표시
- **Pass criterion**: 목록의 ref 와 버전 표시가 모두 개발이다

### T6. 운영으로 되돌린다

- **Setup**: T5 직후
- **Run**: 채널 명령으로 운영으로 바꾼다
- **Expected**: 목록에서 ref 가 사라지고, 버전이 최신 릴리스와 같다
- **Pass criterion**: ref 없음 + 버전 = GitHub 최신 릴리스 태그

### T7. 실패하면 그 자리에서 멈춘다

- **Setup**: 없는 브랜치를 가리키는 출처(시험용)
- **Run**: 바꿔 끼우기를 실행한다
- **Expected**: 실패한 단계 이름과 다음 할 일(`NEXT:`)을 출력하고 멈춘다. 실패를 성공으로 보고하지 않는다
- **Pass criterion**: 종료 코드가 0이 아니고, 실패 단계 줄이 있다

### T8. 코어 develop 이 래퍼 develop 에 들어간다

- **Setup**: 코어 develop 에 시험 커밋 하나를 병합
- **Run**: 채널 동기화 워크플로가 끝나기를 기다린다
- **Expected**: claude · codex 래퍼의 `channel/dev` 에 담긴 코어 커밋이 코어 develop 커밋과 같고, 래퍼 검사가 통과했다. 래퍼 develop 은 그대로다
- **Pass criterion**: 두 래퍼의 channel/dev 코어 커밋 = 코어 develop 커밋, 래퍼 검사 성공, 래퍼 develop 변경 없음

### T9. 운영 채널과 릴리스 절차는 그대로

- **Setup**: 이 계획 반영 뒤
- **Run**: 브랜치 없이 마켓을 추가하고, 다음 코어 릴리스 때 기존 체인(동기화 PR → 래퍼 릴리스)을 돈다
- **Expected**: 운영 추가는 main 의 최신 릴리스. `scv-core-released` 동기화 PR 이 예전처럼 열린다
- **Pass criterion**: 운영 버전 = 최신 릴리스, 동기화 PR 생성 · 통과

### T10. codex 의 브랜치 지정 지원을 확인한다

- **Setup**: 빈 임시 codex 설정 폴더
- **Run**: `codex plugin marketplace add <주소>#develop` 을 시도한다
- **Expected**: 결과(되는지 · 안 되는지)가 PLAN.md 위험 칸에 기록되고, 안 되면 채널 명령이 codex 에서 "아직 지원 안 함"을 분명히 말한다
- **Pass criterion**: 기록이 있고, codex 동작이 기록과 맞다

## How to run

```bash
bash core/tests/test-channel.sh
```

## Pass criteria

- 코어: T1–T4 는 `test-channel.sh` 가 통과(맥 · 리눅스 CI 모두). 액션 목록 · 가드 · 도움말 시험(`tests/run.sh`, 코어 시험 전체)도 통과.
- 래퍼(채널 명령의 실행부는 어댑터 몫 — PLAN Path delta): T5–T7 은 각 래퍼의 채널 시험이 임시 설정 폴더에서 본다.
- T10 은 2026-10-26 실험으로 확인(PLAN 위험 칸 — codex 도 브랜치 지정 됨).
- T8 · T9 는 실제 워크플로 결과로 확인해 PR 본문에 근거를 남긴다. 채널 브랜치는 래퍼 develop 이 아니라 `channel/dev` · `channel/stage` 다.

## Related Documents
