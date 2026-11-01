# Test Plan — 프로젝트 순수함수 사전 — 어느 언어든 scv/core 에

## Overview

대화에서 정한 것 하나하나가 시험이다: 어느 언어든 표식 줄의 이름으로 찾기, 프로젝트 저장소의 scv/core 에 사전, 셸은 실행 · 다른 언어는 칸 검사(숫자로 밝힘), 예시 글로 중복, 제외 폴더, scv-core 자신은 그대로. 시험은 임시 git 저장소의 고정 파일로 돌아 결정적이다.

## Test scenarios

### P1. 여러 언어의 표식을 이름으로 찾는다

- **Setup**: 임시 git 저장소에 자바(`/** ... * @pure add */`), C(`// @pure clamp`), 러스트(`/// @pure dot`), TS(`// @pure formatDate`), 파이썬(`# @pure slugify`), 셸(이름 없는 `# @pure`) 함수 하나씩, 각자 역할 · 종류 · 예.
- **Run**: 프로젝트 모드 build.
- **Expected**: 여섯 함수가 전부 사전에 오른다. 위치에 각 파일이 적힌다.
- **Pass criterion**: 사전의 `### 이름` 줄이 정확히 여섯(add · clamp · dot · formatDate · slugify · 셸 함수).

### P2. 사전은 그 저장소의 scv/core/catalog/pure 에

- **Setup**: P1 저장소, 다른 폴더에서 명령 실행.
- **Run**: build 를 저장소 하위 폴더에서.
- **Expected**: `<저장소>/scv/core/catalog/pure/INDEX.md` 가 생기고 다른 곳엔 아무것도 안 생긴다.
- **Pass criterion**: 생성 파일 목록이 사전 폴더 안뿐.

### P3. 빈 칸은 언어와 상관없이 실패

- **Setup**: 러스트 함수에서 예 줄을 뺀다.
- **Run**: check.
- **Expected**: 그 함수 이름 · '예 없음'.
- **Pass criterion**: 종료 코드 1.

### P4. 셸은 실행, 다른 언어는 칸만 — 숫자로 밝힘

- **Setup**: P1 저장소, 셸 예시 하나를 일부러 틀리게.
- **Run**: check.
- **Expected**: 셸 함수 '예시가 틀렸다'. 결과 줄에 '실행 1 · 칸만 5'.
- **Pass criterion**: 틀린 예시 줄이 셸 함수만, 개수 줄이 맞다.

### P5. 같은 언어끼리는 중복 의심, 다른 언어끼리는 '다른 언어 짝'

- **Setup**: TS `formatDate` 와 파이썬 `fmt_date` 가 같은 예(`"2026-01-02" → "26/01/02"`)를 공유. 이어서 같은 예를 가진 TS `shortDate` 를 더한다.
- **Run**: build · check.
- **Expected**: formatDate · fmt_date 는 중복이 아니라 서로의 항목에 `다른 언어 짝: … (py)` · `(ts)` 로 적힌다(사용자 요구 2026-11-01 — 프론트 · 백엔드처럼 언어마다 따로 둘 수 있다). formatDate · shortDate(같은 TS)는 중복 의심.
- **Pass criterion**: 짝 줄 두 개, 중복 의심은 같은 언어 한 짝만.

### P6. 제외 폴더의 표식은 무시

- **Setup**: `tests/` · `node_modules/` 안에 표식이 든 파일.
- **Run**: build.
- **Expected**: 그 함수들은 사전에 없다. 설정으로 제외 목록을 바꾸면 들어온다.
- **Pass criterion**: 기본은 없음, 설정 후 있음.

### P7. scv-core 자신은 그대로

- **Setup**: 이 저장소.
- **Run**: 기존 test-pure-catalog.sh 와 사전 check.
- **Expected**: 기존 T1–T13 통과, 사전 변화 없음.
- **Pass criterion**: 통과, `git diff scv/core/catalog` 비어 있음.

### P8. 래퍼 설치본에서 프로젝트 모드

- **Setup**: 코어 사본(설치본 흉내) + 별도 사용자 저장소.
- **Run**: 사본의 명령으로 사용자 저장소에서 build.
- **Expected**: 사용자 저장소의 scv/core/catalog/pure 에 생긴다. 사본 쪽엔 아무것도 안 생긴다.
- **Pass criterion**: 두 폴더의 파일 목록이 기대대로.

### P9. 규약 — 어느 프로젝트든 차례부터

- **Setup**: work · codegen 규약.
- **Run**: 프로젝트 사전 차례 읽기 · 만든 뒤 다시 만들기 단계를 찾는다.
- **Pass criterion**: 두 규약 모두에 있다.

### P10. 맥 기본 bash 3.2 · 리눅스

- **Setup**: P1–P6.
- **Run**: 맥 CI(bash 3.2 · en_US.UTF-8)와 우분투.
- **Pass criterion**: 같은 결과.

## How to run

```bash
bash core/tests/test-project-pure-catalog.sh
```

## Pass criteria

- P1–P10 전부 통과, 기존 test-pure-catalog.sh 통과.
