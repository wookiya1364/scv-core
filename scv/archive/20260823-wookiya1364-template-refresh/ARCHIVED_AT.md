---
archived_at: 2026-08-23
archived_by: wookiya1364
reason: "1·3단계 완료, 2단계는 호스트 구조상 불가로 취소. TESTS T1 18/18, T2, T3, T4, T5, T6, T7, T9(T5s 4건), T11 통과 — run-dry 972 PASS/0 FAIL(기준선 동일), test-autosync 25/25, test-template-digest 17건. T10 은 수동 확인만(자동 회귀 없음). T12(래퍼 두 곳)는 core 벤더링이 필요해 이 저장소 범위 밖으로 남긴다."
---

# Archive record

This plan was archived on 2026-08-23.

## Reason

- 1단계(지문 산출·판단)와 3단계(조용한 실패 제거) 완료.
- 2단계(업데이트 직후 갱신)는 **취소**. 플러그인 payload 가 버전별로 캐시되어
  업데이트 시점의 세션이 아직 옛 payload 를 들고 있다 — 거기서 갱신을 부르면 옛
  템플릿을 깔고 성공을 보고한다. `core/protocols/update.md` 5항이 이미 금지하고
  있으며 이유가 맞다.

## 남은 일

- **T12 — 래퍼 두 곳(scv-claude-code, scv-codex) 반영.** core 를 벤더링해야
  실제 사용자에게 도달한다. 각 래퍼 저장소의 작업이다.
- **CHANGELOG.** 이 저장소는 릴리스 커밋에서 쓰는 방식이라 미뤘다.
- **T10 자동 회귀.** status 의 어긋남 절은 수동으로만 확인했다.
- **번호 통일.** 템플릿 번호를 SCV 번호로 맞추는 일은 별건이다. 지문이 자리잡아
  이제 안전하게 할 수 있다.
