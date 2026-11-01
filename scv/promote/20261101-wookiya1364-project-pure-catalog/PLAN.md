---
title: 프로젝트 순수함수 사전 — 어느 언어든 scv/core 에
slug: 20261101-wookiya1364-project-pure-catalog
author: wookiya1364
created_at: 2026-11-01
status: planned
kind: feature
lang: korean
tags: [purity, reuse, catalog, any-language]
raw_sources:
  - scv/conversations/20261101-003000-pure-function-catalog-reuse.md
refs:
  - type: link
    url: scv/archive/20261101-wookiya1364-pure-function-catalog/PLAN.md
invariants:
  - "scv-core 자신의 사전(셸 함수 239개)은 결과가 바이트까지 그대로다"
  - "셸 함수의 예시는 지금처럼 실제로 돌려 확인한다"
  - "맥 기본 bash 3.2 · 리눅스에서 같은 결과"
---

# 프로젝트 순수함수 사전 — 어느 언어든 scv/core 에

## Summary

지금 순수함수 사전은 SCV 자신의 셸 함수만 다룬다. 래퍼를 쓰는 사용자 프로젝트에서도 그 프로젝트의 함수를 그 저장소의 `scv/core/catalog/pure/` 에 모아, 기기가 바뀌거나 여럿이 작업해도 같은 사전을 보게 한다. 언어는 정하지 않는다 — 자바 · C · 러스트 · TS · 파이썬 등 무엇이 와도 같은 규칙: 주석 표식 줄에 함수 이름을 적고(`@pure 이름`), 역할 · 종류 · 예시를 곁에 단다.

## Goals / Non-Goals

- **Goals**
  - 표식 줄 `@pure 이름` · `@deterministic 이름` 을 주석 모양과 상관없이 찾는다(`#` `//` `///` `--` `;` `*` `/*` 등). 셸의 이름 없는 표식은 그대로 받는다.
  - 프로젝트 모드: 저장소의 추적 파일 중 표식이 든 파일만 읽어 `<저장소>/scv/core/catalog/pure/` 에 사전을 만든다. 시험 · 의존성 · 생성물 폴더는 뺀다(설정으로 바꿀 수 있음).
  - 예시: 셸 함수는 실제로 돌린다. 다른 언어는 칸(역할 · 종류 · 예 · →)만 검사하고, 그 사실을 결과 줄에 숫자로 밝힌다(조용히 건너뛰지 않음).
  - 중복: 셸은 지금처럼 출력 지문. 다른 언어는 예시끼리 비교 — 같은 입력에 같은 출력인 예시를 공유하고, 같은 입력에 다른 출력인 예시가 없으면 중복 의심.
  - work · codegen 규약: 어느 프로젝트든 새 순수함수 전에 그 프로젝트의 차례를 읽고, 만든 뒤 사전을 다시 만든다.
- **Non-Goals**
  - 다른 언어의 예시를 실제로 실행하기(언어별 실행기는 다음 계획 후보).
  - 표식 없는 함수 자동 찾기.

## Approach Overview

- 원본은 여전히 코드 옆 주석 하나. 표식 줄에 이름이 있으면 그 이름을 쓰고, 없으면(셸) 다음 함수 정의에서 이름을 읽는다 — 언어 파싱 없음.
- 주석 앞머리 모양을 지운 뒤 같은 `역할:` · `종류:` · `예:` 줄을 읽는다. 표식에서 시작해 주석 줄이 끊길 때까지가 한 묶음.
- 파일 고르기는 `git grep -l` 로 표식이 든 추적 파일만 — 언어 · 확장자 목록이 필요 없다.
- 사전 파일 모양 · 종류 표 · 크기 한도 · 예외 목록은 scv-core 와 같다(같은 순수함수가 만든다). 항목에 위치(파일)가 붙어 언어는 확장자로 드러난다.
- scv-core 저장소는 지금 모드 그대로(코어 스크립트), 사용자 프로젝트는 프로젝트 모드. 두 모드는 고르는 파일만 다르고 나머지 단계는 같다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  listMarkedFiles,     // 저장소 → 표식이 든 추적 파일들 (입구, 부수효과)
  extractEntries,      // 파일 내용 → 항목들 (이름 · 층 · 역할 · 종류 · 예시)
  validateEntries,     // 항목들 → 빈 칸 · 모르는 종류
  runShellExamples,    // 셸 항목 → 예시 실제 출력 (결정적 — 함수 호출)
  textDuplicates,      // 셸 아닌 항목들 → 예시를 공유하고 어긋남 없는 짝
  renderCatalog,       // 항목 + 종류 표 → 차례 + 종류 파일 글
  writeOrCompare,      // 글 → 파일 쓰기 또는 낡음 판정 (출구, 부수효과)
)
```

| # | 단계 | 하는 일 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|---|
| 1 | listMarkedFiles | 표식이 든 추적 파일을 고른다(제외 폴더 빼고) | 저장소 → 파일 목록 | 부수효과 (입구) |
| 2 | extractEntries | 어떤 주석 모양이든 표식 · 이름 · 세 칸을 뽑는다 | 파일 내용 → 항목들 | 결정적 |
| 3 | validateEntries | 빈 칸 · 모르는 종류를 찾는다 | 항목 + 종류 표 → 위반 | 순수 |
| 4 | runShellExamples | 셸 함수만 예시를 실제로 돌린다 | 셸 항목 → 틀린 예시 | 결정적 (함수 호출) |
| 5 | textDuplicates | 예시 글로 중복 짝을 찾는다 | 항목들 → 중복 의심 짝 | 순수 |
| 6 | renderCatalog | 사전 글을 만든다 | 항목 + 종류 표 → 파일 글들 | 결정적 |
| 7 | writeOrCompare | 쓰거나 낡음을 알린다 | 파일 글 → 결과 | 부수효과 (출구) |

- 부수효과 위치: 1(파일 고르기 · 읽기)과 7(쓰기 · 비교)만. 4 는 표식 함수를 부르지만 그 함수들의 순수성은 기존 순수 검사가 본다.
- 재사용: 3 · 6 과 셸 쪽 4 · 지문 중복은 지금의 검사기 순수부를 그대로 쓴다. 바뀌는 것은 2(표식 읽기 넓히기)와 1 · 5(새로).

## Guardrails

- scv-core 자신의 사전 결과가 바뀌면 안 된다 — 기존 시험 T1–T13 그대로 통과.
- 언어 · 확장자 목록을 코드에 두지 않는다. 주석 앞머리 모양만 안다.
- 실행하지 않은 예시를 '맞음'이라 하지 않는다 — 결과 줄에 '실행 n · 칸만 m' 로 나눠 적는다.
- 사용자 프로젝트에 사전 말고 다른 파일을 만들지 않는다.

## Exit criteria

- All TESTS.md scenarios pass
- 자바 · C · 러스트 · TS · 파이썬 · 셸이 섞인 시험 프로젝트에서 한 번의 build 로 모든 함수가 `scv/core/catalog/pure/` 에 오른다.
- 래퍼 설치본에서 프로젝트 모드가 그 프로젝트 저장소에 사전을 만든다(설치본 복사본 시험).

## Suggested path

1. 표식 읽기를 넓힌다 — 이름 붙은 표식 · 여러 주석 모양 — `extractEntries`
2. 프로젝트 모드 파일 고르기와 제외 폴더 설정 — `listMarkedFiles`
3. 셸 아닌 항목의 예시 글 중복 판정, 결과 줄에 실행 · 칸만 개수 — `textDuplicates`, `runShellExamples`
4. 프로젝트 사전 쓰기 · 낡음 검사 — `renderCatalog`, `writeOrCompare`
5. 계약 · work · codegen 규약 갱신 — 어느 프로젝트든 차례부터 읽고, 만든 뒤 다시 만들기
6. 여러 언어가 섞인 시험 프로젝트로 시험 · 맥 bash 3.2 확인 — 시험을 쓰고 돌린다

## Related Documents

- `core/contracts/purity.md` — 사전 규칙(이 계획이 넓힘)
- `scv/archive/20261101-wookiya1364-pure-function-catalog/PLAN.md` — 앞 계획

## Risks / Open Questions

- 주석이 아닌 글(문자열 · 문서)에 `@pure 이름` 이 있으면 잘못 잡힌다 — 제외 폴더(시험 · 문서)와 '주석 앞머리로 시작하는 줄만'으로 줄인다(추정 — 드묾).
- 예시 글 비교는 실제 실행보다 약하다 — 같은 일을 다른 예시로 적은 두 함수는 못 잡는다. 사전 읽기 규칙이 보완.
- 큰 저장소에서 `git grep` 시간 — 측정해 보고.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
