# TESTS — 구현 원칙 4종

## Overview

기계 검증층은 "원칙이 프로토콜에 존재하고 `SCV_GUIDANCE=minimal` 투영에서
사라지지 않는다"까지만 보장한다. "에이전트가 실제로 원칙을 따랐는가"는 검증
수단이 없다 — `path delta` 필드와 같은 한계이며 숨기지 않는다.

`test-guidance.sh` [6] 은 `codegen.md` 미커밋 변경으로 **의도적으로 실패**한다.
회귀가 아니라 phase-1 스코프 가드의 설계이며, 커밋 후 해소를 확인하는 것이
시나리오 6이다.

## Test scenarios

1. **원칙이 프로토콜 원본에 존재** — `work.md` 에 4개 원칙 앵커가 있고
   `codegen.md` 가 정본을 참조한다. `run-dry.sh` 의 assert 로 고정.
2. **원칙이 CONTRACT 다** — `--mode minimal` 투영에 4개 앵커가 전부 생존한다.
   `test-guidance.sh` 의 work.min.md 배열에 등록해 오분류를 탐지한다.
3. **마커 정합 + full 바이트 동일성** — `--lint` 가 `GUIDANCE_LINT: OK`,
   `--mode full` 출력이 원본과 `cmp -s` 동일.
4. **어블레이션 무회귀** — full/minimal 스크립트 호출 시퀀스와 컬럼0
   frontmatter 표면이 동일. `run-dry.sh` [19] 통과.
5. **PLAN Guardrails 우선 규칙 명시** — 원칙 블록이 "PLAN Guardrails 가
   우선한다"를 문안에 담고 있다.
6. **스코프 가드의 예상된 실패와 해소** — `test-guidance.sh` [6] 이
   `codegen.md` 를 이유로 실패하고, 그 외 모든 검사는 통과한다. 커밋 후 다시
   실행하면 [6] 도 통과한다.
7. **범위 준수** — `core/scripts/` · `core/actions.json` 무변경, 새 문서 파일
   0개, 하위호환 관련 문구 0건.

## How to run

**반드시 `bash` 로 실행한다.** 이 블록은 `bash -euo pipefail` 을 명시적으로
호출한다 — 대화형 셸이 zsh 인 환경에서 `set -e` 만 믿으면 `for` 루프 안의 실패가
삼켜져 **깨진 검증이 통과로 보고된다**(이 계획 구현 중 실제로 겪음).

```bash
bash -euo pipefail -c '
fail() { echo "FAIL: $1"; exit 1; }

# [1] 원칙이 두 프로토콜 원본에 존재
grep -qF -- "Implementation principles" core/protocols/work.md    || fail "work.md 원칙 없음"
grep -qF -- "Implementation principles" core/protocols/codegen.md || fail "codegen.md 참조 없음"

# [3] 마커 정합 + full 바이트 동일
bash core/scripts/guidance-filter.sh --lint core/protocols/work.md >/dev/null || fail "lint"
bash core/scripts/guidance-filter.sh --mode full core/protocols/work.md \
  | cmp -s - core/protocols/work.md || fail "full 투영이 원본과 다름"

# [2][5] minimal 에서 원칙 4개 + Guardrails 우선 규칙 생존
M=$(bash core/scripts/guidance-filter.sh --mode minimal core/protocols/work.md)
for s in "Implementation principles" "reuse what is there" "simplest implementation" \
         "one clear concern" "costly to reverse" "Guardrails override them"; do
  printf "%s" "$M" | grep -qF -- "$s" || fail "minimal 소실: $s"
done

# [4] 호출 시퀀스 full == minimal
for m in full minimal; do
  bash core/scripts/guidance-filter.sh --mode "$m" core/protocols/work.md \
    | grep -oE "\{[A-Z_]+\}/scripts/[a-z0-9-]+\.sh" | sed "s|.*/||" > "/tmp/pc.$m"
done
cmp -s /tmp/pc.full /tmp/pc.minimal || fail "호출 시퀀스 불일치"

# [7] 범위 준수
[ -z "$(git diff --name-only HEAD -- core/scripts/ core/actions.json)" ] || fail "스크립트/액션 변경됨"
grep -qiE "backward|하위호환" core/protocols/work.md && fail "하위호환 문구 유입" || true

# [1][4] 전체 스위트 — test-guidance 는 [6] 때문에 별도 판정
bash core/tests/run-dry.sh >/dev/null || fail "run-dry"
bash tests/run.sh >/dev/null || fail "tests/run.sh"
for t in core/tests/test-*.sh; do
  case "$t" in */test-guidance.sh) continue;; esac
  bash "$t" >/dev/null || fail "$t"
done

# [6] test-guidance: codegen.md 미커밋으로 인한 [6] 실패 1건만 허용
OUT=$(bash core/tests/test-guidance.sh 2>&1 || true)
printf "%s\n" "$OUT" | tail -1
if printf "%s" "$OUT" | grep -qE ", 0 failed"; then
  :                                             # 커밋 후 상태 — 정상
elif printf "%s" "$OUT" | grep -qE ", 1 failed"; then
  printf "%s" "$OUT" \
    | grep -qF "phase-1 scope: byte change outside promote/work: core/protocols/codegen.md" \
    || fail "test-guidance 실패 1건이지만 사유가 예상과 다름"
else
  fail "test-guidance 실패 2건 이상"
fi
echo "ALL GATES OK"
'
```

## Pass criteria

- 위 블록이 exit 0. 즉 시나리오 1~5·7 전부 통과, `run-dry.sh` 와 `tests/run.sh`
  와 `test-guidance.sh` 를 제외한 `test-*.sh` 가 무회귀.
- `test-guidance.sh` 는 **정확히 1건** 실패하며 그 사유가
  `phase-1 scope: byte change outside promote/work: core/protocols/codegen.md`
  여야 한다. 다른 사유의 실패나 2건 이상은 불합격이다.
- **커밋 후 수동 1회**: `test-guidance.sh` 가 0 failed 로 돌아오는 것을 확인한다.
  이 확인 전에는 "스위트 전량 green" 이라고 주장하지 않는다.
- CHANGELOG 와 `docs/guidance-ablation.md` 의 수치가
  `guidance-filter.sh --lint core/protocols/work.md` 실측과 일치한다.
- **명시할 한계**: 에이전트가 원칙을 실제로 따랐는지 검증하는 테스트는 없다.

## Related Documents

<!-- 없음 -->
