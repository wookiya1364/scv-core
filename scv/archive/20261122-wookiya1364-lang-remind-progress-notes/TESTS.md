# Test Plan — 도구 뒤 언어 알림 중복

## Test scenarios

### T15. 생각 항목에 남은 중간 보고
- **Run**: 마지막으로 쓴 묶음(이어진 글 · 생각 항목)이 한국어 생각뿐인 기록 · 영어 생각뿐인 기록 · 한국어 생각 뒤 도구를 둘 연달아 부른 기록으로 도구 뒤 훅을 부름.
- **Pass criterion**: 첫째 · 셋째 알림 없음, 둘째 알림.

## How to run

```bash
bash core/tests/test-lang-enforce.sh
```

관련 시험: `core/tests/test-slow-pure-functions.sh` · `core/tests/test-purity.sh` · `core/tests/test-pure-catalog.sh` · `core/tests/test-hook-dedupe.sh`.

## Pass criteria

- T1–T15 ok, 종료 코드 0 (mac · linux).
