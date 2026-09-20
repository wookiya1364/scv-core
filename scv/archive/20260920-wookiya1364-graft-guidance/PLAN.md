---
title: Graft 안내 — 계획·구현 때 먼저 알리고 설치까지
slug: 20260920-wookiya1364-graft-guidance
author: wookiya1364
created_at: 2026-09-20
status: testing
kind: feature
lang: korean
tags: [graft, guidance, promote, work, codegen]
raw_sources:
  - scv/raw/stale/20260920-wookiya1364-graft-guidance.md
refs: []
invariants:
  - "Graft 는 선택 제공자 — 설치하지 않아도 모든 액션의 결과는 지금과 같다 (안내 한 줄만 더해진다)"
  - "SCV 는 graft 를 설치·빌드·훅하지 않는다 (2026-09-17 결정 유지)"
  - "우선순위 서술은 SCV.md Top-level rules 한 곳만 — 새 문장은 rule-constitution 검사 (a)(b) 를 통과한다"
  - "기존 테스트 전부 통과, 맥·리눅스 동일"
scope:
  - core/scripts/lib/graft.sh
  - core/scripts/graft.sh
  - core/scripts/promote-helper.sh
  - core/scripts/work.sh
  - core/scripts/install-deps.sh                  # 설치 명령을 lib 상수로 참조 (계획서에서 빠져 있던 것 — 드리프트 검사가 잡음)
  - core/protocols/promote.md
  - core/protocols/work.md
  - core/protocols/codegen.md
  - core/tests/test-graft-adapter.sh
  - core/tests/fixtures/graft/**
  - CHANGELOG.md
  - VERSION
---

# Graft 안내 — 계획·구현 때 먼저 알리고 설치까지

## Summary

Graft 는 선택 제공자다: 있으면 계획·구현 헤더에 코드 후보와 영향 범위가 붙고, 없으면 `GRAFT_STATUS: absent`
한 줄만 찍히고 끝난다. 그래서 사용자는 Graft 가 있으면 무엇이 좋아지는지, 어떻게 설치하는지 들을 기회가 없다.
이 계획은 **Graft 가 없을 때 계획(promote)·구현(work·codegen)의 첫 출력에 안내 한 줄**을 더한다 — 무엇이
좋아지는지 + 설치 한 줄 명령. 묻지도 막지도 않는다. Graft 가 지원하지 않는 언어만 있는 프로젝트에서는 안내를 내지
않는다(설치해도 빈 결과가 나오면 신뢰를 잃는다). 구현 중 확인: 이 저장소는 bash 만이 아니다 — DeckUI 에 JS/TS 파일이
29개 있어 안내가 나온다(규칙대로). 셸만 있는 프로젝트에서는 침묵한다. 문구는 한 곳(순수 함수)에서 나오고 프로토콜은 그대로
전달만 한다(4조).

## Goals / Non-Goals

- **Goals**
  - `graft.sh status` 가 `GRAFT_STATUS:` 뒤에 `GRAFT_NOTICE:` 한 줄을 낸다 — absent 이고 지원 언어가 있을 때만.
    문구: 무엇이 좋아지는지(코드 후보·영향 범위·변경 지도 대조) + 설치 명령(install-deps 가 이미 찍는 것과 같은 한 줄).
  - promote-helper·work 헬퍼가 그 줄을 헤더에 그대로 실어 내고, promote·work·codegen 프로토콜은 "있으면 그대로
    전달하라" 한 문장만 갖는다. 문구 복제 없음.
  - 지원 언어 판별: 저장소 파일 확장자 분포 → Graft 지원 언어 목록(lib 상수 한 곳)과 대조. 지원 언어 파일이 0개면
    안내 없음. 목록의 초기값은 구현 단계에서 Graft 문서로 확인해 채운다.
  - `ready` / `off` 에서는 안내 없음. `no-graph`(설치됐지만 그래프 없음)는 `graft init` 안내로 — 구현 중 확정.
- **Non-Goals**
  - 설치를 대신 실행하거나, 설치 여부를 묻는 대화. (강제 아님 — 사용자 결정.)
  - deck·regression·status 헤더에 안내 추가 (deck 은 이미 한 줄이 있고 regression 은 blast 로 다른 역할).
  - Graft 자체의 언어 지원 확장.

## Approach Overview

1. **문구는 순수 함수 하나**: `scv_graft_notice <status> <supported_count>` → 한 줄 또는 빈 문자열.
   absent 이고 supported_count > 0 이면 "Graft 가 있으면 계획·구현 헤더에 관련 코드 후보와 영향 범위가 붙습니다 —
   설치: npm i -g @nanonets/graft && graft init --no-hooks --no-statusline && graft telemetry disable". 그 외 빈 값.
2. **지원 언어 판별은 순수 함수 + 얇은 입구**: 입구가 `git ls-files` 로 확장자 목록을 만들고, 순수 함수가 상수
   목록(`SCV_GRAFT_LANG_EXTS`)과 교집합 개수를 낸다. git 이 없거나 저장소가 아니면 0 → 안내 없음(보수적).
3. **graft.sh status** 가 두 줄을 낸다: `GRAFT_STATUS: …` 와 (있을 때만) `GRAFT_NOTICE: …`. promote-helper 와
   work.sh 는 이미 status 를 파싱해 `GRAFT_STATUS` 를 찍는다 — 같은 자리에서 `GRAFT_NOTICE` 도 찍는다.
4. **프로토콜 두 곳**(promote·work)에 한 문장: "헤더에 `GRAFT_NOTICE:` 가 있으면 첫 출력에 그대로 전달한다 — 문구를
   바꾸거나 늘리지 않는다." codegen 은 work 의 Steps 1–5b 를 "verbatim" 으로 따른다고 이미 적혀 있어(재구현 금지) 문장을
   더하지 않는다 — 더하면 4조 위반이다. 구현 중 확정.
5. **install-deps 의 설치 한 줄과 같은 문자열**을 쓴다 — 두 곳에 각각 적지 않고 lib 상수 하나를 둘이 참조한다(4조).
   지금 install-deps.sh 441행에 박힌 문자열을 상수로 끌어올린다.
6. **검사**: test-graft-adapter.sh 에 가짜 graft 와 언어 픽스처(지원 언어 파일 있음/없음)로 네 조합을 고정한다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  list_repo_files,            // 저장소 → 파일 경로 목록                         (효과: git ls-files)
  scv_graft_ext_histogram,    // 경로 목록 → 확장자\t개수 목록                    (순수)
  scv_graft_supported_count,  // 히스토그램 + 지원 확장자 상수 → 지원 파일 수      (순수)
  scv_graft_notice,           // GRAFT_STATUS + 지원 파일 수 → 안내 한 줄 | ""     (순수)
  emit_header_line,           // 한 줄 → 헬퍼 헤더 출력                           (효과: stdout)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | list_repo_files | 작업 디렉터리 → 경로 목록 | 부수효과 (입구, git) |
| 2 | scv_graft_ext_histogram | 경로 목록 → `확장자\t개수` | 순수 |
| 3 | scv_graft_supported_count | 히스토그램 + `SCV_GRAFT_LANG_EXTS` → 정수 | 순수 |
| 4 | scv_graft_notice | status + 정수 → 한 줄 또는 빈 문자열 | 순수 |
| 5 | emit_header_line | 한 줄 → stdout | 부수효과 (출구) |

- 부수효과 위치: 1(git 호출)과 5(출력)만. 2~4 는 문자열만 다룬다.
- 재사용: `lib/graft.sh` 의 `scv_graft_status`(순수) 를 그대로 쓰고 그 뒤에 4 를 붙인다. 설치 명령 문자열은
  install-deps.sh 의 것을 상수로 올려 둘이 공유.

## Guardrails

- **선택 제공자 그대로**: 안내는 한 줄. 질문(AskUserQuestion)도, 설치 실행도, 종료 코드 변화도 없다.
- **문구는 한 곳**: `lib/graft.sh` 의 순수 함수(와 설치 명령 상수)만 문구를 갖는다. 프로토콜·install-deps 는 참조.
  rule-constitution 검사 (b) 기준선이 늘면 실패다 — 새 문장을 두 파일에 적지 않는다.
- **지원 언어 0 이면 침묵**: 판별이 실패하면(git 없음 등) 안내를 내지 않는 쪽으로 기운다.
- **우선순위 문장 금지**: "Graft 가 있으면 더 낫다" 는 사실 안내지 규칙 우선순위가 아니다 — override/우선 같은 어휘를
  쓰지 않는다(검사 (a)).
- **맥·리눅스 동일**: bash + git + awk(표준입력 필터)만. 확장자 추출은 문자열 처리.
- 커밋·푸시는 사용자.

## Exit criteria

- All TESTS.md scenarios pass
- Graft 없는 프로젝트(지원 언어 있음)에서 promote·work·codegen 헬퍼 헤더에 `GRAFT_NOTICE:` 한 줄이 있고, 프로토콜이
  그것을 첫 출력에 전달하라고 적혀 있다.
- 셸만 있는 프로젝트에서는 `GRAFT_NOTICE:` 가 없다 (이 저장소는 DeckUI JS/TS 때문에 안내가 나온다 — 규칙대로).
- 설치 명령 문자열이 저장소에 한 번만 정의되어 있다.
- rule-constitution 검사 (a)(b) 그대로 통과. CHANGELOG 항목, VERSION 상승.

## Suggested path

1. `lib/graft.sh` 에 `SCV_GRAFT_LANG_EXTS`, `SCV_GRAFT_INSTALL_CMD` 상수와 순수 함수 셋(히스토그램·지원 수·안내)을 더한다.
   지원 확장자 초기값은 Graft 문서(README) 를 읽어 채우고 출처를 주석에 적는다.
2. `graft.sh status` 가 `GRAFT_NOTICE:` 를 낸다(입구에서 `git ls-files` 한 번).
3. promote-helper.sh·work.sh 가 그 줄을 헤더에 실어 낸다. install-deps.sh 는 상수를 참조한다.
4. promote·work·codegen 프로토콜에 전달 문장 한 줄.
5. test-graft-adapter.sh 에 네 조합(absent×지원 있음/없음, ready, off) + 문자열 유일성 검사. 기존 검사 전부, run-dry.
6. CHANGELOG, VERSION.

## Related Documents

- `scv/archive/20260917-wookiya1364-graft-adapter/PLAN.md` — 선택 제공자 결정과 status/blast/ask 계약.
- `scv/archive/20260920-wookiya1364-rule-constitution/PLAN.md` — 4조(같은 요구는 한 곳에만)와 검사 (a)(b).

## Risks / Open Questions

- **Graft 지원 언어 목록의 정확성**: 문서로 확인해도 버전마다 바뀔 수 있다. 목록이 낡으면 안내가 과하거나 빠진다 —
  상수 한 곳이므로 갱신은 한 줄.
- **`no-graph` 상태**: graft 는 있는데 `graft/` 가 없는 경우. 설치 안내가 아니라 `graft init` 안내가 맞다 — 구현 중
  문구를 status 별로 나눌지 결정(안내 함수의 분기 하나).
- **이 저장소의 안내**: bash 저장소라 안내가 없을 줄 알았으나 DeckUI 의 JS/TS 29개가 지원 언어로 잡혀 안내가 나온다.
  규칙(지원 파일 1개 이상)대로이고, Graft 가 실제로 DeckUI 코드를 인덱싱할 수 있으므로 거짓 안내는 아니다. 비율
  임계값(예: 전체의 n%)을 둘지는 사용자가 실물을 보고 결정 — 이번엔 두지 않는다.
- 래퍼 사본에서도 도는 검사다 — 호스트 표기·삽입 문장에 걸리지 않게 rule-constitution 의 교훈을 그대로 적용.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
