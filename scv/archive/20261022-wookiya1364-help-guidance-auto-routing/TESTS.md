# Test Plan — 자동 라우팅에 맞춘 안내 정리

## Overview

새 사용자가 보는 안내(설치 마지막 안내 · 진단 추천 · 계획 문서 · promote 메시지)가 "그냥 말하면 된다"를
기본 입구로 말하는지, 알림 설정이 없다고 멈추지 않는지, 자동 라우팅을 끈 프로젝트는 예전 안내를 받는지를 본다.
대화 Turn 3 의 재현(언어만 든 설정 → "설정 예시 복사" 안내)이 출발점이다.

## Test scenarios

### T1. 알림 미설정에서도 멈추지 않는다 (①)

- **Setup**: 새 폴더에 설치, 설정 파일에 언어만(`{"SCV_LANG":"ko"}`).
- **Run**: 진단 스크립트.
- **Expected**: 추천이 "Configure settings" 가 아니고 준비됨(또는 상태에 맞는 추천). 출력 어디에도 `cp scv/scv_settings.example.json scv/scv_settings.json` 이 없다. 알림은 선택 줄로 한 번 나온다.
- **Pass criterion**: 세 조건 모두.

### T2. 설정 파일이 없을 때도 덮어쓰기 안내가 없다 (①)

- **Setup**: 설치 후 설정 파일 삭제.
- **Run**: 진단 스크립트.
- **Expected**: 추천이 설정 단계에서 멈추지 않고, 설정 안내가 있다면 선택 줄이다.
- **Pass criterion**: "Configure settings" 추천 블록 없음.

### T3. 준비됨 안내의 첫 입구는 그냥 말하기 (②)

- **Setup**: T1 상태(자동 라우팅 기본 켬).
- **Run**: 진단 스크립트.
- **Expected**: 준비됨 블록에 "Ready — no immediate action" 유지, 그 아래 첫 항목이 그냥 말하라는 안내.
- **Pass criterion**: 문구 존재 + 순서.

### T4. 자동 라우팅을 끄면 명령 안내 (② · 불변식)

- **Setup**: 설정에 `SCV_ALWAYS_ON: off`.
- **Run**: 진단 스크립트.
- **Expected**: 준비됨 블록이 `action:help "…"` 명령 입력을 안내하고, 그냥 말하라는 안내는 없다.
- **Pass criterion**: 둘 다.

### T5. 설치 마지막 안내 (④)

- **Run**: 새 폴더에 설치 스크립트.
- **Expected**: 그냥 말하면 된다는 안내가 있고 "your the host agent" 오타가 없다.
- **Pass criterion**: 둘 다.

### T6. 문서 · 메시지 (③)

- **Run**: 템플릿 PROMOTE.md §1.4, raw/README.md, promote 규약의 "Nothing to refine" 메시지, promote-handoff 의 멈춤 안내, help 규약 Mode B 설명, 진단 규약(hydrate.md)의 못 끝낸 대화 이어가기 안내를 검사.
- **Expected**: 각각 그냥 말하기를 기본 입구로 적고(명령은 선택지로 남아도 됨), "다듬을 것 없음" 메시지가 명령만 안내하지 않는다.
- **Pass criterion**: 여섯 곳 모두. (이어가기 안내는 확인 턴에 찾아 추가 — 결과를 보기 전 기준에 넣음.)

### T7. 회귀

- **Run**: run-dry · test-help-budget · test-guidance · test-template-digest · test-force-help.
- **Expected**: 모두 통과.

## How to run

```bash
bash core/tests/test-help-guidance.sh && bash core/tests/test-help-budget.sh && bash core/tests/test-force-help.sh
```

## Pass criteria

- T1–T7 통과, 코어 전체 테스트(codex 사본 포함) 통과.
