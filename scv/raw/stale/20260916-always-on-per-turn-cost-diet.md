---
topic: always-on 매 턴 비용 다이어트 (help 스킬 본문 재주입)
source: scv/conversations/20260914-092553-install-check-0-47-0.md (Turn 55~56, 2026-09-16)
---
# 문제
- SCV_ALWAYS_ON 이 매 턴 "help 액션을 부르라" 고 하고, Skill 호출은 매번 help SKILL.md 본문 전체(≈4k 토큰)를 컨텍스트에 다시 싣는다. 여기에 help.sh 실행 + journal-append 까지 턴당 도구 호출 3~4번.
- 사용자 체감: "되게 오래걸리네" (2026-09-16 21:07). 원격(휴대폰)에서 한 마디마다 수십 초.
- 0.49.0 의 "규약은 세션당 한 번" 은 full.md(≈6k) 만 줄였고, SKILL.md 본문(≈4k)은 매 턴 그대로.
# 후보 (미결)
- SKILL.md 를 "매 턴 필요한 것" 만 남기고 나머지를 full.md 로 이동 (이미 한 번 다이어트했음 — 남은 것의 재분류).
- 짧은 턴(확인·감사)은 스킬 호출 없이 훅이 바로 기록하는 경로 — 단, "판단하지 말고 부르라" 계약과 충돌하므로 기록 보장을 훅이 대신해야 함.
- Skill 재호출 시 본문을 다시 싣지 않는 호스트 기능이 있는지 확인 (0.50.0 에서 "Re-invocation … previously loaded" 문구가 뜨지만 본문은 여전히 실림 — 확인됨).
# 검증 기준 후보
- 턴당 컨텍스트 증가량 측정(전/후), 기록 누락 0 (회귀 검사 test-help-* 유지).

# 실측 (2026-09-16 22:4x, 확인)
- 매 턴 스택(진단 변동 없는 턴): help SKILL.md 10,916B + 훅 블록 ≈1.5K(강제 1,082 + 쉬운말 454 + preflight 한 줄) + 헬퍼 출력 197B ≈ 12.6KB. 진단 변동 턴은 preflight 가 3,266B(진단 1,677 + 권장 행동 856 + Learn more 615).
- 라우터(core/protocols/help.md 9,670B) 절별: Answer shape 2,672 · Every turn 1,648 · Plain language 1,207 · Run script 875 · Protocol once 853 · Deep questions 710 · Never hand back 674 · Language 650 · Final 197.
- 0.49 결정(help-규약은-세션당-한-번만) 의 path delta: "라우터 상한 4,000B 목표 → 9,374B 실측(답 모양 절을 매 턴 유지하기로 — 사용자의 잊음 우려에 대한 답)". 0.50.0 이 그 우려를 지문 메아리 + 답 모양 린트로 구조적으로 막았으므로, 이제 4,000B 목표를 완주할 수 있다.
- 제약: run-dry [15p] — "## Language preference" 가 있는 프로토콜은 바로 뒤에 동일 문구의 "## Plain language first" 를 가져야 한다(≥13개). help.md 에서 둘을 함께 full.md 로 옮기면 대상에서 빠진다. test-help-shape.sh 는 help.md 의 Answer shape 절을 고정(PROTO) — 위치를 full.md 로 바꾸면 검사도 따라가야 하고, 20260903 help-answer-shape 의 TESTS 가 위치를 못박았다면 supersede 선언.
- 상한 검사(test-help-budget): BODY_MAX 10,000 · FULL_MAX 8,000 · TURN_MAX 12,000 · TOTAL 32,000 — 다이어트 뒤 BODY/TURN 을 낮춰 잠그고 FULL 은 올린다.
