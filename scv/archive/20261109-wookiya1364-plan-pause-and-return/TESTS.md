# Test Plan — 계획 밖 요구 — 기존 계획에 넣거나, 보류 후 돌아오기

## Overview

임시 저장소에 계획 두세 개를 만들어 놓고 `plan-link.sh` 의 넣기 · 보류 · 연결 · 복귀를 실행해, 계획 파일만 읽어도 멈춤 · 이유 · 복귀가 보이는지와 충돌이 걸러지는지 확인한다. 대화에서 정한 요구 하나하나가 시나리오 하나다.

## Test scenarios

### T1. 같은 목표의 요구 — 기존 계획에 넣기

- **Setup**: A 계획(in_progress), 단계 1 `[x]` · 2 · 3
- **Run**: `plan-link.sh append A --after 2 --step "새 단계" --why "같은 목표"`
- **Expected**: 단계 2 뒤에 새 단계가 3번으로 들어가고 기존 3은 4로 밀림. `## 변경 이력` 에 "추가" 줄 하나. 단계 1의 글은 바이트 그대로
- **Pass criterion**: 단계 수 3 → 4, 이력 줄 +1, 단계 1 diff 없음

### T2. 다른 목표의 요구 — A 보류 + B 연결

- **Setup**: A(in_progress, 3단계 중 1 끝남), B(planned)
- **Run**: `plan-link.sh pause A --by B --resume-at 2 --why "<한 줄>"`
- **Expected**: A `status: paused` · `paused_by: B` · `resume_at: 2` · 이력 "보류" 줄. B `return_to: A` · 이력 줄
- **Pass criterion**: 두 파일의 frontmatter 값 일치, 종료 코드 0

### T3. 앞쪽 충돌 검사

- **Setup**: A Non-Goals 에 "결제 한도 변경 안 함", B Goals 에 "결제 한도 변경"
- **Run**: `plan-link.sh check-before A B`
- **Expected**: 충돌 1건을 출력하고 종료 코드가 0이 아님. A · B 파일은 바뀌지 않음
- **Pass criterion**: 충돌 줄 1개, 종료 코드 ≠ 0, 두 파일 diff 없음

### T4. 새 계획이 끝나면 바로 A로 복귀

- **Setup**: T2 끝난 상태에서 B 를 보관(archive)
- **Run**: `plan-link.sh resume B`
- **Expected**: A `status: in_progress`, `paused_by` · `resume_at` 없어짐, 이력 "재개 · B 끝남 · 2단계부터" 줄
- **Pass criterion**: A frontmatter 에 paused 관련 키 0개, 이력 줄 +1

### T5. 뒤쪽 충돌 검사

- **Setup**: A 의 남은 단계 2 가 `core/scripts/x.sh` 를 다룸, B 가 같은 파일을 바꿈
- **Run**: `plan-link.sh check-after B --changed core/scripts/x.sh`
- **Expected**: 겹침 1건(단계 2 · 파일 이름) 출력, A 는 바뀌지 않음
- **Pass criterion**: 겹침 줄 1개, A diff 없음

### T6. 여러 겹 — C → B → A 역순 복귀

- **Setup**: A 보류(by B), B 보류(by C)
- **Run**: `resume C` 후 `resume B`
- **Expected**: 첫 번째에서 B 만 재개되고 A 는 보류 그대로, 두 번째에서 A 재개
- **Pass criterion**: 각 단계 뒤 상태 값이 차례대로 맞음

### T7. 끝난 단계 요건이 바뀌면 "다시 하기" 단계

- **Setup**: A 단계 1 `[x]`
- **Run**: `plan-link.sh append A --redo 1 --why "<한 줄>"`
- **Expected**: 단계 1 글은 그대로, 끝에 "다시 하기: <단계 1 이름>" 단계 추가, 이력 "다시 하기" 줄
- **Pass criterion**: 단계 1 diff 없음, 단계 +1

### T8. frontmatter 검사가 paused 를 받아들임

- **Setup**: `status: paused` 인 계획
- **Run**: `check-frontmatter.sh`
- **Expected**: invalid status 오류 없음. `status: pausd` 같은 오타는 여전히 오류
- **Pass criterion**: 앞은 종료 코드 0, 뒤는 ≠ 0

### T9. 맥 · 리눅스 같은 결과

- **Setup**: T1 ~ T8 을 맥(BSD 도구)과 리눅스 컨테이너(GNU 도구)에서
- **Run**: 같은 시험 파일
- **Expected**: 두 곳 모두 통과
- **Pass criterion**: 두 곳 종료 코드 0

### T10. 패널 표시 (scv-mods)

- **Setup**: 패널 시험에 paused 계획 A(paused_by B) 와 B(return_to A)
- **Run**: scv-dashboard 시험 실행
- **Expected**: A 상태 글 "보류 · <B 제목> 끝나면 재개", B 에 "끝나면 <A 제목>으로 돌아감", 정렬은 in_progress 바로 뒤
- **Pass criterion**: 패널 시험 통과, 기존 상태 표시 시험 변화 없음

## How to run

```bash
bash core/tests/test-plan-link.sh
```

## Pass criteria

- T1 ~ T9 이 맥과 리눅스에서 통과 (core)
- T10 이 scv-mods 패널 시험에서 통과 (별도 PR)

## Related Documents
