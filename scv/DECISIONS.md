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

## [2026-08-27 13:25] scv-core-sync-bot — 기획서는 그림만 — 계획·테스트 문서를 본문에서 분리

- verdict: adopted
- why: 번호식 화면설계서가 스무 절 중 한두 절뿐이고 나머지는 글 덩어리로 딸려 나왔다. 본문을 그림 문서만으로 좁혀 '큰 그림, 적은 글'이 문서 전체의 성격이 되게 한다. 계획·테스트 원문은 사이드 패널 탭으로 계속 따라다니므로 잃는 정보가 없다.
- discarded alternatives: 계획 작성 단계에서 모든 절을 그림+번호로 강제 — 원하는 그림에 가장 가깝지만 작업량이 가장 크고, 지금 불만은 '섞여 나온다'는 것이라 먼저 분리로 해결. / 그림 있는 절을 앞으로 모으고 나머지를 뒤 부록으로 접기 — 글 덩어리가 문서에 남는 건 그대로라 '그림만 나오게'라는 요구를 절반만 만족. / 기본값은 그대로 두고 옵션만 추가 — 매번 지정해야 해서 가장 많이 쓰는 길이 기본이 되지 못함.
- path delta: 폴더 결합 함수를 읽기·고르기·본문 만들기·린트 네 단계로 쪼개고, 고르기 단계에 기본값(그림 문서만)과 되살리기 옵션을 넣는다. 린트 입력을 본문에서 파트 전체로 바꾼다.
- refs: scv/promote/20260827-wookiya1364-deck-picture-only/PLAN.md

## [2026-08-27 16:10] scv-core-sync-bot — 기획서는 그림만 — 계획·테스트 문서를 본문에서 분리 archived

- verdict: archived
- why: 기획서 본문은 이제 그림 문서만이다. 계획·테스트는 원문 패널 세 탭으로 계속 따라다니고, --full 로 예전 전체 결합을 되살릴 수 있다. 그림 문서가 없는 폴더는 기획서를 만들지 않고 사유 한 줄로 정상 종료한다 — 호출부가 이를 오류로 받으면 안 된다. 앞으로 깨지면 안 되는 것: --full 결과가 이 변경 전과 바이트 단위로 같을 것, 원문 패널 세 탭, 섹션 존재 린트는 본문이 아니라 파트 전체를 훑을 것.
- path delta: 린트용 텍스트를 원문 그대로 이으려던 계획을 버리고, 본문과 똑같은 방식으로 합쳐서 넘겼다. 합칠 때 붙는 라벨 제목(Acceptance Criteria)이 인수기준 린트 판정에 걸리고 있어서, 원문 그대로 이으면 --full 결과가 예전과 달라졌기 때문이다. 또한 기존 계약 두 곳을 대체했다 — 본문 조립을 검사하던 픽스처 6곳은 단언을 그대로 두고 --full 로 전환했고, 번호식 계약의 T13 은 제 변경 전부터 이미 깨져 있어(아카이브 마지막 폴더가 그림 있는 폴더로 바뀌면서 전제가 뒤집힘) 두 종류를 각각 검사하도록 다시 썼다. 회귀 11건 실패는 지침에 줄을 추가하며 가드의 줄 번호 앵커 하나가 밀린 것이었고, 앵커 갱신으로 26/26 복구.
- refs: scv/archive/20260827-wookiya1364-deck-picture-only/PLAN.md

## [2026-08-28 13:40] scv-core-sync-bot — 일반 대화에서 scv:help 를 실제로 강제한다 — 표시줄 + 점층 강화 되돌림

- verdict: adopted
- why: 안내 주입만으로는 호출이 대부분 안 된다. 호스트 조사 결과 프롬프트 훅은 프롬프트를 바꿔치기할 수 없고 스킬 호출 강제 장치도 없지만, 응답 종료 훅은 차단 결정과 사유로 모델을 되돌려 세울 수 있다. 호출 여부는 가드가 이미 발행하는 위조 불가 영수증으로 판정한다.
- discarded alternatives: 안내 문구만 강화: 여전히 확률적이라 '무조건'이 아니다. / 프롬프트 훅이 전체 상태 점검을 매 턴 주입: 강제가 붙으면 같은 점검이 한 턴에 두 번 돌고 컨텍스트가 두 배가 된다. / 우리 훅에 자체 재시도 상한(5회): 호스트 기본 상한 8보다 낮아 무의미했고, 같은 강도로 5번 반복하면 5번 다 실패할 수 있다. / 호스트 연속 차단 상한을 환경변수로 무제한 해제: 표시 장치가 고장 나면 세션이 멈추지 않는다. / 새 호출 표시 장치 신설: 영수증이 이미 있고 그쪽이 위조 불가다.
- path delta: 자체 상한 5회 → 상한 없음 + 회차별 강도 상승, 마지막 안전망은 호스트 기본 8회에 위임
- refs: scv/promote/20260828-wookiya1364-forced-help-invocation/PLAN.md
- conversation: scv/conversations/20260828-130200-forced-help-invocation.md

## [2026-08-28 14:27] scv-core-sync-bot — 일반 대화에서 scv:help 를 실제로 강제한다 — 표시줄 + 점층 강화 되돌림 archived

- verdict: archived
- why: 안내 주입만으로는 호출이 대부분 안 됐다. 응답 종료 훅의 차단 결정으로 되돌려 세우고, 호출 여부는 가드가 발행하는 위조 불가 영수증으로 판정한다. 자체 상한 없이 회차마다 요구를 강화하고 마지막 안전망은 호스트 상한에 맡긴다. 앞으로 깨지면 안 되는 것: 되돌림이 어떤 실패 경로에서도 세션을 막지 않는다는 것, 종료 훅이 영수증에 절대 쓰지 않는다는 것(쓰면 위조 불가 성질이 사라진다), 그리고 기록이 되돌림보다 먼저 일어난다는 순서.
- path delta: 가드를 공용 계산으로 '바꾸는' 대신, 공용 계산을 쓰되 라이브러리 부재 시 기존 인라인 계산으로 떨어지는 대비를 남겼다. 가드는 한 줄 버그가 모든 프로젝트의 모든 쓰기를 막는 파일이라, 이 기능을 위해 새 의존성을 하드하게 심는 것이 계획이 의도한 이득(경로 드리프트 방지)보다 비쌌다. 드리프트는 대신 T16 이 검사로 막는다. 또 하나: 되돌릴 때 훅을 즉시 끝내려던 설계가 호스트 상한 도달 시 그 턴의 기록을 통째로 잃는다는 것을 기존 저널 계약이 잡아, 기록을 먼저 하도록 순서를 뒤집었다.
- refs: scv/archive/20260828-wookiya1364-forced-help-invocation/PLAN.md
- conversation: scv/conversations/20260828-130200-forced-help-invocation.md

## [2026-08-28 14:36] scv-core-sync-bot — 기획서 그림이 서로 겹친다 — 그림마다 다른 id, 그리고 빈 그림 없애기

- verdict: adopted
- why: 정적 렌더가 모든 그림에 같은 고정 id 를 붙여, 머메이드가 id 로 한정하는 스타일과 화살촉이 문서 전체에 번진다. 산출물이 승격마다 커밋되므로 바이트 안정성은 지켜야 한다 — 그래서 id 를 그림 내용에서 만든다. 안정성과 유일성을 동시에 얻는다.
- discarded alternatives: 순번(1,2,3): 안정적이지만 중간에 한 장 끼우면 뒤 그림이 전부 밀려 산출물 차이가 커진다. / 빌드 시각 기반 id 로 되돌리기: 애초에 이것을 없애려고 고정한 것이라 원래 문제로 회귀. / 빈 그림 원인을 최소 폭 재정의로 미리 단정하고 고치기: 유력하나 미검증이라, 재는 단계를 계획 첫 항목으로 뒀다. / 두 결함을 따로 계획하기: 기획서가 만들어지는 마지막 단계에서 함께 나오고 증상도 하나라 묶는 편이 검증이 싸다.
- refs: scv/promote/20260828-wookiya1364-deck-mermaid-id-collision/PLAN.md
- conversation: scv/conversations/20260828-143007-deck-mermaid-id-collision.md

## [2026-08-28 15:07] scv-core-sync-bot — 기획서 그림이 서로 겹친다 — 그림마다 다른 id, 그리고 빈 그림 없애기 archived

- verdict: archived
- why: 겹침과 빈 그림은 두 결함이 아니라 하나였다. 머메이드가 그림 id 를 시각에서 만들어 같은 밀리초에 그려진 두 그림이 같은 id 를 받고, 뒤진 쪽은 앞 그림의 요소를 집어 빈 SVG 가 되며 앞 쪽의 스타일·화살촉은 문서 전체에 번진다. 그리는 쪽은 결정적 id 로, 굽는 쪽은 그림 내용에서 뽑은 id 로 고쳤다. 앞으로 깨지면 안 되는 것: 한 문서 안 id 유일성(화살촉·필터·그라디언트가 전부 이 id 로 키를 잡는다), 재빌드 바이트 동일성(이 산출물은 승격마다 커밋된다), 그리고 그림을 끼워 넣어도 나머지 바이트가 안 움직인다는 성질.
- path delta: 계획은 빈 그림의 원인을 '시트 레이아웃에서 폭이 0으로 측정' 으로 보고 그쪽을 고칠 예정이었다. 첫 항목대로 실제로 재 보니 폭은 550px 로 멀쩡했고 가설이 기각됐다. 그래서 고칠 곳이 레이아웃이 아니라 머메이드 설정(결정적 id)과 정적 단계의 id 생성 두 군데로 바뀌었고, 두 증상이 한 원인이라는 것도 그 측정에서 드러났다. '원인 확정 전에 고치지 않는다' 는 가드레일이 실제로 값을 한 사례다. 또 하나: 기존 검사가 그림 한 장짜리 재료만 써서 이 부류를 구조적으로 볼 수 없었기에, 여러 장 재료를 검사에 추가했다.
- refs: scv/archive/20260828-wookiya1364-deck-mermaid-id-collision/PLAN.md
- conversation: scv/conversations/20260828-143007-deck-mermaid-id-collision.md

## [2026-08-31 15:27] scv-core-sync-bot — 강제를 preflight 로 — 진단은 주입하고 되돌림은 없앤다

- verdict: adopted
- why: 0.39.0 의 강제가 응답 종료 시점에 걸려, 모델이 본문을 다 쓴 뒤 되돌려지고 되돌릴 때마다 본문을 통째로 다시 썼다. 목적을 잘못 잡은 것이 근본 원인이다 — 목적은 '스킬이 호출되는 것' 이 아니라 '이 턴에 SCV 현재 상태가 들어와 있는 것' 이었고, 수단을 강제하느라 목적보다 비싼 값을 치렀다. 강제 지점을 턴의 시작으로 옮겨 진단을 주입하고 되돌림을 없앤다.
- discarded alternatives: 되돌림 상한만 1회로 축소: 낭비를 줄일 뿐 없애지 못하고, 본문이 두 번 나가는 문제는 그대로. / 되돌림 사유에 '답을 다시 쓰지 말라'고 명시: 지킬지가 확률적이고 어차피 턴 하나가 더 돈다. / 모든 턴을 대화모드·아카이브검색 둘 중 하나로 밀어넣기: 앞도 뒤도 아닌 턴('고마워')에 쓸데없는 호출이 붙어 같은 낭비가 이름만 바꿔 남는다. / 애매한 턴만 한 줄로 되묻기: 대화가 한 번씩 끊긴다. / 상태 점검 전체 6KB 주입: 절반(2823바이트)이 매번 같은 개요·명령 목록이라 진단 3148바이트만으로 충분.
- path delta: 아직 구현 전 — 계획 단계의 결정
- refs: scv/promote/20260831-wookiya1364-force-help-preflight/PLAN.md
- conversation: scv/conversations/20260831-151549-force-help-preflight.md

## [2026-08-31 15:57] scv-core-sync-bot — 강제를 preflight 로 — 진단은 주입하고 되돌림은 없앤다 archived

- verdict: archived
- why: 강제 지점을 턴의 끝에서 시작으로 옮겼다. 프롬프트 훅이 진단을 직접 실어 보내면 확인하려고 액션을 한 번 더 부를 이유가 없어지고, 답은 항상 한 번만 생성된다. 되돌림·회차별 강화·턴 상태·실패 기록이 전부 사라졌고, 영수증을 읽는 두 번째 소비자가 없어져 가드도 의존성 없는 원래 모습으로 돌아왔다. 앞으로 깨지면 안 되는 것: 종료 훅이 어떤 경우에도 되돌리지 않는다는 것, 분류 세 갈래에서 '둘 다 아님' 이 정당한 결과로 남아 있다는 것(빠지면 짧은 맞장구에도 액션이 붙어 같은 낭비가 돌아온다), 그리고 훅 출력에 상한이 있다는 것.
- path delta: 계획 범위 밖 파일 하나를 고쳤다 — 저널 검사의 '훅 출력 24줄 상한'. 그 값은 쉬운말·항상라우팅 두 블록을 재던 것인데 preflight 가 세 번째 블록으로 붙어 59줄이 됐다. 상한을 없애지 않고 80줄로 올리고 이유를 적었다: 이 출력은 매 턴 값을 치르므로 늘어난다면 결정으로 내려야지 모르게 새면 안 된다. 또 하나: 내가 쓴 새 검사가 핵심부에 호스트 표기를 새게 해 호스트 중립 검사가 잡았다 — 중립 표지로 바꿨다.
- refs: scv/archive/20260831-wookiya1364-force-help-preflight/PLAN.md
- conversation: scv/conversations/20260831-151549-force-help-preflight.md

## [2026-09-01 10:23] scv-core-sync-bot — 지시를 맨 앞으로, 조건문을 명령으로 — preflight 지침 강화

- verdict: adopted
- why: 0.40.0 배포 뒤에도 앞을 보는 턴에서 호출이 안 된다. 원인은 문구 세기 하나가 아니라 넷이다: 자기모순('다시 확인하지 말고 그대로 쓰라' 가 호출 전반을 막는 것처럼 읽힌다), 묻힌 위치(40줄 진단 뒤), 조건문 형태, 그리고 같은 요구를 하는 블록이 둘이라 서로를 약화시킨다. 넷을 함께 고치고, 볼륨 대신 이유를 준다 — 대화 모드는 논의를 파일로 남기고 주입은 그 일을 대신하지 못한다.
- discarded alternatives: 문구만 세게 하고 나머지는 그대로: 모순 문장이 남으면 볼륨을 올려도 반대 방향으로 당기는 문장이 그대로 이긴다. / 라우팅 블록을 그냥 삭제: 그 블록은 별도 기능이고 자기 검사가 있어, 지우면 성질이 조용히 사라진다 — 흡수하고 대체 선언하는 편이 낫다. / 두 블록을 유지한 채 preflight 만 강화: 무시되는 지시가 둘로 남아 서로를 약화시키는 문제가 그대로다. / 되돌림 되살리기: 값이 이미 증명된 실패다. / 새 스위치 추가: 사용자가 기억할 것이 늘어난다.
- path delta: 아직 구현 전 — 계획 단계의 결정
- refs: scv/promote/20260901-wookiya1364-preflight-directive-strength/PLAN.md
- conversation: scv/conversations/20260901-101535-preflight-directive-strength.md

## [2026-09-01 11:06] scv-core-sync-bot — 지시를 맨 앞으로, 조건문을 명령으로 — preflight 지침 강화 archived

- verdict: archived
- why: 지시가 무시된 원인은 문구 세기가 아니라 넷이었다: 자기모순('다시 확인하지 말고 그대로 쓰라' 가 호출 전반을 막는 것처럼 읽혔다), 40줄 진단 뒤에 묻힌 위치, 조건문 형태, 같은 요구를 하는 블록이 둘. 넷을 함께 고치고 볼륨 대신 이유를 줬다 — 대화 모드는 논의를 파일로 남기고 주입은 그 일을 대신하지 못한다. 앞으로 깨지면 안 되는 것: 지시가 진단보다 먼저 나온다는 순서, 셋째 갈래('둘 다 아니면 그냥 답하라')의 존재, 그리고 두 스위치의 등록.
- path delta: 옛 라우팅 검사 파일을 살려 고치는 대신 삭제했다 — 그 계획을 대체하므로 두 파일이 같은 성질을 중복 검사하게 되고, 남겨두면 전체 스위트가 계속 빨간불이다. 지우기 전에 성질 네 가지(스위치 규칙·쉬운말 독립·비 SCV 폴더 침묵·키 등록)가 새 검사에 모두 들어왔는지 대조했다. 그 과정에서 내가 검사를 다시 쓰며 키 등록 항목을 빠뜨린 것을 발견해 되살렸다 — 계획이 '가장 조용한 위험' 이라 적어 둔 바로 그 지점이 실제로 일어날 뻔했다.
- refs: scv/archive/20260901-wookiya1364-preflight-directive-strength/PLAN.md
- conversation: scv/conversations/20260901-101535-preflight-directive-strength.md

## [2026-09-01 14:07] scv-core-sync-bot — 갱신은 이미 자동이다 — 강요 문구를 걷고, 조용한 갱신을 보이게

- verdict: adopted
- why: 자동 갱신은 이미 구현돼 돌고 있다. 사용자가 손으로 sync 를 치는 이유는 (1) 래퍼 문서 3곳이 코어 규약과 반대로 안내하고 (2) 갱신 보고가 훅에서 2>/dev/null 로 버려져 아무 증거가 안 남기 때문이다. 로직이 아니라 보고 경로와 문구를 고친다.
- discarded alternatives: update 액션 안에서 sync 를 직접 부르는 안 — 배포본이 버전별로 캐시되므로 갱신 시점의 세션은 아직 옛 payload 를 들고 있다. 그 자리에서 부르면 옛 템플릿을 깔고 성공했다고 보고한다. 코어 규약이 이미 금지하는 길이다.|훅에서 stderr 를 통째로 내보내는 안 — 한 줄 문제를 고치려다 점검 스크립트의 모든 경고가 매 턴 쏟아진다. 고른 줄만 싣는다.|매 턴 '문서 최신' 을 찍는 안 — 침묵이 기본값이라는 성질을 잃는다.
- refs: scv/promote/20260901-wookiya1364-update-auto-refresh/PLAN.md
- conversation: scv/conversations/20260901-131508-update-auto-refresh.md

## [2026-09-01 14:37] scv-core-sync-bot — 갱신은 이미 자동이다 — 강요 문구를 걷고, 조용한 갱신을 보이게 archived

- verdict: archived
- why: 자동 갱신은 이미 돌고 있었다. 손으로 sync 를 치게 만든 것은 (1) 코어 규약과 반대로 말하는 래퍼 문서 3곳과 (2) 훅이 점검의 stderr 를 2>/dev/null 로 버려 갱신 증거가 화면에 안 남는 것이었다. 앞으로 지켜야 할 것 둘 — 갱신할 것이 없으면 훅 출력이 한 줄도 늘지 않는다(침묵이 기본값), 그리고 점검의 stderr 는 통째로 싣지 않고 템플릿 갱신 줄만 골라 싣는다(같은 통로로 설정 계열 보고가 함께 나온다).
- path delta: as planned
- refs: scv/archive/20260901-wookiya1364-update-auto-refresh/PLAN.md
- conversation: scv/conversations/20260901-131508-update-auto-refresh.md

## [2026-09-01 16:02] scv-core-sync-bot — 분류를 걷어내고 무조건 부르게 — 판단은 help 가 한다

- verdict: adopted
- why: 지시 블록이 행동보다 판단을 앞세우고, 그 판단에 '부르지 않아도 된다'는 정당한 출구(C)가 있다. 애매한 턴 앞에서 침묵이 언제나 더 싸므로 볼륨을 올려도 이 비대칭은 남는다. 분류를 지침에서 걷어내 help 안으로 옮긴다 — 판단이 사라지는 게 아니라 주체가 모델에서 액션으로 바뀐다.
- discarded alternatives: 문구만 더 강하게 하는 안 — 0.40.0·0.41.0 에서 두 번 시도했고 두 번 다 안 됐다. 원인이 세기가 아니라 구조(판단이 앞에 있음)라는 것이 이번 진단이다.|예외 없이 완전 무조건으로 가는 안 — 이미 SCV 액션이 도는 턴에서 자기 자신을 다시 부르게 되어 동작이 깨진다. 예외 둘은 분류가 아니라 정의상 해당 없음이다.|C 를 그냥 삭제하는 안 — 짧은 턴마다 대화 파일이 쌓인다. 그 판단은 없앨 것이 아니라 옮길 것이다.
- refs: scv/promote/20260901-wookiya1364-unconditional-help/PLAN.md
- conversation: scv/conversations/20260901-155801-unconditional-help.md

## [2026-09-01 16:19] scv-core-sync-bot — 출구를 옮기는 것은 없애는 것이 아니다 — help 의 돌려보내기도 뺀다

- verdict: lesson
- why: 무조건 호출을 설계하며 모델 쪽 분류는 없앴지만, help 안에 '남길 논의 없음 → 아무것도 쓰지 않고 끝' 갈래를 새로 뒀다. 그것은 출구를 지침에서 액션으로 옮겼을 뿐 출구 자체는 살려 둔 것이고, 같은 구멍이 자리만 바꾼다. 사용자가 잡아냈다. 앞으로 '무조건' 을 설계할 때는 옮긴 자리에 출구가 다시 생기지 않았는지 확인한다.
- refs: scv/promote/20260901-wookiya1364-unconditional-help/PLAN.md
- conversation: scv/conversations/20260901-155801-unconditional-help.md

## [2026-09-01 16:34] scv-core-sync-bot — 분류를 걷어내고 무조건 부르게 — 판단은 help 가 한다 archived

- verdict: archived
- why: 지시 블록에서 세 갈래를 걷어내고 조건 없는 명령 하나로 만들었다(21행 → 13행). 부를 필요가 있었는지는 인자를 쥔 help 가 판단한다. 앞으로 지켜야 할 것 셋 — 지시 블록에 갈래·조건을 다시 넣지 않는다, help 는 돌려보내지 않고 항상 기록한다, 짧은 턴은 세션 대화 파일에 이어 붙인다. 대체된 계획의 성질 넷(스위치 끄면 침묵·비 SCV 폴더 무출력·비차단·요구 블록 하나)은 새 검사가 이어받았다.
- path delta: as planned
- refs: scv/archive/20260901-wookiya1364-unconditional-help/PLAN.md
- conversation: scv/conversations/20260901-155801-unconditional-help.md

## [2026-09-03 10:18] scv-core-sync-bot — help 의 답 모양 — 여섯 자리 고정, 빈 자리 생략

- verdict: adopted
- why: 좋은 점검 답의 양식(결론 먼저·예상 밖 사실·항목표 지금/바꿀 것/규모·큰 것만 상세·횡단 관심사·추천 붙인 결정표)을 help 의 모든 턴에 고정한다. 좋았던 이유는 표가 아니라 네 성질 — 확인됨 표시, 예상 밖 먼저, 사실/바꿀 것/규모 분리, 추천 붙인 번호표. '모든 턴' 과 '빈 표 금지' 는 규칙 하나로 양립한다: 모양은 고정, 빈 자리는 지운다.
- discarded alternatives: 맞는 경우(항목 여럿 점검)에만 쓰는 안 — 사용자가 모든 턴을 원했고, 빈 자리 생략 규칙이 있으면 모든 턴에 써도 연극이 되지 않는다.|출력을 기계로 검사해 되돌리는 안 — 0.39.0 이 갔다가 답이 통째로 재생성되는 값을 치르고 걷어낸 길. 규약 문구 층위에 둔다.|'한 턴에 질문 하나' 를 그대로 두는 안 — 독립 결정 6개를 여섯 턴에 나눠 묻는 것은 사용자 주의를 낭비한다. 의존이면 하나씩, 독립이면 한 표로 구분한다.
- refs: scv/promote/20260903-wookiya1364-help-answer-shape/PLAN.md
- conversation: scv/conversations/20260903-100312-help-audit-shape.md

## [2026-09-03 10:50] scv-core-sync-bot — 점검표가 아니라 어휘다 — 답의 자리는 질문이 고른다

- verdict: lesson
- why: 처음 안 '여섯 자리를 놓고 빈 것을 지운다' 는 점검표에서 출발한다 — 모델이 칸을 훑으며 비었나를 판단하고, 그 과정에서 칸을 채우려고 억지 내용을 만들기 쉽다. 사용자가 바로잡았다: 질문에서 출발해 부르는 자리만 고른다. 결과가 같아 보여도 모델이 따르는 방향이 반대다. 앞으로 답 모양을 규칙으로 쓸 때는 '무엇을 지울까' 가 아니라 '무엇을 부를까' 로 쓴다.
- refs: scv/promote/20260903-wookiya1364-help-answer-shape/PLAN.md
- conversation: scv/conversations/20260903-100312-help-audit-shape.md

## [2026-09-03 11:44] scv-core-sync-bot — help 의 답 모양 — 질문이 부르는 자리만, 정해진 순서로 archived

- verdict: archived
- why: 좋은 점검 답의 여섯 부분(결론·예상 밖 사실·항목표·상세·횡단·결정표)을 help 가 골라 쓰는 어휘로 규약에 넣었다. 답은 질문이 부르는 부분만 쓰고, 완성돼 보이려고 더하지 않는다. 앞으로 지켜야 할 것 셋 — 규약 안의 이름은 모델용이지 사람용이 아니며 사용자에게 나가지 않는다(구현 중 사용자 지적으로 추가), 사실은 (confirmed) 로 표시하고 추정과 섞지 않는다, 의존 질문은 한 턴에 하나·독립 결정은 추천 붙여 한 표. 옛 계약 문구 'one question per turn' 은 새 규칙과 모순되지 않으므로 유지한다 — 지웠다가 회귀 6건이 떨어져 되살렸다.
- path delta: 제안 경로에 없던 셋째 규칙(사람의 말로 — 만든 이름 금지)을 같은 절에 추가했다. 구현 중 사용자가 내 답에서 그 문제를 실제로 겪었고, 같은 답을 다스리는 규칙이라 계획을 갈라 내지 않았다. 또 옛 계약 문구를 지웠다가 회귀로 발견해 복구했다.
- refs: scv/archive/20260903-wookiya1364-help-answer-shape/PLAN.md
- conversation: scv/conversations/archive/20260903-100312-help-audit-shape.md

## [2026-09-03 15:08] scv-core-sync-bot — 명령이 세션 모델을 바꾸지 않는다 — 기본은 세션 모델 그대로

- verdict: adopted
- why: SCV 명령 15개 머리말의 model 줄(opus/haiku)이 명령이 도는 동안 세션 모델을 바꾼다. 0.43.0 의 무조건 호출과 결합되어 Fable 세션에서도 매 턴 Opus 5 가 답했다 — 사용자의 모델 선택이 무시됨. 기본을 session-default(줄 없음)로 뒤집고 opus/haiku 매핑은 선택지로 남긴다. 저장 경로도 고장(없는 env-set.sh 호출, 등록부에 키 없음) — 설정 파일로 옮긴다.
- discarded alternatives: 지금 적용만 하고 기본은 두는 안 — 플러그인 갱신마다 다시 Opus 로 돌아간다. 0.42.0 에서 없앤 '갱신 뒤 손으로 한 번 더' 를 다른 이름으로 되살리는 꼴.|무조건 호출을 되돌리는 안 — 원인은 호출이 아니라 명령의 모델 지정이다. 짝을 고쳐야지 호출을 물릴 일이 아니다.|model 줄을 sonnet 같은 중간값으로 바꾸는 안 — 어느 값이든 사용자 선택을 덮어쓴다는 문제는 같다.
- refs: scv/promote/20260903-wookiya1364-session-model-default/PLAN.md
- conversation: scv/conversations/20260903-150216-command-model-override.md

## [2026-09-03 15:48] scv-core-sync-bot — 명령이 세션 모델을 바꾸지 않는다 — 기본은 세션 모델 그대로 archived

- verdict: archived
- why: 래퍼 명령 15개의 model 줄을 걷어내 기본을 세션 모델로 뒤집었다. 매핑은 set-models 의 선택지로 남고(첫 선택지 session-default), 저장은 사라진 env-set.sh 대신 코어 settings-set.sh 로 설정 파일에 — 코어 등록부에 SCV_MODEL_POLICY(기본 session-default) 를 두었다. 앞으로 지켜야 할 것: 래퍼 명령 파일은 model 줄 없이 커밋한다(계약 검사가 잠근다), 코어 페이로드에는 호스트·모델 이름을 쓰지 않는다(호스트 중립 검사), 템플릿 트리 파일을 바꾸면 지문을 다시 계산한다.
- path delta: 셋. (1) 설정 파일 읽기를 코어 라이브러리 대신 python3 로 JSON 직접 읽기로 — 래퍼가 프로젝트 경로를 인자로 받는 자리라 cwd 기반 해석보다 단순하고 python3 는 선언된 의존성. (2) 코어 검사에서 모델 이름 단언을 걷어내고 'model 줄의 유무·서로 다름' 만 보게 — 호스트 중립 검사가 core/ 전체에서 opus·sonnet·haiku 를 금지한다는 것을 회귀 15건 실패로 알았다. (3) 템플릿 지문 재계산 — 설정 예시가 템플릿 트리라는 것을 회귀 4건 실패로 다시 확인.
- refs: scv/archive/20260903-wookiya1364-session-model-default/PLAN.md
- conversation: scv/conversations/archive/20260903-150216-command-model-override.md

## [2026-09-04 10:33] scv-core-sync-bot — 깊은 질문은 배경 조사로 — 세션 effort 는 그대로, 스위치는 기본 off

- verdict: adopted
- why: effort 도 모델과 같은 원칙: 세션 다이얼은 사용자 것. SCV 는 스위치(기본 off)를 켠 프로젝트에서만 깊은 질문을 배경 조사 에이전트에 넘기고 결과는 scv/raw 파일로 남긴다. 단계 선택은 호출별 effort 가 실제로 먹는 워크플로 호스트로 한정 — 정의 파일 effort 줄은 2.1.260 실측에서 안 먹었다.
- discarded alternatives: 사용자 effort 를 low/medium 으로 눌러 놓는 안 — 명령 파일 effort 줄로 가능하지만 어제 뺀 model 줄과 같은 다운그레이드 | 정의 파일 effort 로 low~max 를 고르는 안 — 실측에서 세 단계 모두 세션값으로 돌아 기댈 수 없음 | 명령(promote·work)이 조사를 자동으로 부르는 안 — 비용(조사 1건 출력 139k 토큰)이 커 이번 범위 밖
- refs: scv/promote/20260904-wookiya1364-effort-auto-level/PLAN.md
- conversation: scv/conversations/20260904-094830-effort-auto-level.md

## [2026-09-04 11:24] scv-core-sync-bot — 깊은 질문은 배경 조사로 — 세션 effort 는 그대로, 스위치는 기본 off archived

- verdict: archived
- why: effort 도 모델과 같은 원칙으로 확정: 세션 다이얼은 사용자 것, SCV 는 바꾸지 않는다. 대신 SCV_DELEGATE_EFFORT=on(기본 off) 인 프로젝트에서 매 턴 훅이 넷째 블록을 실어 깊은 질문을 배경 조사 에이전트(scv-investigator, 래퍼가 싣는다)에 넘기고 결과 전문은 scv/raw/ 파일로 남긴다. 실측으로 굳힌 것: 에이전트 정의 파일의 effort 줄은 Claude Code 2.1.260 에서 먹지 않는다(세 단계 모두 세션값) — 단계 선택은 워크플로 호출별 effort 가 있는 호스트로 한정. 앞으로 지켜야 할 것: off 면 훅 출력 바이트 동일, 코어 본문에 단계 이름 금지, 에이전트에 effort 줄 금지.
- path delta: 블록 자리를 계획의 '진단 뒤' 에서 '라우팅 지시 뒤·진단 앞' 으로 옮겼다 — 반박 검토가 훅 자체의 0.40.0 교훈(지시가 진단 뒤에 묻히면 무시된다)과의 충돌을 짚었다. 에이전트는 '읽기 전용' 이 아니라 '편집 도구 금지 + scv/raw 만 쓰기' 로(결과 파일을 쓰려면 Write 가 필요). 결과 도착 시 대화 파일에 경로·요약을 잇는 줄 하나 추가. 순수성 검사가 블록의 <날짜> 를 리다이렉션으로 오인해 표기를 YYYYMMDD 로.
- refs: scv/archive/20260904-wookiya1364-effort-auto-level/PLAN.md
- conversation: scv/conversations/20260904-094830-effort-auto-level.md

## [2026-09-11 13:57] scv-core-sync-bot — 비운 뒤에도 이어진다 — 압축·/clear·재개 뒤 진행 상황 재주입

- verdict: adopted
- why: 저널·결정·대화는 이미 자동 저장되지만 비운 뒤 다시 읽어 주는 훅이 없었다. 세션 시작 이벤트(압축·비움·재개)에 기존 recap 조립기 + 활성 대화 1건을 싣는다. 새 세션 시작은 preflight 가 맡으므로 제외. 상한 없음(사용자 결정).
- discarded alternatives: 매 턴 계획 파일 재주입(planning-with-files 방식) — preflight 가 이미 매 턴 상태를 실어 중복 비용 | 압축 직전(PreCompact) 저장 — 저장은 이미 자동이고 그 이벤트 stdout 은 모델에 닿지 않음 | startup 포함 — 첫 메시지 preflight 와 중복 | 80줄 상한 — 사용자가 결정·대화가 더 길 수 있다며 거부
- refs: scv/promote/20260911-wookiya1364-session-resume-recap/PLAN.md
- conversation: scv/conversations/20260911-110227-next-features-0-46-1.md

## [2026-09-11 13:57] scv-core-sync-bot — 명령을 skills 로 — 플러그인 구조·설명 길이를 CI 가 지킨다

- verdict: adopted
- why: 래퍼의 commands/ 는 공식 문서상 legacy. 같은 이름으로 skills/<action>/SKILL.md 로 옮기고 commands/ 는 같은 릴리스에서 삭제. 구조 검사(claude plugin validate --strict)와 설명 길이 상한(개별 1,536·합계 8,000)을 CI 게이트로.
- discarded alternatives: 한 릴리스 동안 commands/·skills/ 공존 — 스킬 목록 두 배, 문서도 공존 비권장 | context: fork 적용 — 포크는 대화 이력 없고 사용자와 대화 불가, SCV 명령 흐름과 안 맞음 | 개별 상한만 — 스킬 증가 시 총량 통제 불가하여 합계 상한 채택 | Codex 래퍼 동시 변경 — 이미 skills 구조라 무변경
- refs: scv/promote/20260911-wookiya1364-skills-layout-gates/PLAN.md
- conversation: scv/conversations/20260911-110227-next-features-0-46-1.md

## [2026-09-11 14:46] scv-core-sync-bot — 비운 뒤에도 이어진다 — 압축·/clear·재개 뒤 진행 상황 재주입 archived

- verdict: archived
- why: 세션 시작 훅 템플릿(on-session-start.sh)이 압축·비움·재개 직후 recap(진행 중 계획·최근 결정 5·미결) + 활성 대화 1건 전문(가림 필터 경유)을 싣는다. 스위치 SCV_RESUME_RECAP 기본 on. 새 세션 시작은 등록하지 않는다(preflight 중복). 지켜야 할 것: 훅은 아무 것도 쓰지 않고 항상 exit 0, 폴더는 scv/ 고정(SCV_DIR 무시 — 다른 두 훅과 같음), 심볼릭 링크·탭/개행 파일명은 건너뜀, 파일마다 프로세스를 띄우지 않는다(3천 파일 0.2초).
- path delta: 계획대로 갔으나 적대 검증이 사소 6건 + 가장자리 2건을 잡아 같은 릴리스에 반영 — 링크 추적·특수 파일명·SCV_DIR 어긋남·status 엄격 인식·mtime 동률·파일당 fork 성능·stat 폴백 중복·60줄 넘는 미완 frontmatter. 계획의 '순수부 셋' 은 넷(나머지 활성 대화 목록)이 됐다. PR 은 pr-helper 의 epic 기준(epic/<slug> ← main 생성) 대신 이 저장소의 브랜치 규칙(develop ← feat/*)에 맞춰 직접 연다.
- refs: scv/archive/20260911-wookiya1364-session-resume-recap/PLAN.md
- conversation: scv/conversations/20260911-110227-next-features-0-46-1.md

## [2026-09-11 15:40] scv-core-sync-bot — 명령을 skills 로 — 플러그인 구조·설명 길이를 CI 가 지킨다 archived

- verdict: archived
- why: 래퍼 열다섯 명령이 skills/<action>/SKILL.md 로 옮겨졌고(name: 추가, commands/ 삭제) 호출 이름은 그대로. 투영·갱신 소유 규칙·모델 정책·계약 검사·워크플로가 새 경로를 본다. PR 게이트: claude plugin validate --strict 를 마켓 매니페스트·플러그인 매니페스트·skills·agents 넷에 각각(루트 하나만 돌리면 마켓 매니페스트만 본다 — 적대 검증이 잡음). 코어 검사 test-skill-descriptions.sh: name==디렉터리, 개별 ≤1,536·합계 ≤8,000(현재 5,709), model/context 줄 금지. 지켜야 할 것: CI 에 없는 래퍼 원자성 검사(test-sync-core-atomicity.sh)도 경로 변경 때 같이 고칠 것 — 이번에 빠져 blocker 로 잡혔다.
- path delta: 계획대로 갔으나 적대 검증이 넷을 잡아 반영: 원자성 검사의 commands 참조 20곳(CI 밖), validate 가 루트에서 마켓 매니페스트만 검사(대상 넷으로), 설명 검사의 탭 구분자가 빈 값을 밀어 '없음' 을 못 잡던 것(\x1f 구분자·접힘/이어쓰기 description·따옴표 name), test-delegate-effort 의 commands 기반 래퍼 감지(T9/T10 조용히 SKIP). validate 가 로그인 없이 CI 에서 도는 것은 첫 실행으로 확인 — 대체 경로 불필요. /skill-doctor 실측은 래퍼 릴리스 뒤.
- refs: scv/archive/20260911-wookiya1364-skills-layout-gates/PLAN.md
- conversation: scv/conversations/20260911-110227-next-features-0-46-1.md

## [2026-09-14 09:50] scv-core-sync-bot — help 본문 다이어트 — 매 턴 11k 토큰을 4~5k 로, 동작은 검사가 지킨다

- verdict: adopted
- why: help 는 매 턴 강제 호출이라 본문 28KB(≈11k tok)가 세션 비용의 가장 큰 항목. 분기 전용 본문 11KB 를 protocols/help/ 부속 파일로 빼서 분기에서만 읽고, 훅과 중복인 위임 절은 포인터로, 설명문은 압축. 부속 파일은 기존 배송 경로(export→materialize 재귀 치환→래퍼 트리 교체)로 실려가 래퍼 무변경 — 확인됨.
- discarded alternatives: 1·2단계만 먼저(부속 파일 분리 보류): 절감이 ~3k tok 에 그쳐 기각 · 쉬운 말 절 축소: 열세 규약 공통 계약(run-dry 15p · help-shape T7)이라 이번 범위 밖 · 래퍼 투영에 부속 파일 지원 추가: 조사 결과 불필요
- refs: scv/promote/20260914-wookiya1364-help-body-diet/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-14 10:02] scv-core-sync-bot — help 매 턴 비용 다이어트 — 재검토로 범위 확장 (스크립트 출력 A·B 합침)

- verdict: adopted
- why: 매 턴 스택 실측 44.5KB(≈17k tok) 중 본문은 2/3. 보조 스크립트가 대화 모드에도 배너·진단(훅과 중복)과 archive 목록 48줄을 찍는다. 대화 모드 출력은 파싱 머리만, archive 목록은 --archive-index 로 분리 → 매 턴 약 18KB(≈6.5k). 인자 없음·위치 인자 출력은 불변이라 기존 검사 무수정.
- discarded alternatives: 훅 진단 블록 압축(약 2KB): 매 턴 진단 주입은 사용자 결정 영역 — 후속 계획으로 · 라우터 변형(대화 루프까지 부속 파일로): 보통 턴마다 Read 증가 — 기각
- refs: scv/promote/20260914-wookiya1364-help-body-diet/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-14 10:23] scv-core-sync-bot — help 규약은 세션당 한 번만 — 2단계 계획, epic help-turn-cost

- verdict: adopted
- why: 1단계 뒤에도 본문이 매 턴 재주입되어 세션 누적(오늘 8턴 234KB)이 압축을 앞당긴다. 규약 전체는 세션당 1회 Read, 재읽기 시점은 훅 상태(session_id 변화 · SessionStart compact/clear/resume)로 결정적으로. 같은 표식으로 진단도 변동 시에만 전체. 1단계 실측 뒤 구현.
- discarded alternatives: 모델 자기 판단('컨텍스트에 안 보이면 읽어라'): 비결정적이라 기각 · 1단계와 한 PR: 효과 분리 측정 불가라 기각
- refs: scv/promote/20260914-wookiya1364-help-load-once/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-14 11:56] scv-core-sync-bot — help 매 턴 비용 다이어트 — 17k 토큰을 6~7k 로, 동작은 검사가 지킨다 archived

- verdict: archived
- why: 매 턴 스택 44,458B→17,653B(래퍼 17,963B). 분기 본문 5개를 protocols/help/ 부속 파일로 빼고(래퍼 무변경 — 배송 경로가 하위 폴더를 통째로 실어 나른다), help.sh --with-context 는 파싱 머리만, archive 목록은 --archive-index 로. 배운 것: 래퍼에선 자리표시자 확장으로 본문이 ~390B 커지므로 상한 검사는 래퍼 투영본에서도 돌려야 한다; 규약 문장을 고정한 run-dry 앵커가 다이어트의 실제 마찰(10개 재조준). 지켜야 할 것: 쉬운 말 절·답 모양 절은 계약, 인자 없음·위치 인자 출력은 불변.
- path delta: 계획 순서대로 갔으나 두 번 벗어났다: (1) 본문 상한 14,000B 만으로는 매 턴 상한 18,000B 를 못 맞춰 계획에 없던 절(B0~B2·persistence·최종 노트)까지 압축; (2) TESTS 의 How to run 에서 verify-core --root . 는 export 트리 전용이라 test-profile-and-export 로 교체. VERSION 은 릴리스 chore PR 관례라 미변경.
- refs: scv/archive/20260914-wookiya1364-help-body-diet/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-14 11:59] scv-core-sync-bot — run-dry 다이어트 — 문장 고정을 구조 검사로, 남는 고정엔 이유를

- verdict: adopted
- why: run-dry 981 중 규약 문장 고정 353(GUIDANCE 전용 80 · mermaid 187 · 중복 3)이 변경 마찰의 원인(help 다이어트에 10개 재조준, promote 면 ~151). 스크립트 실행 검사는 전부 유지, 표현 고정은 구조 검사로, 계약 고정은 why 부착 + 총수 상한. 기능 PR 과 섞지 않고 별도 계획.
- discarded alternatives: 전용 검사와의 중복 제거만: 겹침이 1/38 이라 효과 없음 · 앵커 일괄 삭제: 출처 없이 지우면 결정을 잃는다 — 출처 표 필수 · help-turn-cost 2단계와 합치기: 성격이 달라 기각
- refs: scv/promote/20260914-wookiya1364-run-dry-anchor-diet/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-14 14:17] scv-core-sync-bot — run-dry 다이어트 — 문장 고정을 구조 검사로, 남는 고정엔 이유를 archived

- verdict: archived
- why: 제거 가능한 고정은 GUIDANCE 전용 32 + 중복 3 뿐 — 처음 감사(~270)는 문자열을 어느 규약에서든 찾은 과대치. 배운 것: 앵커 감사는 대상 파일에서만 세야 하고, git log -S 는 코어 추출 커밋으로 몰려 출처가 안 나온다. 지켜야 할 것: 문장 고정엔 why 필수(총수 ≤120), GUIDANCE 문구는 골격만, 스크립트 실행 검사 241 불변.
- path delta: 범위 축소(사용자 결정 A): 목표 ≤750 → 실측 965; mermaid 세 섹션 구조화와 (b)/(c) 사람 판단 표는 뺐다. why 는 출처 섹션 태그로 자동 부착(계약/표현 판단은 뒤로). 성능: 앵커마다 GUIDANCE 걷어내기 3분 → 파일당 캐시 7초.
- refs: scv/archive/20260914-wookiya1364-run-dry-anchor-diet/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-16 09:59] scv-core-sync-bot — help 규약은 세션당 한 번만 — 매 턴은 기록 계약만, 진단은 변동 시에만 전체 archived

- verdict: archived
- why: 매 턴 라우터(9.4KB) + 세션당 1회 full.md(6.4KB); 재읽기 시점은 훅 상태(세션 번호 변화·압축/지우기/재개·N턴)로 결정, 진단은 해시 비교로 변동 시에만 전체. 진단 변동 없는 턴 스택 17,653→11,245B. 배운 것: (1) 훅이 잘못된 입력에도 표식을 쓰면 저널 계약(무효 입력엔 아무 것도 안 씀)이 깨진다 — 세션 번호가 없으면 표식 자체를 건드리지 않는다 (2) 되찾기 훅의 '아무 것도 안 쓴다' 계약은 표식 한 파일만 예외로 완화했다 (3) 벤더 페이로드의 호스트 이벤트 이름 검사는 주석까지 본다. 지켜야 할 것: 답 모양 절은 매 턴 라우터에 남는다(잊음 완화의 핵심), mark 없이는 다음 턴 다시 load(자기 회복).
- path delta: 라우터 상한 4,000B 목표 → 9,374B 실측(답 모양 절을 매 턴 유지하기로 — 사용자의 잊음 우려에 대한 답). 세션 번호가 없으면 매 턴 load 가 아니라 표식 비활성(이전 동작 그대로)으로 바꿈. 기록 계약 누락 감사(완화 b)는 범위에서 빼 후속으로. 되찾기 훅 계약 완화(T10 예외)와 delegate 검사의 표식 초기화는 계획에 없던 손질.
- refs: scv/archive/20260914-wookiya1364-help-load-once/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-16 13:34] scv-core-sync-bot — 규약 지문 메아리 — 잊었는지 묻지 않고, 지문과 답 모양으로 잡아 다시 싣는다

- verdict: adopted
- why: 모델의 주의는 못 재므로 행동 체크섬으로: 규약을 읽은 컨텍스트에만 있는 무작위 지문을 매 턴 append 에 적게 하고 Stop 훅이 부재를 감지해 다음 턴 강제 재읽기; Stop 훅의 답 모양 린트로 계약 위반도 다음 턴 경고+재읽기. 통신 체크섬·재전송, 영상 참조 프레임 검사와 같은 구조. 기존 '기록 누락 감사'를 대체.
- discarded alternatives: 규약 암기 후 LLM 지식과 비교: 규약은 지식이 아니라 컨텍스트라 불가·자기보고 신뢰 불가 · Stop 훅으로 답 차단: non-blocking 계약 위반 · 라우터에 지문 싣기: 메아리 무의미
- refs: scv/promote/20260916-wookiya1364-help-protocol-echo/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-16 17:42] scv-core-sync-bot — 규약 지문 메아리 — 잊었는지 묻지 않고, 지문과 답 모양으로 잡아 다시 싣는다

- verdict: archived
- why: 규약을 읽은 컨텍스트에만 있는 8자리 지문을 매 턴 기록에 적게 하고 종료 훅이 표식과 비교한다 — 없거나 다르면 protocol=0 으로 되돌려 다음 턴에 규약을 다시 싣는다(빠진 뒤 재읽기까지 최대 10턴 → 다음 턴). 답 골격 린트(첫 문단 문장 수·결론 없이 표 시작·첫 문단 코드값·결정표 추천 열)도 같은 신호. 종료 훅은 여전히 답을 막지 않는다. 지문은 라우터·훅 출력·PROTOCOL 줄에 절대 싣지 않는다(검사) — 구현 중 diag 의 brief 줄에 지문이 새던 필드 읽기 결함을 검사가 잡았다.
- path delta: mark 출력 JSON 에도 지문을 싣는다(규약을 읽은 턴에만 실행되므로 불변식 유지) — 파일만 읽게 하면 mark 전엔 파일이 없어 순서가 꼬인다. 종료 훅은 저널 꼬리(4000B)와 별개로 마지막 어시스턴트 메시지 전문(64KB)을 뽑아 린트한다. 범위 밖 둘: 회귀 러너 게이트 상한 300→600(코어 검사 47개 ≈290초, 새 검사가 더해지자 보관 계약 3건이 같은 게이트로 붉게 떴다) · 래퍼 통합 문서에 훅이 쓰는 파일 넷 명시.
- refs: scv/archive/20260916-wookiya1364-help-protocol-echo/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-16 21:58] scv-core-sync-bot — 답 모양 검사는 이번 턴의 답만 본다 — 기록 경합 제거

- verdict: adopted
- why: 0.50.0 린트가 원본(transcript)의 마지막 답을 읽는데 호스트가 원본을 비동기로 적어 훅이 한 턴 전 답을 봄(관찰 2건, 같은 초). 호스트가 넘기는 last_assistant_message 를 1순위로, 없으면 원본을 턴 경계로 잘라 1초 안에서 재시도, 그래도 없으면 생략(src=none). 따옴표 안 마침표 오탐도 함께.
- discarded alternatives: 값 없는 호스트에서 린트를 끄기 — 사용자가 '무조건 적용' 을 요구해 기각 · 로그 형식 완전 불변 — 사후 검증을 위해 끝에 src 토큰 하나는 덧붙이기로
- refs: scv/promote/20260916-wookiya1364-answer-lint-turn-race/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-16 23:21] scv-core-sync-bot — 답 모양 검사는 이번 턴의 답만 본다 — 기록 경합 제거 archived

- verdict: archived
- why: 종료 훅의 린트 본문 출처를 셋으로 고정: 호스트가 넘긴 last_assistant_message → 원본의 이번 턴(마지막 사람 프롬프트 이후, 1초 안 재시도) → 없음(생략). 낡은 답을 보는 경우 0. 드리프트 줄 끝 src= 토큰으로 사후 검증 가능. 따옴표·괄호 안 마침표는 문장으로 안 센다. 지켜야 할 것: 지문 검사 경로 불변, U(사람 프롬프트) 없는 창은 안전 쪽(생략), 스위치 둘 다 off 면 읽지 않음, 템플릿 파일 변경 시 TEMPLATE_DIGEST 재계산.
- path delta: as planned — 추가로 test-help-echo 하네스의 원본 흉내에 사람 프롬프트 줄을 넣었다(새 규칙상 U 없으면 생략이라 옛 흉내가 붉어짐). 회귀 1차 9건은 코드 문제가 아니라 커밋 전 diff 검사·지문 미갱신.
- refs: scv/archive/20260916-wookiya1364-answer-lint-turn-race/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-16 23:33] scv-core-sync-bot — 매 턴 라우터 다이어트 — 답 모양은 남기고 나머지는 압축, 진단 안내문은 직접 부를 때만

- verdict: adopted
- why: 매 턴 스택 ≈12.6KB(라우터 9.7KB + 훅 1.5KB + 헬퍼). 답 모양·언어·쉬운 말 절은 바이트 그대로 두고(사용자 결정: 잊음 우려 유지, run-dry [15p] 공통 문구) 기록 계약·헬퍼·규약 읽기 절 압축, 배경 조사 절은 full.md 로 → 라우터 ≤7KB. 변동 턴 preflight 는 진단 본문 + 권장 첫 줄만(Learn more·hydrate 방법 제거) → ≤2KB. 상한 하향 잠금.
- discarded alternatives: 답 모양 절을 full.md 로 이동(라우터 ≈4.2KB, −5.5KB/턴) — 사용자가 매 턴 유지를 택함 · 매 턴 Skill 호출 자체를 훅 명령으로 대체 — always-on 계약 검사들과 얽혀 별도 계획으로
- refs: scv/promote/20260916-wookiya1364-help-router-diet/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-16 23:59] scv-core-sync-bot — 매 턴 라우터 다이어트 — 답 모양은 남기고 나머지는 압축, 진단 안내문은 직접 부를 때만 archived

- verdict: archived
- why: 라우터 9,670→7,115B(−26%), 매 턴 스택 ≈9.0KB, 변동 턴 preflight ≈1.5KB. 언어·쉬운 말·답 모양 절은 md5 로 고정, 위임 절은 full.md 로. 지켜야 할 것: 다른 검사가 정확한 문구로 고정한 계약 문장(nothing worth keeping · rejected on purpose · Short turns skip this question entirely · no conversation file yet, open one · one question per turn · dependent question or one Decisions table — never both)과 명령 셋은 한 줄 안에 그대로. 상한 7,500/9,500/9,000.
- path delta: 목표 7,000B 는 고정 절 4,529B + 계약 문구·명령 ≈1,000B 가 바닥이라 7,115B 에서 멈춤 → 사용자 결정으로 T1 7,200. 추가로 run-dry 의 printf|grep 파이프 44곳을 히어스트링으로(macOS pipefail SIGPIPE 간헐 실패).
- refs: scv/archive/20260916-wookiya1364-help-router-diet/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-17 07:28] scv-core-sync-bot — SCV 자체 그래프 — 문서·계획·동시변경을 의존성 0 으로, graphify 제거

- verdict: adopted
- why: graphify 는 52개 계획 중 실사용 0, Python+LLM 무게, 문서 그래프 하나에만 쓰임. SCV 가 이미 가진 재료(docs 링크 · 보관 계획→파일 · 결정 참조 · 동시변경)로 bash+jq 그래프를 scv/.graph/ 에 자동 재생성하고, 영향 조회(impact)를 work 헤더·회귀 앞단에 붙인다. 문서 범위 docs/+README+core/contracts(설정 키로 변경). graphify 참조 전부 제거.
- discarded alternatives: 자체 그래프만 먼저 만들고 graphify 제거는 다음 계획 — 경로가 둘 남아 기각 · 산출물 커밋(scv/graph/) — 보관마다 큰 diff 라 무시 파일로 · docs/ 만 — 계약 문서가 빠져 기각 · git numstat 동시변경 — 계획 단위가 잡음이 적어 이번엔 제외
- refs: scv/promote/20260917-wookiya1364-scv-own-graph/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-17 08:38] scv-core-sync-bot — SCV 자체 그래프 — 문서·계획·동시변경을 의존성 0 으로, graphify 제거 archived

- verdict: archived
- why: graph.sh(build/status/ensure/impact/report) + lib/graph.sh 로 scv/.graph/ 를 bash+jq 만으로 만든다(55 계획 ≈1.8초, 노드 421 · 링크 9,587). 소비처 넷·help·install-deps·host-profile·regression 이 새 그래프를 쓰고 graphify 참조 0. 지켜야 할 것: 순수부의 jq 프로그램은 함수 밖 상수(검사기가 > 와 sort_by 를 오인) · 결정적 출력(built_at 만 시각) · 없는 경로는 missing 표시 · SCV_GRAPH=off/jq 없음은 막지 않음 · 템플릿 변경 시 TEMPLATE_DIGEST · promote.md 줄 수 변화 시 guard.md 예외 앵커.
- path delta: as planned — 추가로 regression.sh 에 --dry/--changed, work.sh 에 IMPACT 블록. 놀란 것: 순수성 검사기가 jq 본문의 비교 연산자(>)를 리다이렉션으로, sort_by 를 sort 명령으로 읽음 → jq 프로그램을 함수 밖 상수로. bash 의 "${1:-{}}" 가 닫는 중괄호를 덧붙이는 함정. 병렬 회귀 실행 시 빌드 2초 검사(T6)가 부하로 붉을 수 있음(단독 실행 녹색).
- refs: scv/archive/20260917-wookiya1364-scv-own-graph/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-17 08:54] scv-core-sync-bot — Graft 어댑터 — 있으면 코드 영향 범위와 관련 코드 후보를 덧붙이고, 없으면 조용히 생략

- verdict: adopted
- why: 자체 그래프(이력)와 Graft(현재 의존)는 겹치지 않는다. Graft 를 필수가 아닌 선택 제공자로: graft 가 PATH 에 있고 graft/ 가 있으면 회귀 앞단에 blast(정적 영향), work/promote 헤더에 ask(관련 코드 후보). 없으면 GRAFT_STATUS: absent 한 줄뿐. 설치·init·훅은 SCV 가 하지 않는다(--no-hooks --no-statusline 안내만). Graft 는 bash 미지원 — 이 저장소에선 실증 불가, 가짜 graft 픽스처로 계약 검증.
- discarded alternatives: Graft 결과를 자체 그래프에 합치기 — 스키마가 문서화되지 않아 이번엔 나란히만 · 이번 릴리스에서 제외 — 사용자가 포함을 택함
- refs: scv/promote/20260917-wookiya1364-graft-adapter/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-17 09:18] scv-core-sync-bot — Graft 어댑터 — 있으면 코드 영향 범위와 관련 코드 후보를 덧붙이고, 없으면 조용히 생략 archived

- verdict: archived
- why: graft.sh(status/blast/ask) + lib/graft.sh. 없으면 GRAFT_STATUS: absent 한 줄이 유일한 차이. ready 면 회귀 앞단 blast 블록·work 헤더 ask 후보. 지켜야 할 것: SCV 는 graft 를 설치·init·build·훅하지 않음 · 시간 제한·실패는 exit 0 · 자체 그래프 블록 아래에만 · 소스에 제어 문자 없이 jq 유니코드 이스케이프로 구분자.
- path delta: as planned — 놀란 것: Graft 는 bash 미지원(이 저장소에서 실증 불가, 픽스처로 계약 검증). 소스에 US 제어 문자를 넣으면 이 도구의 명령 검증에 걸린다 — jq 이스케이프로 대체.
- refs: scv/archive/20260917-wookiya1364-graft-adapter/PLAN.md
- conversation: scv/conversations/20260914-092553-install-check-0-47-0.md

## [2026-09-17 14:52] scv-core-sync-bot — 변경 지도 — 계획서가 바뀔 함수를 선언하고, Graft 가 대조하고, 문서가 그린다

- verdict: adopted
- why: 읽는 사람이 추가·변경·삭제를 그림으로 한눈에 보게 한다. 파이프라인 절과 화면의 단계 태그가 이미 있으므로, 새 개념을 넣는 대신 빈칸을 메우는 일로 잡았다. Graft 는 선택 제공자로 두어 없어도 문서가 완성된다.
- discarded alternatives: Graft 가 A/M/D 를 직접 판정하게 하는 안 — Graft 는 존재하는 코드만 보므로 구현 전 계획에서는 빈 결과가 나온다. / 계획서에 표를 미리 적어 고정하는 안 — 실제 변경과 벌어진다. / 파일 단위 A/M/D — 함수 단위여야 화면·파이프라인과 이어진다.
- refs: scv/promote/20260917-wookiya1364-deck-change-map/PLAN.md
- conversation: scv/conversations/20260917-133700-release-0512-verify.md

## [2026-09-17 17:23] scv-core-sync-bot — 변경 지도 배송 + 고정 밀리초 예산 제거

- verdict: archived
- why: 계획서가 함수 단위로 추가·변경·삭제를 선언하고, deck 이 그것을 상태별 색 그림과 표로 그린다. 화면의 번호도 자기를 움직이는 함수와 그 상태를 함께 보여준다. Graft 는 선언을 코드와 대조하는 선택 제공자이며, 없으면 설치 명령만 안내하고 나머지는 그대로 그려진다. 함께, 세 검사에 박혀 있던 고정 밀리초 예산을 기계 사정에 맞춰 늘어나는 예산으로 바꿨다 — 이것이 부하에서 계획 25건을 한꺼번에 붉게 만들던 원인이다.
- discarded alternatives: Graft 가 추가·변경·삭제를 직접 판정하게 하는 안 — 존재하는 코드만 보므로 구현 전에는 빈 결과가 난다. / 흔들리는 단언에 재시도를 붙이는 안 — 실패를 두 번 기다릴 뿐 기준이 여전히 기계에 달려 있다. / 예산을 그냥 크게 키우는 안 — 빠른 기계에서 진짜 느려짐을 놓친다.
- path delta: 계획에 없던 일 셋을 더했다. (1) Graft 응답을 원본 JSON 대신 어댑터의 사람용 후보 줄로 읽는다 — JSON 모양 추정은 어댑터가 이미 떠안고 있어 두 번 할 이유가 없었다. (2) deck 프로토콜에 변경 지도 절을 넣었다 — 약속 문서가 실제 동작을 말하지 않으면 계약이 아니다. (3) 검증 도중 발견한 시간 예산 흔들림을 같은 계획 안에서 고쳤다. 순수 단계는 계획의 5개가 아니라 7개로 나뉘었다.
- refs: scv/archive/20260917-wookiya1364-deck-change-map/PLAN.md
- conversation: scv/conversations/20260917-133700-release-0512-verify.md

## [2026-09-18 11:22] scv-core-sync-bot — 지난 작업 찾기 — 제목이 아니라 본문까지 훑는다

- verdict: adopted
- why: 제목만 보고 고르면 놓친다 — '회귀' '훅' '설정' 은 제목에 0건인데 본문에 25~30건씩 있다. 본문 전체 훑기는 37ms 로 사실상 공짜인데 쓰지 않고 있었다. 결정 기록을 이름으로 꺼내 그 구간만 읽는 기존 도우미와 같은 방식을 아카이브 검색에도 적용한다.
- discarded alternatives: 의미 검색(임베딩) — 설치할 것이 늘어나 '설치 없이 돈다' 는 원칙이 깨진다. / 색인 파일을 미리 만들어 두기 — 훑는 데 37ms 면 충분하고 색인은 낡는다. / 제목 목록을 없애기 — 새 훑기가 빈손일 때 돌아갈 자리가 필요하다. / Code Mode 의 자바스크립트 실행 환경 도입 — 같은 이유로 원칙과 충돌한다.
- refs: scv/promote/20260918-wookiya1364-archive-body-search/PLAN.md
- conversation: scv/conversations/20260917-133700-release-0512-verify.md

## [2026-09-18 12:33] scv-core-sync-bot — 지난 작업 찾기 본문 훑기 배송

- verdict: archived
- why: 제목만 보던 아카이브 검색이 본문까지 훑는다. 보관된 계획서와 그 검사·구조·보관 기록, 소비된 원자료, 대화(보관 하위 폴더 포함), 결정 기록 244파일 22,510줄을 한 번에 보고 맞는 대목만 출처와 함께 낸다. 줄 단위로 함께 나온 낱말 수를 세고 계획 폴더로 묶어 대표 줄 하나만 보인다. 읽기만 하며 설치할 것을 늘리지 않는다.
- discarded alternatives: 의미 검색 — 설치할 것이 늘어 원칙과 충돌. / 미리 만드는 색인 — 훑는 데 0.2초면 충분하고 색인은 낡는다. / 제목 목록 제거 — 훑기가 빈손일 때 돌아갈 자리가 필요하다. / 파일 단위 점수 — 한 계획이 네 문서로 상위를 독차지하고 보여주는 대목이 엉뚱해진다.
- path delta: 계획대로 갔지만 구현 중 내 실수 넷을 잡았다. (1) 계획에 적어둔 '한 번에 끝내라' 를 내가 어겨 줄마다 셸로 돌려 11초가 걸렸다 — 그 규칙은 훑기 뒤 계산에도 적용된다. (2) 따옴표가 깨진 줄이 74KB 에 셸 치환을 돌려 1.5초를 먹었다. (3) 검색 도구는 파일이 하나뿐이면 이름을 생략한다 — 이름 표시를 강제하지 않으면 기록이 하나인 프로젝트에서 항상 빈손이 된다. (4) 이 시스템의 문자 도구가 한글을 바이트로 세어 자르기가 글자를 깼다 — 자르기를 보여줄 몇 줄로 옮겼다. 그리고 외부 명령을 쓰는 함수는 순수가 아니라 결정적으로 표시해야 하고, awk 프로그램 글은 함수 밖 상수로 둬야 검사기가 오해하지 않는다.
- refs: scv/archive/20260918-wookiya1364-archive-body-search/PLAN.md
- conversation: scv/conversations/20260917-133700-release-0512-verify.md

## [2026-09-20 12:13] wookiya1364 — 규칙 헌법 — 최상위 불변식과 해소 순서 한 문장

- verdict: adopted
- why: 규칙이 프로토콜 3,811줄·훅·계약·템플릿에 흩어져 서로 어긋나는 쌍이 여섯(A~F) 확인됐고, 근본 원인은 우선순위를 말하는 자리가 세 곳에 국소적으로만 있고 전역 규칙이 없다는 것. SCV.md Top-level rules 를 최상위 층으로 승격해 조항 7개 이하 + 해소 순서 한 문장을 한 곳에만 두고, 옛 3곳은 참조로 바꾸고, 유일성 검사와 중복 요구 래칫으로 재발을 막는다.
- discarded alternatives: 저장소 전용 계약 문서(core/contracts)에 두기 — 런타임 에이전트가 읽지 못하고 다운스트림에 배송되지 않는다. / 개념 1(삭감 일괄 결정 표)을 먼저 도입 — regression.md 21행과 정면 충돌, 기존 충돌을 먼저 해소해야 한다. / 결정 프리미티브화(개념 5)를 먼저 — 위계 없이 큰 규칙을 하나 더 얹는 것과 같다. / 검사 b 를 첫날부터 게이트로 — 의도된 반복 문장이 많아 오탐으로 막힌다, 래칫으로 시작. / 옛 우선순위 문장 3곳을 그대로 두고 헌법이 인용 — '한 곳에만' 이 약해진다.
- refs: scv/promote/20260920-wookiya1364-rule-constitution/PLAN.md
- conversation: scv/conversations/20260920-112254-jev-laya-concepts-scv.md

## [2026-09-20 12:25] wookiya1364 — 충돌 A 해소를 규칙 헌법 계획에 합친다

- verdict: adopted
- why: 해소 순서만 두면 지금 텍스트에서는 더 좁은 regression 규칙(슬러그마다 질문)이 이겨, 배송 직후 판정이 사용자 결정(help 쪽 결정 표 하나)과 반대가 되는 공백이 생긴다. regression.md 의 삭감 질문 규칙 한 곳을 원문 불변 예외에 더해 이 계획에서 함께 고치고 대체 선언을 붙여 공백을 없앤다. 구현체를 보고 어색하면 되돌린다.
- discarded alternatives: 후속 계획 ②로 미루기 — 릴리스 사이에 결정과 반대인 판정 공백이 남는다. / work.md 9c 의 슬러그별 supersede 확인까지 함께 고치기 — 삭감과 다른 상황, 범위가 번진다.
- refs: scv/promote/20260920-wookiya1364-rule-constitution/PLAN.md
- conversation: scv/conversations/20260920-112254-jev-laya-concepts-scv.md

## [2026-09-20 14:27] wookiya1364 — journal-index 계약을 obsolete 로 — 검사 파일이 decision-index 에서 지워졌다

- verdict: obsolete
- why: 보관 계약의 실행 명령이 core/tests/test-journal-index.sh 를 가리키는데, 그 파일은 20260824 decision-index(f124557 '결정이 스스로 색인된다')가 지웠다. decision-index 가 supersedes 를 선언했어야 했으나 비어 있어 회귀에서 붉었다. 기능은 decision-index 가 이어받았다.
- refs: scv/archive/20260823-wookiya1364-journal-index/PLAN.md

## [2026-09-20 14:27] wookiya1364 — deck-change-map 계약을 obsolete 로 — 배송되지 않은 검사 파일을 가리킨다

- verdict: obsolete
- why: 실행 명령이 core/tests/test-timing-budget.sh 를 요구하지만 그 파일은 git 이력에 없다 — 같은 배송에서 고정 밀리초 예산을 제거하며 검사도 함께 사라졌다. 기능(변경 지도)은 살아 있고 test-deck-change-map.sh 가 core 검사 루프와 CI 에서 계속 돈다. 회귀 목록에서만 뺀다.
- refs: scv/archive/20260917-wookiya1364-deck-change-map/PLAN.md

## [2026-09-20 17:59] wookiya1364 — 규칙 헌법 배송 — 조항 7 + 해소 순서 한 곳, 충돌 A 닫힘, 재발 검사

- verdict: archived
- why: scv/SCV.md Top-level rules 가 최상위 층이 됐다: 조항 7개(묻고 추측하지 않는다·보관 불변·영수증 없는 쓰기 금지·같은 요구는 한 곳에만·검증 없는 완료 선언 금지·순수함수 파이프라인·사용자에게 양보)와 출처, 해소 순서 한 문단. 우선순위를 말하던 3곳은 참조로. regression 삭감은 결정 표 하나로(옛 규칙 대체 선언). 검사 (a) 우선순위 서술 유일성 게이트 + (b) 중복 요구 래칫(기준선 11, 그중 2는 13개 프로토콜에 복제된 쉬운 말 절 — 4조의 최대 위반이 첫날 드러남). 지켜야 할 것: 새 규칙 문서는 우선순위를 적지 말고 Top-level rules 를 참조한다. 허용목록에 후속이 참조로 바꿀 work.md 두 줄이 남아 있다.
- path delta: 넷. (1) 조항 구성 — 옛 1·2조를 합치고 순수함수 파이프라인을 6조로: codegen 의 'Guardrails 는 파이프라인 규칙을 못 이긴다' 를 참조로 바꾸려면 파이프라인이 헌법 층이어야 뜻이 보존된다. (2) TEMPLATE_VERSION 을 올리지 않음 — 릴리스 규칙(스키마 변경에만)과 지문 기반 자동 갱신을 구현 중 확인. (3) 순수부를 core/scripts/lib 로 — 순수성 검사기가 거기만 본다; 첫 판에 awk 비교 연산자를 리다이렉션으로 오해한 위반 2건을 잡아 상수로 뺐다. (4) 사용자 지시로 계획 밖 수정 5건: 맥 전용 테스트 버그 2건(GNU sed -i, awk \x 16진 BOM), 회귀 실행기가 설정값(SCV_LANG)을 자식에 흘리던 것(env_load 가 새로 내보낸 키만 지움, T7), 보관 색인이 보관 때만 재생성되어 obsolete 표시가 효력 없던 것(archive-index.sh 추출 + 삭감 절차에 새로 고침 단계), 지워진 검사 파일을 가리키던 계약 2건 obsolete. 회귀 17건 붉음 → 43/43 초록. 리눅스 실측은 PR CI 에서.
- refs: scv/archive/20260920-wookiya1364-rule-constitution/PLAN.md
- conversation: scv/conversations/20260920-112254-jev-laya-concepts-scv.md

## [2026-09-20 20:52] wookiya1364 — Graft 안내 — 계획·구현 때 먼저 알리고 설치까지

- verdict: adopted
- why: Graft 는 선택 제공자라 없으면 status 한 줄만 찍히고 끝나, 사용자가 무엇이 좋아지는지·어떻게 설치하는지 들을 기회가 없었다. absent 이고 Graft 지원 언어 파일이 있을 때만 promote·work·codegen 헤더에 안내 한 줄(효과 + 설치 명령)을 실어 프로토콜이 그대로 전달한다. 문구·설치 명령은 lib 한 곳(4조). 강제 아님 — 묻지도 막지도 않는다.
- discarded alternatives: 설치를 묻는 질문 추가 — 강제로 읽힌다, 사용자가 '강제는 아니다' 라고 함. / 모든 액션에 안내 — 매 턴 반복은 피로. / 언어 판별 없이 항상 안내 — bash 저장소에서 설치해도 빈 결과가 나와 신뢰를 잃는다. / 프로토콜마다 문구를 적기 — 4조 위반, 검사 (b) 에 걸린다.
- refs: scv/promote/20260920-wookiya1364-graft-guidance/PLAN.md

## [2026-09-20 20:52] wookiya1364 — 규칙 충돌 후속 — B~E 해소, 허용목록 두 줄 참조화, pr-helper 재실행 누출

- verdict: adopted
- why: 규칙 헌법이 남긴 것들을 한 계획으로 닫는다. B 는 B0 에 '주제가 명백히 다르면 새로 열고 한 줄' 예외, C 는 상시 문구에 단계 규칙 우선(참조) + 래퍼 두 곳 핸드오프 이슈, D 는 기록 의무를 contracts/recording.md 한 곳에 두고 대화 있는 액션 7개에 포인터, E 는 sync 동의 기준 한 문장. work.md 두 문장을 참조화해 허용목록의 '후속' 줄을 비우고, 실행기의 설정 누출 차단 함수를 lib 로 올려 pr-helper 재실행도 같은 것을 쓴다.
- discarded alternatives: C 를 래퍼 파일 직접 수정으로 — 어댑터 소유 영역, 이 저장소에서 안 고친다. / D 를 헌법 조항으로 — 조항은 7개 상한이고 절차 본문은 계약이 맞다. / D 를 변경 액션 4개로만 — 읽기 액션도 사용자 말이 오가므로 7개. / 기존 5개 기록 문장을 계약으로 통째 이전 — 원문 수정이 커져 이번엔 링크만.
- refs: scv/promote/20260920-wookiya1364-rule-conflicts-followup/PLAN.md

## [2026-09-20 21:46] wookiya1364 — Graft 안내 배송 — 없으면 무엇이 좋아지는지와 설치 방법을 헤더 한 줄로

- verdict: archived
- why: graft.sh status 가 absent/no-graph 이고 저장소에 Graft 지원 언어 파일이 있을 때 GRAFT_NOTICE 한 줄(효과 + 설치 또는 init 명령)을 낸다. promote·work 헬퍼가 헤더에 그대로 실고 프로토콜은 '그대로 전달' 한 문장. 지원 언어 판별은 추적 파일 확장자 ∩ README 언어 목록(lib 상수). 문구·설치 명령은 lib/graft.sh 한 곳, install-deps 도 상수 참조. 지켜야 할 것: 안내는 한 줄이고 묻지도 막지도 않는다; 문구를 다른 파일에 복제하지 않는다.
- path delta: 셋. (1) 이 저장소는 bash 만이 아니었다 — DeckUI JS/TS 29개가 지원 언어로 잡혀 여기서도 안내가 나온다(규칙대로, 거짓 안내 아님); 비율 임계값은 두지 않았다. (2) codegen 프로토콜에는 문장을 더하지 않았다 — work Steps 1–5b 를 verbatim 으로 따른다고 이미 적혀 있어 더하면 4조 위반. (3) no-graph 는 설치 명령이 아니라 graft init 안내로 확정. 그 외 as planned.
- refs: scv/archive/20260920-wookiya1364-graft-guidance/PLAN.md

## [2026-09-21 00:52] wookiya1364 — 규칙 충돌 후속 배송 — B~E 닫힘, 기록 계약 한 곳, 누출 차단 함수 하나

- verdict: archived
- why: B: help B0 에 '주제가 명백히 다르면 묻지 않고 새로 열고 한 줄' 예외. C: 상시 문구에 '실행 중 액션의 단계 규칙이 먼저(해소 순서 참조)' + 래퍼 둘에 핸드오프 이슈(#269, #206). D: core/contracts/recording.md 가 기록 의무의 유일한 본문, Core 프로토콜 13개가 ## Recording 한 줄로 가리킨다. E: sync 동의 기준 한 문장(삭제 없는 갱신 자동, 삭제 있으면 미리보기+승인). work.md 두 문장 참조화 → 허용목록의 '후속' 줄 0. env_settings_unset_args 를 lib 로 올려 실행기·pr-helper 가 같은 함수(T8). 지켜야 할 것: 새 프로토콜은 ## Recording 절과 우선순위 참조형을 갖는다; 보관 계약이 고정한 구절은 문장을 고칠 때 한 줄 안에 살려 둔다.
- path delta: 다섯. (1) ## Recording 절은 쉬운 말 절 뒤에 — run-dry 가 쉬운 말 절의 위치를 고정한다. (2) 절 삽입으로 guard 계약의 줄 번호 앵커 3개가 +4 밀려 고쳤다 — 줄 번호 앵커는 깨지기 쉽다(후속: 문구 앵커). (3) help.md 크기 예산(7200B) 때문에 포인터를 한 줄로 줄여 13개 모두 같은 한 줄. (4) regression 프로토콜도 포함(12→13). (5) 8월 보관 계약 T3 가 'Guardrails override them' 구절을 grep 으로 고정하고 있어, 새 참조형 문장 안에 그 구절을 한 줄로 살렸다 — supersedes 로 그 계획을 통째 건너뛰는 것은 과했다.
- refs: scv/archive/20260920-wookiya1364-rule-conflicts-followup/PLAN.md

## [2026-09-21 07:51] wookiya1364 — 미결 6건 후속 — 결정 계약 한 곳, 중복 검사 허용목록, 갱신 거부 때 커밋 안내

- verdict: adopted
- why: 어제 보관한 세 계획이 남긴 미결 여섯을 사용자 결정대로 닫는다: 1 Graft 언어 목록은 README 와 일치 확인(날짜 갱신), 2 no-graph 분기는 0.55.0 에 이미 있음, 3 대화 있는 액션 7개 유지, 4 결정 로그 설명 단락을 contracts/decisions.md 한 곳으로, 5 자동 갱신 PARTIAL·drift 문구에 커밋 안내, 6 검사 (b) 의도된 반복은 이유 있는 허용목록으로. 끝나면 코어 0.56.0 과 래퍼 둘 릴리스.
- discarded alternatives: help 라우터의 턴 기록 블록 축약 — full.md 없이도 서야 하는 계약이고 예산 안이라 두었다. 검사 (b) 알고리즘 변경 — 오탐은 허용목록으로 충분하다. 미결 2 를 다시 구현 — 이미 있고 검사가 잠근다.
- refs: scv/promote/20260921-wookiya1364-open-items-followup/PLAN.md
- conversation: scv/conversations/20260921-073800-plugin-0550-apply-check.md

## [2026-09-21 07:51] wookiya1364 — 미결 2 — Graft no-graph 분기는 0.55.0 에 이미 닫혔다

- verdict: not-needed
- why: graft-guidance 계획서의 미결 메모는 구현 중에 적혔고, 배송본의 scv_graft_notice 에 no-graph 분기(graft init 안내)가 있으며 test-graft-adapter.sh 가 잠근다. 사용자 결정 '분기 하나 추가' 는 확인 결과 이미 충족 — 새 코드 없음.
- refs: core/scripts/lib/graft.sh, core/tests/test-graft-adapter.sh
- conversation: scv/conversations/20260921-073800-plugin-0550-apply-check.md

## [2026-09-21 07:51] wookiya1364 — 미결 3 — 대화가 있는 액션은 7개로 유지

- verdict: adopted
- why: rule-conflicts-followup 의 D 범위 해석(status 처럼 읽기만 하는 액션도 사용자가 출력을 보고 말을 덧붙일 수 있어 포함)을 사용자가 2026-09-21 확정. 줄이지 않는다.
- discarded alternatives: 읽기 전용 액션 제외 — 그 턴의 사용자 발언이 기록되지 않는 구멍이 다시 생긴다.
- refs: scv/archive/20260920-wookiya1364-rule-conflicts-followup/PLAN.md
- conversation: scv/conversations/20260921-073800-plugin-0550-apply-check.md

## [2026-09-21 09:05] wookiya1364 — 미결 6건 후속 배송 — 결정 계약 한 곳, 허용목록으로 기준선 11→3, 갱신 거부 때 커밋 안내

- verdict: archived
- why: 결정 로그 규칙은 core/contracts/decisions.md 한 곳 — promote·work·regression 은 스크립트 블록 + 자기 엔트리 블록 + 포인터만 갖는다(run-dry [16] 계약은 그대로). 자동 갱신 PARTIAL 머리줄과 drift 설명이 '커밋(또는 되돌리기)하면 다음 액션이 갱신' 을 말한다. 검사 (b) 는 이유 있는 허용목록(6건)을 래칫 앞에서 빼고 기준선은 빚 3건만. Graft 언어 목록은 README 와 일치(23개) 확인, no-graph 는 이미 있음, 대화 액션 7개 유지. 배운 것: bash 의 local 한 줄에서 앞 변수를 참조하면 확장이 먼저라 바깥 값을 본다 — ratchet_new 가 전역 base 를 읽던 잠복 버그를 함께 고쳤다. 줄 번호 앵커(guard.md)는 프로토콜을 줄이면 반드시 어긋난다 — 후속에서 문구 앵커로.
- path delta: 계획대로 — 단, 예상 못 한 두 가지: guard.md 의 줄 번호 앵커 재지정(986→975), 범위 목록의 줄 끝 주석이 드리프트 검사 글로브를 깨서 주석을 별도 줄로.
- refs: scv/archive/20260921-wookiya1364-open-items-followup/PLAN.md
- conversation: scv/conversations/20260921-073800-plugin-0550-apply-check.md

## [2026-09-21 15:28] wookiya1364 — 후속 다섯 — 문구 앵커, 경계 계약 한 곳, 재실행 시간 초과 안내

- verdict: adopted
- why: 0.56.0 배송이 남긴 후속 다섯을 한 번에 닫는다: 가드 예외 앵커를 줄 번호에서 문구로(문서를 줄여도 어긋나지 않게), 세 프로토콜의 경계 문장을 contracts/boundaries.md 한 곳으로(검사 (b) 기준선 0), pr-helper 증거 재실행이 시간 초과면 그렇게 말하게(원인 추정: 600초 제한). 코덱스 갱신 명령 문구는 래퍼 PR #215 로 이미 정정. 끝나면 코어 0.57.0 + 래퍼 둘.
- discarded alternatives: 재실행 기본 제한 상향 — 일반 프로젝트엔 600초가 충분하고 이 저장소는 설정으로 올린다. 9c 질문 템플릿 반복을 한 문서로 모으기 — 두 액션이 각자 사용자에게 보여주는 템플릿이라 허용목록에 이유와 함께.
- refs: scv/promote/20260921-wookiya1364-followup-five/PLAN.md
- conversation: scv/conversations/20260921-152000-plugin-0560-apply-check.md

## [2026-09-21 16:39] wookiya1364 — 후속 다섯 배송 — 문구 앵커, 경계 계약 한 곳, 재실행 종료 사유 안내

- verdict: archived
- why: 가드 예외는 문구 앵커(path:"문구" — 이유)로, 검사는 문구가 한 줄에만 있고 그 줄이 어휘에 걸리는지 보며 자가검사 3건이 잠근다. 경계 요구 셋은 contracts/boundaries.md 한 곳, 세 프로토콜은 규범 어휘 없는 포인터 한 줄(포인터가 규범 어휘를 담으면 그 자체가 새 중복 키가 된다 — 배운 것). 검사 (b) 기준선 0. pr-helper 재실행은 124 면 시간 초과 문구 + 설정 키, 그 외 종료 코드. 아침의 비정상 종료 원인은 미확정 — 단독 272초라 시간 초과 단독으론 아니고, 61건 회귀와 동시 실행 중이었다; 이제 메시지가 구분해 준다. 코덱스 갱신 명령은 래퍼 PR #215 + 릴리스 본문 편집으로 정정.
- path delta: 계획대로 — 단, 원인 조사(5)는 재현 실패로 '가설 + 관측 가능성 확보' 에서 멈췄다. 편집 도구 실수(perl 치환이 파일 앞에 삽입) 두 번을 줄 번호 스플라이스로 복구.
- refs: scv/archive/20260921-wookiya1364-followup-five/PLAN.md
- conversation: scv/conversations/20260921-152000-plugin-0560-apply-check.md

## [2026-09-21 19:43] wookiya1364 — 과정 계기판 — 이 프로젝트의 파일로 SCV 과정을 숫자로 본다

- verdict: adopted
- why: SCV 는 과정을 강제하는 장치는 촘촘한데 그 과정이 도움이 됐는지 재는 장치가 없다. 기존 파일(아카이브 색인·계획서·대화·결정 로그)만 읽는 읽기 전용 스크립트 하나로 지표 넷(계획당 턴 수·승인→보관 리드타임·후속 재발률·순수 절 보유율)을 적용 범위와 함께 결정적으로 찍는다. 각 프로젝트가 자기를 재는 계기판이지 제품 통계가 아니다 — 진단이지 증명이 아니다.
- discarded alternatives: 원격 텔레메트리·옵트인 수집: 대화 파일을 읽는 플러그인이 밖으로 보내면 신뢰 문제, 옵트인 비율 낮아 전수 불가 · 훅에 새 로깅: 지표가 쓸모 있는지 먼저 보고 · TESTS 첫 통과율 포함: 기존 파일에 구조적 기록이 없어 계산 불가, 후속으로 · status 액션에 한 줄: 숫자 검증 뒤 후속 · 후속 재발을 이름 패턴으로: 정밀도 우선, 구조 신호만 · 실제 저장소 숫자를 테스트 기대값으로: 보관마다 바뀜 · 사용자 언어 순수성 기계 게이트: 별도 계획 · 다른 첫걸음(열린 고리 닫기·아카이브 교훈 합성·위험 등급별 의식·적응형 발판·추정 보정): 측정이 나머지의 근거
- refs: scv/promote/20260921-wookiya1364-process-metrics/PLAN.md
- conversation: scv/conversations/20260921-192248-scv-growth-directions.md

## [2026-09-21 20:08] wookiya1364 — 저널 커밋은 scv-core 만 — 템플릿 기본값은 선택 사항 유지

- verdict: not-needed
- why: scv-core 는 대화·계획·저널 전부를 커밋한다(발전의 투명한 근거). 템플릿 .gitignore.fragment 의 저널 무시 기본값은 바꾸지 않는다 — 다른 프로젝트에서 저널 커밋은 여전히 선택 사항.
- discarded alternatives: 템플릿 기본값도 저널 커밋으로: 모든 사용자 프로젝트의 git 정책이 바뀌어 CHANGELOG·sync 안내가 필요 — 사용자가 불필요하다고 결정
- refs: .gitignore
- conversation: scv/conversations/20260921-192248-scv-growth-directions.md

## [2026-09-21 21:07] wookiya1364 — 과정 계기판 배송 — 기존 파일만 읽어 지표 넷을 적용 범위와 함께 찍는다

- verdict: archived
- why: metrics.sh 가 아카이브 색인·계획서·대화·결정 로그만 읽어 계획당 턴 수 · 승인→보관 리드타임 · 후속 재발률(구조 신호만) · 순수 절 보유율을 n/m 과 함께 결정적으로 찍는다. 순수부 14 함수는 bash 3.2 내장만 쓰고 check-purity 를 통과한다. 첫 측정: 순수 절 28/63, 턴 수 적용 29/63(중앙값 6), 리드타임 적용 43/63(중앙값 51분), 후속 6/63. 배운 것: 탭 구분 레코드의 첫 필드가 비면 read 가 앞 탭을 잘라 필드가 밀린다(빈 값은 '-'); bash 3.2 는 단락 평가 뒤에도 음수 첨자를 오류로 보고 빈 배열 "${a[@]}" 를 unbound 로 본다 — 픽스처가 셋 다 잡았다. 이제부터 깨지면 안 되는 것: 읽기 전용, 시각·난수 없음, 데이터 없는 계획은 0 이 아니라 none.
- path delta: 계획은 lib/yaml.sh 재사용을 적었으나 그 도우미는 파일을 직접 읽어 순수부에서 부를 수 없다 — 텍스트 파서를 새로 썼다. 나머지는 계획대로.
- refs: scv/archive/20260921-wookiya1364-process-metrics/PLAN.md
- conversation: scv/conversations/20260921-192248-scv-growth-directions.md
