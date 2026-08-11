# HANDOFF DRAFTS — 훅 등록 (wrapper 소유) · 발행 대기

> TESTS.md 시나리오 10 은 본 계획에서 **발행하지 않는다** — 아래 2건은
> `action:handoff` 로 발행할 본문 초안이다. 각 초안의 Body / Why 섹션은
> `handoff.sh write --body-file / --why-file` 에 그대로 넣을 수 있는 형태다.
> 계약 원문: `docs/wrapper-integration.md` §6 "Hook seam (journal capture)".

---

## Draft 1 — to: `scv-claude-code`

- 제안 커맨드:
  `handoff.sh write --to scv-claude-code --slug journal-hook-registration --title "Claude Code 훅 등록: UserPromptSubmit/Stop → SCV journal" --decision needed --from-slug 20260804-wookiya1364-team-journal --body-file <body> --why-file <why>`

### Body (`## What scv-claude-code must build`)

## What scv-claude-code must build

Core 0.22.0 의 훅 seam 계약(`docs/wrapper-integration.md` §6)에 따라, vendored
Core 의 훅 템플릿 2종을 Claude Code 훅 시스템에 **등록하는 어댑터 구현**:

1. **이벤트 매핑** (이벤트 이름은 계약 고정):
   - `UserPromptSubmit` → `core/template/hooks/on-user-prompt.sh`
     (stdin JSON 의 `prompt` 필드 → journal-append)
   - `Stop` → `core/template/hooks/on-stop.sh`
     (stdin JSON 의 `transcript_path` 필드 → assistant 응답 요약 append)
2. **등록 방법**: 플러그인의 `hooks` 설정 projection (Claude Code
   `settings.json` 스키마 기준 `hooks.UserPromptSubmit[].hooks[].command` /
   `hooks.Stop[].hooks[].command`) 으로 위 두 스크립트를 등록. cwd 는 프로젝트
   루트여야 한다 (템플릿이 `scv/` 를 cwd 상대로 해석).
3. **env 계약**: 등록된 커맨드 실행 환경에 `SCV_CORE_ROOT`(materialized
   `core/` 절대경로) export. 미설정 시 템플릿은 in-payload 상대경로
   (`<hook dir>/../../scripts/journal-append.sh`)로 폴백한다.
4. **non-blocking 보존**: 템플릿은 모든 실패에서 exit 0 + 무기록이다. 등록을
   blocking 훅으로 만들거나 실패를 세션 실패로 승격하지 말 것.
5. **redaction 우회 금지**: journal 쓰기는 반드시 `journal-append.sh` 경유
   (password/token/secret/api-key/Bearer/AKIA → `[REDACTED]`). wrapper 가
   `scv/journal/` 에 직접 쓰지 말 것.

## Acceptance for the receiving repo

- 훅 등록 후 자유대화 프롬프트 1건 입력 → `scv/journal/<YYYYMMDD>-<author>.md`
  에 `### [HH:MM:SS] user` 블록으로 기록된다.
- 세션 stop 1회 → 같은 파일에 `### [HH:MM:SS] assistant` 요약 블록이 append 된다.
- `{"prompt": "password=hunter2"}` 주입 → 저장본에는 `password=[REDACTED]` 만
  존재하고 원문 `hunter2` 는 리포 어디에도 없다.
- 잘못된 JSON / transcript 미존재 / un-hydrated 프로젝트 → 훅 exit 0, 기록
  없음, 세션 진행에 영향 없음.
- 훅 미등록(구버전 설정) 상태에서도 기존 기능 무회귀.

### Why (`--why-file`)

## What was decided

Core 는 훅 스크립트 템플릿과 계약만 소유하고, 호스트 종속인 등록(설치)은
wrapper 소유로 확정 (update/set-models 와 같은 경계). Claude Code wrapper 는
`UserPromptSubmit`/`Stop` 두 이벤트를 등록해야 자유대화까지 journal 로
영속화되는 핵심 경로가 완성된다.

## Why

- 자유대화(action:* 없이 말하는 내용)는 훅 없이는 캡처 불가 — Core 단독으로는
  이 격차를 닫을 수 없다 (PLAN §Risks "훅 없는 호스트").
- 등록 포맷·이벤트 이름·설정 파일 스키마는 호스트 버전에 종속 → Core 에 넣으면
  host-neutral 계약이 깨진다. 대안(Core 가 settings.json 직접 수정)은 기각.

---

## Draft 2 — to: `scv-codex`

- 제안 커맨드:
  `handoff.sh write --to scv-codex --slug journal-hook-registration --title "Codex 훅 등록: prompt-submit/turn-end 상당 이벤트 → SCV journal" --decision needed --from-slug 20260804-wookiya1364-team-journal --body-file <body> --why-file <why>`

### Body (`## What scv-codex must build`)

## What scv-codex must build

Core 0.22.0 의 훅 seam 계약(`docs/wrapper-integration.md` §6)에 따라, Codex
호스트에서 아래 두 시점에 vendored Core 훅 템플릿을 실행하는 어댑터 구현:

1. **이벤트 매핑** (Codex 의 상당 이벤트에 바인딩):
   - 사용자 프롬프트 제출 시점 (Claude Code 의 `UserPromptSubmit` 상당) →
     `core/template/hooks/on-user-prompt.sh` 에 `{"prompt": "<원문>"}` JSON 을
     stdin 으로 전달.
   - 턴/세션 종료 시점 (Claude Code 의 `Stop` 상당) →
     `core/template/hooks/on-stop.sh` 에 `{"transcript_path": "<JSONL 경로>"}`
     를 stdin 으로 전달. Codex 가 JSONL transcript 를 제공하지 못하면 이
     이벤트는 **등록 생략** (훅은 조용히 skip 하는 계약 — 부분 구현 허용).
2. **등록 방법**: Codex 의 훅/notify 설정 표면에 위 커맨드를 projection.
   cwd 는 프로젝트 루트. stdin JSON 은 어댑터가 조립한다 (호스트 네이티브
   페이로드 → 계약 JSON 필드 `prompt` / `transcript_path` 로 변환).
3. **env 계약**: `SCV_CORE_ROOT` export (미설정 시 in-payload 상대경로 폴백).
4. **non-blocking 보존** + **redaction 우회 금지**: Draft 1 의 4·5항과 동일.

## Acceptance for the receiving repo

- 프롬프트 제출 이벤트 1건 → `scv/journal/<YYYYMMDD>-<author>.md` 에
  `### [HH:MM:SS] user` 블록 기록 (author 는 git config user.name →
  GIT_AUTHOR_NAME → USER 폴백, `lib/author.sh` 와 동일 해석).
- secret 패턴 포함 프롬프트 → 저장본은 `[REDACTED]`, 원문은 리포 어디에도 없음.
- 계약 밖 페이로드(잘못된 JSON 등) → exit 0 + 무기록, 세션 무영향.
- transcript 미지원 구성에서는 on-stop 미등록으로도 acceptance 통과
  (user-prompt 경로만으로 부분 구현 인정, 격차는 wrapper README 에 명시).

### Why (`--why-file`)

## What was decided

훅 등록은 wrapper 소유 — Codex wrapper 는 자기 호스트의 이벤트 표면에 Core
훅 템플릿 2종을 바인딩한다. 이벤트 이름이 Claude Code 와 다르므로 계약은
"상당 이벤트 + stdin JSON 필드(`prompt`/`transcript_path`)" 로 고정한다.

## Why

- journal 영속화의 커버리지는 호스트별 훅 등록에 달려 있고, Codex 의 훅
  표면은 Claude Code 와 다르다 — Core 가 아니라 wrapper 만 닫을 수 있는 격차.
- transcript 형식/제공 여부는 호스트 버전 종속 → on-stop 은 조용히 skip 하는
  non-blocking 계약이므로 부분 구현(등록 생략)을 허용해 배포를 막지 않는다.
