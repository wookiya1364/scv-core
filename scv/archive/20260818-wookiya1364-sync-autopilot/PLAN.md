---
title: sync 자동화와 가드 실효 회복
slug: 20260818-wookiya1364-sync-autopilot
author: wookiya1364
created_at: 2026-08-18
status: done
kind: refactor
lang: korean
tags: [sync, guard, ci]
raw_sources:
  - scv/raw/stale/20260818-wookiya1364-sync-autopilot-guard-fixes.md
refs: []
invariants:
  - "sync 는 PROJECT:LOCAL 블록과 preserve 정책 파일을 계속 보존한다"
  - "가드는 영수증 저장소가 사용 불가일 때 계속 닫힌 쪽으로 실패한다 (fail open 금지)"
  - "SCV_GUARD_SCRIPTS 단일 값의 기존 동작은 바이트 그대로 유지된다"
  - "자동 sync 는 미수화 프로젝트와 pre-2.x 레거시에서 절대 실행되지 않는다"
---

# sync 자동화와 가드 실효 회복

## Summary

sync 의 `.scv-backup` 사본을 없애고 더티 거부로 바꾼다. 액션이 시작될 때 프로젝트
템플릿이 payload 보다 낡았으면 그 자리에서 자동으로 최신화한다. 그리고 문서 최신화
작업에서 드러난 "가드가 실제로는 안 걸린다" 계열 버그 5건의 동작을 고친다.

## Goals / Non-Goals

- **Goals**
  - `scv:update` → 리로드 → 다음 액션에서 문서 포맷이 자동으로 최신화된다
  - sync 가 사본 디렉터리를 만들지 않는다. 커밋 안 된 변경이 있는 파일은
    덮어쓰지 않고 이름을 말한다
  - Codex 어댑터 액션들이 영수증을 발급한다 (`SCV_GUARD_SCRIPTS` 콜론 목록)
  - 영수증 저장소가 사용 불가일 때 거부 사유가 원인을 이름 붙인다
  - 무력 테스트 2건(T15·T21)이 실제로 판정하고, 래퍼 투영본이 어느 배치에서든 돈다
- **Non-Goals**
  - `state-index.sh` 의 shared-core-migration 격리는 건드리지 않는다 (별개 장치)
  - pre-2.x 레거시의 대화형 마이그레이션 흐름은 그대로 둔다 — 자동화하지 않는다
  - update 액션이 sync 를 직접 부르게 하지 않는다. 버전별 플러그인 캐시 구조에서
    update 시점의 sync 는 **옛 payload** 로 돌아 옛 템플릿을 다시 깐다
  - 래퍼 저장소 변경(codex hooks.json, cc CI 등록)은 Core 벤더링 이후 별도 PR

## Approach Overview

**sync.** `backup_file`/`BACKUP_DIR` 를 제거한다. 기존 파일을 바꾸기 전에
`git status --porcelain -- <파일>` 로 더티를 판정하고, 더티면 `DIRTY` 로 보고하고
건너뛴다. 추적 안 된 파일과 git 이 없는 환경은 더티로 취급한다 — 복구 경로가 없는
곳에서 무단 덮어쓰기는 없다. `--force <파일>` 이 preserve 와 같은 방식으로 더티
거부도 우회한다. 동일 파일(`cmp -s`)은 지금처럼 더티 검사 전에 건너뛴다.

**자동 최신화.** `lib/scvroot.sh` 에 `scv_autosync` 를 추가한다. 프로젝트 스탬프
(`SCV.md` 의 `STANDARD:VERSION`)와 payload `TEMPLATE_VERSION`(lib 위치 기준
`../../TEMPLATE_VERSION`)을 비교해서 다르면 `sync.sh --project-dir` 를 돌리고 한 줄
보고한다. sync 는 끝에서 스탬프를 다시 찍으므로 한 번 돌면 수렴한다.
`scv_init_paths` 가 호출하고(액션 스크립트 9개가 이미 source), `help.sh` 와
`status.sh` 는 명시 호출한다.

**가드.** `SCV_GUARD_SCRIPTS` 를 콜론으로 갈라 디렉터리별 고정 문자열 비교.
gate 모드에서 영수증 저장소가 만들 수도 쓸 수도 없으면 거부 사유를 저장소 경로와
`SCV_GUARD_STATE` 안내로 바꾸고, mint 실패는 stderr 한 줄을 남긴다. 닫힌 쪽 실패는
유지한다 — 모델이 저장소 권한을 부술 수 있으므로 fail open 은 가드 해제와 같다.

**테스트.** T15 를 비면제 경로로 옮겨 새 사유를 단언한다. T21 을 계획 문서 조건
없이 두 스크립트(`guard.sh`·`check-provenance.sh`)의 면제 집합 직접 비교로 다시
쓴다. 루트 해석을 후보 탐색(`../`,`../../` × `core`, `vendor/scv-core/core`,
`plugins/scv/vendor/scv-core/core`)으로 바꿔 래퍼 투영본에서도 돌게 한다.

## Guardrails

- 미수화 프로젝트(SCV.md 도 PROMOTE.md 도 없음)에서 자동 sync 절대 금지 —
  수화는 사용자 동의가 있는 별도 액션이다
- pre-2.x(스탬프 unknown 포함)에서 자동 sync 절대 금지. 2.0.0 은퇴 패스가 사용자
  문서 7종을 삭제하는데, 프로토콜은 삭제 전 DECISIONS.md 이관 **제안**을 요구한다.
  이 경우 한 줄 안내만 낸다
- 자동 sync 실패는 액션을 막지 않는다 (경고 후 계속)
- 재귀 가드(`SCV_AUTOSYNC_RUNNING`)와 끄기(`SCV_AUTOSYNC=off`, 환경변수만) 필수
- `core/` 는 호스트 중립 — 새 코드·주석·테스트에 호스트 토큰 금지, 필요하면 기존
  T19 의 런타임 조립 방식
- raw/promote/archive/conversations 내용물은 sync 가 지금도 앞으로도 만지지 않는다
- 가드의 fail-open 두 입력(빈 payload·JSON 리더 없음)은 그대로 유지
- 계약·프로토콜 문서(guard.md·sync.md·update.md·wrapper-integration.md)는 같은
  PR 에서 새 동작과 일치시킨다 — 배포 문서가 가드·게이트 동작과 모순되면 안 된다
- `test-guard-consistency.sh` 의 구문 스윕을 통과해야 한다. 새 anchor 가 필요하면
  줄 번호까지 정확히 등록한다

## Exit criteria

- TESTS.md 시나리오 전부 통과
- 스탬프가 낡은 프로젝트에서 아무 액션이나 한 번 돌리면 템플릿이 최신화되고,
  두 번째 실행은 no-op 이다 (수렴 증명)
- 옛 코드에서 실패하는 회귀 케이스가 각 버그마다 존재한다 — 통과만 하는 테스트는
  무엇도 증명하지 않는다
- 래퍼 배치를 흉내 낸 트리에서 test-guard.sh 가 전 케이스 통과한다
- `tests/run.sh` · `core/tests/run-dry.sh` · `core/tests/test-*.sh` ·
  `tests/test-host-neutral.sh` · `tests/test-guard-consistency.sh` 전부 초록
- 릴리스 아티팩트에 변경이 들어가고, 래퍼 후속 PR 목록(codex hooks.json·문서,
  cc CI 등록)이 명시된다

## Suggested path

1. sync.sh — 백업 기계 제거, 더티 거부 삽입, 보고 문구 교체
2. lib/scvroot.sh — `scv_autosync` 추가, `scv_init_paths` 연결, help/status 호출
3. guard.sh — `SCV_GUARD_SCRIPTS` 콜론 분해, 저장소 사용 불가 사유 교체, mint 경고
4. core/tests/test-guard.sh — 루트 후보 탐색, T15 재작성, T21 재작성, 다중 디렉터리
   mint 케이스 추가
5. 새 테스트 — autosync 수렴·가드레일(미수화/레거시/재귀/끄기), sync 더티 거부
6. 문서 — guard.md·sync.md·update.md·wrapper-integration.md·release 문서 정합
7. 전체 스위트 + 릴리스 준비 (0.28.0)

## Related Documents

- [`TESTS.md`](./TESTS.md)
- `core/contracts/guard.md` — 실패 정책·mint 허용목록 절이 이번에 바뀐다

## Risks / Open Questions

- 자동 sync 가 액션 도중(예: readpath consume 직전) 발화한다. sync 는 워크플로
  내용물을 만지지 않지만, 테스트로 못 박는다 (T7)
- 더티 판정이 `git` 부재 환경에서 전부-거부로 떨어진다. 의도된 보수성이지만, 그런
  환경 사용자는 sync 가 아무것도 안 바꾸는 것처럼 보일 수 있다 — 보고 줄에 이유가
  나온다
- 래퍼 후속 PR 전까지 codex 의 mint 격차는 그대로다. Core 가 먼저 나가야 한다
- 플러그인 캐시가 이전 버전을 물고 있는 세션은 autosync 도 이전 payload 기준으로
  판단한다 — 리로드 전에는 어떤 설계도 새 payload 에 손이 닿지 않는다 (알려진 한계)

## Links

- Raw originals: (frontmatter 참조)
- Related PRs:
