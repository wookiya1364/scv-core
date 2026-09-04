---
slug: command-model-override
started_at: 2026-09-03T15:02:16+09:00
status: archived
archived_at: 2026-09-03T15:48:36+09:00
promoted_to: scv/archive/20260903-wookiya1364-session-model-default/
---

# SCV 명령이 세션 모델을 덮어쓴다 — "claude-opus-5" 표시의 정체

## Turn 1 — 2026-09-03T15:02:16+09:00

**User**: scv:help 를 부르면 "Successfully loaded skill · 12 tools allowed · claude-opus-5" 라고 나온다. 나는 Fable 5.1 xhigh 를 쓰는데, SCV 가 모델을 opus-5 로 강제 변환한 것인가?

**Claude Code**: 맞다 — 강제 변환이다 (확인됨). SCV 명령 파일마다 머리말에 어떤 모델로 돌릴지가 적혀 있다. help·promote·work 등 9개는 "opus", status·update 등 6개는 "haiku". Claude Code 는 그 줄을 보고 그 명령이 도는 동안 세션 모델을 바꾼다. "opus" 는 지금 Opus 5 로 풀리니 표시가 "claude-opus-5" 다. 이 머리말은 v0.11.5 부터 있었다.

문제가 커진 이유: 0.43.0 부터 help 가 매 턴 불린다. 즉 Fable 5.1 xhigh 로 세션을 열어도 **거의 매 턴 Opus 5 가 답한다.** 그리고 status 같은 명령은 Haiku 로 내려간다.

빠져나가는 길은 이미 있다: `/scv:set-models session-default` — 머리말의 모델 줄을 전부 지워서 세션 모델을 그대로 쓰게 한다. 프로젝트 `.env` 에 `SCV_MODEL_POLICY=session-default` 로 남겨 플러그인 갱신 뒤 sync 가 다시 적용한다. 지금 두 프로젝트(scv-core, DMN) 모두 정책 미설정 = 기본값(opus/haiku 매핑).

판단: 기본값이 틀렸다. 플러그인이 사용자의 세션 모델을 조용히 바꾸는 것은, 사용자가 더 좋은 모델을 고른 경우 다운그레이드다. 무조건 호출과 결합되면 세션 모델 선택이 사실상 무의미해진다. 기본을 session-default 로 바꾸고, opus/haiku 매핑은 원하는 사람이 켜는 것으로 뒤집어야 한다.

부수 발견: 정책이 `.env` 에 저장된다 — 설정은 0.23.0 부터 scv_settings.json 으로 옮겼는데 이 명령만 옛 자리를 본다. 같이 손볼 후보.

## Turn 2 — 2026-09-03T15:04:49+09:00

**User**: 지금 적용 + 기본값도 바꾼다.

**Claude Code**: 두 갈래로 간다. (1) 지금: 설치된 플러그인의 명령 파일에서 모델 지정 줄을 전부 지운다(세션 모델 그대로). 플러그인 캐시는 프로젝트 공용이라 한 번이면 모든 프로젝트에 적용된다. 정책은 프로젝트에 남겨 갱신 뒤에도 다시 적용되게 한다. (2) 계획: 래퍼의 기본값을 "세션 모델 그대로" 로 뒤집고 Opus/Haiku 매핑은 선택지로 남긴다. 확인할 것 — 재생성 파이프라인에서 모델 줄이 어디서 생기는지, Codex 래퍼도 같은지, 정책 저장 위치(.env 대 설정 파일).

## Turn 3 — 2026-09-03T15:06:26+09:00

**Claude Code** (조사 결과):
- **지금 적용 완료**: 설치된 플러그인(0.44.0)의 명령 15개에서 모델 지정 줄을 전부 지웠다. 다음 SCV 명령부터 세션 모델(Fable 5.1)이 그대로 유지된다. 플러그인 캐시는 프로젝트 공용이라 모든 프로젝트에 즉시 적용.
- **지속이 고장나 있다 (확인됨)**: set-models 명령의 3단계가 코어의 `env-set.sh` 로 `.env` 에 정책을 쓰라고 하는데, 그 스크립트는 없다 — 0.23.0 에서 설정을 scv_settings.json 으로 옮기며 사라졌다. 코어 설정 등록부에 `SCV_MODEL_POLICY` 키도 없다. 즉 지금 `/scv:set-models` 는 적용은 되지만 저장은 실패한다. 래퍼 sync 는 `.env` 의 그 키를 읽어 재적용하지만, 그 키를 쓸 길이 없었다.
- **Codex 래퍼는 해당 없음**: skills 방식이라 모델 지정 줄이 없다.
- **모델 줄의 출처**: 래퍼 저장소의 commands/*.md 에 커밋돼 있고, `apply-model-policy.sh` 의 `recommended` 매핑(v0.11.5)이 단일 진실. 래퍼 검사 `test-core-contract.sh` 가 "모든 명령에 model 줄이 있어야 한다" 고 단언한다 — 기본값을 뒤집으면 이 검사도 뒤집어야 한다.

계획 범위(코어 + 래퍼, 0.42.0 과 같은 방식):
1. 래퍼 commands/*.md — 모델 지정 줄 전부 제거 (기본 = 세션 모델).
2. 래퍼 apply-model-policy.sh — 기본 정책을 session-default 로. recommended(opus/haiku 매핑)는 선택지로 유지. 정책을 scv_settings.json 에서 읽고(.env 는 옛 프로젝트 호환으로 뒤에).
3. 래퍼 commands/set-models.md — 첫 선택지를 session-default 로, 저장은 코어 `settings-set.sh` 로.
4. 코어 설정 등록부에 `SCV_MODEL_POLICY` 키 등록(기본 session-default, _doc).
5. 래퍼 검사 — "model 줄 있어야" → "기본은 없어야, 정책을 켜면 생겨야".

받아들임 기준: (1) 새로 설치한 플러그인의 어떤 명령에도 모델 지정 줄이 없다. (2) set-models 로 opus 매핑을 켜면 줄이 생기고, session-default 로 돌리면 사라진다. (3) 정책이 scv_settings.json 에 저장되고 sync 가 그것을 읽어 재적용한다. (4) 코어 설정 등록부에 키가 있고 검사가 통과한다. (5) Codex 래퍼는 무변경.

## Turn 4 — 2026-09-03T15:11:13+09:00

**User**: 그럼 DMN 에서 매핑 꺼줘. sync 안 돌리고 플러그인 업데이트만 해서 해결할래.

**Claude Code**: 알겠다. DMN 의 옛 방식 파일에 적어 둔 정책 줄을 지웠다 — 그 줄은 sync 를 돌릴 때만 뜻이 있었다. 설치된 플러그인의 명령 파일에는 이미 모델 줄이 없으므로 지금 상태는 "세션 모델 그대로" 다. 앞으로는 플러그인 갱신 하나로 끝나도록 기본값을 뒤집는 계획을 바로 구현한다. 즉 계획 승인으로 읽는다.

## Turn 5 — 2026-09-03T15:14:56+09:00

**Claude Code** (구현 결과): 코어 3곳 + 검사 1개, 래퍼 5곳.
- 코어: 설정 등록부에 `SCV_MODEL_POLICY`(기본 session-default, 설명) 등록. set-models 규약에 "런타임 기본은 세션 모델, 매핑은 선택, 저장은 설정 파일" 문장. 검사 파일 신설(16건 — 래퍼 체크아웃이 옆에 있으면 래퍼 파일까지 대조).
- 래퍼: 명령 파일 15개에서 모델 줄 제거(커밋). 정책 스크립트는 기본을 session-default 로 문서화하고 재적용 모드가 설정 파일을 먼저 읽고 `.env` 는 호환. set-models 문서는 첫 선택지 session-default, 저장은 `settings-set.sh`. 계약 검사의 "model 줄 있어야" 를 "없어야" 로 뒤집음. sync 안내 문구 갱신. 정책 검사 6·7·8 추가(15건 통과).
- 계획과 다르게 간 곳: 없음. 설정 읽기는 코어 라이브러리 대신 python3 로 JSON 을 직접 읽었다 — 래퍼가 프로젝트 경로를 인자로 받는 자리라 라이브러리의 cwd 기반 해석보다 단순하고, python3 는 이미 선언된 의존성이다.

## Turn 6 — 2026-09-03T15:26:05+09:00

**Claude Code** (회귀에서 잡힌 것): 첫 누적 회귀에서 15건이 떨어졌다. 원인은 나 — 코어 페이로드는 호스트 중립이라 `tests/test-host-neutral.sh` 가 "Claude", "Codex", "/scv:" 뿐 아니라 **공급자 모델 이름(opus·sonnet·haiku)** 까지 core/ 전체(설정 예시의 설명문, 검사 파일 포함)에서 금지한다. 내가 설정 설명에 "Claude Code 래퍼만 해당 · all-opus | all-sonnet | all-haiku" 를, 검사 파일에 `model: opus` 같은 단언을 넣었다. 둘 다 걷어냈다 — 설명은 "상위 모델 / 경량 모델" 로, 검사는 "model 줄의 유무와 서로 다름" 만 보게. 그 뒤 최상위 러너·계획 검사 16건·설정 검사 모두 녹색.

## Turn 7 — 2026-09-03T15:39:07+09:00

**Claude Code**: 둘째 회귀에서 4건이 남았다. 원인: 설정 예시 파일은 템플릿 트리 안이라 바꾸면 템플릿 지문을 다시 계산해야 하는데 빠뜨렸다 — 0.42.0 때와 같은 함정. 지문을 다시 만들고 코어 검사 파일 전부를 개별 실행해 이상 없음을 확인한 뒤 확정 회귀를 다시 걸었다.

## Turn 8 — 2026-09-03T16:18:05+09:00

**User**: 다 돌았어?

**Claude Code**: (배경 승격 사슬 상태를 확인해 답함 — 아래 본문 참조.)

## Turn 9 — 2026-09-04T09:15:24+09:00

**User**: (플러그인 갱신 뒤) scv:help 를 부르면 "Successfully loaded skill · 12 tools allowed" 만 나온다. 세션 모델이 따로 표기되지는 않는다.

**Claude Code**: 그것이 고쳐졌다는 표시다. Claude Code 는 명령이 세션 모델을 **덮어쓸 때만** 그 줄에 모델 이름을 붙인다. 덮어쓰는 것이 없으면 세션 모델이 그대로 쓰이고 표기도 없다. 즉 "claude-opus-5" 가 사라진 것 = 0.45.0 이 적용됐고 Fable 세션이 유지된다는 뜻. 실기기 확인 완료 — 이 대화의 목표가 닫혔다.
