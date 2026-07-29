# SCV Core와 Wrapper 소유권 경계

이 문서는 `scv-core`, `scv-codex`, `scv-claude-code` 중 어디에서 변경해야
하는지 결정하기 위한 운영 가이드다.

관련 계약의 상세 설명은 다음 문서에 있다.

- [Architecture](architecture.md)
- [Wrapper integration](wrapper-integration.md)
- [Host profile contract](../core/contracts/host-profile.md)

## 한 줄 원칙

> Claude Code와 Codex에서 결과가 같아야 하는 기능은 `scv-core`가 소유하고,
> 각 호스트가 기능을 발견·호출·설치하는 방식은 해당 wrapper가 소유한다.

```text
                         scv-core
              공통 프로토콜 · 로직 · 템플릿
                              │
                immutable release + SHA-256
                 ┌────────────┴────────────┐
                 │                         │
        scv-claude-code               scv-codex
        /scv:* · Claude UX            $scv:* · Codex UX
```

## 저장소별 책임

| 저장소 | 책임 |
|---|---|
| `scv-core` | 두 호스트에서 동일해야 하는 SCV의 의미, 동작, 프로젝트 상태 |
| `scv-codex` | Codex plugin 등록, skill discovery, 호출 문법, 설치와 모델 UX |
| `scv-claude-code` | Claude Code slash command, tool/model metadata, 설치와 모델 UX |

## `scv-core`가 소유하는 영역

### 공통 액션과 워크플로

14개 SCV 액션 중 다음 12개 구현은 Core가 소유한다.

- `help`
- `status`
- `promote`
- `work`
- `codegen`
- `deck`
- `regression`
- `report`
- `sync`
- `install-deps`
- `workspace`
- `handoff`

정규 action 목록과 owner는
[`core/actions.json`](../core/actions.json)에 선언한다.

### 공통 파일과 동작

다음 변경은 `scv-core`에서 한다.

- `core/protocols/**`: action의 절차와 사용자 워크플로
- `core/scripts/**`: hydrate, sync, promote, work, report, regression 등 공통 실행 로직
- `core/template/scv/**`: hydrate 결과와 표준 SCV 문서
- `core/scripts/state-index.sh`: 상태 파일 판정, 충돌, pointer, migration
- `core/DeckUI/**`와 `core/assets/**`
- 공통 notifier, attachment, workspace, handoff 로직
- 공통 fixture와 regression test

`scv/SCV.md`가 유일한 canonical 상태 인덱스다. `CLAUDE.md`와 `CODEX.md`
fallback, 다음 pointer marker, hydrated 판정, conflict 및 명시적 migration은
Core resolver 한 곳에서만 구현한다.

```text
<!-- SCV:HOST-POINTER target=SCV.md -->
```

Wrapper는 이 규칙을 별도로 재구현하면 안 된다.

## Wrapper가 공통으로 소유하는 영역

호스트에 종속되는 다음 항목은 각 wrapper가 소유한다.

- plugin manifest와 marketplace metadata
- action 또는 skill discovery 파일
- 호출 문법과 인자 전달 방식
- 설치, reload, wrapper update UX
- 호스트별 모델 정책과 model metadata
- host profile의 실제 값
- wrapper `VERSION`, changelog, release, CI/CD
- Core release를 검증하고 vendor하는 maintainer 도구

Core action catalog에는 `update`와 `set-models`도 포함되지만, 두 액션은
`owner: adapter`이며 실제 protocol과 entrypoint는 각 wrapper가 구현한다.

## `scv-codex`가 소유하는 영역

Codex wrapper에서는 다음 항목을 수정한다.

- `.agents/plugins/marketplace.json`
- `plugins/scv/.codex-plugin/plugin.json`
- `plugins/scv/skills/*/SKILL.md`
- `plugins/scv/skills/*/agents/openai.yaml`
- `plugins/scv/references/codex-runtime.md`
- `plugins/scv/adapter/host-profile.env`
- `plugins/scv/adapter/protocols/update.md`
- `plugins/scv/adapter/protocols/set-models.md`
- `plugins/scv/adapter/scripts/update.sh`
- `plugins/scv/adapter/scripts/apply-model-policy.sh`
- Codex wrapper의 vendoring, 검증, release, CI 도구

Codex host profile은 다음과 같은 호스트 차이를 정의한다.

- 자연어 implicit invocation
- 선택적 exact selector `$scv:<action>`
- `argv-array` 방식의 안전한 인자 전달
- Codex plugin root와 skill 검색 위치

일반 `SKILL.md`는 Codex가 action을 발견하도록 등록하는 얇은 wrapper다.
실제 action 의미와 절차는 vendored Core protocol을 읽는다. `update`와
`set-models` skill만 Codex adapter protocol을 읽는다.

Codex의 `state-index.sh`, `hydrate.sh`, `sync.sh`는 Core 호출 전후 순서만
조정하는 shim이다. 상태 판정이나 template merge를 다시 구현하는 곳이 아니다.

## `scv-claude-code`가 소유하는 영역

Claude Code wrapper에서는 다음 항목을 수정한다.

- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `adapter/claude-code.env`
- `/scv:<action>` slash command 등록
- `commands/*.md`의 YAML frontmatter
- `argument-hint`, `allowed-tools`, `model`
- `$ARGUMENTS`와 `CLAUDE_PLUGIN_ROOT` 연결
- `scripts/apply-model-policy.sh`
- `scripts/update.sh`
- Claude wrapper의 Core sync, 검증, release, CI 도구

Claude의 일반 `commands/*.md`는 소유권이 나뉜다.

| 부분 | 소유자 |
|---|---|
| YAML frontmatter, tool/model metadata | Claude wrapper |
| action protocol 본문 | Core에서 생성된 projection |
| `commands/update.md` 전체 | Claude wrapper |
| `commands/set-models.md` 전체 | Claude wrapper |

`scripts/hydrate.sh`, `scripts/sync.sh`, `adapter/scripts/state-index.sh`는
Claude UX와 호출 순서를 담당하는 shim이다. pointer, conflict, hydration
규칙은 반드시 vendored Core resolver에 위임한다.

## 직접 편집하면 안 되는 생성 영역

### Codex

다음 경로는 immutable Core release를 Codex profile로 materialize한 결과다.

```text
plugins/scv/vendor/scv-core/**
```

이 경로를 직접 수정하지 않는다. Core release 후 wrapper vendoring 도구로
전체를 다시 생성한다.

### Claude Code

다음 경로는 wrapper 저장소에 존재하더라도 대부분 Core projection이다.

```text
vendor/scv-core/**
protocols/**
template/**
DeckUI/**
assets/**
```

Root `scripts/**`, `tests/**`, `commands/*.md`도 adapter allowlist와 command
frontmatter를 제외하면 Core projection이다. 생성 파일을 직접 고치지 말고
Core source를 수정한 뒤 `scripts/sync-core.sh`로 갱신한다.

## 변경 위치 판단표

| 변경 요구 | 수정 위치 |
|---|---|
| promote가 잘못된 PLAN을 생성한다 | `scv-core` |
| work, regression, report의 동작을 바꾼다 | `scv-core` |
| hydrate 결과나 표준 문서를 바꾼다 | `scv-core` |
| `SCV.md` 판정, conflict, pointer, migration을 고친다 | `scv-core` |
| DeckUI 또는 공통 asset을 바꾼다 | `scv-core` |
| Codex 자연어 skill routing 또는 `$scv:*`를 바꾼다 | `scv-codex` |
| Codex marketplace, plugin manifest를 바꾼다 | `scv-codex` |
| Codex update 또는 모델 설정 UX를 바꾼다 | `scv-codex` |
| Claude `/scv:*` frontmatter나 allowed-tools를 바꾼다 | `scv-claude-code` |
| Claude command별 opus/sonnet/haiku 정책을 바꾼다 | `scv-claude-code` |
| Claude marketplace, reload, update UX를 바꾼다 | `scv-claude-code` |
| 공통 action을 새로 추가하거나 이름을 바꾼다 | Core와 두 wrapper |
| host-profile 계약이나 Core API를 호환 불가능하게 바꾼다 | Core와 두 wrapper |

## 양쪽을 함께 수정해야 하는 변경

새 공통 action을 추가하는 경우를 예로 들면 다음 순서로 작업한다.

1. `scv-core`의 action catalog, protocol, entrypoint, shared test를 추가한다.
2. `scv-codex`에 얇은 `SKILL.md`와 `agents/openai.yaml` 등록을 추가한다.
3. `scv-claude-code`에 slash command frontmatter를 추가한다.
4. 두 wrapper가 같은 Core release를 고정하고 contract test를 통과시킨다.

Host profile schema를 호환 불가능하게 변경하는 경우에는 Core의
`CORE_API`를 올리고 두 wrapper adapter를 같은 계약으로 함께 갱신한다.

## Core 변경이 Wrapper에 전달되는 과정

```text
scv-core 변경
  → Core test
  → develop → stage → main
  → VERSION 및 vX.Y.Z release
  → immutable tar.gz + SHA-256
  → wrapper repository_dispatch 또는 scheduled polling
  → 각 wrapper가 checksum과 provenance 검증
  → host profile로 materialize
  → Core + adapter contract test
  → chore/core-vX.Y.Z → develop PR
  → wrapper별 develop → stage → main
  → wrapper별 release
```

자동화는 wrapper 영구 브랜치를 직접 수정하지 않는다. 검증된
`develop` 대상 PR을 만드는 것까지 자동이며, wrapper별 승격과 release는
각 저장소의 gate를 따른다.

설치된 plugin은 runtime에 Core를 다운로드하지 않는다. 각 wrapper release는
정확한 Core version, source commit, canonical/materialized digest, release
artifact SHA-256을 고정한 self-contained payload다.

## 버전 축

세 종류의 버전은 독립적으로 관리한다.

| 버전 | 의미 |
|---|---|
| Core `VERSION` | 공통 SCV 동작과 release payload |
| `CORE_API` | Core와 wrapper의 통합 호환성 |
| `TEMPLATE_VERSION` | hydrate/sync가 관리하는 프로젝트 template schema |
| Wrapper `VERSION` | 해당 Claude 또는 Codex plugin release |

Core pin을 갱신하는 PR은 wrapper `VERSION`을 자동으로 변경하지 않는다.
사용자에게 새 payload를 배포할 때 wrapper별 version과 release를 별도로
결정한다.

## 변경 전 체크리스트

변경을 시작하기 전에 다음 질문을 순서대로 확인한다.

1. Claude Code와 Codex에서 결과가 같아야 하는가?
   - 그렇다면 Core 변경이다.
2. 차이가 plugin 발견, 호출, 인자 전달, 설치 또는 모델 기능 때문인가?
   - 그렇다면 해당 wrapper 변경이다.
3. vendored Core 또는 생성 projection을 직접 편집하려는가?
   - 중단하고 Core source 또는 adapter source를 찾는다.
4. action catalog나 host-profile 계약이 바뀌는가?
   - Core와 두 wrapper의 seam 변경으로 계획한다.
5. Core release 후 wrapper update PR과 두 호스트 contract test까지
   완료했는가?
