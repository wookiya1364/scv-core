---
title: 큰 시험 파일 나누기 — CI 가장 느린 조각 줄이기(릴리스 없이)
slug: 20261104-wookiya1364-split-big-tests
author: wookiya1364
created_at: 2026-11-04
status: testing
kind: refactor
lang: korean
tags: [ci, tests]
raw_sources:
  - scv/conversations/20261102-182255-writing-style-bullets.md
refs:
  - type: link
    url: https://news.hada.io/topic?id=34105
invariants:
  - "시험 내용 · 판정은 그대로 — 통과 개수 합계가 나누기 전과 같음"
  - "지난 계획의 시험 명령(원래 파일 이름)은 계속 전부를 돌림"
---

# 큰 시험 파일 나누기

## Summary

- Linear 의 CI 개선 글(사용자 링크)에서 우리에게 효과가 있는 것은 '큰 시험 파일 나누기' 하나(확인 — 우리 CI 는 준비 15초 남짓, 시간은 시험 본체).
- 맥 CI 조각 5개가 209~301초, 가장 큰 파일 선택지 시험 199초 · 실체 보여 주기 시험 125초 · 모델 프롬프트 시험 111초.
- 사용자 결정: 나누되 릴리스 없이 develop 에만.

## Goals / Non-Goals

- **Goals**: 선택지 시험 3조각, 실체 보여 주기 시험 2조각. 원래 이름은 조각을 차례로 부르는 묶음(`# scv-test: aggregate`), 전체 시험 · 회귀는 묶음을 건너뜀. 시간 기록표 갱신.
- **Non-Goals**: 모델 프롬프트 시험 — 9곳을 시도했지만 뒤 조각이 앞 조각의 값을 써서 나눌 수 없었음(보류). 시험 내용 변경.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | rf_list_tests | 시험 목록에서 묶음을 뺌 | 폴더 → 시험 줄들 | 부수효과 (입구: 파일 읽기) |
| 2 | regression core loop | 코어 시험 목록에서 묶음을 뺌 | 파일들 → 키들 | 부수효과 (입구) |

- 부수효과 위치: 둘 다 파일 목록을 읽는 입구. 새 순수 함수 없음.

## Guardrails

- 조각마다 통과, 조각 통과 합계 = 원래(선택지 89 · 실체 보여 주기 78)
- 원래 이름으로 돌리면 전부 돈다(지난 계획 22개가 부름)

## Exit criteria

- TESTS.md T1–T3 통과, 전체 시험 · 회귀 통과
- PR CI 의 맥 가장 느린 조각 수치 보고(전 약 300초)

## Suggested path

1. 나누기 · 묶음 · 목록 건너뛰기 — `rf_list_tests`, `regression core loop`
2. 시간 기록표 갱신 — 조각 이름으로 시간을 나눠 적음
3. 전체 시험 · 회귀 · PR CI 수치 — 전후를 잼
