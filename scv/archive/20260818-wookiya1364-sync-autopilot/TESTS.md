# Test Plan — sync 자동화와 가드 실효 회복

## Overview

세 갈래를 검증한다: sync 의 새 안전장치(더티 거부), 액션 시작 시 자동 최신화의
동작과 가드레일, 그리고 가드 실효 버그 5건의 수정. 전부 동작으로 검사한다 — 이번
버그들 대부분이 "문장으로는 맞게 읽히는 코드"였고, 그중 둘은 무력한 테스트 뒤에
숨어 있었다. 각 수정마다 옛 코드에서 실패하는 회귀 케이스를 요구한다.

## Test scenarios

### T1. sync 는 더 이상 사본을 만들지 않는다

- **Setup**: 임시 git 프로젝트, 수화 완료, 템플릿과 다른 내용의 scv 문서 몇 개를
  **커밋해 둔 상태**
- **Run**: `sync.sh --project-dir`
- **Expected**: 파일은 갱신되고 `.scv-backup/` 은 생기지 않는다. "Backups:" 줄 없음
- **Pass criterion**: `[[ ! -e .scv-backup ]]` 그리고 출력에 `Backups` 부재

### T2. 커밋 안 된 변경이 있는 파일은 건너뛰고 이름을 말한다

- **Setup**: T1 프로젝트에서 SCV 소유 문서 하나를 수정하고 커밋하지 않음
- **Run**: sync
- **Expected**: 그 파일은 바뀌지 않고 `DIRTY` 로 보고된다. 다른 파일은 정상 갱신
- **Pass criterion**: 파일 내용 불변 + 보고에 파일명 등장. `--force <그 파일>` 로
  재실행하면 덮어쓴다

### T3. 추적 안 된 파일과 git 없는 환경은 더티로 취급한다

- **Setup**: (a) 템플릿과 다른 내용의 미추적 scv 문서, (b) `.git` 없는 프로젝트
- **Expected**: 둘 다 해당 파일을 건너뛰고 이유를 보고한다
- **Pass criterion**: 내용 불변. 동일 내용 파일은 여전히 조용히 skip (cmp 우선)

### T4. 낡은 스탬프는 다음 액션에서 자동으로 메워진다

- **Setup**: 수화된 git 프로젝트, `SCV.md` 스탬프를 `2.0.0` 으로 되돌림
- **Run**: `scv_init_paths` 를 쓰는 액션 헬퍼 하나 (예: `status.sh`)
- **Expected**: sync 가 자동 실행되고 한 줄 보고, 스탬프가 payload 버전으로 갱신
- **Pass criterion**: 실행 후 스탬프 == `TEMPLATE_VERSION`. **같은 헬퍼를 한 번 더
  돌리면 sync 가 다시 돌지 않는다** (수렴 — 출력에 autosync 줄 부재)

### T5. 자동 최신화의 가드레일

- **Setup/Expected**:
  - (a) 미수화 디렉터리(빈 scv/) → 자동 sync 안 돎, 파일 생성 0
  - (b) 스탬프 unknown(pre-2.x 레거시 흉내: SCV.md 없음 + PROMOTE.md 있음) →
    자동 sync 안 돎, 한 줄 안내만
  - (c) `SCV_AUTOSYNC=off` → 안 돎
  - (d) `SCV_AUTOSYNC_RUNNING=1` → 안 돎 (재귀 가드)
- **Pass criterion**: 네 경우 모두 트리 변경 없음. (b)는 안내 문구 존재

### T6. 자동 sync 실패는 액션을 막지 않는다

- **Setup**: 스탬프 낡음 + sync 가 실패하도록 만든 환경(payload 템플릿 디렉터리
  제거 등)
- **Expected**: 경고 한 줄 후 액션 헬퍼는 정상 종료
- **Pass criterion**: 헬퍼 exit 0, stderr 에 경고 존재

### T7. 자동 sync 는 워크플로 내용물을 만지지 않는다

- **Setup**: raw/promote/archive/conversations 에 파일이 있는 낡은 스탬프 프로젝트
- **Run**: 자동 sync 발화
- **Expected**: 그 네 디렉터리의 파일 내용·목록이 바이트 그대로
- **Pass criterion**: 실행 전후 해시 목록 동일

### T8. SCV_GUARD_SCRIPTS 가 콜론 목록을 받는다

- **Setup**: 두 디렉터리 A·B, `SCV_GUARD_SCRIPTS="A:B"`, gate-bash
- **Expected**: A 의 스크립트를 부르는 명령도 B 의 것도 영수증을 발급한다.
  둘 다 아닌 명령은 발급하지 않는다
- **Pass criterion**: 세 경우 각각 영수증 파일 유/유/무. **옛 guard.sh 에 같은
  픽스처를 돌리면 B 케이스가 실패한다** (회귀 증명)

### T9. 단일 값 동작은 그대로다

- **Setup**: 기존 형식 `SCV_GUARD_SCRIPTS="A"`
- **Expected**: 기존과 동일하게 발급/비발급
- **Pass criterion**: 기존 test-guard.sh 관련 케이스 전부 통과 유지

### T10. 사용 불가 저장소의 거부 사유가 원인을 이름 붙인다

- **Setup**: `SCV_GUARD_STATE` 를 만들 수 없는 경로로, gate-write, 비면제 대상
- **Expected**: 거부는 유지되(닫힘) 사유에 저장소 경로와 `SCV_GUARD_STATE` 가
  들어간다. "액션을 실행하라"는 무익한 안내가 아니다. mint 모드는 stderr 한 줄
- **Pass criterion**: deny JSON 의 reason 에 경로 문자열 포함. **옛 guard.sh 는
  일반 사유를 내므로 이 단언이 실패한다** (회귀 증명)

### T11. T15 가 실제로 판정한다

- **Setup**: 수정된 test-guard.sh 의 해당 케이스가 비면제 경로를 쓴다
- **Expected**: 가드의 저장소 처리 동작이 바뀌면 케이스가 빨개진다
- **Pass criterion**: 케이스 대상 파일이 `*.md`/면제류가 아니다 (검사로 강제)

### T12. T21 이 두 스크립트를 직접 비교한다

- **Setup**: 수정된 T21
- **Expected**: guard.sh 와 check-provenance.sh 의 면제 집합 공통 4종
  (`*.md`·`.gitignore`·`.gitattributes`·`LICENSE`)이 양쪽에 있음을 단언한다.
  계획 문서 존재 여부와 무관하게 **항상 실행**된다
- **Pass criterion**: 한쪽 스크립트에서 항목 하나를 지운 사본에 돌리면 실패한다

### T13. 래퍼 배치에서도 test-guard.sh 가 돈다

- **Setup**: 임시 트리 `wrap/tests/test-guard.sh` + `wrap/vendor/scv-core/core/…`
  (cc 배치 흉내, 파일은 심볼릭 아닌 실제 복사)
- **Run**: `bash wrap/tests/test-guard.sh`
- **Expected**: 전 케이스 통과 (현재는 13건 실패)
- **Pass criterion**: exit 0. Core 배치(`core/tests/`)에서도 여전히 exit 0

### T14. 문서와 동작이 일치한다

- **Setup**: 변경 전체
- **Run**: `tests/test-guard-consistency.sh` + 문서 grep
- **Expected**: guard.md 의 실패 정책·mint 절, sync.md 의 백업 문장, update.md 5항,
  wrapper-integration.md 의 SCV_GUARD_SCRIPTS 서술이 전부 새 동작과 일치
- **Pass criterion**: consistency 4/4 + `.scv-backup` 이 sync.md 에서 사라짐

### T15. 전체 스위트가 초록이다

- **Run**: `tests/run.sh`, `core/tests/run-dry.sh`, `core/tests/test-*.sh`,
  `tests/test-host-neutral.sh`
- **Pass criterion**: 실패 0. 새 코드가 `core/` 호스트 중립성을 깨지 않는다

## How to run

```bash
bash core/tests/test-guard.sh && bash core/tests/test-autosync.sh && bash core/tests/test-sync-dirty.sh
```

## Pass criteria

- T1–T15 전부 통과
- 회귀 증명 3건(T8·T10·수렴 T4)이 옛 코드에서 실제로 실패한다
- 전체 스위트 실패 0, 릴리스 아티팩트에 변경 포함

## Related Documents

- [`PLAN.md`](./PLAN.md)
