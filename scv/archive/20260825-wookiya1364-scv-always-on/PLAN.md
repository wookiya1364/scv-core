---
title: "일반 대화에도 SCV 가 끼어든다 — SCV_ALWAYS_ON 스위치"
slug: 20260825-wookiya1364-scv-always-on
author: "wookiya1364"
created_at: 2026-08-25
status: obsolete
obsoleted_at: 2026-09-01
obsoleted_by: 20260901-wookiya1364-preflight-directive-strength
kind: feature
lang: korean
tags: [hooks, help, routing, settings]
raw_sources:
  - scv/raw/stale/20260825-wookiya1364-scv-always-on.md
refs: []
supersedes: []
scope:
  - "core/template/hooks/on-user-prompt.sh"
  - "core/scripts/lib/settings.sh"
  - "core/template/scv/scv_settings.example.json"
  - "core/TEMPLATE_DIGEST"
  - "core/tests/test-always-on.sh"
  - "core/tests/test-journal.sh"
  - "CHANGELOG.md"
invariants:
  - "off 만 끈다 — 값이 없거나 다른 값이면 켜져 있다 (쉬운말 스위치와 같은 규칙)"
  - "이미 액션 프로토콜이 실린 턴은 가로채지 않는다 — 진행 중인 작업을 끊지 않는다"
  - "훅은 어떤 경우에도 세션을 막지 않는다 (기존 NON-BLOCKING 보장 유지)"
  - "새 키는 설정 등록부(공개 키 목록)와 예시 파일에 함께 실린다 — 숨은 키를 만들지 않는다"
---

## Why

`scv:help` 를 쳐야만 SCV 가 움직인다. 명령 없는 일반 대화는 스킬 설명의 권고에
기대는데, 호스트 모델이 대부분 무시한다 (raw 참조). 사용자는 프로젝트 단위
스위치로 "무조건 끼어들기"를 원한다.

## What

### 1. 스위치 — `SCV_ALWAYS_ON` (on/off, 기본 on)

- `SCV_PLAIN_KEYS` 등록 (26 → 27), 예시 파일에 `_doc` + 기본값 `"on"`.
- 판정 규칙은 쉬운말 스위치와 동일: off(대소문자 무관)만 끈다.

### 2. 훅 — `on-user-prompt.sh` 에 라우팅 지시 블록

쉬운말 블록 다음에, 스위치가 꺼져 있지 않으면 stdout 으로 한 블록 추가:

- 이 메시지를 SCV 입력으로 다뤄라 — help 액션의 상태 점검과 Mode 판정
  (A 진단 / B 대화 / B' 아카이브 검색)을 거쳐 그 프로토콜로 답하라.
- 단, 이번 턴에 이미 SCV 액션 프로토콜이 실려 있으면 그것을 계속하라
  (가로채지 않는다).
- 끄는 법 한 줄 명시 (`scv/scv_settings.json SCV_ALWAYS_ON=off`).

기존 보장 유지: scv/ 없는 프로젝트는 출력 없음, 설정 라이브러리를 못 찾아도
세션을 막지 않음, 저널 기록 동작 불변.

### 3. 템플릿 지문

`core/template/` 이 바뀌므로 `compute-template-digest.sh > core/TEMPLATE_DIGEST`.

## Non-Goals

- 코드 레벨 강제(호스트가 지원하지 않음) — 매 턴 지시가 상한. 한계는 사용자와
  공유됨.
- help 프로토콜 본문 변경 — 라우팅만 넘기고 Mode 판정은 기존 문법에 맡긴다.
- 래퍼별 훅 등록 방식 변경 (등록은 래퍼 소유 — 기존 계약 그대로).

## Guardrails

- 호스트 중립(core/ 에 호스트 이름 금지), whitespace 계약(파일 끝 빈 줄 금지),
  기존 `test-journal.sh` [6] 훅 계약 green 유지.
- 설정 키 개수를 세는 기존 테스트가 있으면 함께 갱신 (26 → 27).

## Exit criteria

- 키 없음/on/이상값 → 훅 stdout 에 라우팅 블록, off → 없음 (쉬운말 블록과
  독립).
- scv/ 없는 폴더 → 출력 없음.
- `bash core/tests/test-always-on.sh` green + `test-journal.sh`·`test-settings.sh`
  green.
