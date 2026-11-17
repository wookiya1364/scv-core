# Test Plan — /scv:update — gh 없이 최신 버전 확인, 앱 · 터미널 어디서든 직접 올리기

## Overview

`/scv:update` 의 엔진(`../scv-claude-code/scripts/update.sh`)과 설명서를 본다. 가짜 `claude` 와 가짜 `git` 으로
상태(설치 범위와 버전, 태그 목록, 실패할 명령)를 파일로 들고, 엔진이 부른 명령을 기록해 견준다 — 실제 마켓 · 네트워크 ·
설치본은 건드리지 않는다. 틀은 `tests/test-mods.sh` 의 가짜 `claude` 를 따른다. 대화에서 나온 요구 둘
(① `gh` 없이 최신 버전이 읽힌다 ② 앱 · 터미널 어디서든 직접 올라간다 ③ 한 번에 모드까지 오른다 ④ 모드도 깔린 범위마다 오른다)이
T1 · T3 · T14 · T18 이고, 나머지는 그 넷을 지키는 경계다.

## Test scenarios

### T1. gh 가 없어도 최신 버전이 읽힌다

- **Setup**: PATH 에 `gh` 가 없다. 가짜 `git` 이 태그 줄 `v0.93.3` · `v0.94.0` 을 낸다. 설치 버전은 0.85.2.
- **Run**: 인자 없이 엔진을 실행.
- **Expected**: `LATEST_VERSION: 0.94.0`, `UP_TO_DATE: no`. 설치 버전이 0.94.0 이면 `UP_TO_DATE: yes`.
- **Pass criterion**: 출력에 "unavailable" 이 0번, 위 두 줄이 그대로 나옴. 엔진 파일 안에 `gh` 를 부르는 줄이 0곳.

### T2. 최신 버전 고르기 — 숫자로 견주고 정식 태그만 센다

- **Setup**: 태그 줄 `v0.9.0` · `v0.10.0` · `v0.94.0` · `v0.94.0-codex.1` · `v1.0.0-rc.1` · `channel-dev` · 빈 줄 · `nightly`.
- **Run**: 순수 함수 `update_latest_version` 에 그 줄들을 넘김.
- **Expected**: `0.94.0`. (`0.10.0` 이 `0.9.0` 보다 높게 견줘진다. 접미사 붙은 것과 이름 태그는 세지 않는다.)
- **Pass criterion**: 출력이 정확히 `0.94.0` 한 줄. 정식 태그가 하나도 없으면 빈 값.

### T3. 새 버전이 있으면 직접 올린다 — 명령 두 줄, 순서대로

- **Setup**: 설치 `user 0.85.2`, 최신 0.94.0. 가짜 `claude` 가 올리기 뒤 버전을 0.94.0 으로 바꾼다.
- **Run**: 엔진을 `apply` 로 실행.
- **Expected**: 가짜 `claude` 가 받은 명령이 순서대로 `marketplace update scv-claude-code` → `update scv@scv-claude-code` (범위 user).
  출력에 앞뒤 버전(0.85.2 → 0.94.0)이 든 RESULT 줄과 "새 세션을 열면 적용" NEXT 줄. 종료 코드 0.
- **Pass criterion**: 기록된 명령 2줄이 위 순서와 같음 · RESULT 줄에 두 버전이 모두 있음 · 종료 코드 0.

### T4. 이미 최신이면 아무 명령도 실행하지 않는다

- **Setup**: 설치 `user 0.94.0`, 최신 0.94.0.
- **Run**: `apply`.
- **Expected**: 바꾸는 명령 기록 0줄. RESULT 가 "이미 최신 0.94.0". NEXT(새 세션) 줄 없음. 종료 코드 0.
- **Pass criterion**: 기록에 `marketplace update` · `update` 가 0번 · 출력에 새 세션 안내 0번.

### T5. 설치 범위가 둘이면 범위마다 올린다

- **Setup**: 설치 `user 0.85.2` 와 `project 0.85.2`, 최신 0.94.0.
- **Run**: `apply`.
- **Expected**: `marketplace update` 1번, `update` 2번(범위 user 한 번, project 한 번). RESULT 에 범위별 앞뒤 버전.
- **Pass criterion**: 기록된 `update` 줄이 정확히 2줄이고 두 범위가 하나씩 있음.

### T6. 앞 단계가 실패하면 멈추고 실패라고 말한다

- **Setup**: 가짜 `claude` 가 `marketplace update` 에서 오류 문구와 함께 실패한다.
- **Run**: `apply`.
- **Expected**: `update` 는 실행되지 않는다. RESULT 가 실패한 단계 이름을 담고, NEXT 가 다음 행동 한 줄. 종료 코드 1.
- **Pass criterion**: 기록에 `update scv@` 0번 · 출력에 "올렸다"는 뜻의 성공 줄 0번 · 종료 코드 1 · 가짜가 낸 오류 문구가 출력에 그대로 있음.

### T7. claude 명령줄이 없으면 못 한다고 말하고 칠 명령을 안내한다

- **Setup**: `claude` 실행 파일 자리에 없는 경로를 준다.
- **Run**: `apply`.
- **Expected**: RESULT 가 실패(명령줄 없음), NEXT 가 터미널에서 칠 명령 두 줄(`claude plugin marketplace update …` · `claude plugin update …`). 종료 코드 1.
- **Pass criterion**: 종료 코드 1 · NEXT 에 두 명령이 그대로 있음 · 진단(인자 없음)은 같은 조건에서도 종료 코드 0.

### T8. 최신 버전을 못 읽어도 올리기는 되고, 진단은 이유를 말한다

- **Setup**: 가짜 `git` 이 실패한다(네트워크 없음). 설치 `user 0.85.2`, 가짜 `claude` 는 올리기 뒤 0.94.0.
- **Run**: 인자 없이 한 번, `apply` 로 한 번.
- **Expected**: 진단은 `LATEST_VERSION: (unavailable — <이유>)` · `UP_TO_DATE: unknown`, 종료 코드 0.
  `apply` 는 명령 두 줄을 실행하고 앞뒤 버전(0.85.2 → 0.94.0)으로 보고.
- **Pass criterion**: 진단 출력의 이유에 `gh` 라는 말이 없음 · `apply` 의 RESULT 에 두 버전이 있음.

### T9. 진단은 읽기만 하고, 출력 다섯 줄이 그대로다

- **Setup**: 임시 프로젝트 폴더(파일 몇 개)에서 실행. 가짜 `claude` 의 명령 기록을 비워 둔다.
- **Run**: 인자 없이 실행.
- **Expected**: 출력이 `INSTALLED_VERSION` · `MARKETPLACE_NAME` · `PLUGIN_NAME` · `LATEST_VERSION` · `UP_TO_DATE` 순서의 다섯 줄로 시작. 프로젝트 폴더의 파일 목록과 내용이 실행 전후 같음. 바꾸는 명령 기록 0줄.
- **Pass criterion**: 다섯 줄의 이름 · 순서 일치 · 폴더 전후 비교 차이 0 · 기존 `tests/test-mods.sh` 의 업데이트 진단 검사 통과.

### T10. 채널이 운영이 아니면 올리지 않는다

- **Setup**: 설치본이 개발(또는 스테이징) 채널이라고 읽히는 상태.
- **Run**: `apply`.
- **Expected**: 바꾸는 명령 0줄. `/scv:channel` 을 안내하는 한 줄. 채널은 그대로.
- **Pass criterion**: 기록에 `marketplace` · `update` · `install` · `uninstall` 0번 · 출력에 `/scv:channel` 이 1번 이상.

### T11. 설명서와 README 가 새 동작을 말한다

- **Setup**: 없음(파일 읽기).
- **Run**: `skills/update/SKILL.md` 와 README 세 언어판을 훑음.
- **Expected**: 설명서에 엔진을 `apply` 로 부르는 줄이 있고, "확인만 요청받으면 올리지 않는다"와 "새 세션을 열면 적용된다"가 있다.
  업데이트 방법으로 슬래시 명령(`/plugin marketplace update`)을 직접 치라고 시키는 안내와 "자동 실행 금지" 문구가 없다.
  설명 줄(description)이 "안내한다"가 아니라 "올린다"는 뜻이다. 모드도 함께 오른다는 말이 설명서에 있다.
- **Pass criterion**: `skills/update/SKILL.md` 에서 `/plugin marketplace update` 0곳 · README 세 판에서 그 명령으로 시작하는 줄(명령 칸의 안내) 0곳이고 `/scv:update` 안내가 있음 · `apply` 호출 줄 1곳 이상.
  (README 의 슬래시 명령 두 줄은 터미널용 참고 한 줄로 남는다 — 코어의 README 검사가 요구한다.)

### T12. 두 셸에서 같은 결과

- **Setup**: 맥 기본 셸(bash 3.2)과 새 셸(bash 5).
- **Run**: 새 시험 파일을 두 셸로 실행.
- **Expected**: 통과 수가 같고 실패 0.
- **Pass criterion**: 두 실행 모두 끝 줄이 `FAIL=0` 이고 `PASS=` 의 수가 서로 같음.

### T13. 실제 환경에서 한 번 — gh 없이 진단

- **Setup**: 실제 설치본. PATH 에서 `gh` 가 있는 폴더를 뺀다(임시로, 그 명령 한 번에만).
- **Run**: 고친 엔진을 인자 없이 실행.
- **Expected**: 실제 최신 버전이 읽힌다. 걸린 시간을 잰다.
- **Pass criterion**: `LATEST_VERSION:` 이 `x.y.z` 꼴 · 출력을 사용자에게 그대로 보임 · 걸린 시간을 마무리 보고에 적음.
  (실제로 버전이 오르는 것은 다음 릴리스 때 앱 세션에서 본다 — 이 시나리오의 범위 밖, "확인 못 한 것"에 적는다.)

### T14. /scv:update 한 번에 모드까지 오른다

- **Setup**: 본체 `user 0.85.2`(최신 0.94.0), 모드 마켓 있음, 모드 `scv-dashboard user 0.2.19`. 가짜 `claude` 가 올리기 뒤 본체 0.94.0 · 모드 0.2.25 로 바꾼다.
- **Run**: 업데이트 엔진을 `apply` 로 한 번 실행.
- **Expected**: 기록된 명령에 본체 두 줄(마켓 새로 받기 → 본체 올리기) 다음에 모드 두 줄(모드 마켓 새로 받기 → 모드 올리기)이 순서대로 있다. 출력에 본체 결과(0.85.2 → 0.94.0)와 모드 결과(0.2.19 → 0.2.25)가 따로 있다.
- **Pass criterion**: 명령 4줄이 위 순서 · 본체 RESULT 1줄과 모드 RESULT 1줄이 모두 있음 · 종료 코드 0.

### T15. 본체가 이미 최신이어도 모드는 올린다

- **Setup**: 본체 `user 0.94.0`(최신 0.94.0), 모드 `scv-dashboard user 0.2.19`, 올리기 뒤 0.2.25.
- **Run**: `apply`.
- **Expected**: 본체 쪽 바꾸는 명령 0줄, 모드 쪽 명령 2줄. 본체는 "이미 최신", 모드는 0.2.19 → 0.2.25.
- **Pass criterion**: 기록에 본체 올리기 0번 · 모드 올리기 1번 · 두 결과 줄이 모두 있음.

### T16. 모드 마켓이나 설치된 모드가 없으면 모드 쪽은 아무것도 하지 않는다

- **Setup**: 두 경우 — (가) 모드 마켓이 없음 (나) 마켓은 있고 설치된 모드가 없음.
- **Run**: `apply`.
- **Expected**: 모드를 바꾸는 명령 0줄(마켓을 새로 추가하지도 않는다). 본체 결과는 그대로. 종료 코드는 본체 결과만 따른다.
- **Pass criterion**: 기록에 `marketplace add` 0번 · 모드 `update` · `install` 0번 · 본체 RESULT 가 T3 과 같음.

### T17. 모드가 실패해도 본체 결과를 가리지 않는다

- **Setup**: 본체는 올라가고, 가짜 `claude` 가 모드 마켓 새로 받기에서 실패한다.
- **Run**: `apply`.
- **Expected**: 본체 RESULT 는 올라간 그대로(0.85.2 → 0.94.0). 모드 RESULT 는 실패와 다음 행동 한 줄. 종료 코드 1.
- **Pass criterion**: 본체 RESULT 에 두 버전이 있음 · 모드 RESULT 에 실패가 있음 · 종료 코드 1 · "모두 올렸다"는 뜻의 줄 0번.

### T18. 같은 모드가 두 범위에 깔려 있으면 범위마다 올린다

- **Setup**: 모드 `scv-dashboard` 가 `user 0.2.19` 와 `project 0.2.19` 로 둘 다 깔려 있다. 올리기 뒤 0.2.25.
- **Run**: 모드 엔진을 직접(`/scv:mods` 의 길) 한 번, 업데이트 엔진의 `apply` 로 한 번.
- **Expected**: 두 길 모두 모드 올리기 명령이 2번(범위 user 한 번, project 한 번). RESULT 가 범위별로 앞뒤 버전을 말한다.
- **Pass criterion**: 기록된 모드 올리기 줄이 정확히 2줄이고 두 범위가 하나씩 · 고치기 전에는 이 시나리오가 실패함(1줄)을 먼저 봄.

### T19. 모드가 한 범위에만 깔려 있으면 지금과 같다

- **Setup**: 기존 모드 시험의 상태 그대로.
- **Run**: `tests/test-mods.sh` 전체.
- **Expected**: 고치기 전과 통과 수가 같고 실패 0 — 부르는 명령과 출력 줄이 그대로다.
- **Pass criterion**: 엔진을 보는 검사의 기대값을 바꾸지 않고 실패 0. (범위 칸 때문에 기대값을 바꿔야 하면 멈추고 사용자에게 묻는다.)
  바뀌는 것은 한 줄뿐이다 — "업데이트 설명서에 모드라는 말이 없어야 한다"는 검사는 오늘 요구(업데이트가 모드까지 올림)와 반대라
  "모드도 함께 올린다고 말한다 · 인자는 여전히 없다"로 바꾼다.

### T20. 확인만 하는 진단은 모드도 건드리지 않는다

- **Setup**: 모드가 옛 버전으로 깔려 있다.
- **Run**: 업데이트 엔진을 인자 없이 실행.
- **Expected**: 모드 쪽 명령 0줄. 출력은 T9 의 다섯 줄.
- **Pass criterion**: 기록에 모드 마켓 · 모드 이름이 든 바꾸는 명령 0번.

## How to run

```bash
/bin/bash ../scv-claude-code/tests/test-update.sh && bash ../scv-claude-code/tests/test-update.sh && bash ../scv-claude-code/tests/test-mods.sh
```

## Pass criteria

- 위 명령이 종료 코드 0 — 새 시험(T1~T12 · T14~T20)이 두 셸에서 실패 0, 기존 모드 시험이 그대로 통과.
- T13 의 실제 출력을 사용자에게 보였고, 사용자가 "이대로 계속"을 골랐다.
- 고치기 전 코드에서 새 시험의 실패 수가 1 이상이었다(그 수를 마무리 보고에 적는다).

## Related Documents

- 같은 틀의 시험: `../scv-claude-code/tests/test-mods.sh`
