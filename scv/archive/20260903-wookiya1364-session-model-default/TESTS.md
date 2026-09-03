# Test Plan — 명령이 세션 모델을 바꾸지 않는다

## Overview

두 축이다. **기본이 세션 모델인가** — 새 설치 상태에서 모델 지정 줄이 하나도 없는가.
**선택은 살아 있는가** — 매핑을 켜면 줄이 생기고, 끄면 사라지고, 그 선택이 설정
파일에 남아 sync 가 다시 적용하는가. 코어에서 검사할 수 있는 것(등록부)은 항상
돌고, 래퍼 파일은 옆에 체크아웃이 있을 때만 본다.

## Test scenarios

### T1. 코어 설정 등록부에 정책 키가 있다

- **Setup**: 없음.
- **Run**: 설정 예시 파일과 설정 라이브러리를 읽는다.
- **Expected**: `SCV_MODEL_POLICY` 가 공개 키 목록에 있고, 예시 기본값이
  `session-default` 이며, 설명(_doc)이 있다.
- **Pass criterion**: 세 가지가 모두 확인된다.

### T2. 하이드레이트한 새 프로젝트의 설정 파일에 키가 생긴다

- **Setup**: 임시 프로젝트를 하이드레이트한다.
- **Run**: 생성된 설정 파일을 읽는다.
- **Expected**: `SCV_MODEL_POLICY` 키가 있고 값이 `session-default` 다.
- **Pass criterion**: 키와 값이 확인된다.

### T3. 래퍼 명령 파일에 모델 지정 줄이 없다 (래퍼 체크아웃 있을 때)

이 계획의 핵심이다.

- **Setup**: 형제 경로에 Claude Code 래퍼 저장소가 있을 때만.
- **Run**: 래퍼의 명령 파일 15개 머리말을 본다.
- **Expected**: `model:` 줄이 하나도 없다.
- **Pass criterion**: 15개 모두 0건. 체크아웃이 없으면 SKIP.

### T4. 매핑을 켜면 줄이 생기고, 끄면 사라진다 (래퍼 체크아웃 있을 때)

- **Setup**: 래퍼의 명령 파일을 임시 폴더에 복사한다.
- **Run**: 정책 스크립트로 `recommended` 를 적용한 뒤, `session-default` 를 적용한다.
- **Expected**: 첫 적용 뒤 help 는 opus·status 는 haiku 줄이 있고, 둘째 적용 뒤 줄이
  전부 사라진다. 두 번 적용해도 결과가 같다(멱등).
- **Pass criterion**: 세 상태가 모두 확인된다.

### T5. 정책을 설정 파일에서 읽는다 (래퍼 체크아웃 있을 때)

저장이 고장나 있던 자리다.

- **Setup**: 임시 프로젝트의 설정 파일에 `SCV_MODEL_POLICY=all-haiku` 를 쓴다. `.env`
  는 없다.
- **Run**: 정책 스크립트를 프로젝트 기준으로 재적용 모드로 돌린다.
- **Expected**: 설정 파일의 값을 읽어 매핑을 적용한다.
- **Pass criterion**: 명령 파일에 haiku 줄이 생긴다.

### T6. 옛 `.env` 만 있는 프로젝트도 읽는다 (래퍼 체크아웃 있을 때)

- **Setup**: 설정 파일에 키가 없고 `.env` 에만 `SCV_MODEL_POLICY=all-opus` 가 있다.
- **Run**: 재적용 모드로 돌린다.
- **Expected**: `.env` 의 값을 읽는다.
- **Pass criterion**: opus 줄이 생긴다.

### T7. set-models 문서가 없는 스크립트를 부르지 않는다 (래퍼 체크아웃 있을 때)

- **Setup**: 없음.
- **Run**: 래퍼의 set-models 명령 문서를 읽는다.
- **Expected**: 저장 단계가 코어의 `settings-set.sh` 를 부르고, 사라진 `env-set.sh` 는
  언급하지 않는다. 첫 선택지가 session-default 다.
- **Pass criterion**: 세 가지가 모두 확인된다.

### T8. 래퍼 검사가 새 기본을 잠근다 (래퍼 체크아웃 있을 때)

- **Setup**: 없음.
- **Run**: 래퍼의 계약 검사를 읽는다.
- **Expected**: "모든 명령에 model 줄이 있어야" 단언이 없고, "기본은 없어야" 단언이 있다.
- **Pass criterion**: 옛 단언 0건, 새 단언 1건 이상.

### T9. Codex 래퍼는 무변경 (체크아웃 있을 때)

- **Setup**: 형제 경로에 Codex 래퍼가 있을 때만.
- **Run**: Codex 래퍼의 스킬 파일들을 본다.
- **Expected**: 모델 지정 줄이 없다 — 전에도 없었고 지금도 없다.
- **Pass criterion**: 0건.

## How to run

```bash
bash core/tests/test-model-policy-default.sh
```

## Pass criteria

- T1~T2 통과. T3~T9 는 통과 또는 SKIP(체크아웃 없음).
- 기존 설정 검사(test-settings.sh)가 여전히 통과한다 — 키가 하나 늘어도.

## Related Documents

- [`PLAN.md`](./PLAN.md)
