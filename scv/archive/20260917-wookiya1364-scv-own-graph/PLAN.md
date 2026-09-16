---
title: "SCV 자체 그래프 — 문서·계획·동시변경을 의존성 0 으로, graphify 제거"
slug: 20260917-wookiya1364-scv-own-graph
author: "wookiya1364"
created_at: 2026-09-17
status: testing
kind: feature
epic: 20260917-scv-graph
lang: korean
tags: [graph, docs, archive, co-change, impact, graphify-removal, jq]
raw_sources:
  - scv/raw/stale/20260916-graft-partial-adoption-shared-conversation.md
  - scv/raw/stale/20260916-graph-dependency-decision.md
  - scv/conversations/20260914-092553-install-check-0-47-0.md
refs: []
invariants:
  - "/scv:deck 은 기존과 마찬가지로 잘 되어야 한다 — 그림 2(전체 구조)의 출처 줄만 바뀌고 렌더·린트·정적 mermaid 는 그대로"
  - "새 외부 의존 없음 — bash · jq · git 만. 스킬·Python·LLM 호출 없음"
  - "그래프 산출물은 무시 파일(scv/.graph/) — 커밋되지 않고 필요할 때 자동 재생성"
  - "promote·work·status·deck 의 사용자 흐름은 그대로 — 질문이 하나 줄어들 뿐(그래프 갱신 여부를 묻지 않는다)"
  - "훅·가드·기록 계약은 손대지 않는다"
scope:
  - "core/scripts/lib/graph.sh (신설, 순수부: 링크 추출 · 계획→파일 추출 · 결정 참조 · 동시변경 · 군집 · 핵심 노드 · JSON/보고 렌더 · 영향 조회)"
  - "core/scripts/graph.sh (신설, 효과부: build | status | ensure | impact <path>… | report)"
  - "core/scripts/promote-helper.sh · work.sh · status.sh · deck-context.sh (GRAPHIFY_SKILL/GRAPH_DIR → graph.sh ensure/status; work.sh 에 IMPACT 블록)"
  - "core/scripts/help.sh · install-deps.sh (의존성 표에서 graphify 행 제거) · core/scripts/lib/host-profile.sh (scv_graph_skill_available 제거; SCV_GRAPH_SKILL_PATHS 는 받아도 무시)"
  - "core/scripts/regression.sh (변경 파일의 영향 목록을 앞단에 정보로 출력 — 선택은 바꾸지 않음)"
  - "core/protocols/promote.md (Step 1 · Step 6.2 3-way/2-way 질문 제거 · graph.json 매핑 알고리즘을 새 계약으로) · work.md · status.md · deck.md · install-deps.md · codegen.md"
  - "core/template/scv/PROMOTE.md · core/template/.gitignore.fragment · core/.gitignore · .gitignore (scv/.graph/ 추가, .graphify 줄 제거) · core/template/scv/scv_settings.example.json (SCV_GRAPH · SCV_GRAPH_DOCS)"
  - "core/tests/test-graph.sh (신설) · core/tests/run-dry.sh ([11e]·[11f]·[11xx]·[11bbb]·deck 픽스처의 graphify 계약 → 새 계약) · core/tests/test-deck-*.sh (Source 줄)"
  - "docs/wrapper-integration.md (그래프 스킬 경로 계약 폐기 안내) · CHANGELOG.md"
---

# SCV 자체 그래프 — 문서·계획·동시변경을 의존성 0 으로, graphify 제거

## Summary

graphify 는 보관된 52개 계획 중 실제로 쓴 계획이 0 이고, Python 스킬 + LLM 빌드 비용이 붙는데,
SCV 가 그것으로 하는 일은 문서 그래프 하나(계획서 다이어그램 2 · deck 큰 그림 · status 신선도)뿐이다.
이 계획은 SCV 가 이미 가진 재료 — docs 문서의 링크, 보관된 계획마다 건드린 파일, 결정 로그의 참조,
같은 계획에서 함께 바뀐 파일 쌍 — 를 bash + jq 로 하나의 그래프(`scv/.graph/graph.json` + 보고)로
떨구고, graphify 참조를 전부 걷어낸다. 얻는 것은 두 도구 다 못 주는 것 — "이 파일을 바꾸면 무엇이
같이 바뀌고 어느 계획·결정이 얽혔는가"(영향 조회) — 이고, 구현 명령과 회귀 앞단에서 바로 쓴다.
그래프는 빠르게(목표 2초 안) 자동 재생성되므로 사용자에게 갱신 여부를 묻는 질문이 사라진다.

## Goals / Non-Goals

- **Goals**
  - `graph.sh build` 가 bash+jq 만으로 그래프를 만든다: 노드(doc · file · plan · decision), 링크(link · touches · refers · cochange), 군집(폴더·epic), 핵심 노드, 근거(계획 슬러그).
  - `graph.sh impact <path>…` 가 함께 바뀌는 파일(가중치·근거 계획)과 얽힌 계획·결정·문서를 낸다. work.sh 헤더와 regression.sh 앞단에 정보로 붙는다.
  - promote·work·status·deck 이 graphify 대신 이 그래프를 쓴다. 신선도는 mtime 으로 자동 판정, 낡으면 자동 빌드(`ensure`).
  - graphify 참조 0 (core/ · docs/ · README · 템플릿 · 검사). 설정 두 개: `SCV_GRAPH=on|off`, `SCV_GRAPH_DOCS`(문서 폴더 목록, 기본 "docs README.md README.*.md core/contracts").
  - deck 무회귀: 그림 2 의 출처 줄 `Source: scv graph (built YYYY-MM-DD)`.
- **Non-Goals**
  - tree-sitter · 호출 그래프 · 코드 심볼 (Graft 의 영역 — 계획 C 어댑터로).
  - git numstat 동시변경 (계획 단위가 잡음이 적다 — 원재료 결론). 필요하면 다음 계획.
  - LLM 이 붙이던 의미 군집 이름 — 폴더·epic 이름으로 근사한다.
  - 래퍼 저장소 코드 변경 (core-sync 로 자동 반영; 계약 문서만 갱신).

## Approach Overview

1. **재료 수집(효과부)** — `SCV_GRAPH_DOCS` 의 md 파일, `scv/archive/*/PLAN.md`(+ `scv/promote/*/PLAN.md` 는 `kind: plan(active)` 로 표시), `scv/DECISIONS.md`.
2. **추출(순수부)** — 문서 링크(`](x.md)` 상대 경로, 앵커·URL 제외) · 계획→파일(frontmatter `scope:` 항목의 경로 + 본문 백틱 안 경로; 확장자 있는 상대 경로만, URL 제외) · 결정→계획(`refs: scv/archive/<slug>/PLAN.md`).
3. **그래프 만들기(순수부)** — 노드/링크 집합, 같은 계획이 건드린 파일 쌍마다 cochange 링크(weight = 계획 수, evidence = 슬러그들), 군집(파일은 상위 두 폴더, 계획은 epic 또는 연월), 핵심 노드(차수 상위 10).
4. **떨구기(효과부)** — `scv/.graph/graph.json`(결정적, `built_at` 만 시각) + `scv/.graph/GRAPH_REPORT.md`(## Communities · ## God Nodes · ## Co-change pairs · ## Sources).
5. **신선도** — graph.json mtime vs (문서·PLAN·DECISIONS 최신 mtime) → built|stale|missing. `ensure` = stale/missing 이면 build.
6. **영향 조회** — `impact <path>…`: 입력 경로마다 cochange 이웃(가중치 내림차순, 근거), touches 한 계획, 그 계획을 refers 한 결정, link 한 문서. 텍스트 + `--json`.
7. **소비처 갈아끼우기** — promote-helper/work/status/deck-context 는 `graph.sh ensure` 뒤 `GRAPH_STATUS: built` 와 경로를 찍는다. promote.md 6.2 의 매핑: 군집 = 폴더/epic, 핵심 노드 = god_nodes, 새 구성요소 = `:::new`, 근거 = evidence. deck.md 의 "run /graphify" 안내 → "그래프는 자동으로 만들어진다".
8. **graphify 제거** — 의존성 표·install-deps·host-profile 감지·gitignore·PROMOTE.md·run-dry 계약. SCV_GRAPH_SKILL_PATHS 는 래퍼가 계속 넘겨도 무시(호환).

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  listSources,          // 설정·저장소 → {docs[], plans[], decisions}                  (입구, 부수효과)
  extractDocLinks,      // (docPath, md 텍스트) → [{from,to}]                          순수
  extractPlanTouches,   // (slug, PLAN.md 텍스트) → {slug, epic, files[]}              순수
  extractDecisionRefs,  // (DECISIONS.md 텍스트) → [{decisionId, planSlug}]            순수
  buildGraph,           // (links, touches, refs) → {nodes, links}                     순수
  coChange,             // (touches) → cochange 링크 [{a,b,weight,evidence}]           순수
  assignCommunities,    // (nodes) → nodes+community                                   순수
  rankGodNodes,         // (nodes, links) → god_nodes[]                                순수
  renderGraphJson,      // (graph, built_at) → JSON 텍스트                             순수
  renderReport,         // (graph) → GRAPH_REPORT.md 텍스트                            순수
  writeOutputs,         // scv/.graph/ 에 쓰기                                          (출구, 부수효과)
)
impact = flow(readGraphJson /*효과*/, queryImpact /*순수: (graph, paths[]) → 결과*/, renderImpact /*순수*/)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | listSources | 설정 값·저장소 → 문서·계획·결정 파일 목록과 본문 | 부수효과 (입구) |
| 2 | extractDocLinks | 문서 경로·본문 → 상대 링크 쌍 | 순수 |
| 3 | extractPlanTouches | 슬러그·PLAN 본문 → {slug, epic, files} | 순수 |
| 4 | extractDecisionRefs | DECISIONS 본문 → 결정→계획 참조 | 순수 |
| 5 | buildGraph | 2·3·4 결과 → 노드·링크(link/touches/refers) | 순수 |
| 6 | coChange | 3 결과 → cochange 링크(가중치·근거) | 순수 |
| 7 | assignCommunities | 노드 → 군집 라벨(폴더 두 단계 / epic) | 순수 |
| 8 | rankGodNodes | 노드·링크 → 차수 상위 목록 | 순수 |
| 9 | renderGraphJson · renderReport | 그래프 → JSON / 보고 md | 순수 |
| 10 | writeOutputs | 텍스트 → scv/.graph/ 파일 | 부수효과 (출구) |
| 11 | queryImpact · renderImpact | graph.json · 경로들 → 이웃·계획·결정·문서 | 순수 |

- 부수효과 위치: 1(읽기)·10(쓰기)·impact 의 readGraphJson. 나머지는 문자열/JSON 만 받는다 — `check-purity.sh` 대상.
- 재사용: 신선도 mtime 비교는 promote-helper/work/status 에 셋이 따로 있던 것을 `graph.sh status` 하나로 모은다. deck-context 의 present/absent 판정도 같은 함수.

## Guardrails

- 새 외부 의존 없음. jq 없으면 `GRAPH_STATUS: unavailable` 로 조용히 넘어간다 — 어떤 명령도 막지 않는다.
- 그래프 빌드가 실패해도 promote/work/status/deck 은 진행한다(그림 2 생략 · IMPACT 생략) — 기존 "graceful degrade" 그대로.
- 결정적 출력: 같은 입력이면 graph.json 이 `built_at` 만 다르다(정렬 고정). 검사가 두 번 빌드해 비교한다.
- 경로 추출은 저장소 안의 실제 경로만 노드로(존재하지 않는 경로는 `missing: true` 로 표시, 링크는 유지) — 오래된 계획의 이름 바뀐 파일을 감춘다.
- graphify 스킬 자체(~/.claude/skills)는 건드리지 않는다 — SCV 가 참조를 끊을 뿐.
- deck 계약(DeckUI 린트·정적 mermaid) 변경 없음. `Source:` 줄의 문구만 `scv graph (built YYYY-MM-DD)`.
- 래퍼 계약: host-profile 의 `SCV_GRAPH_SKILL_PATHS` 를 받아도 오류 없이 무시. wrapper-integration 문서에 폐기 표시.

## Exit criteria

- All TESTS.md scenarios pass
- `grep -ri graphify` 가 core/ · docs/ · README* · 템플릿 · 검사에서 0 (CHANGELOG 이력과 scv/archive 는 제외).
- 이 저장소에서 `graph.sh build` ≤ 2초, 알려진 동시변경 쌍(on-stop.sh ↔ lib/help-state.sh) 이 근거 슬러그와 함께 나온다.
- promote 한 번(실제 계획 하나)에서 그림 2 가 새 그래프로 그려지고 deck 이 정적 mermaid 로 만들어진다.

## Suggested path

1. 검사부터: test-graph.sh(순수부 T1~T4, 빌드 T5~T8) 붉음.
2. lib/graph.sh 순수부 → graph.sh build/status/ensure/impact/report → 녹색.
3. 소비처 넷 + regression 앞단 + help/install-deps/host-profile 정리 → T9.
4. 규약 여섯 + PROMOTE.md + gitignore + 설정 예시 → run-dry 계약 갱신 → T10~T12.
5. 실제 promote 한 번으로 deck 확인, CHANGELOG, 래퍼 문서.

## 성공지표 (Metrics)

| 지표 | baseline (2026-09-17) | target |
|---|---|---|
| 그래프 빌드 의존성 | Python 스킬 + LLM 호출 | bash + jq, LLM 0 |
| 그래프 빌드 시간 (이 저장소, 55 계획) | 분 단위(LLM) | ≤ 2초 |
| promote 에서 그래프 관련 질문 | 최대 1회(3-way) | 0회 |
| 실제 계획이 그래프를 쓴 비율 | 0/52 | 그림 2 매번 자동 |
| 수정 범위 조회 | 없음 | `graph.sh impact` — work 헤더·regression 앞단 |
| graphify 참조 | 스크립트 5 · 규약 6 · 검사 ≈30 · gitignore 3 | 0 |

## 예외처리 (Edge cases)

- docs 폴더가 없는 프로젝트 → 문서 노드 0, 계획·동시변경만으로 그래프. 보고에 "docs: none".
- 보관 계획이 0 인 새 프로젝트 → 문서 링크만. impact 는 "근거 없음".
- PLAN.md 의 `scope:` 항목에 괄호 설명이 붙은 경우(`core/x.sh (설명)`) → 첫 경로 토큰만.
- 같은 파일이 다른 표기(`./a.sh`, `a.sh`)로 적힘 → 정규화(선행 `./` 제거).
- 백틱 안 경로가 URL·버전·설정 키인 경우 → 확장자 규칙과 슬래시 규칙으로 걸러 노드로 만들지 않는다.
- jq 없음 → status `unavailable`, 소비처는 그림 2 생략·IMPACT 생략, 종료 코드 0.
- scv/.graph/ 가 읽기 전용이거나 쓰기 실패 → 경고 한 줄, 진행.
- 심볼릭 링크 → 따라가지 않는다(가드 관례).

## Related Documents

- scv/raw/20260916-graft-partial-adoption-shared-conversation.md — "코드 그래프는 빌려 쓰고, 계획 그래프는 직접 만든다"
- scv/raw/stale/20260916-graph-dependency-decision.md — graphify 실사용 0/52 · Graft 문서 색인 안 함 · 사용자 목표
- core/protocols/promote.md Step 6.2 — 지금의 graph.json 소비 계약(군집·핵심 노드·링크)
- .graphify/docs/graphify-out/GRAPH_REPORT.md — 옛 보고의 절 이름(Community · God Nodes) 참고

## Risks / Open Questions

- 계획이 건드린 파일 추출은 텍스트 규칙이라 놓치거나 과잉 추출할 수 있다 — `missing: true` 표시와 검사 픽스처로 상한을 잡는다. 정확한 목록이 필요하면 ARCHIVED_AT 의 커밋 해시로 `git diff --name-only` 를 붙이는 것이 다음 단계.
- run-dry 의 graphify 계약 ≈30줄을 새 계약으로 바꾸는 작업이 가장 손이 많이 간다 — 문구 고정 검사는 새 문구를 고정한다.
- 래퍼가 SCV_GRAPH_SKILL_PATHS 를 계속 넘기는 동안 호환 유지 — 래퍼 쪽 정리는 별도 handoff.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs: #217 (앞 두 계획)
