---
title: "명령을 skills 로 — 플러그인 구조·설명 길이를 CI 가 지킨다"
slug: 20260911-wookiya1364-skills-layout-gates
author: "wookiya1364"
created_at: 2026-09-11
status: planned
kind: refactor
lang: korean
epic: 20260911-plugin-modernize
tags: [skills, commands, plugin-layout, ci, validate, description-budget, wrapper]
raw_sources:
  - scv/conversations/20260911-110227-next-features-0-46-1.md
  - scv/raw/stale/20260911-research-plugin-trends.md
refs: []
invariants:
  - "호출 이름은 하나도 바뀌지 않는다 — 열다섯 개 /scv:<action> 이 이전과 같은 이름으로 뜬다"
  - "각 스킬의 본문은 코어 protocol 과 바이트 단위로 같다 — 투영 검사(project-core.sh --check)가 그대로 통과"
  - "명령이 세션 모델을 바꾸지 않는다 (0.45.0) — 어떤 SKILL.md 에도 model 줄이 없다"
  - "코어 페이로드(core/scripts · protocols · template)는 이 계획으로 바뀌지 않는다 — 바뀌는 것은 코어 tests 와 docs 뿐"
  - "Codex 래퍼는 무변경 — 이미 skills 구조"
scope:
  - "(래퍼 scv-claude-code) commands/*.md ×15 → skills/<action>/SKILL.md, name: 추가, commands/ 삭제"
  - "(래퍼 scv-claude-code) scripts/project-core.sh"
  - "(래퍼 scv-claude-code) scripts/sync-core.sh"
  - "(래퍼 scv-claude-code) scripts/apply-model-policy.sh"
  - "(래퍼 scv-claude-code) tests/test-core-contract.sh"
  - "(래퍼 scv-claude-code) .github/workflows/core-contract.yml · core-sync.yml · test-model-policy.yml"
  - "(래퍼 scv-claude-code) adapter/README.md · docs/core-wrapper-ownership.ko.md · README*.md"
  - "core/tests/test-model-policy-default.sh"
  - "core/tests/test-autosync.sh"
  - "core/tests/test-skill-descriptions.sh"
  - "docs/wrapper-integration.md"
  - "VERSION"
  - "CHANGELOG.md"
---

# 명령을 skills 로 — 플러그인 구조·설명 길이를 CI 가 지킨다

## Summary

래퍼는 아직 예전 방식인 `commands/` 폴더를 쓴다. 공식 문서는 이를 legacy 로 표시하고, 새
`skills/` 방식에서만 보조 파일 폴더·경로 조건·호출 주체 제어가 붙는다. 열다섯 명령을 같은
이름의 `skills/<action>/SKILL.md` 로 옮기고 `commands/` 는 같은 릴리스에서 없앤다(사용자
결정). 옮기는 김에 두 가드를 CI 에 건다 — 플러그인 구조 검사(`claude plugin validate
--strict`)와 스킬 설명 길이 상한(개별 1,536자 · 합계 8,000자).

## Goals / Non-Goals

- **Goals**
  - 열다섯 스킬이 `skills/<action>/SKILL.md` 에 있고 `/scv:<action>` 으로 이전과 같이 뜬다.
  - 투영(코어 protocol 본문 + adapter 소유 frontmatter)이 새 경로로 그대로 돈다.
  - 래퍼 PR 게이트에 `claude plugin validate . --strict` 가 있다 (Linux 잡, 실패 시 PR 차단).
  - 스킬 설명 길이 검사: 개별 1,536자(공식 잘림 지점) · 합계 8,000자. 초과 시 코어 검사 실패.
  - `/skill-doctor` 로 실측한 스킬별 컨텍스트 비용을 CHANGELOG 에 적는다.
- **Non-Goals**
  - `context: fork` 적용 — 포크는 대화 이력이 없고 기본으로 사용자와 대화할 수 없다(공식 문서).
    SCV 명령은 전부 사용자에게 묻는 흐름이라 맞지 않는다. 이번엔 구조만 옮긴다.
  - 설명 문구 자체를 다듬는 일 — 지금 최대 542자로 상한 안이다. 검사만 건다.
  - Codex 래퍼 — 이미 skills 구조(얇은 포인터). 무변경.
  - 코어 payload 변경 — protocols·scripts·template 은 그대로다.

## Approach Overview

**확인된 사실 (2026-09-11).**
- 공식 문서: `commands/deploy.md` 와 `skills/deploy/SKILL.md` 는 같은 `/deploy` 를 만든다.
  플러그인에서는 `/plugin:name`. `name:` frontmatter 가 없으면 설치 디렉터리명(버전 문자열)
  으로 떨어지므로 **반드시 적는다**. SKILL.md 는 `argument-hint` · `allowed-tools` ·
  `$ARGUMENTS` 를 같은 방식으로 지원한다.
- `claude plugin validate . --strict` 는 로컬 검증만 하며 인증이 필요 없다고 문서가 말한다
  (CI 에서의 실측은 미확인 — 아래 위험). 현재 래퍼는 매니페스트·commands 모두 통과.
- 래퍼 설명 길이: 15개, 257~542자, 합계 약 5,800자. 공식 잘림 지점 1,536자.
- `commands/` 경로가 박힌 곳(실측 grep): 래퍼 `project-core.sh`(투영) · `sync-core.sh`(scopes,
  adapter_owned 2건, frontmatter-only 규칙, 코어 소유 판정, 스테이지 복사) ·
  `apply-model-policy.sh` · `tests/test-core-contract.sh` 5곳 · 워크플로 3개 · `adapter/README.md`
  · `docs/core-wrapper-ownership.ko.md`; 코어 `tests/test-model-policy-default.sh` ·
  `tests/test-autosync.sh:314` (그 밖의 코어 언급은 주석).
- Codex 래퍼는 `skills/<name>/SKILL.md` + `skills/<name>/agents/openai.yaml` 구조.

**옮기는 규칙은 하나다.** `commands/<a>.md` → `skills/<a>/SKILL.md`. frontmatter 맨 앞에
`name: <a>` 한 줄을 더하고 나머지(description · argument-hint · allowed-tools)는 그대로.
본문은 투영이 다시 만든다(코어 protocol 과 같아야 함). `update` 와 `set-models` 는 adapter
소유라 본문도 그대로 옮긴다. `commands/` 는 같은 커밋에서 지운다 — 둘 다 두면 스킬 목록이
두 배가 되고 문서도 공존을 권하지 않는다.

**경로가 박힌 곳을 전부 따라간다.** 투영 스크립트는 `skills/$action/SKILL.md` 를 쓰고 없으면
같은 오류 문구로 멈춘다. 갱신 스크립트의 scopes 는 `commands` 대신 `skills`, adapter_owned 는
`skills/set-models/SKILL.md` · `skills/update/SKILL.md`, "frontmatter 만 adapter 소유" 규칙은
`skills/` 아래 `SKILL.md` 로. 모델 정책 스크립트는 `skills/*/SKILL.md` 를 돈다. 계약 검사와
워크플로 `paths` 도 같이.

**가드 둘.** (1) 래퍼 `core-contract.yml` 의 Linux 잡에 단계 하나 — Claude Code CLI 설치
(`npm install -g @anthropic-ai/claude-code`, 버전 고정) 후 `claude plugin validate . --strict`.
인증 없이 도는지 첫 실행에서 확인한다; 인증을 요구하면 같은 검사를 코어 셸 검사로 대체하고
그 사실을 CHANGELOG 에 적는다. (2) 코어 `tests/test-skill-descriptions.sh` — 옆 체크아웃의
`scv-claude-code/skills/*/SKILL.md` 를 읽어 `name:` 이 디렉터리명과 같은지, description 이
개별 1,536자 · 합계 8,000자 이내인지, `model:` 줄이 없는지 본다. 코어 검사이므로 래퍼에도
투영되어 래퍼 CI 에서 돈다. 호스트 중립 검사에 걸리지 않도록 래퍼 이름은 소문자 저장소명만.

**실측을 남긴다.** 릴리스 후 `/skill-doctor` 를 한 번 돌려 스킬별 컨텍스트 비용과 미사용
표시를 CHANGELOG 에 적는다 — 다음에 설명을 다듬을지 정하는 근거다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readFrontmatter,      // SKILL.md 텍스트 → frontmatter 문자열          (입구: 파일 읽기)
  parseSkillMeta,       // frontmatter 문자열 → {name, description, hasModel}
  checkOne,             // {meta, dirName} → 위반 목록 (이름 불일치 · 길이 초과 · model 줄)
  sumDescriptions,      // 설명 길이 목록 → 합계
  report,               // 위반 목록 + 합계 → ✓/✖ 줄과 종료 코드        (출구: stdout)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readFrontmatter | 파일 경로 → frontmatter 문자열 | 부수효과 (입구: 파일 읽기) |
| 2 | parseSkillMeta (`scv_skill_meta`) | 문자열 → name·description·model 유무 | 순수 |
| 3 | checkOne (`scv_skill_check`) | meta + 디렉터리명 + 상한 → 위반 줄들 | 순수 |
| 4 | sumDescriptions (`scv_skill_total`) | 길이 목록 → 합계 | 순수 |
| 5 | report | 위반·합계 → 출력·exit | 부수효과 (출구) |

- 부수효과 위치: 1(읽기)과 5(출력)뿐. 상한값은 인자로 받는다(기본 1536 · 8000).
- 재사용: 코어 검사 골격(`ok/fail/skip`, 옆 체크아웃 탐색)은 `test-model-policy-default.sh` 와 같다.
  투영·갱신 파이프라인(`project-core.sh` · `sync-core.sh`)은 경로만 바뀌고 단계는 그대로.

## Guardrails

- 호출 이름 열다섯 개는 바뀌지 않는다 — 디렉터리명 = 이전 파일 stem.
- 스킬 본문은 코어 protocol 과 바이트 단위로 같아야 한다 — 손으로 고치지 않는다, 투영이 만든다.
- `model:` 줄을 어느 SKILL.md 에도 넣지 않는다 (0.45.0 원칙). `context: fork` 도 넣지 않는다.
- `commands/` 는 남기지 않는다 — 공존 기간 없음(사용자 결정).
- 코어 payload(protocols · scripts · template)는 손대지 않는다. 코어에서 바뀌는 것은 tests 와 docs.
- 코어 검사 본문에 호스트 이름·모델 이름을 적지 않는다 — 래퍼는 `scv-claude-code` 로만.
- validate 단계는 PR 게이트다 — 실패를 경고로 낮추지 않는다. 인증 문제로 CI 에서 돌 수 없으면
  단계를 빼고 코어 셸 검사로 대체하되 그 결정을 CHANGELOG 에 적는다.
- Codex 래퍼 파일은 건드리지 않는다.

## Exit criteria

- All TESTS.md scenarios pass
- 래퍼 PR 의 Contract 잡(ubuntu · macos)이 녹색이고, 그 안에 `claude plugin validate --strict`
  단계가 있으며 통과한다.
- 마켓플레이스 갱신 후 `/scv:help` 가 이전과 같이 뜬다(수동, T12).
- `/skill-doctor` 실측 수치가 CHANGELOG 에 있다.

## Suggested path

1. 래퍼 브랜치에서 `git mv commands/<a>.md skills/<a>/SKILL.md` ×15, 각 파일 맨 앞에 `name: <a>`.
2. `project-core.sh` · `sync-core.sh` · `apply-model-policy.sh` 경로 교체 → `project-core.sh
   --check` 통과 확인.
3. `tests/test-core-contract.sh` 경로 5곳, 워크플로 3개 `paths`, README/docs 언급.
4. `core-contract.yml` 에 validate 단계(Linux). 로컬에서 `claude plugin validate . --strict` 통과 확인.
5. 코어: `test-model-policy-default.sh` · `test-autosync.sh` 경로, `test-skill-descriptions.sh`
   신설, `docs/wrapper-integration.md §3` 경로.
6. 코어 회귀 전부 + 래퍼 검사 전부 → 래퍼 PR. 메모리의 함정대로: 계약 변경이므로 래퍼측
   수정을 먼저 브랜치에 넣고 그 브랜치에서 sync-core 를 직접 돌린다.
7. 릴리스 후 `/skill-doctor` 실측 → CHANGELOG.

## Related Documents

- [`FEATURE_ARCHITECTURE.md`](./FEATURE_ARCHITECTURE.md)
- `scv/archive/20260903-wookiya1364-session-model-default/PLAN.md` — 명령 파일 15개 frontmatter 를 한 번에 손댄 직전 사례
- `docs/wrapper-integration.md` §3 — adapter 투영

## Risks / Open Questions

- `claude plugin validate` 가 CI 의 비로그인 환경에서 도는지는 문서 문구("로컬 검증")로만 추정.
  첫 CI 실행이 검증이다. 안 되면 대체 경로(Guardrails 참조).
- 마켓플레이스 자동 갱신 뒤 예전 `commands/` 캐시가 남아 스킬이 두 번 보일 가능성 — 문서상
  이전 버전 디렉터리는 유예 기간 뒤 정리된다. 릴리스 노트에 `/reload-plugins` 를 적는다.
- 래퍼 갱신 워크플로(core-sync)가 `commands` 스코프를 기대하는 채로 코어 릴리스가 먼저 오면
  벤더링이 실패한다 — 그래서 래퍼 수정을 먼저 넣는다(Suggested path 6).
- 설명 합계 상한 8,000자는 스킬이 늘면 다시 정할 값이다. 검사 인자로 두어 바꾸기 쉽게 한다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
