# Test Plan — 증적 영상은 사람 속도로

## Overview

임계 판독(기본 4·양의 정수만·이상값 폴백), ffprobe 기반 길이 측정과 경고
(짧으면 한 줄, 같거나 길면 침묵, ffprobe 없으면 건너뜀), pr-helper 연결,
설정 키 등록을 확인한다.

## Test scenarios

### T1. 임계 판독 (test-evidence-pacing.sh)
- **Expected**: 기본 4 · `SCV_EVIDENCE_MIN_SECONDS=7` → 7 · `abc`/`0`/`-3` → 4.

### T2. 길이 측정 + 경고 (test-evidence-pacing.sh, ffmpeg 있을 때만)
- **Setup**: ffmpeg 로 1초짜리 무음 webm 생성.
- **Expected**: 기본 임계(4) → `evidence:` + `shorter than` 경고, exit 0.
  임계 1 → 경고 없음. 존재하지 않는 파일 → 무경고·exit 0.

### T3. pr-helper 연결 (test-evidence-pacing.sh, ffmpeg 있을 때만)
- **Setup**: 임시 저장소 + 실행 기록에 1초 영상, `pr-helper --dry-run`.
- **Expected**: stderr 에 `evidence:` 경고 1줄, dry-run 출력은 기존 형식 그대로.

### T4. ffprobe 부재 → 조용히 건너뜀 (test-evidence-pacing.sh)
- **Setup**: PATH 에서 ffprobe 를 가린 채 warn 호출.
- **Expected**: 출력 없음, exit 0.

### T5. 키 등록 (test-evidence-pacing.sh)
- **Expected**: `SCV_PLAIN_KEYS` 에 SCV_EVIDENCE_MIN_SECONDS, 비밀 목록엔
  없음, 예시 파일 `_doc` + `"SCV_EVIDENCE_MIN_SECONDS": "4"`.

### T6. 기존 계약 불변
- **Run**: `bash core/tests/test-pr-notify.sh`
- **Expected**: green — 알림·PR 동작에 영향 없음.

## How to run

```bash
bash core/tests/test-evidence-pacing.sh && bash core/tests/test-pr-notify.sh
```

## Pass criteria

- 두 테스트 파일 모두 실패 0 (ffmpeg 없는 환경에서는 T2·T3 이 skip 으로 green).
