---
slug: per-model-prompting-live-check
started_at: 2026-09-27T16:00:59+09:00
status: promoted
promoted_to: scv/archive/20260927-wookiya1364-prompting-read-verdict
---

## Turn 1 — 2026-09-27T16:00:59+09:00
protocol: 8ae70f64

**User**: (끝까지 진행 승인의 마지막 단계 — 설치본으로 실제 대화 실측)

**Claude Code**: 릴리스: 코어 v0.59.0 → v0.59.1(코덱스 사본의 help 규약 합계 상한 초과 패치), 클로드 v0.59.0 → v0.59.1(가이드 폴더 경로 수정), 코덱스 v0.59.0-codex.1. 이 기기 두 플러그인 설치 완료.
실측 1 (클로드 0.59.0, 헤드리스 "로그인 버그 고쳐줘"): help 가 --model claude-opus-5-5 를 받았지만 GUIDE: none. 원인 — 클로드 help 스킬은 플러그인 최상위 투영본 scripts/help.sh 를 부르는데 SCV_PROMPTING_GUIDES 를 벤더 코어 기준(../../../prompting)으로 적었다. 클로드 0.59.1 에서 prompting 으로 고치고 플러그인 최상위에서 해석을 잠그는 CI 검사 추가(옛 값에서 붉음 확인). 저널 답 머리줄 모델 표기(assistant · claude-opus-5-5)는 동작.
실측 2 (클로드 0.59.1): GUIDE: load opus-5-5 + GUIDE_FILE 두 개(opus-5-5.md · best-practices.md)가 나옴. 모델은 prompt-refine.md 를 읽고 요청을 다시 써 대화 기록에 **다시 쓴 요청** 단락을 남겼지만, GUIDE_FILE 원문은 열지 않았고 mark 도 하지 않았다(.help-guide 비어 있음). 답 화면에 다시 쓴 요청 인용이 없었다. 끝 조건은 저장소에서 채움("직접 실행해 확인") — 되묻기 없음.
결론: 가이드를 "알리는" 장치는 동작, 모델이 원문을 "읽게 하는" 장치는 약하다. 사용자 요구 "꼭 레퍼런스"를 만족하지 못함(확인).
코덱스 실측: codex exec 가 로그인 만료(refresh_token_reused)로 실행 못 함 — 사용자 재로그인 필요.

## Turn 2 — 2026-09-27T16:27:31+09:00
protocol: 861206b5

**User**: 추천대로 결과로 판정하자.

**Claude Code**: 결정 — 결과로 판정. 설계 초안: help 가 GUIDE: load 를 낸 턴을 기록(.help-guide-turn: 지문·모델·결정)하고, 종료 훅이 그 턴에 읽음 표시(model-prompting.sh mark)가 없으면 다음 턴 경고 한 줄을 예약한다(기존 .help-warn 통로 — 매 턴 훅이 지시 바로 뒤에 싣고 지움). 기록이 없으니 다음 help 는 다시 load. help 출력에 정확한 읽음 표시 명령 한 줄(GUIDE_MARK_CMD)을 더해 모델이 경로를 짓지 않게 한다. 규약 재표시(help-state mark)는 턴 기록의 지문도 옮긴다. 두 번째 실측에서 드러난 "다시 쓴 요청이 답 화면에 없음" 도 같은 방식으로 볼지 묻는다(대화 기록에 다시 쓴 요청이 있는데 답에 인용이 없으면 경고). 계획 초안으로 promote.

## Turn 3 — 2026-09-27T18:18:53+09:00
protocol: 08ea85be

**User**: (질문 답) 같이 잡기 (추천) — 다시 쓴 요청이 답 화면에 안 보인 것도 함께 판정.

**Claude Code**: 계획 20260927-wookiya1364-prompting-read-verdict 구현(코어 0.60.0, 커밋 전).
- help 가 GUIDE: load 인 턴에 읽음 표시 명령을 절대 경로로 준다(GUIDE_MARK_CMD). 이번 턴 기록(.help-guide-turn)을 남긴다.
- 멈춤 훅이 model-prompting.sh stop 으로 판정: 안 읽음(load 인데 읽음 표시 없음) · 안 보임(대화 블록에 다시 쓴 요청이 있는데 답에 > 인용 없음) → 다음 턴 경고를 .help-warn 에 덧붙임, .help-drift 에 한 줄. 같은 턴 규약 재표시 때 턴 기록 지문도 옮김.
- 계획에서 달라진 길: (1) 턴 기록 재도장은 새 순수 함수(4필드) (2) 인용은 호스트가 준 마지막 메시지 + 이번 턴 답 텍스트 전부에서 찾음 — 도구 호출 전 첫 메시지 인용도 인정(거짓 경고 방지) (3) 비용 여유 확보로 full.md 모델별 절 문구도 줄임.
- 검사: test-model-prompting T10~T14 초록, 변이 시험 2건(턴 기록 옮기기 끔 · 앞 메시지 합치기 끔)에서 붉음 확인. 코어 테스트 55개 중 help-shape 1건만 붉음 — 커밋 전 "종료 훅이 바뀌었다" 현상, 임시 커밋 사본에서 초록(확인).
- 코덱스 벤더 사본: help 규약 합계 31,891B(여유 109B), 코어 테스트 전부 — guidance 1건 붉음은 현재 배포된 0.59.1 사본에도 있는 기존 현상(확인).
- 회귀: 50개 중 44 통과, 6 실패 — 모두 help-shape 의 커밋 전 현상으로 수렴(3개 직접, 3개 코어 전체 게이트). 임시 커밋 사본에서 6개 재실행 중.
- 설치본 0.59.1 로 이번 턴 help: GUIDE: load opus-5-5 → 원문 두 개(opus-5-5.md · best-practices.md)를 끝까지 읽고 mark 실행(GUIDE_MARK: opus-5-5).
