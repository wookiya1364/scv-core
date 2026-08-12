# 강제 호출 — 조사 기록

2026-08-12. 235개 에이전트가 세 번에 걸쳐 조사하고 서로 반증한 결과. 배포된 물건과
문서를 직접 읽어서 확인한 사실만 적는다.

## 왜 시작했나

배포된 플러그인은 LLM 이 scv 명령을 쓰도록 **강제하지 못한다**. 전부 설명문(description)
이고, 모델이 안 쓰기로 고르면 그만이다. 대표님 표현: "LLM이 플러그인 안쓰고 그냥
그럴듯하게 대화를 만들거잖아."

## 확인 1 — 배포된 0.24.0 에는 유도 문구조차 없다

설치된 플러그인이 모델에게 보여주는 `scv:help` 설명문 전문:

```
Show SCV workflow + diagnose project + recommend next step. With an argument,
talk through an idea OR search the archive for past work — SCV picks the right
mode from your wording.
```

"언제 써라"가 없다. 15 개 커맨드 전부 그렇다. 유도 문구는 `develop` 에만 있고,
`v0.24.0` 태그는 그 작업보다 50 분 먼저 잘렸다. `/scv:update` 는 "최신입니다"라고
답한다 (VERSION 도 태그도 둘 다 0.24.0).

## 확인 2 — 훅은 이미 있는데 레버를 버리고 있다

배포 트리에 `UserPromptSubmit` 훅이 이미 등록돼 있고 매 턴 실행된다. 그런데:

```bash
printf '%s\n' "$PROMPT" | bash "$JOURNAL_APPEND" --speaker user >/dev/null 2>&1 || true
exit 0
```

stdout 이 모델에게 문맥을 주입하는 통로인데 `/dev/null` 로 버린다. 배포 트리 전체에
`PreToolUse` / `permissionDecision` 검색 결과 **0 건**.

## 확인 3 — 차단은 두 호스트 다 된다 (재현함)

Codex 에서 실제로 재현했다. 임시 프로젝트에서 PLAN.md 를 손으로 쓰라고 시키니:

```
Command blocked by PreToolUse hook: ZQ9 GATE: no PLAN.md may be written by hand.
```

PLAN.md 는 만들어지지 않았다. SCV 자체 문서
(`scv-codex/plugins/scv/references/journal-hooks.md:18-24`) 가 "Codex 는 이게 안 된다"
고 적어놨는데 **그게 틀렸다**.

같은 재현에서 자기 차단 함정도 그대로 터졌다 — 로그 세 번째 줄이
`Command: scv:promote` 를 막고 있다. 조잡한 가드는 자기가 지키려던 명령을 막는다.

## 확인 4 — 자기 차단 해법은 영수증이다

호스트가 발생시키는 이벤트로 영수증을 발급한다. 모델이 Bash 로 훅 이벤트를 위조할
수 없으므로, "진짜 scv 명령이 돌고 있다"는 사실만은 조작이 안 된다.

- Claude Code: `Skill` 도구 호출 (실제 대화 기록에서 확인:
  `"name":"Skill","input":{"skill":"scv:promote",...}`), 그리고 사용자가 직접 타이핑한
  경우를 위한 `UserPromptExpansion`. 후자를 빠뜨리면 자기 차단이 난다.
- Codex: 벤더된 Core 스크립트의 Bash 호출. 스킬 호출 이벤트가 없어서 이 방법뿐이고,
  따라서 Claude Code 보다 약하다 (모델이 스크립트를 직접 돌려 영수증을 위조 가능).

## 확인 5 — 우회로 11 개 중 6 개만 "명령이 없어서"였다

가설은 "명령 없는 정상 경로를 명령으로 바꾸면 오탐이 0 이 된다" 였다. 절반만 맞았다.

**1군 — 진짜로 명령이 없는 경로 (6 개)**

```
core/template/scv/PROMOTE.md:66-116          빠른 경로
core/integrations/loop-runner.md:52          외부 루프
scv-claude-code/README.md:221-223 (+ko/ja)   BMAD/GSD 조합
core/template/scv/raw/README.md:98-103       방법 B — 수동 작성
core/protocols/work.md:619                   "or by hand"
core/protocols/promote.md:517, :522          "by hand"
```

**2군 — 명령이 돌고 있는데도 막히는 경로 (5 개)**

```
core/protocols/help.md:60        .env 쓰기 — 첫 헬퍼(:88)보다 앞선다. 유일한 진짜 순서 자기차단
core/protocols/promote.md:100    .env SCV_PROMOTE_LANG
core/protocols/promote.md:430    <testDir>/*.spec.ts — scv/ 밖, 면제 대상 아님
core/protocols/routine.md:65     + 배포된 예제 3 개
set-models                       .env / .codex/config.toml — actions.json 에서 entrypoint:null
```

2 군이 더 나쁘다. 문서가 수동적으로 허용하는 게 아니라 **프로토콜이 모델에게
지시하는 내용**이기 때문이다.

## 확인 6 — 진짜 병목은 Rule B 의 탈출구였다

Rule B 의 두 번째 조건 "status: in_progress|testing 인 계획이 있으면 허용" 은 쓸 수도
없고 안전하지도 않다.

**쓸 수 없다.** `core/scripts/work.sh` 는 status 필드를 쓰지 않는다 (`:247`, `:253`
에서 읽기만 한다). 상태 전이는 `work.md:245-247` 의 모델 재량 산문이다. 이 저장소
아카이브 8 개 중 5 개가 지금도 `status: planned` 이고, `in_progress` 나 `testing` 인
것은 **하나도 없다**. 정상 작업 중에 거짓인 조건이다.

**안전하지 않다.** PLAN.md 는 `.md` 라 Rule B 면제고, Rule A 는 기존 파일 수정을
허용한다. 모델이 frontmatter 한 줄을 `in_progress` 로 고치면 세션 내내 저장소 전체가
열린다. 영수증이 아니라 **모델이 스스로 발급하는 토큰**이다.

→ 튜닝이 아니라 삭제. Rule B 는 영수증만 본다.

## 확인 7 — 해법: 영수증 인정 범위를 15 개 명령 전부로

`{work, codegen}` → 모든 scv 명령. 2 군 5 개 중 4 개가 이것만으로 풀린다. 남은
`help.md:60` 은 `.env` 쓰기를 새 Core 스크립트(`env-set.sh`)로 바꾸면 된다.

결과: SCV 자체 명령 15 개에서 오탐 0 개, 두 호스트 다.

대가는 명확하다. `action:status` 한 번이면 세션이 열린다. Rule B 가 보장하는 것은
"이 세션에서 SCV 를 썼다" 이지 "이 쓰기가 계획된 작업이다" 가 아니다. 후자는 CI
게이트가 머지 시점에 본다. **두 층이 다른 일을 한다.**

## 확인 8 — 일관성 테스트의 함정 두 개

**토큰 면제를 쓰면 안 된다.** `work.md:619` 의 `"via action:promote or by hand"` 는
`action:promote` 를 포함하므로 토큰 allowlist 방식이면 면제돼버린다. "명령으로 하거나,
손으로 하거나" 가 위반의 전형적 모양이라, 명령 토큰의 존재는 위반과 **양의 상관**이다.

**한국어를 검사해야 한다.** `raw/README.md`, `loop-runner.md`, `routines/README.md`,
routine 예제 8 개가 한국어 전용이다. 영어 문구만 훑으면 놓친다.

**검사기 위치.** `tools/export-core.sh` 는 `core/` 와 `tools/` 만 배포하므로 저장소
루트 `tests/` 는 배포되지 않는다. 반면 `core/tests/` 는 배포되고 해시로 고정된다
(`SHA256SUMS` 확인). 따라서 검사기는 루트 `tests/` 에 둔다 — `core/tests/` 에 두면
`test-host-neutral.sh:24` 의 금지 문자열 `/scv:` 를 자기가 포함해서 자기 테스트에
걸린다. (탐침 파일로 실제 확인함.)

## 확인 9 — Codex CI 가 가드를 금지하고 있다

`scv-codex/plugins/scv/tests/test-codex-plugin.sh:157` 이
`assert "hooks" not in manifest` 로 hooks 부재를 강제하고, `plugin-ci.yml:41` 이 그걸
돌린다. Claude 쪽도 `hooks/hooks.json:2` 설명이 "Non-blocking by contract" 이고
`adapter/README.md:22` 가 "registration must stay non-blocking" 이라고 적혀 있다.
같은 릴리스에서 안 바꾸면 한쪽은 CI 빨간불, 다른 쪽은 자기모순 문장 배포다.

`docs/wrapper-integration.md:147-151` 도 blocking 등록을 금지하지만, 이 파일은
`export-core.sh` 가 `docs/` 를 제외하므로 **배포되지 않는다**. 래퍼 작성자용으로
고치되, "배포 문서 모순" 요구에는 해당하지 않는다.

## 못 막는 것 (천장)

1. **`action:status` 한 번으로 세션이 열린다.** 오탐 0 의 대가. 정밀한 영수증을 쓰면
   2 군 5 개 denial 이 전부 돌아온다.
2. **Bash 로 쓰면 안 보인다.** `bash -c 'cat > src/foo.ts'`, `git checkout`,
   `sed ... > f.tmp && mv`. 이 중 둘은 배포 문서가 허용한다 (`sync.md:119` 옵션 [3]).
   `env-set.sh` 도 의도적으로 이 구멍을 쓴다 — 허용된 쓰기는 이름 있는 스크립트로,
   허용 안 된 쓰기는 도구 표면으로.
3. **기존 파일 수정은 항상 허용.** Rule A 는 생성만 막는다. PLAN.md 내용은 무방비다.
4. **`.md` 는 어디든 쓸 수 있다.** 면제 범위가 넓을 수밖에 없다.
5. **CI 게이트는 내용 품질을 안 본다.** 얇은 계획을 써서 아카이브하면 통과한다.
6. **훅 밖에서 일하면 안 보인다.** 사람이 에디터로, 외부 루프가 새 세션으로, 다른
   도구가 구동하는 경우.
7. **고친 문서가 설치된 프로젝트에 안 간다.** `SCV.md` 는 frontmatter 가 없어
   merge_policy 도 없고, `DECISIONS.md`/`TODO.md`/`journal/README.md` 는 `preserve` 라
   설치본에 영영 안 간다. `loop-runner.md` 는 손으로 복사하는 파일이다.
8. **래퍼 표면은 Core 가 못 본다.** 커맨드 본문은 투영되고 diff 검사되지만
   frontmatter 설명문, 래퍼 README, 어댑터 프로토콜은 손으로 쓴 것이라 Core 에서
   닿지 않는다. 새 일관성 테스트는 `core/` 만 검사한다. 이 구멍은 이번 릴리스로
   닫히지 않는다.

## 이 릴리스가 실제로 배송하는 것

배포되는 Core 문서 중 어느 것도 가드가 금지하는 행동을 허용하거나 지시하지 않는다
(배포되는 모든 언어에서). SCV 자체 명령 15 개는 두 호스트에서 오탐 없이 영수증을
발급한다. 유일한 순서 자기차단(`help.md:60`)이 닫힌다. 모델이 스스로 발급하던 잠금
해제 토큰이 사라진다. 그리고 문서와 가드가 어긋나면 CI 가 빨갛게 뜬다.

**모델이 계획 없이 코드를 못 쓰게 만드는 것은 아니다. 그렇게 하려면 제품을 따르는
게 아니라 제품을 무시해야 하도록 만드는 것이다.**
