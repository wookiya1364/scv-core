# Test Plan — PR·보고 첨부는 이번 슬러그 것만

## Overview

새 라이브러리의 모드·필터·추론, PR 헬퍼의 슬러그 한정 수집(+재실행·dry-run 출력),
보고 수집기의 슬러그 한정, `all` 모드의 옛 동작 보존, 템플릿·프로토콜 문구를
확인한다. 실제 PR 에 붙는 영상 확인은 배포 후 수동 1건.

## Test scenarios

### T1. lib — 모드 읽기·필터·추론 (`core/tests/test-attachments-scope.sh`)
- 모드: 환경변수 > .env > 기본 slug; `all` 만 all, `ALL`/빈값/이상값 처리 명시.
- 필터: 슬러그 포함 경로만 통과, `all` 이면 전부.
- 추론: 명시 슬러그 > 진행 중 계획 1개 > 빈 문자열(여럿/0개).
- **Pass criterion**: 스위트 전량 통과

### T2. PR 헬퍼 — 슬러그 한정 + 재실행 + dry-run 줄
- **Setup**: 임시 프로젝트(git, archive 슬러그 A 의 TESTS How-to-run 이 test-results 에
  A 영상 1개를 만드는 명령), test-results 에 남의 슬러그 B 영상·스크린샷만 존재.
- **Run**: `pr-helper.sh A --dry-run` (slug 모드)
- **Expected**: `ATTACHMENTS_SCOPE: slug` 줄, `ATTACHMENTS_FILES:` 에 B 파일 없음;
  dry-run 이라 재실행 없음(A 영상 없음 → 0건 알림 줄). `SCV_ATTACHMENTS_SCOPE=all` 이면
  B 파일이 목록에 있다. 재실행 경로는 라이브러리의 함수 단위로 검증(블록 추출·1회 실행).
- **Pass criterion**: 스위트 통과

### T3. 보고 수집기 — 슬러그 한정·추론·폴백
- **Expected**: `SCV_ATTACHMENTS_SLUG=A` 면 A 의 최신 파일만; 슬러그 없고 진행 중 계획이
  A 하나면 A; 여럿이면 전부 + stderr 알림; `all` 이면 옛 동작.
- **Pass criterion**: 스위트 통과

### T4. 템플릿·프로토콜·스코프·스위트
- **Expected**: `.env.example.scv` 에 `# SCV_ATTACHMENTS_SCOPE=slug`, work.md 와 report.md
  에 `SCV_ATTACHMENTS_SCOPE` 언급, report.md 에 `--slug`, 액션 15, run-dry·tests/run.sh·
  core/tests 전량 exit 0.
- **Pass criterion**: `ALL GATES OK`

## How to run

```bash
bash -euo pipefail -c '
fail() { echo "FAIL: $1"; exit 1; }
bash core/tests/test-attachments-scope.sh >/dev/null || fail "T1–T3 test-attachments-scope"
grep -q "^# SCV_ATTACHMENTS_SCOPE=slug" core/template/.env.example.scv || fail "T4 .env 예시"
grep -qF "SCV_ATTACHMENTS_SCOPE" core/protocols/work.md || fail "T4 work.md"
grep -qF "SCV_ATTACHMENTS_SCOPE" core/protocols/report.md || fail "T4 report.md"
grep -qF -- "--slug" core/protocols/report.md || fail "T4 report.md --slug"
[ "$(jq -r ".actions | length" core/actions.json)" -eq 15 ] || fail "T4 액션 수"
echo "OK [T1-T4 anchors]"
bash core/tests/run-dry.sh >/dev/null || fail "T4 run-dry"
bash tests/run.sh >/dev/null || fail "T4 tests/run.sh"
for t in core/tests/test-*.sh; do bash "$t" >/dev/null || fail "T4 $t"; done
echo "ALL GATES OK"
'
```

## Pass criteria

- 위 블록 exit 0. 배포 후 수동 1건: 회귀 → PR 에서 영상이 이번 슬러그 것뿐.

## Related Documents

- 원재료: `scv/raw/stale/20260821-wookiya1364-slug-scoped-attachments.md`
