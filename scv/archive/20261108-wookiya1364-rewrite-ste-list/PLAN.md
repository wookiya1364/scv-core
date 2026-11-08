---
title: 다시 쓴 요청에 한국어판 STE 목록 적용 + 규칙 충돌 문구 2건
slug: 20261108-wookiya1364-rewrite-ste-list
author: wookiya1364
created_at: 2026-11-08
status: planned
kind: feature
lang: korean
tags: [model-prompting, rewrite, rules]
raw_sources:
  - scv/conversations/20261108-080440-read-karpathy-subtitle.md
invariants:
  - "SCV_LANG 이 korean 이 아니면 지금과 같은 출력(목록 구역이 없으면 싣지 않음)"
  - "SCV_REWRITE_STE=off 이면 지금과 같은 출력"
  - "가이드 읽음 판단 · GUIDE 줄은 그대로"
---

# 다시 쓴 요청에 한국어판 STE 목록 적용 + 규칙 충돌 문구 2건

## Summary

다시 쓴 요청 규칙은 '가장 좋은 프롬프트로 다시 써라'라는 방향만 있고 목록이 없었다. 항공 정비 설명서용 쉬운 영어(ASD-STE100)의 규칙을 한국어로 옮기고, 낱말은 실제 긴 대화(slay 세션 요청 269개)에서 뽑은 목록 3판을 만들어 지난 실제 요청 20개로 가린 채 비교했다: 다시 쓴 요청 15승 3패(뜻 보존 4.35/3.60 · 한 가지로 읽힘 4.05/4.00 · 사용자 확인 쉬움 4.80/3.75 · 군더더기 없음 4.75/3.05), 길이 157자/269자, 그 글을 받은 답 10승 8패. 이 목록을 help 가이드 안내 단계에 세션마다 한 번 싣는다. 같은 점검에서 찾은 규칙 충돌 2건(첫 도구 자리 · 마무리 상자 질문)의 문구도 실제 동작에 맞춘다.

## Goals / Non-Goals

- **Goals**
  - `core/contracts/rewrite-ste.md` 의 `ste:korean` 구역을 SCV_LANG 이 korean 일 때 가이드 안내 끝에 `STE:` 로 싣는다(규약 지문마다 한 번 전문, 그 뒤는 한 줄)
  - 설정 `SCV_REWRITE_STE`(on|off, 기본 on)
  - 다시 쓰기 절차(prompt-refine 2)가 `STE:` 목록을 따르게 한다
  - 첫 행동 안내 · choices.md 10항 문구를 실제 동작에 맞춘다
- **Non-Goals**
  - 금지 낱말 자동 검사(등록 때 거절) — 다음 단계
  - 다른 언어 목록, 매 턴 규칙 줄이기

## Guardrails

- korean 이 아니거나 off 이면 출력이 지금과 같다
- 선택 안내 줄(400B 상한)은 건드리지 않는다

## Exit criteria

- TESTS.md 시나리오 통과, 관련 기존 시험 통과

## Suggested path

1. 계약 파일 `rewrite-ste.md` 작성 — `단계 1` — 목록 3판을 구역으로
2. 가이드 안내 끝에 STE 싣기 — `단계 2` — 구역 고르기 함수 재사용
3. prompt-refine 2 에 한 줄 — `단계 3` — 목록을 따르게
4. 시험 · 버전 · 변경 기록 — `단계 4`
