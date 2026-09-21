# 코어가 main 까지 승격되면 래퍼 둘도 릴리스해 버전을 올린다

사용자 요구 (2026-09-20, rule-constitution PR 올리는 중). 원문:

> pr까지 다 올리고 develop -> stage -> main 까지 승격되면 https://github.com/wookiya1364/scv-claude-code ,
> https://github.com/wookiya1364/scv-codex는 래퍼프로젝트거든. 여기도 릴리스해서 버전 올려야해.

## 순서

1. scv-core: PR(feat/rule-constitution-0.54.0 → develop) 병합 → `gh workflow run promote.yml` 로 develop → stage → main,
   태그 0.54.0, 릴리스 산출물(tarball + SHA-256).
2. scv-claude-code: 벤더링된 코어를 0.54.0 으로 올리고(어댑터의 sync-core 스크립트), 플러그인 버전 상승, 릴리스.
3. scv-codex: 같은 순서.
4. 래퍼 쪽 후속 확인: 이번 코어 변경이 래퍼 문서에 요구하는 것 — regression 삭감 표 형식(래퍼 스킬 문구가 옛 "슬러그마다
   질문" 을 복제하고 있으면 참조로), Top-level rules 참조. 코어의 rule-constitution 검사 (b) 는 코어만 보므로 래퍼
   문서의 복제는 사람이 봐야 한다.

## 이 저장소에서 할 수 있는 것 / 없는 것

- 할 수 있는 것: 코어 PR 과 승격 워크플로 실행(사용자 승인 후).
- 없는 것: 래퍼 저장소의 커밋·릴리스는 그 저장소에서 해야 한다 — 옆 체크아웃(../scv-claude-code, ../scv-codex)에서
  각자의 릴리스 절차(docs/release.md 상당)를 따른다. 두 체크아웃은 오늘 origin 최신으로 옮겨 두었다.
