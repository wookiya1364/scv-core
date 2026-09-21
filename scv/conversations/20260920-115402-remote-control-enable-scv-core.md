---
slug: remote-control-enable-scv-core
started_at: 2026-09-20T11:54:02+0900
status: active
promoted_to: null
---

## Turn 1 — 2026-09-20T11:54:02+0900
protocol: 9d5440cb

**User**: (Remote Control 실행 결과 붙여넣기) `claude rc` → Enable Remote Control? y → spawn mode 1 (same-dir) 선택 → `·✔︎· Connected · scv-core · develop`, Capacity 1/32, 기기명 macbook-pro-local-cozy-locket, 접속 링크 `claude.ai/code?environment=<env id>`, "space to show QR code · w to toggle spawn mode". 별도 질문 없이 성공 출력만 공유. 직전 맥락: 홈 디렉터리에서 실행해 "Workspace not trusted"로 실패했고, 프로젝트 디렉터리로 옮겨 재실행하도록 안내함.

**Claude Code**: 원격 제어 연결 성공 확인. 출력에서 확인된 사실: 연결 상태 Connected, 대상 프로젝트 scv-core, 브랜치 develop, 동시 세션 1/32 사용, spawn mode는 same-dir(새 세션이 현재 디렉터리를 공유). 이 터미널을 닫거나 Ctrl+C를 누르면 원격 제어가 끊긴다는 점만 주의 사항으로 전달. 검증 기준은 모바일 앱 Code 탭 또는 claude.ai/code에서 이 세션이 보이는지 확인.

이 턴에서 함께 처리한 것: SCV 출력 언어를 한국어로 저장(설정 파일이 없어 이번에 생성됨). 프로젝트 진단 결과 이 디렉터리는 아직 hydrate 되지 않은 상태 — 사용자가 원할 때 진행하도록 한 줄로만 안내하고 강권하지 않음. spawn mode를 worktree로 바꾸려면 터미널에서 w 키.
