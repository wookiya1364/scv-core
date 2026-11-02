# Test Plan — README 그림을 이미지로 — 휴대폰에서도 보이게

## Overview

사용자가 원한 것은 README 그림이 휴대폰 GitHub 앱에서도 보이는 것, 그리고 그림 원본이 파일로 따로 남는 것이다.
아래 시나리오는 그림이 이미지로 바뀌었는지, 원본이 짝지어 있는지, README 검사가 그 규칙을 지키는지, 다른 검사 규칙은 그대로인지를 하나씩 본다.

## Test scenarios

### T1. 코어 README 에 머메이드 블록이 없고 그림 이미지가 있다

- **Setup**: 이 저장소.
- **Run**: README 3판에서 머메이드 블록 수와 `assets/diagrams/*.svg` 참조 수를 센다.
- **Expected**: 판마다 머메이드 0, 이미지 2 이상.
- **Pass criterion**: `tools/check-readme.sh --profile core .` 가 OK 로 끝난다.

### T2. 이미지마다 같은 이름의 원본(.mmd)이 있다

- **Setup**: 이 저장소.
- **Run**: README 검사.
- **Expected**: 참조된 SVG 마다 같은 경로 · 이름의 `.mmd` 가 있다.
- **Pass criterion**: 검사 출력에 원본 빠짐 ✖ 없음.

### T3. 검사가 원본 빠짐 · 이미지 모자람을 잡는다

- **Setup**: 시험이 README 사본을 만들어 (a) `.mmd` 하나를 지우고, (b) 이미지 참조를 하나만 남긴다.
- **Run**: `bash tests/test-check-readme.sh`
- **Expected**: (a) · (b) 사본 모두 검사가 빨갛게 실패하고, 원본은 초록.
- **Pass criterion**: 시험 통과.

### T4. 다른 검사 규칙은 그대로다

- **Setup**: 기존 깨진 사본 8개(명령 · 설정 · 링크 · 주제 · 그림 · 언어판).
- **Run**: `bash tests/test-check-readme.sh`
- **Expected**: 기존 8개 사본은 여전히 빨갛다. scv-mods 프로필 규칙(mermaid 1, seq /scv-mirror)은 바뀌지 않았다.
- **Pass criterion**: 시험 통과, `diagrams()` 의 mods 줄 변화 없음.

### T5. 이미지가 실제로 그림이다

- **Setup**: 뽑은 SVG 6개.
- **Run**: 각 SVG 가 `<svg` 로 시작하고 원본의 노드 글자(예: 루프 그림의 'Regression')를 담는지 본다.
- **Expected**: 모두 유효한 SVG, 노드 글자 포함.
- **Pass criterion**: 6개 모두 만족.

### T6. 휴대폰에서 보인다

- **Setup**: 코어 main 반영 뒤.
- **Run**: 사용자가 GitHub 휴대폰 앱에서 코어 README 를 연다.
- **Expected**: 루프 · 구조 그림이 코드가 아니라 그림으로 보인다.
- **Pass criterion**: 사용자 확인.

## How to run

```bash
bash tests/test-check-readme.sh && bash tools/check-readme.sh --profile core .
```

## Pass criteria

- T1–T5 자동 통과, T6 사용자 확인. 두 래퍼는 코어 릴리스 뒤 같은 검사(`--profile claude` · `--profile codex`)로 확인한다.

## Related Documents

- `tools/check-readme.sh`
