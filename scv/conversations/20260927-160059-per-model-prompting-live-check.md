---
slug: per-model-prompting-live-check
started_at: 2026-09-27T16:00:59+09:00
status: active
promoted_to: null
---

## Turn 1 — 2026-09-27T16:00:59+09:00
protocol: 8ae70f64

**User**: (끝까지 진행 승인의 마지막 단계 — 설치본으로 실제 대화 실측)

**Claude Code**: 릴리스: 코어 v0.59.0 → v0.59.1(코덱스 사본의 help 규약 합계 상한 초과 패치), 클로드 v0.59.0 → v0.59.1(가이드 폴더 경로 수정), 코덱스 v0.59.0-codex.1. 이 기기 두 플러그인 설치 완료.
실측 1 (클로드 0.59.0, 헤드리스 "로그인 버그 고쳐줘"): help 가 --model claude-opus-5-5 를 받았지만 GUIDE: none. 원인 — 클로드 help 스킬은 플러그인 최상위 투영본 scripts/help.sh 를 부르는데 SCV_PROMPTING_GUIDES 를 벤더 코어 기준(../../../prompting)으로 적었다. 클로드 0.59.1 에서 prompting 으로 고치고 플러그인 최상위에서 해석을 잠그는 CI 검사 추가(옛 값에서 붉음 확인). 저널 답 머리줄 모델 표기(assistant · claude-opus-5-5)는 동작.
실측 2 (클로드 0.59.1): GUIDE: load opus-5-5 + GUIDE_FILE 두 개(opus-5-5.md · best-practices.md)가 나옴. 모델은 prompt-refine.md 를 읽고 요청을 다시 써 대화 기록에 **다시 쓴 요청** 단락을 남겼지만, GUIDE_FILE 원문은 열지 않았고 mark 도 하지 않았다(.help-guide 비어 있음). 답 화면에 다시 쓴 요청 인용이 없었다. 끝 조건은 저장소에서 채움("직접 실행해 확인") — 되묻기 없음.
결론: 가이드를 "알리는" 장치는 동작, 모델이 원문을 "읽게 하는" 장치는 약하다. 사용자 요구 "꼭 레퍼런스"를 만족하지 못함(확인).
코덱스 실측: codex exec 가 로그인 만료(refresh_token_reused)로 실행 못 함 — 사용자 재로그인 필요.
