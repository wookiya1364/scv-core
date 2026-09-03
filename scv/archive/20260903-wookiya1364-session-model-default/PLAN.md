---
title: "명령이 세션 모델을 바꾸지 않는다 — 기본은 세션 모델 그대로"
slug: 20260903-wookiya1364-session-model-default
author: "wookiya1364"
created_at: 2026-09-03
status: testing
kind: feature
lang: korean
tags: [model-policy, set-models, wrapper, settings]
raw_sources:
  - scv/conversations/20260903-150216-command-model-override.md
refs: []
invariants:
  - "Codex 래퍼는 바뀌지 않는다 — 모델 지정 줄이 애초에 없다"
  - "opus/haiku 매핑(recommended)은 없애지 않는다 — 원하는 사람이 켜는 선택지로 남는다"
  - "설정 파일의 기존 키·값은 한 글자도 바뀌지 않는다 — 키 하나가 더해질 뿐"
  - "래퍼 sync 가 정책을 다시 적용하는 흐름은 유지된다 — 읽는 자리만 설정 파일로 옮긴다"
scope:
  - "core/template/scv/scv_settings.example.json"
  - "core/scripts/lib/settings.sh"
  - "core/protocols/set-models.md"
  - "core/tests/test-model-policy-default.sh"
  - "core/TEMPLATE_DIGEST"
  - "VERSION"
  - "CHANGELOG.md"
---

# 명령이 세션 모델을 바꾸지 않는다 — 기본은 세션 모델 그대로

## Summary

SCV 명령 파일마다 "이 명령은 Opus 로, 저 명령은 Haiku 로" 가 적혀 있어, 사용자가
Fable 5.1 로 세션을 열어도 SCV 명령이 도는 동안 모델이 바뀐다. 0.43.0 부터 help 가
매 턴 불리므로 **사실상 매 턴 Opus 5 가 답했다** — 사용자의 모델 선택이 무시된 셈이다.
기본을 "세션 모델 그대로" 로 뒤집고, Opus/Haiku 매핑은 원하는 사람이 켜는 선택지로
남긴다. 그리고 그 선택을 저장하는 길이 고장나 있어 함께 고친다.

## Goals / Non-Goals

- **Goals**
  - 새로 설치한 플러그인의 어떤 명령에도 모델 지정 줄이 없다. 세션 모델이 그대로다.
  - 모델 매핑을 켜고 끄는 명령(set-models)이 저장까지 실제로 된다 — 설정 파일에.
  - 래퍼 sync 가 그 설정을 읽어 플러그인 갱신 뒤에도 다시 적용한다.
- **Non-Goals**
  - Opus/Haiku 매핑을 없애지 않는다. 기본에서 선택지로 내려올 뿐이다.
  - Codex 래퍼는 건드리지 않는다. 모델 지정 줄이 없다.
  - 무조건 호출(0.43.0)을 되돌리지 않는다. 이 계획이 그 짝이다.

## Approach Overview

**무엇이 일어나고 있었나 (확인됨).** 래퍼 저장소의 명령 파일 15개 머리말에 `model:`
줄이 있다 — help·promote·work 등 9개는 opus, status·update 등 6개는 haiku. v0.11.5 에
"사용 프로필별 모델" 로 들어갔다. Claude Code 는 그 줄을 보고 명령이 도는 동안 세션
모델을 바꾼다. 0.43.0 이 help 를 매 턴 부르게 하자, 이 줄이 매 턴 발동했다.

**저장이 고장나 있다 (확인됨).** set-models 명령의 3단계는 코어의 `env-set.sh` 로
`.env` 에 정책을 쓰라고 하는데, 그 스크립트는 0.23.0 에서 설정을 scv_settings.json 으로
옮기며 사라졌다. 코어 설정 등록부에 `SCV_MODEL_POLICY` 키도 없다. 래퍼 sync 는 `.env`
의 그 키를 읽어 다시 적용하지만, 그 키를 쓸 길이 없었다. 즉 지금 set-models 는
적용은 되고 저장은 실패한다.

**고치는 방향.** 기본값을 뒤집는다. 플러그인이 사용자의 세션 모델을 조용히 바꾸는
것은, 더 좋은 모델을 고른 사람에겐 다운그레이드다. 명령 파일에서 모델 줄을 걷어내고,
정책 스크립트의 기본을 session-default 로 둔다. recommended(opus/haiku 매핑)는 그대로
선택지로 남는다 — 비용을 아끼려는 사람이 켠다.

저장은 설정 파일로 옮긴다. 코어 등록부에 키를 더하고(기본값 session-default, 설명
포함), set-models 는 코어의 `settings-set.sh` 로 쓰고, 래퍼 sync 는 설정 파일을 먼저
읽고 옛 `.env` 는 호환용으로 뒤에 본다.

**두 저장소에 걸친다.** 키 등록과 규약 문장은 코어, 명령 파일·정책 스크립트·set-models
문서·래퍼 검사는 래퍼. 0.42.0 과 같은 방식으로 간다 — 계획은 여기, 래퍼 파일은 범위에
명시, 래퍼 검사는 옆에 체크아웃이 있을 때만 돌고 없으면 건너뛴다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readPolicy,        // (설정 파일, .env) → 정책 이름 | 없음(=session-default)   ← 부수효과 (입구)
  resolveMapping,    // 정책 이름 → 명령별 모델 | 없음                             ← 순수
  applyToCommands,   // (명령 파일들, 매핑) → 머리말 갱신                          ← 부수효과 (출구)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readPolicy | 설정 파일 → 정책 이름 (없으면 session-default) | 부수효과 (입구) — 설정 파일 먼저, .env 는 호환 |
| 2 | resolveMapping | 정책 이름 → {명령: 모델} 또는 빈 매핑 | 순수 — recommended 표는 그대로 |
| 3 | applyToCommands | 매핑 → 명령 파일 머리말 | 부수효과 (출구) — 빈 매핑이면 줄을 지운다 |

- 부수효과 위치: 1(읽기)·3(쓰기). 2 는 순수하고 이미 있는 `recommended_for` 표를 그대로 쓴다.
- 재사용: 스크립트의 정책 네 가지와 멱등 적용 로직은 그대로. 바뀌는 것은 **기본값**(빈
  매핑)과 **읽는 자리**(설정 파일).

## Guardrails

- 명령 파일의 `model:` 줄 외에는 머리말을 건드리지 않는다.
- recommended·all-opus·all-sonnet·all-haiku 정책의 동작은 바뀌지 않는다.
- 설정 파일의 기존 키·값은 불변. 키 하나가 더해질 뿐.
- Codex 래퍼는 무변경.
- 정책이 잘못된 값이면 지금처럼 오류를 내고 아무 것도 바꾸지 않는다.

## 성공지표 (Metrics)

| 지표 | 지금 (baseline) | 목표 (target) |
|---|---|---|
| 새 설치 플러그인의 모델 지정 줄 | 15개 명령 전부 | 0개 |
| Fable 세션에서 help 가 도는 모델 | Opus 5 (매 턴) | 세션 모델 그대로 |
| set-models 저장 | 실패 (없는 스크립트 호출) | 설정 파일에 저장 |
| sync 의 정책 재적용 | .env 만 읽음 | 설정 파일 먼저, .env 호환 |

## 예외처리 (Edge cases)

- **정책을 켠 사람이 플러그인을 갱신함** — 새 캐시는 줄이 없다. 다음 `/scv:sync` 가
  설정 파일을 읽어 매핑을 다시 붙인다. (자동 갱신은 코어 sync 라 이 단계를 안 거친다 —
  기본이 세션 모델이므로 대부분의 사용자는 영향 없음. 켠 사람만 sync 한 번.)
- **옛 프로젝트에 `.env` 로만 정책이 있음** — 설정 파일에 키가 없으면 `.env` 를 본다.
- **잘못된 정책 값** — 오류 + 무변경. 지금과 같다.
- **Codex 래퍼** — 스크립트도 줄도 없다. 아무 일도 없다.

## Exit criteria

- TESTS.md 시나리오 전부 통과.
- 래퍼 저장소에서 `grep -c '^model:' commands/*.md` 가 전부 0.
- 새 세션에서 help 를 불렀을 때 표시가 세션 모델이다.

## Suggested path

1. 코어: 설정 등록부에 `SCV_MODEL_POLICY`(기본 `session-default`, 설명) 추가. set-models
   규약에 "런타임 기본은 세션 모델" 한 줄.
2. 래퍼: `apply-model-policy.sh --policy session-default` 를 저장소에 돌려 명령 15개의
   줄을 걷어내고 커밋. 스크립트의 `--from-env` 를 "설정 파일 먼저, .env 호환" 으로.
3. 래퍼: set-models 문서 — 첫 선택지 session-default, 저장은 `settings-set.sh`.
4. 래퍼 검사: "model 줄이 있어야" → "기본은 없어야, 정책을 켜면 생겨야".
5. 코어 검사 파일 신설 — 등록부 키 확인 + 래퍼 체크아웃이 있으면 위 항목 확인.
6. 버전·변경기록.

## Related Documents

- [`FEATURE_ARCHITECTURE.md`](./FEATURE_ARCHITECTURE.md)
- [`TESTS.md`](./TESTS.md)

## Risks / Open Questions

- 비용을 이유로 haiku 매핑을 쓰던 사람은 갱신 뒤 세션 모델로 올라간다. 릴리스 노트에
  "켜는 법" 을 적는다.
- 래퍼 검사가 정책 없는 상태를 기본으로 보게 되므로, 기존 회귀 계약 중 "model 줄 있음"
  을 잠근 것이 있으면 그것을 대체 선언해야 한다 — 구현 중 확인.

## Links

- Raw originals: (frontmatter 참조)
- Related PRs:
