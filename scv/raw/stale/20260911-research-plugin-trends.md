---
title: Claude Code 플러그인 생태계 2026 조사 (0.46.1 다음 기능 후보 근거)
date: 2026-09-11
author: wookiya1364
source: 웹 조사 (배경 에이전트 3개: 웹 트렌드 · Claude Code 공식 문서 · SCV 인벤토리)
conversation: scv/conversations/20260911-110227-next-features-0-46-1.md
---

# 범례
- [확인] 출처 본문에서 직접 확인 · [추정] 2차 출처 종합 · [미발견] 검색으로 못 찾음

# 1. 인기 플러그인 · 마켓플레이스
- [확인] 공식 마켓 `claude-plugins-official` 자동 등록, 커뮤니티는 `anthropics/claude-plugins-community` (리뷰 후 `@claude-community`). 제출 전 `claude plugin validate` 필수. https://code.claude.com/docs/en/plugins
- [추정] 2026-07 공식 마켓 200+ 플러그인. https://designrevision.com/blog/official-claude-code-plugins
- [추정] 랭킹 상위: Superpowers(workflow) · Context7 · frontend-design · Claude Mem · security-guidance · code-review · typescript-lsp · planning-with-files · Caveman · skill-creator. https://designrevision.com/blog/best-claude-code-plugins
- [확인] obra/superpowers 284.7k★. https://github.com/obra/superpowers
- [추정] 강한 카테고리 3개: 워크플로 규율(plan→TDD→review), 메모리/컨텍스트, 1st-party 품질 게이트. https://github.com/hesreallyhim/awesome-claude-code

# 2. 플랫폼 신기능 (플러그인 저자 채택 중)
출처: https://code.claude.com/docs/en/whats-new , https://code.claude.com/docs/en/changelog
- [확인] `/skill-doctor` v2.1.261 (2026-09-04): 스킬별 context 비용 + 미사용 스킬 표시.
- [확인] `/plugin` 설치·활성·제거가 재시작 없이 적용 v2.1.268 (09-10). `--plugin-dir` 폴더 지정 v2.1.265.
- [확인] `PreModelSwitch`/`PostModelSwitch` hook, `SessionStart` resume hook 이 staleness 수신 v2.1.251 (08-28).
- [확인] `maxEffortLevel`, `/effort` 모델별 저장, `effort:` frontmatter 가 기본 effort 고정 모델(Fable 5 등)에서 무시되던 버그 수정 v2.1.267/268.
- [확인] hook 이벤트 32종 문서화(SessionStart · PreCompact · SubagentStart/Stop · WorktreeCreate/Remove · TeammateIdle …), `if:` 조건 hook, hook 이 `$CLAUDE_EFFORT` 수신. https://code.claude.com/docs/en/hooks
- [확인] plain stdout 이 컨텍스트로 들어가는 hook 이벤트는 `UserPromptSubmit`, `UserPromptExpansion`, `SessionStart`, `PostModelSwitch` 뿐.
- [확인] 플러그인 컴포넌트: skills / commands(legacy) / agents / hooks / .mcp.json / .lsp.json / monitors(experimental) / output-styles / bin/. 변수 `${CLAUDE_PLUGIN_DATA}` (업데이트 후 유지). https://code.claude.com/docs/en/plugins-reference
- [확인] Routines (`/schedule`, cron·API·GitHub webhook 트리거). https://code.claude.com/docs/en/routines
- [확인] Workflow 툴 (`agent()/parallel()/pipeline()`, `ultracode` opt-in). https://code.claude.com/docs/en/workflows
- [확인] Subagent `isolation: worktree`. https://code.claude.com/docs/en/sub-agents
- [확인] Skill frontmatter: `context: fork` + `agent:`, `background`, `disable-model-invocation`, `user-invocable`, `allowed-tools`(스킬 턴 동안만), `paths`, `effort`. description + when_to_use 합산 1,536자에서 잘림. SKILL.md 500줄 이하 권장. https://code.claude.com/docs/en/skills
- [추정] `claude plugin eval`: early access, 공식 문서 페이지 없음(404). 케이스 형식이 출처마다 다름(`evals/<case>/prompt.md`+`graders/` vs `evals.json`). ablation arm(플러그인 유무 2회 실행)이 핵심. https://www.matthewswong.com/en/blog/claude-code-plugin-eval-test-suite/ , https://github.com/wshobson/agents/blob/main/docs/plugin-eval.md
- [미발견] `RemoteTrigger` 공식 문서.
- [확인] Claude Tag (Team/Enterprise, admin 이 plugins·skills 를 채널에 부착). https://claude.com/docs/claude-tag/overview

# 3. 저자 베스트 프랙티스
- [확인] `claude plugin validate ./p --strict` (CI 권장). `plugin.json` `version` 이 캐시 키 → bump 할 때만 업데이트 전달. auto-update 뒤 hooks/MCP/LSP 는 `/reload-plugins` 필요.
- [추정] `claude plugin tag` + GHA 3단(validate --strict → `claude -p` 헤드리스 발화 확인 → 수동 release). https://www.matthewswong.com/en/blog/claude-code-plugin-ci-release-automation/
- [추정] 스킬 listing 이 context 1% 예산 초과 시 덜 쓰인 스킬부터 description 탈락 → "설치됐는데 안 뜨는" 무증상 실패.
- [확인] Anthropic 스킬 설계 글. https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills

# 4. spec-driven 경쟁작
- Superpowers: brainstorm → worktree → plan → subagent + 2단계 리뷰 → TDD → review. [확인]
- GitHub Spec Kit: 9개 명령 플러그인화(PR #1451), 111k★. [추정]
- BMAD v6 (6.8.0, 2026-05): 역할 에이전트 + 모듈. [추정]
- ccpm: PRD→epic→task→Issues, agentskills.io 표준으로 멀티 하네스. [확인] https://github.com/automazeio/ccpm
- planning-with-files: 플랜/진행 파일을 hook 으로 매 턴 재주입 → /clear·compaction 생존. [확인] https://github.com/othmanadi/planning-with-files
- 공통 신요소: worktree 격리 + 병렬 subagent, 플랜 파일 재주입, 멀티 하네스, eval/CI 게이트. SCV 의 archive 누적 회귀는 대응물 [미발견].

# 5. SCV 현재 상태 대조 (confirmed, 2026-09-11)
- 래퍼는 legacy `commands/` (skills/ 없음). hooks: UserPromptSubmit · Stop · PreToolUse×3 · UserPromptExpansion. SessionStart · PreCompact 없음.
- CI 5개 워크플로에 `claude plugin validate` 없음. evals/ · monitors/ 없음. `allowed-tools` 는 이미 사용 중.
- 문서상 열린 후속 작업: s3/r2 첨부 백엔드 1건. raw/ 21건 전부 stale. promote/ 비어 있음.
