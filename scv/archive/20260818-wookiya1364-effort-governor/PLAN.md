---
title: effort governor — 작업 무게에 맞춘 자동 실행 조절
slug: 20260818-wookiya1364-effort-governor
author: wookiya1364
created_at: 2026-08-18
status: done
kind: feature
lang: korean
tags: [effort, cost, protocols]
raw_sources:
  - scv/raw/stale/20260818-wookiya1364-effort-governor.md
refs: []
invariants:
  - "자동 승급은 올리는 방향만 존재한다 — 검증 도중 강등 금지"
  - "SCV_EFFORT_MODE=off 는 현재 동작과 100% 동일하다 (판정도 출력도 없음)"
  - "사용자의 그 자리 지시가 어떤 판정보다 우선한다"
  - "core/ 텍스트는 호스트 레벨명 대신 밴드명과 실행 형태로만 말한다"
---

# effort governor — 작업 무게에 맞춘 자동 실행 조절

## Summary

세션 effort 다이얼은 사용자 소유라 모델이 못 돌리지만, 비용의 지배항은 다이얼이
아니라 실행 방식이다. 계획서에서 셀 수 있는 신호로 밴드를 판정하고(백테스트
13/14), 밴드×단계 격자로 6레벨 전부를 결정적으로 배치해, 가벼운 작업이 ultra
세션에서도 조용히 싸게 돌게 한다. 기본은 auto — 개입 0, 통지 한 줄.

## Goals / Non-Goals

- **Goals**
  - `effort-class.sh`: 계획 폴더에서 밴드(standard/heavy/orchestration)와 승급
    장전 여부를 결정적으로 판정, 감사 가능한 REASON 한 줄 출력
  - `SCV_EFFORT_MODE=auto|ask|off` (.env, 기본 auto) — auto 는 판정대로 실행,
    ask 는 큰 어긋남에만 객관식 1회, off 는 완전 무동작
  - work.md·codegen.md 에 집행 절: 밴드×단계 격자(기계 low → 종합 medium →
    구현 high/xhigh → 검증 high/max/팬아웃), 승급 사다리, 아카이브 실측 기록
  - 어느 모드든 자동 승급 동작(품질 보호 방향만)
- **Non-Goals**
  - 세션 다이얼 변경 — 호스트가 권한을 주지 않고, 주더라도 사용자 소유가 맞다
  - light 밴드 예측 — 실측 0건, 실측 3건까지 닫는다 (기계 단계·economy 액션의
    결정적 low 와는 별개)
  - 6레벨을 확률로 예측 — 격자는 결정적 배치이지 예측이 아니다
  - economy 액션의 모델 라우팅 변경 — 이미 배송됨

## Approach Overview

**판정은 스크립트, 집행은 프로토콜.** `core/scripts/effort-class.sh` 가 계획
폴더에서 신호를 세어(parallel_groups·cross-repo 선언·adversarial 요구·raw 크기)
백테스트 통과 규칙 R1→R2→R3 로 밴드를 내고, {cross-repo, adversarial,
raw≥9000B} 중 2개 이상이면 `EFFORT_ESCALATION: armed` 를 함께 낸다. frontmatter
`effort_class:` 선언이 있으면 항상 이긴다.

세션 자세는 스크립트가 볼 수 없으므로(호스트가 env 로 노출 안 함) 모드 분기와
격자 집행은 프로토콜 텍스트가 모델에게 지시한다: Step 6 직전에 판정 실행 →
auto 면 한 줄 통지 후 격자대로, ask 면 두 단계 이상 어긋날 때만 객관식 1회,
off 면 아무것도 하지 않는다. standard 판정의 계획 범위에서는 다중 에이전트
오케스트레이션을 띄우지 않는다 — 그것이 절약의 지배항이다.

아카이브 --reason 에 (판정, 실사용 밴드, 승급 이력) 을 남겨 다음 백테스트가
92.9% 와 격자를 갱신한다.

## Guardrails

- 검증 도중 강등 금지. 승급은 실측 신호(같은 단계 적색 2회, 반박 복수)로만,
  재승인 없이 한 밴드씩
- off 모드는 판정 스크립트 호출조차 하지 않는다 — 현재 동작과 바이트 동일 경험
- core/ 호스트 중립: 레벨명(xhigh 등) 금지, 밴드명·실행 형태·"the host's session
  effort setting" 으로만. 레벨 매핑 표는 래퍼 문서 몫
- work.md·codegen.md 는 guidance-filter 계약 대상 — lint 통과, full 투영 바이트
  동일 유지(회귀 계약 T2가 감시), guard-consistency 구문 스윕 통과
- effort-class.sh 는 판정만 한다 — 파일을 쓰지 않는다
- TESTS 는 내구성 규칙 준수: git-diff 단언 금지, 실존 파일만, 전체 스위트 재실행
  금지, sentinel 은 CANARY-*-토큰

## Exit criteria

- TESTS.md 시나리오 전부 통과, 옛 코드(스크립트 부재·프로토콜 무절)에서 실패하는
  회귀 케이스 존재
- 판정이 백테스트 14건을 재현한다: 아카이브 14 슬러그에 effort-class.sh 를
  돌리면 백테스트 예측과 동일한 밴드 (13 적중 1 과소 그대로 — 규칙이 같으므로)
- auto/ask/off 세 모드의 프로토콜 지시가 상호 배타적이고, off 가 무동작임이
  텍스트로 검증된다
- 전체 스위트 초록, 릴리스 아티팩트에 포함

## Suggested path

1. effort-class.sh — 신호 산출·규칙·선언 우선·REASON/ESCALATION 출력
2. test-effort-class.sh — 픽스처 판정 + 아카이브 14건 재현 + 선언 우선 + 무해성
3. work.md·codegen.md — Effort governor 절 (모드 분기, 격자, 승급, 기록)
4. .env.example.scv — SCV_EFFORT_MODE 문서화
5. 전체 스위트 + 문서 정합(guard-consistency·guidance lint)

## Related Documents

- [`TESTS.md`](./TESTS.md)

## Risks / Open Questions

- grep 신호는 휴리스틱 — cross-repo 를 본문 어휘(wrapper/래퍼)로 검출한다. 오탐은
  위쪽(heavy)으로만 틀리므로 품질 위험이 아니라 소폭 낭비다. frontmatter 선언이
  항상 탈출구
- ask 모드의 "두 단계 어긋남" 판단은 모델 몫 — 세션 자세를 아는 유일한 주체
- 격자 세부는 초기값 — 아카이브 실측 기록이 쌓이면 백테스트로 보정
- 래퍼 후속: README 레벨 매핑 표(3언어), codex 는 팬아웃 미지원이라 orchestration
  칸이 순차 강하 — 문서 한 줄

## Links

- Raw originals: (frontmatter 참조)
- Related PRs:
