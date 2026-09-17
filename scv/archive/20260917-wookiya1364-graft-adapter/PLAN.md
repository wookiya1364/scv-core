---
title: "Graft 어댑터 — 있으면 코드 영향 범위와 관련 코드 후보를 덧붙이고, 없으면 조용히 생략"
slug: 20260917-wookiya1364-graft-adapter
author: "wookiya1364"
created_at: 2026-09-17
status: testing
kind: feature
epic: 20260917-scv-graph
lang: korean
tags: [graft, adapter, impact, blast, code-context, optional-dependency]
raw_sources:
  - scv/raw/stale/20260916-graft-partial-adoption-shared-conversation.md
  - scv/raw/stale/20260916-graph-dependency-decision.md
  - scv/conversations/20260914-092553-install-check-0-47-0.md
refs:
  - type: link
    url: https://github.com/trailhq/Graft
invariants:
  - "새 필수 의존 없음 — graft 가 없으면 모든 명령이 지금과 똑같이 동작한다(출력에 어댑터 흔적 없음)"
  - "SCV 는 graft 를 설치·초기화·훅 등록하지 않는다 — 안내 한 줄만, 그것도 사용자가 직접 install-deps 를 쳤을 때만"
  - "자체 그래프(scv/.graph)와 그 영향 조회는 그대로 — Graft 는 그 아래에 덧붙는 두 번째 제공자"
  - "훅·가드·기록 계약은 손대지 않는다 · deck 무회귀"
scope:
  - "core/scripts/lib/graft.sh (신설, 순수부: 가용성 판정 · blast/ask JSON → 요약 레코드 · 텍스트 렌더)"
  - "core/scripts/graft.sh (신설, 효과부: status | blast [--base <ref>] | ask <task> — graft 없으면 GRAFT_STATUS: absent, exit 0)"
  - "core/scripts/regression.sh (영향 블록 아래에 === impact (graft blast) === 덧붙임 — 정보만) · core/scripts/work.sh · promote-helper.sh (GRAFT_STATUS 한 줄 + 있을 때 후보 블록)"
  - "core/scripts/install-deps.sh (--print 에 선택 항목 한 줄: graft — 코드 그래프, npm, 훅 없이) · core/protocols/work.md · promote.md · regression.md (있을 때 읽는 법 한 문단)"
  - "core/template/scv/scv_settings.example.json (SCV_GRAFT=auto|off)"
  - "core/tests/test-graft-adapter.sh (신설 — 가짜 graft 픽스처) · core/tests/run-dry.sh (계약 한두 줄)"
  - "docs/wrapper-integration.md · CHANGELOG.md"
---

# Graft 어댑터 — 있으면 코드 영향 범위와 관련 코드 후보를 덧붙이고, 없으면 조용히 생략

## Summary

자체 그래프는 "과거에 같이 바뀐 것"(이력)을 안다. Graft(코드 그래프 엔진, tree-sitter, 23개 언어)는
"지금 코드가 무엇에 의존하는지"(현재)를 안다. 둘은 겹치지 않는다. 이 계획은 Graft 를 **의존이 아니라
선택 제공자**로 붙인다: `graft` 가 PATH 에 있고 그래프(`graft/`)가 있으면 회귀 앞단에 변경의 정적
영향 범위(`graft blast --depth all --format json`)를 자체 그래프 영향 바로 아래에 덧붙이고, 계획
수립·구현 헤더에 관련 코드 후보(`graft ask --json`, file:line)를 싣는다. 없으면 아무 흔적 없이 지금과
같다. 설치·초기화·훅은 SCV 가 하지 않는다 — 원재료의 결론대로 훅·상태줄 없이(`--no-hooks
--no-statusline`, pull 방식) 쓰라는 안내 한 줄만, install-deps 의 선택 항목으로.

주의(확인): Graft 는 bash/shell 을 지원하지 않는다. 이 저장소(scv-core)에서는 어댑터가 줄 것이 없고
TS·Python 등 다운스트림 프로젝트에서 의미가 있다. 검사는 가짜 `graft` 명령(픽스처)으로 계약을 검증한다.

## Goals / Non-Goals

- **Goals**
  - `graft.sh status` → `GRAFT_STATUS: absent | no-graph | ready` (PATH 에 없음 / 있으나 graft/ 없음 / 준비됨). 어느 경우도 exit 0.
  - `graft.sh blast [--base <ref>]` → 변경이 닿는 심볼·파일을 요약한 텍스트 블록(+ `--json`). `ready` 아니면 빈 출력.
  - `graft.sh ask "<task>"` → 상위 후보 file:line 목록(최대 10). `ready` 아니면 빈 출력.
  - regression.sh: 자체 그래프 영향 블록 아래 `=== impact (graft blast) ===` (ready 일 때만). work.sh · promote-helper.sh: `GRAFT_STATUS:` 한 줄, ready 면 `=== code candidates (graft ask) ===` 블록(계획 제목으로 ask).
  - `SCV_GRAFT=off` 로 끌 수 있다(기본 auto).
- **Non-Goals**
  - Graft 설치·`graft init`·훅·MCP 등록·상태줄 — SCV 가 하지 않는다.
  - Graft 그래프를 SCV 그래프에 합치는 것 — 출력만 나란히 싣는다(합치기는 다음 계획 후보).
  - `--deep`(LLM) 옵션 사용.

## Approach Overview

1. **가용성(효과부 → 순수부)**: `command -v graft` 와 `graft/` 폴더(또는 `graft check --json` 이 0) → 순수 함수 `scv_graft_status <has_bin> <has_graph> <switch>` → absent|no-graph|ready|off.
2. **blast**: `graft blast --base <ref> --depth all --format json` (기본 ref 는 `origin/main` 이 있으면 그것, 아니면 `HEAD`) → 순수 함수 `scv_graft_blast_summary <json>` 이 닿는 파일 수·심볼 수·상위 파일 10개(심볼 수 내림차순)를 레코드로 → `scv_graft_render_blast` 가 텍스트로. JSON 필드 이름은 Graft 버전에 따라 다를 수 있으므로 `files[]`/`symbols[]`/`impacted[]` 중 있는 것을 쓰고, 모르는 모양이면 "요약 불가 — 원문 N바이트" 한 줄.
3. **ask**: `graft ask "<task>" --json` → `scv_graft_ask_summary <json> <n>` → 상위 n개 `path:line — label` 줄.
4. **소비처**: regression.sh 의 영향 블록 다음에 blast 블록(변경 파일이 있고 ready 일 때). work.sh/promote-helper.sh 는 `GRAFT_STATUS:` 를 늘 찍고, ready 면 계획 제목(또는 인자)로 ask 한 블록.
5. **안내**: install-deps `--print` 의 "optional" 절에 한 줄 — "graft (코드 그래프, 선택): npm i -g @nanonets/graft · graft init --no-hooks --no-statusline · graft telemetry disable". `--check` 는 graft 를 세지 않는다(필수 아님).

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  probe,               // PATH·graft/ 존재·설정 → {has_bin, has_graph, switch}     (입구, 부수효과)
  scv_graft_status,    // (has_bin, has_graph, switch) → absent|no-graph|ready|off  순수
  runGraft,            // blast/ask 실행 → JSON 텍스트                                (부수효과, ready 일 때만)
  scv_graft_blast_summary,  // JSON → "files\x1fsymbols\x1ftop(path:count …)"       결정적 (jq)
  scv_graft_ask_summary,    // (JSON, n) → "path:line\x1flabel" 줄들                  결정적 (jq)
  scv_graft_render,    // 레코드 → 텍스트 블록                                        순수
  emit,                // stdout                                                       (출구)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | probe | 환경 → has_bin·has_graph·switch | 부수효과 (입구) |
| 2 | scv_graft_status | 세 값 → 상태 | 순수 |
| 3 | runGraft | 명령 → JSON | 부수효과 (ready 일 때만, 실패는 빈 출력) |
| 4 | scv_graft_blast_summary | JSON → 요약 레코드 | 결정적 (jq) |
| 5 | scv_graft_ask_summary | JSON·n → 후보 줄들 | 결정적 (jq) |
| 6 | scv_graft_render | 레코드 → 텍스트 | 순수 |
| 7 | emit | 텍스트 → stdout | 부수효과 (출구) |

- 부수효과 위치: 1·3·7. 4·5·6 은 문자열만 받는다 — 픽스처 JSON 으로 검사.
- 재사용: 자체 그래프의 영향 블록 자리(regression.sh 6b, work.sh impact 절) 바로 아래에 붙는다.

## Guardrails

- graft 가 없으면 출력에 `GRAFT_STATUS: absent` 한 줄 외 아무것도 더하지 않는다 (work/promote 헤더). regression 은 absent 면 줄 자체를 내지 않는다.
- graft 호출은 항상 타임아웃(기본 20초) 안에서, 실패·타임아웃·JSON 파싱 실패는 빈 출력 + stderr 한 줄, exit 0.
- `graft init`·`build --deep`·훅·MCP 를 절대 부르지 않는다. `graft build` 도 부르지 않는다(사용자의 그래프 상태를 바꾸지 않는다).
- 자체 그래프 블록·순서·문구는 그대로. graft 블록은 그 **아래**.
- 호스트 중립 검사: 코어 본문에 호스트 이름을 적지 않는다.

## Exit criteria

- All TESTS.md scenarios pass
- graft 없는 환경(CI)에서 코어 검사·run-dry·루트 러너가 지금과 같이 녹색이고, 소비처 출력의 유일한 차이는 `GRAFT_STATUS: absent` 한 줄.
- 가짜 graft 픽스처로 ready 경로가 끝까지 돈다(blast 요약 · ask 후보 · 타임아웃 · 깨진 JSON).

## Suggested path

1. 검사부터(test-graft-adapter.sh, 가짜 graft 픽스처 둘: 정상 JSON · 깨진 JSON/느린 응답).
2. lib/graft.sh 순수부 → graft.sh → 녹색.
3. regression/work/promote-helper 에 붙이기 → install-deps --print 한 줄 → 설정 예시.
4. 규약 세 곳 한 문단씩 · run-dry 계약 · CHANGELOG · 래퍼 문서.

## 성공지표 (Metrics)

| 지표 | baseline | target |
|---|---|---|
| graft 없는 환경의 출력 차이 | — | `GRAFT_STATUS: absent` 한 줄만 |
| ready 환경에서 회귀 앞단 정보 | 자체 그래프 영향(이력)만 | + 정적 영향 범위(파일·심볼 수·상위 파일) |
| 계획·구현 헤더 | 자체 그래프 impact | + 관련 코드 후보 ≤10 (file:line) |
| 새 필수 의존 | 0 | 0 |
| graft 호출 상한 | — | 20초, 실패 시 exit 0 |

## 예외처리 (Edge cases)

- graft 있음, `graft/` 없음 → `no-graph`: 안내 한 줄("graft build 로 만들 수 있다"), 호출 없음.
- `origin/main` 없음 → `--base HEAD` 로 대체(작업 트리 변경만).
- JSON 필드 모양이 예상과 다름 → 요약 불가 한 줄 + 원문 크기. 실패로 세지 않는다.
- ask 결과 0건 → "(후보 없음)".
- bash 만 있는 저장소(이 저장소) → graft 가 있어도 결과가 비어 있음 → "(후보 없음)". 정상.
- `SCV_GRAFT=off` → `GRAFT_STATUS: off`, 호출 없음.
- graft 가 텔레메트리를 켜 둔 상태 — SCV 는 건드리지 않는다; 안내 줄에 `graft telemetry disable` 를 적는다.

## Related Documents

- scv/raw/stale/20260916-graft-partial-adoption-shared-conversation.md — 어댑터 방식·설치 권장(--no-hooks --no-statusline)·겹치는 지점 셋
- scv/archive/20260917-wookiya1364-scv-own-graph/PLAN.md — 자체 그래프(이력)와의 역할 분담
- https://github.com/trailhq/Graft — CLI: `ask --json` · `blast --depth all --format json` · `check --json` · 지원 언어(bash 없음)

## Risks / Open Questions

- Graft JSON 스키마가 문서화돼 있지 않아 필드 이름을 추정한다 — 요약 함수는 관용적으로(있는 필드만), 검사는 픽스처로.
- 이 저장소에서 실증 불가(bash 미지원) — 다운스트림에서 첫 실사용 뒤 조정 가능성.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs: #217 · #218
