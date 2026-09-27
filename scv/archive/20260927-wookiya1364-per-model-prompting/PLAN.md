---
title: 모델별 프롬프팅 — help 가 그 모델의 공식 가이드 원문을 보고 요청을 최선의 프롬프트로 다시 쓴다
slug: 20260927-wookiya1364-per-model-prompting
author: wookiya1364
created_at: 2026-09-27
status: testing
kind: feature
lang: korean
tags: [model, prompting, help, socratic, wrapper, codex, metrics, offline]
raw_sources:
  - scv/conversations/20260926-212911-per-model-prompt-overlay.md
refs: []
invariants:
  - "모델을 모르거나 가이드 원문이 없는 모델이면 다시 쓰기·되묻기 없이 지금처럼 답한다"
  - "사용자의 원래 문장은 그대로 남는다 — 다시 쓴 요청은 옆에 보이고 기록된다"
  - "한 턴에 되묻기는 하나, 추천 답을 함께 — 짧은 확인 턴(응·고마워)은 다시 쓰기도 되묻기도 없다"
  - "코어 호스트 중립 검사·help 비용 상한 검사 통과, 맥(bash 3.2)·리눅스 동일"
scope:
  # 코어 — 장치 (모델 이름을 모른다)
  - core/protocols/help.md
  - core/protocols/help/full.md
  - core/protocols/help/prompt-refine.md
  - core/scripts/help.sh
  - core/scripts/lib/help-state.sh
  - core/scripts/lib/model-prompting.sh
  - core/scripts/lib/host-profile.sh
  - core/contracts/host-profile.md
  - core/contracts/host-profile.env.example
  - core/contracts/recording.md
  - core/template/hooks/on-stop.sh
  - core/scripts/lib/metrics.sh
  - core/scripts/metrics.sh
  - core/tests/test-model-prompting.sh
  - core/tests/test-help-budget.sh
  - core/tests/test-metrics.sh
  - core/tests/fixtures/model-prompting/**
  - core/tests/fixtures/metrics/**
  - docs/wrapper-integration.md
  # 클로드 래퍼 — Anthropic 원문과 색인 (후속 PR, ../scv-claude-code)
  #   prompting/INDEX.tsv · prompting/*.md (영문 원문 7) · scripts/refresh-prompting-guides.sh · host-profile.env
  # 코덱스 래퍼 — OpenAI 원문과 색인 (후속 PR, ../scv-codex)
  #   plugins/scv/prompting/INDEX.tsv · plugins/scv/prompting/*.md · tools/refresh-prompting-guides.sh · host-profile.env
---

# 모델별 프롬프팅 — help 가 그 모델의 공식 가이드 원문을 보고 요청을 최선의 프롬프트로 다시 쓴다

## Summary

사용자가 어느 모델을 쓰든, help 가 그 모델의 공식 프롬프팅 가이드 **원문**(SCV 안의 md 사본, 오프라인)을 근거로
사용자 요청을 최선의 프롬프트로 다시 쓰고, 그 다시 쓴 요청으로 같은 모델이 일하게 한다. 다시 쓰는 데 필요한
것이 비어 있고 대화·저장소에서 알아낼 수 없으면 help 는 **소크라테스식으로 묻는다**. 다시 쓴 요청은 사용자에게
보이고 대화 기록에 남는다.

지금 help 의 모양 그대로다(확인): 매 턴 훅은 사용자 문장을 고치지 않고 "help 를 먼저 부르라" 를 덧붙이며, 같은
모델이 help 지침을 읽고 따른다. 이 계획은 그 help 에 "원문 참조 → 다시 쓰기 → 되묻기" 단계를 더한다.

## Goals / Non-Goals

- **Goals**
  - 모델별 가이드 원문을 영문 md 사본으로 **각 SCV 플러그인 안에** 둔다. 머리에 원본 주소 · 가져온 날짜 · 저작권자 표기.
    - 클로드 플러그인: Anthropic 원문 7개(모델 6: Fable 5.1 · Fable 5 · Opus 5.5 · Opus 5 · Opus 4.8 · Sonnet 5, 공통 모범 사례 1).
    - 코덱스 플러그인: OpenAI 원문(GPT-5.6 가이드, Codex 가이드, GPT-5.2 · 5.1 · 5 가이드 — 목록은 구현 때 OpenAI 문서 색인에서 확정).
      OpenAI 문서도 페이지 끝에 `.md` 를 붙이면 원문 마크다운을 준다(확인).
  - help 가 현재 모델을 안다 — 모델이 자기 모델 id(시스템 안내에 있음, 확인)를 help 스크립트에 넘긴다.
  - 모델이 바뀌었거나 세션·압축 뒤 처음이면 help 가 `GUIDE: load <원문 경로들>` 을 내고, 모델이 그 원문을 읽는다.
    같은 모델이면 `GUIDE: loaded`. help 규약을 한 번 읽는 장치(load/loaded)와 같은 모양.
  - **다시 쓰기**: 짧은 확인 턴이 아니면, 모델이 원문의 권고를 근거로 요청을 다시 쓴다 — 무엇을, 끝 조건, 범위,
    멈출 조건, 피할 것 등 원문이 그 모델에 권하는 요소. 다시 쓴 요청을 답 앞에 짧게 보이고 턴 기록에 남긴다.
  - **소크라테스식 되묻기**: 다시 쓴 요청에 원문이 중요하다고 보는 요소가 비었고 대화·저장소에서 알아낼 수 없으면,
    그 빈 곳 하나를 추천 답과 함께 묻는다(한 턴에 하나). 알아낼 수 있으면 묻지 않고 채운 근거를 한 줄 적는다.
  - 원문이 오래되면(기본 90일) `GUIDE:` 줄에 갱신 명령을 붙인다.
  - 멈춤 훅이 저널의 답 기록에 답한 모델을 남기고, 계기판에 "모델별 답 수" 한 줄.
- **Non-Goals**
  - 사용자 문장을 지우거나 대체 — 훅도 help 도 할 수 없다. 다시 쓴 요청은 옆에 둔다.
  - 모델 전환 훅 · 매 턴 훅의 새 줄 — help 가 모델 id 를 받으므로 필요 없다(이전 안에서 뺐다).
  - 사고량(effort) 자동 변경 — 사용자 다이얼. 원문이 권하는 값은 다시 쓴 요청 옆에 권고로만.
  - 원문 요약·번역·편집 — 원문 그대로.
  - help 가 불리지 않는 턴(SCV 액션이 직접 실린 턴, 상시 help off)의 다시 쓰기.

## Approach Overview

**코어는 모델 이름을 모른다.** 코어의 호스트 중립 검사가 제공자·호스트 이름과 opus·sonnet·haiku 같은 모델 이름을
payload 전체에서 막는다(확인). 그래서:

- **각 래퍼**가 자기 제공자의 원문만 싣는다 — 클로드 사용자는 Anthropic 원문만, 코덱스 사용자는 OpenAI 원문만 받는다.
  **클로드 래퍼**(SCV 클로드 플러그인)가 원문 7개와 색인 `prompting/INDEX.tsv`(모델 id → 키 · 파일 · 원본 주소 ·
  가져온 날짜)를 싣고, 호스트 프로필에 `SCV_PROMPTING_GUIDES=<플러그인 기준 폴더>` 한 키를 더한다. 원문 갱신 스크립트도
  래퍼에 있다(원본 주소가 제공자 이름을 담는다). 공식 문서는 페이지마다 `.md` 원문을 준다(확인).
  **코덱스 래퍼**도 같은 형식의 색인 · OpenAI 원문 · 갱신 스크립트 · 같은 프로필 키를 싣는다 — 코어 변경 없음.
  코덱스 모델 id 예: `gpt-5.6-sol`(이 기기 코덱스 설정에서 확인).
- **코어**는 호스트 프로필의 그 키로 색인을 찾아 데이터로만 읽는다: 모델 id 정규화 → 색인에서 정확히 일치 → 이 컨텍스트에서
  이미 읽었는지 → `GUIDE:` 줄. 키가 없으면(코덱스·오래된 래퍼) `GUIDE: none`.

**help 흐름 (한 턴)**:
1. help 스크립트가 `--model <자기 모델 id>` 를 받는다. 이전에 읽은 모델과 다르거나 이 컨텍스트에서 처음이면
   `GUIDE: load <모델 원문> <공통 원문>`, 같으면 `GUIDE: loaded`, 모르면 `GUIDE: none`.
2. `load` 면 모델이 원문을 읽고 `help-state.sh mark-guide` 로 표시한다(표식에 읽은 모델 id 필드 하나).
3. 짧은 확인 턴이 아니면 다시 쓰기: 원문 규칙을 적용해 요청을 다시 쓴다. 비어 있는 핵심 요소를 대화·저장소에서 찾는다.
4. 찾지 못한 빈 곳이 있으면 → 그 하나를 추천 답과 함께 묻고 멈춘다(소크라테스식, 한 턴 하나). 없으면 → 다시 쓴 요청으로 진행.
5. 턴 기록에 `**다시 쓴 요청**:` 한 단락 — 어떤 원문 규칙을 적용했는지 한 줄 포함.

단계 3~5 의 본문은 새 부속 파일 `protocols/help/prompt-refine.md` 에 두고 `full.md` 는 가리키기만 한다 — help 본문의
비용 상한 검사(확인: `test-help-budget.sh`)를 넘지 않게.

**id 매칭은 정확히 일치.** `claude-opus-5` 와 `claude-opus-5-5` 처럼 앞이 같은 id 가 있어 접두어 매칭은 틀린다.
정규화는 소문자 · 앞뒤 공백 제거 · 끝의 `[…]` 표기(예: 1M 컨텍스트) 제거만.

**재설정**: 압축·/clear·재개 때 help 표식이 재설정되면 읽은 모델 필드도 비운다 — 원문이 컨텍스트에서 사라졌을 수 있으니 다시 load.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readInputs,          // [효과] --model 인자 · help 표식 · 호스트 프로필의 색인 · 오늘(주입) → 문자열들
  normalizeModelId,    // 원시 id → 정규화 id ("" 이면 모름)
  lookupGuide,         // (정규화 id, 색인 텍스트) → (키, 모델 원문, 공통 원문, 가져온 날짜) | ""
  guideDecision,       // (가이드 행, 표식의 읽은 모델) → load | loaded | none
  ageDays,             // (가져온 날짜, 오늘) → 경과 일수
  guideLine,           // (결정, 가이드 행, 경과 일수, 기준 일수, 색인 폴더) → "GUIDE: …" 줄
  emit,                // [효과] help 스크립트 출력
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readInputs | 인자 · 표식 파일 · 색인 파일 · 오늘 → 문자열 | 부수효과 (입구) |
| 2 | normalizeModelId | 원시 id → 정규화 id | 순수 |
| 3 | lookupGuide | (id, 색인) → 가이드 행 \| "" | 순수 |
| 4 | guideDecision | (가이드 행, 읽은 모델) → load \| loaded \| none | 순수 |
| 5 | ageDays | (날짜, 오늘) → 정수 | 순수 |
| 6 | guideLine | 결정 · 행 · 일수 → 한 줄 | 순수 |
| 7 | emit | 줄 → stdout | 부수효과 (출구) |

- 다시 쓰기와 되묻기는 스크립트가 아니라 모델이 한다(판단). 스크립트는 "무엇을 읽을지" 만 정한다 — 판단은 모델, 검증은 기계.
- 부수효과 위치: 1 · 7 과 `mark-guide`(표식 쓰기) 뿐. 오늘 날짜는 효과층이 읽어 넘긴다.
- 재사용: 날짜 → 일수는 계기판의 `scv_mx_civil_to_minutes`. 표식 파싱·렌더는 `lib/help-state.sh`(필드 하나 추가).
  멈춤 훅의 대화 기록 리더와 `journal-append.sh`.

## Guardrails

- 코어 payload 에 제공자·호스트·모델 이름을 넣지 않는다 — 코어 픽스처도 중립 id(`vendor-model-a` 등).
- 사용자 원래 문장을 지우거나 바꾸지 않는다. 다시 쓴 요청은 보이고 기록된다 — 숨은 변형 금지.
- 원문은 손대지 않는다 — 머리 표기 외 요약·번역·편집 없음.
- 원문 본문을 매 턴 싣지 않는다 — `load` 인 턴에만 모델이 파일로 읽는다.
- 되묻기는 한 턴에 하나, 추천 답을 함께. 대화·저장소에서 알아낼 수 있는 것은 묻지 않는다(사용자 피로).
- 구현 방법을 캐묻지 않는다 — 되묻기는 목표 · 끝 조건 · 범위 · 멈출 조건 · 피할 것만(promote 되묻기와 같은 규칙).
- 사고량·모델 설정을 바꾸지 않는다.
- help 본문 비용 상한을 넘기지 않는다 — 새 단계 본문은 부속 파일.
- 스위치 `SCV_MODEL_PROMPTING=off` 면 `GUIDE: none` (기본 on).

## Exit criteria

- All TESTS.md scenarios pass
- 래퍼 릴리스 뒤 이 기기에서: 모델을 바꾼 다음 help 턴에 `GUIDE: load` 로 그 모델 원문을 읽고, 다시 쓴 요청이 답 앞에 보이며,
  끝 조건이 없는 요청에는 추천 답과 함께 한 번 묻는다(실측, 대화 기록으로 확인).
- 코어 호스트 중립 · help 비용 상한 · 순수성 · 기존 테스트 전부 초록, 맥·리눅스 CI 초록.
- 계기판에 모델별 답 수가 나온다.

## Suggested path

1. 코어 순수부 `lib/model-prompting.sh` (정규화 · 조회 · 결정 · 경과 일수 · GUIDE 줄) + 전수 검사. help 표식에 읽은 모델 필드.
2. 호스트 프로필 키 `SCV_PROMPTING_GUIDES` (계약 · 예시 · 읽기 · 화이트리스트).
3. `help.sh --model` → `GUIDE:` 줄, `help-state.sh mark-guide`, 재설정 때 필드 비우기.
4. help 규약: `full.md` 에 한 문단(가리키기) + 새 부속 파일 `prompt-refine.md`(다시 쓰기 · 되묻기 · 기록 형식). `help.md` 의 스크립트 호출에 `--model` 한 줄. 기록 계약에 "다시 쓴 요청" 단락.
5. 멈춤 훅 답 기록에 모델 표기 + 계기판 "모델별 답 수".
6. `docs/wrapper-integration.md`: 새 프로필 키와 색인 형식.
7. 코어 릴리스 → 클로드 래퍼 후속 PR: Anthropic 원문 7 · 색인 · 갱신 스크립트 · 프로필 키.
8. 코덱스 래퍼 후속 PR: OpenAI 원문 · 색인 · 갱신 스크립트 · 프로필 키. 코덱스 모델이 자기 id 를 아는지 먼저 확인하고,
   모르면 모델이 코덱스 설정의 `model` 줄을 읽어 넘기도록 코덱스 쪽 help 호출 안내에 한 줄.

## Edge cases (예외처리)

| 조건 | 동작 |
|---|---|
| 프로필 키 없음(오래된 래퍼) · 색인 없음 | `GUIDE: none` — 다시 쓰기 · 되묻기 없이 지금처럼 |
| 모델 id 를 모름(인자 없음) · 색인에 없는 모델 | `GUIDE: none` |
| 색인엔 있는데 원문 파일이 없음 | `GUIDE: none` + 누락 파일 이름 한 줄 |
| 같은 모델, 이미 읽음 | `GUIDE: loaded` |
| 모델이 바뀜 · 압축/clear/재개 뒤 | `GUIDE: load` |
| 원문이 기준 일수(90)보다 오래됨 | `GUIDE:` 줄에 갱신 명령 |
| 짧은 확인 턴(응 · 고마워 · ok) | 다시 쓰기 · 되묻기 없음 |
| 빈 곳이 있지만 대화 · 저장소로 채울 수 있음 | 묻지 않고 채움 + 채운 근거 한 줄 |
| 빈 곳이 여럿 | 가장 결과를 크게 바꾸는 하나만 묻는다 — 나머지는 다음 턴 |
| 사용자가 "그냥 해" 류로 되묻기를 거절 | 추천 답으로 채우고 진행, 그 사실을 기록 |
| 모델 id 끝의 `[…]` 표기 | 정규화에서 떼고 조회 |

## Metrics (성공 지표)

| 지표 | 지금(baseline) | 목표(target) |
|---|---|---|
| 색인에 있는 모델에서 help 가 그 모델 원문을 근거로 다시 쓴 요청을 남기는 비율 | 0% (확인: SCV 가 모델을 모름) | 짧은 확인 턴을 뺀 help 턴 100% |
| 다시 쓴 요청에 원문 규칙 근거 한 줄이 붙는 비율 | 해당 없음 | 100% |
| 계기판에서 모델별 답 수 | 불가 (확인) | 가능 |
| 모델별 품질 비교 | 불가 | 범위 밖 — 쌓인 뒤 후속 |

## Related Documents

- `core/contracts/purity.md`
- `docs/wrapper-integration.md`

## Risks / Open Questions

- **코덱스 모델이 자기 id 를 아는지** 확인하지 못했다 — 모르면 설정 파일의 모델 줄로 대신한다(프로필 · 명령행 덮어쓰기와 다를 수 있음).
- **저작권**: 공식 문서 원문을 공개 저장소(래퍼 둘)에 담는 조건은 확인하지 못했다(Anthropic · OpenAI 모두). 사용자 결정으로 출처 · 날짜 · 저작권자 표기와 함께 담고,
  나중에 빼기 쉽게 한 폴더에 모은다.
- **매 턴 훅이 돌지 않는 설정**(`SCV_ALWAYS_ON`/`SCV_FORCE_HELP` off 등)에서는 세션 전환을 알 방법이 없어, 규약 표식과 마찬가지로
  가이드 읽음 기록도 새 세션에 남을 수 있다. 읽음 기록을 규약 지문에 묶었으므로 규약 표식이 맞는 한 가이드도 맞는다 — 규약보다 나빠지지는 않는다.
- **모델이 자기 id 를 틀리게 넘기면** 엉뚱한 원문을 읽는다 — 피해는 가이드 차이만큼. 멈춤 훅의 대화 기록 모델과 다르면 계기판에 불일치로 보인다.
- **다시 쓰기 비용**: 매 help 턴 짧은 블록 하나가 답에 더해진다 — 답 모양 검사(첫 1~2문장 규칙)와 부딪치지 않게 "다시 쓴 요청" 을 답 앞의
  인용 한 블록으로 두는데, 답 모양 린트가 그것을 첫 문장으로 세는지 구현 중 확인.
- **되묻기 피로**: "빈 곳 하나 · 추천 답 · 알아낼 수 있으면 묻지 않기" 로 줄이지만, 실제 빈도는 실측 전 모른다.
- **공통 모범 사례 원문 크기**가 load 턴 비용을 키운다 — 원문 7개 크기를 T7 에 기록.
- **help 가 안 불리는 턴**에는 다시 쓰기가 없다 — 원문은 컨텍스트에 남아 적용은 이어질 것으로 추정.
- **날짜 접미사가 붙는 모델 id** 는 색인에 그 id 를 그대로 적는다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
