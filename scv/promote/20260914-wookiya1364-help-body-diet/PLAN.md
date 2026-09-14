---
title: "help 매 턴 비용 다이어트 — 17k 토큰을 6~7k 로, 동작은 검사가 지킨다"
slug: 20260914-wookiya1364-help-body-diet
author: "wookiya1364"
created_at: 2026-09-14
status: planned
kind: refactor
epic: 20260914-help-turn-cost
lang: korean
tags: [help, protocol, token-budget, progressive-disclosure, skills, tests]
raw_sources:
  - scv/conversations/20260914-092553-install-check-0-47-0.md
  - scv/raw/stale/20260914-wookiya1364-help-body-diet.md
  - scv/raw/stale/20260914-wookiya1364-skill-cost-measurement.md
refs: []
invariants:
  - "help 본문을 읽는 기존 검사 여섯(test-force-help · test-help-shape · test-delegate-effort · test-guidance · test-profile-and-export · test-host-runtime-materialization)과 run-dry 의 help 단언이 전부 통과한다 — 앵커 문장은 지우지 않고, 옮긴 앵커는 검사의 대상을 '본문+부속 파일'로 바꿔 준다"
  - "쉬운 말 절(## Plain language first)은 바이트 단위로 그대로다 — 열세 규약이 한 문구를 공유하고 test-help-shape T7 이 HEAD 와 비교한다"
  - "답 모양 절(## Answer shape)은 그대로다 — 그 절이 help 의 계약이고 test-help-shape 가 문장 단위로 본다"
  - "세 모드(진단·대화·archive 검색)와 짧은 턴 이어붙이기, '기록 없이 돌려보내지 않는다' 규칙의 동작은 이전과 같다"
  - "본문은 호스트 중립이다 — 부속 파일 경로도 ${SCV_CORE_ROOT} 자리표시자만 쓰고, 호스트 이름·effort 단계 이름은 어디에도 적지 않는다"
  - "래퍼(scv-claude-code · scv-codex)는 무변경 — 투영 검사(project-core.sh --check)가 그대로 통과한다"
scope:
  - "core/protocols/help.md (본문 다이어트 + 분기 자리에 '지금 읽어라' 포인터 + archive 목록은 --archive-index 로)"
  - "core/scripts/help.sh (--with-context 는 파싱 머리만 · --archive-index 신설 · 인자 없음/위치 인자 형태는 그대로)"
  - "core/protocols/help/language-setup.md · legacy-migration.md · hydrate.md · archive-search.md · promote-handoff.md (신설, 분기 본문)"
  - "tools/verify-core.sh (규약 파일 수 세기를 최상위로 한정)"
  - "core/tests/run-dry.sh (옮긴 앵커의 대상을 본문+부속 파일로)"
  - "core/tests/test-help-budget.sh (신설 — 본문 상한·부속 파일 참조 검사)"
  - "core/tests/test-delegate-effort.sh (위임 절이 포인터로 줄어도 통과하는지 확인, 필요 시 최소 수정)"
  - "docs/wrapper-integration.md (protocols/ 하위 폴더는 액션이 아니라는 규칙 한 줄)"
  - "VERSION · CHANGELOG.md (0.48.0 — 전후 실측 포함)"
---

# help 매 턴 비용 다이어트 — 17k 토큰을 6~7k 로, 동작은 검사가 지킨다

## Summary

help 는 매 턴 강제로 불리는 액션인데 본문이 28KB(호출당 약 11k 토큰)다. 그중 절반은 그
턴에 쓰이지 않는 분기(hydrate 제안 · 언어 첫 설정 · 옛 대화 이사 · archive 검색 · promote
넘김)이고, 조사 위임 절은 매 턴 훅이 이미 같은 규칙을 싣는다. 분기 본문을 규약 하위 폴더의
부속 파일로 빼서 그 분기에 들어갈 때만 읽게 하고, 중복 절은 포인터로 줄이고, 남는 설명문은
원칙만 남기고 압축한다. 동작은 바꾸지 않는다 — 그것을 기존 검사 여섯과 새 상한 검사가
지킨다. 래퍼는 손대지 않는다.

재검토(2026-09-14, 대표님 요청)에서 매 턴 실리는 것 전부를 재 보니 본문은 3분의 2였다. 보조
스크립트가 대화 모드에서도 배너와 프로젝트 진단(훅이 이미 매 턴 싣는 것과 같은 내용)을 찍고,
archive 목록 48줄을 매 턴 찍는다. 둘을 같이 걷는다 — 대화 모드 출력은 파싱 머리만, archive
목록은 별도 플래그로 archive 검색 분기에서만. 매 턴 약 44.5KB(≈17k 토큰) → 약 18KB(≈6.5k).

## Goals / Non-Goals

- **Goals**
  - `core/protocols/help.md` 본문이 14,000 바이트 이하(약 5.3k 토큰)가 되고, 그 상한을 코어
    검사가 지킨다. 목표치는 13,000 바이트 안팎.
  - 분기 다섯의 본문이 `core/protocols/help/<name>.md` 다섯 파일로 옮겨지고, help.md 의 그
    자리에는 앵커 제목 + 한두 줄 + "지금 `${SCV_CORE_ROOT}/protocols/help/<name>.md` 를 읽고
    따르라" 만 남는다.
  - 부속 파일이 내보내기 → 벤더링 → 래퍼 투영 → 플러그인 캐시까지 **기존 경로로** 실려가고,
    `${SCV_CORE_ROOT}` 치환도 받는다 (래퍼 변경 없이).
  - 옮겨진 앵커를 보는 run-dry 단언은 '본문 + 부속 파일' 을 대상으로 바뀌고, 나머지 검사는
    수정 없이 통과한다.
  - 보조 스크립트의 `--with-context` 출력이 파싱 머리(ARG_CONTEXT · UNFINISHED · LEGACY)만이고,
    archive 목록은 새 `--archive-index` 플래그로만 나온다. 인자 없음(진단) · 위치 인자(옛 형태)
    출력은 바이트 단위로 그대로다.
  - 매 턴 스택(훅 주입 + help 본문 + 보조 스크립트 대화 모드 출력)이 18,000 바이트 이하이고,
    그 합을 새 검사가 잰다.
  - 릴리스 후 `claude plugin details` 로 help 의 on-invoke 값을 다시 재서 CHANGELOG 에 전후를
    적는다.
- **Non-Goals**
  - 쉬운 말 절 · 답 모양 절의 문구 변경 — 둘은 계약이고 검사가 문장 단위로 본다.
  - 다른 열네 규약의 다이어트 — promote(69KB) · work(44KB) 는 호출당 비용이라 별도 계획.
  - 매 턴 훅(on-user-prompt.sh)이 싣는 preflight 문구 변경. 진단 블록 압축(통과한 의존성 줄
    생략, 약 2KB)은 매 턴 진단 주입이 사용자 결정 영역이라 **후속 계획**으로 남긴다.
  - 대화 루프(B0~B2)까지 부속 파일로 빼는 라우터 방식 — 보통 턴마다 읽기 호출이 늘어 기각.
  - 스킬 설명(description) 문구 변경 — 0.47.0 검사 상한 안이다.
  - 래퍼 스크립트(project-core.sh · sync-core.sh) 변경 — 필요 없음이 확인됐다(아래).

## Approach Overview

**확인된 사실 (2026-09-14, 코어 develop + 옆 체크아웃 scv-claude-code · scv-codex).**
- 실측: `claude plugin details scv@scv-claude-code` — 상시 ~2,327 tok, help on-invoke ~11.1k,
  promote ~26.2k, work ~16.7k. 세션 `/skill-doctor` 는 빈 출력이라 CLI 로 쟀다.
- help.md 28,121 바이트. 절별 크기(바이트): 언어 첫 설정 1,803 · 옛 대화 이사 1,250 · hydrate
  A0+A1 3,746 · archive 검색 분기 1,314 · promote 넘김 B3~B6 3,266 (합 11,379, 분기 전용) ·
  조사 위임 1,465 (훅과 중복) · 쉬운 말 1,207 (계약, 불변) · 답 모양 2,672 (계약, 불변).
- 매 턴 훅 `core/template/hooks/on-user-prompt.sh` 는 쉬운 말 블록을 SCV_PLAIN_LANGUAGE 만
  보고 매 턴 싣고(7~21행), 위임 블록은 SCV_DELEGATE_EFFORT=on 일 때 싣는다(96~115행).
- **부속 파일이 실려가는 길 (래퍼 무변경의 근거).**
  `tools/export-core.sh` 는 `core/` 를 통째로 복사한다(52행). `tools/materialize-profile.sh` 는
  `find "$CORE_ROOT" ... -name '*.md'` 로 재귀 수집해 `SCV_CORE_ROOT` 를 perl 로 치환하고
  (57~112행), 규약 후처리도 `find "$CORE_ROOT/protocols" -type f -name '*.md'` 로 재귀다
  (120~140행). 래퍼 `scripts/project-core.sh` 는 `protocols/` 트리를 `diff -qr` 로 통째 비교·교체
  하고(338 · 464행), 스킬 본문 생성 루프는 `protocols/*.md` 최상위 파일만 돈다(513행) — 하위
  폴더 파일은 새 액션으로 오인되지 않는다. 플러그인 캐시 루트에 `protocols/` 가 실제로 있다
  (`~/.claude/plugins/cache/scv-claude-code/scv/0.47.0/protocols/help.md`). Codex 래퍼는
  `SCV_CORE_ROOT="$SCV_CORE_VENDOR/core"` 로 벤더 코어를 직접 읽으므로(references/codex-runtime.md
  15행) `${SCV_CORE_ROOT}/protocols/help/<name>.md` 가 양쪽에서 같은 파일을 가리킨다.
- **매 턴 스택 실측 (바이트).** 훅 주입 4,873(지시 1,153 · 진단 3,266) + help 본문 29,292 + 보조
  스크립트 `--with-context` 출력 10,293(파싱 머리 4,635 — 그중 archive 목록 48줄 ≈ 4,200 · 배너와
  진단 5,875) = 약 44,500 ≈ 17k 토큰. `core/scripts/help.sh` 는 42~155행에서 파싱 머리를 찍고
  157행부터 배너·진단을 항상 찍는다. 이 출력 내용을 단언하는 검사는 인자 없음 형태(run-dry 2279)와
  위치 인자 형태(run-dry 713 `help.sh "search refund"` 의 ARCHIVE_INDEX · test-host-runtime-
  materialization 69)뿐이고, `--with-context` 출력은 `ARG_CONTEXT: provided` 한 줄만 본다(같은
  파일 130~134행). 훅의 진단 블록은 `help.sh` 인자 없음 출력을 `scv_force_trim_diagnosis` 로 잘라
  넣는다(on-user-prompt.sh 121~138행) — 즉 대화 모드의 진단은 순수 중복이다.
- **걸리는 곳 셋 (코어 안).** `tools/verify-core.sh:76` 이 `find core/protocols -type f -name
  '*.md'` 로 규약 수를 세어 15 를 요구한다 — 재귀라 부속 파일이 수를 깨뜨린다.
  `core/tests/run-dry.sh` 가 help 본문에 앵커 문장 서른 개쯤을 단언한다(2109~2113 · 3256~3265 ·
  3298~3301 · 3331~3333 · 3836~3837 등) — 그중 열 개(언어 질문 넷 · promote 선택지 셋 · ARCHIVE_INDEX · hydrate.sh · 이사 질문)가 옮겨질 본문 안에 있다.
  `core/tests/test-delegate-effort.sh:147` 은 위임 절이 `## Answer shape` 앞에 있고 비어 있지
  않기만 본다(그리고 "never changes that dial" 문장, effort 단계 이름 부재).
- **지워선 안 되는 것.** run-dry [15p] 는 열세 규약의 쉬운 말 절이 한 문구임을 md5 로 본다;
  test-help-shape T7 은 help 의 쉬운 말 절을 HEAD 와 바이트 비교한다. test-guidance 160행은
  materialize(minimal) 결과의 help.md 에 `action:promote` 호스트 토큰이 있어야 한다 —
  B3~B4 가 옮겨지면 본문에 한 군데는 남겨야 한다. test-profile-and-export 36~37행은 벤더
  help.md 의 `$scv:help` · `$ARGUMENTS` 를 본다(머리말 절, 그대로).

**다섯 손질, 한 PR.** 본문 셋(1~3)과 보조 스크립트 둘(4~5).

1. **훅과 중복인 절을 포인터로.** 조사 위임 절(1,465B)을 제목은 그대로 두고 4줄로 줄인다:
   스위치가 on 이면 매 턴 훅의 `[SCV delegate]` 블록이 이 턴에도 그대로 적용된다 · SCV 는
   세션 다이얼을 바꾸지 않는다("never changes that dial" 유지) · 깊은 질문만 배경으로 · 얕은
   질문은 위임하지 않는다. 쉬운 말 절은 손대지 않는다(계약).
2. **설명문 압축.** 원칙 문장과 검사 앵커는 남기고 근거 서술만 줄인다 — "기록 없이 돌려보내지
   않는다"(1,061B → 앵커 세 문장 + 규칙), 세 모드 소개, 의도 분류 표, B0~B2, 스크립트 실행,
   대화 저장, 마무리. 압축 뒤에도 test-force-help T18·T19 앵커 일곱 문장은 그대로 남는다.
3. **분기 본문을 부속 파일로.** `core/protocols/help/` 아래 다섯 파일:
   `language-setup.md`(언어 첫 설정 질문·저장) · `legacy-migration.md`(옛 대화 이사 질문·수행) ·
   `hydrate.md`(A0 hydrate 제안 + A1 진단 재표시·codegen 언급·워크스페이스) ·
   `archive-search.md`(B' 다섯 단계) · `promote-handoff.md`(B3 질문 + B4~B6 처리).
   help.md 의 각 자리는 **앵커 제목 그대로** + 진입 조건 한 줄 + "Read
   `${SCV_CORE_ROOT}/protocols/help/<name>.md` now and follow it" 한 줄. 부속 파일은 머리에
   "help.md 의 어느 분기에서 읽히는가" 한 줄과 돌아갈 자리를 적고, 쉬운 말 절·언어 절을 다시
   싣지 않는다(run-dry [15p] 의 규약 목록은 최상위 glob 이라 부속 파일은 세지 않지만, 검사로
   못 박는다).

4. **대화 모드 출력은 파싱 머리만.** `help.sh --with-context` 는 `ARG_CONTEXT · UNFINISHED_
   CONVERSATIONS · LEGACY_CONVERSATIONS` 를 찍고 끝난다(157행 앞에서 exit 0). 인자 없음(진단
   모드)과 위치 인자(옛 형태, `help.sh "search refund"`)는 지금 출력 그대로 — 기존 검사가 그
   둘을 보고, 옛 형태는 계약을 깨지 않으려 남긴다.
5. **archive 목록은 요청할 때만.** 새 플래그 `help.sh --archive-index` 가 파싱 머리 + `ARCHIVE_INDEX:`
   블록만 찍는다. 규약의 파싱 목록에서 ARCHIVE_INDEX 줄을 빼고, archive 검색 부속 파일
   (`archive-search.md`) 1단계를 "먼저 `--archive-index` 를 돌려 목록을 받아라"로 바꾼다. 목록은
   archive 가 늘수록 커지는 항목(지금 48줄)이라 이 손질의 절감은 시간이 갈수록 커진다.

**검사는 이렇게 따라간다.** `verify-core.sh` 의 수 세기에 `-maxdepth 1`. run-dry 에
`HELP_ALL="$(cat "$HELP_CMD" "$PROTOCOL_ROOT"/help/*.md)"` 를 두고 옮겨진 열 앵커만 그
대상으로 바꾼다(제목 앵커 — "Step A0 — Auto-hydrate on first run", "Mode B' — Archive Search
…", "Step B3", "First-time language setup" — 는 본문에 남으므로 그대로). 새
`test-help-budget.sh` 가 본문 상한(14,000B) · 부속 파일 다섯의 존재와 help.md 에서의 정확히
한 번 참조 · 부속 파일에 쉬운 말/언어 절 부재 · 전체 합(본문+부속) 30,000B 이하(내용 폭증 방지)
를 본다. 호스트 중립은 기존 test-host-neutral 이 저장소 전체를 보므로 부속 파일도 걸린다.
같은 검사가 보조 스크립트 세 형태(인자 없음 · `--with-context` · `--archive-index`)의 출력을 돌려
대화 모드에 배너·진단·archive 목록이 없고, archive 플래그에 목록이 있고, 인자 없음 출력이 여전히
진단을 품는지 본다. 그리고 매 턴 스택 합(훅 출력 + help.md + `--with-context` 출력)이 18,000
바이트 이하인지 잰다 — 이 숫자가 이 계획의 성적표다.

**실측을 남긴다.** 릴리스·설치 후 `claude plugin details scv@scv-claude-code` 를 다시 돌려
help on-invoke 전후(11.1k → 목표 5.5k 이하)를 CHANGELOG 0.48.0 에 적는다. 부속 파일을 읽는
분기는 그 턴에 파일 크기만큼 더 쓰므로, "매 턴 절감 × 대부분의 턴" 대 "분기 턴 +1 도구 호출"
의 맞바꿈임을 같이 적는다.

## 순수함수 · 파이프라인 (Pure functions & pipeline)

두 파이프라인이 있다. 하나는 새 검사, 하나는 이미 있는 배송 경로(단계는 그대로, 입력만 는다).

```
flow(
  readProtocol,      // 경로 → 본문 문자열                                   (입구: 파일 읽기)
  splitSections,     // 본문 → [{heading, bytes}]
  measureBudget,     // [{heading, bytes}] + 상한 → 위반 목록 (본문 상한 · 합계 상한)
  collectRefs,       // 본문 → [부속 파일 이름] (${SCV_CORE_ROOT}/protocols/help/<name>.md 패턴)
  checkRefs,         // [이름] + 실제 파일 목록 → 위반 목록 (없는 참조 · 참조 안 된 파일 · 중복 참조)
  checkNoDuplicateRules, // 부속 파일 본문 → 위반 목록 (쉬운 말 절 · 언어 절이 있으면)
  report,            // 위반 목록들 → ✓/✖ 줄과 종료 코드                       (출구: stdout)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | readProtocol | 파일 경로 → 문자열 | 부수효과 (입구: 파일 읽기) |
| 2 | splitSections (`scv_help_sections`) | 문자열 → 제목·바이트 목록 | 순수 |
| 3 | measureBudget (`scv_help_budget`) | 목록 + 상한 두 값 → 위반 줄들 | 순수 |
| 4 | collectRefs (`scv_help_refs`) | 문자열 → 부속 파일 이름 목록 | 순수 |
| 5 | checkRefs (`scv_help_check_refs`) | 이름 목록 + 실제 파일 이름 목록 → 위반 줄들 | 순수 |
| 6 | checkNoDuplicateRules (`scv_help_sub_clean`) | 부속 파일 문자열 → 위반 줄들 | 순수 |
| 7 | report | 위반·수치 → 출력·exit | 부수효과 (출구) |

- 부수효과 위치: 1(읽기)과 7(출력)뿐. 상한값은 인자로 받는다(기본 본문 14000 · 합계 30000).
- 재사용: 코어 검사 골격(`ok/fail/skip`, 페이로드 탐색)은 `test-skill-descriptions.sh` 와 같다.
  배송 파이프라인 `export-core.sh → materialize-profile.sh → (래퍼) project-core.sh` 는 단계도
  코드도 그대로 — 입력 트리에 `protocols/help/` 가 늘 뿐이다.
- 실행 시 경로(모델 쪽): `SKILL.md 본문 → 분기 판정 → (분기일 때만) 부속 파일 Read → 분기 수행`.
  포인터 문장이 "지금 읽어라" 명령형이어야 모델이 읽기를 건너뛰지 않는다 — 검사 T5 가 문장
  형태를 본다.

## Guardrails

- 앵커를 지우지 않는다. 검사가 보는 문장은 본문에 남기거나(제목 앵커 전부, T18·T19 일곱 문장,
  "never changes that dial", `action:help` · `action:promote` 토큰 각 하나 이상, `ARCHIVE_INDEX:` ·
  `LEGACY_CONVERSATIONS` 파싱 줄), 옮길 때는 그 검사의 대상을 본문+부속 파일로 바꾼다. 바꾼
  단언은 PR 본문에 전부 나열한다.
- 쉬운 말 절과 답 모양 절은 한 글자도 바꾸지 않는다.
- 부속 파일에는 쉬운 말 절 · 언어 절 · 호스트 이름 · effort 단계 이름을 적지 않는다. 경로는
  `${SCV_CORE_ROOT}/protocols/help/<name>.md` 형태만.
- 래퍼 두 저장소는 이 계획으로 바뀌지 않는다. 투영 검사가 실패하면 그것은 코어 쪽 실수다.
- 분기 동작을 바꾸지 않는다 — 질문 문구·선택지·처리 순서는 옮길 뿐 고치지 않는다. 고칠 것이
  보이면 다른 계획으로 적는다.
- 보조 스크립트의 인자 없음 출력과 위치 인자 출력은 바이트 단위로 바꾸지 않는다 — 훅과 옛 검사가
  그것을 본다. 줄이는 것은 `--with-context` 출력뿐이고, 목록은 새 플래그로 옮긴다.
- `status: active` 는 사용자가 정한다.

## Exit criteria

- All TESTS.md scenarios pass
- `core/protocols/help.md` ≤ 14,000 바이트, 부속 파일 다섯 존재, 새 검사가 코어 CI 에서 돈다.
- 매 턴 스택(훅 출력 + help.md + `help.sh --with-context` 출력) ≤ 18,000 바이트 — 현재 44,500.
- 코어 검사 전체(run-dry · test-force-help · test-help-shape · test-delegate-effort ·
  test-guidance · test-profile-and-export · test-host-runtime-materialization · test-host-neutral ·
  verify-core) 통과. 옆 체크아웃에서 `project-core.sh --check` PROJECTION_MISMATCH 0.
- 릴리스·설치 후 `claude plugin details` 의 help on-invoke 가 5.5k 이하로 실측되고 CHANGELOG
  0.48.0 에 전후가 적혀 있다(수동, T9).

## Suggested path

1. `tools/verify-core.sh:76` 수 세기에 `-maxdepth 1` (부속 파일을 만들기 전에 — 순서가 바뀌면
   중간 커밋마다 verify 가 깨진다).
2. `core/tests/test-help-budget.sh` 를 먼저 쓴다(Red): 본문 상한 · 부속 파일 다섯 · 참조 한 번 ·
   부속 파일 청결 · 합계 상한. 지금 본문 28KB 라 실패한다.
3. 분기 다섯을 `core/protocols/help/*.md` 로 옮기고 본문 자리에 포인터 스텁을 남긴다(3단계).
   옮긴 직후 run-dry 를 돌려 실패하는 앵커 일곱을 확인하고, 그 단언만 `HELP_ALL` 로 바꾼다.
4. 조사 위임 절을 포인터로(1단계), 설명문 압축(2단계). 각 단계 뒤 test-force-help ·
   test-help-shape · test-delegate-effort 를 돌린다.
5. `tools/materialize-profile.sh` 를 임시 디렉터리에 돌려 `protocols/help/*.md` 에
   `SCV_CORE_ROOT` 리터럴이 남지 않았는지, 옆 체크아웃에 벤더링해 `project-core.sh --check` 가
   0 인지 본다(T6·T7).
6. `help.sh`: `--with-context` 는 파싱 머리 뒤 exit 0, `--archive-index` 신설(4·5단계). 규약의 파싱
   목록과 `archive-search.md` 1단계를 맞춘다. run-dry 713(위치 인자) · 2279(인자 없음) 가 그대로
   통과하는지, `--with-context` 출력에 "Current project diagnosis" 가 없는지 본다(T10·T11).
7. 매 턴 스택 합을 재서 18,000 이하 확인(T12). docs 한 줄, VERSION 0.48.0, CHANGELOG(전후 실측은
   릴리스 뒤 T9 에서 채운다).

## Related Documents

- `scv/archive/20260911-wookiya1364-skills-layout-gates/PLAN.md` — 투영·검사 구조의 직전 변경
- `scv/archive/20260903-wookiya1364-help-answer-shape/PLAN.md` — 답 모양 절이 계약이 된 경위
- `scv/archive/20260904-wookiya1364-effort-auto-level/PLAN.md` — 조사 위임 절과 훅 블록의 관계

## 성공지표 (Metrics)

| 지표 | baseline (2026-09-14 실측) | target |
|---|---|---|
| 매 턴 스택 바이트 (훅 + 본문 + 스크립트 대화 모드 출력) | 44,458 | ≤ 18,000 (구현 실측 17,653 · 래퍼 투영본 17,963) |
| help.md 본문 바이트 | 28,121 | ≤ 14,000 (구현 실측 12,808 · 래퍼 투영본 13,199) |
| `help.sh --with-context` 출력 바이트 | 10,293 | ≤ 1,000 (구현 실측 127) |
| help on-invoke 토큰 (`claude plugin details`) | ~11,100 | ≤ 5,500 |
| 분기 턴의 추가 비용 | 0 | 부속 파일 1개 크기(1.3~3.8KB) + Read 1회 |
| help 본문을 읽는 기존 검사 통과 수 | 6/6 + run-dry | 6/6 + run-dry (대상 넓힌 단언 ≤ 7) |
| 래퍼 저장소 변경 파일 수 | — | 0 (벤더·투영 산출물 제외) |

## 예외처리 (Edge cases)

- 부속 파일이 빠진 채 릴리스되는 경우 — T2 가 CI 에서 잡는다(고아 참조 ✖). 실행 시에는 도달하지 않는다.
- 모델이 분기에서 부속 파일을 읽지 않고 답하는 경우 — T9(b) 로 한 번 관찰. 재현되면 그 분기의 스텁에 질문 문구를 되돌린다(부분 되돌림, 다른 분기는 유지).
- 옆 체크아웃이 없는 환경 — T7 은 SKIP, 나머지는 코어만으로 돈다.
- 규약 수 세기 수정 전에 부속 파일을 먼저 만드는 경우 — verify-core 가 15 초과로 실패한다. Suggested path 1 이 그래서 맨 앞이다.
- `SCV_DELEGATE_EFFORT=on` 인 프로젝트 — 위임 절이 포인터로 줄어도 훅의 `[SCV delegate]` 블록이 매 턴 실리므로 동작 동일(test-force-help T20 이 훅 쪽을 본다).

## Risks / Open Questions

- 모델이 분기에서 부속 파일 읽기를 건너뛸 위험 — 포인터를 명령형 한 문장으로 두고(검사),
  릴리스 뒤 hydrate 안 된 프로젝트에서 실제로 읽는지 한 번 본다(T9). 건너뛰면 그 분기 스텁에
  질문 문구까지 되돌리는 것이 되돌리기 쉬운 완화책.
- 분기 턴은 이전보다 도구 호출 한 번과 부속 파일 크기만큼 더 쓴다 — 매 턴 절감과의 맞바꿈.
  수치는 CHANGELOG 에 적는다.
- `claude plugin validate --strict` 가 `protocols/help/` 같은 비컴포넌트 하위 폴더에 경고를 내는지
  는 미확인(추정: 안 낸다). 래퍼 CI 첫 실행에서 확인한다.
- run-dry 단언 중 여기서 세지 못한 것이 옮겨질 본문 안에 더 있을 수 있다 — Suggested path 3 이
  그것을 실측으로 잡는다.
- 쉬운 말 절 1,207B 는 이번에 못 줄인다(열세 규약 공통 계약). 규약 전체 다이어트 때 함께.
- archive 검색 분기가 `--archive-index` 를 부르지 않고 예전처럼 출력에서 목록을 찾으려 할 위험 —
  부속 파일 1단계를 명령형으로 두고 T11 이 규약 문장을 본다.
- 후속 후보(이 계획 밖): 훅 진단 블록 압축(약 2KB, 사용자 결정 영역) · 열세 규약 공통 쉬운 말 절
  축소 · promote(69KB) · work(44KB) 본문 다이어트.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs:
