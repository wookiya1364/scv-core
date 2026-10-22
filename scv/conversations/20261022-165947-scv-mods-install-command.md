---
slug: scv-mods-install-command
started_at: 2026-10-22T16:59:47+0900
status: promoted
promoted_to: scv/promote/20261022-wookiya1364-update-installs-mods/
---

## Turn 1 — 2026-10-22T16:59:47+0900
protocol: ad1501d7

**User**: scv-mods 만들었는데, 업데이트 및 설치방법이 좀 불편해. (다른 세션 링크 — 대화 내역) 그래서 scv내에서 mods 설치 및 업데이트까지 진행할 수 있는 명령어가 있으면 좋을 거 같은데, 가능할까? (붙여 넣은 다른 세션 답: 리눅스 설치 · 업데이트 순서)

**다시 쓴 요청**: 변경 없음 — scv-mods 의 모드를 SCV 안에서 한 명령으로 설치 · 업데이트(마켓 추가 · 인증 확인 · 전후 버전 표시 · 다시 불러오기 안내)할 수 있는지 판단하고, 둘 곳을 장단과 함께 추천해 줘. 만들기는 결정 뒤 계획으로. 붙여 넣은 다른 세션 답은 자료로만. [SCV 원칙 적용 — 단위 표]

**Claude Code**: 가능(확인 — claude plugin CLI 에 marketplace add/update, install, update, list 가 있고 셸에서 돎; 이 맥 scv-hello@scv-mods 745b604 설치됨). 불편의 실체(scv-mods 대화 기록): 두 줄 명령, 비공개 저장소 인증, 버전 고정 시 '이미 최신', 다시 불러오기 필요. 공유 링크(cshk_)는 읽기 도구가 형식을 받지 않아 못 읽음. 둘 곳 4안: 코어 명령(17번째 — codex 는 이 모드를 못 씀, 두 봇 멈춤) / Claude 래퍼 전용 명령(추천) / 기존 업데이트 명령 확장 / mods 저장소 스크립트. 선택 창으로 물음.

## Turn 2 — 2026-10-22T17:01:41+0900
protocol: ad1501d7

**User**: (선택 창) 둘 곳 = 기존 업데이트 명령 확장, 범위 = 설치 · 업데이트 + 목록 · 삭제

**Claude Code**: 확인: 업데이트 명령은 코어 명령 목록에서 이미 '래퍼 몫'(owner adapter)이라 코어 명령 수 그대로, 봇 안 멈춤. 코어 규약(protocols/update.md)은 '호스트의 마켓 방식만 · 프로젝트 파일 안 바꿈 · 다시 불러오기 안내'를 요구 — 모드 설치도 이 안에 맞음. Claude 래퍼의 update.sh 는 지금 버전 진단만(읽기 전용 설명). 할 일: Claude 래퍼 update 에 모드 묶음(scv-mods) 설치 · 업데이트 · 목록 · 삭제, 전후 버전, 비공개 저장소 인증 확인, 다시 불러오기 안내; Codex 는 '모드 없음' 한 줄. 계획으로 넘길지 선택 창.

## Turn 3 — 2026-10-22T17:04:24+0900
protocol: ad1501d7

**User**: (선택 창) 네, 계획 만들기

**다시 쓴 요청**: 이 대화를 근거로 promote 계획을 만들어 줘: Claude 래퍼의 SCV 업데이트 명령이 scv-mods 모드를 설치(없으면 마켓 추가 후) · 업데이트(전후 버전 표시) · 목록 · 삭제하고, 비공개 저장소 인증이 없으면 할 일을 알려 주며, 끝에 다시 불러오기를 안내하게. 코어 명령 수는 그대로, Codex 는 '모드 없음' 안내. 계획 · 시험 문서만 쓰고 구현은 따로 승인받아. [SCV 원칙 적용 — 단위 표]

**Claude Code**: 계획 scv/promote/20261022-wookiya1364-update-installs-mods/ (PLAN.md · TESTS.md T1–T11) 작성, 결정 기록(adopted). 확인: claude plugin list --json [--available] · marketplace list --json 으로 상태를 읽을 수 있음. 설치 · 삭제는 실행 전 선택 창, 업데이트는 전후 버전. 그림 · 구현 여부는 선택 창.

## Turn 4 — 2026-10-22T17:16:35+0900
protocol: ad1501d7

**User**: (선택 창) 그림 건너뛰기, 구현 → 릴리스까지; 중간 확인 '이대로 계속'

**다시 쓴 요청**: 계획 update-installs-mods 를 구현해 줘: Claude 래퍼의 SCV 업데이트 명령에 모드 목록 · 설치(마켓 없으면 추가부터) · 업데이트(전후 버전) · 삭제와 인증 실패 안내 · 다시 불러오기 안내를 넣고, 코어 업데이트 규약에 선택 절, Codex 는 '모드 없음' 한 줄. TESTS T1–T11 로 고정하고 처음 돌아가는 순간 실제 출력을 보여 준 뒤, 보관 승인 → 코어 · 두 래퍼 릴리스까지. [SCV 원칙 적용 — 단위 표]

**Claude Code**: 구현: Claude 래퍼 scripts/update-mods.sh(순수 mods_plan · mods_summary + 양 끝 CLI), update.sh 는 'mods' 일 때만 넘김, 스킬 문서 모드 절(설치 · 삭제 전 확인), README 3개 언어, 래퍼 몫 목록 · CI 등록, tests/test-update-mods.sh 28/28. 이 맥 실제: 목록 · scv-hello 업데이트(이미 최신 745b604) — 처음 결과 보고 '이대로 계속'. 바뀐 것 없을 때 다시 불러오기 안내 빼도록 고침. Codex: 업데이트 규약 · 스킬에 '모드 없음' + 시험 2개(처음에 Claude 명령 표기를 써 호스트 검사에 걸려 고침). 코어: update 규약 선택 절 6, 0.70.0. 회귀 시험 진행 중.

## Turn 5 — 2026-10-22T17:23:50+0900
protocol: ad1501d7

**User**: 명령어가 너무길어 scv:mods-install 이런게 낫지않아?? 파라메터 추가는 구려

**다시 쓴 요청**: 변경 없음 — 모드 명령을 '/scv:update mods install …' 대신 인자 없는 짧은 이름(scv:mods-install 같은)으로 바꾸는 게 나은지, 명령 수 · 동기화 봇 · Codex 영향까지 따져 모양을 추천하고 고르게 해 줘. 고른 뒤 계획 · 구현을 고친다. [SCV 원칙 적용 — 단위 표]

**Claude Code**: 동의 — 짧은 이름이 낫다. 확인: 래퍼의 스킬 집합은 코어 명령 목록(actions.json)과 같아야 해 새 명령은 코어 명령이 되고(16→늘어남), 0.69.0 때처럼 두 동기화 봇이 멈춰 손 동기화 필요, Codex 에도 같은 이름 스킬('모드 없음')이 생김. 인자 없이: 모드 이름은 설치 가능 목록에서 선택 창으로 고름. 모양 선택 창: /scv:mods(업데이트+목록) + mods-install + mods-remove (추천) / 넷 다 따로 / 지금 그대로.

## Turn 6 — 2026-10-22T17:35:13+0900
protocol: ad1501d7

**User**: (선택 창) 명령 3개

**다시 쓴 요청**: 모드 명령을 인자 없는 셋으로 바꿔 줘: /scv:mods 는 설치된 모드 전부 업데이트 + 목록, /scv:mods-install · /scv:mods-remove 는 선택 창에서 모드를 고른다. 코어 명령 목록(래퍼 몫)과 규약, Claude 래퍼 스킬 · 엔진, Codex 스킬('모드 없음')을 맞추고, 업데이트 명령은 원래대로 되돌려. 계획 · 시험을 먼저 고치고, 통과하면 보관 승인 → 코어 · 두 래퍼 릴리스. [SCV 원칙 적용 — 단위 표]

**Claude Code**: 코어: 명령 19개(래퍼 몫 셋), 규약 mods · mods-install · mods-remove, 가드 receipt 목록 · 검사 수 · help 목록 · verify-core, 0.70.0 변경 기록 새 모양. 업데이트 규약 · 래퍼 업데이트 스킬은 되돌림. Claude: 엔진 scripts/mods.sh(인자 없음 = 업데이트+목록, candidates · list = 보기), 스킬 셋, 명령 목록 다섯 곳 19, README. 실제 실행: /scv:mods 한 번에 업데이트(이미 최신) + 목록. 래퍼 시험 41/41. 새 코어를 넣은 Claude 사본: 계약 · 정책 · 설명 · 투영 검사 통과. Codex: 스킬 셋 + 규약 셋 + 목록 19 + README. 계획 · 시험 문서를 새 모양으로 다시 씀. Claude 전체 실행 · Codex 사본 검사 진행 중.

## Turn 7 — 2026-10-22T23:38:43+0900
protocol: 08eca6da

**User**: 어디까지 했어

**Claude Code**: 구현 · 시험은 끝, 커밋 · 보관 · 릴리스는 아직(확인). 세 저장소 모두 작업 브랜치에 변경만 있고 커밋 0 — 코어 22 · claude 14 · codex 11 파일. 시험: 계획 시험 41/41, codex 사본 코어 61/61, claude 전체 실행 통과, codex 검증 명령 19개, codex 플러그인 시험은 맥 전용 기존 실패 1건만. 다음: 계획 보관 승인(선택 창) → 코어 PR · 0.70.0 → 두 래퍼 손 동기화 → 래퍼 릴리스. 결과물 변화 없음.
