---
topic: graphify · Graft 둘 다 꼭 필요한가 — 종속성 최소 + 효과 최대
source: 이 세션 조사 (2026-09-16 21:2x), 공유 대화 원재료 20260916-graft-partial-adoption-shared-conversation.md
---
# 사실 (확인)
- graphify 실사용: scv/archive 52개 계획 중 PLAN.md 에서 graphify/graph.json 을 참조한 것 1개 (20260804 team-journal). 그래프는 2026-09-11 에 빌드됨(graph.json 346KB) 이나 그 뒤 계획들이 쓰지 않음.
- graphify 는 Python 기반 스킬(pipx/venv 감지 코드 있음) + LLM 빌드 비용(cost.json 존재). 의존성 무게가 "스킬 하나" 가 아니라 Python 런타임 + 패키지.
- SCV 소비 계약: `.graphify/docs/graphify-out/graph.json` `{nodes:[{id,label,community}], links:[{source,target}]}` + GRAPH_REPORT.md(Community labels · God nodes · Surprising connections). 소비처 4곳: promote 다이어그램2, deck 큰 그림, status 신선도, work.sh.
- 이 저장소 docs/ 는 md 5개, 문서 간 링크 14개. 링크 그래프는 grep 으로 즉시 나옴.
- 보관 계획은 PLAN.md 본문에 건드리는 파일 경로를 적고(형식 자유), FEATURE_ARCHITECTURE.md 를 갖고, ARCHIVED_AT.md 53개 중 24개에 커밋/PR 흔적. 계획 보관 커밋 메시지는 6건만.
- Graft 는 문서를 색인하지 않음 → graphify 자리를 대체 못 함. Graft 조회(ask/blast)는 SCV 와 충돌 없음, 훅·statusline 만 충돌.
# 결론 (제안)
- 둘 다 필수 아님. graphify 는 뺀다(효과 근거 없음 + 무게). Graft 는 의존이 아니라 "있으면 인지" 어댑터로 나중에.
- 효과는 SCV 자체 그래프로 올린다 — 의존성 0(bash+jq+git): (1) docs/ 마크다운 링크 그래프, (2) 보관 계획 → 건드린 파일(PLAN.md 경로 + ARCHIVED_AT 커밋의 git diff --name-only), (3) 파일 쌍 동시변경 가중치 + 근거(plan/DECISIONS 링크). 출력은 **기존 graph.json 계약과 같은 모양**(nodes/links/community + god nodes 보고) 으로 떨궈 소비처 4곳을 안 고친다. community 는 LLM 라벨 대신 디렉터리/계획 묶음으로 근사.
- 잃는 것: LLM 이 붙이던 의미 군집 라벨. 얻는 것: "왜"(계획·결정) 와 정적 연결 없는 동시변경 — 두 도구 다 못 주는 것.

# 사용자 목표 (2026-09-16 21:4x, 확정) — 네 계획 공통 수용 기준
- 토큰을 줄인다.
- 수정 범위를 빠르고 정확하게 찾는다.
- 전체적으로 SCV 에 도움이 되어야 한다 (특정 명령만 좋아지고 다른 데가 나빠지면 안 됨).
- /scv:deck 은 기존과 마찬가지로 잘 되어야 한다 (큰 그림·As-Is 다이어그램 포함 — graphify 제거 뒤에도 같은 입력 계약으로).
- 확정 순서: B(린트 지연) → A(매 턴 비용) → D(자체 그래프, graphify 제거) → C(Graft 어댑터, 선택).
