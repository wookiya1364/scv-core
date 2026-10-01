# Test Plan — 자동 알림은 사람 턴이 아니다 · PR 은 저장소 브랜치 규칙대로

## Overview

자동 입력(호스트 설정의 머리말로 시작하는 입력)이 새 턴을 열지 않는지 — 새 턴 표 · 등록 안내 · 종료 차단 · 도움말 다시 읽기 횟수가
없고 예약 경고는 다음 사람 턴으로 미뤄지는지 — 와, 머리말이 비면 모든 출력이 지금과 같은지를 본다. PR 도구는 설정한 대상 브랜치로
PR 을 열고, SCV 기록은 함께 올리며, 그 밖에 커밋 안 된 변경이 있으면 아무것도 하지 않고 멈추는지를 본다. 대화에서 나온 요구가
하나씩 시나리오다(최소 요구 — 빼지 않는다).

## Test scenarios

### T1. 자동 입력 판별 — 순수 함수

- **Setup**: 머리말 목록 `<machine-event> <other-event>`(중립 픽스처).
- **Run**: `scv_mp_prompt_kind` 에 여러 입력.
- **Expected**: 머리말로 시작 → auto, 앞 공백 · 줄바꿈 뒤 머리말 → auto, 중간에 머리말이 든 글 → human, 빈 목록 → human, 두 번째
  머리말 → auto, 빈 입력 → human.
- **Pass criterion**: 모든 경우가 기대값과 같다.

### T2. kind 하위 명령 — 호스트 설정을 읽는다

- **Setup**: 호스트 설정에 `SCV_AUTO_PROMPT_PREFIXES=<machine-event>` 있는 경우 · 없는 경우.
- **Run**: 프롬프트를 표준 입력으로 `model-prompting.sh kind`.
- **Expected**: 있을 때 머리말 입력 → `auto`, 없을 때 → `human`. 모델별 프롬프팅 스위치 off 여도 판별은 같다.
- **Pass criterion**: 출력이 기대값과 같다.

### T3. 자동 입력 턴 — 새 턴을 열지 않는다

- **Setup**: 요구 항목 목록이 있는 임시 저장소, 머리말 설정, 사람 턴을 한 번 등록.
- **Run**: 머리말로 시작하는 입력으로 매 턴 훅 실행.
- **Expected**: 턴 표 파일이 바뀌지 않는다, 훅 출력에 등록 안내 · 첫 행동 지시 · 진단이 없다, 자동 표시 파일 = 지금 표, 등록 전
  파일 쓰기 거절이 없다(직전 등록 유효).
- **Pass criterion**: 네 조건 모두.

### T4. 종료 훅 — 자동 턴은 판정을 건너뛰고, 다음 사람 턴은 지금처럼

- **Setup**: T3 직후.
- **Run**: (a) 인용 없는 답으로 종료 훅 (b) 사람 입력으로 훅 → 등록 없이 종료 훅.
- **Expected**: (a) 막지 않는다(`STOP_GATE: auto`) (b) 새 표가 생기고, 등록이 없으니 지금처럼 막는다.
- **Pass criterion**: 두 결과 모두.

### T5. 예약 경고는 다음 사람 턴으로

- **Setup**: 예약 경고 파일이 있는 상태.
- **Run**: 자동 입력 턴 → 사람 입력 턴.
- **Expected**: 자동 턴 출력에 경고가 없고 파일도 남아 있다. 사람 턴 출력에 경고가 실리고 파일이 지워진다.
- **Pass criterion**: 두 턴 모두 기대대로.

### T6. 도움말 다시 읽기 횟수는 자동 턴을 세지 않는다

- **Setup**: 다시 읽기 간격을 작게(예: 2).
- **Run**: 사람 턴 → 자동 턴 여러 번 → 사람 턴.
- **Expected**: 도움말 상태의 턴 수가 사람 턴만큼만 오른다.
- **Pass criterion**: 턴 수가 기대값과 같다.

### T7. 머리말이 비면 지금과 같다

- **Setup**: 머리말 설정 없음(기본).
- **Run**: 머리말로 시작하는 입력을 포함해 매 턴 훅 · 종료 훅.
- **Expected**: 출력 · 턴 표 동작이 이 기능 전과 같다(새 표, 등록 안내, 종료 판정).
- **Pass criterion**: 이 기능 전 기대값과 같다.

### T8. PR 대상 브랜치 — 순수 함수

- **Setup**: (에픽, 설정, origin 기본) 조합.
- **Run**: `scv_pr_base_branch`.
- **Expected**: 에픽 있음 → `epic/<slug>`, 설정 있음 → 설정값, 둘 다 없음 → origin 기본, 그것도 없음 → main.
- **Pass criterion**: 모든 조합이 기대값과 같다.

### T9. PR 도구 실행 — 설정한 대상 브랜치로 연다

- **Setup**: 가짜 gh(인자 기록), 임시 저장소, 보관된 계획.
- **Run**: 설정 `SCV_PR_BASE=develop` / 설정 없음으로 PR 도구(`--no-push`).
- **Expected**: 기록된 `gh pr create` 인자의 대상이 각각 develop / 지금과 같은 기본.
- **Pass criterion**: 두 경우 모두.

### T10. PR 커밋 범위 — SCV 기록은 함께, 그 밖의 커밋 안 된 변경은 멈춤

- **Setup**: (a) 보관 폴더 밖 구현 파일이 수정 · 미커밋 (b) SCV 폴더(작업 기록 · 대화)만 수정 (c) 결과 폴더만 있음.
- **Run**: PR 도구.
- **Expected**: (a) exit 1, 파일 목록과 할 일 안내, 새 커밋 · gh 호출 없음 (b) SCV 변경이 보관 폴더와 같은 커밋에 들어감
  (c) 멈추지 않음. `--dry-run` 은 (a) 에서도 멈추지 않고 경고만.
- **Pass criterion**: 세 경우와 dry-run 모두.

### T11. 매 턴 크기 · 고정 절 불변

- **Setup**: 기능 전후.
- **Run**: `test-help-budget.sh`, `test-help-router-diet.sh`, `test-help-shape.sh`.
- **Expected**: 매 턴 스택 수치가 같고(9192B), 고정 절 지문 · 답 모양 검사 통과.
- **Pass criterion**: 통과 + 수치 동일.

### T12. 두 호스트

- **Setup**: 코덱스 벤더 도구로 만든 임시 사본.
- **Run**: 사본에서 코어 검사 전부.
- **Expected**: 모두 통과.
- **Pass criterion**: 실패 0.

### T13. 맥 · 리눅스

- **Setup**: 맥 기본 bash 3.2, 최신 bash, CI 두 OS.
- **Run**: 새 검사 전부. 새 변수를 비운 채로도 한 번.
- **Expected**: 모두 통과. CI 두 OS 로그에서 새 검사 줄이 각각 보인다.
- **Pass criterion**: 실패 0, 로그 두 곳 확인.

### T14. 기존 검사 전부

- **Setup**: 저장소 전체.
- **Run**: CI 와 같은 순서의 전체 검사(계약 · 계획서 형식 · 가드 일치 · 공유 회귀 · 코어 검사 전부).
- **Expected**: 모두 통과.
- **Pass criterion**: 실패 0.

## How to run

```bash
bash core/tests/test-model-prompting.sh && bash core/tests/test-pr-base.sh && bash core/tests/test-help-budget.sh && bash core/tests/test-help-router-diet.sh
```

## Pass criteria

- T1–T14 전부 통과, 두 OS CI 로그 확인, 코덱스 사본 통과. 릴리스 · 설치본 실측은 PLAN 의 Exit criteria 로 확인한다.

## Related Documents

- 대화: `scv/conversations/20261001-083005-auto-turns-pr-base-fixes.md`
