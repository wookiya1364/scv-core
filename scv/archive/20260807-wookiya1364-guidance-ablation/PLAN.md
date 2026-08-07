---
title: "가이던스 어블레이션 1단계 — CONTRACT/GUIDANCE 분리 + SCV_GUIDANCE=minimal (promote·work)"
slug: 20260807-wookiya1364-guidance-ablation
author: "wookiya1364"
created_at: 2026-08-07
status: planned
kind: refactor
lang: ko
epic: 20260807-scv-simplification
tags: [ablation, protocols, guidance, simple-mode]
raw_sources: []
refs:
  - type: reference
    url: "https://www.youtube.com/watch?v=qyPCVqFUyDo"
    note: "Boris Cherny — 시스템 프롬프트 80% 삭제, CLAUDE_CODE_SIMPLE=1 어블레이션"
supersedes: []
invariants:
  - "CONTRACT(파일 경로·frontmatter 스키마·스크립트 호출·불변식)는 어떤 모드에서도 절대 생략되지 않는다"
  - "기본 모드(SCV_GUIDANCE 미설정)의 주입 내용은 분리 전과 의미적으로 동일 — 두 호스트 동작 동일성 유지"
  - "1단계 범위는 promote.md · work.md 2개 프로토콜로 한정한다"
---

# 가이던스 어블레이션 1단계

## Summary (what & why)

SCV 프로토콜(promote.md ~800줄)은 결정론적 **계약**과 행동 **코칭**이 섞여
있다. Boris 의 어블레이션 논리대로면 코칭은 모델이 좋아질수록 무가치하거나
해로울 수 있는데, SCV 에는 이를 측정할 수단이 없다. Claude Code 의
`CLAUDE_CODE_SIMPLE=1` 과 동형인 스위치를 SCV 에 만들어, "지우고 → 측정하고
→ 필요한 것만 되살리는" 체계를 SCV 자체가 갖추게 한다. 위험을 통제하기 위해
1단계는 **하네스 + 최대 프로토콜 2개(promote·work)**로 한정한다.

## Goals

1. **마크업 규약**: 프로토콜 md 안에서 가이던스 블록을
   `<!-- SCV:GUIDANCE -->` … `<!-- /SCV:GUIDANCE -->` 로 감싼다. 마커 밖은
   전부 CONTRACT. 분류 기준을 문서화: 삭제해도 산출물의 형식·경로·불변식이
   변하지 않으면 GUIDANCE, 변하면 CONTRACT.
2. **주입 스위치**: 프로토콜을 호스트에 주입하는 지점(래퍼가 사용하는 Core
   진입 스크립트)에 `SCV_GUIDANCE=full|minimal` (기본 full). minimal 이면
   GUIDANCE 블록을 제거하고 주입. 프로토콜 파일 자체는 불변 — 주입 시점
   필터.
3. **어블레이션 하네스**: run-dry 의 promote·work 경로를 두 모드로 실행해
   **산출물(생성 파일 목록·frontmatter·스크립트 호출 시퀀스)이 동일**함을
   비교하는 테스트. 차이가 나면 해당 지시는 GUIDANCE 가 아니라 CONTRACT 였던
   것 — 재분류를 강제하는 안전망.
4. **promote.md·work.md 분류 작업**: 전 행을 CONTRACT/GUIDANCE 로 분류.
   목표 비율을 정하지 않는다 — 분류 기준만 따르고 결과 비율을 CHANGELOG 에
   보고 (Boris: 예측하지 말고 측정하라).
5. **2단계 예고(이 계획 범위 밖)**: 나머지 12개 프로토콜 확산은 1단계 릴리스
   후 실사용 피드백(minimal 모드로 쓴 프로젝트의 문제 보고)을 근거로 별도
   계획.

## Non-Goals

- 나머지 12개 프로토콜 분리 (2단계)
- 프로토콜 내용 삭제 (분리와 스위치만 — 삭제 판단은 측정 후)
- 호스트별 시스템 프롬프트/CLAUDE.md 관여

## Steps

1. 마커 규약 + 분류 기준 문서 (docs/ 또는 프로토콜 헤더)
2. 주입 필터 구현 (Core 진입 스크립트 + wrapper 전달 경로 조사)
3. 어블레이션 비교 하네스 (run-dry 확장 또는 별도 test)
4. promote.md 분류 → 하네스 통과 → work.md 분류 → 하네스 통과
5. CHANGELOG 에 분류 결과(줄 수 비율) 보고 (0.22.0 웨이브 또는 후속 0.23.0)

## Risks / Open Questions

- **주입 지점이 호스트마다 다를 수 있음** — Step 2 조사에서 래퍼가
  프로토콜을 어떻게 로드하는지 확인 필요. 필터를 Core 스크립트로 만들 수
  없으면 계약(마커) + 래퍼 handoff 로 전환.
- GUIDANCE 로 분류했지만 실은 특정 호스트/모델에서 필요한 지시 → 기본값이
  full 이므로 사용자 피해 없음. minimal 은 명시적 옵트인.
- 마커가 deck/문서 렌더에 노출될 가능성 → HTML 주석이라 마크다운 렌더에서
  불가시, 테스트로 확인.
