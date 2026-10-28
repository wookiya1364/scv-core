# Test Plan — CI 단축 — 시험을 여러 워커로 나눠 Contracts 3분 안에, 문서 · 버전 PR 은 무거운 시험 건너뛰기

## Overview

시험 실행 도구가 (1) 시험을 동시에 돌려 시간을 줄이고, (2) 실패를 숨기지 않으며, (3) 속도 검사를 끝에 혼자 돌리는지 확인한다.
가짜 시험 폴더로 도구 자체를 시험하고, 실제 64개 시험과 PR CI 실행 기록으로 시간을 잰다.

## Test scenarios

### T1. 모두 통과하면 0 으로 끝난다

- **Setup**: 가짜 시험 폴더 — 통과하는 시험 3개.
- **Run**: 도구를 그 폴더에 돌린다.
- **Expected**: 시험마다 통과 줄 하나와 걸린 초, 마지막 줄에 통과 3 · 실패 0.
- **Pass criterion**: 종료 코드 0, 통과 줄 3개.

### T2. 하나라도 실패하면 실패로 끝나고 이름과 로그 전문이 보인다

- **Setup**: 통과 2개 + 실패 1개(고유한 문구를 찍고 1 로 끝남).
- **Run**: 도구를 돌린다.
- **Expected**: 실패한 시험 이름이 실패 목록에 있고, 그 시험이 찍은 고유 문구가 출력에 그대로 있다.
- **Pass criterion**: 종료 코드 0 이 아님, 실패 이름 · 고유 문구 모두 출력에 있음.

### T3. 혼자 표시가 붙은 시험은 다른 시험과 겹치지 않고 끝에 돈다

- **Setup**: 동시에 돌 시험 3개(각각 시작 · 끝 시각을 파일에 남김) + 혼자 표시 시험 1개(같은 방식).
- **Run**: 동시 수 3 으로 도구를 돌린다.
- **Expected**: 혼자 시험의 시작 시각이 다른 모든 시험의 끝 시각보다 늦다.
- **Pass criterion**: 겹침 0.

### T4. 동시에 돈다(차례로가 아니다)

- **Setup**: 각각 2초 쉬는 시험 4개.
- **Run**: 동시 수 4 로 도구를 돌린다.
- **Expected**: 전체가 8초보다 훨씬 짧다.
- **Pass criterion**: 전체 5초 미만.

### T5. 동시 수를 정할 수 있고, 1 이면 차례로 돈다

- **Setup**: T4 와 같은 폴더.
- **Run**: 동시 수 1 로 돌린다.
- **Expected**: 차례로 돌아 8초 이상.
- **Pass criterion**: 전체 8초 이상, 통과 4.

### T6. 가르기(classify)와 요약(summarize)은 순수하다

- **Setup**: 파일 이름 목록과 표시 줄 문자열, 결과 줄 문자열.
- **Run**: 두 함수를 같은 입력으로 두 번 부른다.
- **Expected**: 같은 출력, 파일 · 폴더를 만들지 않음.
- **Pass criterion**: 두 출력이 같고, 임시 폴더가 비어 있음.

### T7. bash 3.2 에서도 같다

- **Setup**: 시스템 bash(맥 /bin/bash 3.2).
- **Run**: T1 · T2 · T3 을 시스템 bash 로 돌린다.
- **Expected**: 같은 결과.
- **Pass criterion**: 세 시나리오 모두 통과.

### T8. 실제 시험 64개가 도구로 모두 통과한다(코어 · codex 사본)

- **Setup**: 이 저장소, 그리고 codex 도구로 만든 코어 사본(격리 폴더 이름 `core`).
- **Run**: 두 곳에서 도구로 집중 시험 전체를 돌린다.
- **Expected**: 실패 0. 시간 표가 찍힌다.
- **Pass criterion**: 두 곳 모두 실패 0.

### T9. PR CI 에서 Contracts (ubuntu-latest) 가 3분 안에, 맥은 동시 한도 안에서 크게 줄어든다

- **Setup**: 이 계획의 PR.
- **Run**: CI 를 두 번 이상 돌리고, 운영체제마다 첫 작업 시작부터 결과 작업 끝까지를 실행 기록에서 읽는다.
- **Expected**: 우분투 180초 이하. 맥은 처음(15~16분)보다 크게 짧다(맥 동시 한도 5대).
- **Pass criterion**: 두 실행 모두 통과 + 우분투 180초 이하 + 맥 처음의 절반 이하.

### T10. 일부러 실패시킨 CI 실행에서 실패가 보인다

- **Setup**: 실패하는 시험을 하나 넣은 임시 커밋(병합하지 않는 시험용 브랜치).
- **Run**: CI 를 돌린다.
- **Expected**: Contracts 작업 실패, 로그에 그 시험 이름과 출력.
- **Pass criterion**: 작업 실패 + 로그에 시험 이름.

### T11. 병합에 필요한 검사 이름이 그대로다

- **Setup**: 이 계획의 PR.
- **Run**: PR 검사 목록과 저장소 규칙의 필수 검사 목록을 비교한다.
- **Expected**: 이름이 모두 같다(Contracts (ubuntu-latest) · Contracts (macos-latest) · DeckUI · Deterministic release artifact · check).
- **Pass criterion**: 차이 0.

### T12. 조각 나누기는 고르고, 빠짐 · 겹침이 없다(순수)

- **Setup**: 시험 이름 10개와 시간 기록(한 개는 기록 없음).
- **Run**: 조각 수 3 으로 1/3 · 2/3 · 3/3 을 각각 고르고, 같은 입력으로 한 번 더.
- **Expected**: 세 조각을 합치면 원래 목록과 같다(빠짐 0 · 겹침 0). 가장 긴 시험은 혼자 한 조각에 간다. 같은 입력 → 같은 출력.
- **Pass criterion**: 합집합 = 원래 목록, 교집합 0, 두 번의 출력이 같음, 조각 합의 최대 − 최소 ≤ 가장 긴 시험.

### T13. 문서 · 버전 판정(순수)

- **Setup**: 바뀐 파일 목록 여러 벌.
- **Run**: 판정 함수에 넣는다.
- **Expected**: `VERSION`+`CHANGELOG.md` → yes, `docs/a.md` → yes, `README.md` → no(README 검사 대상), `core/protocols/help.md` → no(실행되는 규약), `.github/workflows/x.yml` → no, 빈 목록 → no(애매하면 전체).
- **Pass criterion**: 모든 경우가 기대와 같다.

### T14. 문서 · 버전만 바뀐 PR 에서 Contracts 두 개가 무거운 시험 없이 통과 보고

- **Setup**: docs/ 한 줄만 바꾼 시험용 PR(병합하지 않음).
- **Run**: CI 를 돌린다.
- **Expected**: 조각 작업이 건너뛰어지고, Contracts (ubuntu-latest) · Contracts (macos-latest) 는 통과.
- **Pass criterion**: 두 검사 통과 + 조각 작업 skipped.

### T15. 설정 불러오기는 한 번에 읽어도 값이 옛 길과 바이트까지 같다

- **Setup**: 공백 · $ · 따옴표 · 탭 · 줄바꿈 · 숫자 · true/false/null · 비밀 키 · 환경 우선이 섞인 설정 두 파일.
- **Run**: 키마다 settings_get(옛 길)과 env_load(새 길)를 같은 껍데기에서 비교.
- **Expected**: 값이 모두 같고, 일반 파일의 비밀 키는 알리되 값은 찍지 않는다.
- **Pass criterion**: `core/tests/test-env-load.sh` 통과(bash 5 · 3.2).

### T16. 맥 조각이 필요한지 판정(순수)

- **Setup**: 바뀐 파일 목록 여러 벌.
- **Run**: ci_needs_macos 에 넣는다.
- **Expected**: .md · VERSION 만 → no, .sh · 워크플로 · JSON 하나라도 → yes, 빈 목록 → yes.
- **Pass criterion**: `tests/test-ci-plan.sh` 통과.

## How to run

```bash
bash core/tests/test-run-focused.sh && bash core/tests/test-env-load.sh && bash tests/test-ci-plan.sh && bash core/tests/run-focused.sh --dir tests --dir core/tests --also core/tests/run-dry.sh
```

## Pass criteria

- T1–T8 · T12 · T13 · T15 · T16 은 로컬에서 통과, T9–T11 은 PR CI 실행 기록으로 확인, T14 는 병합 뒤 첫 문서 · 버전 PR 에서.
- 실패를 숨기는 경로가 없다(T2 · T10).
