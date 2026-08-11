# TESTS — 가이던스 어블레이션 1단계

## Test scenarios

1. **마커 정합** — promote.md·work.md 의 모든 `SCV:GUIDANCE` 마커가 짝이
   맞고(열림/닫힘 대응), 중첩이 없다 (lint 스크립트).
2. **기본 모드 불변** — `SCV_GUIDANCE` 미설정 시 주입 내용이 분리 전 원문과
   바이트 동일하다 (마커 자체는 HTML 주석이라 렌더 불가시 — 주입 원문
   비교는 마커 포함 허용, 렌더 결과 기준 동일).
3. **minimal 필터** — `SCV_GUIDANCE=minimal` 주입 결과에 GUIDANCE 블록
   내용이 0건 포함되고, CONTRACT 부분은 전부 존재한다.
4. **어블레이션 동등성** — run-dry 의 promote·work 시나리오를 full/minimal
   두 모드로 실행 → 생성 파일 목록·frontmatter 스키마·스크립트 호출
   시퀀스가 동일하다. 차이 발생 시 테스트 실패(재분류 강제).
5. **잘못된 마커 fail-closed** — 닫힘 누락 마커를 가진 픽스처에서 주입
   필터가 명확한 에러로 중단하고, 침묵 속 부분 주입을 하지 않는다.
6. **다른 12개 프로토콜 무변** — promote·work 외 프로토콜 파일이 이 계획
   에서 바이트 불변이다 (git diff 검증).
7. **deck 비노출** — 마커가 포함된 md 를 deck 으로 빌드해도 마커 텍스트가
   렌더 출력에 나타나지 않는다.

## How to run

```bash
bash core/tests/run-dry.sh          # full/minimal 이중 실행 포함
for t in core/tests/test-*.sh; do bash "$t"; done
bash tests/run.sh
```

## Pass criteria

- 시나리오 7건 커버·통과, 기존 스위트 무회귀
- CHANGELOG 에 CONTRACT/GUIDANCE 분류 비율 보고
