# Test Plan — 미결 6건 후속 — 결정 계약 한 곳, 중복 검사 허용목록, 갱신 거부 때 커밋 안내

## Overview

여섯 건 각각을 사용자 결정대로 닫았는지 하나씩 고정한다. 문서 변경(1·4)은 "새 문장이 있고 옛 단락이 없다" 는 grep 과
기존 계약 검사(run-dry [16], rule-constitution (a)(b))의 통과로, 문구 변경(5)은 자동 갱신 픽스처의 stderr 로, 검사
변경(6)은 허용목록·기준선 개수와 자가검사(심은 중복은 잡히고 허용된 중복은 안 잡힘)로, 기록만 하는 것(2·3)은 결정
로그 엔트리의 존재로 본다. 마지막으로 전체 검사와 릴리스 세 곳을 확인한다.

## Test scenarios

### T1. 1 — Graft 지원 언어 목록: README 와 일치 + 확인 날짜

- **Setup**: `core/scripts/lib/graft.sh`, github.com/nanonets/graft README (2026-09-21).
- **Run**: README 의 완전 지원 9개 + 넓은 지원 14개 언어의 확장자가 모두 `SCV_GRAFT_LANG_EXTS` 에 있는지 사람이 대조(계획서 표에
  기록). `test-graft-adapter.sh` 가 상수 옆 주석에 `2026-09-21 확인` 이 있는지 grep.
- **Expected**: 23개 언어 모두 대응, 값 변경 없음. 주석에 확인 날짜와 확인 절차 한 줄.
- **Pass criterion**: `bash core/tests/test-graft-adapter.sh` 통과, 주석 grep 1건.

### T2. 2 — no-graph 분기는 이미 있다 (사실 기록)

- **Setup**: `core/scripts/lib/graft.sh` `scv_graft_notice`, `core/tests/test-graft-adapter.sh` 112·154행.
- **Run**: `scv_graft_notice no-graph 3` 출력에 `graft init` 이 있고 `npm i -g` 가 없는지. 결정 로그에 "미결 2 는 0.55.0 에 이미 닫힘" 엔트리.
- **Expected**: 안내 문구 = init 명령. 엔트리 1개(verdict: lesson 또는 not-needed).
- **Pass criterion**: test-graft-adapter 통과 + `grep -c 'no-graph' scv/DECISIONS.md` ≥ 1 (이 계획 이후 추가분).

### T3. 3 — "대화가 있는 액션" 7개 유지 (결정 기록)

- **Setup**: `scv/DECISIONS.md`.
- **Run**: "7개" 와 "유지" 를 담은 엔트리 grep.
- **Expected**: 엔트리 1개, author 있음.
- **Pass criterion**: grep 1건 이상, `record-read.sh --key` 로 읽힘.

### T4. 4 — 결정 로그 계약 한 곳 + 세 프로토콜 축약, 기존 계약 유지

- **Setup**: `core/contracts/decisions.md`(신설), `core/protocols/{promote,work,regression}.md`.
- **Run**: 계약 문서에 다섯 요소(append-only · seed via sync · 핸드오프 형식 재사용 · author 필수 · 스크립트로만 + INDEX) grep.
  세 프로토콜 각각에 `contracts/decisions.md` 참조 1개 이상, `decisions-append.sh` 호출 블록 1개, 엔트리 블록 헤더
  `## [<YYYY-MM-DD HH:MM>] <author>` 와 `author is mandatory` 그대로. 옛 설명 단락("keeps the format identical across the three
  append points", "reuses the handoff decision format") 은 프로토콜에서 0건(계약에만).
- **Expected**: 참조 3/3, 옛 단락 0건, run-dry [16] 통과, 검사 (b) 후보에서 키 2개(`the entry reuses…`, `write it with the script…`) 사라짐.
- **Pass criterion**: `bash core/tests/run-dry.sh` 통과 + `bash core/tests/test-rule-constitution.sh` 통과 + grep 결과 일치.

### T5. 5 — 갱신 거부(PARTIAL)와 드리프트 설명에 커밋 안내

- **Setup**: `core/tests/test-autosync.sh` T4b 픽스처(커밋 안 된 수정이 있는 프로젝트).
- **Run**: 자동 갱신 stderr 의 PARTIAL 머리줄과 `scv_template_drift` 출력.
- **Expected**: PARTIAL 머리줄에 `commit (or discard)` 와 `next action refreshes` 가 있고, 기존 `PARTIAL` · `the files below were skipped` ·
  DIRTY 줄은 그대로. drift 출력에도 `commit` 안내 한 줄. 강제 덮어쓰기 없음(파일 내용 그대로).
- **Pass criterion**: `bash core/tests/test-autosync.sh` 통과(새 assert 포함) + `bash core/tests/test-scvroot.sh` 통과.

### T6. 6 — 검사 (b) 허용목록: 의도된 반복은 빠지고 심은 중복은 잡힌다

- **Setup**: `core/tests/fixtures/rule-constitution/duplicate-allowlist.txt`(신설, `<키>\t<이유>`), `duplicate-baseline.txt`(축소),
  `core/scripts/lib/rule-constitution.sh` `scv_rc_allowed_out`.
- **Run**: 본 검사 — 후보 수·기준선 수 출력. 자가검사 `--self-test` — (i) 허용목록의 키를 두 파일에 심어도 `B_NEW` 비어 있음,
  (ii) 허용목록에 없는 픽스처 문장을 심으면 잡힘(기존). 이유 없는 허용목록 줄을 임시로 넣으면 검사가 거부.
  `bash core/scripts/check-purity.sh` 로 새 함수의 `@pure` 표기 검사.
- **Expected**: 허용목록 6건(쉬운 말 2 · 언어 설정 1 · 훅 머리말 3), 기준선 3건, 후보 = 기준선 이하. 자가검사 통과. 순수성 통과.
- **Pass criterion**: `bash core/tests/test-rule-constitution.sh && bash core/tests/test-rule-constitution.sh --self-test && bash core/tests/test-purity.sh` 통과.

### T7. 전체 검사 + 릴리스 세 곳

- **Setup**: 위 전부 병합된 브랜치. 래퍼 두 체크아웃(../scv-claude-code, ../scv-codex) 최신.
- **Run**: How to run 전체. PR → develop 병합, `gh workflow run promote.yml`, 래퍼 각각 핀 PR 병합 → 릴리스 PR → promote.
- **Expected**: 로컬(맥)과 CI(ubuntu·macos) 초록. 코어 v0.56.0 릴리스 자산 2개. 래퍼 v0.56.0 · v0.56.0-codex.1 "Latest".
- **Pass criterion**: `gh release view v0.56.0` 자산 2개; 래퍼 두 곳 `gh release list` 최신 항목 일치.

## How to run

```bash
bash core/tests/test-rule-constitution.sh && bash core/tests/test-rule-constitution.sh --self-test && bash core/tests/test-graft-adapter.sh && bash core/tests/test-autosync.sh && bash core/tests/test-scvroot.sh && bash core/tests/test-purity.sh && bash core/tests/run-dry.sh && bash tests/run.sh
```

## Pass criteria

- T1~T7 전부 통과. How to run 의 마지막 명령까지 exit 0.
- `core/tests/test-*.sh` 57개 전부 초록(로컬 맥) + PR CI 초록.
- 코어·래퍼 둘의 릴리스가 모두 게시됨.

## Related Documents

- `scv/archive/20260920-wookiya1364-rule-conflicts-followup/TESTS.md` T4 — 기록 계약 검사의 원형
