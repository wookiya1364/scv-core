# Test Plan — PR 을 만들면 증적이 Slack 에도 간다

## Overview

PR 생성/갱신 성공 후, 알림 채널이 설정된 프로젝트에서 slug 증적(성공 포함)이
게시되는지 — 기본 on·off 만 끔·provider 미설정 무동작·실패 무해(best-effort)·
dry-run 존중 — 확인한다. 기존 pr-helper·첨부 계약은 그대로 green.

## Test scenarios

### T1. 기본 on + provider + dry-run — 게시된다 (test-pr-notify.sh)
- **Setup**: 임시 git 저장소(archive/<slug>/PLAN+TESTS, github origin), 실행
  기록 + 영상 1·스크린샷 1, 가짜 gh(PR 생성), 설정: NOTIFIER_PROVIDER=slack +
  SLACK_BOT_TOKEN/CHANNEL_ID(가짜) + NOTIFIER_DRY_RUN=1.
- **Run**: `pr-helper.sh <slug> --no-push --no-rerun`
- **Expected**: `PR created:` 이후 stderr 에 `pr-notify: upload` 2건과
  `pr-notify: done (2 file(s))`, DRY_RUN 페이로드에 PR URL 포함. exit 0.

### T2. off 만 끈다 (test-pr-notify.sh)
- **Setup**: T1 + `SCV_PR_NOTIFY=off`.
- **Expected**: `pr-notify:` 로그 없음, PR 은 정상 생성.

### T3. provider 미설정 → 조용히 건너뜀 (test-pr-notify.sh)
- **Setup**: T1 에서 NOTIFIER_PROVIDER 제거.
- **Expected**: `pr-notify:` 로그 없음, 오류 없음, exit 0.

### T4. 검증 실패 → 경고 한 줄, PR 은 무사 (test-pr-notify.sh)
- **Setup**: provider=slack, 토큰 없음, dry-run 아님.
- **Expected**: `pr-notify:` 경고(continuing) 1줄, exit 0, `PR created:` 출력.

### T5. 키 등록 (test-pr-notify.sh)
- **Expected**: `SCV_PLAIN_KEYS` 에 SCV_PR_NOTIFY, 비밀 목록에는 없음, 예시
  파일에 `_doc` 설명 + `"SCV_PR_NOTIFY": "on"`.

### T6. 기존 계약 불변 (기존 파일 그대로)
- **Run**: `bash core/tests/test-run-manifest.sh` ·
  `bash core/tests/test-attachments-scope.sh`
- **Expected**: 전부 green.

## How to run

```bash
bash core/tests/test-pr-notify.sh && bash core/tests/test-run-manifest.sh && bash core/tests/test-attachments-scope.sh
```

## Pass criteria

- 세 테스트 파일 모두 실패 0. T1 의 파일 2건·T4 의 경고 문자열까지 검증.
