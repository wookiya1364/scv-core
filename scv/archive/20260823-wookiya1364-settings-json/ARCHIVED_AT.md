---
archived_at: 2026-08-23
archived_by: wookiya1364
reason: "1·2·3단계 전부 완료. test-settings 58건, run-dry 973 PASS/0 FAIL(기준선 972 + 설치 검사 1), tests/run.sh 통과, core/tests 24개 실패 0. T12(래퍼 두 곳)는 core 벤더링이 필요해 이 저장소 범위 밖으로 남긴다."
---

# Archive record

This plan was archived on 2026-08-23.

## Reason

- 설정이 `scv/scv_settings.json` 과 `scv/scv_settings.secret.json` 두 벌로 옮겨졌다.
  프로젝트 루트의 `.env` 는 더 이상 읽지 않는다.
- 계획 수립 이후 계약이 둘 바뀌었다(사용자 결정):
  - `.env` 되돌아가기를 없앴다. 대신 이사가 안 됐으면 한 액션에 한 번 알린다.
  - 업데이트가 사용자 설정을 바꾸지 않는다 — 없는 키만 더한다.
- 기존 테스트가 실제 결함을 하나 잡았다: 설치가 빈 설정 파일을 만들면 그 존재만으로
  "이사 완료" 로 판정되어 기존 프로젝트가 설정을 잃는다. 설정 파일은 사용자
  데이터지 템플릿 뼈대가 아니다.

## 남은 일

- **T12 — 래퍼 두 곳(scv-claude-code, scv-codex) 반영.** core 를 벤더링해야
  실제 사용자에게 도달한다. 각 래퍼 저장소의 작업이다.
- **CHANGELOG.** 이 저장소는 릴리스 커밋에서 쓰는 방식이라 미뤘다.
- **템플릿 버전.** 올리지 않았다. 갱신을 이제 내용 지문으로 판단하므로 번호를
  올리지 않아도 전달된다.
