# Test Plan — Graft 어댑터 — 있으면 코드 영향 범위와 관련 코드 후보를 덧붙이고, 없으면 조용히 생략

## Overview

graft 가 없는 환경(CI 포함)에서 아무것도 달라지지 않음을, 있는 환경(가짜 graft 픽스처)에서 상태·blast 요약·ask 후보·소비처 블록·실패 처리가 계약대로임을 본다. 픽스처는 PATH 앞에 두는 `graft` 셸 스크립트 두 벌(정상 JSON · 깨진 JSON/느림).

## Test scenarios

### T1. 상태 판정 (순수)
- **Setup**: lib source.
- **Run**: scv_graft_status 에 (has_bin, has_graph, switch) 여덟 조합.
- **Expected**: switch=off → off · bin 없음 → absent · bin 있음·graph 없음 → no-graph · 둘 다 → ready.
- **Pass criterion**: 표 전부 일치.

### T2. blast 요약 (결정적)
- **Setup**: 픽스처 JSON — 파일 3개·심볼 7개(파일별 4/2/1), 다른 모양(필드 없음), 빈 객체.
- **Run**: scv_graft_blast_summary
- **Expected**: "3\x1f7\x1fa.ts:4 b.ts:2 c.ts:1" · 모양 다름 → "?\x1f?\x1f" + 원문 크기 표시 · 빈 객체 → 0/0.
- **Pass criterion**: 정확 일치.

### T3. ask 요약 (결정적)
- **Setup**: 픽스처 JSON — 후보 12개(점수 내림차순 아님).
- **Run**: scv_graft_ask_summary <json> 10
- **Expected**: 점수 내림차순 상위 10, `path:line\x1flabel`. 후보 0 → 빈 출력.
- **Pass criterion**: 정확 일치.

### T4. graft 없음
- **Setup**: PATH 에 graft 없음, 임시 프로젝트.
- **Run**: graft.sh status · blast · ask "x" · work.sh <slug> · promote-helper --dry-run · regression --dry --changed a
- **Expected**: `GRAFT_STATUS: absent` (status) · blast/ask 빈 출력 exit 0 · work/promote 헤더에 `GRAFT_STATUS: absent` 한 줄만, 후보 블록 없음 · regression 출력에 graft 블록 없음.
- **Pass criterion**: 다섯 출력.

### T5. graft 있음, 그래프 없음
- **Setup**: 가짜 graft(PATH), `graft/` 폴더 없음.
- **Run**: graft.sh status · blast
- **Expected**: `GRAFT_STATUS: no-graph`, blast 빈 출력, 가짜 graft 가 호출되지 않았다(호출 로그 파일 없음).
- **Pass criterion**: 세 조건.

### T6. ready — blast 블록
- **Setup**: 가짜 graft(정상 JSON) + `graft/` 폴더 + git 저장소(origin/main 없음).
- **Run**: regression.sh --dry --changed a.ts
- **Expected**: `=== impact (scv graph) ===` 다음에 `=== impact (graft blast) ===` 블록 — 파일 수·심볼 수·상위 파일. 가짜 graft 호출 로그에 `blast --base HEAD --depth all --format json`.
- **Pass criterion**: 순서·내용·호출 인자.

### T7. ready — ask 후보 블록
- **Setup**: T6 환경 + 계획 하나.
- **Run**: work.sh <slug> · promote-helper.sh --dry-run
- **Expected**: `GRAFT_STATUS: ready` + `=== code candidates (graft ask) ===` 블록에 file:line 줄 ≤10. 호출 로그에 `ask "<계획 제목>" --json`.
- **Pass criterion**: 두 출력.

### T8. 실패 처리
- **Setup**: 깨진 JSON 을 내는 가짜 graft · 30초 잠자는 가짜 graft(타임아웃 2초로 설정).
- **Run**: graft.sh blast · ask
- **Expected**: 둘 다 빈 출력 + stderr 한 줄, exit 0, 소비처는 그대로 진행. 타임아웃은 3초 안에 끝난다.
- **Pass criterion**: 종료 코드·시간.

### T9. 스위치·안내
- **Setup**: SCV_GRAFT=off + 가짜 graft ready 환경.
- **Run**: graft.sh status · install-deps.sh --print · --check
- **Expected**: `GRAFT_STATUS: off`, 호출 없음. --print 에 graft 안내 한 줄(--no-hooks --no-statusline · telemetry disable 포함), --check 는 graft 를 세지 않는다(exit 코드 불변).
- **Pass criterion**: 세 조건.

### T10. 기존 검사 회귀 없음
- **Setup**: 없음
- **Run**: 코어 검사 전체 · run-dry · tests/run.sh · 호스트 중립 검사
- **Expected**: 전부 녹색.
- **Pass criterion**: 실패 0.

## How to run

```bash
bash core/tests/test-graft-adapter.sh
```

## Pass criteria

- T1~T10 전부 녹색.
- graft 없는 CI 에서 출력 차이는 `GRAFT_STATUS: absent` 한 줄뿐.

## Related Documents

- core/tests/test-graph.sh — 임시 프로젝트·픽스처 방식(재사용)
