# Test Plan — 글 대신 검사

## Overview

다섯 가지가 실제로 도는지 확인한다: 매 턴 글이 줄었는데 규칙은 검사가 계속 막는지, 정정 턴에만 제안이 뜨는지, 새 임시방편 주석만 알리는지, 대시보드가 증거 없는 '끝'을 거절하고 노드 상세에 증거 · 실제 진행을 보이는지, 사전과 같은 일을 하는 순수 함수가 언어마다 실제로 돌려져 막히는지. 코어 부분은 새 시험 파일 `core/tests/test-checks-not-comments.sh`, 대시보드 부분은 모드 시험으로 잰다.

## Test scenarios

### T1. 매 턴 글이 줄어듦

- **Setup**: 계획 시작 전 매 턴 글 크기를 `test-instruction-diet.sh` 방식으로 재어 기준값으로 적음.
- **Run**: 1단계 뒤 같은 방식으로 다시 잼.
- **Expected**: 새 값 < 기준값, 새 값 ≤ 10,800 B, codex 사본도 상한 안.
- **Pass criterion**: 크기 비교 두 개가 모두 참이고 `test-instruction-diet.sh` · `test-help-budget.sh` 종료 코드 0.

### T2. 덜어 낸 줄의 규칙을 검사가 여전히 막음

- **Setup**: 덜어 낸 줄마다 그 규칙을 어기는 사례 하나씩(예: 영어 최종 답, 불릿 없는 긴 문단, 등록 없는 쓰기).
- **Run**: 각 사례를 해당 검사에 넣음.
- **Expected**: 사례마다 검사가 거절하고, 거절 문구에 고칠 방법이 적혀 있음.
- **Pass criterion**: 덜어 낸 줄 수 = 거절된 사례 수, 거절 문구가 빈 사례 0.

### T3. 대조 표에 검사가 없는 줄은 남음

- **Setup**: 검사가 없는 규칙 줄이 든 매 턴 글.
- **Run**: `matchRuleToCheck` → `dropCoveredLines`.
- **Expected**: 그 줄은 덜어 낼 목록에 없음.
- **Pass criterion**: 덜어 낼 목록에 검사 없는 줄 0개.

### T4. 정정 턴 뒤에 제안 안내가 뜸

- **Setup**: 같은 세션의 둘째 사람 턴이 "아니, 그게 아니라 … 로 고쳐" 같은 정정.
- **Run**: 매 턴 훅을 그 턴으로 돌림.
- **Expected**: 출력에 "검사로 남기기"를 선택 창으로 물으라는 안내 한 줄.
- **Pass criterion**: 안내 줄 1개.

### T5. 정정이 아닌 턴 · 세션 첫 턴엔 안내가 없음

- **Setup**: (a) 새 기능 요청 턴 (b) 세션 첫 턴인 정정 문장.
- **Run**: 매 턴 훅을 각각 돌림.
- **Expected**: 두 경우 모두 안내 없음.
- **Pass criterion**: 안내 줄 0개 · 0개.

### T6. 고르기 전엔 파일이 생기지 않음

- **Setup**: T4 상태.
- **Run**: 훅을 돌린 뒤 저장소 파일 목록 비교.
- **Expected**: 새 파일 · 바뀐 파일 없음 (기록 파일 제외).
- **Pass criterion**: `git status --short` 전후 같음 (scv/journal · scv/conversations 제외).

### T7. 새 임시방편 주석만 알림

- **Setup**: 임시 저장소에 원래 주석 `// TODO: old` 가 있는 파일, 그 위에 변경으로 `// TODO: 나중에 제거` · `# workaround — 큰 변경이라 미룸` · `// 일반 설명` 을 추가.
- **Run**: 계획 끝 검사의 주석 알림.
- **Expected**: 새로 넣은 두 줄만 파일:줄로 알림, 원래 TODO 와 일반 설명은 없음.
- **Pass criterion**: 알림 2줄, 줄 번호가 실제 추가 줄과 같음.

### T8. 순수 함수 표식 주석은 알리지 않음

- **Setup**: 변경으로 `# @pure foo` 와 그 밑 설명 주석 블록 추가.
- **Run**: 주석 알림.
- **Expected**: 알림 없음.
- **Pass criterion**: 알림 0줄, `check-purity.sh` · 사전 모양 시험 종료 코드 0.

### T9. 주석 알림은 막지 않음

- **Setup**: T7 상태.
- **Run**: 계획 끝 검사 전체.
- **Expected**: 알림은 나오지만 종료 코드는 알림이 없을 때와 같음.
- **Pass criterion**: 두 실행의 종료 코드가 같은 숫자(0 = 0).

### T10. 맥 · 리눅스 같은 결과

- **Setup**: T7 · T8 · T19 사례.
- **Run**: 맥(BSD 도구)과 리눅스(GNU 도구, CI 또는 컨테이너)에서 각각.
- **Expected**: 알림 · 막힘 줄이 글자까지 같음.
- **Pass criterion**: 두 출력의 `diff` 종료 코드 0.

### T11. 증거 없는 '끝'은 거절

- **Setup**: 단계 2 를 `doing` 으로 보고한 상태.
- **Run**: 단계 보고 도구에 `done` 을 증거 없이 보냄.
- **Expected**: 거절, 답에 "증거(파일 경로 또는 명령 출력)를 함께 보내라"는 이유. 노드 상태는 진행 중 그대로.
- **Pass criterion**: 거절 1건, 상태 변화 0.

### T12. 단계 시작 전에 생긴 파일은 증거로 안 받음

- **Setup**: 단계 시작 시각보다 바뀐 시각이 앞선 파일 하나, 뒤인 파일 하나.
- **Run**: 앞선 파일로 `done` → 뒤인 파일로 `done`.
- **Expected**: 첫째 거절(이유: 단계 시작 전 파일), 둘째 받음.
- **Pass criterion**: 거절 1 · 받음 1.

### T13. 프로젝트 밖 · 없는 파일은 거절

- **Setup**: 프로젝트 밖 경로, 없는 경로.
- **Run**: 각각으로 `done`.
- **Expected**: 둘 다 거절, 이유가 각각 "프로젝트 밖" · "파일 없음".
- **Pass criterion**: 거절 2건, 이유 글이 서로 다름.

### T14. 명령 출력 발췌도 증거로 받음

- **Setup**: 화면이 없는 단계, 시험 출력 발췌 글.
- **Run**: 발췌 글로 `done` → 빈 글로 `done`.
- **Expected**: 첫째 받음, 둘째 거절.
- **Pass criterion**: 받음 1 · 거절 1.

### T15. 끝난 노드를 누르면 증거가 보임

- **Setup**: 이미지 파일 하나 · 글 파일 하나 · 출력 발췌를 증거로 받은 끝난 단계.
- **Run**: 모드 시험에서 그 노드를 누름.
- **Expected**: 이미지는 그림으로, 글 파일은 앞부분, 출력 발췌는 글로 보임.
- **Pass criterion**: 상세에 그림 1개 · 글 앞부분 1개 · 출력 글 1개, 합계 3개.

### T16. 진행 중 노드를 누르면 실제 진행이 보임

- **Setup**: `doing` 보고에 로그 파일 경로와 주소를 줌. 로그 끝에 `epoch 3/10 loss 0.42` 같은 줄과 퍼센트 줄.
- **Run**: 그 노드를 누름.
- **Expected**: 로그 최근 줄, 진행률 막대(찾은 경우), 주소 여는 버튼.
- **Pass criterion**: 세 가지가 모두 나오고, 주소로 나가는 읽기 요청 0건.

### T17. "지금 하는 일" 카드가 사라짐

- **Setup**: 현재 모드 시험의 패널 그림.
- **Run**: 패널을 그림.
- **Expected**: "지금 하는 일" 카드 없음, 노드 상세가 그 자리를 맡음. 바뀐 화면에 맞춘 시험 말고 기존 시험 그대로 통과.
- **Pass criterion**: "지금 하는 일" 글 0회, `claude plugin test .` 실패 0.

### T18. 계획 끝 검사가 사전 중복 검사를 자동으로 돌림

- **Setup**: 사전이 있는 임시 프로젝트, 중복 없음.
- **Run**: 계획 끝 검사.
- **Expected**: 출력에 사전 중복 검사 결과 줄("중복 의심 0")이 있음.
- **Pass criterion**: 결과 줄 1개, 종료 코드 0.

### T19. 셸 중복은 계획 끝 검사에서 막힘

- **Setup**: 사전에 `trim_spaces` 가 있고, 같은 일을 하는 `strip_blank` 를 `@pure` 와 다른 예시로 더함.
- **Run**: 계획 끝 검사.
- **Expected**: "중복 의심: trim_spaces · strip_blank"로 막힘.
- **Pass criterion**: 막힘 1줄, 종료 코드 1.

### T20. TS · 파이썬 · 러스트 중복도 실제로 돌려 잡음

- **Setup**: 언어마다 같은 일을 하는 함수 두 개를 서로 다른 예시 글로 사전에 넣음 (예시 글끼리는 겹치지 않게).
- **Run**: 계획 끝 검사.
- **Expected**: 세 언어 각각 "중복 의심" 1줄 — 예시 글 비교만으로는 못 잡는 짝임.
- **Pass criterion**: 중복 의심 3줄(언어마다 1), 종료 코드 1.

### T21. 다른 이유를 적으면 통과 · 도구가 없으면 알림

- **Setup**: T19 짝을 중복 예외 파일에 이유와 함께 적음. 따로, node · python3 · rustc 를 PATH 에서 뺀 실행.
- **Run**: 계획 끝 검사 두 번.
- **Expected**: 이유 있음 → 통과, 이유 빈 줄 → 막힘. 도구 없음 → "돌려 보지 못함: <언어>" 줄, 그 언어 때문에 막지 않음.
- **Pass criterion**: 종료 코드 0 · 1, "돌려 보지 못함" 줄 3개.

## How to run

```bash
bash core/tests/test-checks-not-comments.sh && bash core/tests/test-instruction-diet.sh && bash core/tests/test-help-budget.sh && (cd ../scv-mods/marketplace/mods/scv-dashboard && claude plugin test .)
```

## Pass criteria

- T1~T21 모두 통과 (T10 은 리눅스 쪽 실행 결과를 기록에 남김).
- 순수 사전 검사 · 사전 모양 시험이 맥 · 리눅스 둘 다 종료 코드 0.

## Related Documents

- [`PLAN.md`](./PLAN.md)
