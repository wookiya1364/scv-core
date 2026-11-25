# Test Plan — 원칙 글도 맥락에 한 번만

## Overview

매 턴 훅이 싣는 원칙 글이 "이 맥락에 한 번"으로 판정되는지 본다. 고치기 전에는 규약 지문이 바뀔 때마다 전문이 다시 실렸다(실제 세션의 한 줄 턴 108개 중 105개).

## Test scenarios

### T1. 지문이 바뀐 둘째 턴도 한 줄

- **Setup**: 새 시험 프로젝트, 세션 s1.
- **Run**: 훅을 한 번 돌리고, 규약 지문을 다른 값으로 바꾼 뒤 훅을 다시 돌린다.
- **Expected**: 첫 턴은 `PRINCIPLE:` 과 원칙 전문, 둘째 턴은 `PRINCIPLE: (` 로 시작하는 한 줄.
- **Pass criterion**: 둘째 턴 출력에 원칙 전문의 첫 줄이 없고, 첫 턴보다 1,500 B 이상 작다. 고치기 전에는 실패한다.

### T2. 대화 초기화 뒤 첫 턴은 전문, 그다음은 한 줄

- **Setup**: T1 의 상태.
- **Run**: `help-state.sh reset --turn-dir <세션 턴 폴더>` 뒤 훅을 두 번 돌린다.
- **Expected**: 첫 번째는 전문, 두 번째는 한 줄.
- **Pass criterion**: 초기화 뒤 `.principle-seen` 이 없고, 두 출력이 전문 · 한 줄 순서다.

### T3. 원칙 경고가 남은 턴만 전문

- **Setup**: 원칙을 이미 실은 세션.
- **Run**: (a) 세션 경고 파일에 `[SCV 원칙]` 줄을 두고 훅을 돌린다. (b) 확인 범위 경고만 두고 훅을 돌린다.
- **Expected**: (a) 전문, (b) 한 줄.
- **Pass criterion**: (a) 에 원칙 전문의 첫 줄이 있고 (b) 에는 없다.

### T4. 끈 설정에서는 이전과 같다

- **Setup**: `SCV_RULES_ONCE=off` 인 프로젝트.
- **Run**: 훅 → 훅 → 지문 바꾸고 훅.
- **Expected**: 전문 → 한 줄 → 전문(지문 비교 그대로).
- **Pass criterion**: 세 출력의 원칙 부분이 그 순서다.

### T5. 원칙을 끈 설정에서는 싣지 않는다

- **Setup**: `SCV_REWRITE_PRINCIPLE=off`.
- **Run**: 훅 한 번.
- **Expected**: `PRINCIPLE` 줄이 없다.
- **Pass criterion**: 출력에 `^PRINCIPLE` 이 0줄.

### T6. 세션마다 따로

- **Setup**: s1 이 이미 원칙을 실은 프로젝트.
- **Run**: 처음 온 세션 s2 로 훅을 돌린다.
- **Expected**: s2 의 첫 턴은 전문.
- **Pass criterion**: s2 출력에 원칙 전문의 첫 줄이 있다.

### T7. 원칙 경고 가르기(순수 판정)

- **Setup**: 없음.
- **Run**: `scv_mp_warn_has_principle` 에 세 글을 준다 — 원칙 줄이 있는 글, 확인 범위 줄만 있는 글, 빈 글.
- **Expected**: 1 · 0 · 0.
- **Pass criterion**: 세 값이 그대로다.

## How to run

```bash
bash core/tests/test-principle-once.sh
```

## Pass criteria

- T1–T7 통과(맥 기본 셸 · 새 셸 · 리눅스). 관련 시험(test-instruction-diet · test-model-prompting · test-rewrite-guide-only · test-rules-once · test-session-resume) 통과, 푸시 전 전체 실행 통과.

## Related Documents
