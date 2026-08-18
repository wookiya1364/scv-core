---
title: "쉬운 말 먼저 — 사용자 대상 출력의 기본 규칙"
slug: 20260812-wookiya1364-plain-language
author: "wookiya1364"
created_at: 2026-08-12
status: obsolete
obsoleted_at: 2026-08-18
obsoleted_by: 20260818-wookiya1364-regression-contract-repair
kind: feature
lang: ko
tags: [protocols, ux, language]
raw_sources: []
supersedes: []
scope:
  - "core/protocols/*.md"
  - "core/tests/**"
  - "CHANGELOG.md"
invariants:
  - "promote.md·work.md 외의 프로토콜에 SCV:GUIDANCE 마커를 넣지 않는다 (어블레이션 1단계 범위)"
  - "core/scripts/ 와 core/actions.json 은 수정하지 않는다"
  - "기존 Language preference 절의 내용을 바꾸지 않는다 — 옆에 붙이기만 한다"
---

# 쉬운 말 먼저

## Summary

SCV는 사용자에게 말을 걸 때 어떤 **언어**로 말할지는 정해 두었지만, 얼마나
**쉽게** 말할지는 정해 두지 않았다. 그래서 계획 설명이나 진행 보고가 길고
어려워지고, 읽는 사람이 이해하기 전에 지친다.

규칙 하나를 더한다. **짧고 쉽게 먼저 말하고, 사용자가 더 원할 때 자세히
들어간다.** 비유나 작은 예가 더 빨리 통하면 그걸 쓴다.

이건 취향 문제가 아니라 도구가 쓸모 있느냐의 문제다. 이해되지 않은 계획은
승인받을 수 없고, 이해되지 않은 보고는 판단 재료가 되지 못한다.

## Goals / Non-Goals

- **Goals**
  1. 프로토콜 13개의 `## Language preference` 옆에 `## Plain language first`
     절을 추가한다. 문구는 13개 파일에서 **동일**하게 유지한다.
  2. 사용자가 읽는 모든 것에 적용됨을 명시한다 — 질문, 계획, 진행 보고, 요약,
     에러 설명.
  3. 회귀 가드: 13개 파일 전부에 그 절이 있는지 테스트로 고정한다.

- **Non-Goals**
  - 기존 `Language preference` 절 수정 (언어 선택 규칙은 그대로)
  - 공통 블록 주입 장치 신설 (`{{SCV_...}}` 토큰) — 아래 참조
  - promote·work 외 프로토콜에 `SCV:GUIDANCE` 마커 도입

## Approach Overview

**왜 13번 복사하나.** 프로토콜은 액션마다 따로 로드된다. 모든 액션이 읽는
공통 서문이 없다. `Language preference`도 같은 이유로 13번 복사돼 있다.
토큰(`{{SCV_PLAIN_LANGUAGE}}`)을 만들어도 **각 파일에 토큰을 적어야 하므로
파일 수는 그대로**고, 빌드 단계에 장치만 하나 더 는다. 기존 패턴을 따른다.

**분류 문제.** 어블레이션 기준으로 보면 이건 "채팅 출력 전용 코칭"이라
GUIDANCE다. 그런데 `test-guidance.sh` [6]이 promote·work 외 프로토콜에
마커가 들어가는 것을 막는다(1단계 범위). 그래서 **13개 전부 마커 없이**
넣는다 — 결과적으로 CONTRACT로 취급된다.

이건 의도적 타협이다. 같은 문구를 파일마다 다르게 분류하는 것보다는 일관되게
두는 편이 낫고, 어블레이션 2단계에서 나머지 프로토콜에 마커를 도입할 때 함께
GUIDANCE로 감싸면 된다. CHANGELOG에 그 이월을 적는다.

## Guardrails

- `core/scripts/`, `core/actions.json`, host-profile 계약은 건드리지 않는다.
- `promote.md`·`work.md` 외 프로토콜에 `SCV:GUIDANCE` 마커를 넣지 않는다.
  넣으면 `test-guidance.sh` [6]이 실패한다.
- 기존 `## Language preference` 절의 본문을 수정하지 않는다.
- 새 절의 문구는 13개 파일에서 **바이트 동일**해야 한다. 파일마다 다르게 쓰면
  유지가 안 된다.
- 새 절 안에 `${SCV_CORE_ROOT}/scripts/*.sh` 호출이나 **컬럼0 frontmatter 키**를
  쓰지 않는다. 어블레이션 동등성 비교가 깨진다.
- 호스트 종속 토큰 금지 — `Claude` / `Codex` / `/scv:` / 모델명.
- 규칙 자체가 쉬운 말로 쓰여 있어야 한다. 어려운 문장으로 "쉽게 쓰라"고 하면
  그 자체가 반례다.

## Exit criteria

- `core/protocols/*.md` 13개 전부에 `## Plain language first` 절이 있고, 그
  본문이 서로 동일하다.
- `guidance-filter.sh --lint`가 promote·work에서 OK, `--mode full`이 원본과
  바이트 동일.
- `--mode minimal` 투영에도 그 절이 살아 있다(마커 밖이므로).
- `run-dry.sh` · `test-*.sh` 18종 · `tests/run.sh` 전부 green.
- 13개 파일 존재를 고정하는 회귀 assert가 있다.
- `git diff --name-only HEAD -- core/scripts/ core/actions.json`이 비어 있다.

## Suggested path

1. 절의 문구를 확정한다. 짧게 — 열 줄 안쪽.
2. 13개 프로토콜의 `## Language preference` 절 **뒤**에 삽입한다.
3. `run-dry.sh`에 13개 전부를 확인하는 assert를 넣는다.
4. 스위트 실행. `test-guidance.sh` [6]은 커밋 전까지 빨간불이다(프로토콜 11개가
   promote·work 밖) — 커밋 후 해소되는지 확인한다.
5. CHANGELOG에 기록. 2단계 GUIDANCE 이월도 함께 적는다.
6. archive → DECISIONS 엔트리.

## Related Documents

<!-- 없음 -->

## Risks / Open Questions

- **CONTRACT가 13개 × 약 10줄 늘어난다.** minimal 투영이 커지는데, 이는
  어블레이션 목표와 반대 방향이다. 2단계에서 GUIDANCE로 감싸면 해소된다.
- **지켜지는지 검증할 수단이 없다.** 테스트가 보장하는 것은 "프로토콜에 문장이
  있다"까지다. 에이전트가 여전히 어렵게 말해도 실패하는 테스트는 없다.
  `path delta`와 같은 한계다.
- **문구를 나중에 고치면 13곳을 다 고쳐야 한다.** 회귀 assert가 누락을 잡지만
  불일치 자체를 막지는 못한다. 2단계에서 토큰화를 재검토한다.
