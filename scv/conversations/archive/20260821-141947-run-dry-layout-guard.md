---
slug: run-dry-layout-guard
started_at: 2026-08-21T14:19:47+09:00
status: archived                # active | promoted | archived
promoted_to: scv/promote/20260821-wookiya1364-run-dry-layout-guard/
archived_at: 2026-08-21T14:26:59+09:00
---

## Turn 1 — 2026-08-21T14:19:47+09:00

**User**: (0.31.1 패치 제안에) 예 — 이대로 진행.

**Claude Code**: 0.31.0 릴리스 직후 Claude 래퍼의 core-sync 검증이 run-dry [15q] "TEMPLATE_VERSION files disagree" 로 실패. 원인: 그 검사가 core/TEMPLATE_VERSION 과 ../TEMPLATE_VERSION(저장소 루트 복사본)을 비교하는데, 래퍼는 페이로드를 자기 루트에 투영해 돌리므로 부모 복사본이 없다. Codex 래퍼는 vendor/scv-core/ 아래에서 돌려 통과. 고침: 루트 복사본이 있을 때만 비교, 없으면 단일 복사본 배치로 통과. 래퍼 배치를 흉낸 가드 1건 추가. 0.31.1 로 패치 릴리스.
