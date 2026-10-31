---
title: 매 턴 훅 속도 — 같은 판단은 한 번, 설정은 파일당 한 번 읽기
slug: 20261030-wookiya1364-hook-dedupe-settings-read
author: wookiya1364
created_at: 2026-10-30
status: testing
kind: refactor
lang: korean
tags: [hooks, performance, settings, ci]
raw_sources:
  - scv/conversations/20261030-103500-hook-speed-hydrate.md
  - scv/raw/20261030-research-hook-speed.md
refs:
  - type: link
    url: scv/archive/20261028-wookiya1364-ci-parallel-tests/PLAN.md
invariants:
  - "매 턴 훅이 내는 글은 옛 길과 바이트까지 같다 (사람 턴 · 자동 알림 턴 · 스위치 켬/끔 모두)"
  - "settings_get 이 돌려주는 값은 모든 키에서 옛 길과 바이트까지 같다 (비밀 키 · 없는 키 · 문자열 아닌 값 포함)"
  - "bash 3.2 (맥 기본)에서 돈다 — 연관 배열 같은 bash 4+ 기능 금지"
  - "훅은 어떤 실패에도 막지 않는다 (exit 0, 기존 NON-BLOCKING 보장)"
---

# 매 턴 훅 속도 — 같은 판단은 한 번, 설정은 파일당 한 번 읽기

## Summary

매 턴 훅이 이 맥에서 1회 1.09–1.25초 걸린다(측정, 2026-10-30). 시간 대부분은 같은 판단을 여러 번 하는 것과, 설정 값을 키마다 jq 를 새로 띄워 읽는 데서 나온다. 출력은 바이트 그대로 두고 이 두 가지만 줄여서, 사용자의 매 턴 대기와 훅을 수십 번 부르는 시험(맥 CI Contracts 5분 28초)을 함께 줄인다.

## Goals / Non-Goals

- **Goals**
  - 이번 입력이 사람 메시지인지 가르는 판단(`model-prompting.sh kind`)을 한 턴에 한 번만 한다 — 지금은 훅과 `show-real.sh` 가 같은 판단을 따로 한다.
  - 선택 창 상태(`choice-gate.sh` 의 line · tool · unattended)를 한 턴에 한 번만 계산한다 — 지금은 훅 1번 + `show-real.sh` 2번.
  - 설정 파일 하나는 한 프로세스에서 jq 로 한 번만 읽고, 그 뒤 키 찾기는 jq 없이 한다(`settings_get` 의 바깥 모양 그대로).
  - 바꾼 뒤 훅 1회 시간(이 맥, 같은 측정 방법)과 맥 CI Contracts 시간을 재서 전후를 보고한다.
- **Non-Goals**
  - `model-prompting.sh` 호출(human · prompt 등) 묶기 — 다음 계획 후보(사용자 결정 2026-10-30).
  - 시험 개수 · 시험 내용 줄이기.
  - 진단(help.sh) 출력이나 진단 자르기 바꾸기.
  - scv-core 의 'hydrate 안 됨' 표시 — 그대로 둔다(사용자 결정, 메모에 이유).

## Approach Overview

조사(scv/raw/20261030-research-hook-speed.md)에서 확인한 것: 한 턴에 bash 하위 프로세스 13개, jq 약 81번(그중 설정 값 읽기 44번), `show-real.sh` 0.21초(그 안에서 kind · choice-gate 를 훅과 중복), `choice-gate.sh` 3번 0.11초, 훅 자신의 설정 읽기 16번 0.12초.

1. **같은 판단 한 번.** 훅이 입력을 읽은 직후 kind 와 선택 창 상태를 먼저 구하고, `show-real.sh` 에는 그 값을 넘긴다. 값을 받지 못한 `show-real.sh`(직접 부를 때)는 지금처럼 스스로 구한다 — 두 판별이 갈라지지 않게 한 판단을 같은 명령으로 하는 지금의 원칙(2026-10-07 독립 검토)은 그대로다.
2. **설정은 파일당 한 번.** `settings_lookup_json` 이 키마다 jq 를 띄우는 대신, 파일 내용 → 펼친 표(키 · 값)를 jq 한 번으로 만들고, 같은 내용이면 그 표를 다시 쓴다. 찾기는 bash 3.2 에서 도는 방법으로(연관 배열 없이). 값에 줄바꿈 · 탭 · 따옴표가 있어도 옛 결과와 같아야 한다.
3. 바뀔 때마다 옛 길과 새 길을 같은 입력으로 돌려 바이트 비교한다(앞 계획의 env_load 비교 시험과 같은 방식).

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readHookInput,     // 표준입력 → INPUT (JSON 텍스트)
  classifyTurn,      // INPUT → kind (human | auto)
  choiceState,       // 설정 표 → { tool, unattended, line }
  showRealLines,     // { switch, tool, unattended, kind } → 안내 줄
  indexSettings,     // 설정 파일 내용 → 펼친 표 (키 · 값)
  lookupSetting,     // 펼친 표, 키 → 값
  emitHookOutput,    // 모은 줄 → 표준출력
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | `readHookInput` | 훅 입력을 한 번만 읽는다 | 표준입력 → INPUT | 부수효과 (입구) |
| 2 | `classifyTurn` | 사람 메시지인지 자동 알림인지 한 번 가른다 | INPUT → kind | 순수 (호스트 설정은 인자로) |
| 3 | `choiceState` | 선택 창 도구 · 사람 없는 실행 · 안내 줄을 한 번 구한다 | 설정 값 → tool · unattended · line | 순수 |
| 4 | `showRealLines` | 실체 보여 주기 안내를 받은 값으로 만든다 | switch · tool · unattended · kind → 줄 | 순수 (지금 `scv_show_real_rule`) |
| 5 | `indexSettings` | 설정 JSON 을 키 · 값 표로 한 번 펼친다 | 파일 내용 → 표 | 순수 (jq 1번) |
| 6 | `lookupSetting` | 표에서 키 하나를 찾는다 | 표 · 키 → 값 | 순수 (jq 없음) |
| 7 | `emitHookOutput` | 모은 줄을 내보낸다 | 줄 → 표준출력 | 부수효과 (출구) |

- 부수효과 위치: 1 (표준입력), 설정 파일 읽기(`_settings_slurp`, 지금 그대로), 7 (표준출력). 2–6 은 인자만 본다.
- 재사용: `scv_show_real_rule` · `scv_show_real_channel` · `settings_resolve` · `settings_is_secret` 는 그대로 쓴다. `model-prompting.sh kind` 와 `choice-gate.sh` 의 판단 로직은 바꾸지 않고 부르는 횟수만 줄인다.

## Guardrails

- 훅 출력 · `settings_get` 값은 옛 길과 바이트까지 같아야 한다(frontmatter invariants). 하나라도 다르면 고치지 말고 차이부터 보고한다.
- bash 3.2 호환. 맥 · 리눅스 둘 다(BSD · GNU 도구 차이 주의).
- 훅은 NON-BLOCKING — 새 코드도 실패하면 옛 길로 가거나 아무것도 안 내고 exit 0.
- 비밀 키 처리(일반 파일의 비밀 키 무시 + 경고, 값은 절대 찍지 않음)는 지금과 같다. 펼친 표를 디스크에 쓰지 않는다(프로세스 안에서만).
- `show-real.sh` · `choice-gate.sh` 를 직접 부르는 길(인자 없이)은 지금과 같은 결과.
- `model-prompting.sh` 의 human · prompt 호출, 진단, 시험 내용은 건드리지 않는다(Non-Goals).

## Exit criteria

- All TESTS.md scenarios pass
- 훅 출력 바이트 비교(사람 · 자동 · 스위치 조합)와 설정 값 바이트 비교(모든 키)가 통과
- 훅 1회 시간: 이 맥에서 전후 각 5회 측정값을 보고(목표치는 두지 않음 — 줄지 않으면 원인을 보고)
- 맥 CI Contracts 시간 전후를 보고, 우분투 · 맥 CI 모두 통과

## Suggested path

1. 지금 훅 출력과 설정 값을 기준으로 떠 두는 비교 시험을 먼저 만든다 — 옛 길과 새 길을 같은 입력으로 돌려 바이트 비교
2. 설정 펼치기 · 찾기를 넣는다 — `indexSettings`, `lookupSetting`
3. 훅이 kind 와 선택 창 상태를 한 번 구해 넘기게 한다 — `readHookInput`, `classifyTurn`, `choiceState`
4. `show-real.sh` 가 넘겨받은 값을 쓰게 한다(없으면 지금처럼) — `showRealLines`, `emitHookOutput`
5. 훅 1회 시간을 전후 5회씩 재고, 시험 시간 기록을 갱신한다 — 같은 측정 스크립트로 전후 숫자 남기기
6. PR 로 우분투 · 맥 CI 를 돌려 Contracts 시간 전후를 기록한다 — CI 실측 보고

## Related Documents

- scv/raw/20261030-research-hook-speed.md — 측정 방법과 단계별 시간
- scv/archive/20261028-wookiya1364-ci-parallel-tests/PLAN.md — 앞 계획(env_load jq 한 번, 맥 3분은 이 계획으로 넘김)

## Risks / Open Questions

- 설정 값에 줄바꿈 · 탭이 있으면 펼친 표가 깨질 수 있다(추정) — 비교 시험 입력에 그런 값을 넣어 막는다.
- 줄어드는 몫은 약 0.3–0.4초로 추정(측정 전). 맥 CI 3분까지는 이 계획만으로 부족할 수 있다 — 그 경우 숫자로 보고하고 model-prompting 묶기를 다음 계획으로.
- 맥 러너 편차가 크다(같은 시험 ±40%, 앞 계획 실측) — CI 전후 비교는 시험 시간 합으로도 함께 본다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
