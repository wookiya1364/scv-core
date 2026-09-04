---
title: "깊은 질문은 배경 조사로 — 세션 effort 는 그대로, 스위치는 기본 off"
slug: 20260904-wookiya1364-effort-auto-level
author: "wookiya1364"
created_at: 2026-09-04
status: testing
kind: feature
lang: korean
tags: [effort, delegate, background, hook, settings, wrapper]
raw_sources:
  - scv/conversations/20260904-094830-effort-auto-level.md
refs: []
invariants:
  - "세션의 effort 는 SCV 가 절대 바꾸지 않는다 — 명령 파일에 effort 줄을 두지 않는다 (0.29.0·0.45.0 원칙)"
  - "스위치가 off(기본)면 훅 출력은 지금과 한 글자도 다르지 않다 — 기존 검사 전부 그대로 통과"
  - "기존 스위치 셋(SCV_PLAIN_LANGUAGE · SCV_ALWAYS_ON · SCV_FORCE_HELP)의 동작은 바뀌지 않는다"
  - "코어 본문은 호스트 이름과 effort 단계 이름(low~max, ultracode)을 적지 않는다 — 단계 이름은 래퍼 소유"
  - "설정 파일의 기존 키·값은 불변 — 키 하나가 더해질 뿐"
  - "Codex 래퍼는 무변경"
scope:
  - "core/scripts/lib/force-help.sh"
  - "core/template/hooks/on-user-prompt.sh"
  - "core/template/scv/scv_settings.example.json"
  - "core/scripts/lib/settings.sh"
  - "core/protocols/help.md"
  - "core/template/scv/SCV.md"
  - "docs/wrapper-integration.md"
  - "core/TEMPLATE_DIGEST"
  - "core/tests/test-delegate-effort.sh"
  - "core/tests/test-force-help.sh"
  - "VERSION"
  - "CHANGELOG.md"
  - "(래퍼) agents/scv-investigator.md — 새 디렉터리"
  - "(래퍼) tests/test-core-contract.sh"
---

# 깊은 질문은 배경 조사로 — 세션 effort 는 그대로, 스위치는 기본 off

## Summary

사용자마다 effort 가 다르고, 높은 단계일수록 답이 늦다. 그렇다고 SCV 가 세션 effort 를
눌러 놓는 것은 어제(0.45.0) 모델에서 "다운그레이드" 라고 판정한 것과 같은 일이다. 그래서
세션 다이얼은 손대지 않고, **깊은 질문만 배경 조사 에이전트에 넘긴다.** 답은 지금 세션
그대로 나가고, 깊은 결과는 파일로 남아 뒤따른다. 스위치 하나(기본 off)로 켠다.

## Goals / Non-Goals

- **Goals**
  - 설정 파일의 스위치를 켜면, 매 턴 훅이 "깊은 질문은 배경 조사에 위임하라" 는 블록을
    하나 더 싣는다. off 면 아무 것도 달라지지 않는다.
  - 래퍼가 배경 조사 에이전트 정의를 한 파일로 실어 보낸다. 세션 모델·effort 를 상속한다.
  - 조사 결과는 `scv/raw/` 에 파일로 남는다 — 알림 본문이 잘려도 원문이 살아남고, 다음
    계획의 재료가 된다.
  - 위임 도구가 호출별 effort 단계를 지원하는 호스트에서만 깊이에 맞춰 단계를 고른다.
    아니면 세션 그대로.
- **Non-Goals**
  - 세션 effort 를 낮추거나 높이지 않는다. 명령 파일에 effort 줄을 두지 않는다.
  - 서브에이전트 정의 파일의 `effort:` 줄에 기대지 않는다 — 실험에서 안 먹었다(아래).
  - 어떤 SCV 명령(promote·work 등)도 배경 조사를 자동으로 부르지 않는다. 이번은 help 가
    매 턴 받는 지시문 한 블록과 에이전트 한 파일까지다.

## Approach Overview

**확인된 사실 (2026-09-04, Claude Code 2.1.260 실측).**
- 서브에이전트 정의 파일에 `effort: low / high / max` 를 적어도 요청 기록은 셋 다 세션값
  이었다. 같은 계산 문제의 사고 토큰도 low 2,610 · max 3,006 으로 거의 같았다. 문서는
  "덮어쓴다" 고 하지만 지금은 안 먹는다.
- 워크플로 도구의 호출별 effort 는 먹는다(세션 xhigh 에서 high 로 기록됨). 그래서 단계
  선택은 그 도구가 있는 호스트로 한정한다.
- 배경 에이전트가 끝나면 사용자 입력 없이 알림이 와 모델이 깨어난다. 알림 본문은 약
  4.5천 자에서 잘린다 — 결과를 파일로 남겨야 하는 이유.
- 사용자 범위 `agents/` 에 파일을 쓰면 수 초 뒤 바로 호출된다. 프로젝트 범위의 새
  디렉터리는 재시작 전 미인식이다(문서). 플러그인은 루트 `agents/` 를 디렉터리 관례로
  찾는다(설치된 다른 플러그인 10개에서 관찰 — 추정).
- 조사 1건 실측: 도구 36회, 출력 약 139k 토큰, 띄운 뒤 보고까지 3분 28초.

**훅에 블록 하나.** 매 턴 훅은 이미 스위치로 켜고 끄는 블록 셋을 싣는다(쉬운 말 ·
라우팅 지시 · preflight 진단). 넷째 블록을 같은 패턴으로 더한다. 다른 점 하나 — 기존
스위치는 "off 만 끈다" 인데 이 스위치는 "on 만 켠다" 다. 기존 정규화 함수는 빈값을 on
으로 보므로 그대로 못 쓴다. 순수 함수 하나(on 만 on, 나머지 off)와 블록 본문을 찍는
순수 함수 하나를 더한다. 본문은 12줄 이내 — 훅 출력 상한 80줄에 지금 57줄이다.

**블록이 하는 말 (호스트 중립).** 답은 지금 세션 그대로. 질문이 깊으면(여러 파일을 읽거나
검증이 필요하면) 호스트에 배경 조사 에이전트 `scv-investigator` 가 있을 때 그것에 넘기고,
답에 "깊은 결과가 뒤따른다" 고 적는다. 결과는 `scv/raw/` 파일로, 알림에는 요약만. 위임
도구가 호출별 노력 단계를 지원하면 깊이에 맞춰 고르고, 아니면 세션 그대로.

**래퍼에 에이전트 한 파일.** `agents/scv-investigator.md` — 배경 실행, 모델 상속, 편집
도구 없음(쓰기는 `scv/raw/` 결과 파일 하나뿐). effort 줄은 두지 않는다(먹지 않고, 원칙에도 어긋난다). 단계 이름
(low~max)과 "깊이별로 어느 단계를 고르는지" 는 이 파일의 설명에만 적는다 — 코어는 호스트
중립 검사가 단계 이름을 막는다.

**두 저장소에 걸친다.** 스위치·훅·등록·검사는 코어, 에이전트 파일과 계약 검사는 래퍼.
0.45.0 과 같은 방식 — 래퍼 검사는 옆에 체크아웃이 있을 때만 돌고 없으면 건너뛴다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readSwitch,        // 설정 파일 → 원시 값                      ← 부수효과 (입구)
  normalizeOnOnly,   // 원시 값 → "on" | "off"  (on 만 on)       ← 순수
  renderDelegate,    // "on" → 블록 본문 (12줄 이내) | "off" → 빈 문자열   ← 순수
  emitHook,          // 블록 본문 → 훅 stdout                    ← 부수효과 (출구)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readSwitch | 설정 파일 → `SCV_DELEGATE_EFFORT` 원시 값 | 부수효과 (입구) — 기존 `_scv_read` 그대로 |
| 2 | normalizeOnOnly | 원시 값 → on / off | 순수 — 새 함수. `on`/`ON` 만 on, 빈값·그 외 전부 off |
| 3 | renderDelegate | on/off → 블록 본문 또는 빈 문자열 | 순수 — 새 함수, printf 만 |
| 4 | emitHook | 본문 → stdout | 부수효과 (출구) — 기존 훅의 자리에 한 줄 호출 |

- 부수효과 위치: 1(읽기)·4(쓰기). 2·3 은 순수하고 purity 검사가 자동으로 잡는다.
- 결과가 돌아오면: 답하는 모델이 raw 파일 경로와 요약 한 줄을 세션 대화 파일에 이어 붙인다
  (기록 규칙은 help 규약의 것 그대로).
- 재사용: `_scv_read`, 블록 배치 자리, 훅의 exit-0 규약. 새로 만드는 것은 2·3 뿐.

## Guardrails

- 세션 effort 는 어디서도 바꾸지 않는다. 명령 파일·에이전트 파일에 effort 줄 없음.
- off(기본)일 때 훅 stdout 은 바이트 단위로 지금과 같다.
- 기존 라우팅 지시문(`scv_force_routing`)에 글을 덧붙이지 않는다 — 21줄 상한 검사가 있다.
- 새 블록은 라우팅 지시 **뒤, 진단 앞**에 선다 — 지시이므로 진단 뒤에 묻히면 안 된다
  (0.40.0 의 교훈). 기존 순서 검사(지시 < 갱신 안내 < 진단)는 그대로 성립한다.
- 코어 본문에 호스트 이름, 모델 이름, effort 단계 이름을 적지 않는다.
- 에이전트는 저장소를 고치지 않는다 — 편집 도구가 없고, 쓰기는 조사 결과 파일
  (`scv/raw/`) 하나뿐이며 git 상태를 바꾸지 않는다고 정의 파일이 못 박는다.
- 조사 결과 파일은 `scv/raw/` 규칙을 따른다 — 비밀 없음, 기존 raw 를 지우지 않음.

## 성공지표 (Metrics)

| 지표 | 지금 (baseline) | 목표 (target) |
|---|---|---|
| 스위치 off 일 때 훅 출력 | 57줄 | 57줄 (동일) |
| 스위치 on 일 때 훅 출력 | — | ≤ 69줄 (블록 12줄 이내, 상한 80) |
| 세션 effort 가 SCV 때문에 바뀌는 경우 | 0 | 0 |
| 깊은 결과의 원문 보존 | 알림 본문(약 4.5천 자에서 잘림) | `scv/raw/` 파일 (전문) |
| 래퍼의 배경 조사 에이전트 | 없음 | 파일 1개, 배경 실행, 모델 상속 |

## 예외처리 (Edge cases)

- **스위치 값이 `maybe`·빈값·따옴표 포함** — 전부 off. 켜는 값은 `on` 뿐.
- **호스트에 에이전트가 없음(Codex, 또는 래퍼 갱신 전)** — 블록은 실리지만 "있을 때" 조건이
  라 모델은 그냥 답한다. 아무 일도 없다.
- **위임 도구가 단계 선택을 지원하지 않음** — 세션 effort 그대로 배경 실행. 지원하면
  깊이에 맞춰 고른다.
- **얕은 질문** — 위임하지 않는다. 판단은 답하는 모델의 몫이고, 블록은 기준만 준다.
- **조사 결과가 길다** — 파일에 전문, 알림에 요약. 잘려도 원문은 남는다.
- **같은 질문에 조사가 두 번 뜸** — 이번 범위 밖. Risks 에 적는다.

## Exit criteria

- TESTS.md 시나리오 전부 통과.
- 스위치 off 로 기존 검사 전부(test-force-help · test-journal · test-autosync · purity ·
  host-neutral · template-digest) 그대로 통과.
- 스위치 on 인 실제 프로젝트에서 깊은 질문을 던졌을 때, 답이 그 턴에 나오고 조사 결과
  파일이 `scv/raw/` 에 생긴다(실기기 1회).

## Suggested path

1. 코어: `force-help.sh` 에 순수 함수 둘(on 만 on 정규화 · 블록 본문). purity 검사 통과.
2. 코어: 훅에 넷째 블록 — `_scv_read SCV_DELEGATE_EFFORT` → 정규화 → on 이면 본문 출력.
   자리는 라우팅 지시 뒤·진단 앞(항상-켬이 꺼진 프로젝트에서는 홀로).
3. 코어: 설정 예시에 `_doc` + 기본 `off`, `SCV_PLAIN_KEYS` 등록, 지문 재계산.
4. 코어: help 규약에 한 단락 — 스위치가 켜져 있으면 깊은 질문은 위임(MAY), 호스트 중립.
5. 코어 검사 파일 신설(등록부 · 하이드레이트 · off 침묵 · on 블록 · 상한 · 래퍼 파일은
   체크아웃 있을 때만). 기존 test-force-help 에 스위치 케이스 추가.
6. 래퍼: `agents/scv-investigator.md` 신설(배경 실행 · 편집 도구 없음 · 모델 상속 · effort
   줄 없음 · 결과는 `scv/raw/` 파일). 계약 검사에 "파일 있음 · effort 줄 없음" 추가.
7. 버전·변경기록. 릴리스 노트에 켜는 법과 "세션 effort 는 그대로" 한 줄.

## Related Documents

- [`FEATURE_ARCHITECTURE.md`](./FEATURE_ARCHITECTURE.md)
- [`TESTS.md`](./TESTS.md)

## Risks / Open Questions

- 빠른 답의 권고를 먼저 실행한 뒤 깊은 결과가 뒤집는 경우. 블록이 "깊은 결과가 뒤따른다"
  고 적게 하지만, 사용자가 기다릴지는 사용자의 몫이다.
- 깊다고 판단하는 턴마다 조사 1건 비용(실측 출력 139k 토큰). 기본 off 인 이유.
- 플러그인 루트 `agents/` 가 자동 발견된다는 것은 관찰 기반 추정 — 구현 첫 단계에서
  실기기로 확인한다. 안 되면 사용자 범위 파일로 안내하는 대안.
- 정의 파일 `effort:` 가 새 Claude Code 에서 먹기 시작하면 단계 선택을 그쪽으로 넓힐
  수 있다 — 후속 계획.

## Links

- Raw originals: (frontmatter 참조)
- Related PRs:
