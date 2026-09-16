---
source: https://claude.ai/share/aa5cadb0-9c58-4876-8d8b-9e5672dc7417
captured: 2026-09-16T21:19:27+09:00
topic: Graft 부분 채택 + 계획 이력 그래프
---

# 요약 (계획 수립용)

- Graft 는 컨텍스트 검색 레이어, SCV 는 워크플로/권한 레이어 → 경쟁 아님, 결합 대상.
- 직접 구현 금지 영역: tree-sitter 23개 언어 추출기 (Graft 본체). SCV 벤더링 원칙(bash + git/jq, 런타임 외부 의존 없음)과 충돌.
- 부분 채택 = **어댑터**: "코드 컨텍스트 제공자" 계약 하나. graft 가 PATH 에 있으면 `graft ask --json` / `graft blast --base origin/main --format json` 호출, 없으면 기존 방식 폴백. (플래그 이름은 미검증 — 구현 시 확인)
  - 꽂는 곳 둘: promote(계획 세울 때 코드 구조) · regression(영향 범위 산정).
- 설치 권장: `graft init --agents claude --no-hooks --no-statusline` (pull 방식, README 벤치마크 정답률 최고). 먼저 `--dry-run`, `--no-global`, `graft telemetry disable`. 훅·statusline·settings.json 훅 블록이 SCV 와 겹치는 세 지점 — 조회(ask/blast/MCP)는 안 겹침.
- **계획 이력 그래프** (SCV 고유, 의존성 0): scv/archive 의 계획 단위로 "어떤 파일을 건드렸는지" 기록 → 파일 쌍 동시변경 카운트 + 근거(plan/DECISIONS) 링크 → JSON 하나. promote 가 조회. bash + jq. Graft 가 못 채우는 칸(정적 연결 없이 함께 바뀌는 파일, "왜").
- 세 선택지 비용: git 동시변경(의존성 0) / universal-ctags(바이너리 1) / tree-sitter(Node+네이티브, 포기).
- 결론: "코드 그래프는 빌려 쓰고(어댑터), 계획 그래프는 직접 만든다."
- 이번 세션 추가 확인: Graft 는 마크다운·문서를 색인하지 않음 → SCV 의 graphify 사용처(docs 그래프: promote 다이어그램2·deck 큰 그림·status 신선도)는 Graft 로 대체 불가. graphify 를 뺄지는 별도 결정.

# 전문

공유자: 성욱. 이는 Claude와 성욱 님 간의 대화 사본입니다. 콘텐츠에는 Anthropic의 견해를 반영하지 않는 검증되지 않았거나 안전하지 않은 내용이 포함될 수 있습니다. 공유된 스냅샷에는 여기에 표시되지 않은 첨부 파일과 데이터가 포함될 수 있습니다.
신고하기
보낸 메시지: https://github.com/anthropics/claude-code/issues/91870

https://github.com/anthropics/claude-code/issues/91870

설명해주라

그저께

Claude 응답: Claude Code에 "Function Hooks"(제품명 Claude Mods)를 추가하자는 제안 이슈입니다.
페이지 읽음

페이지 읽음

Claude Code에 "Function Hooks"(제품명 Claude Mods)를 추가하자는 제안 이슈입니다. Anthropic 직원(@poteat)이 커뮤니티 피드백을 받으려고 올렸고, 9월 9일 업데이트에서 "몇 주 내 출시 확정"으로 정리됐습니다. 지금은 CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1 claude로 실험 사용 가능합니다.

핵심 아이디어

지금 훅은 셸 스크립트를 특정 시점에 실행하는 방식인데, 이걸 TypeScript 함수로 바꾸자는 것. 구조가 Express/Koa 미들웨어와 똑같습니다.


ts
on('tool.call', async ($, e, next) => {
  if (isDestructive(e.input))
    return { decision: 'deny', reason: '...' }
  return next(e)
})
$ = 부수효과 객체(파일, 네트워크, 프로세스, UI 등 모든 권한이 여기 통과). 관리자가 $에서 특정 권한을 제거하면 그 아래 모든 플러그인이 그 부수효과를 호출할 수 없게 됩니다 — 부탁이 아니라 구조적 보장.
next = 양파 구조. 먼저 등록된 것이 나머지를 감싸므로, 관리자는 앞에 붙여 통제하고 기본값은 뒤에 붙입니다.
ui.render 훅으로 컴포넌트 props나 렌더 결과를 감쌀 수 있고, * 하나로 모든 이벤트(플러그인들의 $ 호출 포함)를 받아 감사 로그를 함수 하나로 만들 수 있습니다.

왜 사람들이 열광하는가

댓글 대부분이 같은 말입니다 — "CLAUDE.md에 적은 규칙은 강제되지 않는다". 모델이 세션 시작에 한 번 읽고 잊어버리니까요. 셸 훅은 강제는 되지만 (1) 명령어 문자열을 정규식으로 파싱해야 해서 오탐이 심하고(댓글에 git push가 본문에 언급된 GitHub 코멘트를 차단한 사례), (2) Windows에서 Git Bash가 인자를 망가뜨리고, (3) 조합·순서 개념이 없습니다. 타입 있는 함수 + argv 배열 실행($.process.run)이 이 세 가지를 한 번에 없앱니다.

논쟁의 핵심: fail-open

이슈에서 가장 뜨거운 부분이고, 실측 댓글이 많습니다. 훅이 예외를 던지거나 10초 예산을 넘기면 "skipped; what is below it ran in its place" — 즉 건너뛰고 원래 동작이 그대로 실행됩니다. 비밀정보 마스킹 훅이 죽어도 도구 출력은 모델에게 그대로 전달된다는 뜻이라, 여러 사람이 onError: 'deny' 같은 fail-closed 선언을 요구하고 있습니다. 타임아웃으로 죽은 훅은 자기 죽음을 try/catch로 잡을 수 없으니 엔진 차원의 선언이 유일한 해법이라는 논지.

그 외 반복되는 요청: CI에서 합성 이벤트로 훅을 테스트할 수 있게 해달라, $ 표면을 공식 문서화해달라(지금은 바이너리를 grep해서 알아내는 중 — 이벤트 20개, capability 36개), 기존 셸 훅도 계속 지원해달라.

성욱님 입장에선 C2E나 AI-TMR 쪽 팀 작업 규칙(커밋 컨벤션, 민감정보 마스킹 등)을 코드로 강제하는 데 바로 쓸 만한 물건입니다.


그저께
보낸 메시지: https://github.com/wookiya1364/scv-claude-code

https://github.com/wookiya1364/scv-claude-code
이거에 저 기능을 넣는게 가능할까

그저께

Claude 응답: 가능합니다.
2페이지 읽음

2페이지 읽음

가능합니다. 다만 "지금 넣을 수 있다"와 "지금 넣는 게 좋다"는 다릅니다.

기술적으로는 그대로 얹힙니다. SCV는 이미 hooks/hooks.json을 가진 정식 플러그인이라, 거기에 "modules": ["./index.ts"] 한 줄을 추가하면 됩니다. 이슈 댓글의 실측에 따르면 커맨드 훅은 함수 훅의 next() 안쪽에서 실행되므로, 기존 셸 훅을 하나도 건드리지 않고 함수 훅을 바깥에 두르는 점진 마이그레이션이 가능합니다.

SCV에서 특히 이득이 큰 지점

PreToolUse 가드 — 지금은 명령어 문자열을 파싱해서 "scv/ 밖 쓰기"를 판단하는데, tool.call의 타입 있는 이벤트로 바꾸면 오탐이 사라집니다. 이슈에 정확히 같은 사례가 있습니다(커밋 메시지에 git push가 들어있어서 차단된 경우).
always-on 라우팅 / plain-language 리마인더 — 현재 훅 stdout으로 매 턴 주입하는데, prompt.context 훅이 이걸 위해 만들어진 겁니다. 매 턴 새로 계산되고, SessionStart additionalContext의 길이 캡 문제도 우회합니다(이슈에 8,000자 캡 오측정 소동이 길게 있습니다).
Windows — README에 "Windows native 미지원"이라고 적으신 그 이유가 셸 계층입니다. $.process.run(argv)는 셸을 아예 안 거치므로 MSYS 인자 망가짐 클래스가 통째로 사라집니다. 여러 댓글이 이걸 최대 이득으로 꼽습니다.
journal 리댁션 — 지금은 기록 후 처리지만, 함수 훅은 모델이 읽기 전에 도구 출력을 다시 쓸 수 있습니다.

막는 요소들

아직 실험 플래그입니다. $ 표면이 빌드마다 바뀌고(fs.readFile → fs.read 리네임 논쟁 진행 중), 계약 버저닝이 없습니다. 마켓플레이스로 배포하는 플러그인이라 사용자 CC 버전이 제각각인데, 지금 올리면 매 릴리스마다 깨집니다.
훅당 10초 예산. /scv:regression이나 테스트 실행을 훅 안에서 돌리면 초과 → 조용히 스킵됩니다.
기본이 fail-open입니다. README에 "Fails open on internal errors"라고 이미 적어두신 성질이 그대로 유지되므로, 가드 관점에서 개선되는 건 오탐 쪽이지 강제력 쪽이 아닙니다. onError: 'deny'는 아직 요청 단계.
vendor/scv-core가 전부 bash라, 훅 레이어만 TS로 바꿔도 $.process.run(["bash", ...])으로 코어를 부르는 순간 Windows 문제는 되돌아옵니다.

현실적인 순서를 제안하면: 지금은 CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1 환경에서만 로드되는 실험 브랜치로 prompt.context 하나만 포팅해보시는 게 좋습니다. 이건 deny 권한이 없어서 실패해도 안전하고, always-on 주입이 훅 stdout보다 깔끔해지는지 바로 확인됩니다. 가드 포팅은 정식 출시 후, claude plugin validate로 CI 게이트 걸 수 있게 된 다음이 맞습니다.

한 가지 주의: 플래그가 켜진 환경에서 셸 훅과 함수 훅을 둘 다 등록해두면 둘 다 실행됩니다. 가드는 이중 판정이라 괜찮지만 journal 같은 기록성 훅은 중복 기록되니, 포팅한 이벤트는 셸 쪽에서 빼거나 서로 배타적으로 걸어야 합니다.


그저께
보낸 메시지: https://github.com/prekuter/dryforge

https://github.com/prekuter/dryforge

이건 뭐야

그저께

Claude 응답: SCV와 거의 같은 문제를 푸는 경쟁 플러그인입니다.
페이지 읽음

페이지 읽음

SCV와 거의 같은 문제를 푸는 경쟁 플러그인입니다. 다만 접근 방식이 반대쪽입니다.

한 줄 요약: 코딩 에이전트에게 "권한 경계(authority boundary)"를 씌우는 하니스. Claude Code와 Codex 양쪽을 지원하고, 진입점은 딱 세 개입니다.

ready — 요구사항을 **실행 가능한 계약(contract)**으로 변환. 애매한 결정들을 미리 사용자에게 물어서 확정
go — 승인된 계약대로만 실행. 계약과 충돌하면 자기가 해석을 바꾸지 않고 사용자에게 되돌림
migration — 기존 코드베이스를 스캔해 초기 프로젝트 문서(harness)를 구축

핵심 주장은 "에이전트 실패는 추론 실패가 아니라 권한 실패"라는 것. 그래서 권한 소유자를 표로 못 박아둡니다. 의도는 사용자가, 요구 동작은 명세가, 구현 사실은 코드가, 완료 여부는 증거가 소유. 모델의 자신감은 완료 근거가 못 됩니다. 검증 관점도 일부러 분리해서, 구현을 판단하는 쪽에는 구현자의 "왜 이게 맞는지" 설명을 안 넘깁니다. 자기 확인을 구조적으로 막는 것.

reward hacking 섹션이 이 README에서 제일 흥미롭습니다. 체크리스트를 상세하게 만들면 모델이 체크박스 채우기를 목표로 삼고, 문서 템플릿에 슬롯이 많으면 내용 없는 일반론으로 채운다 — 그래서 규칙을 더 추가하는 대신 정보와 권한 배치를 바꿔서 "가장 짧은 유효 경로"가 사용자 의도와 일치하게 만든다는 논지입니다.

SCV와의 차이

	SCV	dryforge
강제 수단	PreToolUse 훅 + CI 게이트	없음 — 전부 스킬/프롬프트
산출물	scv/ 계획·테스트·리그레션 스위트	.dryforge 계약 + 프로젝트 문서(CLAUDE.md, docs/)
발동	always-on, 대화에 끼어듦	명시적 호출만
완료 근거	실행된 테스트, PR에 e2e 영상 첨부	리스크에 비례하는 증거 floor
대상	팀 (Slack/Discord 리포트)	개인~팀, 스택 무관

즉 SCV는 테스트가 영원히 쌓이는 쪽에, dryforge는 시작하기 전에 의도를 확정하는 쪽에 무게를 둡니다. 앞선 대화의 function hooks 관점에서 보면 dryforge는 아직 강제력이 0입니다 — 문서에 "모델이 이렇게 해야 한다"고 적힌 규칙뿐이라, 이슈에서 여러 명이 지적한 "prose decays" 문제에 그대로 노출됩니다. 반대로 SCV는 이미 훅 레이어가 있어서 function hooks가 나오면 바로 이득을 봅니다.

별 179개에 커밋 17개니 최근에 올라와서 빠르게 주목받은 저장소로 보입니다. 문서 완성도가 높은 편이라 README 자체를 참고 자료로 볼 만합니다.


그저께
보낸 메시지: https://github.com/trailhq/Graft

https://github.com/trailhq/Graft

이건 어때? scv랑 결합해서쓰면 더좋나

그저께

Claude 응답: 레이어가 다릅니다.
페이지 읽음

페이지 읽음

레이어가 다릅니다. 앞의 셋(SCV, dryforge)은 워크플로/권한 레이어고, Graft는 컨텍스트 검색 레이어입니다. 그래서 경쟁이 아니라 결합 대상이 맞습니다.

Graft가 하는 일

코드베이스를 tree-sitter로 파싱해서 심볼 그래프를 만들고, LLM으로 "이 서브시스템이 뭘 하는지"를 평문으로 설명한 마크다운 노드 묶음을 graft/에 캐시합니다. 에이전트가 매 태스크마다 grep → 파일 열기 → import 따라가기를 반복하는 탐색 비용을 없애는 게 목적. SWE-bench Verified 50개로 정답률 54% → 66%, 토큰 23% 절감을 주장합니다. graft/는 커밋하지 않고 node_modules처럼 각자 빌드하는 로컬 캐시입니다.

구조 그래프(build, ask, grep, callers, map)는 모델을 아예 안 부르고 무료입니다. LLM은 --deep에서만 쓰고, 프로바이더/키는 본인 것을 씁니다.

SCV와의 결합

궁합은 좋습니다. SCV의 /scv:promote가 계획을 세울 때 코드베이스 구조를 파악해야 하는데, 지금은 매번 탐색합니다. 여기에 graft ask나 MCP의 graft_find_code가 붙으면 계획 품질과 토큰이 둘 다 개선됩니다. graft blast --base origin/main은 SCV의 리그레션 범위 결정에도 바로 쓸 수 있고요.

다만 충돌 지점이 실제로 있습니다.

훅 경합. Graft는 SessionStart / UserPromptSubmit / PostToolUse / Stop에 전부 훅을 겁니다. SCV도 매 턴 hook stdout으로 always-on 라우팅과 plain-language 리마인더를 주입하죠. 둘 다 UserPromptSubmit에 붙으면 매 턴 컨텍스트가 양쪽에서 밀려들어옵니다. 절약하려고 넣은 도구가 주입량으로 상쇄될 수 있습니다.
statusline. Graft가 .claude/settings.json에 자기 statusline을 씁니다. SCV나 기존 설정과 겹치면 --no-statusline으로 꺼야 합니다.
PreToolUse 가드. SCV 가드가 scv/ 밖 쓰기를 막는데, Graft는 CLI가 직접 graft/를 쓰므로 도구 호출을 안 거쳐서 대체로 괜찮습니다. 다만 실제로 확인은 해보셔야 합니다.

권장 도입 순서

graft init --dry-run으로 건드릴 파일 전부 확인 → graft init --agents claude --no-statusline --no-hooks로 MCP + 스킬 파일만 먼저 붙이세요. 훅 없이 MCP 도구(graft_find_code, graft_trace_calls)만 써도 README의 "pull 변형"이 오히려 정답률 98%로 가장 높게 나왔습니다. 푸시형 주입이 아니라 필요할 때만 당겨오는 쪽이라 SCV의 컨텍스트 예산과도 안 싸웁니다. 효과를 보면 그때 훅을 켜고 SCV 쪽 주입을 줄이면 됩니다.

참고로 Graft도 훅을 무겁게 쓰는 쪽이라, 앞서 본 function hooks가 나오면 같은 마이그레이션 대상입니다. 셋 중에선 Graft가 가장 성숙합니다(별 7.7k, 커밋 478, 벤치마크 방법론 공개). 텔레메트리는 기본 켜짐이니 회사 코드에 쓰신다면 graft telemetry disable로 꺼두시는 게 좋겠습니다.


그저께
보낸 메시지: scv안에 넣어서 쓰는 개념어떨까 scv에 저것중에 필요한걸 직접구현하는거로

scv안에 넣어서 쓰는 개념어떨까 scv에 저것중에 필요한걸 직접구현하는거로

그저께

Claude 응답: 직접 구현은 범위를 아주 좁히지 않으면 말리기 쉽습니다.

직접 구현은 범위를 아주 좁히지 않으면 말리기 쉽습니다. 다만 "좁힌 버전"은 꽤 말이 됩니다.

직접 만들면 안 되는 부분

Graft의 본체는 23개 언어 tree-sitter 추출기입니다. TS/Python/Go/Java/Kotlin/PHP/Swift는 스코프 인식 크로스파일 호출 해석까지 손으로 짰고, 메서드 호출을 리시버 타입으로 해석하고(self.router = APIRouter() 같은 것), LSP 연동에 모노레포·서브모듈·중첩 클론 경계 처리까지 있습니다. 커밋 478개에 팀이 붙어서 만든 물건이라 여기를 따라가는 건 SCV 본업이 아닙니다.

게다가 설계 철학이 충돌합니다. SCV는 bash + 벤더링된 scv-core, 런타임에 아무것도 안 가져오고 .env도 안 읽는다는 게 명시된 원칙이죠. Graft는 npm 전역 설치 + 프로바이더 키가 필요합니다. 이걸 SCV 안에 흡수하면 그 원칙이 깨집니다.

대신 할 만한 것 두 가지

첫째, 어댑터 인터페이스. SCV가 "코드 컨텍스트 제공자" 계약 하나를 정의하고, graft가 PATH에 있으면 graft ask --json을 호출하고 없으면 기존 방식으로 폴백하는 구조. 구현은 얇은 셸 래퍼 하나면 되고, Graft가 망하거나 유료화돼도 SCV는 멀쩡합니다. /scv:promote가 계획 세울 때와 /scv:regression이 영향 범위 좁힐 때 두 군데만 꽂으면 됩니다. Graft의 blast --base origin/main --format json은 특히 리그레션 범위 산정에 거의 그대로 맞습니다.

둘째 — 이쪽이 더 중요한데 — Graft가 못 하는 걸 SCV가 만드는 것. Graft의 그래프는 코드에서만 나옵니다. 코드가 증명 못 하는 것, 즉 "왜 이렇게 됐는지"는 못 담습니다. 그런데 SCV는 scv/archive/에 계획·테스트·DECISIONS.md를 이미 쌓고 있습니다. 여기에 그래프를 얹는 건 아무도 못 하는 일입니다.

구체적으로: 아카이브된 plan마다 어떤 파일을 건드렸는지 기록해두면, 새 변경이 건드리는 파일에서 과거 어떤 계획이 이 코드를 만졌고 그때 어떤 결정을 내렸는지를 역으로 끌어올 수 있습니다. "6개월 전 아무도 기억 못 하는 테스트가 깨진 걸 잡는다"는 README 문구를, 테스트뿐 아니라 결정 맥락까지 확장하는 셈이죠. tree-sitter도 LLM 키도 필요 없고, 파일 경로 매칭과 git 이력만으로 됩니다.

정리하면 코드 그래프는 빌려 쓰고, 계획 그래프는 직접 만드는 쪽이 맞습니다. dryforge가 "프로젝트 하니스"로 노리는 게 정확히 후자인데, 걔는 문서를 새로 쓰는 방식이라 강제력이 없습니다. SCV는 이미 강제된 산출물이 쌓여 있으니 출발점이 더 좋습니다.


그저께
보낸 메시지: 코드그래프도 넣으면 안되나 의존성 설치가 너무 늘어나서

코드그래프도 넣으면 안되나 의존성 설치가 너무 늘어나서

그저께

Claude 응답: 의존성 걱정이 맞는 지점입니다.

의존성 걱정이 맞는 지점입니다. Graft를 의존하면 npm 전역 설치 + Node + 프로바이더 키가 붙는데, SCV는 bash와 git·jq 정도로 버티는 게 강점이니 그게 깨집니다. 그래서 "코드 그래프를 넣되 의존성은 0으로" 하는 방법을 먼저 보는 게 맞습니다.

의존성 비용 순으로 세 가지 선택지

방식	새 의존성	얻는 것
git 동시변경 그래프	없음	함께 바뀌는 파일 쌍
universal-ctags	바이너리 1개	심볼 위치 인덱스
tree-sitter	Node + 네이티브 모듈	호출 엣지, 타입 해석

세 번째는 포기하시는 게 맞습니다. Graft가 커밋 478개 들여 만든 부분이고, SCV의 벤더링 원칙과도 정면 충돌합니다.

주목할 건 첫 번째입니다. git log --numstat만 돌리면 "이 파일이 바뀔 때 같이 바뀐 파일"이 나옵니다. 파싱도, 언어 지원도, 키도 필요 없습니다. 언어 무관이라 23개 언어 목록 같은 게 아예 존재하지 않고요.

그리고 이건 Graft가 못 하는 그래프입니다. Graft의 엣지는 import와 호출, 즉 정적 구조뿐입니다. 정적으로 연결이 없는데 항상 같이 바뀌는 파일들 — 스키마와 마이그레이션, 프론트 타입과 백엔드 DTO, 설정과 그걸 읽는 코드 — 은 잡지 못합니다. 실무에서 빠뜨려서 사고 나는 건 오히려 이쪽이죠.

SCV에서 특히 잘 맞는 이유는 아카이브 때문입니다. git 동시변경만 쓰면 잡음이 많습니다(리네임, 대량 포맷팅, 릴리스 커밋). 그런데 SCV는 scv/archive/에 계획 단위로 어떤 파일을 건드렸는지가 이미 남습니다. 커밋이 아니라 계획을 단위로 삼으면 잡음이 확 줄고, 엣지마다 "왜 같이 바뀌었는지"가 plan 문서로 붙습니다. 가중치 있는 그래프에 근거 링크가 달린 셈이라, 그냥 코드 그래프보다 정보량이 많습니다.

구현은 생각보다 작습니다. 아카이브 순회하면서 파일 목록 뽑고, 쌍 카운트해서 JSON 하나로 떨구고, /scv:promote가 그걸 조회하는 정도. bash + jq로 끝납니다.

실용적인 선은 이렇습니다: 구조 그래프는 만들지 마세요. 에이전트가 이미 파일을 읽을 수 있고, Graft 없이도 import는 따라갑니다. 비싼 건 파싱이 아니라 재계산이 불가능한 이력입니다. 메모리에 남길 가치가 있는 건 그쪽이고, 그건 SCV만 가지고 있습니다.

Graft는 나중에 선택적 어댑터로 남겨두시면 됩니다. 있으면 쓰고 없으면 폴백 — 필수 의존성이 아니면 설치 부담은 사용자 선택이 되니까요.


그저께
보낸 메시지: 그럼 코드그래프가 필요하면 graft 설치해서 scv랑 통합되게 해야해??

그럼 코드그래프가 필요하면 graft 설치해서 scv랑 통합되게 해야해?? 겹치는게있다며

그저께

Claude 응답: 겹치는 건 컨텍스트 주입 경로지 코드 그래프 자체가 아닙니다.

겹치는 건 컨텍스트 주입 경로지 코드 그래프 자체가 아닙니다. 그 구분이 답을 정합니다.

겹치는 것과 안 겹치는 것

Graft가 SCV와 부딪히는 건 딱 세 군데입니다 — statusline, 매 턴 프롬프트 주입, 그리고 .claude/settings.json 훅 블록. 코드 그래프 조회(graft ask, graft blast, MCP 도구들)는 어디와도 안 부딪힙니다. 그런데 정작 코드 그래프가 필요해서 설치하는 거라면 원하는 건 후자죠.

그래서 답은 자동 주입을 끄고 조회만 쓰는 것입니다.


graft init --agents claude --no-hooks --no-statusline

이러면 MCP 서버와 스킬 파일만 남습니다. 매 턴 주입도, statusline 점유도, settings.json 훅도 없습니다. SCV의 훅 레이어는 그대로 유지되고, Claude가 필요할 때만 graft_find_code를 부릅니다. README 벤치마크에서 정답률이 가장 높게 나온 "pull" 방식이 이겁니다 — 98%로, 주입 방식보다 오히려 5포인트 높습니다.

통합이라고 할 것도 별로 없습니다. SCV 입장에서 해야 할 일은 /scv:promote와 /scv:regression 쪽에 "graft가 있으면 먼저 조회하라"는 한 줄 추가 정도입니다. 없으면 기존대로 동작하고요. SCV가 Graft를 의존하는 게 아니라 인지만 하는 관계입니다.

정리하면

코드 그래프가 필요하면 → Graft 설치, 단 --no-hooks --no-statusline
필요 없으면 → 설치 안 함, SCV 혼자 멀쩡히 동작
어느 쪽이든 SCV 코드에 tree-sitter는 안 들어감

앞서 말씀드린 계획 이력 그래프는 이것과 별개로 SCV 안에 만드시면 됩니다. 의존성 0이고, Graft가 있든 없든 값이 있고, 오히려 Graft가 못 채우는 칸을 채우니까요.

한 가지만 확인하세요. graft init이 ~/.codex/ 같은 저장소 밖에도 쓰는 경우가 있습니다. --no-global을 같이 주거나, 먼저 --dry-run으로 건드릴 파일 전부 보고 결정하시는 게 안전합니다.


그저께
Claude에게 직접 질문해 보세요
