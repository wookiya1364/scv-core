# Test Plan — 모델별 프롬프팅 — help 가 그 모델의 공식 가이드 원문을 보고 요청을 최선의 프롬프트로 다시 쓴다

## Overview

두 층을 본다. 기계가 판정하는 층: help 스크립트가 모델 id 와 색인만 보고 "무엇을 읽을지(GUIDE: load/loaded/none)" 를
결정적으로 정하는지, 코어가 모델 이름을 모른 채로 그 일을 하는지. 모델이 하는 층(다시 쓰기 · 되묻기): 규약 문서에
그 단계가 빠짐없이 있는지 문자열로 보고, 실제 행동은 래퍼 릴리스 뒤 대화 기록으로 실측한다(T8).

## Test scenarios

### T1. 순수부 전수 검사

- **Setup**: `core/scripts/lib/model-prompting.sh` 를 source.
- **Run**: 고정 입력 —
  정규화: `Vendor-Model-A` → `vendor-model-a`, `vendor-model-a[1m]` → `vendor-model-a`, 앞뒤 공백, 빈 값 → 빈 값 ·
  조회: 색인에 `vendor-model-a` 와 `vendor-model-a-5` 가 있을 때 `vendor-model-a` 는 앞 행만(접두어 충돌 없음), 없는 id → 빈 값, 주석 · 빈 줄 무시, 공통 행은 모델 행에 붙어 나온다 ·
  결정: (행 없음, *) → none / (행 A, 읽은 모델 없음) → load / (행 A, A) → loaded / (행 A, B) → load ·
  경과 일수: 윤년 경계, 형식 오류 → 빈 값 ·
  GUIDE 줄: none → `GUIDE: none` / load → 모델 원문과 공통 원문 경로 / loaded → `GUIDE: loaded` 한 줄 / 기준 초과 → 같은 줄에 갱신 명령.
- **Expected**: 모든 케이스 기대값과 일치.
- **Pass criterion**: `OK [T1] <n>/<n>`.

### T2. help 스크립트 — 모델 전환 → load, 표시 → loaded, 다른 모델 → load

- **Setup**: 임시 저장소 + 픽스처 색인(`core/tests/fixtures/model-prompting/`, 중립 id 2개 + 공통 1, md 3개), 픽스처 호스트 프로필에 `SCV_PROMPTING_GUIDES`.
- **Run**: `help.sh --with-context --model vendor-model-a` → `help-state.sh mark-guide vendor-model-a` → 같은 호출 → `--model vendor-model-b`.
- **Expected**: 첫 출력 `GUIDE: load` + A 원문 · 공통 원문 경로, 표시 뒤 `GUIDE: loaded`, B 로 바꾸면 다시 `GUIDE: load` + B 원문. 기존 헤더 줄(ARG_CONTEXT · PROTOCOL …)은 그대로.
- **Pass criterion**: `OK [T2] load→loaded→load`.

### T3. 조용해야 할 때 `GUIDE: none`

- **Run**: (a) 프로필 키 없음 (b) 색인 파일 없음 (c) 색인에 없는 모델 (d) `--model` 없음 · 빈 `--model ""` (e) 원문 파일 누락 (f) `SCV_MODEL_PROMPTING=off`.
- **Expected**: (a)(b)(c)(e)(f) 와 빈 `--model ""` 은 `GUIDE: none`(e 는 누락 파일 이름 한 줄 추가). `--model` 을 아예 안 주면 GUIDE 줄이 없다 — 이전과 바이트 단위로 같은 출력. 모두 exit 0, 다른 헤더 줄 불변.
- **Pass criterion**: `OK [T3] 6/6 none`.

### T4. 재설정이 읽은 모델을 비운다

- **Run**: A 를 읽음 표시 → 표식 재설정(압축 · clear · 재개 경로와 같은 `reset`) → `help.sh --model vendor-model-a`.
- **Expected**: `GUIDE: load` (원문이 컨텍스트에서 사라졌을 수 있으므로).
- **Pass criterion**: `OK [T4] reset→load`.

### T4b. 컨텍스트가 바뀌면 다시 load (리뷰 반영)

- **Run**: (1) 읽음 표시 뒤 세션 전환(매 턴 훅의 prompt 사건) (2) 읽음 표시 뒤 종료 훅의 흐려짐 재설정(지문 비움) (3) 같은 턴에 원문 표시를 규약 표시보다 먼저 함.
- **Expected**: (1)(2) `GUIDE: load`, (3) 다음 턴 `GUIDE: loaded` — 읽음 기록은 규약 지문(컨텍스트에 묶인 값)에 묶이고, 규약 재표시가 같은 턴의 기록을 새 지문으로 옮긴다.
- **Pass criterion**: `OK [T4] session switch→load · drift reset→load · guide-then-protocol mark→loaded`.

### T5. 규약 문서 — 다시 쓰기 · 되묻기 단계가 빠짐없이 있다

- **Run**: `protocols/help/prompt-refine.md` 와 `full.md` · `help.md` 를 문자열로 검사.
- **Expected**: 부속 파일에 — (1) `GUIDE: load` 면 원문을 읽고 `mark-guide` (2) 짧은 확인 턴은 건너뜀 (3) 원문 규칙으로 요청 다시 쓰기 + 적용한 규칙 근거 한 줄 (4) 빈 곳을 대화·저장소에서 먼저 찾기 (5) 못 찾으면 가장 영향 큰 빈 곳 하나를 추천 답과 함께 묻고 멈춤 (6) 구현 방법은 묻지 않음 (7) 턴 기록의 `**다시 쓴 요청**:` 단락. `full.md` 는 그 파일을 가리키고, `help.md` 의 스크립트 호출에 `--model`. 규약 문서에 호스트 · 모델 이름 없음.
- **Pass criterion**: `OK [T5] 7/7 clauses` + `test-help-budget.sh` 초록(비용 상한).

### T6a. 지역 설정 · 셸 판본 (리뷰 반영)

- **Run**: 정규화 · 스위치 · 화자 이름을 bash 5 와 macOS bash 3.2 × `C` · `en_US.UTF-8` · `ko_KR.UTF-8` 에서.
- **Expected**: 여섯 조합 모두 같은 결과 — bash 3.2 의 UTF-8 에서 `[A-Z]` 가 소문자까지 맞던 문제가 없다.
- **Pass criterion**: `OK [T8] 6/6 shell×locale`.

### T6b. 색인 값 검증 (리뷰 반영)

- **Run**: 색인 파일 열에 `../secret/key.md`, `@refresh` 에 셸 명령을 이어 붙인 색인.
- **Expected**: 그 모델은 `GUIDE: none` + `GUIDE_MISSING` (폴더 밖 경로를 읽으라고 내보내지 않음), 갱신 명령은 평범한 파일 이름만 · 따옴표로 감싼 경로.
- **Pass criterion**: `OK [T9] traversal refused · refresh quoted and plain-named`.

### T6c. 벤더링이 선택 키를 옮긴다 (리뷰 반영)

- **Run**: `tests/test-profile-and-export.sh` — 프로필에 `SCV_PROMPTING_GUIDES` 를 넣고 `vendor-core.sh` 로 구체화.
- **Expected**: 구체화된 `core/host-profile.env` 에 그 키가 그대로 있다(빠지면 배포본에서 기능이 영영 꺼진다).
- **Pass criterion**: `profile, export, vendoring, and worktree source: ok`.

### T6. 멈춤 훅 모델 표기 + 계기판

- **Setup**: 대화 기록 JSONL 픽스처(답 둘, 마지막 `vendor-model-b`), 계기판 픽스처 저널(모델 표기 A 3 · B 2 · 없음 1).
- **Run**: 멈춤 훅 실행 후 저널 확인, `metrics.sh` 와 `--tsv`.
- **Expected**: 답 기록에 `vendor-model-b` 표기, 기존 저널 기록은 그대로. 계기판 기존 네 줄 그대로 + "모델별 답 수" 한 줄, 기대 파일과 바이트 일치.
- **Pass criterion**: `OK [T6] stop-hook model tag` + `test-metrics.sh` 전부 통과.

### T7. 코어 계약 검사 + 맥 · 리눅스

- **Run**: `bash tests/run.sh`(호스트 중립 포함), `check-purity.sh core/scripts/lib/model-prompting.sh`, `run-dry.sh`, 코어 테스트 전부 — macOS(bash 3.2)와 CI 리눅스.
- **Pass criterion**: 전부 exit 0, 코어 CI 초록.

### T8. 클로드 래퍼 — 원문 · 색인 · 실측 (래퍼 후속 PR 에서)

- **Setup**: `../scv-claude-code` 후속 브랜치.
- **Run**: 래퍼 계약 검사 + 확인 스크립트 + 이 기기 실측 한 번.
- **Expected**: 색인에 모델 6 + 공통 1 행, 각 원문 머리에 원본 주소 · 가져온 날짜 · "Anthropic 문서 원문", 원문 본문은 원본과 바이트 일치(가져온 날 기준),
  `claude-opus-5-5[1m]` → opus-5-5 원문 · `claude-opus-5` → opus-5 원문, 원문 7개 크기 기록. 실측: 끝 조건 없는 요청 하나를 보내 — 다시 쓴 요청이 답 앞에 보이고,
  끝 조건에 대해 추천 답과 함께 한 번 묻고, 대화 기록에 `**다시 쓴 요청**:` 과 적용 규칙 근거가 남는다.
- **Pass criterion**: 래퍼 CI 초록 + 확인 스크립트 `OK` + 실측 대화 기록 경로를 보관 기록에 적는다.

### T9. 코덱스 래퍼 — OpenAI 원문 · 색인 · 실측 (래퍼 후속 PR 에서)

- **Setup**: `../scv-codex` 후속 브랜치.
- **Run**: 코덱스 래퍼 CI + 확인 스크립트 + 이 기기 코덱스 실측 한 번.
- **Expected**: 색인에 OpenAI 가이드 행(확정 목록), 각 원문 머리에 원본 주소 · 가져온 날짜 · "OpenAI 문서 원문", 원문 본문은 원본과 바이트 일치,
  `gpt-5.6-sol` → GPT-5.6 가이드. 실측: 코덱스에서 끝 조건 없는 요청 하나 — 다시 쓴 요청이 보이고 추천 답과 함께 한 번 묻는다.
  코덱스 모델이 자기 id 를 모르면 설정의 모델 줄로 넘긴 경로가 동작한다.
- **Pass criterion**: 코덱스 래퍼 CI 초록 + 확인 스크립트 `OK` + 실측 기록 경로를 보관 기록에.

## How to run

```bash
bash core/tests/test-model-prompting.sh && bash core/tests/test-help-budget.sh && bash core/tests/test-metrics.sh
```

## Pass criteria

- T1 ~ T7 초록(코어 PR), T8 초록(클로드 래퍼 후속 PR + 실측), T9 초록(코덱스 래퍼 후속 PR + 실측).
- 기존 검사 전부 통과: `bash tests/run.sh`, `bash core/tests/run-dry.sh`, `for t in core/tests/test-*.sh; do bash "$t"; done`.

## Related Documents

- `core/contracts/purity.md`
