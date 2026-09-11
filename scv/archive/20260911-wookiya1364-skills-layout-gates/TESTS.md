# Test Plan — 명령을 skills 로 — 플러그인 구조·설명 길이를 CI 가 지킨다

## Overview

이전과 **같은 이름으로 같은 본문**이 뜨는지(구조만 바뀌었는지), 경로가 박혀 있던 스크립트와
검사가 전부 따라왔는지, 새 가드 둘(구조 검사 · 설명 길이)이 실제로 잡는지 본다. 래퍼 파일을
보는 케이스는 옆 체크아웃이 있을 때만 — 없으면 SKIP.

## Test scenarios

### T1. 열다섯 스킬이 새 자리에, 예전 폴더는 없다

- **Setup**: `../scv-claude-code` 체크아웃.
- **Run**: `core/actions.json` 의 action id 열다섯 개를 순회.
- **Expected**: 각 `skills/<id>/SKILL.md` 가 있고, `commands/` 디렉터리가 없다.
- **Pass criterion**: 15/15 존재, `[[ ! -e commands ]]`.

### T2. frontmatter — name 이 디렉터리명, model 줄 없음

- **Run**: 각 SKILL.md 의 frontmatter 파싱.
- **Expected**: `name: <id>` 가 있고 디렉터리명과 같다. `description` 비어 있지 않다. `model:` 줄이 없다. `context:` 줄이 없다.
- **Pass criterion**: 15/15.

### T3. 투영 — 본문이 코어 protocol 과 같다

- **Run**: 래퍼에서 `bash scripts/project-core.sh --check` (또는 계약 검사가 부르는 동일 경로).
- **Expected**: `PROJECTION_MISMATCH` 0건. adapter 소유 둘(update · set-models)은 제외.
- **Pass criterion**: exit 0.

### T4. 갱신 스크립트의 소유 규칙이 새 경로를 안다

- **Run**: `sync-core.sh` 의 scopes 에 `skills` 가 있고 `commands` 가 없다; adapter_owned 에 `skills/set-models/SKILL.md` · `skills/update/SKILL.md`; frontmatter-only 규칙이 `skills/` + `SKILL.md` 를 본다. 기존 `tests/test-sync-core-atomicity.sh` 통과.
- **Pass criterion**: grep 3건 + 검사 exit 0.

### T5. 모델 정책 적용이 skills 를 돈다

- **Run**: 임시 복제에 `apply-model-policy.sh --policy recommended` → `skills/help/SKILL.md` 에 `model:` 생김, `skills/status/SKILL.md` 와 값이 다름; `--policy session-default` → 전부 사라짐; 두 번 적용 시 체크섬 동일.
- **Pass criterion**: `core/tests/test-model-policy-default.sh` 가 새 경로로 통과.

### T6. 설명 길이 검사 — 통과와 실패 둘 다

- **Setup**: (a) 실제 래퍼 skills; (b) 임시 복제에서 한 스킬의 description 을 1,600자로; (c) 임시 복제에서 합계가 8,100자가 되도록.
- **Run**: `bash core/tests/test-skill-descriptions.sh` (경로 인자 또는 환경변수로 대상 지정).
- **Expected**: (a) FAIL 0; (b) 개별 상한 위반 1건 FAIL; (c) 합계 상한 위반 FAIL.
- **Pass criterion**: 세 결과가 기대와 같다.

### T7. 플러그인 구조 검사 — 로컬과 CI

- **Run**: 래퍼 루트에서 `claude plugin validate . --strict`; `.github/workflows/core-contract.yml` 에 같은 명령을 부르는 단계가 Linux 잡에 있다.
- **Expected**: 로컬 `✔ Validation passed`; 워크플로에 단계 존재; 첫 PR 의 Contract (ubuntu) 잡에서 그 단계가 통과.
- **Pass criterion**: 로컬 exit 0 + grep + 런 로그.

### T8. 워크플로 paths 가 새 폴더를 본다

- **Run**: `core-contract.yml` · `core-sync.yml` · `test-model-policy.yml` 에 `skills/**` 가 있고 `commands/**` 가 없다.
- **Pass criterion**: grep.

### T9. 호출 이름 불변

- **Run**: 스킬 디렉터리명 집합 == 고정 목록 {codegen, deck, handoff, help, install-deps, promote, regression, report, routine, set-models, status, sync, update, work, workspace}.
- **Pass criterion**: 집합 동일.

### T10. Codex 래퍼 무변경

- **Run**: `../scv-codex` 에 대해 `git status --porcelain` 이 비어 있고 이 계획의 커밋이 그 저장소를 건드리지 않는다.
- **Pass criterion**: 빈 출력.

### T11. 기존 회귀 전부

- **Run**: `for t in core/tests/test-*.sh; do bash "$t"; done` 와 래퍼 `tests/test-core-contract.sh` · `tests/run-dry.sh` · `tests/test-apply-model-policy.sh`.
- **Expected**: 전부 FAIL 0.
- **Pass criterion**: 종료 코드 전부 0.

### T12. 실기기 — 갱신 뒤 호출과 비용 (수동)

- **Setup**: 래퍼 릴리스 후 `/plugin marketplace update` + `/reload-plugins`.
- **Run**: `/scv:help` 호출; `/skill-doctor` 실행.
- **Expected**: help 가 이전과 같이 뜬다. skill-doctor 가 scv 스킬 열다섯을 비용과 함께 보여 주며 중복 항목이 없다.
- **Pass criterion**: 수치 기록 → CHANGELOG.

## How to run

```bash
bash core/tests/test-skill-descriptions.sh && bash core/tests/test-model-policy-default.sh
```

## Pass criteria

- T1–T11 자동 케이스 FAIL 0 (래퍼 케이스는 체크아웃 없으면 SKIP).
- 래퍼 PR Contract 잡 녹색(validate 단계 포함).
- T12 수동 확인 + 실측 수치 기록.

## Related Documents

- `docs/wrapper-integration.md` §3
