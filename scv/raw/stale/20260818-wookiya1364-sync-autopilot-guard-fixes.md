# sync 자동화·백업 제거 + 가드 실효 버그 5건 — 측정 기록과 결정

2026-08-18. 대표님 지시 두 갈래를 한 계획으로 묶는다.

1. "update하면 자동으로 문서포멧들도 전부 최신화 되었으면 한다. 지금은 scv:sync하면
   backup 보낸다 뭐 하면서 되게 이상하게 만들고 귀찮아진다. 백업하는게 아니고,
   레거시를 최신화 자동으로 하면 되잖아."
2. 문서 최신화 작업(적대 검증 41건) 중 드러난 **가드가 실제로는 안 걸리는** 계열
   버그 5건. 문서는 이미 사실대로 고쳐서 배포했고, 이번엔 동작을 고친다.

## 확인 1 — sync 의 백업은 스크립트 자신도 반쯤 부정하고 있다

`core/scripts/sync.sh` 한 파일 안에 "복구 경로가 무엇인가"에 대한 답이 두 개다.

```
sync.sh:344  레거시 은퇴 문서:  deliberately WITHOUT backup
             (user decision; git history is the recovery path)
sync.sh:174  템플릿 덮어쓰기:  .scv-backup/<타임스탬프>/ 에 사본 생성
```

그리고 그 `.scv-backup/` 은 `.gitignore.fragment:9` 에 들어 있다 — **추적도 안 되는
사본**이 프로젝트마다 쌓인다. git 이 이미 이전 내용을 갖고 있고 `git diff` 가 사본
디렉터리보다 잘 보여준다.

### 결정 — 백업 대신 더티 거부

덮어쓸 파일에 **커밋 안 된 변경이 있으면 덮어쓰지 않고 파일 이름을 말한다.**

- 판정: `git status --porcelain -- <파일>` 이 비어 있지 않으면 더티. 추적 안 된
  파일도 더티로 취급한다(신규 파일은 git 에 이전 내용이 없으므로 덮어쓰면 소실).
- git 저장소가 아니면 **다른 내용의 파일 전부를 더티로 취급**한다. 복구 경로가
  없는 곳에서 무단 덮어쓰기는 없다.
- 탈출구는 새로 만들지 않는다. 기존 `--force <파일>` 이 preserve 우회와 같은
  의미로 더티 거부도 우회한다.
- merge-on-markers(SCV.md)도 같은 규칙. PROJECT:LOCAL 밖의 로컬 편집은 머지가
  잃어버리므로, 더티면 그 파일을 건너뛰고 이름을 말한다.
- `backup_file`/`BACKUP_DIR`/`BACKUPS_CREATED`/"Backups:" 보고 전부 제거.
  `state-index.sh` 의 shared-core-migration 격리는 별개 장치이므로 이번 범위 밖.

## 확인 2 — "update 하면 자동 최신화"는 update 안에서는 불가능하다

플러그인 캐시가 버전별 디렉터리다. update 시점에 실행 중인 세션은 **옛 payload 의
sync.sh** 를 물고 있으므로, update 가 sync 를 부르면 옛 템플릿을 다시 깔고 "최신화
완료"라고 찍는다. 리로드 전에는 새 payload 에 손이 닿지 않는다.

### 결정 — 다음 액션이 격차를 스스로 메운다

장치는 이미 다 있다. 프로젝트에 스탬프가 있고 payload 에 버전이 있다:

```
프로젝트  scv/SCV.md   <!-- STANDARD:VERSION -->2.0.0<!-- /STANDARD:VERSION -->
payload   TEMPLATE_VERSION                      2.1.0
```

`lib/scvroot.sh` 에 `scv_autosync` 를 둔다. `scv_init_paths` 가 root 해석 직후
호출하고(9개 액션 스크립트가 이미 source), `help.sh`/`status.sh` 는 명시 호출한다.

동작: 스탬프 ≠ payload `TEMPLATE_VERSION` 이면 그 자리에서 `sync.sh --project-dir`
를 돌리고 한 줄 보고한다. sync 는 마지막에 스탬프를 payload 버전으로 다시 찍으므로
(sync.sh:382-386, 구현 전 확인함) 한 번 돌면 수렴한다 — 무한 재실행 없음.

가드레일 (하나라도 어기면 자동 실행하지 않고 조용히 액션 계속):

- **미도입/미수화 프로젝트에서는 절대 안 돈다.** SCV.md 도 PROMOTE.md 도 없으면
  no-op. 자동 sync 가 수화(hydrate)를 대신하면 안 된다 — 그건 사용자 동의가 있는
  별도 액션이다.
- **pre-2.x(스탬프 unknown 포함) 레거시는 자동으로 돌리지 않는다.** 2.0.0 은퇴
  패스가 사용자 작성 문서 7종을 백업 없이 삭제하는데, sync.md 프로토콜은 삭제 전에
  DECISIONS.md 이관을 **제안하라**고 지시한다. 자동 실행은 그 대화를 건너뛰게 된다.
  이 경우 한 줄 안내만 낸다: "template 1.x — 대화형 마이그레이션은 sync 액션으로".
  2.x → 2.y 만 자동이다. 이때 위험한 덮어쓰기는 확인 1 의 더티 거부가 막는다.
- 재귀 금지: `SCV_AUTOSYNC_RUNNING=1` 가드. 끄기: `SCV_AUTOSYNC=off` (환경변수만,
  파일 아님 — 가드의 SCV_GUARD=off 와 같은 이유).
- sync 실패는 액션을 막지 않는다(경고 후 계속). 마이그레이션이 액션을 벽돌로
  만들면 안 된다.
- payload 쪽 기준은 스크립트 자신의 위치에서 푼다: `lib/../..` 의
  `TEMPLATE_VERSION`. 저장소 배치(core/TEMPLATE_VERSION)와 materialized 배치
  (루트/TEMPLATE_VERSION) 둘 다 이 규칙으로 맞는다 — 구현 전 확인함.
- 중첩 모듈: `--project-dir "$(dirname "$SCV_DIR")"` 로 그 모듈의 scv 만 갱신.

### 계약 개정

`core/protocols/update.md` 5항 "Keep project-template synchronization as a
separate sync action" 은 이 설계와 정면 충돌한다. 개정: update 는 여전히 payload
만 갱신하지만, **리로드 후 첫 SCV 액션이 프로젝트 템플릿 격차를 자동으로 메운다**
고 명시하고, `sync` 는 수동 재실행·pre-2.x 대화형 마이그레이션용으로 남긴다.
`sync.md` 의 `.scv-backup` 문장(49·52·81·82행 부근)도 새 동작으로 바꾼다.

## 확인 3 — Codex 에서 어댑터 액션 4개가 영수증을 안 낸다

`guard.sh:188` 이 `SCV_GUARD_SCRIPTS` 를 **고정 문자열 한 개**로 비교한다
(`grep -qF`). codex `hooks.json` 은 벤더링된 `core/scripts` 한 곳만 넘기는데,
`$scv:update`·`$scv:set-models`·`$scv:sync`·hydrate 는 `adapter/scripts/` 로 돈다.
codex 에는 mint 훅 항목이 없어 셸 관찰이 유일한 발급 경로다 — 즉 **네 액션이
아무것도 발급하지 않는다.** 훅을 직접 돌려 확인했고, `guard.md:85-88` 이 요구하는
"어댑터 스크립트 디렉터리도 mint 허용목록에" 를 변수 구조상 지킬 수 없다.

### 결정 — 콜론 구분 다중 디렉터리

`SCV_GUARD_SCRIPTS` 를 콜론으로 갈라 디렉터리별로 기존과 동일한 고정 문자열 비교를
한다. 기존 단일 값은 그대로 동작(하위 호환). 계약과 wrapper-integration §7,
codex-runtime.md 의 "알려진 격차" 문구는 Core 가 벤더링된 **뒤** 래퍼 PR 에서
고친다 — 순서를 어기면 문서가 아직 없는 동작을 약속한다.

## 확인 4 — Codex 훅 두 항목이 서로 다른 환경을 넘긴다

`gate-write` 만 `SCV_GUARD_EXEMPT=".codex/config.toml"` 을 갖고 `gate-bash` 는
없다. 같은 패치가 editor 경로로는 허용, shell 경로로는 거부 — 재현 확인.
`$scv:set-models` 3단계가 정확히 그 파일 편집이다.

### 결정 — 두 항목 모두 두 변수를 다 싣는다 (래퍼 PR)

`SCV_GUARD_SCRIPTS`(콜론 목록: 벤더 core/scripts + adapter/scripts)와
`SCV_GUARD_EXEMPT` 를 gate-bash·gate-write 양쪽에. `test-guard-registration.sh` 에
어댑터 스크립트 발급과 셸 경로 config.toml 면제 케이스를 추가한다.

## 확인 5 — 영수증 저장소를 못 쓰면 조용히 전부 거부된다

`mint()` 의 `mkdir -p ... || return 0` 이 소리 없이 no-op 하고, `has_receipt` 가
세션 내내 거짓이 되어 Rule B 가 비면제 쓰기 전부를 거부한다. 거부 메시지는 "액션을
실행하라"인데 실행해도 같은 저장소에 발급하므로 도움이 안 된다.

### 결정 — 닫힌 채 유지하되, 이유를 바꾼다

fail open 으로 돌리지 않는다. 모델이 Bash 로 저장소를 `chmod 000` 하면 fail open
= 가드 해제가 되므로, 닫힌 쪽이 적대적으로 안전하다. 고치는 것은 **침묵**이다:

- gate 모드에서 저장소가 사용 불가면 거부 사유를 바꾼다 — 저장소 경로와 권한
  문제를 이름 붙이고 `SCV_GUARD_STATE` 로 옮기는 길을 안내한다.
- mint 실패 시 stderr 한 줄. 계약의 실패 정책 절은 이미 사실대로(닫힘·침묵) 고쳐
  배포했으므로, "침묵" 부분만 다시 사실에 맞게 갱신한다.

## 확인 6 — 그 버그를 잡았어야 할 테스트 둘이 무력하다

- `core/tests/test-guard.sh` T15 가 `README.md` 로 검사한다. `*.md` 는 Rule B
  면제라 **가드가 뭘 하든 통과**한다. 비면제 경로로 바꾸고 새 동작(거부 + 저장소를
  이름 붙인 사유)을 단언한다.
- T21 이 `scv/promote/<계획>/PLAN.md` 존재를 조건으로 삼는데 그 계획은 아카이브로
  이동했다 — **영영 안 돈다.** 계획 문서가 아니라 **두 스크립트를 직접** 비교하게
  다시 쓴다: guard.sh 의 `is_exempt` 와 check-provenance.sh 의 `is_exempt` 가 공통
  집합(*.md·.gitignore·.gitattributes·LICENSE)을 둘 다 담는지.

## 확인 7 — 래퍼에 투영된 test-guard.sh 가 13/34 실패한다

cc 의 `tests/test-guard.sh` 는 Core `core/tests/test-guard.sh` 의 바이트 동일
투영이다. 루트를 `<파일>/../..` 로 잡는데, Core(`core/tests/`)에서는 저장소
루트가 맞고 cc(`tests/`)에서는 **한 단계 위**다. 그래서 cc 에서 가드 스크립트를
`labs/core/...` 에서 찾다 실패한다. codex 는 벤더 서브트리 안에서 상대 배치가
유지되어 초록이다. **cc CI 는 이 테스트를 아예 안 돈다** — 빨간 채로 보이지 않았다.

### 결정 — Core 테스트를 배치 무관하게, cc CI 에 등록

후보 루트(`../`, `../../`)×후보 코어(`core`, `vendor/scv-core/core`,
`plugins/scv/vendor/scv-core/core`)를 탐색해 guard.sh 가 실재하는 조합을 쓴다.
cc `core-contract.yml` 의 Cross-platform smoke 에 `tests/test-guard.sh` 를
추가한다(래퍼 PR).

## 예상 함정

- 새 스크립트·새 동작은 Core 벤더링 후에야 래퍼가 쓸 수 있다. Core → 봇 동기화 →
  래퍼 PR 순서. 릴리스 PR 제목에는 `[no-plan: …]`, 래퍼에서 벤더 트리를 직접
  만지지 않는다.
- `core/` 는 호스트 중립: 새 코드·주석에 호스트 토큰 금지. 테스트 안에서 호스트
  토큰이 필요하면 기존 T19 방식(런타임 조립)을 따른다.
- sync.md·update.md 문구 변경은 `test-guard-consistency.sh` 의 구문 스윕 대상이다.
  "by hand" 류 문구를 새로 넣으면 anchor 등록이 필요하다.
- autosync 가 readpath consume 도중에도 발화할 수 있다 — sync 는 raw/promote/
  archive 내용물을 만지지 않으므로 안전하지만, 테스트로 못 박는다.
- 더티 거부의 "추적 안 됨 = 더티" 규칙은 첫 sync(수화 직후, 커밋 전)와 상호작용
  한다: 그 시점 파일들은 템플릿과 동일해서 `cmp -s` 로 먼저 걸러진다 — 동일 파일은
  더티 검사 전에 skip. 순서를 지킬 것.
