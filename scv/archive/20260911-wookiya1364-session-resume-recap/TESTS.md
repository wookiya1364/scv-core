# Test Plan — 비운 뒤에도 이어진다 — 압축·/clear·재개 뒤 진행 상황 재주입

## Overview

세 축을 본다. (1) 새 훅이 켜진 프로젝트에서 진행 중 계획·최근 결정·활성 대화를 실제로
싣는가, (2) 꺼졌거나 SCV 를 쓰지 않는 프로젝트에서 **아무 것도** 내지 않고 막지도 않는가,
(3) 래퍼가 올바른 경우(압축·비움·재개)에만 등록했는가. 코어에서 볼 수 있는 것은 항상
검사하고, 래퍼 파일은 옆 체크아웃이 있을 때만 — 없으면 SKIP 이지 실패가 아니다.

## Test scenarios

### T1. 스위치 off — 빈 출력, exit 0

- **Setup**: 임시 프로젝트를 하이드레이트하고 진행 중 계획 하나를 둔다. `scv/scv_settings.json` 에 `SCV_RESUME_RECAP: "off"`.
- **Run**: `printf '{"source":"compact"}' | bash core/template/hooks/on-session-start.sh`
- **Expected**: stdout 이 바이트 단위로 비어 있고 종료 코드 0.
- **Pass criterion**: `[[ -z "$out" && $rc -eq 0 ]]`

### T2. 미하이드레이트 — 빈 출력, exit 0

- **Setup**: `scv/` 가 없는 임시 디렉터리.
- **Run**: 같은 명령.
- **Expected**: 빈 stdout, exit 0.
- **Pass criterion**: 위와 같음.

### T3. 진행 중 계획이 실린다

- **Setup**: 하이드레이트 + `scv/promote/20260911-x-demo/PLAN.md` (title "데모 계획", status planned). 스위치 기본(키 없음).
- **Run**: `printf '{"source":"clear"}' | bash …/on-session-start.sh`
- **Expected**: 출력에 `[SCV resume]` 표식, `20260911-x-demo`, `데모 계획` 이 있다.
- **Pass criterion**: 세 문자열 모두 grep 됨.

### T4. 최근 결정 5건이 실린다

- **Setup**: `decisions-append.sh` 로 결정 6건을 기록(색인 생성됨).
- **Run**: 같은 명령.
- **Expected**: 가장 최근 5건의 제목이 있고, 가장 오래된 1건은 없다.
- **Pass criterion**: 5건 grep 성공, 1건 grep 실패.

### T5. 활성 대화 1건 — 전문, 가장 최근 것만

- **Setup**: `scv/conversations/` 에 파일 셋 — (a) status promoted, (b) status active (오래됨), (c) status active (최근). (c) 본문에 고유 문장 "CONV-C-BODY" 와 여러 턴.
- **Run**: 같은 명령.
- **Expected**: (c) 의 경로와 본문 전체(모든 턴)가 실린다. (b) 는 경로만 한 줄, (a) 는 아예 없다.
- **Pass criterion**: `CONV-C-BODY` 와 (c) 의 마지막 턴 표제가 있음; (b) 경로 1회, (b) 본문 없음; (a) 경로 없음.

### T6. 대화 디렉터리가 없어도 recap 은 실린다

- **Setup**: 하이드레이트 + 계획 하나, `scv/conversations/` 없음.
- **Run**: 같은 명령.
- **Expected**: 계획 slug 가 실리고, stderr 에 오류 없이 exit 0.
- **Pass criterion**: slug grep 성공, rc 0.

### T7. 머리말이 비워진 이유를 말한다

- **Setup**: 하이드레이트 + 계획 하나.
- **Run**: source 를 `compact` / `clear` / `resume` / 필드 없음 네 가지로 실행.
- **Expected**: 앞 셋은 머리말에 그 값이 그대로 들어 있고, 넷째는 일반 머리말(값 없음)이며 실패하지 않는다.
- **Pass criterion**: 각각 grep 결과가 기대와 같다.

### T8. 잘못된 stdin 도 막지 않는다

- **Setup**: 하이드레이트 + 계획 하나.
- **Run**: `printf 'not json' | bash …/on-session-start.sh`
- **Expected**: 일반 머리말 + recap 이 실리고 exit 0.
- **Pass criterion**: slug grep 성공, rc 0.

### T9. 대화 본문은 가림 필터를 거친다

- **Setup**: 활성 대화 본문에 `token=abc123secret` 한 줄을 직접 써 넣는다(쓸 때 필터를 우회한 상황을 흉내).
- **Run**: 같은 명령.
- **Expected**: 출력에 `abc123secret` 이 없고 `[REDACTED]` 가 있다.
- **Pass criterion**: grep 으로 확인.

### T10. 아무 것도 쓰지 않는다

- **Setup**: T5 상태에서 `scv/` 전체의 체크섬을 기록.
- **Run**: 같은 명령을 두 번.
- **Expected**: 체크섬이 그대로다 (저널·결정·대화·설정 어디에도 변화 없음).
- **Pass criterion**: 전후 `find scv -type f | sort | xargs cksum` 동일.

### T11. 순수부 · 호스트 중립

- **Setup**: 없음.
- **Run**: `bash core/scripts/check-purity.sh` (또는 `core/tests/test-purity.sh`) 와 `tests/test-host-neutral.sh`.
- **Expected**: `lib/resume-recap.sh` 의 `@pure` 함수가 통과하고, 새 템플릿·순수부에 호스트 이름·이벤트 이름이 없다.
- **Pass criterion**: 두 검사 exit 0.

### T12. 래퍼 등록 — 압축·비움·재개에만 (옆 체크아웃 있을 때)

- **Setup**: `../scv-claude-code/hooks/hooks.json` 존재.
- **Run**: JSON 파싱.
- **Expected**: `SessionStart` 항목이 정확히 하나, matcher 가 `compact|clear|resume` (순서 무관, `startup`·`fork` 없음), 명령이 `on-session-start.sh` 를 가리키고 `SCV_CORE_ROOT` 를 내보낸다. 기존 항목(UserPromptSubmit·Stop·PreToolUse×3·UserPromptExpansion)은 그대로다.
- **Pass criterion**: 조건 전부 참. 체크아웃 없으면 SKIP.

### T13. 템플릿 지문

- **Run**: `bash core/scripts/compute-template-digest.sh --check core/TEMPLATE_DIGEST`
- **Expected**: 일치.
- **Pass criterion**: exit 0.

### T14. 설정 등록부

- **Run**: `settings.sh` 의 `SCV_PLAIN_KEYS` 에 `SCV_RESUME_RECAP` 이 있고, 예시 JSON 에 `_doc` 과 기본값 `"on"` 이 있다. 키가 없는 설정 파일에 `settings-ensure.sh` 를 돌리면 키가 더해지고 기존 값은 바이트 단위로 보존된다.
- **Pass criterion**: grep + 전후 diff 가 추가 한 줄뿐.

### T15. 문서 — 훅 seam 에 셋째 템플릿

- **Run**: `docs/wrapper-integration.md` §6 표에 `on-session-start.sh` 행이 있고, 요구사항에 "새 세션 시작(startup)은 등록하지 않는다" 취지가 있다.
- **Pass criterion**: grep.

### T16. 실기기 — /clear 뒤 첫 턴 (수동)

- **Setup**: 래퍼 릴리스 설치 후, 진행 중 계획이 있는 프로젝트에서 Claude Code 세션.
- **Run**: `/clear` → "지금 뭐 하던 중이었지?" 한 줄.
- **Expected**: 모델이 도구 호출 없이 진행 중 계획의 slug 와 최근 결정 제목을 말한다.
- **Pass criterion**: 답에 slug 가 있다. 실측 출력 크기를 기록한다.

## How to run

```bash
bash core/tests/test-session-resume.sh
```

## Pass criteria

- T1–T15 가 `core/tests/test-session-resume.sh` 에서 FAIL 0 (래퍼 케이스는 체크아웃 없으면 SKIP).
- 기존 `core/tests/*.sh` 전부 통과 (특히 test-journal · test-force-help · test-delegate-effort · test-template-digest · test-settings · test-whitespace).
- T16 수동 확인 후 CHANGELOG 에 실측 크기 기록.

## Related Documents

- `docs/wrapper-integration.md` §6
