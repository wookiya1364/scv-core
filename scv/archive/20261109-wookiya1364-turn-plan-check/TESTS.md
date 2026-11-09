# Test Plan — 고친 턴은 계획 기록이 있어야 끝남 · 선택 답은 계획에 바로 · 대시보드에 이력

## Overview

2026-11-09 시제품(턴 끝 검사 1~3판 · 선택 답 기록)으로 잰 장면을 그대로 시험으로 고정한다. 시험은 임시 git 저장소 · git 아닌 폴더 · 가짜 계획을 만들어 훅 스크립트를 직접 부른다. 네 세션 다시 세기는 로컬 기록이라 CI 시험이 아니라 측정 단계(T13)로 둔다.

## Test scenarios

### T1. 셸로 코드 수정, 계획 기록 없음 → 막힘 (장면 A)

- **Setup**: 진행 중 계획 하나가 있는 임시 git 저장소, 턴 시작 사진
- **Run**: `sed -i` 로 코드 파일 한 줄 바꾸고 턴 끝 판정
- **Expected**: BLOCK, 막는 말에 `plan-link.sh progress` 또는 `append` 사용법 한 줄
- **Pass criterion**: 끝 코드가 막힘이고 막는 말이 한 줄

### T2. 계획 밖 일 + plan-link append (요청 번호 포함) → 통과 (장면 B)

- **Setup**: T1 과 같음
- **Run**: 코드 수정 + `bash <절대경로>/plan-link.sh append …` 성공
- **Expected**: PASS. 계획의 새 줄에 `(요청 <번호>)` 와 사용자 원문 앞부분이 붙어 있음
- **Pass criterion**: 판정 PASS · 새 줄에 번호와 원문이 둘 다 있음

### T3. 계획 안 일 + progress 한 줄 → 통과 (장면 P)

- **Setup**: T1 과 같음
- **Run**: 코드 수정 + `plan-link.sh progress <계획> --step 6 --note …`
- **Expected**: PASS. `## 변경 이력` 에 `**<날짜> 진행** — 6단계: …` 줄
- **Pass criterion**: 판정 PASS · 진행 줄 1개

### T4. 가짜 기록은 모두 막힘 (장면 C · H · H2 · H3 · J · B2)

- **Setup**: T1 과 같음
- **Run**: 코드 수정과 함께 각각 — 계획에 아무 글(C), 손으로 쓴 이력 모양 줄(H), 그 줄에 요청 번호까지(H2), 명령 이름만 적고 손으로 씀(H3), 실패한 plan-link(J), 요청 번호 빠진 append(B2)
- **Expected**: 여섯 장면 모두 BLOCK
- **Pass criterion**: 6/6 BLOCK

### T5. 남는 한계는 통과하되 원문이 보임 (장면 K)

- **Setup**: T1 과 같음
- **Run**: 코드 수정 + 내용이 `x` 인 append
- **Expected**: PASS, 그 줄에 사용자 원문 앞부분이 붙어 있음
- **Pass criterion**: 판정 PASS · 줄에 원문 있음

### T6. 바뀐 것이 이번 턴 것만 (장면 D · D2 · E · F)

- **Setup**: 턴 시작 전에 미커밋 변경이 있는 저장소
- **Run**: (D) 이번 턴 변경 없음, (D2) 같은 파일을 이번 턴에 또 고침, (E) 고치고 커밋까지, (F) 코드 아닌 scv/ 안 파일만 고침
- **Expected**: D PASS · D2 BLOCK · E BLOCK · F PASS
- **Pass criterion**: 네 판정이 그대로

### T7. scv/ 밖 문서도 바뀐 것으로 봄

- **Setup**: 계획 없는 저장소
- **Run**: 루트의 `.md` 한 줄 바꿈
- **Expected**: BLOCK (계획을 만들거나 exempt 를 쓰라는 말)
- **Pass criterion**: BLOCK

### T8. git 아닌 폴더도 검사함 (장면 G 고침)

- **Setup**: git 이 아닌 임시 폴더, 계획 없음
- **Run**: 파일 하나 고침
- **Expected**: BLOCK. 파일 1,000개 폴더의 사진이 0.3초 안
- **Pass criterion**: BLOCK · 시간 기준 통과

### T9. 작업 공간의 다른 저장소 (몰래 고친 스크립트)

- **Setup**: 저장소 A(프로젝트) · B(설정 목록에 있음), 둘 다 턴 시작 사진
- **Run**: 명령 글에 B 경로가 보이지 않는 스크립트가 B 를 고침
- **Expected**: B 에서 BLOCK, A 는 PASS
- **Pass criterion**: B 판정 BLOCK

### T10. 릴리스 예외

- **Setup**: 계획 없는 저장소
- **Run**: 버전 파일 수정 + `plan-link.sh exempt --kind release --why "…"`. 정하지 않은 종류(`--kind misc`)도 한 번
- **Expected**: release 는 PASS, misc 는 exempt 명령이 거절(끝 코드 2)하고 판정 BLOCK
- **Pass criterion**: 두 판정 그대로

### T11. 2번 막히면 통과 + 기록 없음 표시

- **Setup**: T1 상태
- **Run**: 기록 없이 턴 끝 판정을 세 번
- **Expected**: 1 · 2번째 BLOCK, 3번째 PASS 와 함께 저널 · 계획에 '계획 기록 없음' 한 줄
- **Pass criterion**: 판정 순서와 기록 한 줄

### T12. 선택 답 자동 기록

- **Setup**: 진행 중 계획, AskUserQuestion 결과 모양의 훅 입력
- **Run**: 선택 답 훅에 질문 · 답을 넣음 (slay 오늘 답 17개를 고정 자료로)
- **Expected**: `## 변경 이력` 에 17줄이 시각 순서로, 각 줄에 답 · 질문. 17개 1초 안
- **Pass criterion**: 17줄 · 시간 기준

### T13. 네 세션 다시 세기 (측정 단계 — CI 아님)

- **Setup**: 로컬 기록(slay · 강의 · 공고 자동화 · 이 세션)
- **Run**: 다시 세기 스크립트로 턴마다 판정
- **Expected**: slay 계획 밖 11/11 BLOCK · 강의 41/41 · 공고 6/6 · 이 세션 계획 안 턴 막힘 0
- **Pass criterion**: 수치를 계획 변경 이력에 적고, 다르면 원인을 적음

### T14. 대시보드 (scv-mods 저장소의 시험)

- **Setup**: slay 계획 사본 + 변경 이력 18줄
- **Run**: 패널 모델로 계획을 읽음
- **Expected**: 단계 8개(`2b.` 포함) · 이력 18개, 최근 것이 맨 위
- **Pass criterion**: 수치 그대로

### T15. 끄기와 기존 동작

- **Setup**: `SCV_TURN_PLAN_CHECK=off`
- **Run**: T1 과 같은 수정
- **Expected**: 판정하지 않음(PASS). 0.86.0 plan-link 시험(test-plan-link.sh)과 guard 시험이 그대로 통과
- **Pass criterion**: PASS · 기존 시험 통과

## How to run

```bash
bash core/tests/test-turn-plan-check.sh
```

## Pass criteria

- T1~T12 · T15 가 맥 · 리눅스 CI 에서 통과, core 전체 시험 통과
- T13 측정 수치를 계획에 적음
- T14 는 scv-mods `claude plugin test` 로 통과
