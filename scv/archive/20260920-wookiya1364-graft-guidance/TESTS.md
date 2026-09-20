# Test Plan — Graft 안내 — 계획·구현 때 먼저 알리고 설치까지

## Overview

Graft 가 없고 지원 언어 파일이 있는 프로젝트에서만 안내 한 줄이 헬퍼 헤더에 실리고, 그 밖의 모든 경우(ready·off·
no-graph·지원 언어 없음)에는 지금과 출력이 같다는 것을 고정한다. 문구와 설치 명령은 저장소에 한 번만 정의된다.
가짜 graft 와 언어 픽스처는 기존 test-graft-adapter.sh 의 방식을 그대로 쓴다.

## Test scenarios

### T1. absent + 지원 언어 있음 → 안내 한 줄

- **Setup**: PATH 에 graft 없음. 임시 git 저장소에 지원 확장자 파일(예: `a.ts`) 1개 이상.
- **Run**: `bash core/scripts/graft.sh status`.
- **Expected**: `GRAFT_STATUS: absent` 와 `GRAFT_NOTICE: …` 두 줄. 안내 줄에 "코드 후보" 와 설치 명령(`npm i -g @nanonets/graft`)이 있다.
- **Pass criterion**: 두 줄 존재, 안내에 두 구절 포함.

### T2. absent + 지원 언어 없음 → 안내 없음

- **Setup**: PATH 에 graft 없음. 임시 저장소에 `.sh`·`.md` 만.
- **Run**: 같은 명령.
- **Expected**: `GRAFT_STATUS: absent` 한 줄만. `GRAFT_NOTICE:` 없음.
- **Pass criterion**: grep -c 'GRAFT_NOTICE' == 0.

### T3. ready / off / no-graph → 안내 없음 (또는 no-graph 는 init 안내)

- **Setup**: 가짜 graft 스크립트 + `graft/` 폴더(ready), `SCV_GRAFT=off`, graft 있고 `graft/` 없음(no-graph).
- **Run**: 같은 명령 세 번.
- **Expected**: ready·off 에 `GRAFT_NOTICE:` 없음. no-graph 는 `GRAFT_NOTICE:` 에 `graft init` 안내(설치 명령 아님).
- **Pass criterion**: 각 상태의 기대와 일치.

### T4. 헬퍼 헤더가 그대로 실어 낸다

- **Setup**: T1 의 저장소를 hydrate 한 임시 프로젝트.
- **Run**: `promote-helper.sh`, `work.sh <slug>` (계획 하나 심어서).
- **Expected**: 두 헬퍼의 헤더에 `GRAFT_NOTICE:` 줄이 graft.sh 출력과 바이트 단위로 같다.
- **Pass criterion**: diff 없음.

### T5. 프로토콜은 전달만 한다

- **Setup**: `core/protocols/promote.md`, `work.md`, `codegen.md`.
- **Run**: `GRAFT_NOTICE` 를 grep. 설치 명령 문자열(`npm i -g @nanonets/graft`)을 `core/` 에서 grep.
- **Expected**: promote·work 에 "relay … verbatim" 문장 1개씩. codegen 은 work 의 Steps 1–5b 를 verbatim 으로 따른다는 기존 문장으로 덮이므로 새 문장 없음(4조). 설치 명령 문자열 정의는 `core/scripts/lib/graft.sh` 한 곳 — `core/` 의 다른 파일(스크립트·프로토콜·템플릿)에는 없음.
- **Pass criterion**: grep 결과가 기대와 같다.

### T6. 규칙 헌법 검사 그대로

- **Run**: `bash core/tests/test-rule-constitution.sh`.
- **Expected**: (a) 위반 0, (b) 기준선 이하.
- **Pass criterion**: 통과.

### T7. 기존 테스트·맥·리눅스

- **Run**: `bash core/tests/test-graft-adapter.sh`, core 테스트 루프, run-dry, tests/run.sh. PR CI(우분투·맥).
- **Expected**: 실패 0.
- **Pass criterion**: 종료 코드 0, CI 초록.

## How to run

```bash
bash core/tests/test-graft-adapter.sh && bash core/tests/test-rule-constitution.sh && bash core/tests/run-dry.sh && bash tests/run.sh
```

## Pass criteria

- T1~T7 통과.
- 안내 문구·설치 명령 정의가 저장소에 한 곳.
- Graft 없는 프로젝트의 다른 출력은 변화 없음(안내 한 줄 추가 외).
