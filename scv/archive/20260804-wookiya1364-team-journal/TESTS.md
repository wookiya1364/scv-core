# TESTS — 전면 기록화 (journal + DECISIONS + TODO + 훅)

## Test scenarios

각 시나리오는 최소 요구이며 PR 이 배송하는 것과 같다. 축소·병합 금지, 추가는 허용.

1. **hydrate 산출** — 새 hydrate 프로젝트에 `scv/journal/README.md`,
   `scv/DECISIONS.md`, `scv/TODO.md` 가 생성되고 셋 다
   `merge_policy: preserve` frontmatter 를 가진다.
2. **sync 전파** — 구버전으로 hydrate 된 프로젝트에서 sync 실행 →
   위 3종이 `NEW` 로 전파되고, 이미 내용을 적은 프로젝트에서는
   `SKIP (preserve)` 로 사용자 내용이 보존된다.
3. **author 해석** — `git config user.name` 설정 시 그 값, 미설정 시
   `$GIT_AUTHOR_NAME` → `$USER` 순 폴백. 공백·한글 이름이 파일명 슬러그로
   안전 변환된다.
4. **journal append + 귀속** — `journal-append.sh` 호출 →
   `scv/journal/<YYYYMMDD>-<author>.md` 에 `### [HH:MM:SS] <speaker>` 블록
   append. 서로 다른 author 두 명이 같은 날 기록하면 **파일이 분리**된다.
5. **redaction** — `password=hunter2`, `Bearer eyJ...`, `api_key: sk-...`,
   `AKIA...` 를 포함한 입력이 journal 에 `[REDACTED]` 로 마스킹되어 저장되고
   원문은 어디에도 남지 않는다.
6. **UserPromptSubmit 훅 계약** — Claude Code 훅 stdin JSON 샘플
   (`{"prompt": "..."}` 형태)을 `on-user-prompt.sh` 에 주입 → journal 에
   해당 턴이 기록된다. 잘못된 JSON 이면 exit 0 (non-blocking) + 기록 없음.
7. **결정 기록 지점** — promote 승인/work archive/regression obsolete 각
   프로토콜 텍스트에 DECISIONS.md append 지시가 존재하고(run-dry assert),
   지시된 엔트리 형식에 author 필드가 필수로 포함된다.
8. **대화 영속화 전환** — 신규 hydrate 의 `.gitignore` 에
   `/scv/.conversations/` 가 없고, help 프로토콜의 대화 저장 경로가
   `scv/conversations/` 이다. 구 `.conversations/` 가 존재하는 프로젝트에서
   help 가 마이그레이션을 제안한다(프로토콜 assert).
9. **status 노출** — DECISIONS 에 엔트리 2건, TODO 에 미완료 1건이 있는
   프로젝트에서 `status.sh` 출력에 최근 결정과 미완료 TODO(작성자 표시)가
   나타난다.
10. **훅 등록 handoff** — scv-claude-code, scv-codex 대상 handoff 2건이
    훅 seam 계약(등록 방법·이벤트 이름)을 담아 발행된다.

## How to run

```bash
bash core/tests/test-journal.sh        # 신규 (3,4,5,6 커버)
bash core/tests/run-dry.sh             # 1,2,7,8,9 assert 포함
for t in core/tests/test-*.sh; do bash "$t"; done
bash tests/run.sh
```

## Pass criteria

- 시나리오 10건 전부 자동 테스트(또는 run-dry assert)로 커버되고 통과
- 기존 스위트 무회귀
- redaction 시나리오는 마스킹 실패 시 **테스트 실패** (경고 아님)
