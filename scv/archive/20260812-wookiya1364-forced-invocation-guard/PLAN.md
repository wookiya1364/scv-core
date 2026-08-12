---
title: scv 명령 호출을 기계적으로 강제한다 (가드 훅 + 문서 정합)
slug: 20260812-wookiya1364-forced-invocation-guard
author: wookiya1364
created_at: 2026-08-12
status: planned
kind: feature
lang: korean
tags: [enforcement, hooks, guard, governance]
raw_sources:
  - scv/raw/stale/20260812-wookiya1364-forced-invocation.md
refs: []
invariants:
  - "배포되는 Core 문서 중 어느 것도 가드가 금지하는 행동을 허용하거나 지시하지 않는다 (배포되는 모든 언어에서)"
  - "SCV 자체 명령 15 개는 두 호스트에서 오탐 0 개로 통과한다"
  - "가드는 hydrate 되지 않은 프로젝트에서 완전히 무반응이다 (scv/ 없으면 즉시 허용)"
  - "가드 스크립트가 없거나 내부 오류가 나면 열린 채로 실패한다 (fail-open)"
  - "저널 훅 두 개(UserPromptSubmit, Stop)는 계속 non-blocking 이다"
  - "core/tests/run-dry.sh 의 빠른 경로 단언 13 개가 그대로 통과한다"
  - "core/tests/test-host-neutral.sh 의 금지 문자열 검사를 가드 스크립트가 통과한다"
  - "CI 프로버넌스 게이트와 가드의 면제 목록이 정확히 같다"
---

# scv 명령 호출을 기계적으로 강제한다 (가드 훅 + 문서 정합)

## Summary

배포된 플러그인은 LLM 이 scv 명령을 쓰도록 강제하지 못한다. 전부 설명문이고, 모델이
안 쓰기로 고르면 그만이다. 이 계획은 `PreToolUse` 가드 훅으로 **계획 파일을 손으로
만드는 것과 계획 없이 코드를 고치는 것을 실제로 거부**하게 만들고, 동시에 배포 문서가
가드와 모순되지 않도록 정리한 뒤 그 정합성을 CI 로 고정한다.

세 가지가 한 릴리스에 같이 나가야 한다. 가드만 먼저 내면 배포된 문서가 모델에게
"가드가 거부하는 짓을 하라"고 지시하는 상태가 된다.

## Goals / Non-Goals

- **Goals**
  - 계획 파일(`PLAN.md` / `TESTS.md` / `FEATURE_ARCHITECTURE.md`)을 명령 없이 새로
    만드는 것을 두 호스트에서 거부한다. (Rule A, 기본 켜기)
  - 세션에 scv 영수증이 없으면 `scv/` 밖 코드 파일 쓰기를 거부한다.
    (Rule B, 기본 켜기)
  - 배포되는 Core 문서에서 가드와 모순되는 문장을 전부 없앤다 — 한국어 문서 포함.
  - 그 정합성을 CI 테스트로 고정해서 다음 릴리스에서 다시 어긋나지 않게 한다.
  - SCV 자체 명령 15 개가 두 호스트에서 오탐 없이 돌게 한다.
- **Non-Goals**
  - 모델이 명령을 호출하도록 **강제**하기 — 훅은 도구 호출이 있어야 발동한다.
    파일을 안 건드리고 말로만 때우는 대화는 이 계획의 사정권 밖이다.
  - 쓰기 모양의 Bash 명령 파싱 (`bash -c 'cat > f'`) — 표면이 크고 부서지기 쉽다.
  - 계획의 **내용** 품질 심사.
  - 래퍼가 손으로 쓴 표면(커맨드 frontmatter 설명문, 래퍼 README, 어댑터 프로토콜)의
    정합성 검사 — Core 에서 닿지 않는다. 이번 릴리스로 안 닫힌다.

## Approach Overview

### 영수증 (receipt)

호스트가 발생시키는 이벤트로 발급한다. 모델이 Bash 로 훅 이벤트를 위조할 수 없으므로
"진짜 scv 명령이 돌고 있다"는 사실만은 조작이 안 된다.

| 호스트 | 발급 시점 |
|---|---|
| Claude Code | `Skill` 도구 호출, 그리고 사용자가 직접 타이핑한 경우 `UserPromptExpansion` |
| Codex | 벤더된 Core 스크립트 또는 어댑터 스크립트의 Bash 호출 |

`UserPromptExpansion` 을 빠뜨리면 자기 차단이 난다 — 사용자가 슬래시 명령을 직접
타이핑하면 `Skill` 이벤트가 안 뜬다.

영수증은 세션 단위로 저장소 **밖**에 쓴다 (`${SCV_GUARD_STATE}`, 기본값은 임시
디렉터리). 커밋되지 않고, 모델이 정상 작업 중 건드리는 경로가 아니다.

**인정 범위는 15 개 명령 전부다.** `{work, codegen}` 으로 좁히면 명령이 돌고 있는데도
막히는 경우가 5 개 생긴다.

### 두 규칙

**Rule A — 계획 위조 금지 (기본 켜기)**
영수증 없이 `<scv_root>/promote/*/PLAN.md`, `TESTS.md`, `FEATURE_ARCHITECTURE.md` 를
**새로 만드는 것**을 거부한다. 이미 있는 파일 수정은 언제나 허용 — `<TODO>` 채우기와
상태 전이가 정상 경로이기 때문이다.

**Rule B — 계획 없는 구현 금지 (기본 켜기)**
영수증이 없으면 `scv/` 밖 파일 쓰기를 거부한다. 면제: `*.md`, `.gitignore`,
`.gitattributes`, `LICENSE`, 그리고 호스트 설정(`.codex/config.toml`).

Rule B 의 두 번째 조건이었던 "`status: in_progress` 계획이 있으면 허용" 은 **삭제**
한다. 이유 둘: `work.sh` 가 status 필드를 아예 쓰지 않아 정상 작업 중에도 거짓이고,
PLAN.md 가 Rule B 면제(`.md`) 이면서 Rule A 수정 허용이라 **모델이 스스로 발급할 수
있는 토큰**이었다.

### 자기 차단을 막는 네 가지

1. 영수증이 명령 자신의 쓰기보다 **먼저** 발급된다 (`Skill` 이벤트가 스킬 본문의 모든
   도구 호출에 선행).
2. 사용자가 타이핑한 경로는 `UserPromptExpansion` 이 따로 덮는다.
3. Rule A 는 **생성만** 막는다.
4. Core 스크립트 디렉터리의 스크립트를 부르는 Bash 는 무조건 허용하고 영수증을
   발급한다 (`work.sh --archive`, `deck.sh`, `readpath.sh consume`, `sync.sh`,
   `hydrate.sh` 가 전부 여기 해당).

### 문서 정합

우회로 11 개 중 6 개는 "명령이 없어서", 5 개는 "명령이 도는데도 막혀서" 생긴다.
후자 4 개는 영수증 인정 범위를 넓히면 공짜로 풀리고, 남은 하나(`help.md:60` 의 `.env`
쓰기 — 첫 헬퍼 호출보다 앞선다)는 새 스크립트 `env-set.sh` 로 바꾼다.

전자 6 개는 문서를 고친다. 빠른 경로는 **없애지 않고** `work.sh --fast "<intent>"` 를
붙여서 명령이 되게 한다 — 추가만 하므로 기존 CI 단언 13 개가 그대로 통과한다.

### 정합성 테스트

`tests/test-guard-consistency.sh` (저장소 루트 — `export-core.sh` 가 `core/` 와
`tools/` 만 배포하므로 여긴 안 나간다. `core/tests/` 에 두면 `test-host-neutral.sh`
의 금지 문자열 `/scv:` 를 자기가 포함해서 자기 테스트에 걸린다).

`core/contracts/guard.md` 에 기계가 읽는 선언을 두고 네 가지를 단언한다.

1. 선언된 영수증 발급 명령 집합이 `core/actions.json` 의 id 목록과 **정확히 같다** —
   16 번째 명령을 추가하면 가드 결정을 기록할 때까지 CI 가 빨갛다.
2. 배포 디렉터리에 금지 문구가 없다 (영어 + 한국어). **토큰 면제를 쓰지 않는다** —
   `"via action:promote or by hand"` 가 `action:promote` 때문에 면제되면 안 된다.
3. 예외 앵커가 기록된 `file:line` 에서 여전히 일치한다 (죽은 예외 방지).
4. 스캔한 파일 수 > 0, 매치한 문구 수 > 0 (검사기가 no-op 로 썩는 것 방지).

## Guardrails

- **저널 훅 두 개를 blocking 으로 만들지 말 것.** `UserPromptSubmit` 과 `Stop` 은
  계속 `exit 0` 로 열린 채 실패해야 한다. 가드는 별도 `PreToolUse` 항목이다.
- **가드는 fail-open.** 스크립트가 없거나 내부 오류면 허용하고 stderr 에 한 줄
  남긴다. 호스트가 이미 그 경로에서 열린 채 실패하므로 닫아봐야 적대적 강도는 거의
  안 오르는데, 가드 버그 하나가 모든 프로젝트의 모든 쓰기를 벽돌로 만든다.
  다만 **규칙에 명시적으로 걸린 경우는 닫는다.**
- **hydrate 안 된 프로젝트에서 무반응.** 첫 문장이 scv root 판정이고, 없으면 즉시
  허용. `cwd` 기준 `[[ -d scv ]]` 를 쓰지 말 것 — `cd src/` 하면 조용히 꺼진다.
  `lib/scvroot.sh` 의 walk-up 을 쓴다.
- **`test-host-neutral.sh` 를 통과할 것.** `core/` 안에 `Claude`, `Codex`,
  `CLAUDE_PLUGIN_ROOT`, `/scv:` 등이 들어가면 안 된다. 호스트 **이벤트 이름**은
  허용된다 (`on-user-prompt.sh:9` 가 `UserPromptSubmit` 을 포함하고 통과 중).
  영수증 판정은 `SCV_ACTION_TEMPLATE` 시임으로 주입받는다.
- **빠른 경로를 삭제하지 말 것.** 추가만 한다. `run-dry.sh:2189-2196`, `:2254-2263`
  의 단언 13 개가 그대로 통과해야 한다.
- **CI 게이트와 면제 목록을 정확히 일치시킬 것.** 어긋나면 제품이 "코드 변경"의
  정의를 두 가지로 말하게 된다.
- **한국어 문서를 빠뜨리지 말 것.** `raw/README.md`, `loop-runner.md`,
  `routines/README.md`, routine 예제 8 개가 한국어 전용이다.
- **Rule B 를 "계획된 작업만 허용"이라고 설명하지 말 것.** 실제 보장은 "이 세션에서
  SCV 를 썼다" 이다. 계획 여부는 CI 게이트가 머지 시점에 본다.
- **`.env` 를 면제 목록에 넣지 말 것.** 사용자 프로젝트의 `.env` 는 임의 내용이므로
  가드가 계속 봐야 한다. 그래서 정당한 쓰기를 `env-set.sh` 로 옮기는 것이다.

## Exit criteria

- TESTS.md 시나리오 전부 통과.
- 빈 프로젝트를 hydrate 한 뒤 15 개 명령을 Rule B 켠 채로 전부 돌려서 **거부 0 건**.
- 두 호스트에서 Rule A 거부와 Rule B 거부가 각각 실제로 재현된다.
- `test-guard-consistency.sh` 가 문서 수정 **전에는 빨갛고** 후에는 초록이다.
  (수정 전에도 통과하면 검사기가 no-op 라는 뜻이다.)
- 두 래퍼 CI 가 초록 — Codex 의 `assert "hooks" not in manifest` 를 바꾼 뒤.
- hydrate 안 된 디렉터리에서 아무 파일이나 써도 가드가 반응하지 않는다.
- 가드 스크립트를 지운 상태에서도 세션이 정상 동작한다 (fail-open 확인).

## Suggested path

1. `core/scripts/env-set.sh` — `.env` 한 줄을 이식성 있게 생성/치환/추가. 다른 어떤
   변경보다 먼저, 독립적으로 검증 가능.
2. `.env` 쓰기 지시 4 곳을 `env-set.sh` 호출로 바꾼다
   (`help.md:60`, `promote.md:100`, `work.md:509`, `.env.example.scv:34-35` 의 손수
   만든 sed 레시피 삭제).
3. `work.sh` 에 `--fast "<intent>"` 를 더하고 `PROMOTE.md` §1.6 을 **추가만** 해서
   고친다.
4. 자기 차단 감사 — 15 개 프로토콜 + 어댑터 2 개를 손으로 훑어 "첫 영수증 지점"과
   "첫 비면제 쓰기 지점"을 표로 만들어 `core/contracts/guard.md` 에 기록한다.
   정규식으로 하지 말 것 (기존 스크립트 호출 파서는 줄 번호가 없어 순서를 표현 못
   하고, 산문 언급도 매치한다).
5. 문서 수정 전부를 한 커밋으로 — Core 6 곳 + 래퍼가 소유한 곳
   (`scv-claude-code/README.md` 3 개 언어, `commands/set-models.md`,
   `scv-codex/.../adapter/protocols/set-models.md`).
6. `core/contracts/guard.md` + `tests/test-guard-consistency.sh`.
7. 가드 훅 자체 (`core/template/hooks/`).
8. 래퍼 등록 두 곳 + 그 과정에서 뒤집어야 하는 계약 문장들.
9. CI 프로버넌스 게이트 (별도 계획 `20260812-wookiya1364-ci-provenance-gate`) 를
   구현하고 면제 목록을 맞춘다.
10. 릴리스 — 버전 올리고 두 래퍼에 재벤더, 전체 테스트, 빈 프로젝트 실증.

## Related Documents

- [`TESTS.md`](./TESTS.md)
- [`scv/promote/20260812-wookiya1364-ci-provenance-gate/PLAN.md`](../20260812-wookiya1364-ci-provenance-gate/PLAN.md) — 같은 릴리스에 나가는 CI 층
- [`scv/raw/stale/20260812-wookiya1364-forced-invocation.md`](../../raw/stale/20260812-wookiya1364-forced-invocation.md) — 조사 기록

## Risks / Open Questions

- **Codex 신뢰 만료.** Codex 는 훅 해시에 신뢰를 묶는다. 가드 스크립트를 고칠 때마다
  사용자가 `/hooks` 를 다시 승인할 때까지 강제가 꺼진다. 릴리스 노트와
  `/scv:update` 안내에 넣어야 한다. 이 설계에서 가장 큰 운영 위험이다.
- **Codex 훅 등록 경로가 문서 근거뿐이다.** 재현에 성공한 것은 매니페스트 `hooks` 키
  방식이고, 기본 경로(`plugins/scv/hooks/hooks.json`) 는 문서로만 확인했다. 배포
  전에 실증해야 한다. 안 되면 매니페스트 키를 쓰고
  `test-codex-plugin.sh:157` 을 지운다.
- **훅은 핫 리로드가 안 된다.** 업데이트 후 재시작 또는 `/reload-plugins` 전에는
  강제가 안 걸린다.
- **조용한 무력화.** 경로 오타나 캐시 불일치로 가드가 꺼져도 티가 안 난다.
  `/scv:help` 에 자가 점검(탐침 발급 후 살아있는지 보고)을 넣어야 한다.
- **고친 문서가 설치본에 안 갈 수 있다.** `SCV.md` 는 frontmatter 가 없어
  merge_policy 도 없고, `DECISIONS.md`/`TODO.md`/`journal/README.md` 는 `preserve` 다.
  "배포했다"와 "적용됐다"는 다르다.
- **성능.** 조기 종료 1.4ms, 전체 훅 경로 21.9ms 로 측정됐다. 가드 항목은
  `timeout: 5` 로 둔다 — 저널 훅의 30/60 초는 매 쓰기마다 도는 게이트에는 너무 길다.

## Links

- Raw originals: (frontmatter `raw_sources` 참조)
- Related PRs:
