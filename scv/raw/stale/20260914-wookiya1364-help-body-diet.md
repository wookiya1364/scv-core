---
slug: install-check-0-47-0
started_at: 2026-09-14T09:25:53+09:00
status: active
promoted_to: null
---

## Turn 1 — 2026-09-14T09:25:53+09:00

**User**: 설치했는데 잘 동작하나?

**Claude Code**: 0.47.0 설치 확인. 확인된 것: (1) installed_plugins 가 0.47.0, 오늘 갱신됨 (2) commands/ 없고 skills/ 15개 — /scv:help 가 skills/help 에서 떴다 (3) SessionStart(compact|clear|resume) 훅 등록, /clear 직후 이 세션 첫 턴에 되찾기 recap 이 실제로 실렸다 (4) UserPromptSubmit 훅이 오늘 저널·preflight·쉬운말 지시를 실었다. 미확인: T16 (진행 중 계획 있는 프로젝트에서 slug 언급) — 이 저장소엔 진행 중 계획이 없어 여기서는 검증 불가. /skill-doctor 실측 미실시. 관찰: preflight 가 이 저장소를 '미hydrate'·설정파일 없음으로 진단 — 코어 저장소 자체는 원래 hydrate 대상이 아니므로 예상 범위(추정).

## Turn 2 — 2026-09-14T09:27:36+09:00

**User**: 응 너가해봐 (/skill-doctor 를 직접 돌려봐)

**Claude Code**: /skill-doctor 는 이 세션에서 스킬로 노출되지 않아 CLI 등가인 `claude plugin details scv@scv-claude-code` 로 실측. 상시 ~2,327 tok, 호출 시 promote 26.2k · work 16.7k · help 11.1k. 결과를 scv/raw/20260914-wookiya1364-skill-cost-measurement.md 에 raw 로 저장.

## Turn 3 — 2026-09-14T09:29:56+09:00

**User**: 그러면 help 본문 다이어트 하면서, 성능은 유지할 수 있어?

**Claude Code**: 가능하다고 본다. 근거(확인): help 본문 29,292 바이트(~11.1k tok) 중 (a) 매 턴 훅이 이미 싣는 쉬운말 규칙 1.2k·조사 위임 규칙 1.5k 바이트가 중복, (b) 분기 전용 본문(hydrate 제안 3.7k·언어 첫 설정 1.8k·옛 대화 이사 1.2k·archive 검색 1.3k·promote 넘김 3.2k = 11.2k 바이트)은 그 분기가 뜰 때만 필요. 세 단계 제안: 1) 훅 중복 제거(~1k tok) 2) 설명문 압축(~2k tok) 3) 분기 본문을 skills/help/ 아래 별도 파일로 빼고 분기 진입 시 읽게(~4k tok). 합쳐 ~11k→~4-5k tok 추정. 성능 유지 장치: 기존 archive 의 help 테스트 4벌 + 회귀 스위트 + 전후 `claude plugin details` 실측. 위험(추정): 3단계는 래퍼 core-sync 투영이 SKILL.md 한 파일만 옮기는 것으로 보여 부속 파일 투영 지원이 필요할 수 있음 — 미확인.

## Turn 4 — 2026-09-14T09:39:51+09:00

**User**: 너의 권고대로 가자.

**Claude Code**: 승인. 3단계(훅 중복 제거·설명문 압축·분기 본문 분리)를 한 계획으로, 래퍼 투영 확인을 첫 작업으로. promote 로 넘긴다.
