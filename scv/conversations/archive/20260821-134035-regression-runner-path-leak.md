---
slug: regression-runner-path-leak
started_at: 2026-08-21T13:40:35+09:00
status: archived                # active | promoted | archived
promoted_to: scv/promote/20260821-wookiya1364-regression-runner-path-leak/
archived_at: 2026-08-21T13:56:02+09:00
---

## Turn 1 — 2026-08-21T13:40:35+09:00

**User**: (누적 회귀 1건 실패 보고에 대해) 예 — fix 계획 추가, 같은 PR.

**Claude Code**: 어제 보관한 plain-answers-enforcement 계약이 러너 안에서만 T6(run-dry) 실패. 원인: 러너가 scv_init_paths 로 export 한 SCV_DIR·RAW_DIR·STATE_FILE·PROMOTE_DIR·ARCHIVE_DIR 가 자식 시나리오에 상속돼, run-dry [19] 의 임시 프로젝트 안 work.sh 가 이 저장소의 경로를 본다. 단독·timeout 환경에서는 972/972 통과, 5개를 빼면 러너 안에서도 통과(실측). 0818 의 SCV_AUTOSYNC_RUNNING 누수와 같은 종류 — 같은 방식(env -u)으로 러너 한 곳만 고친다.
