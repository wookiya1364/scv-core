# Test Plan — 글쓰기 8가지 — 읽는 사람이 덜 헤매게, 선택 창은 그대로

## Overview

사용자가 고른 8가지가 규칙 · 검사로 들어갔는지, 그리고 선택 창 수가 늘지 않았는지를 본다. 숫자로 잴 수 있는 것은 깨진 사본으로
빨간색을 확인하고, 글 규칙은 문서가 한 곳에 있고 규약들이 그곳을 가리키는지로 확인한다.

## Test scenarios

### T1. ① 값 없는 통과 기준을 경고한다

- **Setup**: 통과 기준이 "잘 동작한다"뿐인 시험서와, "`OK readme` 출력, 종료 코드 0"인 시험서.
- **Run**: 판정 함수와 work 머리말.
- **Expected**: 앞 것만 `TESTS_VAGUE:` 1줄, 뒤 것은 0줄. 종료 코드는 둘 다 0(막지 않음).
- **Pass criterion**: 경고 줄 수 1 · 0, 종료 코드 0 · 0.

### T2. ④ 줄글 표 칸과 긴 문단을 막는다

- **Setup**: README 사본에 (a) 41자 넘는 표 칸, (b) 7줄 문단을 넣는다.
- **Run**: `bash tests/test-check-readme.sh`
- **Expected**: 두 사본 모두 빨강, 원본은 초록.
- **Pass criterion**: 시험 출력 `baseline green`, 깨진 사본 수가 이전 8 → 10.

### T3. 세 저장소 지금 README 가 통과한다

- **Setup**: 코어 · claude · codex 를 같은 부모 폴더에.
- **Run**: `check-readme.sh --profile core|claude|codex`
- **Expected**: 세 프로필 모두 `OK readme`.
- **Pass criterion**: 종료 코드 0 · 0 · 0.

### T4. ⑦ promote 가 파일을 쓰기 전에 개요를 확인받는다 — 묻는 지점 수 그대로

- **Setup**: 바꾸기 전 promote · work 의 묻는 지점 수(11 · 10, `Question:` · `Ask …` 줄).
- **Run**: 같은 방법으로 다시 센다. promote 에 개요 확인 절이 Step 5 앞에 있고, Step 5 승인이 그 확인을 가리키는지 본다.
- **Expected**: 11 · 10 그대로, 개요 확인 절 1개.
- **Pass criterion**: 수 11 · 10, 절 1.

### T5. ② 실물 확인은 볼 곳을 짚어 묻는다

- **Setup**: `contracts/show-real.md`.
- **Run**: 확인 질문 절을 본다.
- **Expected**: 묻는 말이 결과에서 볼 곳을 짚도록 적혀 있고(예시 하나), 보기(계속 · 고칠 점)와 '한 번' 규칙은 그대로.
- **Pass criterion**: `test-show-real.sh` 통과 + 절에 예시 문장 1개.

### T6. ③⑤⑥⑧ 글 모양 규칙이 한 곳에 있고 규약이 가리킨다

- **Setup**: 새 글 규칙 문서.
- **Run**: 규칙 문서에 네 항목이 있는지, help · promote · work 가 그 문서를 가리키는지, 같은 문장이 둘 이상 문서에 있지 않은지(중복 래칫).
- **Expected**: 네 항목, 가리킴 3곳, 중복 0.
- **Pass criterion**: `test-rule-constitution.sh` 통과, 가리킴 3.

### T7. 크기 예산 · 다이제스트 · 코어 시험

- **Run**: `bash tests/run.sh` · `bash core/tests/run-dry.sh`
- **Pass criterion**: 둘 다 실패 0.

## How to run

```bash
bash tests/run.sh && bash core/tests/run-dry.sh >/dev/null && for t in core/tests/test-writing-guidance.sh core/tests/test-show-real.sh core/tests/test-rule-constitution.sh; do bash "$t" || exit 1; done
```

## Pass criteria

- T1–T7 자동 통과(위 명령 종료 코드 0). T3 의 래퍼 README 는 래퍼 저장소에서 같은 검사로 확인.

## Related Documents

- `core/contracts/writing.md` (새 문서)
