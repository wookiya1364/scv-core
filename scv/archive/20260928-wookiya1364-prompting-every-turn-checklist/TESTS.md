# Test Plan — 모델별 프롬프팅 — 매 턴 1:1 비교 · 등록, 빠지면 같은 턴에 막는다

## Overview

순수부는 전수 검사, 흐름은 임시 저장소에서 매 턴 훅 → (등록 있음/없음) → 가드 쓰기 → 종료 훅 순으로 본다. 래퍼 데이터는 인용 검사.

## Test scenarios

### T1. 순수부
- **Run**: 목록 병합(공통 + 모델, 같은 id 는 모델 우선) · 등록 검증(완전 · 빠짐 · 잘못된 상태 · 빈 값 · rewrite 없음) · 매 턴 블록(모델 앎 · 모름 · 스위치 off) · 종료 판정(등록 × 인용 × 계속 중) · 인용 확인.
- **Pass criterion**: `OK [T20]` 전수.

### T2. 등록 흐름
- **Run**: 매 턴 훅(토큰) → `checklist` → 불완전 등록(거절 + 빠진 항목) → 완전 등록(REGISTERED) → 다음 턴 훅(새 토큰, 이전 등록 무효).
- **Pass criterion**: `OK [T21]`.

### T3. 보장 두 겹
- **Run**: 등록 전 가드 쓰기 → 거절(사유에 등록 명령), 등록 뒤 → 허용. 종료 훅: 등록 없음 → 차단 JSON, 계속 중(stop_hook_active) → 차단 없음 + 다음 턴 경고, 등록 + 인용 → 통과.
- **Pass criterion**: `OK [T22]`.

### T4. 벤더 배치에서 가이드 폴더 찾기
- **Run**: 가이드 폴더가 코어 루트 세 단계 위에 있는 배치(클로드 래퍼 모양)에서 `checklist` 가 목록을 낸다.
- **Pass criterion**: `OK [T23]`.

### T5. 기존 검사 · 비용
- **Run**: 코어 테스트 전부, 코덱스 벤더 사본(격리) 전부, 래퍼 인용 검사.
- **Pass criterion**: 초록(사본의 기존 test-guidance 한 건 제외), 새 매 턴 상한 안.

## How to run

```bash
bash core/tests/test-model-prompting.sh && bash core/tests/test-help-budget.sh
```

## Pass criteria

- T1 ~ T5 초록. 설치본 연속 턴 실측에서 모든 턴 등록 · 인용.

## Related Documents

- `core/contracts/purity.md`
- `core/contracts/guard.md`
