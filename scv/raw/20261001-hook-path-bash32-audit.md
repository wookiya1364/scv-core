# 다음 계획 후보 — 훅 경로의 bash 3.2 점검 · PR 도구 에픽 브랜치

출처: 계획 20261001-wookiya1364-auto-turns-pr-base-fixes 검증 중 발견(대화 scv/conversations/20261001-083005-auto-turns-pr-base-fixes.md Turn 2~3).
사용자 결정(2026-10-01): 찾은 두 줄(아래 확인한 것 둘째 · 셋째)은 0.63.0 에서 고치고, 나머지 점검은 다음 계획으로 넘긴다.

## 확인한 것

- 훅은 PATH 의 bash 로 돈다. 맥 기본 PATH 면 bash 3.2.
- `core/scripts/lib/help-state.sh` 의 스위치 함수가 `${v,,}`(bash 4 전용)를 써서, 3.2 로 도는 매 턴 훅에서 턴 세기 · 진단 줄이기가
  통째로 꺼졌다 — 0.63.0 에서 고침(case 비교), `core/tests/test-help-load-once.sh` [T7] 이 맥 CI 에서 지킨다.
- `core/scripts/help.sh:375` 가 빈 목록을 `"${a[@]}"` 로 읽어, 빠진 도구가 한 갈래에만 있으면 bash 3.2 + set -u 에서 멈춰 진단 아래쪽이
  잘렸다(위 수정이 켜지면 잘린 진단끼리 비교해 틀린 "변동 없음" 이 나올 수 있었다) — 0.63.0 에서 고침, 같은 [T7] 이 지킨다.
- 액션 스크립트 10개는 bash 4 미만이면 Homebrew bash 로 갈아탄다(`BASH_VERSINFO` 검사): work · status · regression · readpath ·
  promote-helper · pr-helper · journal-append · install-deps · deck · deck-context. Homebrew bash 가 없으면 "SCV requires bash 4+" 로 끝난다.
- 갈아타지 않는 훅 경로 스크립트: 훅 넷(on-user-prompt · on-stop · on-session-start · guard), help · help-state · model-prompting ·
  recap · record-read · decisions-append.

## 후보(영향 미확인)

| 위치 | 문법 | 부르는 곳 | 갈아탐 |
|---|---|---|---|
| lib/record-index.sh:44 | `${m,,}` | recap · record-read · decisions-append | 없음 |
| lib/author.sh:39 | `${in,,}` | decisions-append | 없음 |
| lib/author.sh:39 | `${in,,}` | journal-append · promote-helper | 있음 |
| decisions-append.sh:64 | `${t,,}` | (직접) | 없음 |

- 세션 시작 요약(recap)이 3.2 에서 깨지는지, 그 줄까지 실제로 닿는지 확인하지 않았다.
- Homebrew bash 가 없는 맥에서는 작업 기록 쓰기(journal-append)가 끝나 버리고, 훅이 오류를 삼키므로 기록이 조용히 빠질 수 있다(코드로 본 추정).

## 정할 것

- 훅 경로를 3.2 에서도 되게 할지(지금 force-help · model-prompting · graft · help-state 방식), 갈아타기로 통일할지.
- 확인 방법: 맥 CI 에서 훅 경로 검사를 PATH 의 bash 를 시스템 bash 로 바꿔 한 번 더 돌린다(이번 [T7] 방식).

## PR 도구의 에픽 브랜치(같은 계획의 독립 검토가 찾음, 기존 동작)

- `core/scripts/pr-helper.sh` 의 "Ensure base branch exists" 는 에픽 브랜치가 원격에 없으면 늘 `origin/main` 에서 만든다 —
  `SCV_PR_BASE` · origin 기본 브랜치를 보지 않는다. main 이 없는 저장소에서는 커밋을 만든 뒤에 실패한다(코드로 확인, 재현은 검토 에이전트).
- 정할 것: 에픽 브랜치의 출발점을 `SCV_PR_BASE` > origin 기본 브랜치 > main 으로 맞출지, 실패 판정을 커밋 앞으로 당길지.
- 같은 검토의 곁가지(기존): scvroot 의 위로 찾기가 맥의 `/tmp` 심볼릭 링크 아래에서 실패한다(검토 에이전트 관찰, 미확인).
