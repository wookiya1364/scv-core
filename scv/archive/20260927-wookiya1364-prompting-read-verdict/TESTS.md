# Test Plan — 모델별 프롬프팅 — 원문을 읽었는지 · 다시 쓴 요청을 보였는지 결과로 판정한다

## Overview

판정은 순수 함수가 하고, 멈춤 훅은 읽고 쓰기만 한다. 순수부는 전수 검사, 흐름은 임시 저장소에서 help → (표시 있음/없음) →
멈춤 훅 → 다음 턴 경고로 본다. 설치본 한 턴 실측은 릴리스 뒤.

## Test scenarios

### T1. 순수부 전수 검사

- **Run**: 턴 기록 파싱(정상 · 깨짐), 읽음 판정(같은 지문 · 옮긴 지문 · 비워진 지금 지문 · 다른 모델 · 빈 기록), 다시 쓴 요청 감지
  (영문 · 한국어 라벨 · 없음), 인용 감지(일반 인용 · 코드 블록 안 `>` · 없음), 판정 행렬(결정 none/load/loaded × 읽음 × 기록 × 인용),
  경고 문장(키 포함).
- **Pass criterion**: `OK [T1] <n>/<n>`.

### T2. 안 읽음 → 다음 턴 경고 → 다시 load

- **Run**: 임시 저장소 · 픽스처 가이드. help `--model A` (load) → 표시 없이 멈춤 훅 → 매 턴 훅 출력 → help `--model A`.
- **Expected**: 매 턴 훅 출력에 "원문 안 읽음" 경고(키 포함), 다음 help 는 `GUIDE: load`, `.help-guide-turn` 은 판정 뒤 지워짐.
- **Pass criterion**: `OK [T2] unread→warn→load`.

### T3. 읽고 표시함 → 경고 없음 · 같은 턴 규약 재표시도 경고 없음

- **Run**: (a) help load → `GUIDE_MARK_CMD` 줄의 명령 실행 → 멈춤 훅 (b) help load → 원문 표시 → `help-state.sh mark` → 멈춤 훅
  (c) 멈춤 훅의 드리프트 재설정으로 지문이 비워진 경우.
- **Expected**: 세 경우 모두 경고 없음.
- **Pass criterion**: `OK [T3] 3/3 no false warning`.

### T4. 다시 쓴 요청 기록 있음 · 답에 인용 없음 → 경고

- **Run**: help load → 표시 → 대화 파일에 `**다시 쓴 요청**:` 단락을 가진 Turn 블록 → 인용 없는 답으로 멈춤 훅. 대조: 인용 있는 답 · 단락 없는 기록.
- **Expected**: 첫 경우만 "다시 쓴 요청 안 보임" 경고.
- **Pass criterion**: `OK [T4] unshown only when recorded and not quoted`.

### T5. 조용해야 할 때

- **Run**: 결정 none(모르는 모델) · 스위치 off · 턴 기록 없음 · 훅 입력 깨짐.
- **Expected**: 경고 없음, 모두 exit 0, 기존 경고 파일 내용은 보존(덧붙임만).
- **Pass criterion**: `OK [T5] silent`.

### T6. 계약 · 비용 · 순수성

- **Run**: `test-help-budget` · `test-help-router-diet` · `check-purity` · 호스트 중립 · 코어 테스트 전부, 그리고 코덱스 벤더 사본(격리 폴더)에서 코어 테스트 전부.
- **Pass criterion**: 전부 초록, help 규약 합계 원본 · 코덱스 사본 모두 상한에서 100B 이상 여유.

## How to run

```bash
bash core/tests/test-model-prompting.sh && bash core/tests/test-help-budget.sh
```

## Pass criteria

- T1 ~ T6 초록. 설치본 실측(릴리스 뒤)에서 안 읽은 턴 다음에 경고가 보인다.

## Related Documents

- `core/contracts/purity.md`
