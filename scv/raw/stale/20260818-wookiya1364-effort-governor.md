# effort governor — 작업 무게에 맞춘 자동 실행 조절, 근거와 결정

2026-08-18. 대표님 요구: "가벼운 작업에도 항상 ultra 가 돌아 비용 낭비다. 매번
effort 를 손으로 바꾸는 건 못 할 짓이다. scv 가 알아서 맞추되, 권고만 하고 마는
건 켜나마나다 — 차라리 자동으로 하든가, 물어보려면 객관식으로 물어라. 기본은
auto." 기본 모드 auto 는 객관식으로 확정받았다.

## 확인 1 — 호스트가 허용하는 것과 안 하는 것

- 메인 세션의 effort 다이얼(호스트의 effort/추론강도 설정)은 **사용자 소유**다.
  모델에게 그것을 바꿀 도구가 없다. 두 호스트 공통.
- 그러나 **실행 방식은 모델 소유**다: (a) 서브에이전트 정의와 워크플로 호출은
  per-call effort 를 받는다(호스트 하니스 문서 명시). (b) 오케스트레이션을 띄울지
  말지는 프로토콜이 정한다.
- 비용의 지배항은 다이얼이 아니라 오케스트레이션이다 — 이번 세션 실측: 워크플로
  하나당 40만~130만 토큰. 세션 다이얼을 못 돌려도, 판정이 standard 인 작업에서
  오케스트레이션을 끄고 기계 단계를 low 위임으로 돌리면 실행 비용이 판정을
  따라간다. **취소·재실행·수동 effort 변경이 전부 불필요해지는 이유.**
- economy 액션(status 등)은 이미 모델 라우팅(haiku)이 배송돼 있다 — 확률 판정
  없이 결정적. 이 계획의 대상이 아니다.

## 확인 2 — 판정 규칙은 백테스트를 통과한 것만 싣는다

아카이브 14건 전부에 소급 검증했다 (판독 14 에이전트 × effort low + 종합 1).
**적중 13/14 (92.9%), 과소 배정 1건, 과대 배정 0건.**

살아남은 규칙 (순서대로 첫 일치):

```
R1  frontmatter parallel_groups 선언   → orchestration
R2  래퍼 후속(cross-repo) 선언          → heavy
R3  나머지                             → standard
```

데이터가 기각한 가설 — 싣지 않는다:
- 시나리오 수: 0개짜리가 heavy 4건, 21개짜리가 standard. 신호 아님.
- Guardrails 수: 0개가 heavy 4건, 14개가 standard. 역상관에 가깝다.
- adversarial 요구 단독: standard·heavy·orchestration 전 밴드에서 발화. 단독
  분리력 없음.
- light 밴드 예측: 실측 0건. 지어낸 문턱은 비싼 방향의 미스가 된다. light 는
  economy 액션과 기계 단계에만 결정적으로 존재하고, 예측 밴드로는 실측 3건이
  쌓일 때까지 닫는다.

유일한 미스(sync-autopilot: heavy 예측, 실제 orchestration — 적대검증 4렌즈
33건)는 비싼 방향이었다. 그 계열의 사전 신호는 raw 크기 하나뿐인데 이웃과
1,140바이트 차이의 단일점 적합이라 규칙으로 싣지 않고 **승급 사전 무장 힌트**로
만 쓴다: {cross-repo, adversarial 요구, raw ≥ 9000B} 중 2개 이상이면 자동 승급을
미리 장전.

## 확인 3 — 오분류의 비대칭과 자동 승급

- 구현·검증 단계에서 과소 배정은 품질 사고, 과대 배정은 유한한 토큰 낭비다.
  그래서 경계는 위로 라운딩하고, **자동 승급(올리는 방향만)** 이 백스톱이다:
  같은 단계 테스트 2회 연속 적색, 또는 검증자 반박 복수 발생 → 재승인 없이 한
  밴드 위로, 한 줄 통지 후 계속. 검증 도중 강등은 없다.
- 기계 단계(스캔·투영·보고)는 반대: 재실행이 싸고 자기증명적이므로 아래로
  라운딩, 항상 low 위임.
- 이 구조 덕분에 "자동으로 낮추기"가 안전하다 — 낮게 틀리면 사고가 아니라
  몇 분의 지연으로 끝난다.

## 결정 — 판정은 스크립트, 집행은 프로토콜

**`core/scripts/effort-class.sh <plan-dir|PLAN.md>`** (신규, 결정적):

- 출력: `EFFORT_CLASS: standard|heavy|orchestration`,
  `EFFORT_REASON: <한 줄 감사 근거>`, `EFFORT_ESCALATION: armed|normal`
- 신호 산출(전부 파일에서 셈): parallel_groups = frontmatter 존재;
  cross-repo = PLAN 본문의 wrapper/래퍼 후속 선언(대소문자 무시 grep — 백테스트
  추출과 동일 기준); adversarial = PLAN/TESTS 의 적대·변이(mutation) 요구;
  raw_bytes = raw_sources 실파일 크기 합.
- frontmatter `effort_class:` 가 있으면 **선언이 이긴다**(REASON: declared) —
  "이번 건 무조건 ultracode" 의 파일 형태.
- 판정만 한다. 세션 effort 는 스크립트가 볼 수 없으므로(호스트가 env 로 노출하지
  않음) 모드별 행동은 프로토콜(모델)이 집행한다.

**모드: `.env` `SCV_EFFORT_MODE=auto|ask|off`, 기본 auto** (미설정 = auto):

- `auto`: 판정대로 조용히 실행 + 한 줄 통지
  (`scv: 판정 standard — 절약 실행, 자동 승급 대기`). 개입 0.
- `ask`: 판정과 세션 자세가 크게 어긋날 때만 객관식 1회(두 선택지: 판정대로 /
  세션대로). 고르는 즉시 그 방식으로 계속 — 취소·재실행 왕복 없음.
- `off`: 아무 출력도 판정도 없음. 전부 세션 설정 그대로 = 현재 동작과 동일.
- 어느 모드든 사용자의 그 자리 한마디("이번 건 ultracode로")가 최우선.
- 어느 모드든 자동 승급은 동작(품질 보호 방향만).

**집행(프로토콜 텍스트)** — work.md·codegen.md 에 "Effort governor" 절:

- Step 6 직전에 effort-class.sh 실행, 모드별 분기.
- 밴드→실행 정책: standard = 이 계획 범위에서 오케스트레이션 금지, 기계 단계는
  low 위임, 구현은 본류; heavy = high 위임 허용 + 단일 적대 검증 + 힌트에 따라
  승급 장전; orchestration = 계획이 계약한 다중 검증(호스트가 지원할 때 —
  병렬 능력 없는 호스트는 기존 parallel_groups 규칙처럼 순차 강하).
- 승급 트리거와 "검증 중 강등 금지"를 명문화.
- 아카이브 시 --reason 에 판정·실제 사용 밴드를 남긴다 — 92.9% 를 갱신할 실측
  데이터가 스스로 쌓인다.

**부속**: `.env.example.scv` 에 SCV_EFFORT_MODE 문서화 한 줄.

## 결정 2 — 6레벨 전부의 제자리: 예측이 아니라 격자

대표님 추가 요구: 3개만 쓰지 말고 low·medium·high·xhigh·max·ultracode 6개를
전부 최적 조건에 배치하라. 원칙을 지키며 푼다 — **예측은 여전히 밴드 3개**
(백테스트된 것)만 하고, 6레벨은 밴드×단계의 결정적 격자에서 자리를 얻는다.
새로 지어낸 확률 문턱은 하나도 없다.

| 단계 \ 밴드 | standard | heavy | orchestration |
|---|---|---|---|
| 기계 (스캔·투영·덱 생성·판독) | low | low | low |
| 경량 종합 (보고 조립·요약·분류) | medium | medium | medium |
| 구현 | high | xhigh | xhigh |
| 검증 | high (단일) | max (강한 단일 적대) | ultracode (다중 렌즈 팬아웃) |

- 세로축(단계)은 **결정적** — 판단이 아니라 작업 종류다. 기계 단계가 low 로
  충분하다는 것은 이 저장소가 실측했다(백테스트 판독 14건 자체가 low 로 돌았고
  전건 정상).
- 가로축(밴드)만 예측이고, 그건 13/14 짜리 규칙이다.
- **ultracode 칸의 정체를 정직하게**: per-call effort 값은 low~max 다섯 개뿐이고
  ultracode 는 값이 아니라 **실행 형태**(다중 에이전트 팬아웃 + xhigh 급 본류)다.
  그래서 표의 ultracode 칸은 "워크플로 팬아웃으로 검증하라(각 에이전트는 역할별
  high/xhigh)" 를 뜻한다. core 텍스트에는 호스트 레벨명이 아니라 이 실행 형태로
  적는다.
- **승급 사다리가 나머지 칸을 채운다**: high → xhigh → max → (팬아웃 전환).
  standard 구현이 두 번 막히면 xhigh, 또 막히면 max — heavy 의 칸들을 실측
  신호로 빌려 쓰는 구조라, 모든 레벨이 정적 배치 아니면 사다리 경유로 도달
  가능하다.
- **초기값의 한계 명시**: 아카이브에는 단계별 effort 실측이 없다. 이 격자는
  검증된 예측이 아니라 합리적 초기값이고, 그래서 아카이브 --reason 에
  (판정 밴드, 단계별 실사용, 승급 이력) 을 남겨 다음 백테스트가 격자를 보정한다.
  "최적" 은 선언이 아니라 기록→보정 루프의 수렴점이다.

## 예상 함정

- `core/` 호스트 중립: "ultracode" 같은 호스트 레벨명은 core 텍스트에 못 들어간다
  (금지 토큰은 아니지만 호스트 종속 개념). 프로토콜은 밴드명(standard/heavy/
  orchestration)과 "the host's session effort setting" 으로만 말한다. 레벨 매핑
  (xhigh 등)은 래퍼 README 몫.
- work.md·codegen.md 는 guidance-filter 계약 대상: full 투영 바이트 동일 검사가
  회귀 계약(regression-contract-repair T2)에 있다. 마커 균형과 lint 를 지켜야
  한다. 또 guard-consistency 의 "by hand" 구문 스윕 주의.
- effort-class.sh 의 grep 신호는 휴리스틱이다 — 백테스트 추출과 같은 기준을 쓰되,
  frontmatter `effort_class:` 선언이 항상 탈출구다. 판정 한 줄(REASON)이 감사
  가능성의 핵심이므로 생략 금지.
- ask 모드의 "크게 어긋남" 판정은 모델 몫(세션 자세는 모델만 안다) — 프로토콜에
  기준을 명시: 밴드가 세션 자세보다 두 단계 이상 낮거나 높을 때만.
- 테스트는 이번에 만든 내구성 규칙을 지킨다: git-diff 단언 금지, 실존 파일만,
  전체 스위트 재실행 금지. sentinel 은 CANARY-*-토큰.
