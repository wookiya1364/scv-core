# 스킬 비용 실측 — 0.47.0 (2026-09-14)

출처: `claude plugin details scv@scv-claude-code` (Claude Code 2.1.270). 세션 안 `/skill-doctor` 는 사용자 터미널에서 '(no content)' 만 찍혔음 — 원인 미확인.

```
scv 0.47.0
  Description: Claude Code plugin for team workflows. Every change becomes a plan + tests before merging; archived tests accumulate into a self-running regression suite. Run /scv:help to start. 15 slash commands, no flags to memorize.
  Source: scv@scv-claude-code

Component inventory
  Skills (15)  codegen, deck, handoff, help, install-deps, promote, regression, report, routine, set-models, status, sync, update, work, workspace
  Agents (1)  scv-investigator
  Hooks (5)  UserPromptSubmit, Stop, SessionStart, PreToolUse, UserPromptExpansion  (harness-only — no model context cost)
  MCP servers (0)
  LSP servers (0)

Projected token cost
  Always-on:   ~2,327 tok   added to every session

Per-component (rounded)
  component         always-on  on-invoke
  codegen                ~150      ~5.8k
  report                 ~140      ~1.3k
  work                   ~170     ~16.7k
  install-deps           ~140      ~2.2k
  help                   ~180     ~11.1k
  handoff                ~140      ~2.4k
  set-models             ~150      ~2.4k
  promote                ~210     ~26.2k
  routine                ~130      ~3.1k
  workspace              ~140      ~1.7k
  status                 ~100      ~2.1k
  deck                   ~170      ~4.7k
  update                 ~110      ~1.5k
  regression             ~160      ~4.5k
  sync                   ~110      ~3.3k
  scv-investigator       ~120       ~600

  On-invoke cost is paid each time a skill or agent fires.
  Token counts are estimates and may differ from actual usage.
```

## 읽기
- 상시 비용 ~2,327 tok/세션 (15 스킬 설명 + 에이전트 1). 훅 5개는 모델 컨텍스트 비용 0.
- 호출 시 큰 셋: promote ~26.2k · work ~16.7k · help ~11.1k. help 는 매 턴 강제 호출이라 실질 비용이 가장 큼.
- 후속 후보: CHANGELOG 0.47.0 항목에 실측 한 줄 추가 / help SKILL.md 본문 다이어트 (매 턴 11k).
