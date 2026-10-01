# 다음 계획 후보 — /clear 뒤 복원 요약이 끝난 대화를 싣는다

출처: 계획 20261001-wookiya1364-restore-choice-questions 진행 중, /clear 뒤 첫 턴에서 발견(대화 scv/conversations/20261001-170437-restore-multiple-choice-questions.md Turn 4).
사용자 결정(2026-10-01): 이번 릴리스(0.64.0) 범위는 그대로 두고, 다음 계획에서 고친다.

## 확인한 것

- 세션 시작 훅(`core/template/hooks/on-session-start.sh:112-140`)은 대화 폴더의 frontmatter status 와 수정 시각을 모아
  `scv_resume_pick_active`(`core/scripts/lib/resume-recap.sh:55-64`)로 하나를 고른다 — status 가 `active` 인 것 중 가장 최근 것만.
- 계획으로 넘긴 대화(status: promoted)에도 작업 중 턴이 계속 붙는다(위 대화의 Turn 2 · 3 · 4). 그래도 고르는 대상에서 빠진다.
- 끝난 대화가 active 로 남아 있다: 20260930-105336-readme-refresh-progress-check(Turn 7 "여기서 마무리"),
  20260918-142708-still-running-status-check, 20260920-115402-remote-control-enable-scv-core, 20260930-001546-github-outreach-email-check.
- 그 결과 2026-10-01 22:44 /clear 뒤 요약은 9/30 README 대화 전문을 "active conversation (most recent)"로 싣고, 진행 중인 작업의
  대화는 싣지 않았다. 계획은 [진행 중] 목록에 떠서, 계획서 · 작업 기록으로 상태를 되짚을 수 있었다.

## 고칠 방향(다음 계획에서 정한다)

- 진행 중 계획(scv/promote/ 의 계획)의 raw_sources 에 있는 대화는 status 가 promoted 여도 고르는 대상에 넣는다 — 수정 시각이 가장
  최근이면 그것을 싣는다.
- 끝난 대화를 닫는 길: 대화를 마무리한 턴에서 status 를 바꾸거나, 오래 손대지 않은 active 대화를 요약에서 따로 알린다.
- 지킬 것: 복원 요약의 크기 상한, 맥 bash 3.2 · 리눅스에서 같은 동작.
