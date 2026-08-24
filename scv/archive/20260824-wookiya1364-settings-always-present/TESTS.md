# Test Plan — 설정 파일은 항상 있고, 모든 키가 보인다

## Overview

파일이 없으면 만들어지고(전체 키·기본값·설명·.env 값), 있으면 사용자 값을 지키며
없는 키만 더하고, 비밀 파일은 무시가 보장될 때만 생기며, 자동 감지 키는 비어 있고,
.env 알림은 값이 다를 때만 나는지 확인한다. 기존 설정 계약(우선순위·순수부 정적 검사·
이사·무시 규칙)은 그대로 통과해야 한다.

## Test scenarios

### T14. 생성 — 전체 키 + 기본값 + 설명 + .env 값 (test-settings.sh)
- **Setup**: hydrate 된 임시 프로젝트, 설정 파일 없음, `.env` 에 SCV_LANG=korean 과 무관 키.
- **Run**: `settings-ensure.sh`
- **Expected**: 파일 생성, 공개 키 26개 전부 존재, `_doc` 존재, SCV_LANG=korean(.env),
  SCV_ATTACHMENTS_SCOPE=slug 등 기본값 채움, 자동 감지 키(NOTIFIER_PROVIDER 등) 빈 값,
  무관 키 없음, `.env` 바이트 동일, 두 번 돌려도 파일 동일.

### T15. 병합 — 사용자 값 불변, 없는 키만, `_doc` 재추가 안 함
- **Expected**: `{"SCV_LANG":"korean","MY_OWN":"mine"}` 만 있던 파일 → ensure 후 두 값 그대로,
  나머지 키 추가. `_doc` 을 지운 파일 → ensure 후에도 `_doc` 없음.

### T16. 비밀 파일 — 무시 보장될 때만
- **Expected**: git 저장소 + `.gitignore` 없음 → ensure 가 무시 줄을 더하고 비밀 파일 생성
  (`git check-ignore` 통과, 모드 600, 비밀 키 전부 빈 값, `.env` 토큰 반영). git 이 아닌
  폴더 → 비밀 파일 없음 + stderr 한 줄. 공개 파일에는 비밀 키 없음.

### T17. 액션 시작(autosync) 에서 자동 생성 · 알림 조건
- **Expected**: 파일 없는 hydrate 프로젝트에서 `scv_init_paths` → 파일 생김. `.env` 값 ==
  설정 값이면 `settings_get` 알림 없음; `.env` 값을 바꾸면 한 번 알림.

### T18. hydrate 가 실제 파일을 만든다 · 스위트
- **Expected**: 새 hydrate 프로젝트에 `scv/scv_settings.json` 존재(전체 키). run-dry ·
  tests/run.sh · core/tests 전량 exit 0, check-purity 통과.

## How to run

```bash
bash -euo pipefail -c '
fail() { echo "FAIL: $1"; exit 1; }
bash core/tests/test-settings.sh >/dev/null || fail "T14–T17 test-settings"
[ -x core/scripts/settings-ensure.sh ] || fail "settings-ensure.sh 없음"
grep -qF "_doc" core/template/scv/scv_settings.example.json || fail "예시에 _doc 없음"
X=$(mktemp -d); trap "rm -rf $X" EXIT
( cd "$X" && git init -q && bash "$OLDPWD/core/scripts/hydrate.sh" init . >/dev/null 2>&1 )
[ -f "$X/scv/scv_settings.json" ] || fail "T18 hydrate 가 설정 파일을 안 만듦"
python3 - "$X/scv/scv_settings.json" <<PY || fail "T18 hydrate 파일에 키 부족"
import json,sys; d=json.load(open(sys.argv[1])); ks=[k for k in d if not k.startswith("_")]
assert len(ks)>=26, len(ks); assert d.get("SCV_ATTACHMENTS_SCOPE")=="slug"; assert d.get("SCV_LANG")==""
PY
echo "OK [T14-T18 anchors]"
bash core/scripts/check-purity.sh >/dev/null 2>&1 || fail "purity"
bash core/tests/run-dry.sh >/dev/null || fail "run-dry"
bash tests/run.sh >/dev/null || fail "tests/run.sh"
for t in core/tests/test-*.sh; do bash "$t" >/dev/null || fail "$t"; done
echo "ALL GATES OK"
'
```

## Pass criteria

- 위 블록 exit 0. 배포 후 실측 2건(파일 없는 프로젝트 / 있는 프로젝트).

## Related Documents

- 원재료: `scv/raw/stale/20260824-wookiya1364-settings-always-present.md`
