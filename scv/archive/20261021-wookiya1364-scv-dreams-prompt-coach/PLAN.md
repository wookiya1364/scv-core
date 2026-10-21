---
title: 드림 — 프롬프트 코치 (지난 세션을 돌아보며 질의 ÷ 목표 도달 비율과 더 좋은 프롬프트 쓰는 법을 알려 준다)
slug: 20261021-wookiya1364-scv-dreams-prompt-coach
author: wookiya1364
created_at: 2026-10-21
status: testing
kind: feature
lang: korean
tags: [dreams, prompting, report, hooks]
raw_sources:
  - scv/conversations/20261021-165832-scv-dreams-prompt-coach.md
refs:
  - type: link
    url: https://platform.claude.com/docs/ko/managed-agents/dreams
invariants:
  - "드림은 입력(세션 기록 · 보관된 계획 · 메모 · 대화 기록)을 바꾸지 않는다"
  - "훅은 드림 때문에 막히거나 느려지지 않는다(배경 실행, 실패해도 세션은 그대로)"
  - "SCV_DREAMS=off 면 훅 출력이 이 기능 전과 바이트 단위로 같다"
---

# 드림 — 프롬프트 코치

## Summary

SCV 는 지금 사람의 요청을 다시 써서 모델에 맞춘다. 드림은 그 반대쪽을 돕는다 — 지난 세션을 돌아보며 사람이 처음부터 더 좋은 프롬프트를 써서 목표(계획 보관)에 더 빨리 닿게 한다. Managed Agents 의 Dreams 처럼 입력은 절대 바꾸지 않고 결과를 따로 만들지만, API · 접근 승인 없이 이 컴퓨터의 세션 기록으로 로컬에서 돈다. 실제 기록 미리 보기(이 저장소): 보관된 계획 하나에 사람 질의 약 7~11번(9/21~30 66 ÷ 10, 10/1~10 87 ÷ 8).

## Goals / Non-Goals

- **Goals**
  - 새 명령 `scv:dreams` 로 직접 부르기.
  - 자동 발동: 대화 비움(clear) · 압축(compact) 직후, 그리고 날짜가 바뀐 뒤 첫 사람 메시지 — 각 한 번, 배경에서.
  - 기간별 '사람 질의 수 ÷ 계획 보관 수' 비율과 계획마다 '보관까지 걸린 질의 수' 분포를 차트로.
  - 개선점: 규칙으로 찾은 것(예: 요청에 완료 기준 · 깊이를 직접 말한 비율, 정정 턴 비율, 보관까지 질의가 많았던 계획)에 근거 턴(짧은 발췌)을 붙인다.
  - 프롬프팅 가이드 조언: 발동마다 판정자(호스트 판정자 명령)가 근거 발췌를 읽고 이 모델의 가이드 규칙 이름을 들어 '다음에 이렇게 쓰면' 예시를 쓴다.
  - 결과: HTML 보고서(내장 SVG 차트) + 다음 턴 맨 위 한 줄 요약.
  - 설정: `SCV_DREAMS`(on 기본 / off), `SCV_DREAMS_JUDGE`(on 기본 / off).
- **Non-Goals**
  - 진짜 Dreams API 호출(접근 요청 · API 과금 · 기록 반출).
  - 사람의 요청을 자동으로 고치기(다시 쓰기는 기존 기능 그대로).
  - 메모(기억) 파일을 다시 쓰기 — 이번에는 보고만.

## Approach Overview

- 입구는 기존 것을 다시 쓴다: 세션 기록 폴더 찾기는 실사용 보고(`show-real-report.sh`)와 같은 방식, 사람 턴 가르기는 `lib/show-real.sh` · `lib/choices.sh` 의 자동 알림 판별, 등록 기록(goal · depth · finish 의 msg/ctx)은 세션 기록 속 register 명령에서.
- 목표 도달 = `scv/archive/*/ARCHIVED_AT.md` 의 보관 시각.
- 새 순수 라이브러리 `core/scripts/lib/dreams.sh` + 효과부 `core/scripts/dreams.sh`(입구 읽기 · 판정자 · 출력 쓰기) + 프로토콜 `core/protocols/dreams.md`.
- 자동 발동: `on-session-start.sh`(source = clear · compact)와 `on-user-prompt.sh`(지난 드림 날짜 ≠ 오늘)에서 `dreams.sh --auto` 를 배경으로 띄우고 바로 돌아온다. 한 번에 하나만(잠금 파일).
- 출력: `scv/dreams/<YYYYMMDD-HHMMSS>.html` + `scv/dreams/latest.json`(요약 · 아직 안 알림 표식). 다음 매 턴 훅이 안 알린 요약을 한 줄 싣고 표식을 지운다.
- 래퍼(클로드 · 코덱스)는 릴리스 순서대로 뒤따라 스킬 · 훅 등록 · 판정자 명령 연결(코덱스는 판정자 없음 → 규칙 개선점만).

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readTranscripts,     // 기록 폴더 → 세션 기록 줄들            (입구, 부수효과)
  readArchives,        // archive 폴더 → 보관 시각들            (입구, 부수효과)
  humanTurns,          // 기록 줄들 → 사람 턴[{시각, 세션, 글}]
  registerFeatures,    // 기록 줄들 → 등록[{시각, goal|depth|finish: msg|ctx|na|asked}]
  bucketPeriods,       // 사람 턴 · 보관 시각 · 기간 길이 → 기간[{질의, 보관, 비율}]
  plansDistribution,   // 사람 턴 · 보관 시각 → 계획마다 보관까지 질의 수
  ruleTips,            // 등록 · 기간 · 분포 → 개선점[{규칙, 숫자, 근거 턴 id}]
  pickEvidence,        // 개선점 · 사람 턴 → 근거 발췌(가림 필터 거친 짧은 글)
  judgeAdvice,         // 근거 발췌 · 가이드 규칙 이름 → 조언 글     (부수효과: 판정자 명령)
  renderHtml,          // 모든 결과 → HTML 글(내장 SVG)
  renderSummary,       // 모든 결과 → 한 줄 요약
  writeOutputs,        // HTML · 요약 → scv/dreams/ 파일           (출구, 부수효과)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readTranscripts | 기록 폴더 목록 → jsonl 줄 | 부수효과 (입구) |
| 2 | readArchives | archive 폴더 → 보관 시각 목록 | 부수효과 (입구) |
| 3 | humanTurns | jsonl 줄 → 사람 턴 | 순수 |
| 4 | registerFeatures | jsonl 줄 → 등록 항목 상태 | 순수 |
| 5 | bucketPeriods | 턴 · 보관 · 기간 → 기간 표 | 순수 |
| 6 | plansDistribution | 턴 · 보관 → 분포 | 순수 |
| 7 | ruleTips | 등록 · 기간 · 분포 → 개선점 | 순수 |
| 8 | pickEvidence | 개선점 · 턴 → 가린 발췌 | 순수 |
| 9 | judgeAdvice | 발췌 → 조언 | 부수효과 (판정자) |
| 10 | renderHtml | 결과 → HTML | 순수 |
| 11 | renderSummary | 결과 → 한 줄 | 순수 |
| 12 | writeOutputs | HTML · 요약 → 파일 | 부수효과 (출구) |

- 부수효과 위치: 1 · 2(읽기), 9(판정자), 12(쓰기)와 훅의 배경 띄우기뿐.
- 재사용: 기록 폴더 찾기 · 자동 알림 판별(실사용 보고), 가림 필터(journal-append --redact-only), 판정자 명령(호스트 설정 SCV_JUDGE_COMMAND).

## 성공지표 (Metrics)

| 지표 | 기준선 (확인) | 목표 |
|---|---|---|
| 계획 하나에 사람 질의 수 | 이 저장소 9/21~10/10: 66÷10 = 6.6, 87÷8 = 10.9 | 드림을 켠 뒤 4주 동안 오르지 않음, 보고서에서 추세가 보임 |
| 요청에 완료 기준을 직접 말한 비율 | 등록 292건 중 1% (깊이 4%) | 드림 조언 뒤 4주 동안 오름 |
| 훅 지연 (자동 발동) | 0 | 0.5초 이하 |

효과 지표(위 두 줄)는 드림을 켠 뒤 실사용으로 본다 — 이 계획의 합격 기준은 아니다(TESTS 는 기능 · 안전만).

## 예외처리 (Edge cases)

- 세션 기록이 없거나 보관된 계획이 0개 — 보고서는 '아직 셀 것이 없음'과 지금까지의 질의 수만.
- 기록에 NUL 문자 · 깨진 줄 — 그 줄만 건너뜀(실사용 보고의 NUL 경고를 되풀이하지 않음).
- 드림이 도는 중에 다시 발동 · 프로세스가 죽어 잠금이 남음 — T5.
- 판정자 실패 · 시간 초과 · 깨진 답 · 판정자 없음(코덱스) — T9.
- 하이드레이트 안 된 프로젝트 · jq 없음 — 아무것도 하지 않고 훅은 정상 종료.
- 날짜가 바뀐 채 세션이 이어짐(자정 넘김) — 날짜 바뀜 발동은 첫 사람 메시지에서 한 번.

## Guardrails

- 입력을 쓰지 않는다 — 세션 기록 · archive · 메모 · 대화 기록은 읽기만(invariants).
- 훅은 배경으로 띄우고 바로 돌아온다 — 훅 지연 상한은 TESTS 에. 실패해도 세션 · 훅은 그대로.
- 보고서 · 요약 · 판정자에게 보내는 글에 경로 · 메일 · 비밀값 · 세션 id 를 넣지 않는다(발췌는 가림 필터 + 길이 제한).
- 매 턴 스택 상한(test-help-budget) 안 — 요약 줄은 안 알린 보고가 있을 때만 한 번.
- 규칙 전문은 한 곳(protocols/dreams.md), 다른 곳은 요지.
- Mac + Linux, bash 3.2, jq.
- 진행 중인 계획(no-idle-next-question)과 분기를 섞지 않는다.

## Exit criteria

- All TESTS.md scenarios pass
- 이 컴퓨터의 실제 기록으로 돌린 보고서를 사용자가 보고 '이대로 좋음'을 고른다(T12).

## Suggested path

1. 순수 라이브러리와 단위 테스트(픽스처 기록).
2. 효과부 dreams.sh(직접 실행) + HTML · 요약.
3. 판정자 연결 + 실패 경로.
4. 자동 발동(시작 훅 · 매 턴 훅) + 잠금 + 다음 턴 요약 + 설정 끔.
5. 프로토콜 · 설정 예시 · 문서.
6. 실제 기록으로 돌려 보여 주기.

## Risks / Open Questions

- 사람 질의 수는 압축 · 대화 비움 뒤 이어진 턴도 셈 — 기준은 세션 기록 속 사람 턴(자동 알림 · 도구 결과 제외).
- 프로젝트 하나의 기록만 보면 표본이 작다(이 저장소 한 달에 질의 ~170) — 기간 길이를 기록 양에 맞춘다.
- 판정자를 발동마다 부르면 하루에 여러 번 쓸 수 있다(사용자 선택) — 같은 발췌는 캐시로 다시 묻지 않는다.
- 보고서가 커밋된다(SCV 기록은 모두 커밋) — 발췌 가림이 핵심 안전장치.

## Links

- 근거 대화: scv/conversations/20261021-165832-scv-dreams-prompt-coach.md
- 참고: Managed Agents Dreams 문서(refs)
