---
slug: update-auto-refresh
started_at: 2026-09-01T13:15:08+09:00
status: archived
archived_at: 2026-09-01T14:37:58+09:00
promoted_to: scv/archive/20260901-wookiya1364-update-auto-refresh/
---

# 업데이트하면 문서도 알아서 새로고침 — /scv:sync 강요 없애기

## Turn 1 — 2026-09-01T13:15:08+09:00

**User**: 매번 플러그인 업데이트하는 것까지는 괜찮은데, 그 뒤에 /scv:sync 로 문서를 새로고침하는 과정이 불필요해 보인다. 그냥 플러그인을 업데이트하면 프로젝트의 SCV 문서가 강제로 새로고침되게 할 수는 없나? 왜 사용자에게 /scv:sync 를 하라고 강요해야 하나?

**Claude Code**: 강요할 필요가 없습니다 — 이미 자동입니다. 코드를 확인한 결과:

- 매 턴 도는 preflight 훅이 help.sh 를 부르고, help.sh 는 시작하자마자 `scv_autosync` 를 호출한다 (core/scripts/help.sh:34).
- `scv_autosync` (core/scripts/lib/scvroot.sh:136~) 는 배포본의 TEMPLATE_VERSION/TEMPLATE_DIGEST 와 프로젝트 SCV.md 의 도장을 비교해, 다르면 **직접 sync.sh 를 실행**한다. 번호가 같아도 지문이 다르면 갱신한다.
- 0.41.0 은 실제로 번호가 아니라 지문만 바뀐 릴리스다 (TEMPLATE_DIGEST 만 변경) — 즉 지문 경로로 자동 갱신이 걸린다.
- 코어 규약(core/protocols/update.md:5-19)도 명시적으로 같은 말을 한다: "update 액션 안에서 sync 를 돌리지 마라. 재시작 후 첫 Core 액션이 알아서 닫는다."

그런데 래퍼의 update 커맨드 문서(commands/update.md:77)에는 이런 낡은 문장이 남아 있다:
"For the project-level template re-sync ... run `/scv:sync` separately."

이 한 줄이 코어 규약과 정면으로 어긋나고, 사용자에게 불필요한 절차를 시키고 있다.

부차 문제 하나 더: 자동 갱신이 성공하면 `scv: workflow docs refreshed ...` 를 stderr 로 알리는데, preflight 훅이 help.sh 를 `2>/dev/null` 로 부른다 (template/hooks/on-user-prompt.sh:103). 그래서 **갱신됐다는 사실이 사용자 눈에 안 보인다.** 조용히 되니까 "정말 됐나?" 싶어 손으로 sync 를 한 번 더 치게 되는 구조다.

**질문**: 문구만 고칠까, 아니면 "다음 메시지에서 자동 갱신됩니다 / 갱신됐습니다"를 눈에 보이게 알리는 것까지 할까?

## Turn 2 — 2026-09-01T13:51:42+09:00

**User**: 모두.

**Claude Code**: 둘 다 한다. 범위를 확정했다 — 낡은 문구 3곳(래퍼 2개 저장소) + 보이게 하기 1곳(코어).

낡은 문구, 실제 위치 3곳:
- scv-claude-code/commands/update.md:77 — "For the project-level template re-sync ... run `/scv:sync` separately."
- scv-codex/plugins/scv/README.md:49 — "Run `$scv:sync` separately to ..."
- scv-codex/plugins/scv/adapter/protocols/update.md:53 — "Recommend `$scv:sync` separately when ..."

보이게 하기, 1곳:
- core/template/hooks/on-user-prompt.sh:103 — `bash "$_scv_probe" 2>/dev/null` 이 자동 갱신 보고를 통째로 버린다. 템플릿 갱신 줄만 골라 preflight 블록에 실어야 한다. stderr 전체를 쏟으면 안 된다 — 훅의 NON-BLOCKING 보장과 출력 위생이 상한이다.

받아들임 기준 초안:
1. 자동 갱신이 실제로 일어난 턴에는 preflight 에 결과 한 줄이 보인다 (갱신됨 / 부분 / 실패).
2. 갱신할 것이 없으면 아무 줄도 나오지 않는다 — 조용함이 기본값이다.
3. 훅은 여전히 실패해도 exit 0 이고, help.sh 의 다른 stderr 는 새지 않는다.
4. 자동 갱신이 꺼졌거나 스스로 못 닫는 상태면 기존 안내 문구가 그대로 나온다.
5. 세 래퍼 문서 어디에도 "sync 를 따로 실행하라"가 남지 않고, "다시 불러온 뒤 첫 액션이 자동으로 닫는다"로 바뀐다.

**질문**: 이 범위로 PLAN.md + TESTS.md 를 뽑을까?
