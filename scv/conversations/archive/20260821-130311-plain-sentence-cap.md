---
slug: plain-sentence-cap
started_at: 2026-08-21T13:03:11+09:00
status: archived                # active | promoted | archived
promoted_to: scv/promote/20260821-wookiya1364-plain-sentence-cap/
archived_at: 2026-08-21T13:56:02+09:00
---

## Turn 1 — 2026-08-21T13:03:11+09:00

**User**: 혹시 지금은 2문장 정도로 제한되어있잖아. 이것도 .env에 환경변수값 추가해서 라인수를 조절할 수 있게 하고싶은데 가능해?

**Claude Code**: 가능하다. .env 에 숫자 하나를 넣으면 "먼저 몇 문장"의 상한이 그 값으로 바뀐다 — 없으면 지금처럼 2가 기본. 예: SCV_PLAIN_MAX_SENTENCES=4 → 매 턴 훅이 "먼저 1–4문장"이라고 알려주고, 명령 설명서의 규칙도 ".env 에 값이 있으면 그 수까지"로 읽는다. 규칙 문구 한 줄 추가(제목·기존 앵커 유지 → 보관한 테스트 계약과 충돌 없음), 훅이 값을 읽어 숫자 치환(없거나 이상한 값이면 2), .env.example.scv·SCV.md 한 줄씩, 테스트 몇 개. #103 은 그대로 머지하고 이 항목은 뒤따르는 작은 계획 하나로 같은 0.31.0 에 싣는 것을 추천. 질문: 단위를 문장 수(추천 — 줄 수는 화면 폭에 따라 달라져 지키기 어렵다)로 할지 줄 수로 할지.

## Turn 2 — 2026-08-21T13:03:11+09:00

**User**: 문장 수로 하자, 진행해

**Claude Code**: 문장 수로 확정. 스위치 이름 SCV_PLAIN_MAX_SENTENCES, 기본 2, 양의 정수만 유효(그 밖은 2). 이 대화를 입력으로 /scv:promote → 구현 → archive → PR 로 진행.
