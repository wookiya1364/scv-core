# Test Plan — 깊은 질문은 배경 조사로

## Overview

세 축이다. **off 면 아무 것도 안 달라지는가** — 기본 상태의 훅 출력이 지금과 같고 기존
검사가 전부 그대로 통과하는가. **on 이면 블록이 실리는가** — 본문이 있고, 짧고, 기존
블록의 순서를 흐트러뜨리지 않는가. **래퍼가 에이전트를 싣는가** — 파일이 있고 배경
실행이며 모델을 상속하고 effort 줄이 없는가. 코어에서 검사할 수 있는 것은 항상 돌고, 래퍼
파일은 옆에 체크아웃이 있을 때만 본다.

## Test scenarios

### T1. 코어 설정 등록부에 스위치 키가 있다

- **Setup**: 없음.
- **Run**: 설정 예시 파일과 설정 라이브러리를 읽는다.
- **Expected**: `SCV_DELEGATE_EFFORT` 가 공개 키 목록에 있고, 예시 기본값이 `off` 이며,
  설명(_doc)이 있다.
- **Pass criterion**: 세 가지가 모두 확인된다.

### T2. 하이드레이트한 새 프로젝트의 설정 파일에 키가 생긴다

- **Setup**: 임시 프로젝트를 하이드레이트한다.
- **Run**: 생성된 설정 파일을 읽는다.
- **Expected**: `SCV_DELEGATE_EFFORT` 키가 있고 값이 `off` 다.
- **Pass criterion**: 키와 값이 확인된다.

### T3. off 면 훅 출력이 지금과 같다

이 계획의 핵심 불변이다.

- **Setup**: 임시 프로젝트 하나. 스위치를 없음 · `off` · `OFF` · `maybe` · 빈값 · `on!`
  각각으로 둔다(같은 폴더에서 설정만 바꾼다 — 진단에 폴더 경로가 찍힌다).
- **Run**: 매 턴 훅을 돌린다.
- **Expected**: 모든 경우 `[SCV delegate]` 표식이 없고, 스위치 키가 없을 때의 출력과
  바이트 단위로 같다. 종료 코드 0.
- **Pass criterion**: 여섯 경우 모두 확인된다.

### T4. on 이면 블록이 실린다

- **Setup**: 임시 프로젝트. 스위치를 `on` · `ON` · ` on `(공백 포함) 으로. 정규화는 기존
  스위치와 같다 — 공백·따옴표를 벗기고 대소문자를 가리지 않는다.
- **Run**: 매 턴 훅을 돌린다.
- **Expected**: `[SCV delegate]` 표식이 한 번 있고, 본문에 "세션 그대로", "배경",
  `scv-investigator`, `scv/raw/`, "대화 파일" 이 들어 있다. 블록은 12줄 이내, 훅 전체는
  80줄 이내.
- **Pass criterion**: 세 경우 모두 확인된다.

### T5. 새 블록이 기존 블록과 스위치를 건드리지 않는다

- **Setup**: 스위치 `on`.
- **Run**: (a) 쉬운 말 스위치 off, (b) 항상-켬 스위치 off, (c) preflight 스위치 off 로 각각
  훅을 돌린다.
- **Expected**: (a)(b)(c) 모두 새 블록은 그대로 실리고, 기존 블록의 유무는 지금 규칙과
  같다. 라우팅 지시 → 갱신 안내 → 진단의 순서는 변함없고, 새 블록은 라우팅 지시 뒤·진단
  앞에 선다. 두 기존 스위치를 모두 끄고 새 스위치도 끄면 완전히 침묵한다.
- **Pass criterion**: 네 경우 모두 확인된다.

### T6. 순수 함수는 순수하다

- **Setup**: 없음.
- **Run**: 순수성 검사를 `force-help.sh` 에 돌린다.
- **Expected**: 새 함수 둘(정규화 · 본문)이 `@pure` 표시를 달고 검사를 통과한다.
- **Pass criterion**: 검사 출력이 OK.

### T7. 코어 본문은 호스트 중립이다

- **Setup**: 없음.
- **Run**: 호스트 중립 검사와 effort 단계 이름 검사를 돌린다.
- **Expected**: 새 블록 본문 · 규약 단락 · 설정 설명 어디에도 호스트 이름, 모델 이름,
  effort 단계 이름(low·medium·high·xhigh·max·ultracode)이 없다.
- **Pass criterion**: 두 검사 통과.

### T8. 템플릿 지문이 새 훅·설정 예시와 맞는다

- **Setup**: 없음.
- **Run**: 지문 검사를 돌린다.
- **Expected**: 지문이 최신이다.
- **Pass criterion**: 검사 통과.

### T9. 래퍼가 배경 조사 에이전트를 싣는다 (래퍼 체크아웃 있을 때)

- **Setup**: 형제 경로에 Claude Code 래퍼 저장소가 있을 때만.
- **Run**: 래퍼의 `agents/scv-investigator.md` 머리말을 읽는다.
- **Expected**: 파일이 있고, 배경 실행 표시가 있고, 모델은 상속이며, `effort:` 줄이
  없고, 도구 목록에 편집 도구(Edit)가 없고 금지 목록에는 있으며, 본문이 `scv/raw/` 밖의
  쓰기를 금한다.
- **Pass criterion**: 여섯 가지 모두 확인된다. 체크아웃이 없으면 SKIP.

### T10. 래퍼 계약 검사가 새 파일을 잠근다 (래퍼 체크아웃 있을 때)

- **Setup**: 없음.
- **Run**: 래퍼의 계약 검사를 읽는다.
- **Expected**: T9 의 조건을 단언하는 항목이 있다. 명령 파일에 `model:` 줄이 없어야 한다는
  기존 단언은 그대로다.
- **Pass criterion**: 새 단언 1건 이상, 기존 단언 유지.

### T11. Codex 래퍼는 무변경 (체크아웃 있을 때)

- **Setup**: 형제 경로에 Codex 래퍼가 있을 때만.
- **Run**: Codex 래퍼의 스킬·어댑터 파일을 본다.
- **Expected**: 이 계획으로 바뀐 파일이 없다. 코어 페이로드 갱신(sync) 외에는 무변경.
- **Pass criterion**: 0건.

### T12. 실기기 1회 — 깊은 질문에 답이 그 턴에 나오고 결과 파일이 생긴다

- **Setup**: 스위치 `on` 인 실제 프로젝트, 래퍼 갱신 뒤 새 세션.
- **Run**: 여러 파일을 읽어야 답할 수 있는 질문을 던진다.
- **Expected**: 답이 그 턴에 세션 effort 로 나오고 "깊은 결과가 뒤따른다" 고 적혀 있다.
  조사가 끝나면 `scv/raw/` 에 결과 파일이 생기고 요약 알림이 온다. 세션 effort 표시는
  바뀌지 않는다.
- **Pass criterion**: 세 가지 모두 관찰된다. (자동 검사 아님 — 구현 뒤 사람이 1회 확인)

## How to run

```bash
bash core/tests/test-delegate-effort.sh
```

## Pass criteria

- T1~T8 통과. T9~T11 은 통과 또는 SKIP(체크아웃 없음). T12 는 실기기 1회 관찰.
- 기존 검사(test-force-help · test-journal · test-autosync · test-purity ·
  test-host-neutral · test-template-digest · test-settings)가 여전히 통과한다.

## Related Documents

- [`PLAN.md`](./PLAN.md)
