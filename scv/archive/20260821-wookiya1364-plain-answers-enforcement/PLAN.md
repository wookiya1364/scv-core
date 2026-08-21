---
title: "쉬운 말 2단계 — 답의 모양, 매 턴 전달, .env 스위치"
slug: 20260821-wookiya1364-plain-answers-enforcement
author: "wookiya1364"
created_at: 2026-08-21
status: done
kind: feature
lang: korean
tags: [protocols, hooks, template, ux, language]
raw_sources:
  - scv/conversations/20260821-103405-plain-answers-enforcement.md
refs: []
supersedes: []
scope:
  - "core/protocols/*.md"
  - "core/template/hooks/on-user-prompt.sh"
  - "core/template/.env.example.scv"
  - "core/template/scv/SCV.md"
  - "core/template/scv/routines/**"
  - "core/TEMPLATE_VERSION"
  - "TEMPLATE_VERSION"
  - "core/tests/**"
  - "docs/guidance-ablation.md"
  - "docs/wrapper-integration.md"
  - "CHANGELOG.md"
invariants:
  - "SCV_PLAIN_LANGUAGE 없음/on → 켜짐, off(대소문자 무관)만 꺼짐 — 그 밖의 값은 켜짐"
  - "기록 훅은 비차단 유지 — 어떤 실패에도 exit 0, scv/journal/ 밖에 쓰지 않는다"
  - "기존 'Language preference' 절과 어블레이션 마커 범위(promote·work 외 마커 금지) 불변"
  - "core/actions.json·액션 개수(15) 불변 — 래퍼 자동 벤더링 보호"
parallel_groups: [[2, 3, 4], [5, 6]]
---

# 쉬운 말 2단계 — 답의 모양, 매 턴 전달, .env 스위치

## Summary

"쉬운 말 먼저" 규칙은 8월 12일에 넣었지만 지켜지지 않는다. 모델은 여전히
길게, 코드값(파일 경로·버전·설정값)으로, 예시 없이 답한다.

원인은 세 가지다. (1) 규칙이 문체 조언이라 **답의 모양**을 정하지 않았다.
(2) 규칙이 `/scv:*` 명령 안에만 있어서 **일반 대화**에는 한 줄도 전달되지
않는다. (3) 어겨도 아무 검사도 켜지지 않는다.

고치는 방법: 규칙을 "먼저 1~2문장 → 예시 하나 → 코드값은 묻기 전엔 금지 →
자세한 건 원하면"이라는 **답의 모양**으로 다시 쓰고, 매 메시지마다 도는 기록
훅이 그 요약을 모델에게 보여주게 하며, SCV.md 에도 같은 안내를 싣는다.
`.env` 의 `SCV_PLAIN_LANGUAGE` 로 켜고 끌 수 있다 — 기본은 켜짐, `off` 만 꺼짐.

## Goals / Non-Goals

- **Goals**
  1. **규칙 재작성 (A)** — 13개 프로토콜의 `## Plain language first` 절 본문을
     "답의 모양" 판으로 바꾼다. 제목은 그대로(누적 회귀 T4 호환), 본문은 13개
     파일에서 바이트 동일, 위치는 `## Language preference` 바로 다음 H2.
     첫 줄이 스위치 안내(`SCV_PLAIN_LANGUAGE=off` 면 이 절은 적용하지 않음).
     좋은 답/나쁜 답 예시 한 쌍을 규칙 안에 넣는다.
  2. **help 대화 모드 매 턴 모양 (A)** — `help.md` Step B2 에 "매 턴: 짧은 답
     → 예시 하나 → 질문 하나(one question per turn)" 를 계약으로 넣는다.
  3. **매 턴 전달 (B1)** — `core/template/hooks/on-user-prompt.sh` 가 SCV 를
     쓰는 프로젝트에서 규칙 요약(12줄 이내)을 stdout 으로 내보낸다. Claude
     Code 와 Codex 모두 이 훅의 stdout 을 모델 컨텍스트에 넣는다(공식 문서
     확인, 2026-08-21). 기록(journal) 동작과 비차단 보장은 그대로.
  4. **안내 (B2)** — 템플릿 `scv/SCV.md` 에 "SCV 는 이렇게 말한다" 절을 넣고,
     루트 지침 파일에 한 줄 추가하는 안내를 붙인다. 훅을 등록하지 않은
     호스트는 이 경로로 규칙을 받는다.
  5. **스위치** — `.env` `SCV_PLAIN_LANGUAGE`. 없음/`on` → 켜짐, `off` 만 꺼짐.
     `.env.example.scv` 에 기본 on 으로 문서화(effort governor 블록과 같은 형식).
     `TEMPLATE_VERSION 2.2.0 → 2.3.0` — 기존 프로젝트는 다음 액션 때 autosync 로
     `.env.example.scv` 와 `SCV.md` 를 자동 수령한다.
  6. **예시 루틴 (C, 작게)** — `core/template/scv/routines/examples/plain-language-audit.md`
     한 개. journal 의 답변을 훑어 "첫 문장이 길다 / 코드값이 섞였다" 를 표시한다.
     자동 실행 없음, 복사해 쓰는 예시.
  7. **회귀 가드** — 위 전부를 `core/tests/` 에 고정한다 (이 계획의 TESTS.md).

- **Non-Goals**
  - 모델 출력을 LLM 으로 채점하는 자동 테스트 (회귀 스위트에 넣지 않음 —
    사람 판정 3건으로 종료, Exit criteria 참조)
  - `Language preference` 절 수정, 새 action, `core/actions.json` 변경
  - promote·work 외 프로토콜에 `SCV:GUIDANCE` 마커 도입 (어블레이션 1단계 범위 유지)
  - `/scv:help` 첫 설정에 스위치 질문 추가 (기본 on 으로 충분 — `.env.example.scv` 가 안내)
  - 루트 지침 파일(CLAUDE.md/AGENTS.md) 자동 수정 — SCV 는 건드리지 않는다

## Approach Overview

**규칙 본문(확정 초안, 영어 원문 — 13개 파일 공통).** 제목 `## Plain language first`
는 유지한다. 본문:

```
Skip this section only when the project `.env` sets `SCV_PLAIN_LANGUAGE=off`
(absent or any other value = on).

Answer shape — every time you explain something to the user:

1. First, 1–2 sentences. Lead with what the user gets.
2. Then one example — from the user's situation, or an everyday comparison.
3. No code values before the user asks: file paths, variable names, version
   numbers, setting values. Use the plain name instead ("the settings file",
   "last week's plan").
4. Detail comes after, and only when wanted. Offer it in one line.

Identifiers the user needs to act on — the next command to run, a file that
was created — stay exact, after the plain summary.

Bad: "The block landed in `.env.example.scv:154-161` and the stamp advanced
2.1.0 → 2.2.0."
Good: "Your settings example file is up to date. For example, the new 'effort'
setting now shows there. Want the exact lines?"

This governs everything the user reads: answers, questions, plans, progress
reports, summaries, and explanations of what went wrong.
```

**훅 요약(초안, 영어, 12줄 이내).** `on-user-prompt.sh` 가 `scv/` 가 있고
스위치가 켜져 있을 때 stdout 으로 낸다. 기록 성공 여부와 무관하게, 기록보다
먼저 낸다. journal 파일에는 절대 섞이지 않는다 (stdout ≠ journal).

```
[SCV plain language] Answer shape: (1) first, 1–2 sentences — lead with what
the user gets; (2) then one example; (3) no code values (paths, variable names,
versions, settings) before the user asks — use plain names; (4) detail after,
only when wanted. Identifiers the user needs to act on stay exact, after the
plain summary. Off switch: .env SCV_PLAIN_LANGUAGE=off.
```

**스위치 읽기.** 훅은 cwd 의 `.env` 에서 `^SCV_PLAIN_LANGUAGE=` 한 줄만 읽는다
(`source` 금지 — 비밀값·nounset 위험). 값은 소문자로 비교해 `off` 일 때만
꺼짐. 프로토콜 쪽은 절의 첫 줄이 스위치 규칙을 말하므로 모델이 `.env` 를 보고
스스로 비켜선다. 중첩 모노레포 모듈은 루트 `.env` 를 따른다(이번 범위의 한계로
Risks 에 적는다).

**위치와 분류.** 13개 프로토콜에서 절은 마커 밖(CONTRACT)에 둔다 — 8월 12일
결정 그대로(1단계 스코프 가드 때문). promote/work 의 `--lint` 측정표를
`docs/guidance-ablation.md` 에 실측으로 갱신한다.

**래퍼 후속.** Claude Code 래퍼는 이미 `UserPromptSubmit` 에 이 훅을 등록해
두어 Core 반영만으로 켜진다. Codex 래퍼는 `plugins/scv/hooks/hooks.json` 에
`UserPromptSubmit`(+ `Stop`) 등록이 없다 — 이번 배송 웨이브에서 등록 PR 을
함께 낸다(사용자 결정). `docs/wrapper-integration.md` §6 에 "훅 stdout 은
컨텍스트로 들어간다 — 등록은 래퍼 소유" 를 적는다.

## Guardrails

- 절의 **제목** `## Plain language first` 는 바꾸지 않는다 — 누적 회귀(T4)가
  제목으로 찾는다. 본문만 바꾼다.
- 13개 파일의 절 본문은 **바이트 동일**. `set-models.md`·`update.md`(어댑터
  스텁)에는 넣지 않는다.
- promote·work 외 프로토콜에 `SCV:GUIDANCE` 마커를 넣지 않는다. promote·work
  안에서도 이 절은 마커 밖에 둔다.
- 훅: 어떤 실패에도 `exit 0`, `scv/journal/` 밖에 쓰지 않는다, `.env` 를
  `source` 하지 않는다, 요약은 12줄 이내, journal 에 요약을 쓰지 않는다.
- 훅·프로토콜·SCV.md 문구에 호스트 이름(Claude/Codex/`/scv:`/모델명)을 넣지
  않는다 — Core 는 호스트 중립.
- `core/actions.json`, `core/scripts/*.sh` 의 계약(액션 15개)은 건드리지 않는다.
- 템플릿 파일(`SCV.md`, `.env.example.scv`, 루틴 README)을 바꾸면 반드시
  `TEMPLATE_VERSION` 을 2.3.0 으로 올린다 — 안 올리면 기존 프로젝트가 못 받는다.
- 규칙 자체가 쉬운 말로 쓰여 있어야 한다. 어려운 문장으로 "쉽게 쓰라"고 하면
  그 자체가 반례다.
- 테스트에 `git diff`/`git status` 단언을 넣지 않는다 — 커밋 상태에 따라 판정이
  흔들린다(0818 회귀 계약 보수의 교훈). 내용 기반 단언만 쓴다.

## Exit criteria

- TESTS.md 의 How-to-run 블록이 exit 0 (T1–T6 전부).
- **사람 판정 3건 통과(수동)**: 샘플 프로젝트에서 ① 명령 없는 일반 대화 질문
  1건 ② `/scv:help` 진단 1건 ③ `/scv:help "<아이디어>"` 대화 1턴. 각각 첫 답이
  "2문장 이내 + 예시 1 + 코드값 없음" 인지 대표님이 눈으로 판정해 통과/반려를
  결정한다. 결과는 archive 에 체크리스트로 남긴다. 이것이 자동 테스트가 못
  보장하는 부분을 닫는 유일한 문이다.
- `run-dry.sh` · `tests/run.sh` · `core/tests/test-*.sh` 전부 green.
  `guidance-filter.sh --lint` OK, full 투영 원본과 바이트 동일.
- CHANGELOG 기록 + `docs/guidance-ablation.md` 측정표 실측 갱신 +
  `docs/wrapper-integration.md` §6 갱신.
- Codex 래퍼 훅 등록은 **배송 웨이브의 별도 PR** 로 기록된다 (이 플랜의 archive
  는 Core 기준으로 닫고, 래퍼 PR 번호를 DECISIONS 에 남긴다).

## Suggested path

1. 규칙 본문과 훅 요약 문구를 확정한다 (위 초안 기준, 영어, 앵커 문구 유지:
   `SCV_PLAIN_LANGUAGE=off` · `1–2 sentences` · `one example` ·
   `No code values before the user asks` · `stay exact, after the plain summary` ·
   `Bad:` · `Good:`).
2. 13개 프로토콜의 `## Plain language first` 본문을 교체한다. `help.md` Step B2
   에 매 턴 모양(`one question per turn`)을 추가한다.
3. `on-user-prompt.sh`: `scv/` 존재 + 스위치 on 이면 요약을 stdout 으로, 그
   다음 기존 기록 경로 그대로. `core/tests/test-journal.sh` 에 on/off/OFF/이상값/
   미적용 폴더/잘못된 입력 6경우를 추가한다.
4. 템플릿: `.env.example.scv` 스위치 블록, `SCV.md` "SCV 는 이렇게 말한다" 절,
   예시 루틴 `plain-language-audit.md`, 루틴 README 의 예시 개수(8→9),
   `TEMPLATE_VERSION` 2.3.0 (core/ 와 루트 둘 다).
5. 테스트 앵커: `run-dry.sh` plain-language 섹션(앵커·위치·옛 문구 부재),
   `test-sync-env-example.sh`(새 변수), `test-routines.sh`(새 예시 lint 대상).
6. 문서: CHANGELOG, `docs/guidance-ablation.md` 측정표(`--lint` 실측),
   `docs/wrapper-integration.md` §6.
7. 사람 판정 3건 → 체크리스트 기록 → archive → DECISIONS.
8. 배송 웨이브: Core 릴리스 → 래퍼 두 곳 벤더링 + Codex `hooks.json` 등록 PR.

## Related Documents

- 대화: `scv/conversations/20260821-103405-plain-answers-enforcement.md`
- 이전 규칙: `scv/archive/20260812-wookiya1364-plain-language/PLAN.md` (본문 교체 대상)

## Risks / Open Questions

- **여전히 "진짜 쉽게 말하는지" 를 기계가 보장하지 못한다.** 보장되는 것은
  "규칙이 매 턴 모델 눈앞에 있다 + 답의 모양이 구체적이다" 까지. 사람 판정
  3건이 닫는다. 반려되면 문구를 고쳐 다시 3건.
- **매 턴 주입 비용.** 12줄 이내 × 매 메시지. 미미하지만 `off` 로 끌 수 있다.
- **중첩 모노레포 모듈.** 훅은 cwd 의 `.env` 만 본다. 모듈별 `.env` 는 이번
  범위 밖 — 필요해지면 별도 계획.
- **Codex 등록.** 공식 문서상 `UserPromptSubmit` stdout 이 컨텍스트로 들어간다.
  실제 등록은 래퍼 PR 에서 실측한다 — 안 되면 SCV.md 안내 경로가 대신한다.
- **문구 13곳 복제.** 어긋나면 run-dry 가 잡는다(동일성 단언). 토큰화는 2단계
  어블레이션 때 재검토.

## Links

- Raw originals: (frontmatter 참조 — 대화 파일)
- Related PRs:
