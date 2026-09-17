# Test Plan — 매 턴 라우터 다이어트 — 답 모양은 남기고 나머지는 압축, 진단 안내문은 직접 부를 때만

## Overview

라우터가 작아졌는데 계약은 그대로인지(남겨야 할 절은 바이트 동일, 기록 계약·명령은 존재), 진단 다듬기가 훅 경로에서만 안내문을 빼고 직접 호출은 그대로인지, 상한이 잠겼는지를 본다. 바이트 측정은 core/protocols 원본 기준(SKILL.md 는 래퍼가 자리표시자를 펼쳐 조금 더 크다).

## Test scenarios

### T1. 라우터 크기
- **Setup**: 없음
- **Run**: `wc -c core/protocols/help.md`
- **Expected**: ≤ 7,200B (사용자 결정 2026-09-16: 손대지 않는 세 절 4,529B + 고정 문구·명령 ≈1,000B 가 바닥이라 7,000 은 못 미침). budget T1 상한 7,500B 통과.
- **Pass criterion**: 두 숫자 모두 만족.

### T2. 남겨야 할 세 절은 바이트 그대로
- **Setup**: `git show develop:core/protocols/help.md` 를 기준으로.
- **Run**: "## Language preference" · "## Plain language first" · "## Answer shape" 세 절을 awk 로 잘라 md5 비교.
- **Expected**: 세 절 모두 동일. run-dry [15p] 통과(PLAIN_N=13 유지, 공통 문구 1개).
- **Pass criterion**: md5 셋 일치 + run-dry 녹색.

### T3. 배경 조사 절은 full.md 로 통째 이동
- **Setup**: 없음
- **Run**: help.md 에 "## Deep questions go to a background investigator" 없음, full.md 에 있음, 절 본문이 develop 의 help.md 절과 동일.
- **Expected**: 위치만 바뀜. `test-delegate-effort.sh` 녹색(절 경로 갱신).
- **Pass criterion**: 세 조건 모두.

### T4. 기록 계약은 라우터에 남는다
- **Setup**: 없음
- **Run**: help.md 에 `protocol: <fingerprint>` · "Append, never overwrite" · `help.sh" --with-context` · `help-state.sh" mark` · `journal-append.sh" --redact-only` · "PROTOCOL: load" · "PROTOCOL: loaded" 가 각각 있다.
- **Expected**: 전부 존재. `test-help-echo.sh`·`test-help-load-once.sh`·budget T2/T3 녹색.
- **Pass criterion**: grep 7건 + 세 검사 녹색.

### T5. 상한 잠금
- **Setup**: 없음
- **Run**: `test-help-budget.sh` (BODY 7,500 · TURN 9,500 · FULL 9,000 · TOTAL 32,000)
- **Expected**: T1·T12 포함 전부 통과. 상한을 0.50.0 값(10,000/12,000)으로 되돌려도 통과(하향만 했음).
- **Pass criterion**: 녹색.

### T6. 훅의 전체 진단에는 안내문이 없다
- **Setup**: 임시 프로젝트(표식 없음 → 첫 턴은 full).
- **Run**: on-user-prompt.sh 실행 → 출력의 preflight 블록.
- **Expected**: "Current project diagnosis" 있음, 의존성 줄들·raw/archive 줄 있음, "Recommended next action" 제목 + 첫 내용 줄 있음, "Learn more" 없음, `hydrate.sh" init` 줄 없음, 블록 ≤ 2,000B. 같은 디렉터리에서 `help.sh` 를 직접 실행하면 "Learn more" 와 hydrate 명령이 그대로 있다.
- **Pass criterion**: 두 출력 비교.

### T7. brief/full 전환은 그대로
- **Setup**: T6 의 임시 프로젝트.
- **Run**: 같은 세션 번호로 훅 두 번.
- **Expected**: 첫 번째 full(다듬은 진단), 두 번째 "진단 변동 없음" 한 줄. 진단이 바뀌면(raw 파일 추가) 세 번째는 다시 full.
- **Pass criterion**: 세 출력의 모양.

### T8. 순수부 — 다듬기 함수
- **Setup**: lib/force-help.sh source.
- **Run**: `scv_force_trim_diagnosis` 에 (a) 진단+권장+Learn more 전체, (b) Learn more 없는 출력, (c) 진단 제목이 없는 출력, (d) 권장 행동 제목만 있고 내용 줄 없음.
- **Expected**: (a) 진단 + 권장 제목 + 첫 내용 줄, Learn more 없음 · (b) 진단 + 권장 첫 줄 · (c) 입력 그대로 · (d) 진단 + 권장 제목. `check-purity.sh` 통과.
- **Pass criterion**: 네 경우 정확 일치 + 순수성.

### T9. 기존 검사 회귀 없음
- **Setup**: 없음
- **Run**: `for f in core/tests/test-*.sh` 전부 · `core/tests/run-dry.sh` · `tests/run.sh`
- **Expected**: 전부 녹색.
- **Pass criterion**: 실패 0.

## How to run

```bash
bash core/tests/test-help-router-diet.sh && bash core/tests/test-help-budget.sh && bash core/tests/test-delegate-effort.sh
```

## Pass criteria

- T1~T9 전부 녹색.
- 실사용 한 세션(5턴 이상)에서 변동 없는 턴의 훅+라우터+헬퍼 합이 9.5KB 이하, 변동 턴 preflight 에 "Learn more" 없음.

## Related Documents

- core/tests/test-help-budget.sh — 상한 검사(기존)
