# Test Plan — .env.example.scv 자동 최신화 — root 불가침의 명명된 예외

## Overview

sync 가 루트 `.env.example.scv` 를 갱신·재생성하되, 사용자의 되돌릴 수 없는
수정은 거부하고, `.env` 와 다른 루트 파일에는 손대지 않음을 검증한다. 모든
시나리오는 실제 git 저장소 픽스처에서 sync.sh 를 직접 실행해 판정한다 (스텁 금지 —
기존 test-sync-dirty.sh 관례).

## Test scenarios

### T1. 낡은 예시 파일이 최신으로 교체된다

- **Setup**: 픽스처 프로젝트에 구버전 `.env.example.scv` (커밋됨, 작업 트리 clean).
- **Run**: sync 실행.
- **Expected**: 파일 내용이 `core/template/.env.example.scv` 와 바이트 일치.
- **Pass criterion**: diff 무차이 + sync 가 갱신을 보고.

### T2. 미커밋 수정은 DIRTY 거부되고 스탬프가 멈춘다

- **Setup**: `.env.example.scv` 에 커밋되지 않은 로컬 수정 (HEAD 복원 불가).
- **Run**: sync 실행.
- **Expected**: 파일 무변경, DIRTY 로 파일명이 지목됨, PARTIAL 보고,
  TEMPLATE_VERSION 스탬프 미전진.
- **Pass criterion**: 수정 내용 보존 + 스탬프 값 이전과 동일.

### T3. 커밋된 커스텀은 교체된다 (git 이력 복구 가능)

- **Setup**: 커스텀 내용을 커밋한 `.env.example.scv` (작업 트리 clean).
- **Run**: sync 실행.
- **Expected**: 최신 템플릿으로 교체됨 (HEAD 가 복원 가능하므로 거부 아님).
- **Pass criterion**: 교체 후 `git show HEAD:.env.example.scv` 로 이전 내용 복구 가능.

### T4. 파일이 없으면 재생성한다

- **Setup**: `.env.example.scv` 가 없는 픽스처 (삭제됨 또는 애초 부재).
- **Run**: sync 실행.
- **Expected**: 최신 템플릿으로 파일 생성.
- **Pass criterion**: 파일 존재 + 템플릿과 바이트 일치.

### T5. .env 는 어떤 경우에도 불변이다

- **Setup**: 값이 채워진 `.env` 가 있는 픽스처 (T1~T4 각 상황 재사용).
- **Run**: sync 실행.
- **Expected**: `.env` 의 mtime·내용 모두 무변경.
- **Pass criterion**: 실행 전후 `.env` 해시 동일.

### T6. scv/ 심볼링크면 같이 건너뛴다

- **Setup**: `scv/` 가 심볼링크인 픽스처 + 구버전 `.env.example.scv`.
- **Run**: sync 실행.
- **Expected**: 템플릿 패스 전체가 WARN 하나로 스킵 — `.env.example.scv` 도 무변경.
- **Pass criterion**: 파일 내용 이전과 동일 + WARN 출력 존재.

### T7. 루트의 다른 파일은 만들지도 고치지도 않는다

- **Setup**: 루트에 사용자 파일 여러 개가 있는 픽스처.
- **Run**: sync 실행.
- **Expected**: `.env.example.scv` 외 루트 파일 무변경, 새 루트 파일 미생성.
- **Pass criterion**: 실행 전후 루트 디렉토리 목록·해시 비교에서 차이는
  `.env.example.scv` 하나뿐.

### T8. --force 는 DIRTY 를 오버라이드한다

- **Setup**: T2 와 동일 (미커밋 수정).
- **Run**: sync 를 `--force .env.example.scv` 로 실행.
- **Expected**: 수정을 버리고 최신 템플릿으로 교체.
- **Pass criterion**: 템플릿과 바이트 일치.

### T9. 거부 해소 후 재시도에서 스탬프가 전진한다

- **Setup**: T2 실행 후 로컬 수정을 커밋(또는 되돌림)한 픽스처.
- **Run**: sync 재실행.
- **Expected**: 파일 갱신 + TEMPLATE_VERSION 스탬프 전진, PARTIAL 해제.
- **Pass criterion**: 스탬프가 payload 의 TEMPLATE_VERSION 과 일치.

### T10. 미채택·pre-2.x 프로젝트는 autosync 가 건드리지 않는다

- **Setup**: (a) scv/ 없는 미채택 픽스처, (b) pre-2.x 스탬프 픽스처, 각각 구버전
  `.env.example.scv` 포함.
- **Run**: autosync 경로(scv_autosync) 트리거.
- **Expected**: 두 픽스처 모두 `.env.example.scv` 무변경.
- **Pass criterion**: 실행 전후 해시 동일.

## How to run

```bash
bash core/tests/test-sync-env-example.sh
```

## Pass criteria

- T1~T10 전부 통과.
- 기존 `core/tests/test-sync-dirty.sh`·`core/tests/test-autosync.sh` 가 무수정으로
  계속 통과 (회귀 없음).

## Related Documents
