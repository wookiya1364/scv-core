# Test Plan — README 최신화 — 코어와 두 래퍼의 첫 화면 안내를 지금 기능에 맞추고, 낡았다고 표시된 옛 자료 21건을 검토한다

## Overview

세 저장소 README 12개가 지금 기능과 맞는지(적힌 명령 · 설정의 실재, 필수 주제, 세 언어판 일치, 업데이트 방법, 버전 번호 없음)를
검사 스크립트와 기존 계약 검사로 확인하고, 검사가 틀린 README 를 실제로 잡는지 붉은 검사로 확인한다. 옛 자료 21건은 검토표로
판정을 확인하고, 검토를 마친 자료만 다시 사용 표시된 뒤 경고에서 빠지며 본문은 그대로인지 확인한다. 마지막으로 릴리스 없이
세 저장소 main 에 반영됐는지 본다.

## Test scenarios

### T1. 범위 — 정해진 파일만 바뀐다

- **Setup**: 각 저장소의 작업 시작 커밋을 기준으로 둔다.
- **Run**: 저장소마다 `git diff --name-only <기준>..HEAD`.
- **Expected**: 코어 — `README.md` · `README.ko.md` · `README.ja.md`, `tools/check-readme.sh`, `tests/test-check-readme.sh`,
  (필요하면) 코어 CI 설정 한 곳, `scv/promote/<slug>/`, `scv/readpath.json`, `scv/conversations/` · `scv/journal/` ·
  `scv/DECISIONS.md` · `scv/INDEX.tsv`. 클로드 — README 3개. 코덱스 — README 3개와 `plugins/scv/README*.md` 3개.
- **Pass criterion**: 목록 밖의 파일이 없다.

### T2. 적힌 명령 · 설정이 모두 실제로 있다

- **Run**: `bash tools/check-readme.sh --profile core .`, `bash tools/check-readme.sh --profile claude ../scv-claude-code`,
  `bash tools/check-readme.sh --profile codex ../scv-codex`.
- **Expected**: 세 언어판에 적힌 명령은 모두 그 저장소의 스킬로, 설정 키는 모두 설정 예시 파일에 있다.
- **Pass criterion**: 세 저장소 모두 exit 0.

### T3. 필수 주제가 빠짐없이 소개된다

- **Run**: T2 와 같은 검사(주제 판정).
- **Expected**: PLAN.md 의 "저장소별 필수 주제" 표에서 ● 인 칸의 표식이 그 저장소 세 언어판 모두에 있다.
- **Pass criterion**: 빠진 주제 0.

### T4. 세 언어판이 같은 구조다

- **Run**: T2 와 같은 검사(언어판 비교).
- **Expected**: 영 · 한 · 일 판의 절 제목 수 · 명령 목록 · 설정 목록이 같다(코덱스 플러그인 README 세 판도 서로 같다).
- **Pass criterion**: 차이 0.

### T5. 두 래퍼 README 에 업데이트 방법이 있다

- **Run**: 래퍼 README 세 언어판(코덱스는 플러그인 README 포함)에서 명령 문자열 검색.
- **Expected**: 클로드 — `/plugin marketplace update scv-claude-code` 와 `/reload-plugins`.
  코덱스 — `codex plugin marketplace upgrade scv-codex` 와 `codex plugin add scv@scv-codex`.
- **Pass criterion**: 모든 언어판에 둘 다 있다.

### T6. 래퍼 README 에 버전 번호 · 다른 호스트 문법이 없다

- **Run**: `check-readme.sh`(버전 표기 판정), 클로드 저장소의 `bash tests/test-core-contract.sh`.
- **Expected**: 래퍼 README 에 릴리스 버전 번호(0.x.y 꼴)가 없다. 클로드 README 에 `$scv:` · `.codex-plugin` 등이 없다.
- **Pass criterion**: 두 검사 모두 통과.

### T7. 검사가 틀린 README 를 잡는다 (붉은 검사)

- **Setup**: README 를 임시 사본에 복사한다(원본은 건드리지 않는다).
- **Run**: `bash tests/test-check-readme.sh`.
- **Expected**: 사본에 (a) 없는 명령을 넣으면 (b) 없는 설정 키를 넣으면 (c) 한 언어판에서 절 하나를 지우면
  (d) 필수 주제 표식 하나를 지우면 (e) 래퍼 README 에 버전 번호를 넣으면 — 각각 검사가 실패한다. 손대지 않은 사본은 통과한다.
- **Pass criterion**: 다섯 경우 모두 exit ≠ 0, 원본 사본은 exit 0.

### T8. 맥 · 리눅스에서 같게 동작한다

- **Run**: 검사 스크립트와 붉은 검사를 맥의 `/bin/bash`(3.2)와 최신 bash, 리눅스 CI 에서 돌린다.
- **Expected**: 세 환경의 판정이 같다.
- **Pass criterion**: 결과 일치.

### T9. 기존 검사가 모두 통과한다

- **Run**: 코어 — 저장소 검사 전체(`tests/` 와 `core/tests/`, 호스트 중립 · 내보내기 검증 포함). 클로드 — `tests/test-core-contract.sh`.
  코덱스 — `python3 tools/validate-core-tree.py --root plugins/scv/vendor/scv-core`, `bash plugins/scv/prompting/check.sh`.
- **Expected**: 모두 초록.
- **Pass criterion**: 실패 0.

### T10. 옛 자료 21건 모두 판정과 근거가 있다

- **Run**: 계획 폴더의 `STALE_REVIEW.md` 를 확인한다.
- **Expected**: PLAN.md 부록 A 의 21건마다 한 행 — 가리키는 바뀐 파일, 판정(유효 · 일부 낡음 · 대체됨), 근거(지금 코드의
  파일:줄, 또는 대체한 보관 계획 slug).
- **Pass criterion**: 21행, 빈 판정 · 빈 근거가 없다.

### T11. 검토를 마친 자료는 경고에서 빠지고, 본문은 그대로다

- **Setup**: 검토 전에 21개 자료 본문의 해시를 기록한다.
- **Run**: `readpath.sh consume <slug> <검토를 마친 자료들>` 뒤 `readpath.sh outdated`.
- **Expected**: 검토를 마친 자료는 OUTDATED-CANDIDATE 목록에서 빠지고, `scv/readpath.json` 의 그 자료 ref_docs 에 이 계획
  slug 가 덧붙는다. 자료 본문 해시는 변하지 않는다. 검토하지 않은 자료는 표시되지 않는다.
- **Pass criterion**: 세 조건 모두 충족.

### T12. 릴리스 없이 세 저장소 main 에 반영된다

- **Run**: 병합 뒤 저장소마다 `gh workflow run promote.yml -f release=false` → 끝나면 main 의 README 를 조회한다
  (`gh api repos/wookiya1364/<repo>/contents/README.md?ref=main`).
- **Expected**: 세 저장소 main 의 README 에 새 필수 주제 표식이 보이고, 새 릴리스(태그)는 생기지 않는다.
- **Pass criterion**: 세 저장소 모두 충족.

## How to run

```bash
bash tools/check-readme.sh --profile core . && bash tests/test-check-readme.sh
```

(두 래퍼 검사는 T2 의 명령을 형제 저장소 경로로 돌린다. 되풀이 검사에서 형제 저장소가 없을 수 있어 위 한 줄에는 넣지 않는다.)

## Pass criteria

- T1 ~ T12 모두 통과.
- 두 래퍼 CI 연결(PLAN.md Suggested path 7)은 다음 코어 배포 뒤의 후속이며 이 계획의 통과 조건이 아니다.

## Related Documents

- `./PLAN.md` — 필수 주제 표, 부록 A(검토 대상 21건)
- `./STALE_REVIEW.md` — 작업 때 생성
