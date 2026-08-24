# 회귀 계약 보수 2 — 설정 이사(0.32.0) 뒤 남은 옛 계약 7건

## 실측 (2026-08-24, develop, 0.34.0 작업 직전)

누적 회귀 24 실행 / 17 통과 / 7 실패 — 제 변경과 무관하게 이미 빨간불.

- `.env` 기반 옛 계약 4건: plain-answers-enforcement(T3 .env off), plain-sentence-cap(T2 .env cap),
  slug-scoped-attachments(T4 .env.example.scv 블록), env-example-autorefresh(test-sync-env-example.sh
  삭제됨) — 0.32.0 이 `.env` 를 읽지 않게 하고 `.env.example.scv` 를 제거하면서 성립 불가.
- regression-runner-path-leak: T2 가 plain-answers-enforcement 를 러너 안에서 돌려 같은 이유로 실패.
- settings-json / template-refresh(0.32.0): How-to-run 이 없는 파일을 부른다 —
  core/tests/test-settings-pure.sh, test-settings-file.sh, test-autosync-digest.sh, core/tests/run.sh
  (실제: test-settings.sh, test-template-digest.sh, test-autosync.sh, tests/run.sh) → exit 127.

## 원하는 동작

0818 보수와 같은 방식: 옛 계약은 frontmatter 3필드로 obsolete 표시(본문 불변), 살아 있어야 할
검증은 새 계약(이 플랜의 TESTS)으로 실제 파일 이름으로 다시 적는다. 이후 누적 회귀 0 실패.
