# Test Plan — scv 명령 호출을 기계적으로 강제한다 (가드 훅 + 문서 정합)

## Overview

세 가지를 검증한다. **막아야 할 것을 막는가**(Rule A / Rule B 거부), **막지 말아야 할
것을 통과시키는가**(SCV 자체 명령 15 개, hydrate 안 된 프로젝트, 정상 편집), 그리고
**문서가 가드와 어긋나면 CI 가 잡는가**.

두 번째가 이 계획에서 제일 위험하다. 오탐이 나면 사용자가 가드를 통째로 꺼버리고,
그러면 아무것도 안 한 것과 같아진다. 그래서 T20(명령 15 개 전수)을 배포 차단 기준으로
둔다.

## Test scenarios

### T1. 영수증 없이 PLAN.md 생성은 거부된다 (Rule A)

- **Setup**: hydrate 된 임시 프로젝트. 영수증 디렉터리 비움.
- **Run**: `Write` 페이로드로 `scv/promote/x/PLAN.md` 생성 시도를 가드에 넣는다.
- **Expected**: `permissionDecision: "deny"`. 거부 사유에 명령 이름과 복구 방법이
  들어 있다.
- **Pass criterion**: 출력 JSON 의 `permissionDecision` 이 `deny` 이고,
  `permissionDecisionReason` 이 비어 있지 않다.

### T2. TESTS.md / FEATURE_ARCHITECTURE.md 도 같이 막힌다

- **Setup**: T1 과 동일.
- **Run**: 세 파일명 각각에 대해 생성 시도.
- **Expected**: 셋 다 거부.
- **Pass criterion**: 3/3 거부. 하나라도 통과하면 Rule A 에 구멍이 있는 것이다.

### T3. 기존 계획 파일 수정은 항상 허용된다

- **Setup**: `scv/promote/x/PLAN.md` 를 미리 만들어 둔다. 영수증 없음.
- **Run**: 같은 경로에 `Edit` 시도.
- **Expected**: 허용.
- **Pass criterion**: 거부되지 않는다. 이게 막히면 `<TODO>` 채우기와 상태 전이가
  전부 깨진다.

### T4. 영수증이 있으면 계획 생성이 허용된다

- **Setup**: `scv:promote` 영수증을 발급한 상태.
- **Run**: `scv/promote/x/PLAN.md` 생성 시도.
- **Expected**: 허용.
- **Pass criterion**: 거부되지 않는다.

### T5. Skill 이벤트가 영수증을 발급한다 (Claude Code)

- **Setup**: 영수증 없음.
- **Run**: `PreToolUse` / `Skill` 페이로드
  (`tool_input.skill = "scv:promote"`) 를 가드에 넣는다.
- **Expected**: 거부하지 않고, 영수증 파일이 생긴다.
- **Pass criterion**: 종료 코드 0 이고 영수증 파일이 존재한다.

### T6. 타이핑한 슬래시 명령도 영수증을 발급한다 (Claude Code)

- **Setup**: 영수증 없음.
- **Run**: `UserPromptExpansion` 페이로드(`command_name` = 명령 id)를 넣는다.
- **Expected**: 영수증 생성.
- **Pass criterion**: 영수증 존재. **이 시나리오가 빠지면 사용자가 직접 타이핑한
  경로에서 자기 차단이 난다** — `Skill` 이벤트가 안 뜨기 때문이다.

### T7. Codex 는 Core 스크립트 Bash 호출로 영수증을 발급한다

- **Setup**: 영수증 없음.
- **Run**: `PreToolUse` / `Bash` 페이로드로
  `bash <core>/scripts/promote-helper.sh` 를 넣는다.
- **Expected**: 허용 + 영수증 생성.
- **Pass criterion**: 영수증 존재. 어댑터 스크립트(`adapter/scripts/*.sh`) 로도 같은
  결과가 나와야 한다 — set-models / update / sync / hydrate 가 그 경로다.

### T8. 15 개 명령 전부가 영수증을 발급한다

- **Setup**: `core/actions.json` 의 id 목록을 읽는다.
- **Run**: 각 id 에 대해 T5 / T7 두 방식으로 영수증 발급을 시도한다.
- **Expected**: 15/15 발급.
- **Pass criterion**: 하나라도 발급 안 되면 실패하고 그 id 를 출력한다.

### T9. 영수증 없이 코드 파일 쓰기는 거부된다 (Rule B)

- **Setup**: hydrate 된 프로젝트, 영수증 없음.
- **Run**: `src/refund.ts` 에 `Write` 시도.
- **Expected**: 거부.
- **Pass criterion**: `permissionDecision: "deny"`.

### T10. 면제 파일은 영수증 없이도 허용된다 (Rule B)

- **Setup**: T9 와 동일.
- **Run**: `README.md`, `docs/x.md`, `.gitignore`, `.gitattributes`, `LICENSE`,
  `.codex/config.toml` 각각에 쓰기 시도.
- **Expected**: 6/6 허용.
- **Pass criterion**: 하나도 거부되지 않는다. 이 목록은 CI 게이트의 면제 목록과
  **정확히 같아야** 한다 — T21 이 그걸 검사한다.

### T11. `.env` 는 면제되지 않는다

- **Setup**: T9 와 동일.
- **Run**: `.env` 에 `Write` / `Edit` 시도.
- **Expected**: 거부.
- **Pass criterion**: 거부된다. 정당한 `.env` 쓰기는 `env-set.sh` 로 가야 한다.

### T12. status 탈출구가 사라졌다

- **Setup**: `scv/promote/x/PLAN.md` 를 `status: in_progress` 로 만들어 둔다.
  영수증은 **없음**.
- **Run**: `src/refund.ts` 에 쓰기 시도.
- **Expected**: 거부.
- **Pass criterion**: 거부된다. 통과하면 모델이 스스로 발급하는 잠금 해제 토큰이
  아직 살아 있다는 뜻이다.

### T13. hydrate 안 된 프로젝트에서는 무반응이다

- **Setup**: `scv/` 가 없는 임시 디렉터리.
- **Run**: `src/anything.ts` 생성, `promote/x/PLAN.md` 생성 둘 다 시도.
- **Expected**: 둘 다 허용, 출력 없음.
- **Pass criterion**: 종료 코드 0, stdout 비어 있음. 두 래퍼 저장소 자신이 여기
  해당한다 — 일부러 `scv/` 를 안 두고 있다.

### T14. 하위 디렉터리에서도 scv root 를 찾는다

- **Setup**: hydrate 된 프로젝트, `cwd` 를 `src/` 로.
- **Run**: T9 와 같은 거부 케이스.
- **Expected**: 거부.
- **Pass criterion**: 거부된다. `cwd` 기준 `[[ -d scv ]]` 로 짜면 여기서 조용히
  꺼진다 — 그 구현을 잡는 시나리오다.

### T15. 내부 오류는 열린 채로 실패한다 (fail-open)

- **Setup**: 가드에 잘못된 JSON 을 stdin 으로 준다. 그리고 별도로 영수증 디렉터리를
  쓰기 불가로 만든다.
- **Run**: 두 경우 각각.
- **Expected**: 허용 + stderr 에 한 줄.
- **Pass criterion**: 종료 코드 0, stdout 에 deny 없음, stderr 비어 있지 않음.

### T16. 가드 스크립트가 없어도 세션이 산다

- **Setup**: 등록은 돼 있는데 스크립트 파일을 지운다.
- **Run**: 아무 쓰기나.
- **Expected**: 정상 진행.
- **Pass criterion**: 쓰기가 성공한다.

### T17. Core 스크립트를 부르는 Bash 는 무조건 허용된다

- **Setup**: 영수증 없음.
- **Run**: `work.sh --archive`, `deck.sh`, `readpath.sh consume`, `sync.sh`,
  `hydrate.sh` 각각의 Bash 페이로드.
- **Expected**: 5/5 허용 + 영수증 발급.
- **Pass criterion**: 하나라도 거부되면 실패. 이들은 전부 `scv/` 안팎에 파일을
  쓰므로, 허용 안 하면 자기 차단이 난다.

### T18. 저널 훅 두 개는 여전히 non-blocking 이다

- **Setup**: 기존 `core/tests/test-journal.sh` 회귀.
- **Run**: `on-user-prompt.sh` 와 stop 훅에 잘못된 JSON / 빈 prompt / 미hydrate
  프로젝트를 준다.
- **Expected**: 전부 종료 코드 0, 아무것도 안 씀.
- **Pass criterion**: 기존 단언이 그대로 통과한다.

### T19. 호스트 중립 검사를 통과한다

- **Setup**: 가드 스크립트가 `core/template/hooks/` 에 있는 상태.
- **Run**: `bash tests/test-host-neutral.sh`
- **Expected**: 통과.
- **Pass criterion**: 종료 코드 0. `Claude`, `Codex`, `CLAUDE_PLUGIN_ROOT`,
  `/scv:` 같은 금지 문자열이 `core/` 안에 없어야 한다. 호스트 **이벤트 이름**은
  허용된다.

### T20. 빈 프로젝트에서 명령 15 개 전수 실증 (배포 차단 기준)

- **Setup**: 새 임시 프로젝트를 hydrate 하고 Rule A / Rule B 둘 다 켠다.
- **Run**: 15 개 명령을 순서대로 실제로 돌린다.
- **Expected**: 거부 0 건.
- **Pass criterion**: 하나라도 거부되면 **배포하지 않는다.** 오탐이 나면 사용자가
  가드를 꺼버리고, 그러면 이 릴리스 전체가 무의미해진다.

### T21. 가드와 CI 게이트의 면제 목록이 같다

- **Setup**: 가드의 면제 목록과 CI 게이트의 면제 목록을 각각 뽑는다.
- **Run**: 두 집합을 비교.
- **Expected**: 정확히 일치.
- **Pass criterion**: 차집합이 양쪽 다 비어 있다. 어긋나면 제품이 "코드 변경"의
  정의를 두 가지로 말하게 된다.

### T22. 일관성 테스트가 수정 전에는 빨갛다 (반전 검사)

- **Setup**: 문서 수정 커밋을 되돌린 트리.
- **Run**: `bash tests/test-guard-consistency.sh`
- **Expected**: 실패, 위반 문장 목록 출력.
- **Pass criterion**: 종료 코드 0 이 **아니어야** 한다. 수정 전에도 통과하면 검사기가
  no-op 라는 뜻이므로 이 시나리오가 그걸 잡는다. 수정 항목을 **하나씩** 되돌려도
  각각 빨개져야 한다.

### T23. 일관성 테스트가 한국어 문장을 잡는다

- **Setup**: `core/template/scv/raw/README.md` 에 "수동으로 직접 작성한다" 류 문장을
  하나 심는다 (임시).
- **Run**: `bash tests/test-guard-consistency.sh`
- **Expected**: 실패, 그 파일과 줄을 지목.
- **Pass criterion**: 한국어 문구를 잡는다. 영어만 검사하면 놓치는 파일이
  `raw/README.md`, `loop-runner.md`, `routines/README.md`, routine 예제 8 개다.

### T24. 일관성 테스트가 토큰 면제에 속지 않는다

- **Setup**: `"via action:promote or by hand"` 형태의 문장을 심는다.
- **Run**: `bash tests/test-guard-consistency.sh`
- **Expected**: 실패.
- **Pass criterion**: 잡는다. `action:promote` 토큰이 있다고 면제하면 안 된다 —
  "명령으로 하거나, 손으로 하거나"가 위반의 전형적 모양이다.

### T25. 명령을 추가하면 일관성 테스트가 빨개진다

- **Setup**: `core/actions.json` 에 16 번째 id 를 임시로 더한다.
- **Run**: `bash tests/test-guard-consistency.sh`
- **Expected**: 실패 — `guard.md` 의 영수증 집합과 불일치.
- **Pass criterion**: 잡는다. Rule B 설계 전체가 "모든 명령이 영수증을 발급한다"에
  기대고 있으므로, 이게 썩지 않게 막는 장치다.

### T26. 빠른 경로 단언 13 개가 그대로 통과한다

- **Setup**: `--fast` 추가와 §1.6 수정 후.
- **Run**: `bash core/tests/run-dry.sh`
- **Expected**: 기존 단언 전부 통과.
- **Pass criterion**: `:2189-2196`, `:2254-2263` 의 13 개가 수정 없이 통과한다.
  §1.6 은 **추가만** 하기로 했으므로 깨지면 안 된다.

### T27. env-set.sh 가 `.env` 를 안전하게 다룬다

- **Setup**: 네 경우 — 파일 없음 / 기존 파일에 키 추가 / 기존 키 치환 /
  `$` 와 공백이 든 줄이 있는 파일.
- **Run**: `bash core/scripts/env-set.sh KEY=VALUE`
- **Expected**: 네 경우 다 올바르고, 무관한 줄이 하나도 안 변한다.
- **Pass criterion**: `$` 가 든 줄과 공백이 든 줄이 바이트 단위로 보존된다.
  BSD/GNU 양쪽에서 동작한다 (`sed -i` 금지).

### T28. help 프로토콜의 순서 자기 차단이 닫혔다

- **Setup**: Codex 경로. 새 프로젝트에서 `action:help` 최초 실행.
- **Run**: 프로토콜대로 진행.
- **Expected**: `.env` 언어 설정이 거부되지 않는다.
- **Pass criterion**: 거부 없음. 수정 전에는 `.env` 쓰기(`:60`)가 첫 헬퍼
  호출(`:88`)보다 앞서서 영수증 없이 실행됐다 — 프로젝트 첫 사용이 벽돌이 되는
  경로다.

### T29. 두 호스트에서 실제 거부가 재현된다 (통합)

- **Setup**: Claude Code 와 Codex 각각에 가드를 등록한 임시 프로젝트.
- **Run**: 모델에게 "PLAN.md 를 직접 써라" 라고 지시한다.
- **Expected**: 두 호스트 다 거부되고 파일이 안 생긴다.
- **Pass criterion**: 파일 부재 + 거부 로그. Codex 는 이미 한 번 재현했지만
  벤더된 페이로드로 다시 확인한다.

### T30. Codex 훅 등록 경로가 실증된다

- **Setup**: `plugins/scv/hooks/hooks.json` (문서상의 기본 경로).
- **Run**: 임시 Codex 환경에서 훅이 실제로 로드되는지 확인.
- **Expected**: 로드됨.
- **Pass criterion**: 로드되면 `test-codex-plugin.sh:157` 을 유지한 채 진행한다.
  안 되면 매니페스트 `hooks` 키로 바꾸고 그 단언을 지운다. **배포 전에 반드시
  실증해야 하는 항목이다** — 지금은 문서 근거뿐이다.

## How to run

```bash
bash core/tests/test-guard.sh
```

T20 / T29 / T30 은 실제 호스트가 필요해서 위 스위트에 안 들어간다. 별도로 한 번씩
돌리고 결과를 기록한다.

## Pass criteria

- T1–T19, T21–T28 이 `test-guard.sh` 한 번으로 전부 통과한다.
- **T20 이 배포 차단 기준이다** — 명령 15 개 중 하나라도 거부되면 배포하지 않는다.
- T22 의 반전 검사가 성립한다 — 문서 수정을 하나씩 되돌릴 때마다 각각 빨개진다.
- T30 이 확인되기 전에는 Codex 쪽을 배포하지 않는다.
- 기존 `core/tests/run-dry.sh`, `tests/run.sh`, `tests/test-host-neutral.sh`,
  `core/tests/test-journal.sh` 가 회귀 없이 통과한다.
- 두 래퍼 CI 가 초록.

## Related Documents

- [`PLAN.md`](./PLAN.md)
