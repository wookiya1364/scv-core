---
title: "쉬운 말 문장 수 스위치 — SCV_PLAIN_MAX_SENTENCES (기본 2)"
slug: 20260821-wookiya1364-plain-sentence-cap
author: "wookiya1364"
created_at: 2026-08-21
status: done
kind: feature
lang: korean
tags: [protocols, hooks, template, ux, language]
raw_sources:
  - scv/conversations/20260821-130311-plain-sentence-cap.md
refs: []
supersedes: []
scope:
  - "core/protocols/*.md"
  - "core/contracts/guard.md"
  - "core/template/hooks/on-user-prompt.sh"
  - "core/template/.env.example.scv"
  - "core/template/scv/SCV.md"
  - "core/tests/**"
  - "docs/wrapper-integration.md"
  - "CHANGELOG.md"
invariants:
  - "SCV_PLAIN_MAX_SENTENCES 없음/이상값(양의 정수가 아님) → 2"
  - "SCV_PLAIN_LANGUAGE=off 이면 문장 수 값은 무의미 — 규칙·훅 요약 자체가 꺼진다"
  - "어제 보관한 계약 그대로: 절 제목 불변, 앵커 7종(특히 '1–2 sentences') 존재, 13곳 본문 동일, 훅 비차단·journal 비오염, TEMPLATE_VERSION 2.3.0 유지"
---

# 쉬운 말 문장 수 스위치 — SCV_PLAIN_MAX_SENTENCES

## Summary

"먼저 1–2문장" 의 2 가 고정돼 있다. 어떤 팀은 3–4문장이 더 편하다. `.env` 에
숫자 하나(`SCV_PLAIN_MAX_SENTENCES`)를 넣으면 그 수까지 허용하고, 없으면 2 다.
단위는 **문장 수** — 줄 수는 화면 폭에 따라 달라져 모델이 지키기 어렵다.

## Goals / Non-Goals

- **Goals**
  1. 13개 프로토콜의 `## Plain language first` 본문에 한 문장을 더한다 — "상한은
     2, `.env` `SCV_PLAIN_MAX_SENTENCES=<n>`(양의 정수)이 있으면 n 까지".
     제목·기존 앵커(`1–2 sentences` 포함)·13곳 동일성은 그대로.
  2. `on-user-prompt.sh` 가 그 값을 읽어 요약의 숫자를 바꾼다 — 없음/이상값은 2,
     `1` 이면 "one sentence", n≥2 면 "1–n sentences". `SCV_PLAIN_LANGUAGE=off`
     가 우선(침묵).
  3. `.env.example.scv` 의 plain-language 블록과 템플릿 `scv/SCV.md` 절에 한 줄씩.
  4. 회귀 가드: run-dry [15p]/[15q] 앵커, test-journal [6p] 값별 출력.

- **Non-Goals**
  - 줄 수 단위, 언어별 문장 분리 규칙, 출력 자동 채점
  - TEMPLATE_VERSION 상승 — 2.3.0 은 아직 미출시라 같은 판으로 함께 나간다
    (어제 보관한 T4 가 2.3.0 을 고정한다)
  - `/scv:help` 첫 설정 질문 추가

## Approach Overview

**규칙 본문에 더할 문장(영어, 13곳 공통).** 1번 항목 바로 뒤:

```
   The cap is 2 unless the project `.env` sets `SCV_PLAIN_MAX_SENTENCES=<n>`
   (a positive integer) — then up to n.
```

**훅.** `.env` 에서 `^SCV_PLAIN_MAX_SENTENCES=` 한 줄을 읽어(`source` 금지)
`^[1-9][0-9]*$` 만 유효. 요약의 "(1) first, 1–2 sentences" 를 "1–n sentences"
(n=1 은 "one sentence")로 바꿔 찍고, 요약 끝의 스위치 안내에 cap 변수도 적는다.
여전히 12줄 이내, stdout 전용, journal 비오염, 비차단.

**줄 번호 앵커.** 본문이 2줄 늘어나면 `core/contracts/guard.md` 의 예외 앵커
3개(deck.md·promote.md)가 또 밀린다 — 함께 옮긴다(어제와 같은 작업).

## Guardrails

- 절 제목·앵커 7종·13곳 동일성·마커 범위(promote·work 외 마커 금지)·훅 비차단·
  journal 비오염은 어제 계약 그대로 — 깨지면 누적 회귀가 잡는다.
- 훅은 `.env` 를 `source` 하지 않는다. 값 검증은 양의 정수만.
- `TEMPLATE_VERSION` 은 2.3.0 유지(미출시 판). 올리지 않는다.
- `core/actions.json`·액션 15개 불변.
- 호스트 이름 금지(Core 호스트 중립).
- 테스트에 `git diff`/`git status` 단언 금지(내용 기반만).

## Exit criteria

- TESTS.md How-to-run exit 0 (T1–T4).
- 어제 보관한 `20260821-wookiya1364-plain-answers-enforcement` 의 TESTS 블록이
  그대로 통과한다(누적 회귀로 확인).
- CHANGELOG Unreleased 에 한 항목, `docs/wrapper-integration.md` §6 에 cap 변수 언급.
- 같은 0.31.0 릴리스로 함께 배송.

## Suggested path

1. 13개 프로토콜 본문에 문장 추가(동일성 유지) → guard.md 앵커 이동.
2. 훅 수정 + test-journal [6p] 값별 케이스.
3. `.env.example.scv`·`SCV.md` 한 줄씩 + run-dry 앵커.
4. CHANGELOG·docs → 스위트 → archive → PR.

## Related Documents

- 대화: `scv/conversations/20260821-130311-plain-sentence-cap.md`
- 선행: `scv/archive/20260821-wookiya1364-plain-answers-enforcement/PLAN.md`

## Risks / Open Questions

- 큰 값(예: 20)을 넣으면 사실상 규칙이 무력해진다 — 사용자의 선택이다. 문서에
  "기본 2, 3–4 정도가 실용" 한 줄로 안내만 한다.
- 모델이 문장 수를 정확히 세지는 않는다 — 상한은 지침이지 검사가 아니다.

## Links

- Raw originals: (frontmatter 참조 — 대화 파일)
- Related PRs:
