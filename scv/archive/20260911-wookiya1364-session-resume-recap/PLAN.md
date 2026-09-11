---
title: "비운 뒤에도 이어진다 — 압축·/clear·재개 뒤 진행 상황 재주입"
slug: 20260911-wookiya1364-session-resume-recap
author: "wookiya1364"
created_at: 2026-09-11
status: testing
kind: feature
lang: korean
epic: 20260911-plugin-modernize
tags: [hook, session-start, compact, recap, conversation, settings, wrapper]
raw_sources:
  - scv/conversations/20260911-110227-next-features-0-46-1.md
  - scv/raw/stale/20260911-research-plugin-trends.md
refs: []
invariants:
  - "기존 훅 둘(on-user-prompt · on-stop)의 출력과 저널 기록은 한 글자도 바뀌지 않는다 — 기존 검사 전부 그대로 통과"
  - "새 훅은 어떤 경우에도 세션을 막지 않는다 — 잘못된 입력·없는 파일·미하이드레이트 → exit 0, 빈 출력"
  - "새 훅은 아무 것도 쓰지 않는다 — 저널·결정·대화 파일에 기록하지 않고 읽어서 조립만 한다"
  - "코어 본문은 호스트 이름을 적지 않는다 — 이벤트 이름·matcher 값은 래퍼 소유"
  - "설정 파일의 기존 키·값은 불변 — 키 하나가 더해질 뿐"
  - "Codex 래퍼는 무변경"
scope:
  - "core/template/hooks/on-session-start.sh"
  - "core/scripts/lib/resume-recap.sh"
  - "core/scripts/recap.sh"
  - "core/scripts/lib/settings.sh"
  - "core/template/scv/scv_settings.example.json"
  - "docs/wrapper-integration.md"
  - "core/TEMPLATE_DIGEST"
  - "core/tests/test-session-resume.sh"
  - "VERSION"
  - "CHANGELOG.md"
  - "(래퍼 scv-claude-code) hooks/hooks.json"
  - "(래퍼 scv-claude-code) adapter/README.md"
  - "(래퍼 scv-claude-code) tests/test-core-contract.sh"
---

# 비운 뒤에도 이어진다 — 압축·/clear·재개 뒤 진행 상황 재주입

## Summary

지금은 대화를 지우거나(/clear) 컨텍스트가 압축되거나 세션을 재개하면, 그 다음 턴의 모델은
방금까지 하던 계획·결정·대화를 모른다. 저널과 결정 로그에는 다 남아 있는데 **다시 읽어 주는
훅이 없다.** 세션 시작 이벤트(압축·비움·재개 세 경우)에 코어의 recap 조립기가 만든 "지금
어디까지 왔나" 와 활성 대화 한 건을 실어 보낸다. 스위치 하나(기본 on)로 끈다.

## Goals / Non-Goals

- **Goals**
  - 압축·/clear·재개 직후 첫 턴부터 모델이 진행 중 계획, 최근 결정 5건, 활성 대화 1건을 안다.
  - 조립은 기존 recap 스크립트가 한다 — 새로 저장하는 것은 없다. 활성 대화는 파일 전문을 싣는다
    (사용자 결정: 줄 수 상한 없음 — "최근 결정이랑 대화가 더 길 수도 있잖아").
  - 스위치 `SCV_RESUME_RECAP` (off 만 끈다, 기본 on — 기존 세 스위치와 같은 규칙).
  - 래퍼가 SessionStart 이벤트에 등록한다. 새 세션 시작(startup)은 제외 — 첫 메시지의 preflight
    진단이 이미 상태를 싣는다 (사용자 결정).
- **Non-Goals**
  - 압축 직전(PreCompact)에 무언가를 저장하는 일 — 저장은 이미 자동이다(저널·결정·대화).
    그리고 그 이벤트의 출력은 모델에 닿지 않는다 (공식 문서 확인).
  - 저널 본문 재주입 — 대화 파일과 결정 색인으로 충분하다. 저널은 요청 시 읽는다.
  - Codex 래퍼 등록 — 등가 이벤트 미확인. 템플릿은 호스트 중립으로 두고 등록은 각 래퍼가.

## Approach Overview

**확인된 사실 (2026-09-11, 공식 문서·실측).**
- 세션 시작 훅은 matcher 로 `startup | resume | clear | compact | fork` 를 구분하고, 평문 stdout 이
  모델 컨텍스트에 들어간다 (컨텍스트에 닿는 이벤트는 프롬프트 제출·프롬프트 확장·세션 시작·
  모델 전환 후 넷뿐). 압축 직전 이벤트의 stdout 은 로그로만 간다.
- 코어 `recap.sh` 가 이미 "비운 직후 되찾기" 를 조립한다 — 진행 중 계획(제목·상태), 최근 결정
  N 건(색인 줄 + 펼치는 명령), 막힌 것, 최근 계획의 미결 사항. 아무 것도 쓰지 않는다.
- 훅 seam 문서 §6 은 템플릿 둘(프롬프트 제출·응답 종료)만 계약한다. 셋째 줄이 필요하다.
- 경쟁 플러그인(planning-with-files 등)은 같은 문제를 "계획 파일을 매 턴 재주입" 으로 푼다.
  SCV 는 매 턴이 아니라 **비운 직후 한 번**만 싣는다 — 매 턴 preflight 가 이미 상태를 싣고
  있어서, 되찾기까지 매 턴 실으면 같은 것을 두 번 사는 셈이다.

**템플릿 하나, 순수부 하나.** `on-session-start.sh` 는 기존 두 템플릿과 같은 골격이다:
`scv/` 없으면 exit 0 · 설정 라이브러리로 스위치 읽기 · stdin 은 한 번만 읽기 · 어떤 실패도
exit 0. 하는 일은 셋이다 — (1) 머리말 한 줄(무슨 일로 비워졌는지: stdin JSON 의 `source`
값을 그대로 쓰되 없으면 일반 문구), (2) `recap.sh` 출력, (3) 활성 대화 1건. 활성 대화는
`scv/conversations/` 최상위에서 frontmatter `status: active` 인 파일 중 가장 최근 것 하나 —
경로와 전문을 싣는다. 대화 파일은 쓸 때 이미 가림 처리(redaction)되지만, 실어 보내기 전에
가림 필터를 한 번 더 통과시킨다 (읽기 전용이라도 비밀값이 컨텍스트로 새는 경로는 막는다).

**순수부는 파일도 stdout 도 만지지 않는다.** `lib/resume-recap.sh` 에 `@pure` 셋:
스위치 해석(off 만 off — force-help 의 것과 같은 규칙, 독립 함수로 두어 서로 묶이지 않게),
활성 대화 고르기(`경로<TAB>status<TAB>mtime` 줄 목록 → 경로 하나), 머리말 만들기(source →
문장). 훅이 파일을 읽어 줄 목록을 만들고, 순수부가 고르고, 훅이 찍는다. 순수성 검사가 그
경계를 지킨다.

**래퍼는 등록만.** hooks.json 에 `SessionStart` 항목 하나, matcher `compact|clear|resume`,
명령은 기존 두 템플릿과 같은 모양(`SCV_CORE_ROOT` 내보내기, 30초). 코어 템플릿은 matcher 를
모른다 — 어느 경우에 뜰지는 래퍼가 정한다. 문서 §6 에 셋째 행과 "이 이벤트의 stdout 도
모델에 닿는다" 를 적는다.

**용량에 대한 판단.** 상한을 두지 않는다(사용자 결정). recap 은 실측 약 1.5KB, 대화 파일은
길면 10KB 를 넘을 수 있다. 비운 직후 한 번이므로 감수한다. 다만 활성 대화가 **여럿**이면
가장 최근 하나만 — 나머지는 경로만 한 줄씩.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readSwitch,          // 설정값 문자열 → on|off
  buildHeader,         // source 문자열 → 머리말 한 줄
  listConversations,   // 대화 디렉터리 → "경로\tstatus\tmtime" 줄들   (입구: 파일 읽기)
  pickActive,          // 줄들 → 경로 하나 (없으면 빈 문자열)
  assemble,            // 머리말 + recap 출력 + 대화 전문 → 블록      (출구: stdout)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readSwitch (`scv_resume_switch`) | 설정 문자열 → `on`/`off` | 순수 |
| 2 | buildHeader (`scv_resume_header`) | source(`compact`/`clear`/`resume`/빈값) → 머리말 | 순수 |
| 3 | listConversations | 디렉터리 → 줄 목록 | 부수효과 (입구: 파일 시스템 읽기) |
| 4 | pickActive (`scv_resume_pick_active`) | 줄 목록 → 경로 하나 | 순수 |
| 5 | assemble | 머리말·recap·대화 → stdout | 부수효과 (출구: recap.sh 실행 · 가림 필터 · 출력) |

- 부수효과 위치: 3(읽기)과 5(실행·출력)에만. 스위치·머리말·고르기는 인자만 받고 문자열만 돌려준다.
- 재사용: `recap.sh` 전체, `lib/settings.sh` 의 `settings_get`, `journal-append.sh --redact-only`,
  `scv_force_switch` 의 규칙(같은 규칙을 독립 함수로 복제 — 서로 묶이지 않게).

## Guardrails

- 기존 두 훅 템플릿과 `force-help.sh` 는 손대지 않는다. 새 파일을 더할 뿐이다.
- 새 훅은 파일을 쓰지 않는다 — 저널·결정·대화·설정 어디에도.
- 새 훅은 막지 않는다 — 어떤 경로로도 0 이 아닌 종료 코드를 내지 않는다.
- 코어 본문에 호스트 이름·이벤트 이름·matcher 값을 적지 않는다 (test-host-neutral). 그것은 래퍼
  hooks.json 과 wrapper-integration.md 의 몫이다.
- 활성 대화는 **최상위** `scv/conversations/*.md` 만 본다 — `archive/` 는 보지 않는다.
- 가림 필터를 거치지 않은 대화 본문을 stdout 에 내지 않는다.
- Codex 래퍼 파일은 건드리지 않는다.

## Exit criteria

- All TESTS.md scenarios pass
- 실기기: Claude Code 에서 진행 중 계획이 있는 프로젝트에서 `/clear` 뒤 첫 메시지에 모델이 그
  계획의 slug 를 스스로 말한다 (T16, 수동).
- 코어 회귀(core/tests 전부)와 래퍼 계약 검사가 통과하고, 스위치 off 프로젝트의 훅 출력이 빈
  문자열이다.

## Suggested path

1. `core/scripts/lib/resume-recap.sh` — 순수 함수 셋 + `@pure` 표기. `check-purity.sh` 통과.
2. `core/template/hooks/on-session-start.sh` — 골격은 `on-user-prompt.sh` 앞부분 복제(설정
   라이브러리 로드 · `_scv_read`), 본문은 머리말 → recap.sh → 활성 대화(가림 필터 경유).
3. 설정 등록부 + 예시 JSON `_doc`/기본값 `on`.
4. `docs/wrapper-integration.md §6` — 표에 셋째 행, 요구사항 7 ("세션 시작 이벤트의 stdout 도
   모델에 닿는다 — 비움·압축·재개에 등록하라, 새 세션 시작은 preflight 가 맡는다").
5. `core/tests/test-session-resume.sh` — TESTS T1–T15. 래퍼 파일은 옆 체크아웃이 있을 때만.
6. `TEMPLATE_DIGEST` 재계산.
7. 래퍼: hooks.json 등록 + adapter/README.md + (있으면) test-core-contract.sh 의 훅 검사.
8. VERSION/CHANGELOG 는 epic 의 다른 계획(skills-layout-gates)과 함께 0.47.0 으로 한 번.

## Related Documents

- [`FEATURE_ARCHITECTURE.md`](./FEATURE_ARCHITECTURE.md)
- `scv/archive/20260904-wookiya1364-effort-auto-level/PLAN.md` — 넷째 블록을 더한 직전 사례 (같은 골격)
- `docs/wrapper-integration.md` §6 — 훅 seam 계약

## Risks / Open Questions

- 활성 대화 전문에 상한이 없어 압축 직후 컨텍스트를 수 KB 더 쓴다. 사용자 결정으로 감수 —
  실측치를 CHANGELOG 에 적고, 문제되면 설정 키 하나로 상한을 더한다.
- stdin JSON 의 `source` 필드 존재는 문서 목록에 명시돼 있지 않다(추정). 없으면 일반 머리말로
  떨어지도록 설계해 두어 어느 쪽이든 동작한다.
- 재개(resume) 시에는 이전 대화가 이미 컨텍스트에 있을 수 있다 — 그래도 실린다. 중복이지만
  해롭지 않고, 사용자가 "재개 뒤에만" 을 포함해 골랐다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
