flow: ci-run | ci-gate
in: none
out: verdict — RELEASE_OK 한 줄, 실패가 있으면 종료 코드 1
does: 릴리스 전에 한 저장소의 CI 명령을 맥이나 리눅스에서 다 돌리고, 실패가 없을 때만 RELEASE_OK 를 낸다 — os=mac 과 os=linux 로 두 번 돌린다
words: 릴리스 래퍼 릴리스 CI 시험 맥 리눅스 로컬 검사

# release-ci

릴리스(core · 래퍼)를 시작하기 전에 저장소마다 두 번 돌린다: `repo=<core|claude|codex> os=mac`, `repo=<…> os=linux`.
둘 다 `RELEASE_OK` 를 낸 뒤에만 PR 을 올리고 릴리스한다. 명령 목록은 이 폴더의 `<repo>.cmds` 이고, 각 저장소의 CI 작업이 돌리는 명령을 옮긴 것이다.
저장소의 CI 가 운영체제마다 다른 명령을 돌리면 `<repo>.<os>.cmds` 를 따로 둔다 — 있으면 그 목록을 쓴다(예: `codex.mac.cmds` 는
codex CI 의 맥 작업이 돌리는 것만 담는다. 나머지는 우분투 전용이고, 그중 하나는 맥의 기본 도구로 돌 수 없다).
