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

## [2026-08-13 11:20] wookiya1364 — 데크를 다크 전용으로 재설계하고 다이어그램을 읽히게 만든다

- verdict: adopted
- why: 대표님이 데크를 "쓸 엄두가 안 난다" 고 했고, 재보니 다이어그램이 자연 크기의
  절반(배율 0.483)으로 찌그러져 16px 글자가 7.7px 로 나오고 있었다. 색 문제로 접수됐지만
  가장 큰 원인은 크기였다. 색은 promote.md 가 모델에게 붙여넣게 한 팔레트 한 줄이
  렌더러를 이기고 SVG 에 구워져서, 라이트·다크 양쪽 다 깨져 있었다. 대표님 자신의
  DesignSystem 토큰과 크롬을 이식하고 다크 전용으로 간다.
- discarded alternatives:
  - 라이트·다크 둘 다 제대로 고치기: 대표님 deck 스킬이 "dark 테마" 로 못 박고 있어
    기각. 화면은 다크 하나, 종이만 라이트로.
  - 인쇄 포기: 대표님 덱은 인쇄를 안 하지만 SCV 데크는 PR 옆 archive/ 에 놓이고
    리뷰어가 인쇄한다. @media print 는 화면에서 도달 불가능하므로 대표님이 거부한
    "독자가 고를 수 있는 두 번째 팔레트" 와 다른 물건이다.
  - promote.md 의 작성 지시문에서 팔레트 고치기: 7 곳을 고쳐야 하고 새로 만드는
    계획만 고쳐지며 기존 아카이브는 영원히 깨진 채로 남는다. 그리고 그 지시문이
    존재하는 이유인 GitHub 렌더링이 회귀한다.
  - 라이트·다크 SVG 두 벌 굽기: 31.6KB SVG 가 두 배가 되고 크롬을 두 번 띄워야 하며
    test-deck-static-mermaid.sh 의 embedded diagrams=1 계약을 깬다.
  - CSS !important 로만 덮기: 실험으로 기각. 특이도 (1,3,1) + !important 도 rect 의
    인라인 style="fill:#FFE082 !important" 를 못 이겼다. 인라인 속성 제거만이 이긴다.
  - 중립색 primary: 조사팀 권고였으나 대표님이 "장미색으로 해라, 공개제품이여도
    괜찮다" 고 확인. 다만 원본은 글자로 2.50:1 이라 같은 색상에서 밝기만 올린
    글자용(#fc7184, 7.39:1)을 따로 둔다.
  - Inter 폰트 임베드: 한글이 없어 한 문장 안에서 글꼴이 갈린다. 한글까지 넣으면
    121KB 파일이 3~7 배로 붓는데 promote 마다 커밋된다. 시스템 스택으로.
- refs: scv/promote/20260813-wookiya1364-deck-redesign/PLAN.md

## [2026-08-14 12:10] wookiya1364 — 승격 대기 판정과 벤더 게이트

- verdict: adopted
- why: 두 곳 다 "초록인데 망가져 있던" 것이고 사람이 손으로 때워서 넘어갔다. 대기
  판정은 자작 조건을 세 번째로 만드는 대신 머지를 결정하는 주체(GitHub 의
  `mergeStateStatus`)에게 묻는다. 벤더링은 금지가 아니라 선언으로 만든다 — Core
  계약이 바뀌면 봇이 못 따라오는 경우가 실제로 있다.
- discarded alternatives:
    - `mergeStateStatus == CLEAN` 하나만 요구: 반대쪽 함정. 건너뛴 매트릭스
      자리표시자가 rollup 을 계속 `UNSTABLE` 로 붙잡아 아무것도 머지되지 않는다.
      그래서 조건이 셋이다(실패 없음 · 대기 없음 · `BLOCKED` 아님).
    - 대기 시간만 늘리기(120초 → 900초): 개수 세기가 틀린 것이므로 더 오래 세도
      같은 답이 나온다. 실제로 count 는 3초 만에 1이 됐다.
    - 자리표시자 이름을 걸러내기: GitHub 의 보고 형식에 의존하게 된다. 형식이 바뀌면
      조용히 옛 버그로 돌아간다.
    - 손 벤더링을 완전 금지: Core 계약이 바뀌면 봇의 자동 벤더링이 실패한다.
      막다른 길이 된다.
    - 문서로만 규정하기: 0.25.0 과 0.26.0 에서 같은 일이 반복됐다. 기계가 잡지
      않으면 다음에도 같은 자리에서 같은 실수를 한다.
    - `[no-vendor: ]` 같은 새 표지 형식: 기존 `[no-plan: <이유>]` 와 모양을 맞춘다.
      배울 관례를 둘로 늘리지 않는다.
    - 워크플로 블록을 문자열로 검사: 이 블록은 두 번 다 문장으로는 맞게 읽혔다.
      틀린 건 특정 입력에서의 동작이므로 블록을 잘라내 그대로 실행한다.
    - 게이트 테스트를 스텁 diff 로: 검증 대상에 diff 를 읽는 방식이 포함된다.
      스텁은 git 이 아니라 내가 이해한 git 을 검증하게 된다.
    - 래퍼 워크플로 스텝을 같은 릴리스에 함께 넣기: 새 스크립트가 벤더링되기 전이라
      CI 가 "파일 없음"으로 빨개진다. Core → 봇 동기화 → 래퍼 순서로 나눈다.
- refs: scv/promote/20260814-wookiya1364-release-machinery/PLAN.md

## [2026-08-14 12:40] wookiya1364 — 승격 대기 판정과 벤더 게이트 archived

- verdict: archived
- why: 승격의 머지 시점 판정을 자작 조건에서 GitHub 의 `mergeStateStatus` 로 옮겼다.
  단 그 값 하나로는 부족하다 — 건너뛴 매트릭스 자리표시자가 rollup 을 `UNSTABLE` 로
  붙잡으므로 세 조건(실패 없음·대기 없음·`BLOCKED` 아님)이 함께 성립해야 한다.
  벤더링은 `[manual-vendor: <이유>]` 선언 없이는 봇 브랜치와 릴리스 체인에서만
  통과한다. 앞으로 깨지면 안 되는 것: 릴리스 체인과 봇 브랜치는 어떤 게이트도 막지
  않는다. 막히면 모든 릴리스가 선다.
- path delta: as planned. 다만 계획에 없던 두 가지를 구현 중에 발견해 고쳤다 —
  워크플로 `run:` 블록 주석에 넣은 매트릭스 표기를 Actions 가 치환한다는 것(주석에서
  제거), 그리고 게이트 테스트 픽스처의 `mkrepo` 가 명령 치환 안에서 돌아 카운터
  증가가 버려진다는 것. 후자는 모든 픽스처가 같은 디렉터리를 덮어써서 8개 게이트가
  건강하다고 잘못 보고되게 만들었다. 이름을 인자로 바꿔 고정했다.
- refs: scv/archive/20260814-wookiya1364-release-machinery/PLAN.md

## [2026-08-18 10:30] wookiya1364 — sync 자동화와 가드 실효 회복

- verdict: adopted
- why: sync 의 `.scv-backup` 은 같은 스크립트의 은퇴 패스가 이미 부정하는 복구
  경로다("git history is the recovery path") — 사본 대신 더티 거부로 바꾼다.
  "update 하면 자동 최신화"는 update 안에서는 불가능하므로(버전별 플러그인 캐시:
  update 시점의 sync 는 옛 payload 로 돈다) 다음 액션이 스탬프 격차를 스스로
  메운다. 가드 버그 5건은 문서를 먼저 사실대로 고쳐 배포했고 이번에 동작을 고친다.
- discarded alternatives:
    - update 액션이 sync 를 직접 호출: 리로드 전에는 새 payload 에 손이 닿지
      않아 옛 템플릿을 다시 깔고 "최신화 완료"라고 찍는다. 초록인데 틀린 것.
    - 백업을 남기되 위치만 개선: 추적 안 되는 사본이 계속 쌓이고, git 이 이미
      이전 내용을 더 잘 보여준다. 파일 안에 복구 경로 답이 두 개인 상태 지속.
    - 더티 파일도 백업 후 덮어쓰기: 사용자가 눈치 못 채는 소실 경로. 거부하고
      이름을 말하는 쪽이 정직하다.
    - pre-2.x 레거시까지 자동 마이그레이션: 2.0.0 은퇴 패스가 사용자 문서 7종을
      삭제하는데 프로토콜은 삭제 전 DECISIONS.md 이관 제안을 요구한다. 자동
      실행은 그 대화를 건너뛴다. 2.x→2.y 만 자동.
    - 가드 저장소 사용 불가를 fail open 으로: 모델이 Bash 로 저장소 권한을 부술
      수 있으므로 fail open = 가드 해제. 닫힌 채 사유만 정직하게 바꾼다.
    - SCV_GUARD_SCRIPTS 를 정규식/글로브로: 고정 문자열 비교의 단순함을 잃고
      이스케이프 버그 표면이 생긴다. 콜론 분해 + 항목별 기존 비교가 최소 변경.
    - T21 을 아카이브된 계획 문서로 재지정: 문서는 또 이동한다. 스크립트 둘을
      직접 비교하면 조건 없이 항상 돈다.
- refs: scv/promote/20260818-wookiya1364-sync-autopilot/PLAN.md

## [2026-08-18 14:20] wookiya1364 — sync 자동화와 가드 실효 회복 archived

- verdict: archived
- why: sync 의 복구 경로를 git 하나로 통일했다 — 사본 디렉터리 대신, git 이 되살릴
  수 없는 파일은 이름을 불러 거부한다. 판정은 `git status` 가 아니라 HEAD 와의
  내용 비교다: status 는 심링크와 assume-unchanged 에서 거짓말을 하고, 실제로
  심링크 관통 덮어쓰기로 저장소 밖 파일이 파괴되는 것을 적대검증이 재현했다.
  낡은 템플릿은 액션 시작 시 자동으로 메워지되 위로만 간다. 거부가 하나라도 있으면
  스탬프는 전진하지 않는다 — 전진시키면 이주가 완료된 척하며 영원히 재시도가 없다.
  앞으로 깨지면 안 되는 것: 스탬프는 게이트다. 거부와 스탬프 전진이 공존하면 자동
  최신화 전체가 거짓 수렴한다.
- path delta: 계획 경로대로 갔으나 적대검증이 설계 셋을 바꿨다. (1) 더티 판정을
  상태 조회에서 HEAD 내용 비교로 — 계획은 `git status --porcelain` 을 명시했지만
  그 방식은 심링크·assume-unchanged 를 통과시킨다. (2) 스탬프를 거부-무전진
  게이트로 — 계획에는 없던 수렴 조건이다. (3) 은퇴 문서 삭제에 거부를 넣었다가
  되돌렸다 — 기록된 사용자 결정(무백업 삭제, 프로토콜의 사전 이관 제안)과 충돌해서,
  규칙 주석에 예외를 명시하는 것으로 답했다. 그리고 재귀 가드를 프로세스 트리
  전체로 export 했다 — 액션 하나가 헬퍼마다 검사를 반복하고 있었다.
- refs: scv/archive/20260818-wookiya1364-sync-autopilot/PLAN.md

## [2026-08-18 14:50] wookiya1364 — 회귀 계약 보수 — 성립 불가 4건의 내구성 있는 재표현

- verdict: adopted
- why: 영원히 빨간 아카이브 4건(커밋 전 상태 단언 3 + 부재 스크립트 1)을 보수
  슬러그 하나가 supersede 한다. 기능은 넷 다 살아 있으므로 검증을 버리지 않고
  내구성 있는 형태로 옮긴다 — 대표님 선택.
- discarded alternatives:
    - 후속 없이 4건 obsolete 마킹: 회귀는 초록이 되지만 살아 있는 기능 4개의
      검증이 사라지고, obsolete 의미("더 이상 유지 안 함")와 어긋난다.
    - 그대로 두기: 매번 "기존 4건 무관"을 확인해야 하고, 진짜 회귀가 그 사이에
      섞이면 놓치기 쉽다.
    - 슬러그 4개로 각각 대체: 아카이브 4개가 늘어나는 비용 대비 이득 없음 —
      네 계약이 한 파일에 들어간다.
    - 아카이브 TESTS.md 본문 직접 수정: 프로토콜 금지. frontmatter 3필드
      supersede 경로가 허용된 유일한 길이다.
- refs: scv/promote/20260818-wookiya1364-regression-contract-repair/PLAN.md

## [2026-08-18 15:20] wookiya1364 — 회귀 계약 보수 archived

- verdict: archived
- why: 영원히 빨간 아카이브 4건을 보수 슬러그 하나가 supersede 했다. 네 기능의
  검증은 내구 형태(내용 존재·투영 생존·실존 스위트 호출)로 이어지고, 옛 4건은
  frontmatter 3필드만으로 obsolete 처리됐다(본문 md5 불변 확인). 내구성은
  직접 증명했다: 동일 내용을 미커밋 트리와 전부-커밋 트리에서 실행해 동일 판정.
  앞으로 깨지면 안 되는 것: TESTS 의 How-to-run 은 트리 내용에만 의존한다 —
  커밋 상태 단언이 들어오는 순간 그 계약은 아카이브되며 죽는다.
- path delta: as planned. 다만 구현 중 다섯 번째 자기함정 테스트를 만들 뻔했다 —
  PROMOTE.md 에 넣은 규칙 문장의 "the uncommitted working tree" 가
  test-sync-dirty 의 카나리아 "uncommitted work" 와 부분 일치해서, 완전히 성공한
  덮어쓰기가 실패로 보고됐다. 카나리아 전부를 실문서에 나타날 수 없는
  CANARY-*-9f3a 토큰으로 바꿨다. 그리고 ci-provenance-gate 의 아카이브 status 가
  done 이 아니라 planned 였다(당시 절차 누락의 흔적) — 마킹 스크립트가 done 만
  바꾸다 걸려서 발견했고, status 무관 치환으로 처리했다.
- refs: scv/archive/20260818-wookiya1364-regression-contract-repair/PLAN.md

## [2026-08-18 16:40] wookiya1364 — effort governor — 작업 무게에 맞춘 자동 실행 조절

- verdict: adopted
- why: 가벼운 작업이 ultra 세션에서 낭비되는 문제를, 사용자 다이얼을 건드리지
  않고 실행 방식으로 푼다. 판정은 아카이브 14건 백테스트를 통과한 3규칙(13/14,
  과소 1·과대 0)만 싣고, 6레벨은 밴드×단계의 결정적 격자로 배치한다. 기본 auto
  (개입 0)는 대표님이 객관식으로 확정.
- discarded alternatives:
    - 권고 한 줄만(advisory): 대표님이 기각 — "켜나마나". 보고 취소하고 다시
      실행하는 왕복이 절약분보다 비싸다.
    - 세션 다이얼 자동 변경: 두 호스트 모두 모델에게 권한이 없고, 있어도
      사용자 소유가 맞다.
    - 시나리오 수·Guardrails 수 기반 판정: 백테스트가 기각 — 0시나리오 heavy
      4건, 21시나리오 standard 1건, guardrails 는 역상관.
    - light 밴드 예측: 실측 0건. 지어낸 문턱은 비싼 방향 미스가 된다.
    - raw≥10000B 를 orchestration 규칙으로: 이웃과 1,140B 차 단일점 적합 —
      규칙 대신 승급 장전 힌트(2-of-3)로 강등.
    - 6레벨을 각각 확률 예측: 검증 불가능한 문턱 5개를 지어내는 일 — 격자
      (결정적) + 사다리(실측 신호)로 전 레벨 도달을 보장하는 쪽이 정직하다.
- refs: scv/promote/20260818-wookiya1364-effort-governor/PLAN.md

## [2026-08-18 17:30] wookiya1364 — effort governor archived

- verdict: archived
- why: 판정은 스크립트(결정적 3규칙, 백테스트 13/14), 집행은 프로토콜(밴드×단계
  격자·상향 승급), 통제는 사용자(auto|ask|off + frontmatter 선언 + 그 자리
  한마디). 세션 다이얼은 끝내 건드리지 않는다 — 절약의 지배항은 오케스트레이션
  억제였다. 앞으로 깨지면 안 되는 것: standard 밴드에서 팬아웃 금지, 검증 중
  강등 금지, off 의 완전 무동작.
- path delta: as planned — 그리고 이 계획 자체가 거버너의 첫 판정 대상이었다.
  heavy(armed) 판정에 따라 팬아웃 대신 단일 강검증으로 갔고, 위임 에이전트
  스폰이 두 번 무산되자(산출물 0) 검증을 인라인으로 직접 수행했다. 그 검증이
  결함 3건을 잡았다: CRLF 가 frontmatter 신호를 숨기고(비싼 방향 미스), raw
  경로 순회가 저장소 밖 파일을 계측하고(20KB 실증 — 픽스처에 scv/raw 가 없어
  우연히 안전해 보였던 것), 무효 선언이 소리 없이 사라졌다. 셋 다 수정 후
  T10 으로 고정.
- refs: scv/archive/20260818-wookiya1364-effort-governor/PLAN.md

## [2026-08-18 16:20] wookiya1364 — .env.example.scv 자동 최신화 — root 불가침의 명명된 예외

- verdict: adopted
- why: 옛날에 hydrate 한 프로젝트가 SCV_EFFORT_MODE 같은 새 .env 옵션의 문서
  블록을 영영 못 받는 전파 공백. 예시 파일은 실사용 설정(.env)과 분리돼 있어
  손실 표면이 작고, 0.28.0 의 HEAD 대조·DIRTY 거부 장치를 그대로 재사용하면
  "git 이력이 유일한 복구 경로" 결정과도 일관된다. 무조건 최신 + autosync
  자동 전파, 별도 마이그레이션 명령 없음.
- discarded alternatives:
  - /scv:help 진단이 구버전을 감지해 갱신 안내만: 발견 문제는 해결 못 하고
    사용자 행동에 의존 — 강제 마이그레이션 결정에 미달.
  - sync 가 차이를 감지해 비파괴 공지만: 같은 이유로 기각.
  - 있는 파일만 갱신(부재 시 방치): 삭제로 예외를 회피하는 경로가 열리고
    "무조건 최신" 결정과 어긋남 — 재생성으로 확정.
  - 이 파일만 스탬프 예외 전진(거부 시 조용히 넘어감): 거부가 재시도되지 않아
    낡은 파일이 영영 방치되는 false-convergence — 0.28.0 이 막은 바로 그 구멍.
- refs: scv/promote/20260818-wookiya1364-env-example-autorefresh/PLAN.md

## [2026-08-18 16:40] wookiya1364 — env-example-autorefresh archived

- verdict: archived
- why: sync 가 루트 .env.example.scv 를 최신 템플릿으로 갱신한다 — root 불가침의
  단 하나 명명된 예외. 새 코드는 정책 case 한 줄과 process_template_file 호출
  하나뿐, 거부·재생성·심볼링크 스킵·스탬프 게이트는 전부 기존 장치가 그대로
  일했다. 앞으로 깨지면 안 되는 것: .env 불가침, 예외의 단일성(다른 루트 파일
  확장 금지), 거부 시 스탬프 미전진.
- path delta: as planned — Red 13건 → Green 1회 반복 23/23. 누적 회귀에서
  sync-autopilot 계약이 러너 안에서만 붉었고, 원인은 이 변경이 아니라
  regression.sh 가 scv_init_paths 를 타며 export 한 SCV_AUTOSYNC_RUNNING=1 이
  자식 시나리오로 누수되는 기존 결함(오염 환경 주입으로 10/11 재현, 깨끗한
  환경 21/21). regression 으로 트리아지, 러너 수정은 후속 플랜.
- refs: scv/archive/20260818-wookiya1364-env-example-autorefresh/PLAN.md
## [2026-08-18 17:05] wookiya1364 — 회귀 러너의 autosync 가드 누수 — 시나리오는 깨끗한 환경에서 돈다

- verdict: adopted
- why: 러너가 재진입 방지용으로 export한 SCV_AUTOSYNC_RUNNING=1이 자식
  시나리오에 상속되어, autosync 훅을 검증하는 계약이 러너 안에서만 죽는다
  (오염 주입 10/11, 깨끗한 환경 21/21로 실증). 러너가 시나리오를 실행할 때
  그 내부 플래그 하나만 지우고 실행한다 — 결함이 있는 곳만 고치는 최소 수정.
- discarded alternatives:
  - 러너 + 스위트 양쪽 보강(test-autosync call()도 자체 정화): 스위트가
    호출자의 누수를 가리면 다른 곳의 같은 버그를 뒤늦게 발견한다 — 기각,
    맹점은 Risk로 기록.
  - scvroot.sh의 export 자체를 옮기거나 제거: 한 액션 안의 헬퍼 중복 체크
    방지라는 본래 목적이 유효하다 — 기각 (불변 조건 1).
- refs: scv/promote/20260818-wookiya1364-regression-runner-env-leak/PLAN.md

## [2026-08-19 09:20] wookiya1364 — regression-runner-env-leak archived

- verdict: archived
- why: 러너가 시나리오를 깨끗한 환경에서 돌린다 — 자기가 켠 재진입 방지 플래그
  하나만 지우고(env -u), 사용자 env·재진입 방지·--ci·스킵 그래프는 전부 그대로.
  수정은 regression.sh 실행 지점 한 곳(+헬퍼 추출), 스위트·scvroot는 무수정.
  앞으로 깨지면 안 되는 것: 시나리오 환경에 러너 내부 플래그 부재, 제거 대상의
  단일성(사용자 env 통과), 러너 자신의 1회 수렴.
- path delta: as planned — Red(T1 누수·T4 실계약 실패) → env -u 한 줄 수정으로
  Green 9/9. 검증 중 식별한 사실 하나: 누적 회귀를 플러그인 캐시 runner로
  돌리면 수정이 반영될 수 없다 — repo runner(core/scripts/regression.sh)로
  재실행해 11/11 복원을 확인했다. 이 구분은 앞으로도 러너 자체를 고치는
  플랜의 검증 함정이다.
- refs: scv/archive/20260818-wookiya1364-regression-runner-env-leak/PLAN.md

## [2026-08-21 10:58] wookiya1364 — 쉬운 말 2단계 — 답의 모양, 매 턴 전달, .env 스위치

- verdict: adopted
- why: 0812 의 "쉬운 말 먼저" 규칙은 문체 조언이라 답의 모양을 정하지 않았고,
  /scv:* 명령 안에만 있어 일반 대화에는 전달되지 않았으며, 어겨도 검사가 없었다.
  규칙을 "1~2문장 → 예시 → 코드값 금지 → 자세한 건 원하면" 의 답의 모양으로
  다시 쓰고, 매 메시지마다 도는 기록 훅이 요약을 모델에게 보여주며(Claude Code·
  Codex 모두 훅 stdout 을 컨텍스트로 넣는다 — 공식 문서 확인), SCV.md 안내를
  더한다. `.env` `SCV_PLAIN_LANGUAGE` 로 끌 수 있다 — 기본 on, off 만 꺼짐.
- discarded alternatives:
  - 명령 안에서만 규칙 유지(훅 주입 없음): 일반 대화가 그대로 빠진다 — 기각.
  - 훅 없이 루트 지침 파일 안내 한 줄만: SCV 가 CLAUDE.md/AGENTS.md 를 안
    건드리는 경계상 사용자가 직접 넣어야 해 전달이 보장되지 않는다 — 훅과
    병행(둘 다)으로 채택, 단독은 기각.
  - 코드값 전면 금지(다음 명령·생성 파일 경로까지 숨김): 명령 흐름이 느려진다
    — 기각. 설명은 쉬운 말, 필수 식별자는 요약 뒤에 그대로.
  - claude -p 자동 스모크를 회귀 스위트에 포함: 모델 호출이 느리고 흔들린다 —
    기각. 사람 판정 3건으로 닫는다.
  - Codex 래퍼 등록을 뒤로 미루기: 기각 — 양쪽 래퍼를 같은 웨이브에 켠다.
- refs: scv/promote/20260821-wookiya1364-plain-answers-enforcement/PLAN.md
- conversation: scv/conversations/20260821-103405-plain-answers-enforcement.md

## [2026-08-21 13:05] wookiya1364 — 쉬운 말 2단계 — 답의 모양, 매 턴 전달, .env 스위치 archived

- verdict: archived
- why: "쉬운 말" 규칙이 지켜지지 않던 세 원인을 한 번에 닫았다 — 규칙을 답의
  모양(먼저 1–2문장 → 예시 → 묻기 전 코드값 금지 → 자세한 건 원할 때)으로
  다시 쓰고(13개 프로토콜, 제목 유지·본문 동일), 매 턴 도는 기록 훅이 그 요약을
  stdout 으로 내 모델 컨텍스트에 넣으며(Claude Code·Codex 공식 문서 확인),
  SCV.md 안내와 `.env` `SCV_PLAIN_LANGUAGE`(기본 on, off 만 꺼짐)를 더했다.
  앞으로 깨지면 안 되는 것: 절 제목 불변(누적 회귀 T4), 13곳 본문 동일, 훅의
  비차단·journal 비오염, off 의 단일 의미, TEMPLATE_VERSION 동반 상승.
  사람 판정 3/3 통과(CHECK.md) — 단, 샘플 3건이지 자동 보장이 아니다.
- path delta: 거의 계획대로. 두 가지 이탈 — (1) `core/contracts/guard.md` 의
  예외 앵커 3개(줄 번호 기준)가 본문이 7줄 길어지며 어긋나 옮겼다(scope 밖 파일,
  기능 변경 아님; 줄 번호 앵커는 프로토콜을 늘릴 때마다 따라 움직여야 한다).
  (2) 누적 회귀 1건(deck-redesign)이 저장소 루트의 `.env` `SCV_LANG` 에 오염돼
  실패했다 — 치우니 통과. scv-core 자신은 `.env` 없이 두는 편이 안전하다.
  effort: orchestration 판정이었지만 단일 구현자 + 단일 검증으로 충분했다(승격 0).
- refs: scv/archive/20260821-wookiya1364-plain-answers-enforcement/PLAN.md
- conversation: scv/conversations/archive/20260821-103405-plain-answers-enforcement.md

## [2026-08-21 13:10] wookiya1364 — 쉬운 말 문장 수 스위치 — SCV_PLAIN_MAX_SENTENCES (기본 2)

- verdict: adopted
- why: "먼저 1–2문장" 의 2 가 고정돼 있어 팀마다 다른 선호를 담을 수 없다.
  `.env` `SCV_PLAIN_MAX_SENTENCES=<n>` 로 상한을 정하고, 없음/이상값은 2 —
  같은 0.31.0 판으로 함께 배송한다.
- discarded alternatives:
  - 줄 수 단위: 화면 폭에 따라 달라져 모델이 지킬 수 없다 — 기각, 문장 수로.
  - 어제 PR(#103)에 끼워 넣기: 이미 CI 중이라 그대로 머지하고 작은 후속 계획으로 —
    기각(별도 계획).
  - TEMPLATE_VERSION 2.4.0: 2.3.0 이 미출시라 같은 판 — 기각(어제 계약 T4 가 2.3.0 고정).
- refs: scv/promote/20260821-wookiya1364-plain-sentence-cap/PLAN.md
- conversation: scv/conversations/20260821-130311-plain-sentence-cap.md

## [2026-08-21 13:40] wookiya1364 — 회귀 러너의 경로 표시 누수 — 시나리오는 자기 scv 경로를 본다

- verdict: adopted
- why: 어제 보관한 plain-answers-enforcement 계약이 누적 회귀에서 처음 돌며
  러너 안에서만 T6(run-dry [19]) 실패 — 러너가 export 한 SCV_DIR·RAW_DIR·
  STATE_FILE·PROMOTE_DIR·ARCHIVE_DIR 가 시나리오의 임시 프로젝트에 상속된 탓.
  0818 의 SCV_AUTOSYNC_RUNNING 누수와 같은 자리·같은 방식(env -u)으로 러너만 고친다.
- discarded alternatives:
  - scvroot 의 export 제거: 한 액션 안의 헬퍼 중복 체크 방지가 유효 — 기각(0818 결정 유지).
  - 별도 PR 로 나중에: 그동안 누적 회귀가 1건 빨간불 — 기각, 같은 PR 에 함께.
- refs: scv/promote/20260821-wookiya1364-regression-runner-path-leak/PLAN.md

## [2026-08-21 13:55] wookiya1364 — 쉬운 말 문장 수 스위치 — SCV_PLAIN_MAX_SENTENCES (기본 2) archived

- verdict: archived
- why: "먼저 1–2문장"의 상한을 `.env` `SCV_PLAIN_MAX_SENTENCES=<n>` 로 정할 수
  있다 — 없음/이상값은 2, `off` 가 우선. 13개 프로토콜 본문에 한 문장(제목·앵커·
  동일성 유지), 훅은 숫자를 치환해 찍고(`1` 은 "one sentence"), 템플릿 두 곳 한 줄,
  TEMPLATE_VERSION 2.3.0 유지(같은 판). 앞으로 깨지면 안 되는 것: 양의 정수만
  유효, 기본 2, off 우선, 어제 계약의 앵커 `1–2 sentences` 는 기본값 출력에 남는다.
- path delta: as planned — guard.md 앵커 3개를 +2줄 옮긴 것까지 계획에 적힌
  대로. 동시 실행(테스트 블록 ∥ 누적 회귀)에서 git worktree 가 겹쳐 T4 가 한 번
  거짓 실패했다 — 단독 재실행으로 통과 확인. 무거운 검증 두 개는 같은 저장소에서
  동시에 돌리지 않는다.
- refs: scv/archive/20260821-wookiya1364-plain-sentence-cap/PLAN.md
- conversation: scv/conversations/archive/20260821-130311-plain-sentence-cap.md

## [2026-08-21 13:56] wookiya1364 — 회귀 러너의 경로 표시 누수 — 시나리오는 자기 scv 경로를 본다 archived

- verdict: archived
- why: 러너가 export 한 경로 표시 5개가 시나리오에 상속돼 임시 프로젝트 안 헬퍼가
  이 저장소의 scv/ 를 봤다 — 보관 계약이 run-dry 를 품으면 러너 안에서만 죽는
  조건. run_scenario_clean 이 자기 표시 6개(autosync 가드 + 경로 5개)만 빼고
  시나리오를 돌린다. 사용자 env 는 그대로. 앞으로 깨지면 안 되는 것: 제거 목록의
  단일성(러너 자신의 표시뿐), 러너 프로세스 자신은 표시를 유지.
- path delta: as planned. scvroot 가 표시를 더 export 하면 재발한다 — 목록이 두
  곳에 있다는 점은 Risk 로만 기록.
- refs: scv/archive/20260821-wookiya1364-regression-runner-path-leak/PLAN.md
- conversation: scv/conversations/archive/20260821-134035-regression-runner-path-leak.md

## [2026-08-21 14:35] wookiya1364 — run-dry 배치 가드 — 래퍼 투영에서도 TEMPLATE_VERSION 검사가 돈다

- verdict: adopted
- why: 0.31.0 의 run-dry [15q] 가 저장소 배치(루트 TEMPLATE_VERSION 복사본)를 전제해
  Claude 래퍼의 core-sync 검증이 실패, 봇 PR 이 안 열렸다. 루트 복사본이 있을 때만
  비교하고 없으면 통과 — 테스트는 페이로드 배치를 전제해야 한다.
- discarded alternatives:
  - 래퍼 투영을 바꿔 루트 복사본을 두기: 래퍼 두 곳을 고쳐야 하고 원인은 core 의
    단언이다 — 기각.
  - 단언 삭제: scv-core 안에서의 일치 검사는 가치가 있다 — 기각(조건부 유지).
- refs: scv/promote/20260821-wookiya1364-run-dry-layout-guard/PLAN.md

## [2026-08-21 14:55] wookiya1364 — run-dry 배치 가드 — 래퍼 투영에서도 TEMPLATE_VERSION 검사가 돈다 archived

- verdict: archived
- why: Core 의 테스트는 래퍼가 그대로 돌린다 — 저장소 배치(루트 TEMPLATE_VERSION
  복사본, `core/TEMPLATE_VERSION` 심볼릭 링크)를 전제한 단언 하나가 Claude 래퍼의
  core-sync 검증을 막았다. 루트 복사본이 있을 때만 비교하고 없으면 단일 복사본
  배치로 통과. 앞으로 깨지면 안 되는 것: 페이로드를 한 디렉터리에 펼친 배치
  (cp -RL, 부모에 TEMPLATE_VERSION 없음)에서 run-dry FAIL 0.
- path delta: as planned — 단, T2 하네스의 첫 판은 `cp -R` 이라 심볼릭 링크가
  끊겨 35건 거짓 실패했다(`core/TEMPLATE_VERSION → ../TEMPLATE_VERSION`); `cp -RL`
  로 역참조해야 래퍼 배치가 된다. 주석의 호스트 이름 한 단어도 host-neutral 검사에
  걸려 지웠다.
- refs: scv/archive/20260821-wookiya1364-run-dry-layout-guard/PLAN.md
- conversation: scv/conversations/archive/20260821-141947-run-dry-layout-guard.md

## [2026-08-21 16:05] wookiya1364 — 기록 훅의 바이트 자르기가 한글을 반으로 — journal 은 항상 온전한 UTF-8

- verdict: adopted
- why: on-stop.sh 의 tail -c 4000 이 한글 한 글자 중간에서 끊겨 일지 첫머리에 깨진
  바이트를 남기고, 편집기는 그 하나로 파일 전체를 잘못 읽었다(실제 프로젝트 실측:
  59KB 중 1곳). 캡 뒤 반쪽 시퀀스를 떨어낸다 — iconv -c(출력으로 판단), 없으면
  python3, 둘 다 없으면 원문.
- discarded alternatives:
  - 캡을 글자 단위로 다시 구현(awk/bash 로 UTF-8 경계 계산): 훅에 파서를 넣는 셈 —
    기각, 표준 도구로 떨어내는 쪽이 단순하다.
  - 캡 제거: 일지 비대화 — 기각.
- refs: scv/promote/20260821-wookiya1364-journal-utf8-tail/PLAN.md
- conversation: scv/conversations/20260821-154845-journal-utf8-tail.md

## [2026-08-21 16:20] wookiya1364 — 기록 훅의 바이트 자르기가 한글을 반으로 — journal 은 항상 온전한 UTF-8 archived

- verdict: archived
- why: 바이트 단위 캡(tail -c)은 멀티바이트 글자를 반으로 자른다 — 일지 첫머리의
  깨진 바이트 하나가 편집기에서 파일 전체를 깨진 것처럼 보이게 했다. 캡 뒤 반쪽
  시퀀스를 떨어낸다(iconv -c 는 바이트를 버리면 exit 1 → 출력으로 판단; 없으면
  python3; 둘 다 없으면 원문). 앞으로 깨지면 안 되는 것: 긴 다국어 답변 뒤 일지가
  유효한 UTF-8, 꼬리 생존, 비차단.
- path delta: as planned — 단, 첫 구현은 iconv 의 exit 1 을 실패로 보고 원문으로
  되돌려 테스트가 빨간불이었다. 실제 일지 4건(ai_tm_center 1, DMN-prototype 3)은
  반쪽 바이트(1·3·2·5개)만 지워 복구했다.
- refs: scv/archive/20260821-wookiya1364-journal-utf8-tail/PLAN.md
- conversation: scv/conversations/archive/20260821-154845-journal-utf8-tail.md

## [2026-08-21 16:50] wookiya1364 — PR·보고 첨부는 이번 슬러그 것만 — SCV_ATTACHMENTS_SCOPE (기본 slug)

- verdict: adopted
- why: PR·Slack 에 붙는 영상이 테스트 결과 폴더의 "마지막 실행" 전체라 남의 기능
  영상이 올라갔다(사용자 실측, 스크립트 확인). 기본을 이번 슬러그 것만으로 바꾸고
  `.env` `SCV_ATTACHMENTS_SCOPE=all` 로만 옛 동작. 0건이면 그 계획의 테스트를 한 번
  재실행해 이번 영상을 만든다. 보고는 `--slug`, 없으면 진행 중 계획 1개 추론,
  아니면 전부+알림.
- discarded alternatives:
  - 프로토콜 문구로만 "PR 직전에 슬러그 spec 재실행" 지시: 모델이 잊으면 그대로
    재발 — 기각, 스크립트가 결정론적으로 거른다.
  - 0건이면 첨부 없이 알림만: 영상 없는 PR 이 생긴다 — 기각(사용자 선택: 재실행).
  - 0건이면 예전처럼 전부: 지금 불편의 원인 — 기각.
  - 보고는 `--slug` 필수: 명령이 길어진다 — 기각, 추론 + 안전 폴백.
- refs: scv/promote/20260821-wookiya1364-slug-scoped-attachments/PLAN.md

## [2026-08-21 17:40] wookiya1364 — PR·보고 첨부는 이번 슬러그 것만 — SCV_ATTACHMENTS_SCOPE (기본 slug) archived

- verdict: archived
- why: 첨부는 폴더가 아니라 계획을 따른다 — 기본 slug 범위(경로에 슬러그 포함),
  0건이면 그 계획의 How-to-run 을 한 번 재실행, 보고는 --slug/진행 중 계획 1개 추론/
  전부+알림 폴백, `all` 로만 옛 동작. 공통 로직은 lib 한 곳. 앞으로 깨지면 안 되는
  것: all 모드 = 옛 출력 그대로, 재실행은 1회·타임아웃·dry-run 제외, 업로드·보관
  정책 불변.
- path delta: as planned — 두 가지 덤. (1) run-dry 의 옛 pr-helper 픽스처(일반 파일명)는
  명시적 all 로 돌리고 slug 기본값 단언 4개를 더했다. (2) collect-artifacts 의 emit 이
  빈 슬롯(스크린샷 없음)에서 set -e 로 중단돼 영상을 못 내던 잠복 결함을 발견·수정 —
  새 테스트가 그 경로를 처음 밟았다. lib 의 필터 함수도 `read` 의 EOF 반환값 때문에
  set -e 호출자에서 죽어 `return 0` 을 명시했다.
- refs: scv/archive/20260821-wookiya1364-slug-scoped-attachments/PLAN.md

## [2026-08-24 09:49] wookiya1364 — 설정 파일은 항상 있고, 모든 키가 보인다

- verdict: adopted
- why: 0.32.0 이 설정 파일 생성을 사람 몫으로 남겨 업데이트해도 파일이 안 생기고, .env 가 비었던 사람은 빈 파일을 받아 무엇을 설정할 수 있는지 몰랐다(팀 피드백). 액션 시작 때 파일이 없으면 전체 키+기본값+설명(+.env 값)으로 만들고, 있으면 없는 키만 더한다. 비밀 파일은 git 이 무시할 때만.
- discarded alternatives: 예시 파일만 심기: 여전히 복사가 사람 몫 — 기각. 비밀 파일 무조건 생성: 무시 안 되면 토큰이 커밋될 수 있다 — 기각(무시 확인 후에만). 자동 감지 키에 기본값 채우기: 언어 자동 감지가 깨진다 — 기각(빈 값 + 설명).
- refs: scv/promote/20260824-wookiya1364-settings-always-present/PLAN.md

## [2026-08-24 10:39] wookiya1364 — 회귀 계약 보수 2 — 설정 이사 뒤 성립 불가 6건의 내구성 있는 재표현

- verdict: adopted
- why: 0.32.0 설정 이사로 .env 기반 계약 4건이 성립 불가가 되고, 같은 날의 두 계약은 없는 테스트 파일 이름을 불러 exit 127 — 누적 회귀 24 실행 / 7 실패. 0818 과 같은 방식으로 옛 6건을 obsolete 표시하고 살아 있는 검증을 실제 파일 이름으로 다시 적는다.
- discarded alternatives: 옛 TESTS 본문 수정: 아카이브 불변 원칙 — 기각. 그냥 두기: 회귀가 계속 빨간불이라 새 결함을 못 본다 — 기각.
- refs: scv/promote/20260824-wookiya1364-regression-contract-repair-2/PLAN.md

## [2026-08-24 11:12] wookiya1364 — 회귀 러너 — 같은 스위트 호출은 한 번만 (suite-gate memoization)

- verdict: adopted
- why: 보관 계약 28개 중 22개가 스위트 전량을 부르므로 같은 2~3분 작업이 20번 넘게 반복돼 회귀 한 번에 15분 이상. 한 run 안에서 같은 관문 호출은 결과가 같으니 한 번만 돌리고 종료 코드를 재사용한다. 계약 파일은 불변.
- discarded alternatives: 계약 TESTS 를 전부 다시 써서 전체 스위트 호출을 빼기: 아카이브 불변 원칙에 어긋나고 22건 — 기각. 임의 명령 일반 캐시: 사용자 블록을 임의로 바꾸게 된다 — 기각(정확히 세 호출만).
- refs: scv/promote/20260824-wookiya1364-regression-runner-memo/PLAN.md

## [2026-08-24 11:20] wookiya1364 — 설정 파일은 항상 있고, 모든 키가 보인다 archived

- verdict: archived
- why: 액션 시작(autosync 자리, 2.x 프로젝트만, SCV_AUTOSYNC=off 제외)에 설정 파일을 보장한다 — 없으면 26키+기본값+_doc(+.env 값), 있으면 없는 키만, 비밀 파일은 git 이 무시할 때만(무시 줄 자동 추가). hydrate 도 실파일. 자동 감지 키는 빈 값이어야 한다(채우면 언어 감지가 깨진다). .env 알림은 값이 다를 때만.
- path delta: 두 번 이탈: (1) 첫 구현은 legacy(2.0 이전) 프로젝트의 진단에서도 파일을 만들어 '진단은 읽기 전용' 계약(test-legacy-state)을 깼다 → 2.x 스탬프 확인 뒤로 이동. (2) 템플릿을 바꾸면 TEMPLATE_DIGEST 를 다시 계산해야 한다(test-template-digest) — scope 에 추가.
- refs: scv/archive/20260824-wookiya1364-settings-always-present/PLAN.md

## [2026-08-24 11:20] wookiya1364 — 회귀 계약 보수 2 archived

- verdict: archived
- why: 0.32.0 설정 이사로 성립 불가가 된 옛 계약 6건(.env 스위치 4·없는 파일 이름 2)을 obsolete 표시하고, 살아 있는 검증을 실제 파일 이름으로 다시 적었다. 앞으로 깨지면 안 되는 것: 계약의 How-to-run 은 존재하는 파일만.
- path delta: as planned — 단, obsolete 표시는 PLAN frontmatter 만으로는 러너가 못 본다(INDEX.yaml 빠른 경로가 우선) → archive 가 INDEX 를 재생성해야 반영된다. 보관 순서를 그렇게 잡았다.
- refs: scv/archive/20260824-wookiya1364-regression-contract-repair-2/PLAN.md

## [2026-08-24 11:20] wookiya1364 — 회귀 러너 suite-gate memoization archived

- verdict: archived
- why: 관문 세 호출(run-dry·tests/run.sh·core 테스트 루프)만 한 run 에 1회 실행하고 종료 코드를 재사용한다. 계약 단언은 매번. 실측 438초/0 실패(직전 15분+). 새 규칙: 계약의 How-to-run 은 자기 테스트 파일만.
- path delta: 첫 구현은 캐시를 command substitution 안에서 채워 서브셸로 새어 나갔다(관문이 슬러그마다 돌았다) → 준비(메인 셸)와 치환(순수)을 분리.
- refs: scv/archive/20260824-wookiya1364-regression-runner-memo/PLAN.md

## [2026-08-25 09:25] scv-core-sync-bot — 첨부는 실행 기록을 따른다 — attachments-run-manifest 채택

- verdict: adopted
- why: 이름 매칭은 Playwright 폴더명 절단에 깨진다(ai_tm_center 실측). 실행 시점 기록(run manifest)을 1순위로, 이름 매칭은 폴백, 0건은 알림, 같은 브랜치 열린 PR 은 갱신.
- refs: scv/promote/20260825-wookiya1364-attachments-run-manifest

## [2026-08-25 09:39] scv-core-sync-bot — 일반 대화에도 SCV 가 끼어든다 — SCV_ALWAYS_ON 채택 (기본 ON)

- verdict: adopted
- why: 명령 없는 대화는 스킬 권고를 모델이 무시한다(실측). 매 턴 닿는 훅 stdout 으로 help 라우팅 지시를 싣고, off 만 끈다. 기본 ON 은 사용자 결정.
- refs: scv/promote/20260825-wookiya1364-scv-always-on

## [2026-08-25 09:51] scv-core-sync-bot — 첨부는 실행 기록을 따른다 — 보관

- verdict: archived
- why: test-run-manifest 18/18, 기존 첨부 계약 26/26, 회귀 21/21. 잘린 이름 재현에서 0→N 첨부 실증.
- path delta: 계획대로. GitLab find_open 은 모의 수준(Non-Goals 명시).
- refs: scv/archive/20260825-wookiya1364-attachments-run-manifest

## [2026-08-25 09:51] scv-core-sync-bot — 일반 대화에도 SCV 가 끼어든다 — 보관

- verdict: archived
- why: test-always-on 15/15, 저널 82/82, run-dry 980, 회귀 21/21. 기본 ON 은 사용자 결정.
- path delta: 계획대로 + test-journal.sh 계약 갱신(off 는 자기 블록만, 둘 다 off 면 완전 침묵).
- refs: scv/archive/20260825-wookiya1364-scv-always-on

## [2026-08-25 16:13] scv-core-sync-bot — PR 증적을 Slack 에도 — pr-evidence-notify 채택

- verdict: adopted
- why: CI 는 실패만, pr-helper 는 PR 본문만 — 성공 slug 증적을 채널에 올리는 주체가 없었다(실측). pr-helper 가 PR 성공 후 best-effort 로 게시. 스레드 정밀 부착은 프로젝트 몫(합의).
- refs: scv/promote/20260825-wookiya1364-pr-evidence-notify

## [2026-08-25 16:18] scv-core-sync-bot — 증적 영상은 사람 속도로 — evidence-pacing 채택

- verdict: adopted
- why: slug 영상이 전환당 2초 미만으로 지나가 사람이 인지 불가(실사용 보고). 스펙 작성 규칙(전환 후 ≥2초 유지)과 영상 길이 기계 검사(경고, ffprobe 있을 때)를 함께 넣는다. 임계는 설정 키로.
- refs: scv/promote/20260825-wookiya1364-evidence-pacing

## [2026-08-25 16:30] scv-core-sync-bot — PR 증적을 Slack 에도 — 보관

- verdict: archived
- why: test-pr-notify 15/15, run-dry 980, 회귀 23/23. 스크린샷은 저장소로 mv 된 사본을 따라가는 처리 포함.
- path delta: 계획대로. 테스트 하니스의 local a=$1 b=$a 한 줄 선언이 set -u 에서 죽는 bash 함정 1회 수습.
- refs: scv/archive/20260825-wookiya1364-pr-evidence-notify

## [2026-08-25 16:30] scv-core-sync-bot — 증적 영상은 사람 속도로 — 보관

- verdict: archived
- why: test-evidence-pacing 14/14(ffmpeg 환경), 경고 전용·ffprobe 부재 침묵 확인.
- path delta: 계획대로.
- refs: scv/archive/20260825-wookiya1364-evidence-pacing

## [2026-08-26 10:07] scv-core-sync-bot — 번호식 화면설계서 — 그림이 주인공인 기획서

- verdict: adopted
- why: 기획서가 '폰트 큰 마크다운'으로 읽히는 문제를 양식 도입으로 해결한다. 실측: 아카이브 21건 중 17건이 그림 0개, 최근 8건은 연속 0개. 밀도 규칙을 따로 만드는 대신 '큰 그림+번호 마커+번호별 상세' 양식을 기본형으로 삼으면, 그림이 없을 때 양식 자체가 성립하지 않아 밀도가 부수적으로 강제된다.
- discarded alternatives: 밀도 개선과 양식 도입을 2개 계획으로 분할(에픽) — 1번에서 만든 밀도 규칙을 2번에서 양식 규칙으로 다시 손볼 가능성이 있어 기각; 양식만 하고 밀도 항목 제외 — 그림 0개가 조용히 통과하는 공백이 남아 기각; 마커·사이드바 규칙을 작성 지시문에 두기 — 20260813 팔레트 사고(지시문에 박아 코드를 고쳐도 안 바뀜)의 재발이라 기각하고 렌더러 코드에 둠; 과거 아카이브 30여 건 일괄 재생성 — 끝난 일의 그림을 지금 지어내는 것이라 충실도 보장 불가로 기각
- refs: scv/promote/20260826-wookiya1364-numbered-spec-deck/PLAN.md

## [2026-08-26 11:52] scv-core-sync-bot — 번호식 화면설계서 — 그림이 주인공인 기획서

- verdict: archived
- why: 기획서의 기본형을 '큰 그림 + 번호 마커 + 번호별 상세'로 바꿨다. FE는 와이어프레임에 ①②③/ⒶⒷ를 달고 우측에 기능·액션 설명, 아래에 상태 띠와 검증 메시지 표를 둔다. BE는 같은 부품을 재사용한다 — 호출 화면 표(최상단), 구성도+순서도 2장, 상태 띠를 테이블 스키마로, 검증표를 실패·응답 표로. 순수함수·파이프라인은 이제 모든 계획의 필수 섹션이며 지침 3곳과 코드 검사로 강제된다. 앞으로 깨지면 안 되는 것: 마커 없는 기존 목업은 바이트 단위로 동일하게 렌더된다(골든 기준선 보관), 렌더러는 쓰지 않은 번호의 설명을 지어내지 않는다, 재료가 없으면 경고만 하고 막지 않는다.
- path delta: 계획의 7단계는 14단계가 됐다. 실제 화면을 열어보며 세 번 되돌아갔기 때문이다 — (1) 다이어그램을 사이드바 옆 칸에 넣자 800px 구성도가 절반으로 줄어 8/13의 '글자 7.7px'가 재발했고, 다이어그램일 때는 전체 폭을 쓰고 상세를 아래로 내리는 배치로 바꿨다. (2) 자동 번호를 렌더 단계에 두었더니 검사 단계가 그 번호를 못 봐 짝 검사가 전부 오탐이었다 — 변환 단계로 옮겨 결정적 데이터의 일부로 만들었다. (3) 목업 안 다이어그램 배경을 투명하게 만든 것이 순서도 글자를 배경에 묻히게 했다(mermaid 기본색은 밝은 배경 전제) — 배경을 되돌리고 순서도 전용 색 규칙을 추가했다. 계약 갱신 2건도 함께: 화면 목업 절이 '선택'에서 '필수'로 바뀌며 옛 문구를 찾던 검사 4건을 새 계약으로 교체했고, 가드 예외 앵커가 편집마다 밀려 '수동 편집'으로 오인되던 문구는 예외를 늘리는 대신 문구를 바꿨다.
- refs: scv/archive/20260826-wookiya1364-numbered-spec-deck/PLAN.md
