# Test Plan — 공개 저장소 개인정보 정리 — 과거 기록까지 지우고, 다시 쌓이지 않게, SCV 기록은 비공개 저장소로

## Overview

사용자가 요구한 것은 세 가지다. 첫째, 감사에서 찾은 개인정보(실명 · 개인 메일 · 주제 밖 개인 대화 · 회사 팀 이름 · 내
컴퓨터 경로 · 세션 id)를 네 공개 저장소의 과거 기록까지 모두 지운다. 둘째, 앞으로 커밋할 때 다시 쌓이지 않게 막는다.
셋째, SCV 기록은 비공개 저장소로 옮긴다. 이와 함께 열린 PR · 릴리스 · 코어 고정 · 채널이 깨지지 않아야 한다. 아래
시나리오는 이것들을 하나씩 확인한다. 개인 값(실명 · 회사 팀 이름 · 개인 메일)은 이 문서에 적지 않는다. 검사는 이
컴퓨터의 비공개 목록 파일(`~/.config/scv/privacy-terms`, 권한 600 — 저장소 밖)과 GitHub 비밀값에서 읽는다.

## Test scenarios

### T1. 새 클론의 모든 ref 에 개인정보가 없다

- **Setup**: 덮어쓴 뒤, 네 저장소를 새로 `--mirror` 클론한다.
- **Run**: 모든 브랜치 · 태그의 파일 내용 · 커밋 메시지 · 작성자 · 커미터를 비공개 목록 + 공통 패턴(개인 메일, `/Users/<이름>/`, `/private/tmp/claude-<숫자>`, `session_01…`, `Claude-Session:`)으로 훑는다.
- **Expected**: 맞는 곳 0건.
- **Pass criterion**: 네 저장소 모두 0건. 검사 스크립트 종료 코드 0.

### T2. 작성자 정보는 그대로다 (사용자 결정, 2026-10-27)

- **Run**: 다시 쓰기 전 · 후 네 저장소의 작성자 · 커미터 이름 · 메일 목록을 비교한다.
- **Expected**: 같다 — 실명 · 개인 메일은 공개 계정의 정체성이라 남긴다.
- **Pass criterion**: 목록 차이 0.

### T3. SCV 기록이 공개 저장소에서 사라졌다

- **Run**: 코어 · 모드의 모든 ref 에서 `scv/journal/`, `scv/conversations/`, `scv/dreams/`, `scv/raw/` 경로가 있었던 커밋을 찾는다.
- **Expected**: 0건. 계획 보관(`scv/archive/`) · 결정 기록은 남아 있다.
- **Pass criterion**: 기록 경로 0건, 보관 계획 수는 전과 같다.

### T4. 비공개 scv-records 에 기록이 모두 있다

- **Setup**: `scv-records`(비공개)를 클론한다.
- **Run**: 저장소별 폴더(core · mods)의 파일 수와 내용 해시를 옮기기 전 목록과 맞춘다. 보관 계획 하나를 골라 그 `raw_sources` 대화 경로가 `scv-records/<저장소>/` 아래에 있는지 본다.
- **Expected**: 파일 수 · 해시가 같고, 근거 대화를 찾을 수 있다. 저장소가 비공개다(`gh api … .private == true`).
- **Pass criterion**: 차이 0, 비공개 확인.

### T5. 코어 payload 가 바이트 그대로다

- **Run**: 다시 쓴 코어의 최근 태그 다섯 개 이상(마지막 릴리스 포함)에서 `tools/export-core.sh` 로 payload 를 만들어 해시를 낸다. 같은 태그의 GitHub 릴리스 자산 SHA-256 과 래퍼 `core.lock.json` 의 payload 해시와 맞춘다.
- **Expected**: 모두 같다.
- **Pass criterion**: 어긋남 0.

### T6. 래퍼의 코어 고정이 새 코어 커밋을 가리킨다

- **Run**: 두 래퍼의 모든 브랜치 끝에서 `vendor/scv-core/core.lock.json`(codex 는 `plugins/scv/vendor/…`)의 `source_commit` 을 읽어, 다시 쓴 코어에 그 커밋이 있는지와 그 커밋의 payload 해시가 lock 과 같은지 본다. 래퍼 기록 전체에서 옛 코어 번호(번호 표의 왼쪽)를 찾는다.
- **Expected**: 모두 있음 · 같음, 옛 번호 0건.
- **Pass criterion**: 래퍼 검증 스크립트(`tools/verify-core.sh` · `scripts/verify-core.sh`) 통과, 옛 번호 0건.

### T7. 브랜치 · 태그 · 릴리스가 그대로다

- **Run**: 전 · 후 목록을 비교한다 — 브랜치 이름 · 수, 태그 이름 · 수, 릴리스 이름 · 자산 · 최신 표시.
- **Expected**: 같다(가리키는 커밋 번호만 바뀜).
- **Pass criterion**: 이름 · 수 · 자산 차이 0.

### T8. 이 컴퓨터의 SCV 가 기록을 비공개 저장소에 남긴다

- **Setup**: 기록 폴더 연결을 마친 코어 작업 사본.
- **Run**: SCV 대화 한 턴을 기록하고(`journal-append.sh`), `pr-helper` 의 기록 커밋 단계를 dry-run 으로 돌린다.
- **Expected**: 새 기록이 `scv-records` 작업 사본에 생긴다. 공개 저장소의 `git status` 에는 기록 파일이 나오지 않는다. pr-helper 가 실패하지 않는다.
- **Pass criterion**: 세 조건 모두 참.

### T9. 다시 쌓이지 않게 — 개인정보 검사가 막는다

- **Setup**: 코어의 `core/scripts/check-privacy.sh` 와 네 저장소 branch-flow 연결.
- **Run**: 임시 브랜치(또는 같은 입력의 로컬 실행)로 다섯 경우를 넣는다 — (a) 개인 메일 작성자(기본은 허용, `SCV_PRIVACY_EMAILS=on` 일 때만 막음), (b) 추가 줄에 `/Users/<이름>/` 경로, (c) 커밋 메시지에 `Claude-Session:` 줄, (d) 비밀 목록의 낱말(실명 · 팀 이름) 하나, (e) 깨끗한 커밋.
- **Expected**: (a)는 기본에서 통과하고 켰을 때 실패한다. (b)~(d)는 실패하고 무엇이 걸렸는지 말한다(개인 값 자체는 출력에서 가린다). (e)는 통과한다.
- **Pass criterion**: 다섯 경우 모두 기대대로. 맥 · 리눅스 결과 같음.

### T10. 작성자 설정과 세션 줄 중단

- **Run**: 이 세션이 이후 만드는 커밋 · PR 본문에 세션 링크 줄이 없는지 확인한다. (작성자 이름 · 메일은 사용자 결정으로 그대로 — T2.)
- **Expected**: 세션 줄이 없다.
- **Pass criterion**: 모두 참.

### T11. 영구 브랜치 규칙이 원래대로다

- **Run**: 덮어쓰기 전 · 후 ruleset JSON(규칙 종류 · 대상 · 우회자 · 시행 상태)을 비교한다.
- **Expected**: 같다(`enforcement: active`).
- **Pass criterion**: 차이 0.

### T12. PR · 릴리스 본문의 개인정보도 정리되었다

- **Run**: 네 저장소의 PR 본문 · 댓글 · 릴리스 본문을 API 로 훑는다(T1 과 같은 패턴).
- **Expected**: 맞는 곳을 고쳐 0건. 고칠 수 없는 것(남의 댓글 등)은 목록으로 보고.
- **Pass criterion**: 고칠 수 있는 것 0건, 나머지는 목록.

### T13. 덮어쓴 뒤 CI · 채널 · 플러그인 업데이트

- **Run**: 네 저장소 develop · stage · main CI 를 다시 돌린다. 채널 동기화로 `channel/dev` · `channel/stage` 를 다시 만든다. 덮어쓰기 전에 임시 설정 폴더에 옛 기록으로 설치해 둔 claude · codex 플러그인을 업데이트한다.
- **Expected**: CI 통과. 채널 브랜치가 새 코어 커밋으로 다시 만들어진다. 업데이트가 되거나, 안 되면 마켓을 지웠다 다시 넣는 안내대로 하면 된다(그 안내가 릴리스 노트에 실린다).
- **Pass criterion**: CI · 채널 통과, 업데이트 결과와 대처가 확인됨.

### T14. 되돌리는 길이 있다

- **Run**: 덮어쓰기 전에, 백업 미러로 다시 올리는 명령을 `--dry-run` 으로 돌려 본다. 덮어쓴 뒤에도 백업이 남아 있는지 확인한다.
- **Expected**: dry-run 이 ref 목록을 정확히 내놓는다. 백업이 남아 있다(공개된 곳에 올리지 않음).
- **Pass criterion**: 둘 다 참.

### T15. 열린 PR 이 깨지지 않았다

- **Run**: 덮어쓰기 직전과 직후 네 저장소의 열린 PR 목록을 본다.
- **Expected**: 직전에 열린 PR 이 0개다(문서 PR 넷은 먼저 병합). 직후에도 깨진 PR 이 없다.
- **Pass criterion**: 열린 PR 0, 또는 열린 PR 마다 diff 가 덮어쓰기 전과 같다.

### T16. GitHub 지원 요청 문안

- **Run**: 저장소별 PR 번호 범위와 옛 커밋 목록(백업에서)을 담은 지원 요청 문안을 만든다. 포크 주인에게 보낼 짧은 부탁 문안도 만든다.
- **Expected**: 사용자가 그대로 보낼 수 있는 문안 두 개.
- **Pass criterion**: 사용자에게 전달됨.

## How to run

```bash
bash core/tests/test-check-privacy.sh && bash tools/privacy-audit.sh --repos ../scv-core ../scv-claude-code ../scv-codex ../scv-mods --terms "${SCV_PRIVACY_TERMS_FILE:-$HOME/.config/scv/privacy-terms}"
```

## Pass criteria

- T1 – T16 모두 통과.
- 네 저장소 새 클론에서 개인정보 0건, 릴리스 · 고정 · 채널 · CI 정상, 기록은 비공개 저장소에.
- 남은 GitHub 쪽 옛 사본(PR ref · 캐시 · 포크)은 지원 요청 문안이 사용자에게 전달된 상태.

## Related Documents

- `PLAN.md` — 범위 · 지킬 것 · 위험
