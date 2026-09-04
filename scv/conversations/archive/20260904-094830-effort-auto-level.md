---
slug: effort-auto-level
started_at: 2026-09-04T09:48:30+09:00
status: archived
archived_at: 2026-09-04T11:24:39+09:00
promoted_to: scv/promote/20260904-wookiya1364-effort-auto-level/
---

## Turn 1 — 2026-09-04T09:48:30+09:00

**User**: 나 궁금한거 있어. 모델은 사용자 따라가게 해놨잖아. 그런데, effort는 사용자마다 전부 다른데, ultracode로 갈수록 너무 생각하는 시간이 길어져서 응답이 오기까지 너무많은 시간을 사용해. 그래서 내 생각에는 사용자가 effort레벨을 어떻게 설정하든 low or medium으로 설정을 해놓는거야. 그 다음에 사용자의 질문 수준에 따라 effort레벨을 low ~ ultracode까지 LLM이 자유롭게 적용시켜서 백그라운드로 찾아보게 하는건 어때?

**Claude Code** (2026-09-04T09:59:21+09:00): 반은 되고, 반은 어제 0.45.0 결정과 정면충돌한다.

- 확인된 사실
  - 명령(스킬) 파일에는 model 줄처럼 `effort` 줄을 둘 수 있다(문서 확인, 실기기 미검증). 그 명령이 도는 동안 세션 effort 를 덮어쓴다. help 가 매 턴 불리므로 help 에 `effort: low` 를 두면 사실상 매 턴 low — 어제 뺀 model 줄과 같은 지렛대.
  - ultracode 는 effort 등급이 아니다. 문서: "Ultracode is not a distinct level and reports as xhigh". 등급은 low/medium/high/xhigh/max. 서브에이전트가 요청 가능한 최고는 max.
  - 스킬 본문은 ${CLAUDE_EFFORT} 로 현재 세션 effort 를 읽을 수 있다.
  - 플러그인 서브에이전트 정의는 effort·background 프론트매터를 지원한다. SCV 는 지금 서브에이전트를 하나도 안 띄운다(코어·래퍼 모두 agents/ 없음).
  - 코어는 0.29.0 에서 "세션 effort 는 사용자 것, SCV 는 실행 모양만" 이라고 결정해 두었다(work.md Step 5e, DECISIONS.md:398).
  - 배경 작업이 끝나면 사용자 입력 없이 모델이 다시 깨어난다 — 이 세션에서 실제로 관찰.
  - 워크플로 에이전트 하나가 "플러그인은 세션 effort 를 못 낮춘다" 는 문구를 문서 인용으로 보고했으나, 원문(plugins-reference)에 그 문장은 없다. 반박 검토의 '불가' 판정은 이 오류에 기댄 것이라 폐기.
- 판단
  - (a) 사용자 effort 를 low/medium 으로 고정: 기술적으로는 effort 줄 한 개로 됨. 그러나 xhigh 를 일부러 고른 사용자에겐 매 턴 다운그레이드 — 어제 model 에서 "기본값이 틀렸다" 고 한 것과 같은 그림. 기본으로는 반대. 모델 정책처럼 켜는 사람만 쓰는 선택지로는 가능.
  - (b) LLM 이 난이도를 보고 배경 조사 effort 를 고름: 가능. 다만 effort 는 서브에이전트 정의별로 고정되므로 "low~max 자유 선택" 은 정의를 여러 개 두고 고르는 모양이 된다. 새로 만드는 일(래퍼 소유, 코어는 등급 이름을 못 씀).
  - 위험: 빠른 답의 권고를 먼저 실행한 뒤 깊은 답이 뒤집는 경우, 매 턴 에이전트 하나가 통째로 도는 비용(0.29.0 측정: fan-out 한 번에 40만~130만 토큰).
- 결정 요청
  1. 세션 effort 를 SCV 가 기본으로 낮출까 → 추천: 아니오. 기본은 세션 그대로, 낮추기는 선택지.
  2. 배경 조사 서브에이전트 → 추천: 래퍼에 파일 하나짜리 실험(effort high, background) 을 명령에 안 붙인 채 손으로 한 번 돌려 알림 시점·토큰을 잰 뒤 결정.

## Turn 2 — 2026-09-04T10:13:37+09:00

**User**: 1. 사용자가 최초에 정한 effort에서 질문을 받는다. 이후, scv:help에서 질문의 난이도(노력)에 따라 effort를 내부에서 자유롭게 결정해서 low ~ max까지 변경하여 호출한다. 이게 가능할까?? 이렇게하면 사용자는 최초에 정한 effort를 낮출수도, 높일수도 있잖아. 이거를 json에서 ON/OFF 하게 할 수도 있고 말야
2. 배경조사 서브에이전트 실험 해주라.

**Claude Code** (2026-09-04T10:23:33+09:00):

1번 — 가능하다. 다만 "effort 를 SCV 가 고른다" 를 실제로 먹게 하는 길은 지금 하나뿐이다.
- 구조: 사용자 답은 세션 effort 그대로(어제 원칙과 일치). help 가 깊다고 판단하면 배경 에이전트에 위임. ON/OFF 는 설정 파일 키 하나 + 매 턴 훅 블록 하나 — 기존 스위치 3개(SCV_PLAIN_LANGUAGE / SCV_ALWAYS_ON / SCV_FORCE_HELP)와 같은 패턴.
- effort 선택 실험 결과 (Claude Code 2.1.260, 확인됨):
  - 서브에이전트 정의 파일의 `effort:` 줄 — low / high / max 셋 다 요청 기록이 세션값 xhigh 로 남음. 같은 계산 문제 사고 토큰 low 2,610 vs max 3,006. 문서는 "덮어쓴다" 고 하지만 지금은 안 먹는다.
  - Workflow 도구의 호출별 effort — 반박 검토 에이전트를 high 로 지정했더니 기록에 high (세션은 xhigh). 먹는다. 단 Workflow 는 사용자가 켜는 도구이고, 스킬 지시문이 부르는 것은 허용됨. 호스트마다 있는지 미확인.
- 놀란 점: 대표님 설정 파일에 effortLevel=xhigh 가 저장돼 있다. 느린 응답의 직접 원인. SCV 가 아니라 /effort 로 내리는 것이 맞다.
- 조사 에이전트가 뽑은 구현 지도(요약): 코어 7파일(force-help.sh 순수함수 2개, on-user-prompt.sh 게이트, 설정 예시 _doc+기본 off, settings.sh 등록, TEMPLATE_DIGEST 재계산, test-force-help.sh 새 케이스, CHANGELOG/VERSION) + 래퍼 3곳(sync-core, agents/<investigator>.md 새 디렉터리, 버전). 크기 작음. 함정: 기본이 off 라 기존 정규화 함수(빈값→on) 재사용 불가, 훅 출력 80줄 상한(지금 57), 지문 재계산.

2번 — 실험 완료.
- 만든 것: ~/.claude/agents/scv-investigator.md (effort high, background true, 읽기 전용 도구). 프로젝트 범위 agents/ 는 새 디렉터리면 재시작 전 미인식(문서) → 사용자 범위에 둠. 파일 쓰고 수 초 뒤 바로 호출됨.
- 시간: 띄운 뒤 3분 28초에 보고 완료, 내게 알림은 약 1분 20초 뒤(총 약 4분 50초). 사용자 입력 없이 알림이 와서 내가 깨어남.
- 비용: 도구 호출 36회, 출력 토큰 약 139k(사고 포함), 캐시 읽기 254만, 캐시 쓰기 88만. high 지정이 안 먹어 사실상 xhigh 비용.
- 품질: 6개 질문 전부 file:line 근거, 기존 테스트 4종 baseline 도 돌림. 결과 전달이 약 4.5k 자에서 잘려 두 번 더 받아야 했음 → 배경 결과는 파일로 쓰고 요약만 돌려주는 규칙 필요.

결정 요청: (1) 이 설계로 계획을 잡되 1차는 "배경 조사 on/off + 결과 파일" 까지, effort 단계 선택은 정의 파일 effort 가 먹기 시작하면 붙이기 — 추천 예. (2) 계획서 초안(PLAN+TESTS)으로 넘길지 — 추천: 대표님 세션 effort 를 먼저 내려 체감을 본 뒤.

## Turn 3 — 2026-09-04T10:28:40+09:00

**User**: 1. 응 그대로 하자. effort 선택은 워크플로있는 호스트로 한정할게. 2. 미디엄으로 내려봤어. 그래도 필요해

**Claude Code**: 결정 확정. (1) 설계 그대로 — 세션 effort 는 손대지 않고, 설정 스위치(기본 off)로 켜면 help 가 깊은 질문을 배경 조사 에이전트에 위임하고 결과는 파일로 남긴다. 위임 effort 선택은 워크플로 도구가 있는 호스트에서만. (2) 세션 effort 를 medium 으로 내린 뒤에도 필요하다고 확인 → 계획서(PLAN + TESTS) 초안으로 넘긴다.

## Turn 4 — 2026-09-04T10:43:39+09:00

**User**: 진행해

**Claude Code**: 계획 승인으로 받고 /scv:work 20260904-wookiya1364-effort-auto-level 로 구현을 시작한다.
