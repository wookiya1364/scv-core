# Test Plan — SCV 모드 명령 셋 — 인자 없이 업데이트 · 설치 · 삭제

## Overview

사용자가 요청한 동작(업데이트 · 목록 · 설치 · 삭제, 모두 인자 없이)과 인증 안내 · 다시 불러오기 안내 · Codex 안내가 각각 하나
이상의 시나리오로 고정된다. 엔진은 가짜 `claude` 명령(PATH 대신 `SCV_CLAUDE_BIN`)으로 시험해 네트워크 없이 돈다. 실제 확인은
Exit criteria 의 이 맥 실행으로 한다. (명령 모양을 바꾼 결정 — 2026-10-22 선택 창 '명령 3개' — 뒤에 시나리오를 다시 적었다.)

## Test scenarios

### T1. 업데이트 명령은 그대로

- **Run**: `/scv:update` 진단 스크립트.
- **Pass criterion**: 출력 키 5개(`INSTALLED_VERSION` … `UP_TO_DATE`) 그대로, 모드 줄 없음, 업데이트 스킬에 모드 언급 없음.

### T2. /scv:mods — 인자 없이 업데이트 + 목록

- **Setup**: 가짜 상태 — scv-hello 745b604 설치, scv-other 설치 가능, 업데이트 뒤 9a1c2d3.
- **Pass criterion**: `RESULT: scv-hello updated 745b604 -> 9a1c2d3`, 이어서 `MOD: scv-hello installed 9a1c2d3` · `MOD: scv-other available`;
  다른 마켓 모드는 빠짐. 마켓이 없으면 아무것도 바꾸지 않고 `/scv:mods-install` 을 안내.

### T3. /scv:mods-install 보기 — 마켓이 없으면 추가부터

- **Pass criterion**: 호출이 `marketplace add wookiya1364/scv-mods` 한 번, 보기에 `MOD: scv-hello available`.

### T4. 설치 — 마켓 추가 → 설치, 이미 있으면 업데이트로

- **Pass criterion**: 마켓 없음 → `marketplace add` → `install scv-hello@scv-mods`, `RESULT: … installed …`, 다시 불러오기 안내;
  이미 설치됨 → install 0번, update 1번.

### T5. 업데이트 전후 버전 · 다시 불러오기는 바뀔 때만

- **Pass criterion**: 바뀌면 `updated old -> new` + 안내, 같으면 `up-to-date` + 안내 없음, 이름 없으면 설치된 모드 전부.

### T6. 삭제

- **Pass criterion**: `uninstall scv-hello@scv-mods` 한 번, `RESULT: scv-hello removed`, 다시 불러오기 안내.

### T7. 비공개 저장소 인증 실패

- **Pass criterion**: 종료 코드 0 아님, '설치됨' 없음, `gh auth login` · `gh auth setup-git` 안내, 이어지는 install 없음.

### T8. 스킬 셋 — 인자 없음, 설치 · 삭제는 선택 창

- **Pass criterion**: 세 스킬이 엔진을 부르고 `argument-hint: ""`, mods-install · mods-remove 에 `AskUserQuestion`, mods 는 묻지 않음.

### T9. Codex — 모드 없음

- **Pass criterion**: Codex 의 세 규약에 'Codex has no SCV mods', 스킬 집합 = 코어 명령 19개 (test-codex-plugin.sh · verify-core.sh).

### T10. 순수 단계 — 같은 입력 같은 출력

- **Pass criterion**: 계획 · 요약 함수 두 번 같은 출력, 가짜 claude 호출 0번.

### T11. 회귀 — 코어 · 두 래퍼

- **Pass criterion**: 코어 저장소 시험 · Codex 사본 코어 시험 · 두 래퍼 검증(새 코어를 넣은 사본) · 두 래퍼 CI 실패 0
  (맥에서 원래 실패하던 Codex 검사 둘은 develop 에서도 같은지로 판정).

## How to run

```bash
bash ../scv-claude-code/tests/test-mods.sh
```

## Pass criteria

- T1–T11 모두 통과.
- 이 맥에서 실제로 `/scv:mods` 한 번에 업데이트 + 목록(Exit criteria).

## Related Documents
