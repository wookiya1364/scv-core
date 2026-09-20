# 회귀 실행기가 프로젝트 언어 설정을 자식 검사에 흘린다 + 낡은 보관 계약 둘

> **처리됨 (2026-09-20, rule-constitution 작업 중 사용자 지시로).** ① env_load 가 새로 내보낸 키를 SCV_ENV_LOADED_KEYS 에
> 적고 실행기가 자식에서 지운다(test-regression-env T7). ② 래퍼 체크아웃 둘을 origin 최신으로 옮김. ③ 계약 둘 obsolete 표시.
> 이 메모는 근거 기록으로 남긴다. 남은 후속: 실행기 누출 검사를 다른 설정 키에도 넓힐지(현재는 env_load 가 내보낸 전부).

20260920 rule-constitution 보관 전 누적 회귀(58 슬러그)에서 17개가 붉었다. 전부 이번 변경과 무관함을
각각 재현으로 확인했다. 원인은 셋.

## 1. 실행기의 SCV_LANG 누출 (실행기 버그, 새 설정 파일과 만나 드러남)

- 재현: 이 저장소 안에서 임시 슬러그로 `env` 를 덤프하면 자식 환경에 `SCV_LANG=korean` 이 더 들어 있다.
  임시 프로젝트(설정 파일 없음)에서는 없다. 이 저장소의 `scv/scv_settings.json` 은 오늘 자동 생성됐다
  (SCV_LANG=korean) — 그래서 어제까지는 안 보였다.
- 영향: 아카이브 계약이 "영어 기본값" 을 전제하는 검사들이 실행기 안에서만 붉다.
  - `test-deck-doc.sh` (English default 9건) → deck-redesign · numbered-spec-deck · deck-picture-only
  - `test-settings.sh` (일반 설정 두 번째 expected japanese got korean 등) → regression-contract-repair-2 · settings-always-present
  - `run-dry.sh` (render-template english 라벨 2건) → journal-utf8-tail · run-dry-layout-guard · run-dry-anchor-diet · scv-own-graph · decision-index
- 확인: `SCV_LANG=korean bash core/tests/run-dry.sh` 가 같은 2건으로 붉다. 변수 없이는 960/0.
- 고칠 곳: 실행기가 자식에 넘기지 말아야 할 변수 목록(run_scenario_clean 의 `env -u …`)에 SCV_LANG 등
  설정에서 온 값을 더하거나, 설정을 실행기 자신만 읽고 export 하지 않게. 어느 쪽이든 픽스처 검사 하나:
  설정 파일이 있는 프로젝트에서 자식 env 에 SCV_LANG 이 없어야 한다.

## 2. 옆에 체크아웃된 래퍼 저장소의 옛 문서 (환경, 이 저장소 밖)

- `test-autosync.sh` T9w, `test-session-resume.sh` T12 는 `../scv-claude-code`, `../scv-codex` 가 있으면
  그 문서를 본다. 그 문서들이 아직 옛 상태. → regression-runner-env-leak · sync-autopilot · update-auto-refresh ·
  session-resume-recap · regression-runner-path-leak(test-regression-env 가 autosync 를 감쌈)
- 고칠 곳: 래퍼 저장소 두 곳의 문서. 이 저장소에서는 할 일 없음.

## 3. 낡은 보관 계약 — 지워진 테스트 파일을 가리킨다 (supersede 선언 누락)

- `20260823-wookiya1364-journal-index` → `core/tests/test-journal-index.sh` (f124557 "결정이 스스로 색인된다" 에서 삭제)
- `20260917-wookiya1364-deck-change-map` → `core/tests/test-timing-budget.sh` (git 이력에 없음 — 커밋된 적 없거나 같은 계획에서 제거)
- 규칙대로면 테스트를 지운 계획이 `supersedes:` 를 선언했어야 한다. 삭감에서 obsolete(수동) 또는 후속 계획의
  supersedes 로 정리.
