# Test Plan — 드림 — 프롬프트 코치

## Overview

드림이 직접 · 자동(clear · compact · 날짜 바뀜)으로 돌고, 입력을 바꾸지 않으며, 질의 ÷ 보관 비율 · 분포 · 근거 붙은 개선점 · 판정자 조언을 HTML 과 한 줄 요약으로 내는지, 끄면 아무것도 나오지 않는지 확인한다. 합격 기준은 구현 전에 여기 고정한다.

## Test scenarios

### T1. 직접 실행 — 보고서가 나온다

- **Setup**: 픽스처 저장소(세션 기록 3개 · 보관 계획 2개 · 등록 명령 포함)
- **Run**: `dreams.sh`
- **Expected**: scv/dreams/<시각>.html 과 latest.json 생성. HTML 에 기간 표(질의 · 보관 · 비율), 분포 차트(SVG), 개선점 1개 이상(근거 턴 발췌 포함).
- **Pass criterion**: 숫자가 픽스처에서 손으로 센 값과 같다.

### T2. 순수 단계

- **Run**: 단계 3~8 · 10 · 11 을 픽스처 입력으로 직접 부름
- **Expected**: 사람 턴에서 자동 알림 · 도구 결과 · 압축 요약이 빠지고, 등록 항목 상태가 정확하고, 기간 · 분포 · 개선점이 정해진 값.
- **Pass criterion**: 단계마다 기대 출력과 같다.

### T3. 자동 발동 — clear · compact

- **Run**: 시작 훅에 source = clear / compact / resume / startup
- **Expected**: clear · compact 에서만 배경 드림이 한 번 뜬다. 훅은 지연 상한 안에 돌아온다.
- **Pass criterion**: 뜬 횟수 clear 1 · compact 1 · 나머지 0, 훅 지연 0.5초 이하(맥 시스템 bash 3.2).

### T4. 자동 발동 — 날짜 바뀜

- **Run**: 지난 드림 날짜를 어제로 둔 채 매 턴 훅 두 번, 오늘로 둔 채 한 번
- **Expected**: 어제 → 첫 번째에서만 뜸, 오늘 → 안 뜸.
- **Pass criterion**: 뜬 횟수 1.

### T5. 한 번에 하나

- **Run**: 드림이 도는 중에 다시 발동
- **Expected**: 두 번째는 뜨지 않는다(잠금). 잠금은 끝나면 풀리고, 오래된 잠금(죽은 프로세스)은 다음 발동이 치운다.
- **Pass criterion**: 동시 실행 0.

### T6. 끄기

- **Run**: SCV_DREAMS=off 로 T3 · T4 · 직접 실행
- **Expected**: 자동 발동 없음, 직접 실행은 '꺼져 있음' 한 줄, 훅 출력이 이 기능 전과 바이트 단위로 같다.
- **Pass criterion**: 출력 비교 일치.

### T7. 입력을 바꾸지 않는다

- **Run**: T1 전후로 세션 기록 · archive · 메모 · 대화 기록의 해시
- **Pass criterion**: 해시 모두 같음.

### T8. 개인 정보 없음

- **Setup**: 픽스처에 홈 경로 · 메일 · 토큰 · 세션 id 를 심은 사람 턴
- **Run**: T1 + 판정자에게 보낸 글 기록
- **Pass criterion**: 보고서 · 요약 · 판정자 입력에 심은 값 0건.

### T9. 판정자

- **Run**: 판정자 명령 = 픽스처 명령(정상 · 실패 · 깨진 답), SCV_DREAMS_JUDGE=off
- **Expected**: 정상 → 조언 칸에 답 + 가이드 규칙 이름, 실패 · 깨진 답 · 끔 · 판정자 없음(코덱스) → 보고서는 나오고 조언 칸에 '조언 없음(이유)'. 같은 발췌는 다시 묻지 않는다(캐시).
- **Pass criterion**: 다섯 경우 모두 보고서 생성, 캐시 적중 시 판정자 호출 0.

### T10. 다음 턴 요약 한 줄

- **Run**: 새 보고서가 생긴 뒤 매 턴 훅 두 번
- **Expected**: 첫 번째에만 '드림: …' 한 줄(비율 · 개선점 하나 · 보고서 위치), 두 번째는 없음. 매 턴 상한 안.
- **Pass criterion**: 한 번만, test-help-budget 통과.

### T11. 직접 명령 · 설정 예시 · 규칙 한 곳

- **Run**: test-rule-constitution · 설정 예시 검사
- **Expected**: protocols/dreams.md 에 규칙 전문, 설정 예시에 SCV_DREAMS · SCV_DREAMS_JUDGE.
- **Pass criterion**: 통과.

### T12. 실제 기록으로 보여 주기

- **Run**: 이 저장소에서 `dreams.sh` (설치본 판정자)
- **Expected**: 실제 숫자 · 차트 · 개선점 · 조언이 나온 보고서를 사용자에게 보인다.
- **Pass criterion**: 사용자가 선택 창에서 '이대로 좋음'을 고른다.

## How to run

```bash
bash core/tests/test-dreams.sh && bash core/tests/test-help-budget.sh && bash core/tests/test-rule-constitution.sh
```

T12 는 실제 세션 기록 · 판정자를 쓰므로 CI · 회귀 실행에 넣지 않는다 — 구현 끝에 한 번 돌려 보인다.

## Pass criteria

- T1 ~ T11 통과(맥 시스템 bash 3.2 와 리눅스 bash).
- T12 사용자 확인.
