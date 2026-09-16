---
title: "규약 지문 메아리 — 잊었는지 묻지 않고, 지문과 답 모양으로 잡아 다시 싣는다"
slug: 20260916-wookiya1364-help-protocol-echo
author: "wookiya1364"
created_at: 2026-09-16
status: testing
kind: feature
epic: 20260914-help-turn-cost
lang: korean
tags: [help, protocol, nonce, checksum, stop-hook, answer-shape, lint, drift]
raw_sources:
  - scv/raw/stale/20260916-wookiya1364-protocol-echo-idea.md
  - scv/conversations/20260914-092553-install-check-0-47-0.md
refs: []
invariants:
  - "훅은 scv/journal/ 밖에 아무것도 쓰지 않고 실패하면 exit 0 (이전 동작으로)"
  - "다시 읽을지의 판단은 모델이 아니라 훅 상태로 — 지문 부재·모양 위반은 표식 protocol=0 으로만 작용한다"
  - "지문은 규약을 실제로 읽은 컨텍스트에만 존재한다 — 라우터(매 턴 본문)에는 절대 적지 않는다"
  - "답 모양 린트는 경고와 재읽기만 한다 — 답을 막거나 고치지 않는다 (Stop 훅은 non-blocking)"
  - "0.49.0 의 표식 형식과 호환 — 필드를 더하되 옛 표식도 파싱된다"
scope:
  - "core/scripts/lib/help-state.sh (nonce 필드 · echo 판정 · 모양 린트 순수부)"
  - "core/scripts/help-state.sh (mark 가 nonce 생성 · echo/lint 하위 명령)"
  - "core/scripts/help.sh (--with-context 의 PROTOCOL 줄에 nonce 를 실어 주지 않는다 — full.md 를 읽을 때만 보이도록 help-state.sh 가 별도 파일로 노출)"
  - "core/protocols/help/full.md (끝에 '이 세션의 규약 지문: <nonce 파일을 읽어라>' 지시) · core/protocols/help.md (append 형식에 지문 줄 한 개)"
  - "core/template/hooks/on-stop.sh (직전 턴 append 의 지문 검사 · 답 모양 린트 → 위반 시 protocol=0 + 다음 턴 경고 줄 예약)"
  - "core/template/hooks/on-user-prompt.sh (예약된 경고 줄 출력)"
  - "core/tests/test-help-echo.sh (신설) · test-help-load-once.sh · test-journal.sh (예외)"
  - "core/template/scv/scv_settings.example.json (SCV_HELP_ECHO on|off · SCV_ANSWER_LINT on|off)"
  - "CHANGELOG.md"
---

# 규약 지문 메아리 — 잊었는지 묻지 않고, 지문과 답 모양으로 잡아 다시 싣는다

## Summary

0.49.0 은 규약을 세션당 한 번만 읽는다. 남은 위험은 "읽었지만 흐릿해진" 상태인데, 모델의 주의는
잴 수 없다. 대신 행동 체크섬 둘을 둔다. (1) **지문 메아리**: 규약 전체를 읽을 때 훅이 만든 무작위
지문이 규약을 읽은 컨텍스트에만 있고, 모델은 매 턴 대화 기록에 그 지문을 적는다. 못 적으면 규약이
컨텍스트에서 빠진 것 — 종료 훅이 감지해 다음 턴에 강제 재읽기. (2) **답 모양 린트**: 종료 훅이
직전 답의 골격을 세어 계약을 벗어나면 다음 턴에 경고 한 줄 + 재읽기. 둘 다 모델에게 "기억하느냐"
묻지 않고 결과로 판정한다 — 통신의 체크섬과 재전송 요청, 영상 압축의 참조 프레임 검사와 같다.

## Goals / Non-Goals

- **Goals**
  - `help-state.sh mark` 가 8자리 지문을 만들어 표식(`nonce`)과 `scv/journal/.help-nonce`(한 줄)에 쓴다.
    full.md 끝의 지시가 그 파일을 읽게 하므로 지문은 규약을 읽은 턴의 컨텍스트에만 있다.
  - 라우터의 append 형식에 `protocol: <지문>` 한 줄. 종료 훅이 이번 턴 append 의 지문을 표식과 비교 —
    다르거나 없으면 protocol=0 + 다음 턴 경고("규약 지문이 없다 — 다시 싣는다"). 자기 회복 루프.
  - 답 모양 린트(순수 함수): 답 본문 → 위반 목록. 규칙은 골격만: 첫 문단 ≤ 2문장(설정 상한) · 표/목록
    앞에 결론 문단 존재 · `| # |` 결정표엔 세 번째 열(추천) 비어 있지 않음 · 코드값이 첫 문단에 없음.
    위반 시 다음 턴 경고 한 줄 + protocol=0. 답을 막지 않는다.
  - 두 스위치(기본 on). 관찰용 집계: 종료 훅이 `scv/journal/.help-drift`(ignore) 에 턴별 결과 한 줄
    (지문 OK/없음 · 린트 위반 수)을 남겨, 세션 뒤 "흐려진 턴" 수를 셀 수 있다 — 이것이 기존 계획의
    "기록 누락 감사"를 대체한다.
- **Non-Goals**
  - 모델 주의의 직접 측정 · 규약 암기 검사 · 답 내용의 품질 판정(골격만 본다).
  - 라우터에 지문을 싣는 것(그러면 메아리가 무의미).
  - Stop 훅으로 답을 차단·수정하는 것.

## Approach Overview

**확인된 사실 (0.49.0 기준).** 표식 `scv/journal/.help-state` 한 줄 JSON(session·protocol·turn·diag·diag_at),
순수부 `lib/help-state.sh`(parse·render 는 필드 추가에 열려 있다 — 없는 필드는 기본값). Stop 훅
`on-stop.sh` 는 저널 캡처만 하고 실패 시 exit 0, 쓰기는 scv/journal/ 안. 매 턴 훅은 진단 앞에 지시
블록을 찍는다 — 경고 줄을 여기에 얹는다. `journal-append.sh --speaker user` 가 저널 한 파일에
사용자 턴을 남기고, Stop 훅은 어시스턴트 출력을 남긴다 — Stop 훅의 stdin 에 마지막 어시스턴트
메시지가 온다(0.22 계획에서 확인).

**지문의 수명.** mark 때 생성, reset·세션 전환 때 비움. 매 턴 훅이 protocol=0 이면 그 턴의 메아리
검사는 건너뛴다(읽기 전이니 지문이 없는 게 정상). 종료 훅은 "이번 턴 append 에 `protocol: <지문>`
줄이 있고 표식과 같다" 를 본다 — 대화 파일 마지막 Turn 블록에서.

**모양 린트의 규칙은 순수 함수에, 문구는 규약에.** `scv_answer_lint <본문> <문장상한>` → 위반 줄들.
문장 수 세기는 마침표·물음표·느낌표 기준(한국어 "다." "요." 포함), 코드값은 백틱 안 경로·버전·
설정 키 패턴. 위반 문구는 다음 턴 훅이 "[SCV 답 모양] 직전 답: <위반> — 규약을 다시 싣는다" 로 출력.

**압축 유비를 문서에 남긴다.** full.md = I-프레임, 라우터 = P-프레임, RELOAD_EVERY = GOP, 진단 해시 =
변화 없는 블록 생략, 지문 메아리 = 체크섬/재전송. 사람이 구조를 한 문장으로 이해하는 그림.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readTurn,        // Stop 훅 stdin + 대화 파일 마지막 Turn → {answer, appended_nonce}     (입구)
  echoCheck,       // {appended_nonce, state.nonce, state.protocol} → ok | missing | mismatch | skip
  answerLint,      // answer + 문장상한 → 위반 목록
  decideReload,    // {echo, violations, switches} → {protocol', warning_line}
  renderState,     // state' → JSON
  writeState,      // JSON → 표식 · 드리프트 로그 한 줄                                     (출구)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readTurn | stdin·파일 → 답 본문, append 의 지문 | 부수효과 (입구) |
| 2 | echoCheck (`scv_echo_check`) | 지문 셋 + protocol → ok/missing/mismatch/skip | 순수 |
| 3 | answerLint (`scv_answer_lint`) | 본문 + 상한 → 위반 줄들 | 순수 |
| 4 | decideReload (`scv_drift_decide`) | echo·위반·스위치 → protocol'·경고 줄 | 순수 |
| 5 | renderState | 상태 → JSON | 순수 |
| 6 | writeState | JSON → 표식·드리프트 로그 | 부수효과 (출구) |

- 지문 생성(`mark`)은 효과부: `head -c 6 /dev/urandom | od` 류 — 무작위는 순수부 밖.
- 재사용: 0.49.0 의 parse/render/reload 그대로, 필드만 `nonce` 추가.

## Guardrails

- 지문은 라우터·훅 출력·PROTOCOL 줄 어디에도 싣지 않는다 — `.help-nonce` 파일을 full.md 지시로 읽을 때만.
- Stop 훅은 답을 막지 않는다. 실패는 exit 0.
- 스위치 off 면 0.49.0 과 바이트 단위 동일 동작.
- 표식 형식은 뒤로 호환(0.49.0 표식을 읽어도 nonce="" 로 정상).

## Exit criteria

- All TESTS.md scenarios pass
- 10턴 시뮬레이션: 지문을 적은 턴은 loaded 유지, 지문을 뺀 턴 다음엔 load + 경고, 모양 위반 답 다음엔 경고.
- 릴리스 뒤 세 세션에서 드리프트 로그의 "흐려진 턴" 수를 기록 — 이후 재읽기 간격 조정의 근거.

## Suggested path

1. 순수부 넷 + `test-help-echo.sh` (Red).
2. `mark` 의 지문 생성·파일 노출, full.md 끝 지시, 라우터 append 형식 한 줄.
3. Stop 훅: append 지문 검사 + 린트 + 표식·드리프트 로그; 매 턴 훅: 경고 줄.
4. 스위치 둘 문서화, 저널 검사 예외(.help-nonce · .help-drift), 10턴 시뮬레이션.
5. CHANGELOG, 압축 유비 그림.

## 성공지표 (Metrics)

| 지표 | baseline (0.49.0) | target |
|---|---|---|
| 규약이 컨텍스트에서 빠진 뒤 다시 실리기까지 | 최대 10턴(주기) | 다음 턴 (지문 부재 감지) |
| 답 모양 계약 위반이 방치되는 턴 | 관찰 불가 | 다음 턴 경고 + 재읽기 |
| 매 턴 추가 비용 | 0 | 지문 줄 ≈ 10 토큰, 훅 린트는 모델 비용 0 |
| 세션 뒤 "흐려진 턴" 수 | 못 셈 | 드리프트 로그로 셈 |

## 예외처리 (Edge cases)

- protocol=0 인 턴(읽기 전) → 메아리 검사 skip.
- 대화 파일이 없는 턴(진단 모드) → 메아리 검사 skip, 린트만.
- Stop 훅 stdin 에 답이 없거나 JSON 이 아님 → 아무것도 쓰지 않고 exit 0.
- 지문 파일이 없어진 경우 → 다음 mark 에서 재생성; 그 사이 메아리는 skip.
- 사용자가 스위치를 끈 경우 → 표식의 nonce 무시, 린트 없음.

## Related Documents

- `scv/archive/20260914-wookiya1364-help-load-once/PLAN.md` — 표식·훅 구조(0.49.0)
- `scv/archive/20260903-wookiya1364-help-answer-shape/PLAN.md` — 답 모양 계약(린트 규칙의 원천)

## Risks / Open Questions

- 모델이 지문을 적는 걸 잊는 것 자체가 "흐려짐"의 신호 — 그래서 감지가 곧 판정이고, 오탐은 재읽기 한 번의
  비용뿐이다. 다만 짧은 턴(맞장구)도 append 하므로 지문은 모든 턴에 요구한다.
- 린트의 문장 세기는 근사 — 코드 블록·표를 제외하고 첫 문단만 본다. 오탐이 잦으면 상한을 3 으로.
- Stop 훅이 대화 파일의 마지막 Turn 을 찾는 방식은 append 형식에 의존 — 형식이 바뀌면 같이 바뀐다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
