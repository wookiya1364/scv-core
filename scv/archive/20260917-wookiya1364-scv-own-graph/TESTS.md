# Test Plan — SCV 자체 그래프 — 문서·계획·동시변경을 의존성 0 으로, graphify 제거

## Overview

순수부(추출·그래프·동시변경·군집·핵심 노드·영향 조회)를 문자열 입력으로 검증하고, 픽스처 프로젝트와 이 저장소에서 빌드·신선도·영향 조회를 실제로 돌린다. 소비처 넷이 새 그래프를 쓰고, graphify 참조가 0 이며, deck 이 그대로 만들어지는지를 본다.

## Test scenarios

### T1. 문서 링크 추출 (순수)
- **Setup**: md 본문 샘플 — 상대 링크 `](architecture.md)`, `](../core/contracts/guard.md)`, 앵커 `](#절)`, URL `](https://…)`, 이미지 `![](x.png)`.
- **Run**: extractDocLinks
- **Expected**: 상대 md 링크 2개만, 문서 기준 경로로 정규화. 앵커·URL·이미지 제외.
- **Pass criterion**: 정확 일치.

### T2. 계획→파일 추출 (순수)
- **Setup**: PLAN.md 샘플 — `scope:` 항목 3개(하나는 `core/x.sh (설명)`), 본문 백틱 `core/y.sh`, `SCV_LANG`, `0.49.1`, `https://a/b.md`, `./core/z.md`.
- **Run**: extractPlanTouches
- **Expected**: files = core/x.sh · core/y.sh · core/z.md (+ scope 나머지), 설정 키·버전·URL 제외, `./` 제거, 중복 제거, epic 값 추출.
- **Pass criterion**: 정확 일치.

### T3. 동시변경 (순수)
- **Setup**: 계획 A{x,y,z}, B{x,y}, C{y}.
- **Run**: coChange
- **Expected**: x–y weight 2 evidence [A,B] · x–z 1 [A] · y–z 1 [A]. 쌍은 사전순, 자기 쌍 없음.
- **Pass criterion**: 정확 일치.

### T4. 군집·핵심 노드 (순수)
- **Setup**: 파일 core/scripts/a.sh, core/scripts/lib/b.sh, docs/c.md, 계획 P(epic E), Q(epic 없음, 슬러그 20260917-…).
- **Run**: assignCommunities · rankGodNodes
- **Expected**: 군집 core/scripts · core/scripts(lib 포함) · docs · E · 2026-09. 핵심 노드는 차수 내림차순·동률은 id 사전순, 최대 10.
- **Pass criterion**: 정확 일치 + 두 번 호출 결과 동일.

### T5. 픽스처 프로젝트 빌드
- **Setup**: 임시 프로젝트 — docs 2개(서로 링크), 보관 계획 3개(scope 겹침), DECISIONS 에 refs 2개, promote 계획 1개.
- **Run**: `graph.sh build`
- **Expected**: `scv/.graph/graph.json`(jq 로 스키마: version, built_at, nodes[kind∈doc|file|plan|decision], links[kind∈link|touches|refers|cochange, weight, evidence], god_nodes, communities) + `GRAPH_REPORT.md`(## Communities · ## God Nodes · ## Co-change pairs · ## Sources). 두 번 빌드하면 built_at 을 뺀 JSON 이 바이트 동일.
- **Pass criterion**: 스키마·절·결정성.

### T6. 이 저장소 빌드
- **Setup**: 저장소 루트.
- **Run**: `time graph.sh build`
- **Expected**: ≤ 2초, 노드 > 50, cochange 링크 `core/template/hooks/on-stop.sh`–`core/scripts/lib/help-state.sh` 존재하고 evidence 에 `20260916-wookiya1364-answer-lint-turn-race` 포함.
- **Pass criterion**: 시간·존재·근거.

### T7. 신선도
- **Setup**: T5 픽스처.
- **Run**: `graph.sh status` (빌드 전) → build → status → PLAN 하나 touch → status → `ensure` → status
- **Expected**: missing → built → stale → built. ensure 는 stale/missing 에서만 빌드(built 이면 파일 mtime 불변).
- **Pass criterion**: 다섯 출력.

### T8. 영향 조회
- **Setup**: T5 픽스처.
- **Run**: `graph.sh impact core/x.sh` · `--json`
- **Expected**: 함께 바뀌는 파일(가중치 내림차순, 근거 슬러그), 건드린 계획, 얽힌 결정, 링크한 문서. 없는 경로 → "근거 없음" 한 줄, 종료 0. `--json` 은 같은 내용의 JSON.
- **Pass criterion**: 항목 넷 + 없는 경로 처리.

### T9. 소비처 넷 + 회귀 앞단
- **Setup**: T5 픽스처.
- **Run**: promote-helper.sh · work.sh <slug> · status.sh · deck-context.sh · regression.sh --dry(변경 파일 2개)
- **Expected**: `GRAPH_STATUS: built` + `GRAPH_DIR: scv/.graph`(GRAPHIFY_SKILL 줄 없음) · work.sh 에 `=== impact (scv graph) ===` 블록(계획 scope 파일들) · status 의 docs graph 절이 "scv graph" · deck-context `SCV_GRAPH: present` · regression 앞단에 영향 목록(선택 결과는 동일).
- **Pass criterion**: 다섯 출력.

### T10. graphify 참조 0
- **Setup**: 없음
- **Run**: `grep -ri graphify core docs README.md README.*.md core/template tests` (CHANGELOG·scv/archive 제외)
- **Expected**: 0건. `scv_graph_skill_available` 정의 없음. install-deps --check/--print 출력에 graphify 없음. help.sh 의존성 표에 graphify 행 없음.
- **Pass criterion**: 전부 0.

### T11. gitignore · 설정
- **Setup**: 없음
- **Run**: 템플릿 fragment · core/.gitignore · .gitignore 확인, 설정 예시 `_doc` 에 SCV_GRAPH·SCV_GRAPH_DOCS.
- **Expected**: `scv/.graph/` 있음, `.graphify*` 줄 없음. `SCV_GRAPH=off` 면 graph.sh ensure 가 아무것도 만들지 않고 `GRAPH_STATUS: off`.
- **Pass criterion**: 세 파일 + 스위치.

### T12. 규약·deck 무회귀
- **Setup**: 없음
- **Run**: `run-dry.sh` · 코어 검사 전체 · `test-deck-doc.sh` · 실제 promote 폴더 하나에 `Source: scv graph (built 2026-09-17)` 그림 2 를 넣고 `deck.sh`
- **Expected**: 전부 녹색. deck 린트 0, 정적 mermaid 내장(embedded diagrams ≥ 2).
- **Pass criterion**: 녹색 + deck 산출물.

## How to run

```bash
bash core/tests/test-graph.sh && bash core/tests/run-dry.sh
```

## Pass criteria

- T1~T12 전부 녹색.
- 코어 검사 전체 · 루트 계약 러너 녹색.
- 다음 promote 에서 그림 2 가 새 그래프로 그려지고 deck 이 정적으로 만들어진다.

## Related Documents

- core/tests/test-help-router-diet.sh — 임시 프로젝트 하네스 방식(재사용)
