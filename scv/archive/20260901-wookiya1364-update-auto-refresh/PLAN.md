---
title: "갱신은 이미 자동이다 — 강요 문구를 걷고, 조용한 갱신을 보이게"
slug: 20260901-wookiya1364-update-auto-refresh
author: "wookiya1364"
created_at: 2026-09-01
status: testing
kind: feature
lang: korean
tags: [hooks, preflight, autosync, update, docs]
raw_sources:
  - scv/conversations/20260901-131508-update-auto-refresh.md
refs: []
invariants:
  - "훅은 어떤 경우에도 세션을 막지 않는다 — 실패해도 exit 0"
  - "갱신할 것이 없으면 아무 줄도 나오지 않는다 — 조용함이 기본값이다"
  - "점검 스크립트의 다른 stderr 는 사용자에게 새지 않는다 — 고른 줄만 싣는다"
  - "scv 폴더가 없는 프로젝트에서는 아무 출력도 없다"
  - "전체 스위치를 끄면 아무 것도 주입하지 않는다"
  - "update 액션은 프로젝트 파일을 건드리지 않는다 — 안에서 sync 를 돌리지 않는다"
scope:
  - "core/template/hooks/on-user-prompt.sh"
  - "VERSION"
  - "core/scripts/lib/force-help.sh"
  - "core/tests/test-autosync.sh"
  - "core/TEMPLATE_DIGEST"
  - "CHANGELOG.md"
---

# 갱신은 이미 자동이다 — 강요 문구를 걷고, 조용한 갱신을 보이게

## Summary

플러그인을 갱신한 뒤 사용자가 매번 sync 를 손으로 친다. 그런데 **자동 갱신은 이미
구현돼 있고 실제로 돈다.** 손으로 치게 만드는 것은 둘이다 — 래퍼 문서 3곳이 코어
규약과 반대로 "sync 를 따로 실행하라"고 시키고, 자동으로 갱신됐다는 **보고가 훅에서
버려져** 아무도 그 사실을 모른다. 문구를 걷고, 보고를 살린다.

## Goals / Non-Goals

- **Goals**
  - 자동 갱신이 실제로 일어난 턴에는 그 결과가 preflight 블록에 한 줄로 보인다.
  - 래퍼 문서 3곳에서 "sync 를 따로 실행하라"를 걷어내고 코어 규약과 일치시킨다.
  - 갱신할 것이 없을 때의 침묵을 그대로 지킨다.
- **Non-Goals**
  - 자동 갱신 로직 자체는 건드리지 않는다. 이미 옳게 돌고 있다.
  - sync 액션을 없애지 않는다 — 손으로 다시 돌리는 길과 2.0 이전 프로젝트의
    대화형 이관 경로로 그대로 남는다.
  - update 액션 안에서 sync 를 부르지 않는다. 그 금지가 이 계획의 전제다.

## Approach Overview

자동 갱신은 `scv_autosync` 가 한다. 액션 스크립트는 `scv_init_paths` 를 통해,
점검 스크립트(`help.sh`)는 시작 줄에서 직접 그것을 부른다. 판단은 배포본의
`TEMPLATE_VERSION`/`TEMPLATE_DIGEST` 와 프로젝트 `SCV.md` 의 도장을 비교하는 순수
함수 하나이고, 다르면 `sync.sh` 를 실제로 실행한다. 번호가 같아도 내용 지문이
다르면 갱신한다 — 0.41.0 이 바로 그 경우였다.

문제는 **보고 경로**다. `scv_autosync` 는 결과를 stderr 로 알리는데(`refreshed` /
`PARTIAL` / `failed`), 프롬프트 훅이 점검 스크립트를 `2>/dev/null` 로 부른다. 갱신은
됐지만 화면에는 아무 것도 안 남는다. 그래서 사용자는 "정말 됐나" 싶어 손으로 한 번
더 친다.

고침은 좁다. 훅에서 점검 스크립트의 stderr 를 **버리지 말고 받아서**, 템플릿 갱신에
관한 줄만 골라 preflight 블록에 싣는다. 고르는 일은 순수 함수 하나로 `force-help.sh`
에 둔다 — 훅 본문은 파일을 읽어 그 함수에 넘기는 바깥층으로 남는다. 다른 stderr 는
버린다: 통째로 쏟으면 훅의 출력 위생이 무너진다.

래퍼 쪽은 문구 교체 3줄이다. 코어 규약(`core/protocols/update.md`)이 이미 정답을
쓰고 있으므로, 래퍼가 그 문장을 따르게만 하면 된다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  readSwitches,        // 설정 파일   → 스위치 값
  routingDirective,    // 스위치      → 지시 블록 문자열
  probeProject,        // 프로젝트    → { 진단 stdout, 보고 stderr }   ← 부수효과
  pickRefreshReport,   // stderr      → 갱신 보고 줄 (없으면 빈 값)     ← 이번에 추가
  trimDiagnosis,       // stdout      → 진단 뒷부분
  emitBlock,           // 조각들      → 훅 출력                        ← 부수효과
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readSwitches | 설정 파일 → 스위치 값 | 부수효과 (입구) |
| 2 | routingDirective | 스위치 → 지시 블록 문자열 | 순수 |
| 3 | probeProject | 프로젝트 경로 → 진단 stdout + 보고 stderr | 부수효과 (갱신이 여기서 일어난다) |
| 4 | pickRefreshReport | stderr → 갱신 보고 줄 (0 또는 1줄) | 순수 |
| 5 | trimDiagnosis | stdout → 개요를 뺀 진단 | 순수 |
| 6 | emitBlock | 지시 + 보고 + 진단 → 훅 출력 | 부수효과 (출구) |

- 부수효과 위치: 1(설정 읽기), 3(점검 실행 = 갱신 발생), 6(출력). 2·4·5 는 순수하다.
- 재사용: 2·5 는 이미 있는 단계를 그대로 쓴다. 새로 만드는 것은 4 하나다.

## Guardrails

- 훅은 실패해도 세션을 막지 않는다. 4단계가 무엇을 하든 종료 코드는 0 이다.
- 고른 줄만 싣는다. 점검 스크립트의 다른 stderr 는 사용자에게 새지 않는다.
- 갱신할 것이 없으면 아무 줄도 내지 않는다. 침묵이 기본값이다.
- 자동 갱신 판단 로직(`scv_autosync`, `scv_template_decide`)은 건드리지 않는다.
- update 액션은 프로젝트 파일을 건드리지 않는다 — 문구만 바꾼다.

## 성공지표 (Metrics)

| 지표 | 지금 (baseline) | 목표 (target) |
|---|---|---|
| 플러그인 갱신 뒤 사용자가 손으로 sync 를 치는 횟수 | 매번 | 0 |
| 갱신이 실제로 일어난 턴에 화면에 남는 증거 | 0줄 | 1줄 |
| 갱신이 필요 없는 턴의 훅 출력 증가분 | 0줄 | 0줄 (유지) |
| 래퍼 문서에 남은 "sync 를 따로 실행하라" | 3곳 | 0곳 |

## 예외처리 (Edge cases)

- **편집 중인 파일이 있어 일부만 갱신됨** — 거부된 파일 이름까지 함께 보고하고,
  도장은 올리지 않는다. 다음 액션이 다시 시도한다.
- **배포본이 프로젝트보다 오래됨** — 되돌리지 않는다. "플러그인을 갱신하라" 한 줄만
  나가고 파일은 그대로다.
- **2.0 이전 프로젝트** — 자동 갱신은 손대지 않는다. 대화형 이관 안내만 나간다.
- **도장이 없거나 손으로 편집된 색인** — 다시 찍으라는 기존 안내를 그대로 쓴다.
- **점검 스크립트가 없거나 실패** — 지시 블록만 나가고 종료 코드는 0 이다.
- **배포본이 불완전(버전 파일 없음)** — 재설치 안내 한 줄. 갱신은 시도하지 않는다.

## Exit criteria

- TESTS.md 시나리오 전부 통과.
- 세 래퍼 문서 어디에도 "sync 를 따로 실행하라"가 남지 않는다.
- 갱신이 일어난 턴에 사용자가 그 사실을 화면에서 읽을 수 있다.

## Suggested path

1. `force-help.sh` 에 stderr 에서 템플릿 갱신 보고 줄만 고르는 순수 함수를 더한다.
2. `on-user-prompt.sh` 에서 점검 스크립트의 stderr 를 버리지 말고 받아, 그 함수에
   넘겨 나온 줄을 지시 블록과 진단 사이에 싣는다.
3. `test-autosync.sh` 에 보임/침묵/누수없음/비차단 검사를 더한다.
4. 래퍼 문구 3곳을 교체한다 — Claude Code 래퍼 1곳, Codex 래퍼 2곳.
5. `TEMPLATE_DIGEST` 재계산, `CHANGELOG.md` 기록.

## Related Documents

- [`FEATURE_ARCHITECTURE.md`](./FEATURE_ARCHITECTURE.md)
- [`TESTS.md`](./TESTS.md)

## Risks / Open Questions

- 훅 출력이 길어지는 것. 갱신은 드문 사건이라 평소에는 한 줄도 늘지 않는다.
- 래퍼 두 곳은 이 저장소 밖이라 코어 검사로 강제할 수 없다. 검사는 래퍼 체크아웃이
  옆에 있을 때만 돌고, 없으면 건너뛴다 — 실패로 세지 않는다.

## Links

- Raw originals: (frontmatter 참조)
- Related PRs:
