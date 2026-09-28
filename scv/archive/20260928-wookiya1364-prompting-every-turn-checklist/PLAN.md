---
title: 모델별 프롬프팅 — 매 턴 요청을 모델 가이드 요구 항목과 1:1 비교 · 등록하고, 빠지면 같은 턴에 막는다
slug: 20260928-wookiya1364-prompting-every-turn-checklist
author: wookiya1364
created_at: 2026-09-28
status: in_progress
kind: feature
lang: korean
tags: [model, prompting, help, hook, guard, stop-hook, checklist]
raw_sources:
  - scv/conversations/20260927-160059-per-model-prompting-live-check.md
refs: []
invariants:
  - "모든 사용자 메시지(길이와 무관)가 대상 — 글자 수로 건너뛰지 않는다"
  - "사용자 원문은 지우거나 바꾸지 않는다, 모델 · 사고량은 건드리지 않는다"
  - "종료 차단은 같은 턴에 한 번만 — 이미 계속 중(stop_hook_active)이면 막지 않고 다음 턴 경고로, 세션을 절대 멈춰 세우지 않는다"
  - "요구 항목 인용은 가이드 원문에 글자 그대로 있어야 한다 — 래퍼 CI 가 기계로 검사"
  - "호스트 중립(코어에 모델 · 호스트 이름 없음), 맥 · 리눅스 동일"
scope:
  - core/scripts/lib/model-prompting.sh
  - core/scripts/model-prompting.sh
  - core/scripts/help-state.sh
  - core/template/hooks/on-user-prompt.sh
  - core/template/hooks/on-stop.sh
  - core/template/hooks/guard.sh
  - core/protocols/help/prompt-refine.md
  - core/tests/test-model-prompting.sh
  - core/tests/test-help-budget.sh
  - core/TEMPLATE_DIGEST
supersedes: []
---

# 모델별 프롬프팅 — 매 턴 1:1 비교 · 등록, 빠지면 같은 턴에 막는다

## Summary

사용자 요구: 매 턴 사용자 질의를 그 모델 버전의 추천 프롬프트로 바꾼 뒤 모델에 전달 — 확실한 보장, 글자 수로 판단하지 않음,
모델 버전별 요구 항목과 1:1 비교하고 빈 곳은 소크라테스식으로 채움. 결정(Turn 12~13): 요구 항목 목록을 공식 원문에서 뽑아 인용과
함께 둔다, 종료 차단을 마지막 그물로 되살린다, 사용자에게는 다시 쓴 요청 인용 하나에 "맥락에서 채움 · 물음" 항목만 보인다.

## Goals / Non-Goals

- **Goals**
  - **요구 항목 목록**(래퍼 데이터): 가이드 폴더의 `checklist-<key>.tsv` — `<id>\t<label>\t<원문 인용>`. 공통(`*` 행의 키) + 모델별.
    인용은 원문에 글자 그대로 — 래퍼 `check.sh` 가 검사.
  - **매 턴 알림**(모든 메시지): 이 턴의 표(토큰)와 함께 "요청을 요구 항목과 1:1 비교 → 빈 항목은 대화 · 저장소에서 채우거나
    가장 영향 큰 하나를 추천과 함께 묻기 → 등록 → 결론 바로 뒤 인용 → 그것으로 일하기" 와 지난 모델의 항목 목록 · 등록 명령.
    모델을 모르면(맨 첫 턴) 목록 받는 명령을 싣는다. 아직 원문을 안 읽었으면 원문 경로 · 표시 명령도(0.61.0 블록).
  - **등록**: `model-prompting.sh register --model <id>` (stdin: 항목별 `id\tmsg|ctx|asked\t값` + `rewrite\t-\t다시 쓴 요청`).
    SCV 가 그 모델의 목록과 대조해 빠진 항목 · 잘못된 상태 · 빈 값이 없을 때만 이번 턴 등록으로 적는다. 아니면 빠진 것을 알려 준다.
  - **보장 두 겹**: (a) 도구 전 검사 — 이번 턴 등록 전 파일 쓰기(Write/Edit 류) 거절, 사유에 등록 명령. (b) 종료 훅 — 이번 턴
    등록이 없거나 답에 다시 쓴 요청 인용이 없으면 끝내기를 막고 계속하게 한다(같은 턴 한 번). 이미 계속 중이면 막지 않고 다음 턴 경고.
  - **가이드 폴더 찾기 보강**: 프로필 값이 코어 루트 기준으로 안 맞으면 위로 올라가며 `INDEX.tsv` 를 찾는다 — 벤더 코어에서 도는
    훅도 클로드 래퍼의 가이드 폴더를 찾게.
- **Non-Goals**
  - 채운 내용의 품질 판정 — SCV 는 항목이 채워졌는지만 본다.
  - 별도 모델 호출로 다시 쓰기(방식 B) — 채택하지 않음.

## Guardrails

- 종료 차단이 세션을 무한히 붙잡지 않는다 — `stop_hook_active` 면 통과 + 다음 턴 경고. 어떤 실패도 exit 0.
- 등록 · 목록 · 토큰 파일은 저널 폴더 아래, 심볼릭 링크면 쓰지 않는다. 등록 내용은 리댁션을 거친다.
- 매 턴 비용 상한은 의도적으로 올린다(매 턴 블록) — 새 상한과 이유를 검사 파일에 적는다.

## Exit criteria

- All TESTS.md scenarios pass
- 설치본 헤드리스 실측: 짧은 메시지를 포함한 연속 턴에서 모든 턴이 등록 · 인용됨(판정 ok), 등록 전 파일 쓰기는 거절됨.

## Suggested path

1. 래퍼 데이터: 요구 항목 목록 추출(원문 인용) + 인용 검사.
2. 순수부: 목록 병합 · 등록 검증 · 매 턴 블록 · 종료 판정 · 인용 확인.
3. 효과부: `checklist` · `register` · `prompt`(블록 + 토큰) · `gate` · `stop` 확장, 가이드 폴더 찾기.
4. 훅: 매 턴 훅 블록, 가드 쓰기 검사, 종료 훅 차단 출력.
5. 규약 문서 · 비용 상한 · 테스트 → 코덱스 사본 → 릴리스 → 실측.

## Risks / Open Questions

- 종료 차단이 걸리면 답을 다시 쓰게 된다(2026-08-31 에 비싸다고 없앤 방식) — 앞쪽 지시가 주력이라 드물게만 걸리게 한다.
- 코덱스 훅의 종료 차단 · 도구 전 거절 출력 형식은 확인하지 않았다 — 클로드 형식으로 내고, 코덱스 실측은 로그인 뒤.
- 매 턴 블록 비용 — 모든 턴에 수백 바이트가 늘어난다.

## Related Documents

- `scv/archive/20260928-wookiya1364-prompting-first-turn/PLAN.md`
- `core/contracts/guard.md`
