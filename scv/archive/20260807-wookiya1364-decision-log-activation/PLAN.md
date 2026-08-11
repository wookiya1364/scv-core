---
title: "결정 로그 실작동 — 실행 경로 복구 + 구현 델타 기록"
slug: 20260807-wookiya1364-decision-log-activation
author: "wookiya1364"
created_at: 2026-08-07
status: done
kind: feature
lang: ko
tags: [decisions, work, protocols, cognitive-debt]
raw_sources:
  - "~/다운로드/notion-understanding-bottleneck-video-analysis.md"
refs:
  - type: reference
    url: "https://www.geoffreylitt.com/2026/07/02/understanding-is-the-new-bottleneck"
    note: "Geoffrey Litt — Understanding is the new bottleneck (인지 부채 · 이해 산출물)"
  - type: reference
    url: "https://margaretstorey.com/blog/2026/02/09/cognitive-debt/"
    note: "Margaret-Anne Storey — Cognitive debt"
supersedes: []
scope:
  - "core/protocols/work.md"
  - "core/template/scv/DECISIONS.md"
  - "core/template/scv/routines/examples/**"
  - "core/tests/**"
  - "scv/DECISIONS.md"
  - "CHANGELOG.md"
  - "docs/guidance-ablation.md"
invariants:
  - "새 필수 기록 필드는 SCV:GUIDANCE 마커 밖(CONTRACT)에 둔다 — minimal 투영에서 사라지면 강제력이 환경변수로 증발한다"
  - "scv/archive/<slug>/ 안의 어떤 파일도 수정하지 않는다 (immutable archive)"
  - "core/scripts/ 의 기존 스크립트를 수정하지 않는다 (work.sh · pr-helper.sh · deck.sh · sync.sh · status.sh)"
  - "core/actions.json 과 host-profile 계약을 건드리지 않는다 — 액션 카탈로그 변경은 래퍼 자동 벤더링을 깨뜨린다"
  - "core/protocols/ 아래에서는 work.md 한 파일만 수정한다 (test-guidance.sh 의 미커밋 diff 스코프 검사)"
---

# 결정 로그 실작동 — 실행 경로 복구 + 구현 델타 기록

## Summary

v0.22.0 은 `scv/DECISIONS.md` 와 3개 자동 append 지점(promote 승인 · work
archive · regression obsolete)을 도입했다. 그런데 **이 저장소에서 결정 엔트리는
0건이고, `scv/DECISIONS.md` 파일 자체가 git 전체 이력에 존재한 적이 없다.**

원인은 기록할 필드가 부족해서가 아니라 **기록 지시가 실행되는 경로가 없어서**다.
아카이브 5건은 전부 수동 `git mv` 로 처리됐고(`scv/archive/INDEX.yaml` 부재가
확증), 프로토콜상 유일한 자동 경로인 `action:work` Step 9b.0 은 한 번도 도달하지
않았다. 이 상태에서 엔트리 스키마에 필드를 더하는 것은 정의상 형식주의다.

따라서 순서를 뒤집는다: **(1) 실행 경로를 복구하고 → (2) 그다음에 기록 내용을
강화한다.** 강화 항목은 신규 필드 **1개**(`path delta:`)뿐이다. 계획 대비 실제로
간 경로와 이탈 이유는 현재 `work.md:201` 의 "tell the user in one line" 으로만
존재하고 채팅과 함께 증발하는, 다른 어디에도 기록되지 않는 유일한 정보축이다.

## Goals / Non-Goals

- **Goals**
  1. **베이스라인 확보** — `scv/DECISIONS.md` 를 생성하고, 아카이브 5건의 소급
     엔트리를 남겨 "엔트리 0건" 상태를 끝낸다.
  2. **실행 경로 복구** — `action:work <slug> --archive` (Step 0 short-circuit)
     경로에서도 Step 9b.0 만은 수행되게 한다. 현재 관측된 아카이브 트래픽 100% 가
     이 경로 바깥(수동 mv)이거나 이 경로이므로, 여기가 막혀 있으면 나머지가 전부
     무효다.
  3. **구현 델타 1필드** — Step 9b.0 엔트리 스키마에 `- path delta:` 를 추가한다.
     기준점 표기는 `Suggested path (legacy PLANs: Steps)` 로 기존 6개 지점과
     일치시키고, nested multirepo 경로 절을 함께 명시한다.
  4. **중복 회피** — `new invariants:` 필드를 **신설하지 않는다.** 기존 `- why:`
     문구에 불변식 절 하나를 덧붙여 흡수한다.
  5. **기계 근거화** — Step 8 에서 `drift-detect.sh <slug>` 를 호출해 `SCOPE_
     OUTSIDE_FILES` 를 델타 서술의 근거로 삼는다. promote-only 스크립트이므로
     archive 이전인 Step 8 이 이걸 돌릴 수 있는 유일한 시점이다.
  6. **누락 탐지** — `decision-log-integrity` 예시 루틴을 추가해 "아카이브 슬러그 ↔
     DECISIONS 엔트리" 대조를 주기 점검 가능하게 만든다. 이것이 이 계획에서 유일한
     사후 탐지 수단이다.

- **Non-Goals**
  - `FEATURE_ARCHITECTURE.md` 의 구현 후 갱신 (다이어그램 스테일 — 후속 슬러그
    `feature-arch-refresh` 로 이월)
  - PR body 에 델타 노출 (`pr-helper.sh` 에 `--body-extra` 류 주입점이 없어
    스크립트 수정이 필요 — 후속 슬러그 `pr-delta-surface` 로 이월)
  - PLAN frontmatter `invariants:` 를 `action:work` 가 강제하게 만들기
    (`PROMOTE.md:294` 가 "work does not enforce this field" 를 명시 — 별건)
  - `promote.md` / `regression.md` 의 엔트리 스키마 변경 (그 두 결정에는 구현
    단계가 없다 — 의도적 비대칭)
  - `docs/guidance-ablation.md` 의 CONTRACT/GUIDANCE **판정 기준 문장** 수정
    (기준을 바꾸면 기존 전체 분류 재검토가 딸려온다 — 측정표 수치만 갱신)

## Approach Overview

**측정된 현재 상태 (2026-08-07, 이 계획의 전제)**

| 사실 | 확인 방법 |
|---|---|
| `scv/DECISIONS.md` 부재 · 이력에도 없음 | `git log --oneline --all -- scv/DECISIONS.md` → 0줄 |
| `scv/archive/INDEX.yaml` 부재 | `work.sh:234-240` 이 `--archive` 마다 재생성한다고 명시 → 미실행 확증 |
| 아카이브 5건 전부 수동 `git mv` | `git show --stat 91588c4` → `scv/{promote => archive}/…` 리네임 + 손으로 쓴 ARCHIVED_AT.md |
| 아카이브 5건 전부 `status: planned` | `grep '^status:' scv/archive/*/PLAN.md` (supersede/regression 은 `done` 전제) |
| `## Suggested path` 보유 0/5 | 4건 `## Steps`(legacy), 1건 둘 다 없음 |
| DECISIONS 를 **쓰는** 코드 0건 | `grep -rn DECISIONS core/scripts/ tools/` → status.sh 읽기 + 주석뿐 |

**설계 판단 — 왜 DECISIONS.md 인가**

델타를 담을 후보 4개를 검토해 3개를 탈락시켰다.

- `ARCHIVED_AT.md` 확장 → `work.sh:214-228` heredoc 수정 필요 + 배포되는
  `PROMOTE.md`(merge_policy overwrite) 동기화까지 딸려온다. "스크립트 무수정"과
  양립 불가.
- `--reason` 에 싣기 → `work.sh:217` 이 `reason: $REASON_LINE` 을 **따옴표 없이**
  YAML 에 보간한다. 사용자가 매번 따옴표를 관리해야 하는 취약한 규약이 된다.
- archive 폴더 신규 파일 → deck(`doc.mjs` 고정 3파일)도 PR body 도 읽지 않는다.
  소비자 없는 산출물.

**정직하게 남는 한계**: DECISIONS.md 의 유일한 소비자인 `status.sh:384-392` 는
`## [날짜` **헤더만** 출력하고 본문 불릿은 표시하지 않는다. 즉 새 필드는 사람이
파일을 직접 열 때만 보인다. 이 계획은 "기록이 남는다"까지만 달성하고 "도구가
보여준다"는 달성하지 않는다 — Non-Goals 의 후속 슬러그가 그 몫이다.

**CONTRACT/GUIDANCE 분류**

`- path delta:` 필드 줄과 "생략 불가" 의무 문장은 **마커 밖(CONTRACT)**. 근거 3중:
(a) `docs/guidance-ablation.md:42-44` 의 전형적 CONTRACT 목록에 "스캐폴드 템플릿"이
있고, (b) `promote.md:446-474` 가 이미 같은 구조(필드는 마커 밖, why 산문은 마커
안)를 쓰고 있으며, (c) `test-guidance.sh` 가 minimal 투영에서 `"scv/DECISIONS.md"`
생존을 이미 요구한다. 근거 산문과 Step 8 코칭만 GUIDANCE 로 감싼다.

## Guardrails

- **새 action 을 만들지 않는다.** `core/actions.json`, host-profile 계약 불변 —
  액션 카탈로그가 바뀌면 래퍼 자동 벤더링이 래퍼 자체 가드에서 실패한다.
- **`core/scripts/` 의 기존 스크립트를 수정하지 않는다.** 특히 `work.sh` 의
  ARCHIVED_AT heredoc(:214-228). 이 경계를 지키는 한 run-dry 의 archive 블록과
  [19b] 실행 동등성 하네스가 원리적으로 무영향이다.
- **`core/protocols/` 아래에서 `work.md` 한 파일만 수정한다.**
  `test-guidance.sh:173-179` 가 `git diff --name-only HEAD -- core/protocols/` 로
  다른 프로토콜의 **미커밋** 변경까지 실패로 판정한다. `codegen.md` 는 손대지
  않는다 — `codegen.md:123` 이 Steps 8–9e 를 work.md verbatim 으로 위임하므로
  이미 상속된다.
- **immutable archive** — `scv/archive/<slug>/` 안의 어떤 파일도 새로 쓰거나
  고치지 않는다. 소급 엔트리는 아카이브 **밖**인 `scv/DECISIONS.md` 에만 쓴다.
- **소급 엔트리는 재구성이지 창작이 아니다.** `ARCHIVED_AT.md` · `CHANGELOG.md` ·
  각 `PLAN.md` 에서 확인 가능한 내용만 쓴다. `path delta:` 는 당시 기록이 없으므로
  `unknown (retroactive)` 로 명시한다 — 모르는 것을 지어내지 않는다.
- **`scv/DECISIONS.md` 를 `action:sync` 로 시딩하지 않는다.** 이 저장소에는
  `scv/{PROMOTE,SCV,TODO,REPORTING}.md` 등이 없어 sync 가 7개 이상 부수 파일을
  한꺼번에 만든다. 템플릿 1개 파일만 복사한다 (프로토콜 문장 `seed via
  action:sync` 와 어긋나는 의도적 예외 — 이유를 커밋 메시지에 남긴다).
- **엔트리 헤더 포맷을 바꾸지 않는다** — `## [<YYYY-MM-DD HH:MM>] <author> — <제목>`.
  `status.sh:384` 정규식이 파싱하고 run-dry 가 3개 프로토콜 공통으로 assert 한다.
  새 정보는 하위 `- <key>:` 불릿으로만 추가한다.
- **기존 heading 문자열을 개명하거나 번호를 재배치하지 않는다.**
  `#### Step 9b.0 — Decision log append (v0.22.0+)` 등은 run-dry 가 리터럴 고정.
- **마커 규율** — 새 GUIDANCE 블록은 열림/닫힘 정확히 한 쌍, 대문자 그대로, 한 줄
  전체(같은 줄에 다른 텍스트 금지), 중첩 없음. 위반 시 `guidance-filter.sh` 가
  fail-closed 로 **full 모드에서도** 전체 벤더링을 중단시킨다.
- **새 GUIDANCE 블록 본문 금지 2가지** — (a) `${SCV_CORE_ROOT}/scripts/*.sh` 호출
  줄, (b) **컬럼0에서 시작하는** frontmatter 키(`invariants:` 등). 둘 중 하나라도
  들어가면 run-dry [19a] 의 calls/front diff 가 깨진다.
- **호스트 종속 토큰 금지** — `Claude` / `Codex` / `AskUserQuestion` / `/scv:` /
  `.claude` / 모델명. `tests/test-host-neutral.sh` 가 exit 1 한다.
- **필드를 2개 이상 늘리지 않는다.** `new invariants:` 는 기존 `why:` 의
  "what was learned while implementing it" 의 부분집합이다 — 중복 필드는 개수와
  무관하게 형식주의다.
- **버전 축**: `VERSION` 만 움직인다. `CORE_API` 는 `tools/verify-core.sh:28` 이
  리터럴 `1` 하드핀이라 올리면 검증기까지 고쳐야 한다. `TEMPLATE_VERSION` 은
  커밋 1b96877 이 템플릿 파일 3종을 통째로 추가하고도 안 올린 선례를 따른다.
- **"강제"를 과장하지 않는다.** DECISIONS 를 쓰는 스크립트는 존재하지 않는다.
  테스트가 보장하는 것은 "프로토콜에 지시가 있다"와 "그 지시가 minimal 에서
  사라지지 않는다" 두 가지뿐임을 PLAN/TESTS/CHANGELOG 어디에서도 숨기지 않는다.

## Exit criteria

- `scv/DECISIONS.md` 가 존재하고 아카이브 5건에 대응하는 소급 엔트리를 담는다.
  `bash core/scripts/status.sh` 의 `[scv/DECISIONS.md — recent decisions]` 블록이
  `(file does not exist …)` 가 아니라 실제 엔트리 수를 보고한다.
- `action:work <slug> --archive` 경로에서 Step 9b.0 이 수행된다는 것이
  `work.md` Step 0 문장에 명시되어 있다.
- `core/protocols/work.md` Step 9b.0 의 ```markdown 펜스 안에 `- path delta:` 가
  존재하고, 그 줄이 어떤 `SCV:GUIDANCE` 마커 쌍에도 속하지 않는다.
- `guidance-filter.sh --mode minimal core/protocols/work.md` 출력에
  `- path delta:` 가 살아 있다.
- `guidance-filter.sh --lint core/protocols/work.md` 가 `GUIDANCE_LINT: OK` 로
  끝나고, `--mode full` 출력이 원본과 바이트 동일하다.
- 기존 스위트 전량 무회귀 — `bash tests/run.sh`, `bash core/tests/run-dry.sh`,
  `for t in core/tests/test-*.sh; do bash "$t"; done` 모두 exit 0.
- `git diff --name-only HEAD -- core/protocols/` 결과가 `core/protocols/work.md`
  단 하나이고, `-- core/scripts/ core/actions.json` 결과가 비어 있다.
- **이 계획 자신이 `bash core/scripts/work.sh <slug> --archive` 로 아카이브되고**,
  그 결과로 `scv/archive/INDEX.yaml` 이 생성되며, `scv/DECISIONS.md` 에
  `- path delta:` 가 채워진 엔트리가 append 된다. 이것이 이 저장소 최초의
  end-to-end 실사용 증거다.

## Suggested path

경로는 제안이고 Guardrails 와 Exit criteria 가 계약이다. 단 **1번은 순서 고정** —
베이스라인 없이 3번 이후를 하면 효과를 측정할 수 없다.

1. **베이스라인** — `core/template/scv/DECISIONS.md` 를 `scv/DECISIONS.md` 로 1개만
   복사(sync 전체 실행 금지). 아카이브 5건의 소급 엔트리를 append: 헤더 날짜는 각
   `ARCHIVED_AT.md` 의 `archived_at`, `why:` 는 PLAN/CHANGELOG 에서 재구성,
   `path delta:` 는 `unknown (retroactive)`.
2. **Step 0 실행 경로 복구** — `work.md:50-52` 의 "Do not continue with Steps 1+" 에
   Step 9b.0 예외 절을 추가. 이 경로는 "대화 밖에서 구현하고 수동 아카이브" 용도
   (`work.md:547`)이므로, 델타를 모를 수 있다는 점을 문안에 반영한다.
3. **Step 9b.0 스키마** — ```markdown 펜스의 `- why:` 와 `- refs:` 사이에
   `- path delta:` 삽입. 기준점을 `Suggested path (legacy PLANs: \`Steps\`)` 로
   표기하고, 둘 다 없는 PLAN 에서는 Step 6 에서 사용자에게 말한 경로를 기준으로
   삼는다고 명시. nested module 절을 `work.md:270` 과 같은 화법으로 추가
   (`<SCV_DIR>/DECISIONS.md`).
4. **`why:` 흡수** — 기존 `why:` 문구에 "including anything that must not break
   from now on" 절을 덧붙인다. 새 필드를 만들지 않는다.
5. **Step 6 / Step 8 훅** — Step 6 의 "tell the user in one line" 에 그 줄이
   9b.0 으로 이어진다는 절을 덧붙이고(CONTRACT, 줄 추가 0), Step 8 에는
   `drift-detect.sh <slug>` 호출과 사전 보고를 GUIDANCE 블록으로 넣는다.
   codegen 은 Step 8 을 상속하지만 Step 6 은 대체하므로, Step 8 문안은 codegen
   에서도 의미가 서는 표현("계획이 예상한 경로 대비")을 쓴다.
6. **회귀 안전망** — `core/tests/run-dry.sh` [16] 에 `- path delta:` assert,
   `core/tests/test-guidance.sh` 의 **work.min.md 용** 배열(`"$TMP/work.min.md"` 를
   grep 하는 쪽 — promote 배열과 혼동 금지)에 같은 앵커 추가. 그 배열 위에 "왜
   여기에 등록해야 하는가" 주석 한 줄을 남긴다.
7. **탐지 루틴** — `core/template/scv/routines/examples/decision-log-integrity.md`
   추가. 아카이브 슬러그마다 대응 엔트리가 있는지, 그 엔트리에 `path delta:` 가
   있는지 대조해 누락을 보고. `archive-integrity.md` 의 frontmatter 5키 규약과
   본문 형식을 그대로 따른다.
8. **문서·측정** — `CHANGELOG.md` 에 `## [0.23.0] - Unreleased` 섹션.
   `guidance-filter.sh --lint core/protocols/work.md` 를 편집 **후** 실행해 나온
   실측값으로 `docs/guidance-ablation.md` 의 work.md 행을 갱신(현재 `203 / 521` 은
   실측 `203 / 529` 와 어긋난 낡은 값 — **별도 커밋**으로 분리해 델타 필드 롤백 시
   함께 되돌아가지 않게 한다).
9. **자기 적용** — 이 계획을 `work.sh --archive` 로 아카이브해 end-to-end 를
   실증한다. 이때 `scv/archive/INDEX.yaml` 이 6건 목록으로 새로 생성된다(예상된
   부수 산출물).

## Related Documents

<!-- 없음. 근거는 본문에 파일:줄로 인라인했다. -->

## Risks / Open Questions

- **[결정 필요] `path delta:` 를 항상 필수로 할 것인가, 이탈했을 때만 쓸 것인가.**
  현재 안은 **항상 필수 + 한 단어 탈출구**(`as planned`)다. 근거: 7번 탐지 루틴이
  "필드 존재"를 기계적으로 볼 수 있어야 "이탈 없음"과 "에이전트가 빠뜨림"을 구분할
  수 있다. 반대 논리도 타당하다 — append-only 로그에 `as planned` 가 무한 누적되는
  것은 보장된 노이즈이고, `refs:`/`conversation:` 의 생략 관행과도 어긋난다.
  **대표님 판단이 필요한 지점이다.** 되돌리기는 한 줄 문구 수정이라 저렴하다.
- **소급 엔트리 5건이 실제 결정을 얼마나 반영하는가.** ARCHIVED_AT 의 `reason:` 은
  5건이 PR 번호만 다른 동일 템플릿 문자열이다. 재구성 원천이 얇다 — 베이스라인
  용도로만 쓰고 "이때 무엇을 결정했는가"의 사료로 과신하지 않는다.
- **어블레이션 취지와의 방향 상충.** CONTRACT 줄이 늘면 minimal 투영이 커진다 —
  프롬프트 축소라는 어블레이션 목표와 반대 방향이다. 이번엔 CONTRACT 추가를 필드
  1줄 + 의무 문장 2~3줄로 제한하고 근거 산문은 전부 GUIDANCE 로 보낸다. 누적
  감시 수단은 CHANGELOG 의 재측정 비율 보고뿐이다.
- **오분류가 조용하다는 구조적 부채.** run-dry [19a] 는 스크립트 호출·컬럼0
  frontmatter 만 보고 [19b] 는 에이전트를 실행하지 않는다. 앞으로 work.md 에
  추가되는 모든 CONTRACT 문장은 `test-guidance.sh` 배열에 **수동 등록**되지 않는
  한 GUIDANCE 로 잘못 감싸도 테스트가 통과한다. 이번엔 앵커를 등록해 막지만, 그
  배열이 수동 유지 목록이라는 사실 자체가 부채다.
- **엔트리 스키마 분기 심화.** promote(5필드) / work(**6필드**) / regression(3필드)
  / `handoff.sh` 가 쓰는 `scv/decisions/<id>.md`(frontmatter 키) / 템플릿 선언.
  공통 검사는 헤더 포맷과 `author is mandatory` 뿐이라 드리프트를 잡지 못한다.
  의도적 비대칭이며 CHANGELOG 문서화에만 의존한다.
- **기존 프로젝트 전파.** `core/template/scv/DECISIONS.md` 는
  `merge_policy: preserve` 라 이미 파일이 있는 프로젝트에는 전파되지 않는다.
  실효 전파 매체는 프로토콜 md 이며 래퍼 재벤더링으로 도달한다. 그 프로젝트들은
  파일 상단 스키마가 구형인데 프로토콜은 신형을 요구하는 상태가 된다 — 수용한다
  (`--force` 덮어쓰기는 사용자가 쌓은 로그를 밀어내므로 금지).
- **릴리스 전파 지연.** 태그 push 는 사용자 수령이 아니다. `SCV_WRAPPER_SYNC_TOKEN`
  미설정 시 최대 하루 폴링 대기이고, 벤더 봇 PR 은 GITHUB_TOKEN 제약으로 CI 가
  안 돌아 close/reopen 이 필요하다. 완료 보고에서 이 구분을 지킨다.

## Links

- 착안 원천: `~/다운로드/notion-understanding-bottleneck-video-analysis.md`
  (Geoffrey Litt — "이해는 검사를 위한 비용이 아니라 다음 아이디어를 만들기 위한
  상태다". 이 계획은 그중 "계획과 구현의 델타" 축 하나만 다룬다.)
- 이월 후속 슬러그 후보: `feature-arch-refresh`, `pr-delta-surface`,
  `decisions-consumer-surface` (status/deck 이 엔트리 본문을 보여주게 하기)
