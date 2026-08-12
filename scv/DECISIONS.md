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

## [2026-08-12 15:07] wookiya1364 — 계획 없는 구현 PR 을 CI 가 막는다 (프로버넌스 게이트)

- verdict: adopted
- why: 세 저장소를 실제로 재 보니 "계획 없이 구현만 올라온 PR" 을 막는 장치가
  하나도 없었다. 계획 문서를 보는 워크플로가 아예 없고, check-frontmatter.sh 는
  CI 에서 실제 저장소를 검사하지 않으며, 검사 대상 glob 이 scv/promote 하나뿐이라
  work 가 아카이브를 먼저 하고 PR 을 여는 정상 경로에서는 볼 것이 없었다.
  코드를 바꾸는 PR 에 아카이브된 계획을 요구하는 쪽을 택했다 — 대표님이 막고 싶어
  한 것이 바로 "플러그인 안 쓰고 그럴듯하게 구현만 올리는" 경로이기 때문이다.
  게이트는 branch-flow.yml 안에 넣는다. 세 저장소에서 경로 필터 없이 모든 PR 에
  도는 유일한 워크플로이고, 그 체크가 이미 required_status_checks 에 올라가 있다.
- discarded alternatives:
  - 계획이 있을 때만 스키마 검사 (약한 안): 거짓 실패는 거의 없지만 막고 싶어 한
    경로가 그대로 열려 있어 목적을 달성하지 못한다.
  - 경고만 하고 막지 않기: 한동안 관찰한다는 장점은 있으나, required_status_checks
    를 이미 켠 마당에 게이트만 무력한 상태로 두는 것은 앞서 진단한 "초록이지만
    망가진 상태" 를 하나 더 만드는 셈이다.
  - 새 워크플로 파일로 분리: 경로 필터 없이 모든 PR 에 돌게 만들고 세 저장소
    ruleset 에 다시 필수 등록해야 한다. branch-flow.yml 은 그 두 조건을 이미
    충족하므로 새 파일을 만들 이유가 없다.
  - 게이트 파서를 새로 작성: lib/yaml.sh 의 yaml_get_list 가 flow/block 두 형식을
    이미 처리한다(실제 계획 8 개 중 7 개가 flow 형식). 새로 쓰면 그 지원을 잃는다.
- refs: scv/promote/20260812-wookiya1364-ci-provenance-gate/PLAN.md

## [2026-08-12 17:05] wookiya1364 — scv 명령 호출을 기계적으로 강제한다 (가드 훅 + 문서 정합)

- verdict: adopted
- why: 배포된 플러그인은 강제가 0 이다. 전부 설명문이고 모델이 안 쓰기로 고르면
  그만이다. PreToolUse 가드 훅으로 실제 거부가 가능하다는 것을 Codex 에서 재현해
  확인했고(파일이 안 만들어짐), SCV 자체 문서가 "Codex 는 안 된다"고 적어놓은 것이
  틀렸다는 것도 확인했다. 자기 차단은 영수증으로 푼다 — 호스트가 발생시키는
  이벤트로 발급하므로 모델이 위조할 수 없다. 대표님이 전체(Rule A + Rule B 둘 다
  기본 켜기)를 요구했고, 그러려면 오탐이 0 이어야 하므로 영수증 인정 범위를 15 개
  명령 전부로 넓힌다.
- discarded alternatives:
  - Rule A 만 켜고 Rule B 는 opt-in (원래 권고안): 오탐 위험은 낮지만 계획 없이
    코드만 고치는 경로가 열려 있다. 대표님이 전체를 요구해 기각.
  - Rule B 의 "status: in_progress 계획이 있으면 허용" 조건을 튜닝: 삭제로 바꿨다.
    work.sh 가 status 를 아예 안 써서 정상 작업 중에도 거짓이고(이 저장소 아카이브
    8 개 중 5 개가 아직 planned), PLAN.md 가 Rule B 면제·Rule A 수정허용이라 모델이
    한 줄 고쳐 스스로 발급하는 토큰이었다.
  - 영수증을 {work, codegen} 으로 좁게 유지: 명령이 도는데도 막히는 경우가 5 개
    생긴다. 그중 help.md:60 은 프로젝트 첫 사용을 벽돌로 만든다.
  - 빠른 경로(PROMOTE.md §1.6) 삭제: work.sh 에 --fast 를 붙여 명령으로 만드는 쪽을
    택했다. 추가만 하므로 기존 CI 단언 13 개가 그대로 통과한다.
  - 일관성 테스트를 core/tests/ 에 두기: 그 디렉터리는 배포되고 해시 고정되며,
    test-host-neutral.sh 의 금지 문자열 '/scv:' 를 검사기가 자기 안에 포함하게 돼
    자기 테스트에 걸린다. 저장소 루트 tests/ 로.
  - 토큰 allowlist 로 예외 처리: "via action:promote or by hand" 가 면제돼버린다.
    명령 토큰의 존재는 위반과 양의 상관이다. 명시적 file:line 앵커로.
  - 가드를 fail-closed 로: 호스트가 이미 그 경로에서 열린 채 실패하므로 적대적
    강도는 거의 안 오르는데, 가드 버그 하나가 모든 프로젝트의 모든 쓰기를 벽돌로
    만든다. 규칙에 명시적으로 걸린 경우만 닫는다.
- refs: scv/promote/20260812-wookiya1364-forced-invocation-guard/PLAN.md
