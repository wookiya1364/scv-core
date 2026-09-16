---
title: "help 규약은 세션당 한 번만 — 매 턴은 기록 계약만, 진단은 변동 시에만 전체"
slug: 20260914-wookiya1364-help-load-once
author: "wookiya1364"
created_at: 2026-09-14
status: testing
kind: refactor
epic: 20260914-help-turn-cost
lang: korean
tags: [help, protocol, token-budget, session-state, hooks, resume-recap, diagnosis]
raw_sources:
  - scv/conversations/20260914-092553-install-check-0-47-0.md
  - scv/raw/stale/20260914-wookiya1364-skill-cost-measurement.md
refs: []
invariants:
  - "help 는 여전히 매 턴 불리고, 매 턴 기록을 남긴다 — 강제 호출(0.43~0.45 결정)과 '기록 없이 돌려보내지 않는다' 규칙은 그대로"
  - "규약을 다시 읽는 시점은 모델 판단이 아니라 훅 상태로 정해진다 — 새 세션 · 압축 · /clear · 재개"
  - "진단은 매 턴 주입된다(0.43 결정) — 바뀌지 않았을 때만 한 줄 요약으로 대신하고, 바뀐 턴에는 전체가 실린다"
  - "훅은 scv/journal/ 밖에 아무것도 쓰지 않고, 실패하면 exit 0 로 이전 동작(전체 주입)으로 돌아간다"
  - "1단계(help-body-diet) 배송·실측 뒤에 구현한다 — 두 변경의 효과를 따로 잰다"
scope:
  - "core/protocols/help.md (매 턴 본문 = 라우터: 기록 계약 · 짧은 턴 · 스크립트 실행 · 규약 읽기 지시 · 답 모양 요약)"
  - "core/protocols/help/full.md (신설 — 1단계 본문 전체가 여기로; 분기 부속 파일은 그대로)"
  - "core/scripts/help-state.sh (신설 — scv/journal/.help-state 읽기·쓰기 순수부 + 얇은 효과부)"
  - "core/scripts/help.sh (--with-context 출력에 PROTOCOL: load|loaded 한 줄)"
  - "core/template/hooks/on-user-prompt.sh · on-session-start.sh (세션 번호 변화·컨텍스트 비움 시 표식 되돌림, 진단 해시 비교)"
  - "core/scripts/lib/force-help.sh (진단 요약 한 줄 순수 함수)"
  - "core/tests/test-help-shape.sh · test-delegate-effort.sh · test-force-help.sh · run-dry.sh (대상을 help/full.md 로 재조준)"
  - "core/tests/test-help-load-once.sh (신설)"
  - "core/template/.gitignore.fragment (scv/journal/ 이미 ignore — 확인만)"
  - "VERSION · CHANGELOG.md (0.49.0 — 1단계와 같이 또는 다음 릴리스)"
---

# help 규약은 세션당 한 번만 — 매 턴은 기록 계약만, 진단은 변동 시에만 전체

## Summary

1단계가 끝나도 help 본문(약 13KB)은 매 턴 다시 실린다. 오늘 8턴 세션에서 본문 사본이 8번
쌓였다(1단계 전 기준 234KB) — 같은 문서를 되풀이해 싣는 구조가 컨텍스트를 채우고 압축을
앞당긴다. 규약 전체는 세션에 한 번만 읽고, 매 턴 본문은 기록 계약과 답 모양 요약만 남긴다.
"다시 읽을 때"는 모델이 판단하지 않는다. 매 턴 훅이 세션 번호 변화를, 되찾기 훅이 컨텍스트
비움(압축·/clear·재개)을 보고 표식을 되돌리고, 보조 스크립트가 `PROTOCOL: load|loaded` 를
찍는다. 같은 표식 파일로 훅 진단도 "바뀐 턴에만 전체, 아니면 한 줄"이 된다. 매 턴 약 18KB(1단계
목표) → 약 8KB, 세션 누적은 턴 수 배 → 1배.

## Goals / Non-Goals

- **Goals**
  - 매 턴 본문(라우터)이 4,000 바이트 이하. 규약 전체는 `protocols/help/full.md` 한 파일, 세션당
    한 번 읽힌다(압축·/clear·재개 뒤에는 다시 한 번).
  - 읽기 시점이 결정적이다: `help.sh --with-context` 가 `PROTOCOL: load` 를 찍으면 읽고
    `help-state.sh mark` 로 표식을 세운다; `loaded` 면 읽지 않는다. 훅이 표식을 되돌리는 조건
    셋(세션 번호 변화 · SessionStart compact|clear|resume · 표식 파일 없음)이 검사로 못 박힌다.
  - 훅 진단: 잘라낸 진단 블록의 해시가 직전 턴과 같으면 한 줄("진단 변동 없음 — 마지막 전체
    HH:MM"), 다르면 전체. 첫 턴은 항상 전체.
  - 매 턴 스택(훅 + 라우터 + 스크립트 출력) ≤ 9,000 바이트, 세션 10턴 누적 ≤ 1단계의 절반.
  - **잊음 완화 둘 (2026-09-15, 사용자 우려 "대화가 길어지면 까먹지 않나"에 답으로 추가).**
    (a) N턴마다 강제 재읽기: 매 턴 훅이 표식에 턴 수를 세고 `SCV_HELP_RELOAD_EVERY`(기본 10) 턴마다
    protocol=0 — 압축이 없어도 규약이 주기적으로 새로 실린다. 비용은 13KB/10턴 ≈ 1.3KB/턴 상당.
    (b) 기록 계약 누락 감사: 저널의 사용자 턴 수와 세션 대화 파일의 append 수를 비교하는 순수 함수 +
    `regression` 이 부를 수 있는 검사 — "기록을 놓친 턴" 을 세션별로 센다. 2단계 전(0.48.x 세션들)과
    후를 같은 자로 잰다. 이 수치가 나빠지면 N 을 줄이거나 라우터를 되돌린다.
  - 기존 검사는 대상만 `help/full.md` 로 옮겨 통과한다(앵커 문장 무삭제).
- **Non-Goals**
  - 강제 호출 자체를 줄이는 것 — 사용자 결정(unconditional-help)이며 이 계획은 그 안에서 논다.
  - 분기 부속 파일 다섯의 재구성 — 1단계 그대로.
  - 다른 규약(promote · work)의 세션당 1회 읽기 — 그것들은 호출당 비용이라 별개.

## Approach Overview

**확인된 사실 (2026-09-14).**
- 매 턴 훅은 stdin JSON 에서 `prompt` 만 읽고(155~160행), 되찾기 훅은 `source` 만 읽는다(57~70행).
  호스트 stdin 에는 `session_id` 가 같이 온다(호스트 문서; 추정 아님 — 되찾기 계획에서 `source`
  필드를 같은 방식으로 확인). 훅 계약: 실패 시 exit 0, `scv/journal/` 밖에 쓰지 않는다
  (hooks.json description · contracts/guard.md). `scv/journal/` 은 기본 ignore(.gitignore.fragment).
- 훅 진단은 `help.sh` 인자 없음 출력을 `scv_force_trim_diagnosis` 로 잘라 넣는다 — 잘라낸 결과가
  결정적이므로 해시 비교가 된다.
- 되찾기 훅(0.47.0)이 SessionStart(compact|clear|resume) 에 이미 걸려 있다 — 표식 되돌림을 여기에
  한 줄 더한다. startup 은 등록하지 않는다(0.47.0 결정) — 새 세션은 매 턴 훅의 세션 번호 비교로
  잡는다.
- 검사 재조준 목록: test-help-shape(답 모양 절·쉬운 말 절 HEAD 비교) · test-delegate-effort(위임
  절) · test-force-help T18·T19 · run-dry 의 help 앵커와 [15p] 쉬운 말 규칙(help.md 가 `## Language
  preference` 를 잃으면 PLAIN_N 이 12 로 떨어져 `>= 13` 이 깨진다 — 라우터에 언어 절과 쉬운 말 절을
  **남긴다**, 둘 다 매 턴 필요한 계약이다) · test-guidance 160(`action:promote` 토큰) · test-profile-
  and-export(`$scv:help` · `$ARGUMENTS`) — 라우터에 남는 것과 full.md 로 가는 것을 표로 적고 PR 에
  싣는다.

**라우터에 남는 것(매 턴).** 머리말(인자 블록 규칙) · 기록 없이 돌려보내지 않는다(앵커 세 문장) ·
언어 절 · 쉬운 말 절(바이트 그대로) · 답 모양 요약(여섯 자리 이름과 두 규칙만; 상세는 full.md) ·
스크립트 실행과 `PROTOCOL:` 처리 · 짧은 턴 이어붙이기 · 대화 파일 append 형식 · `action:promote`
언급 한 줄. 약 3.5KB.

**full.md 로 가는 것(세션당 1회).** 세 모드 소개 · 답 모양 상세 · 의도 분류 · B0~B2 · 저장 규칙 ·
분기 포인터 다섯(부속 파일은 그대로). 1단계 본문에서 라우터로 올라간 것을 뺀 나머지.

**상태 파일.** `scv/journal/.help-state` 한 줄 JSON: `{"session":"<id>","protocol":0|1,
"diag":"<sha256 앞 16자>","diag_at":"HH:MM"}`. 읽기·판정은 순수 함수(문자열 → 문자열), 쓰기는
`help-state.sh` 의 효과부 한 곳. 파일이 없거나 깨지면 "load + 전체 진단"(이전 동작)으로 간다.

**흐름.** 매 턴 훅: stdin 의 session_id ≠ 표식의 session → protocol=0, diag="" 로 되돌리고 저장;
진단 해시 비교 → 같으면 한 줄, 다르면 전체 + 저장. 되찾기 훅: protocol=0 저장. help.sh
`--with-context`: 표식을 읽어 `PROTOCOL: load|loaded` 출력(읽기만). 라우터: `load` 면 full.md 를
Read 하고 `help-state.sh mark` 실행; `loaded` 면 건너뛴다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readState,        // 표식 파일 → 문자열('' 허용)                         (입구)
  parseState,       // 문자열 → {session, protocol, diag, diag_at} (깨지면 기본값)
  decideReload,     // {state, session_id, event} → {protocol', reason}      (event: prompt|reset)
  decideDiag,       // {state, diag_text} → {mode: full|brief, diag', line}
  renderState,      // {state'} → 문자열
  writeState,       // 문자열 → 파일                                          (출구)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readState | 경로 → 문자열 | 부수효과 (입구) |
| 2 | parseState (`scv_hstate_parse`) | 문자열 → 네 필드 | 순수 |
| 3 | decideReload (`scv_hstate_reload`) | 상태 + 세션 번호 + 사건 → 새 protocol 값 | 순수 |
| 4 | decideDiag (`scv_hstate_diag`) | 상태 + 진단 본문 → full/brief + 새 해시 + 요약 한 줄 | 순수 |
| 5 | renderState (`scv_hstate_render`) | 네 필드 → 한 줄 JSON | 순수 |
| 6 | writeState | 문자열 → 파일 (scv/journal/ 안, 임시 파일 뒤 mv) | 부수효과 (출구) |

- 부수효과 위치: 1 과 6. 시각은 인자로 받는다(테스트 고정).
- 재사용: `force-help.sh` 의 순수부 관례(@pure 표시, check-purity 통과), 되찾기 훅의 stdin 한 번
  읽기 관례.

## Guardrails

- 강제 호출·매 턴 기록·매 턴 진단 주입의 **원칙**은 바뀌지 않는다. 바뀌는 것은 "같은 것을 다시
  싣는가"뿐이다.
- 다시 읽을지의 판단을 규약 문장("컨텍스트에 안 보이면 읽어라" 류)에 두지 않는다 — 표식만 본다.
- 훅 실패는 항상 이전 동작(전체 주입)으로 떨어진다. 표식 파일은 `scv/journal/` 안에만.
- 라우터에서 쉬운 말 절·언어 절을 빼지 않는다(run-dry [15p] · test-help-shape T7).
- 1단계 실측(CHANGELOG 0.48.0)이 적힌 뒤에 구현한다.

## Exit criteria

- All TESTS.md scenarios pass
- 매 턴 스택 ≤ 9,000 바이트, 라우터 ≤ 4,000 바이트, 세션 10턴 시뮬레이션에서 full.md 읽기 1회.
- 릴리스 뒤 실사용 3세션에서 (a) 첫 턴에 읽기 1회 (b) /clear 뒤 다시 1회 (c) 진단 변동 없는 턴에
  한 줄 — 셋 다 관찰되고 CHANGELOG 에 적힌다.

## Suggested path

1. `help-state.sh` 순수부 넷 + 효과부, `test-help-load-once.sh` Red.
2. 훅 두 개에 표식 처리(실패 시 exit 0 유지), 진단 해시 비교.
3. `help.sh --with-context` 에 `PROTOCOL:` 한 줄.
4. help.md → 라우터 + `help/full.md`; 검사 재조준(표 대로); 상한 검사 갱신.
5. 10턴 시뮬레이션(훅을 같은 session_id 로 10번, 중간에 compact 한 번) → 읽기 지시 2회 확인.

## 성공지표 (Metrics)

| 지표 | baseline (1단계 목표) | target |
|---|---|---|
| 매 턴 스택 바이트 | ≤ 18,000 | ≤ 9,000 |
| 세션 10턴 누적 help 본문 바이트 | 10 × ~13,000 | 1 × ~14,000 + 10 × ~3,500 |
| 진단 변동 없는 턴의 훅 출력 | ~4,900 | ~1,700 (지시 + 한 줄) |
| full.md Read 횟수 / 세션 | — | 1 + 압축·/clear 마다 1 + N턴(기본 10)마다 1 |
| 기록 계약 누락 턴 / 세션 (감사) | 2단계 전 실측으로 기준선 | 기준선 이하 |

## 예외처리 (Edge cases)

- 표식 파일 없음·깨짐·쓰기 실패 → `load` + 전체 진단(이전 동작). 훅은 exit 0.
- 같은 세션에서 프로젝트 디렉터리를 옮긴 경우 → 표식은 프로젝트별(scv/journal/)이라 새 프로젝트는
  `load`.
- `SCV_ALWAYS_ON=off` → 훅이 라우팅을 싣지 않으므로 표식도 건드리지 않는다; 직접 `/scv:help` 호출은
  `PROTOCOL:` 을 그대로 따른다.
- 호스트가 `session_id` 를 주지 않는 경우(추정: Codex) → 세션 비교 불가 → 매 턴 `load`(이전과 동일
  비용, 동작 동일). 검사가 이 갈래를 본다.
- 되찾기 훅이 꺼진 경우(SCV_RESUME_RECAP=off) → 표식 되돌림은 recap 스위치와 무관하게 실행한다.

## Related Documents

- `scv/promote/20260914-wookiya1364-help-body-diet/PLAN.md` — 1단계 (같은 epic)
- `scv/archive/20260911-wookiya1364-session-resume-recap/PLAN.md` — 되찾기 훅의 stdin·source 처리
- `scv/archive/20260831-wookiya1364-force-help-preflight/PLAN.md` — 진단 주입 결정

## Risks / Open Questions

- 오래 전에 읽은 규약에 대한 주의 저하 — (1) 라우터가 핵심 계약(기록·짧은 턴·쉬운 말·답 모양 요약)을
  매 턴 싣고 (2) 분기 절차는 분기 때 새로 읽히며(1단계 구조) (3) 압축·/clear·재개와 **N턴마다** 강제
  재읽기, (4) 기록 계약 누락 감사가 전후를 같은 자로 잰다. 그래도 남는 것은 "규약을 읽었지만 흐릿해진"
  상태의 미묘한 품질 저하 — 감사 수치와 실사용 3세션 관찰이 판정하고, 나빠지면 N 을 줄인다.
- 모델이 `PROTOCOL: load` 를 보고도 Read 를 건너뛰는 경우 — 표식은 `mark` 로만 세워지므로 다음
  턴에 다시 `load` 가 뜬다(자기 회복). 검사가 "mark 없이는 loaded 로 바뀌지 않음"을 본다.
- `session_id` 필드가 없는 호스트 — 매 턴 load 로 떨어져 비용만 이전과 같다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
