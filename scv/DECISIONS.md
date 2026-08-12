---
name: decisions-log
version: 1.0.0
status: active
last_updated: 2026-08-07
tags: [decisions, append-only, attribution]
standard_version: 1.0.0
merge_policy: preserve
---

# DECISIONS — append-only 결정 로그

> 단일 리포의 결정 전용 기록입니다 (멀티리포 root 전용인 `scv/decisions/` 와
> 별개). 결정에 이르는 대화 원문은 `scv/journal/` 과 `scv/conversations/` 에,
> 결정 자체는 여기에 구조화되어 쌓입니다.

## 규약

- **append-only** — 기존 엔트리의 수정·삭제 금지. 번복도 새 엔트리로 append
  합니다 (이전 엔트리를 refs 로 가리키면 됩니다).
- **author 필수** — 모든 엔트리는 작성자 귀속. 익명 엔트리 금지.
- 교훈(lessons)도 별도 문서가 아니라 엔트리 타입으로 여기에 흡수합니다.
- 자동 append 지점 3곳 (프로토콜이 수행): `action:promote` 계획 승인(채택
  방향 + 버린 대안), `action:work` archive(reason 의 결정 승격 + 계획 대비
  실제 경로), `action:regression` obsolete 판정(왜 폐기인지).
- 아래 스키마는 세 지점의 **합집합 요약**이다. 각 지점의 필수 필드는 서로
  다르며, 규범 원천은 이 파일이 아니라 각 프로토콜의 인라인 템플릿이다.

## 엔트리 스키마 (handoff decision 포맷 재사용)

```markdown
## [YYYY-MM-DD HH:MM] <author> — <제목>

- verdict: adopted | archived | obsolete | needed | maybe | not-needed | lesson
- why: <1–3줄 — 근거>
- discarded alternatives: <버린 대안 — 없으면 생략>
- path delta: <Suggested path(legacy: Steps) 대비 실제로 간 경로와 이탈 이유.
  `action:work` archive 엔트리에서는 필수 — 그대로 갔으면 "as planned">
- refs: <관련 PLAN/PR/티켓 경로·URL — 없으면 생략>
- conversation: <scv/conversations/... 또는 scv/journal/... 링크 — 없으면 생략>
```

<!-- append entries below this line — never edit or delete existing ones -->

> 아래 5건은 **소급 재구성** 엔트리다. v0.22.0 에서 결정 로그 지점이 도입됐지만
> 당시 아카이브가 `action:work` 를 거치지 않아(수동 `git mv`) 엔트리가 남지 않았다.
> 내용은 각 `PLAN.md` · `ARCHIVED_AT.md` · `CHANGELOG.md` 에서 확인 가능한 범위로만
> 복원했고, 당시 기록이 없는 항목은 `unknown (retroactive)` 로 둔다.

## [2026-08-07 14:42] wookiya1364 — PLAN 문법 개편 (plan-grammar) archived

- verdict: archived
- why: PLAN 의 `Steps` 가 "1번 하고 2번 하고" 식 절차 지정이라 베테랑의 과지정
  실패가 문법에 구조화돼 있었다. 계획 문법을 "과업 + 가드레일 + 종료 조건 +
  검증 수단" 중심으로 바꾸고, `Suggested path` 는 계약이 아니라 제안임을
  명시했다. 병렬 힌트(`parallel_groups`)와 raw 인젝션 위생을 함께 넣었다.
  legacy `## Steps` PLAN 은 그대로 처리되도록 후방호환을 유지했다.
- path delta: unknown (retroactive)
- refs: scv/archive/20260807-wookiya1364-plan-grammar/PLAN.md

## [2026-08-07 14:42] wookiya1364 — adoption 단일화 + 표준 문서 7종 제거 archived

- verdict: archived
- why: greenfield(`--new`) 모드와 표준 문서 스캐폴딩 7종을 제거했다. 그 문서들은
  모델이 코드베이스에서 직접 도출 가능한 사실의 선제 스냅샷이라 존재 가치를
  증명한 적이 없다는 어블레이션 논리를 적용한 것이다. `action:sync` 가 기존
  프로젝트에서도 **백업 없이** 삭제하도록 했다 — git 이력을 복구 경로로 삼는
  의도적 결정. TEMPLATE_VERSION 2.0.0 (BREAKING).
- discarded alternatives: 백업 후 삭제 (git 이력이 이미 복구 경로이므로 중복)
- path delta: unknown (retroactive)
- refs: scv/archive/20260807-wookiya1364-adoption-only-doc-removal/PLAN.md

## [2026-08-07 14:42] wookiya1364 — 전면 기록화 (team journal + DECISIONS + TODO) archived

- verdict: archived
- why: feature 단위 검증은 완결적이지만 프로젝트 수준 맥락이 남지 않는 문제를
  풀었다. 작성자 귀속 `scv/journal/`(일·사용자 단위 파일 분리로 git 충돌 차단),
  단일 리포용 `scv/DECISIONS.md`, `scv/TODO.md` 를 도입하고 호스트 훅으로
  자유대화를 캡처하게 했다. redaction 은 휴리스틱이며 안전망이지 허가가 아님을
  문서에 명시했다.
- path delta: unknown (retroactive)
- refs: scv/archive/20260804-wookiya1364-team-journal/PLAN.md

## [2026-08-07 14:42] wookiya1364 — scv/routines 유지보수 루틴 레이어 archived

- verdict: archived
- why: "한 문장 프롬프트 루틴이 매일 돌며 유지보수를 자동화" 하는 실천을 SCV
  구조로 가져왔다. 루틴 1개 = md 파일 1개, frontmatter 5키(name/cadence/
  guardrails/exit/report) 필수, 본문은 절차 나열 금지(경로는 실행 에이전트가
  결정). **스케줄링은 SCV 가 소유하지 않는다** — 호스트(cron/CI)의 몫으로 두고
  SCV 는 정의 형식과 실행 프로토콜만 제공하기로 했다. 예시 7종 동봉.
- discarded alternatives: SCV 가 자체 스케줄러를 갖는 안 (호스트 책임 경계 침범)
- path delta: unknown (retroactive)
- refs: scv/archive/20260807-wookiya1364-routines/PLAN.md

## [2026-08-07 14:42] wookiya1364 — 가이던스 어블레이션 1단계 archived

- verdict: archived
- why: 프로토콜 md 에 결정론적 계약과 행동 코칭이 섞여 있어 코칭의 가치를 측정할
  수단이 없었다. `<!-- SCV:GUIDANCE -->` 마커 규약 + 주입 시점 필터
  (`SCV_GUIDANCE=full|minimal`)를 만들어 "지우고 → 측정하고 → 되살리는" 체계를
  갖췄다. 판정 기준은 "삭제해도 산출물의 형식·경로·불변식이 변하지 않으면
  GUIDANCE". 목표 비율을 정하지 않고 결과만 측정해 보고했다(promote 27.3%,
  work 38.4%). 범위를 promote·work 2개로 한정한 것이 위험 통제의 핵심.
- discarded alternatives: 전체 14개 프로토콜 일괄 분류 (1단계 위험 과다 — 2단계로 이월)
- path delta: unknown (retroactive)
- refs: scv/archive/20260807-wookiya1364-guidance-ablation/PLAN.md

## [2026-08-11 10:49] wookiya1364 — 결정 로그 실작동 (실행 경로 복구 + 구현 델타 기록) archived

- verdict: archived
- why: v0.22.0 이 도입한 결정 로그가 이 저장소에서 엔트리 0건이었다 — 원인은
  필드 부족이 아니라 기록 지시가 도달하는 경로의 부재였고(아카이브 5건 전부
  수동 git mv, INDEX.yaml 부재가 확증), 그래서 "필드 추가"가 아니라 "실행 경로
  복구 → 그다음 기록 강화" 순서로 뒤집었다. 앞으로 깨면 안 되는 것: work.md 에
  CONTRACT 문장을 추가할 때마다 test-guidance.sh 의 work.min.md 생존 배열에
  앵커를 **수동 등록**해야 한다. run-dry [19a] 는 스크립트 호출과 컬럼0
  frontmatter 만 보고 [19b] 는 에이전트를 실행하지 않으므로, 그 배열이
  오분류를 잡는 유일한 수단이다.
- discarded alternatives: ARCHIVED_AT.md 확장(work.sh heredoc + 배포 템플릿
  전파가 딸려옴) · --reason 에 델타 싣기(reason 이 따옴표 없이 YAML 에 보간됨)
  · archive 폴더 신규 파일(deck·PR 어느 쪽도 읽지 않는 소비자 없는 산출물)
  · new invariants 별도 필드(기존 why 의 부분집합)
- path delta: Suggested path 9단계의 뼈대는 그대로 갔으나 4곳이 달라졌다.
  (1) 5단계에서 drift-detect 호출을 GUIDANCE 블록 안에 넣었다가 계획 자신의
  가드레일 위반임을 발견해 CONTRACT 로 옮겼다 — minimal 투영에서 호출이 사라져
  [19a] 호출 시퀀스 diff 가 깨지는 상태였다. (2) 적대 검증이 Step 0 의 unknown
  지시가 무조건임을 잡아내, 같은 대화에서 구현 후 아카이브하는 경로까지 델타를
  버리게 되는 것을 조건부로 고쳤다. (3) 같은 검증에서 nested 모듈 호출이 exit 2
  로 실패함이 드러나 PROMOTE_DIR 우회를 문안에 넣었다(계획에 없던 항목).
  (4) "scope 없으면 건너뛰라"는 예외를 GUIDANCE 에서 CONTRACT 로 올렸다 —
  예외만 minimal 에서 증발하면 (1)의 실패가 부호만 뒤집혀 재발한다. 공통 원인은
  CONTRACT/GUIDANCE 경계가 "지시의 성격"이 아니라 "그 줄이 사라졌을 때 무엇이
  깨지는가"로 결정된다는 점을 편집 중에 반복해서 놓친 것이다.
- refs: scv/archive/20260807-wookiya1364-decision-log-activation/PLAN.md

## [2026-08-11 12:07] wookiya1364 — 구현 원칙 4종 (재활용·최소구현·모듈분리·장기관점) archived

- verdict: archived
- why: work·codegen 은 "무엇을 만들지"(PLAN)와 "무엇이 통과해야 하는지"(TESTS)는
  계약으로 갖고 있었지만 "어떻게 만들지"의 기본값이 없어, 같은 원칙을 매 계획
  Guardrails 에 반복해 쓰거나 아예 빠뜨렸다. 4종을 Core 기본값으로 박되 PLAN
  Guardrails 가 항상 우선하게 해 프로젝트 정책을 덮어쓰지 않게 했다. 앞으로 깨면
  안 되는 것: 원칙 문안을 고칠 때 run-dry [16] 과 test-guidance 의 work.min.md
  배열 앵커가 **리터럴로** 일치해야 한다. 백틱 하나 차이로 앵커가 조용히
  무력화된다 (이번에 실제로 겪음).
- discarded alternatives: 프로젝트 로컬 정책 파일(scv/PRINCIPLES.md — 0.22.0 의
  표준문서 7종 제거 결정과 충돌하고 파일 없는 프로젝트엔 무효) · PLAN 템플릿
  Guardrails 예시만 두기(매 계획 반복, 실효성 낮음) · 하위호환 원칙 포함(SCV
  자신의 광범위한 후방호환과 층위 충돌 — 보류) · 데드코드 루틴 신설(이미 존재)
- path delta: Suggested path 6단계의 순서는 그대로 갔으나 두 번 되돌아갔다.
  (1) 원칙 문안을 사용자에게 승인받은 preview 와 다르게 써서, 회귀 앵커 5개가
  실제 문자열과 어긋났다 — preview 문안으로 되돌려 맞췄다. (2) 그 불일치를 처음
  확인할 때 grep 과 echo 를 AND 로 이어 검사해 실패가 삼켜졌다. 이 세션 셸이
  zsh 라 set -e 가 AND 목록의 좌변과 루프 본문에서 bash 처럼 발동하지 않는다.
  TESTS.md 의 실행 블록을 bash -euo pipefail 명시 호출 + 검사마다 fail 분기를
  붙인 형태로 바꿔, 대화형 셸이 무엇이든 게이트가 서게 했다. 계획 단계에서
  예상하지 못한 항목이며, SCV 의 다른 TESTS.md 에도 같은 위험이 있다.
- refs: scv/archive/20260811-wookiya1364-implementation-principles/PLAN.md

## [2026-08-12 09:14] wookiya1364 — 쉬운 말 먼저 (사용자 대상 출력 기본 규칙) archived

- verdict: archived
- why: 어떤 언어로 말할지는 정해져 있었지만 얼마나 쉽게 말할지는 없었다. 그래서
  계획과 보고가 길고 어려워졌고, 이해되지 않은 계획은 승인 자체가 불가능하다.
  앞으로 깨면 안 되는 것: 문구는 13개 파일에서 동일해야 한다. 회귀 가드가
  누락과 불일치를 잡지만, 문구를 고칠 때는 13곳을 함께 고쳐야 한다.
- discarded alternatives: 공통 블록 토큰 신설(각 파일에 토큰을 적어야 하므로
  파일 수는 그대로고 빌드 장치만 늘어남) · 설명이 많은 액션에만 넣기(가끔
  적용되는 규칙은 없는 규칙보다 나쁘다) · GUIDANCE 마커로 감싸기(1단계 범위가
  promote·work 외 마커를 금지)
- path delta: 계획은 "프로토콜 13개"라고 썼는데 실제 파일은 15개였다. 나머지
  둘(set-models·update)은 Language preference 자체가 없는 어댑터 소유 스텁이라
  대상에서 제외했고, 회귀 가드에 그 제외를 명시적으로 고정했다. 또 report.md 는
  해당 절이 파일 끝이라 뒤따르는 헤딩이 없어 삽입 방식과 동일성 비교 양쪽에
  예외 처리가 필요했다 — 문구 비교를 끝 빈 줄 무시로 바꿔 해결했다.
- refs: scv/archive/20260812-wookiya1364-plain-language/PLAN.md
