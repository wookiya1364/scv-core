---
title: 미결 6건 후속 — 결정 계약 한 곳, 중복 검사 허용목록, 갱신 거부 때 커밋 안내
slug: 20260921-wookiya1364-open-items-followup
author: wookiya1364
created_at: 2026-09-21
status: testing
kind: feature
lang: korean
tags: [followup, graft, decisions, rule-constitution, autosync, release]
raw_sources:
  - scv/conversations/20260921-073800-plugin-0550-apply-check.md
  - scv/raw/stale/20260920-wookiya1364-wrapper-release-after-core.md
refs: []
invariants:
  - "우선순위 서술은 SCV.md Top-level rules 한 곳만 — 새 문장은 rule-constitution 검사 (a)(b) 를 통과한다"
  - "결정 로그 세 지점(계획 승인·보관·폐기)의 엔트리 헤더와 'author is mandatory' 는 세 프로토콜에 그대로 남는다 (run-dry [16] 계약)"
  - "Graft 는 선택 제공자 — 설치·init·build 를 SCV 가 부르지 않는다"
  - "자동 갱신의 거부(DIRTY)는 여전히 거부다 — 문구만 는다, 강제 덮어쓰기는 없다"
  - "기존 테스트 전부 통과, 맥·리눅스 동일 (BSD sed/awk 함정 없음)"
scope:
  # 1. 지원 언어 목록 확인 날짜
  - core/scripts/lib/graft.sh
  - core/tests/test-graft-adapter.sh
  # 4. 결정 로그 계약(신설) + 세 프로토콜의 결정 절 축약
  - core/contracts/decisions.md
  - core/protocols/promote.md
  - core/protocols/work.md
  - core/protocols/regression.md
  - core/tests/run-dry.sh
  - core/contracts/guard.md
  # 5. PARTIAL 안내 + drift 안내에 커밋 문구
  - core/scripts/lib/scvroot.sh
  - core/tests/test-autosync.sh
  # 6. 허용목록 빼기(순수 함수 하나) + 허용목록 파일 신설 + 기준선 축소
  - core/scripts/lib/rule-constitution.sh
  - core/tests/test-rule-constitution.sh
  - core/tests/fixtures/rule-constitution/**
  # 3. "7개 유지" 결정 등 결정 로그와 SCV 장부
  - scv/DECISIONS.md
  - scv/INDEX.tsv
  - scv/readpath.json
  - scv/raw/**
  - scv/conversations/**
  - CHANGELOG.md
  - VERSION
---

# 미결 6건 후속 — 결정 계약 한 곳, 중복 검사 허용목록, 갱신 거부 때 커밋 안내

## Summary

어제 보관한 계획서 셋(graft-guidance · rule-conflicts-followup · rule-constitution)이 "나중에" 로 남긴 여섯 건을
사용자 결정대로 닫는다. 둘(2·3)은 코드를 바꾸지 않고 사실과 결정만 기록하고, 넷(1·4·5·6)은 작은 변경이다.
끝나면 코어를 0.56.0 으로 릴리스하고 래퍼 두 곳(scv-claude-code · scv-codex)도 릴리스한다.

## 사용자 결정 (2026-09-21, 대화 Turn 4)

| # | 미결 | 결정 | 확인한 현재 상태 |
|---|---|---|---|
| 1 | Graft 지원 언어 목록이 낡을 수 있음 | 갱신해라 | README(2026-09-21) 완전 지원 9 + 넓은 지원 14 = 23개. `SCV_GRAFT_LANG_EXTS` 와 **일치** — 목록 자체는 최신. 확인 날짜만 갱신하고, 확인 절차를 주석에 남긴다 |
| 2 | graft 있고 `graft/` 없는 상태 | 안내 함수 분기 하나 추가 | 0.55.0 에 **이미 있다** — `scv_graft_notice` 의 `no-graph` 분기가 `graft init` 을 안내하고 `test-graft-adapter.sh` 112·154행이 잠근다. 코드 변경 없음, 결정 로그에 사실만 남긴다 |
| 3 | "대화가 있는 액션" 7개 범위 | 7개로 둬라 | 변경 없음. 결정 로그 한 줄 |
| 4 | 기록 문장 본문 중복 | 성능·효과가 유지되면 줄여라 | 턴 기록은 이미 한 줄 포인터. 남은 중복은 **결정 로그** 절 — promote 5.1 · work 9b.0 · regression 4 가 같은 설명 단락(append-only·seed·형식 재사용·스크립트로만·INDEX 기록)을 각자 갖고 있고 검사 (b) 기준선에 키 2개로 잡혀 있다. 계약 한 곳으로 옮기고 프로토콜은 명령 한 줄 + 엔트리 블록만 남긴다 |
| 5 | 템플릿 지문 변경의 파급 | 지문이 바뀌어 있으면 커밋을 완료해야 갱신된다고 안내 | 거부 줄(DIRTY)에는 "commit or discard" 가 있으나 PARTIAL 머리줄과 drift 한 줄 설명에는 없다. 두 곳에 "커밋(또는 되돌리기)하면 다음 액션이 갱신한다" 를 넣는다 |
| 6 | 검사 (b) 의 오탐 | 권고대로 | 기준선 11개 중 6개는 **의도된 반복**(쉬운 말 블록 2 · 언어 설정 포인터 1 · 훅 템플릿 머리말 3). 허용목록 파일(키 + 이유)로 빼고 기준선은 진짜 빚 3개만 남긴다. 2개는 4번이 해소한다 |

## Goals / Non-Goals

- **Goals**
  - 결정 로그 절차의 본문이 `core/contracts/decisions.md` 한 곳에만 있고, 세 프로토콜은 스크립트 한 줄 + 자기 엔트리 블록 + 포인터만 갖는다.
  - 자동 갱신이 파일을 건너뛸 때(PARTIAL)와 드리프트 설명 한 줄에 "커밋(또는 되돌리기)을 완료하면 다음 액션이 갱신한다" 가 보인다.
  - 검사 (b) 가 의도된 반복을 허용목록(이유 포함)으로 빼고, 기준선은 진짜 중복만 담는다. 자가검사(심은 중복 잡기)는 그대로 통과.
  - Graft 지원 언어 목록의 확인 날짜와 확인 방법이 상수 옆에 있다.
  - 미결 2·3 은 결정 로그에 사실·결정으로 닫힌다.
  - 코어 0.56.0 릴리스 → 래퍼 둘 릴리스(0.56.0 · 0.56.0-codex.1).
- **Non-Goals**
  - 검사 (b) 의 어휘·키 알고리즘 변경. 기준선에 남는 빚 3개(codegen·work·regression 의 never 문장) 해소.
  - help 라우터의 턴 기록 블록 축약 — 라우터는 full.md 없이도 서야 하는 "떠나지 않는 계약" 이고 예산(7200B) 안이다.
  - 래퍼 저장소 문서의 복제 정리(래퍼 몫).

## Approach Overview

1. **graft.sh 주석** — 확인 날짜를 2026-09-21 로, "README 의 세 층(완전·넓은·LSP) 중 앞 둘의 언어를 확장자로" 라는 확인
   절차 한 줄. 상수 값은 그대로(일치 확인). 테스트는 주석에 `확인` 날짜 형식이 있는지만 본다.
2. **`core/contracts/decisions.md` 신설** — 왜(세 지점에서 자동으로 쌓인다), 무엇을(append-only · seed 는 sync · 핸드오프 결정 형식 재사용 ·
   author 필수 · 스크립트로만 · INDEX.tsv 위치 기록), 어디서 가리키나(세 프로토콜), 검사(run-dry [16] · 검사 (b)).
   `recording.md` 와 같은 골격.
3. **세 프로토콜 축약** — 각 절은 "왜 이 지점이 결정인가" 한 문장 + 스크립트 호출 블록 + 자기 엔트리 블록(verdict 별 필드) +
   `Decision entries follow core/contracts/decisions.md — author is mandatory` 포인터 한 줄. 설명 단락("The script keeps the format
   identical across the three append points…", "The entry reuses the handoff decision format", "seed the file via sync") 은 계약으로.
   run-dry [16] 이 요구하는 `## [<YYYY-MM-DD HH:MM>] <author>` 와 `author is mandatory` 는 세 곳에 남는다.
4. **scvroot.sh 문구** — PARTIAL 머리줄: `… was PARTIAL — the files below were skipped; commit (or discard) your changes in them and the next
   action refreshes them:`. drift 설명: `the refresh could not complete on its own — a file with uncommitted changes is skipped; commit
   (or discard) it, or run the sync action`. `PARTIAL` · `the files below were skipped` · `DIRTY` 는 그대로(기존 검사 계약).
5. **허용목록** — `duplicate-allowlist.txt`: `<키>\t<이유>` 줄들, `#` 주석. 순수 함수 `scv_rc_allowed_out <후보> <허용 키들>` 이 후보에서
   허용 키를 뺀다(래칫 앞). 자가검사에 "허용목록에 있는 키를 두 파일에 심어도 잡히지 않고, 없는 키는 잡힌다" 한 쌍 추가.
   기준선은 남는 3개로 다시 쓴다.
6. **결정 로그** — 미결 2(이미 닫힘)·3(7개 유지)·이 계획 채택.
7. **릴리스** — VERSION 0.56.0 · CHANGELOG · PR → develop · promote 워크플로 · 래퍼 둘(핀 PR 병합 → 릴리스 PR → promote).

## 순수함수 · 파이프라인 (Pure functions & pipeline)

```
flow(
  collect_rows,            // 규칙 문서들 → "<파일>\t<줄>\t<본문>" (효과: 파일 읽기)
  scv_rc_normative_rows,   // rows → 규범 문장 rows
  scv_rc_demand_keys,      // rows → "<키>\t<파일>"
  scv_rc_duplicate_keys,   // → 두 파일 이상의 키
  scv_rc_allowed_out,      // 후보 키들, 허용 키들 → 허용 뺀 후보   ← 신설
  scv_rc_ratchet_new,      // 후보, 기준선 → 기준선에 없는 후보 (비면 통과)
)
```

| # | 단계 | 받는 값 → 돌려주는 값 | 순수/부수효과 |
|---|---|---|---|
| 1 | collect_rows | 파일 경로들 → rows | 부수효과 (입구: 파일 읽기) |
| 2 | scv_rc_normative_rows | rows → 규범 rows | 순수 |
| 3 | scv_rc_demand_keys | rows → 키·파일 | 결정적 |
| 4 | scv_rc_duplicate_keys | 키·파일 → 중복 키 | 결정적 |
| 5 | scv_rc_allowed_out (신설) | 중복 키, 허용 키 → 남은 키 | 순수 |
| 6 | scv_rc_ratchet_new | 남은 키, 기준선 → 새 키 | 순수 |
| 7 | 보고 | 새 키 → ok/fail 출력 | 부수효과 (출구) |

- 부수효과 위치: 1(파일 읽기)과 7(출력)뿐. 허용목록 파일 읽기는 1 과 같은 입구(`strip_comments`)에서.
- 재사용: 2·3·4·6 은 그대로. 5 는 6 과 같은 모양(줄바꿈 포함 검색)이라 같은 골격으로 쓴다.
- 4번(문서)·5번(문구)·1번(주석)은 파이프라인이 아닌 문자열 편집 — 위 표에 넣지 않는다. scvroot 의 메시지는 이미
  `scv_template_decide`(순수) → 출력(효과) 구조이고 출력 문자열만 바뀐다.

## Guardrails

- 결정 로그 세 지점의 엔트리 헤더 형식과 `author is mandatory` 문구는 세 프로토콜에서 지우지 않는다 — run-dry [16] 이 계약이다.
- `journal-append.sh` · `decisions-append.sh` 의 동작·인자는 건드리지 않는다.
- 검사 (b) 의 허용목록은 **이유가 있는 줄만** — 이유 없는 줄은 검사가 거부한다(`#` 주석과 빈 줄만 예외).
- 자동 갱신은 거부를 거부로 둔다 — `--force` 를 자동으로 붙이지 않는다.
- `SCV_GRAFT_LANG_EXTS` 값은 README 와 다를 때만 바꾼다 — 이번엔 일치하므로 그대로.
- 옛 문장 grep 검사(`test-rule-constitution.sh` T3·T10, `test-help-*`)가 보는 문장은 손대지 않는다.
- 맥·리눅스 동일: `sed -i` 는 접미사 없이 쓰지 않고(`perl -pi`), awk 에 멀티바이트 문자 집합·`\x` 이스케이프 없음.

## Exit criteria

- All TESTS.md scenarios pass
- `bash tests/run.sh` · `core/tests/run-dry.sh` · `core/tests/test-*.sh` 전부 초록 (맥 로컬 + PR CI 의 ubuntu·macos)
- `test-rule-constitution.sh` (b): 후보 3건·기준선 3건, 허용목록 6건, 자가검사 통과
- 코어 v0.56.0 태그 + 릴리스 자산 2개; scv-claude-code v0.56.0 · scv-codex v0.56.0-codex.1 릴리스 "Latest"

## Suggested path

1. graft.sh 주석 갱신 + test-graft-adapter 검사 한 줄 (T1).
2. `core/contracts/decisions.md` 작성 → promote/work/regression 절 축약 → run-dry [16] 그대로 통과 확인 (T4).
3. scvroot.sh 두 문구 + test-autosync 검사 (T5).
4. rule-constitution: `scv_rc_allowed_out` + 허용목록 파일 + 기준선 축소 + 자가검사 (T6). 이때 4번 덕에 빠진 키 2개도 기준선에서 사라진다.
5. 결정 로그 3건 (T2·T3 + 채택).
6. VERSION · CHANGELOG · 전체 검사 → PR → promote → 래퍼 둘 (T7).

## Related Documents

- `scv/archive/20260920-wookiya1364-graft-guidance/PLAN.md` — 미결 1·2 의 출처
- `scv/archive/20260920-wookiya1364-rule-conflicts-followup/PLAN.md` — 미결 3·4
- `scv/archive/20260920-wookiya1364-rule-constitution/PLAN.md` — 미결 5·6
- `core/contracts/recording.md` — 결정 계약의 골격 모델

## Risks / Open Questions

- **run-dry 가 옮긴 단락을 다른 문구로도 잡고 있을 수 있다** — 3909행 외의 assert 가 붉으면 그 문구는 프로토콜에 남기고 계약에는 링크만.
- **허용목록 키가 문장 편집으로 바뀐다** — 키는 앞 8단어라 문장을 고치면 허용목록이 안 맞고 검사가 다시 묻는다. 의도된 동작.
- **래퍼 사본에서의 (b)** — 벤더링 사본은 (b) 를 건너뛴다(0.54.1). 허용목록 추가는 사본에 영향 없음.
- **미결 1 은 "갱신" 이 아니라 "확인"** — 목록이 이미 맞아 값이 바뀌지 않는다. 사용자에게 그렇게 보고한다.

## Links

- Raw originals: (listed in frontmatter)
- Related PRs: (구현 후)
