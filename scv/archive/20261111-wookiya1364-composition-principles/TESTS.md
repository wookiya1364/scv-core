# Test Plan — 합성 설계 원칙을 SCV 계약에 넣기

## Overview

가이드의 핵심이 계약 문서에 들어갔는지, 계획서가 체크리스트를 요구하는지, 답이나 근거가 빠지면 경고가 나오는지를 본다.
막는 것은 없어야 한다 — 옛 계획은 지금처럼 다뤄진다.

## Test scenarios

### T1. 계약 문서 — 합성 원칙

- **Setup**: 없음.
- **Run**: 새 계약 문서에서 낱말을 찾는다.
- **Expected**: 요소 단위 합성 · 순회 한 번 · 중간 모음 · 지연 평가 · 구조 공유 · 단항이 모두 있다.
- **Pass criterion**: 여섯 낱말 각각 1번 이상(지금 `purity.md` 에는 0번).

### T2. 계약 문서 — 언어별 수단 표

- **Setup**: 없음.
- **Run**: 표의 줄을 센다.
- **Expected**: 언어 9개(TypeScript/JS · Python · Java · Kotlin · C# · Go · Rust · Scala · Haskell)와 셸 한 줄, 칸은 합성 수단 · 지연 평가 · 불변성 강제 · 구조 공유.
- **Pass criterion**: 표의 본문 줄 10개, 칸 5개. 문서 표 시험(줄글 칸 금지) 통과.

### T3. 계약 문서 — 막는 것과 못 막는 것

- **Setup**: 없음.
- **Run**: 그 절을 읽는다.
- **Expected**: "최대 성능은 증명할 수 없다"는 뜻의 문장이 있고, "보장한다"는 말이 없다.
- **Pass criterion**: 정해 둔 문장 1번, 금지 낱말("최대 성능을 보장") 0번.

### T4. 계약 문서 — 체크리스트 10개

- **Setup**: 없음.
- **Run**: 번호가 붙은 물음을 센다.
- **Expected**: 가이드 6장의 10개가 번호 1 ~ 10 으로 있다.
- **Pass criterion**: 번호 줄 10개.

### T5. 기존 순수성 문서가 새 문서를 가리킨다

- **Setup**: 없음.
- **Run**: `purity.md` 에서 새 문서 이름을 찾는다.
- **Expected**: 가리키는 줄 1개, 나머지 내용은 그대로.
- **Pass criterion**: 새 문서 이름 1번, 고치기 전과의 차이가 그 줄뿐.

### T6. 계획 템플릿 — 체크리스트 표

- **Setup**: 없음.
- **Run**: 계획 만들기 규약의 계획서 템플릿을 본다.
- **Expected**: `순수함수 · 파이프라인` 절 아래에 체크리스트 표(번호 · 물음 · 답 · 근거)가 있다.
- **Pass criterion**: 표 머리 줄 1개.

### T7. 작업 규약 — 끝낼 때 다시 답하기

- **Setup**: 없음.
- **Run**: 작업 규약의 보관 전 단계를 본다.
- **Expected**: 체크리스트를 실제 코드로 다시 채우라는 문장이 있다.
- **Pass criterion**: 그 문장 1번.

### T8. 경고 — 체크리스트 표가 없는 계획

- **Setup**: 순수함수 절은 있고 체크리스트 표가 없는 계획 폴더.
- **Run**: 기획서 만들기.
- **Expected**: 체크리스트가 없다는 경고 1줄. 기획서는 만들어진다.
- **Pass criterion**: 경고 1줄, 종료 코드 0.

### T9. 경고 — 근거가 빈 답

- **Setup**: 체크리스트 표에서 답은 "예"인데 근거 칸이 빈 줄이 2개인 계획.
- **Run**: 기획서 만들기.
- **Expected**: 그 번호들을 이름 붙인 경고.
- **Pass criterion**: 경고에 두 번호가 모두 나온다.

### T10. 경고 없음 — 다 채운 계획

- **Setup**: 표가 있고 모든 답에 근거(또는 "해당 없음"과 이유)가 있는 계획 — 이 계획 자신.
- **Run**: 기획서 만들기.
- **Expected**: 체크리스트 경고 0줄.
- **Pass criterion**: 체크리스트 경고 0줄.

### T11. 옛 계획은 그대로

- **Setup**: 보관된 계획 하나(체크리스트 없음).
- **Run**: 기획서 만들기와 보관 관련 기존 시험.
- **Expected**: 지금처럼 만들어지고, 막히지 않는다.
- **Pass criterion**: 종료 코드 0, 기존 시험 통과 수 그대로.

### T12. 분량과 전체 시험

- **Setup**: 없음.
- **Run**: 분량 한도 시험, 호스트 이름 시험, 전체 시험(4개씩, bash 3.2 · bash 5).
- **Expected**: 매 턴 안내 크기 그대로, 새로 실패한 시험 0개.
- **Pass criterion**: 두 bash 모두 실패 0개.

## How to run

```bash
bash core/tests/test-composition-principles.sh && bash core/tests/test-instruction-diet.sh && bash core/tests/test-help-budget.sh
```

## Pass criteria

- T1–T12 통과.
- PR 검사(맥 · 리눅스) 통과는 PR 을 열 때 본다.

## Related Documents

- [`PLAN.md`](./PLAN.md)
