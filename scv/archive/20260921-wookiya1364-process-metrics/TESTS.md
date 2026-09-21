# Test Plan — 과정 계기판 — 이 프로젝트의 파일로 SCV 과정을 숫자로 본다

## Overview

스크립트 하나가 기존 파일만 읽어 지표 네 개를 결정적으로 찍는지 본다. 판정은 전부 문자열
비교다. 픽스처는 손으로 계산한 기대값과 전수 대조하고, 실제 저장소에서는 "에러 없이 표가
나오고 두 번이 같다" 만 본다(숫자는 보관할 때마다 바뀌므로 고정하지 않는다).

## Test scenarios

### T1. 픽스처 전수 대조 — 지표 네 개와 적용 범위

- **Setup**: `core/tests/fixtures/metrics/scv/` — 계획 4건: P1(대화 A 3턴, 순수 절 있음, adopted+archived 기록),
  P2(대화 B 5턴이며 경로는 원래 자리에 없고 `conversations/archive/` 에만 있음, 순수 절 없음, adopted 만),
  P3(대화 없음, 순수 절 있음, `obsoleted_by: P4`), P4(대화 없음, 순수 절 없음, `supersedes: [P3]`,
  adopted+archived). 결정 로그에 템플릿 행 `[YYYY-MM-DD HH:MM]` 1건 포함.
- **Run**: `SCV_DIR=core/tests/fixtures/metrics/scv bash core/scripts/metrics.sh`
- **Expected**: 표에 네 줄 —
  턴 수: 적용 2/4, 중앙값 4 ·
  리드타임: 적용 2/4(P1·P4), 각 값은 픽스처 시각 차 ·
  후속 재발: 1/4 (P4 만 — obsoleted_by 의 대상이자 supersedes 비어 있지 않음, 이중 계산 없이 1) ·
  순수 절 보유: 2/4.
- **Pass criterion**: 출력이 `core/tests/fixtures/metrics/expected.txt` 와 바이트 단위로 같다.
  `OK [T1] table matches` 가 찍힌다.

### T2. 반복 가능성

- **Setup**: T1 과 같은 픽스처.
- **Run**: 같은 명령을 3회 실행해 출력을 각각 저장.
- **Expected**: 세 출력이 모두 같다.
- **Pass criterion**: `OK [T2] 3/3 identical`.

### T3. 순수 함수 전수 검사 (경계값)

- **Setup**: `lib/metrics.sh` 를 source.
- **Run**: 각 순수 함수에 고정 입력 —
  `civilToMinutes`: `2026-01-01 00:00` → 기준값, `2026-03-01 00:00` (윤년 아님, 2월 28일 경과) 과의 차 = 59일×1440,
  `2024-03-01 00:00` − `2024-02-28 00:00` = 2일×1440 (윤년), 형식 오류 → 빈 값 ·
  `countTurns`: Turn 헤딩 0/1/6개 텍스트 → 0/1/6, 본문 속 `## Turn` 유사 문구(코드 블록 안)는 세지 않는다 ·
  `resolveConvPath`: `scv/conversations/x.md` → 두 줄(그대로, `scv/conversations/archive/x.md`) ·
  `parseDecisions`: 템플릿 행 제외, promote/archive refs 각각 slug 추출 ·
  `parsePlan`: `status:` 뒤 주석 있는 프런트매터, `supersedes: []` 와 `supersedes: [a]`, 순수 절 있음/없음.
- **Expected**: 각 케이스 기대값과 일치. 케이스 수는 스크립트가 찍는다.
- **Pass criterion**: `OK [T3] <n>/<n>` (n = 전체 케이스 수, 실패 0).

### T4. 실제 저장소에서 돈다

- **Setup**: 이 저장소 루트.
- **Run**: `bash core/scripts/metrics.sh` 2회.
- **Expected**: exit 0, 표에 네 지표 이름과 `n/m` 꼴 적용 범위가 각각 있다, 두 출력이 같다.
  `--tsv` 출력에 `unmatched` 행이 있으면 stderr 가 아니라 표 데이터에 남는다.
- **Pass criterion**: `OK [T4] real repo: exit 0, 4 metrics, identical`.

### T5. 읽기 전용

- **Setup**: T4 실행 전후 `git status --porcelain` 과 픽스처 디렉터리의 파일 목록·해시.
- **Run**: T1·T4 를 돌린다.
- **Expected**: 작업 트리 변화 없음, 픽스처 해시 동일.
- **Pass criterion**: `OK [T5] no writes`.

### T6. 순수성 계약

- **Run**: `bash core/scripts/check-purity.sh core/scripts/lib/metrics.sh`
- **Expected**: `OK  purity` 줄. 표식 아래 함수 누락 0.
- **Pass criterion**: exit 0.

### T7. 맥·리눅스 동일

- **Run**: T1~T6 을 macOS(bash 3.2)와 Linux(bash 5)에서 각각. CI 의 core-ci 워크플로가 리눅스를 맡는다.
- **Expected**: 두 환경에서 같은 결과.
- **Pass criterion**: 로컬 실행 + CI 초록.

## How to run

```bash
bash core/tests/test-metrics.sh
```

## Pass criteria

- T1~T6 이 로컬(macOS)에서 초록이고, T7 은 CI 초록으로 확인.
- 기존 검사 전부 통과: `bash tests/run.sh`, `bash core/tests/run-dry.sh`, `for t in core/tests/test-*.sh; do bash "$t"; done`.

## Related Documents

- `core/contracts/purity.md`
