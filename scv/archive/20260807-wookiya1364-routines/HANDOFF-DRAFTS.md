# HANDOFF DRAFTS — action:routine wrapper 등록 (미발행 초안)

> **상태: 초안.** `action:handoff` 로 발행하지 않았다 — 이 계획(TESTS 시나리오
> 10류, wrapper handoff)은 구현 완료 후 두 wrapper 저장소로 발행할 내용을
> 여기에 보관한다. 발행 시 각 섹션의 Body/Why 를 그대로 사용하면 된다.
>
> 배경: `routine` 은 **재벤더링만으로 전파되지 않는 최초의 액션 추가**다.
> 두 wrapper 는 (1) 명령 표면에 `routine` 을 등록하고 (2) "14개 액션 정확히
> 1회" CI 계약을 15로 갱신해야 한다. 두 wrapper 동시 릴리스 권장.

---

## Draft 1 — to: scv-claude-code

- to_repo: `scv-claude-code`
- slug: `register-action-routine`
- title: "action:routine (15번째 액션) 명령 표면 등록 + 액션 계약 14→15"
- decision: needed
- from_slug: `20260807-wookiya1364-routines`

### Body — What scv-claude-code must build

## What scv-claude-code must build

- scv-core 를 `routine` 액션이 포함된 릴리스(0.22.0 웨이브)로 재핀·재벤더링한다.
- slash command 표면에 `/scv:routine` 을 등록한다 — 프로젝션 소스는 벤더링된
  `core/protocols/routine.md`, 엔트리포인트는 `core/scripts/routine.sh`
  (다른 core-owned 액션과 동일한 프로젝션 규칙; `{{SCV_ARGS}}` 는 기존
  host-profile 재료화 방식 그대로).
- 인자 형태: `--list` | `<name>` | `--lint <file>` (+ 선행 모듈 타깃 1개 허용,
  `routine FE <name>` 처럼 인자 2개 이상일 때만 첫 인자를 모듈 타깃으로 해석한다. 단일 bare 인자는 항상 루틴 이름이다 — `routine FE` 는 "FE 루틴 조회"이지 모듈 타깃이 아니다).
- wrapper CI 의 액션 계약을 갱신한다: "**15**개 액션이 정확히 1회씩" (기존 14).
  프로젝션 재생성 diff 검사도 새 프로토콜 파일(routine.md)을 포함해야 한다.
- 스케줄링 비소유 계약을 지킨다: wrapper 는 `action:routine` 실행 시 어떤
  스케줄 등록도 하지 않는다. Claude Code 사용자는 `/loop 1d /scv:routine
  dead-code` 같은 호스트 기능으로 직접 등록한다 — 안내 문구는 core 프로토콜
  Step 4 가 출력한다 (wrapper 는 그대로 노출만).

## Acceptance for the receiving repo

- [ ] `/scv:routine --list` 가 정의된 루틴 표(NAME/CADENCE/REPORT)를 출력한다.
- [ ] `/scv:routine <없는이름>` 이 명확한 에러 + 사용 가능 목록으로 실패한다 (exit 1).
- [ ] wrapper CI 가 "15개 액션 정확히 1회"로 통과한다 (14 계약 잔재 0).
- [ ] `grep -r "crontab -\|systemctl\|launchctl" <wrapper 코드>` 에 routine
      관련 스케줄 등록 코드가 없다 — 등록 예시 안내 텍스트만 존재.
- [ ] core 회귀 스위트(run-dry + core/tests/test-*.sh)가 wrapper 레이아웃에서 통과한다.

### Why — rationale

Boris Cherny 의 "한 문장 유지보수 루틴 20~30개" 실천을 SCV 프로토콜로 가져온
0.22.0 routines 웨이브. core 는 정의 형식(`scv/routines/*.md` frontmatter 계약)
과 실행 프로토콜만 소유하고, 주기 실행은 호스트(= 이 wrapper 의 /loop, cron)가
소유한다. 새 액션 추가는 재벤더링만으로 명령 표면에 나타나지 않으므로 이
handoff 가 필요하다. scv-codex 와 동시 릴리스하지 않으면 두 호스트의 액션
표면이 갈라진다 (같은 내용의 handoff 를 scv-codex 에도 발행).

---

## Draft 2 — to: scv-codex

- to_repo: `scv-codex`
- slug: `register-action-routine`
- title: "action:routine (15번째 액션) 명령 표면 등록 + 액션 계약 14→15"
- decision: needed
- from_slug: `20260807-wookiya1364-routines`

### Body — What scv-codex must build

## What scv-codex must build

- scv-core 를 `routine` 액션이 포함된 릴리스(0.22.0 웨이브)로 재핀·재벤더링한다.
- Codex plugin/skill 표면에 `$scv:routine` 을 등록한다 — 프로젝션 소스는
  벤더링된 `core/protocols/routine.md`, 엔트리포인트는
  `core/scripts/routine.sh` (다른 core-owned 액션과 동일한 프로젝션 규칙;
  인자 전달은 기존 host-profile `SCV_ARGUMENT_STYLE` 그대로).
- 인자 형태: `--list` | `<name>` | `--lint <file>` (+ 선행 모듈 타깃 1개 허용,
  `routine FE <name>` 처럼 인자 2개 이상일 때만 첫 인자를 모듈 타깃으로 해석한다. 단일 bare 인자는 항상 루틴 이름이다 — `routine FE` 는 "FE 루틴 조회"이지 모듈 타깃이 아니다).
- wrapper CI 의 액션 계약을 갱신한다: "**15**개 액션이 정확히 1회씩" (기존 14).
  프로젝션 재생성 diff 검사도 새 프로토콜 파일(routine.md)을 포함해야 한다.
- 스케줄링 비소유 계약을 지킨다: wrapper 는 `action:routine` 실행 시 어떤
  스케줄 등록도 하지 않는다. 사용자는 cron / CI 스케줄 잡으로 직접 등록한다 —
  안내 문구는 core 프로토콜 Step 4 가 출력한다 (wrapper 는 그대로 노출만).

## Acceptance for the receiving repo

- [ ] `$scv:routine --list` 가 정의된 루틴 표(NAME/CADENCE/REPORT)를 출력한다.
- [ ] `$scv:routine <없는이름>` 이 명확한 에러 + 사용 가능 목록으로 실패한다 (exit 1).
- [ ] wrapper CI 가 "15개 액션 정확히 1회"로 통과한다 (14 계약 잔재 0).
- [ ] `grep -r "crontab -\|systemctl\|launchctl" <wrapper 코드>` 에 routine
      관련 스케줄 등록 코드가 없다 — 등록 예시 안내 텍스트만 존재.
- [ ] core 회귀 스위트(run-dry + core/tests/test-*.sh)가 wrapper 레이아웃에서 통과한다.

### Why — rationale

Boris Cherny 의 "한 문장 유지보수 루틴 20~30개" 실천을 SCV 프로토콜로 가져온
0.22.0 routines 웨이브. core 는 정의 형식(`scv/routines/*.md` frontmatter 계약)
과 실행 프로토콜만 소유하고, 주기 실행은 호스트(cron, CI 스케줄, 에이전트 반복
기능)가 소유한다. 새 액션 추가는 재벤더링만으로 명령 표면에 나타나지 않으므로
이 handoff 가 필요하다. scv-claude-code 와 동시 릴리스하지 않으면 두 호스트의
액션 표면이 갈라진다 (같은 내용의 handoff 를 scv-claude-code 에도 발행).
