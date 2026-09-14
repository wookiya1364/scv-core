# Test Plan — help 매 턴 비용 다이어트 — 17k 토큰을 6~7k 로, 동작은 검사가 지킨다

## Overview

본문이 줄었는데 동작은 같은지를 본다. "같다"의 정의는 기존 검사다 — help 본문을 읽는 검사
여섯과 run-dry 의 help 단언이 그대로(또는 대상만 본문+부속 파일로 넓혀서) 통과하면 동작이
같다. 여기에 새 상한 검사가 "줄었다"를 숫자로 못 박고, 배송 경로 검사가 부속 파일이 래퍼
변경 없이 끝까지 실려가는지를 본다. 래퍼 파일을 보는 케이스는 옆 체크아웃이 있을 때만 —
없으면 SKIP. 마지막 T9 는 릴리스·설치 뒤 사람이 한 번 본다.

## Test scenarios

### T1. 본문 상한 — 14,000 바이트 이하, 검사가 지킨다

- **Setup**: `core/protocols/help.md` (다이어트 뒤).
- **Run**: `bash core/tests/test-help-budget.sh`.
- **Expected**: 본문 바이트 ≤ 14,000 → ✓. 임시 복제에서 본문에 1,000줄을 덧붙이면 ✖ 와 exit 1.
- **Pass criterion**: 실제 본문 ✓ · 부풀린 복제 ✖ (검사가 양쪽을 구분한다). 상한은
  `SCV_HELP_BODY_MAX` 로 바꿀 수 있다(기본 14000).

### T2. 부속 파일 다섯 — 존재하고, 본문에서 정확히 한 번씩 읽힌다

- **Run**: 같은 검사. `core/protocols/help/` 의 `language-setup.md · legacy-migration.md ·
  hydrate.md · archive-search.md · promote-handoff.md` 를 순회.
- **Expected**: 다섯 파일 존재. help.md 에 `${SCV_CORE_ROOT}/protocols/help/<name>.md` 참조가
  파일마다 **정확히 한 번**. 참조는 있는데 파일이 없거나(고아 참조), 파일은 있는데 참조가
  없으면(고아 파일) ✖. 임시 복제에서 하나를 지워 ✖ 를 확인한다.
- **Pass criterion**: 5/5 참조 1회 · 고아 0 · 지운 복제 ✖.

### T3. 포인터는 명령형 한 문장이다

- **Run**: help.md 의 부속 파일 참조 줄 다섯.
- **Expected**: 각 줄이 "Read `…/help/<name>.md` now" 꼴 — `Read` 와 `now` 가 같은 줄에 있다.
  분기 진입 조건은 그 앞줄에 있다.
- **Pass criterion**: 5/5 (검사 T3 항목).

### T4. 부속 파일은 깨끗하다 — 규칙 중복 없음, 호스트 중립

- **Run**: 부속 파일 다섯의 본문.
- **Expected**: `## Plain language first` · `## Language preference` 절이 없다. `SCV_CORE_ROOT`
  외의 경로 자리표시자가 없다. `tests/test-host-neutral.sh`(래퍼 안에서만) 와
  `test-delegate-effort` T7 의 effort 단계 이름 검사가 부속 파일에도 걸리지 않는다.
- **Pass criterion**: 절 0건 · 호스트 중립 검사 통과.

### T5. 앵커는 살아 있다 — 기존 검사 전부 통과

- **Run**: `bash core/tests/test-force-help.sh` · `test-help-shape.sh` · `test-delegate-effort.sh` ·
  `test-guidance.sh` · `run-dry.sh` · (저장소 루트) `tests/test-profile-and-export.sh` ·
  `tests/test-host-runtime-materialization.sh` · `tools/verify-core.sh`.
- **Expected**: 전부 통과. run-dry 에서 대상을 `HELP_ALL`(본문+부속 파일)로 바꾼 단언은 열 개이고, 바꾼
  목록이 PR 본문에 있다. test-help-shape T7(쉬운 말 절 HEAD 동일) 통과 —
  즉 쉬운 말 절 무변경. test-guidance 160행(`hostcmd-promote` 가 help.md 에 있음) 통과 — 즉
  `action:promote` 토큰이 본문에 남아 있다. verify-core 의 규약 수 15 통과 — 즉 수 세기가
  최상위로 한정됐다.
- **Pass criterion**: 모든 검사 exit 0.

### T6. 자리표시자 치환이 부속 파일까지 미친다

- **Setup**: 임시 디렉터리에 `tools/export-core.sh --output <tmp>` 로 내보낸 뒤, 호스트 프로필
  하나로 `tools/materialize-profile.sh` 를 돌린다(기존 `tests/test-host-runtime-materialization.sh`
  가 쓰는 방식 그대로).
- **Expected**: 결과의 `core/protocols/help/*.md` 에 `SCV_CORE_ROOT` 리터럴이 남아 있지 않고,
  help.md 의 참조 줄과 부속 파일이 같은 치환값을 가리킨다.
- **Pass criterion**: `grep -c SCV_CORE_ROOT` 0 · 참조 경로에 실제 파일 존재.

### T7. 래퍼 무변경 — 투영 검사 0 불일치 (옆 체크아웃 있을 때만)

- **Setup**: `../scv-claude-code` 체크아웃. 이 코어를 벤더링(`tools/vendor-core.sh` 또는 래퍼의
  sync 경로)한 임시 복제.
- **Run**: 래퍼에서 `bash scripts/project-core.sh --check`.
- **Expected**: `PROJECTION_MISMATCH` 0. `protocols/help/` 다섯 파일이 래퍼 `protocols/help/` 에
  나타난다. `skills/` 아래에 `help/` 외의 새 디렉터리가 생기지 않는다(부속 파일이 액션으로
  오인되지 않음). 래퍼 저장소의 diff 가 벤더·투영 산출물뿐이고 스크립트 변경이 없다.
- **Pass criterion**: exit 0 · 다섯 파일 존재 · `git diff --stat` 에 `scripts/` 없음. 체크아웃 없으면 SKIP.

### T8. 동작 회귀 — 세 모드와 짧은 턴 (archive 검사로)

- **Run**: `/scv:regression` 이 도는 archive 의 help 관련 TESTS 넷
  (`20260828-…-forced-help-invocation` · `20260831-…-force-help-preflight` ·
  `20260901-…-unconditional-help` · `20260903-…-help-answer-shape`) 의 `## How to run`.
- **Expected**: 전부 통과. 이 계획은 그 넷이 못 박은 동작(기록 없이 돌려보내지 않음 · 짧은 턴
  이어붙이기 · 답 모양 · 강제 호출)을 바꾸지 않는다.
- **Pass criterion**: 회귀 스위트 exit 0.

### T9. 실측 — 릴리스·설치 뒤 (수동)

- **Setup**: 0.48.0 릴리스 후 래퍼 갱신·설치(`/plugin marketplace update` → `/reload-plugins`).
- **Run**: (a) `claude plugin details scv@scv-claude-code`. (b) hydrate 안 된 프로젝트에서
  `/scv:help` — hydrate 제안 질문이 뜨는가(부속 파일을 실제로 읽었는가). (c) 진행 중 계획이 있는
  프로젝트에서 `/scv:help "…"` 뒤 "응" — 대화 파일에 이어 붙는가. (d) `/scv:help "지난 … 보여줘"`
  — archive 요약이 나오는가.
- **Expected**: (a) help on-invoke ≤ 5.5k(전 11.1k), 그리고 T12 의 세 수치. (b)(c)(d) 이전과 같은
  질문·출력 — (d) 에서 모델이 `--archive-index` 를 실제로 돌리는지 본다.
- **Pass criterion**: (a) 수치를 CHANGELOG 0.48.0 에 전후로 적는다. (b)~(d) 한 번씩 확인.
  (b) 에서 모델이 부속 파일을 읽지 않고 넘어가면 Risks 의 완화책(그 스텁만 되돌림)으로 간다.

### T10. 보조 스크립트 — 대화 모드 출력은 파싱 머리만, 다른 두 형태는 그대로

- **Setup**: hydrate 안 된 임시 프로젝트(run-dry 가 만드는 것과 같은 꼴) 와 archive 샘플 하나.
- **Run**: `help.sh --with-context` · `help.sh` (인자 없음) · `help.sh "search refund"` (위치 인자).
- **Expected**: `--with-context` 출력에 `ARG_CONTEXT: provided` · `UNFINISHED_CONVERSATIONS:` ·
  `LEGACY_CONVERSATIONS:` 가 있고, `Current project diagnosis` · `Dependency check:` · `╔` 배너 ·
  `ARCHIVE_INDEX:` 가 **없다**; 바이트 ≤ 1,000. 인자 없음 출력은 다이어트 전과 바이트 단위로 같다
  (진단·의존성 표 포함 — run-dry 2279 가 본다). 위치 인자 출력은 그대로 `ARCHIVE_INDEX:` 와 샘플
  slug 를 품는다(run-dry 713 그대로 통과).
- **Pass criterion**: 세 형태 모두 기대와 같다. `test-help-budget.sh` 항목.

### T11. archive 목록은 요청할 때만 — 새 플래그와 규약 문장

- **Run**: `help.sh --archive-index`; `core/protocols/help.md` 와 `core/protocols/help/archive-search.md`.
- **Expected**: 플래그 출력에 파싱 머리 + `ARCHIVE_INDEX:` 블록(항목 `<folder> | <title> | <created_at>`)
  이 있고 배너·진단은 없다. 규약 본문의 파싱 목록에 `ARCHIVE_INDEX:` 줄이 없고, archive 검색
  부속 파일 1단계가 `--archive-index` 를 먼저 돌리라는 명령형 문장이다. run-dry 3301 의
  `ARCHIVE_INDEX:` 단언은 대상을 본문+부속 파일로 바꿔 통과한다.
- **Pass criterion**: 플래그 출력 ✓ · 규약 문장 ✓ · run-dry 통과.

### T12. 매 턴 스택 합 — 18,000 바이트 이하

- **Run**: `test-help-budget.sh` 가 훅(`on-user-prompt.sh` 에 프롬프트 JSON 한 줄) 출력 + `help.md`
  본문 + `help.sh --with-context` 출력의 바이트를 더한다.
- **Expected**: 합 ≤ 18,000 (`SCV_HELP_TURN_MAX` 로 바꿀 수 있다). 다이어트 전 44,458 이라 Red 로
  시작한다. 세 항목 각각의 수치를 한 줄씩 찍어 CHANGELOG 에 옮겨 적을 수 있게 한다.
- **Pass criterion**: 합 ≤ 상한 · 세 수치 출력.

## How to run

```bash
bash core/tests/test-help-budget.sh && bash core/tests/test-force-help.sh && bash core/tests/test-help-shape.sh && bash core/tests/test-delegate-effort.sh && bash core/tests/test-guidance.sh && bash tests/test-profile-and-export.sh
```

## Pass criteria

- T1~T6 · T10~T12 자동 통과, T7 은 옆 체크아웃이 있으면 통과 아니면 SKIP, T8 회귀 통과.
- T9 는 릴리스 뒤 사람이 확인하고 수치를 CHANGELOG 에 적으면 DONE.

## Related Documents

- `core/tests/test-skill-descriptions.sh` — 새 검사가 따르는 골격(ok/fail/skip · 페이로드 탐색 · 순수부 @pure)
