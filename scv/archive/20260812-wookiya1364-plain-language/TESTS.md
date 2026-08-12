# TESTS — 쉬운 말 먼저

## Overview

기계로 확인할 수 있는 것은 "규칙이 13개 프로토콜에 있고, 문구가 서로 같고,
minimal 투영에서도 안 사라진다"까지다. **에이전트가 실제로 쉽게 말하는지는
테스트할 수 없다.** 숨기지 않고 판정 기준에 적는다.

`test-guidance.sh` [6]은 `codegen.md` 등 promote·work 밖 프로토콜의 **커밋되지
않은** 변경을 실패로 본다. 커밋 전에는 그 1건이 빨간불이고, 커밋 후 해소되는
것을 확인하는 것이 시나리오 5다.

## Test scenarios

1. **13개 전부에 존재** — `core/protocols/*.md` 모두에 `## Plain language first`
   절이 있다.
2. **문구 동일** — 13개 파일의 그 절 본문 해시가 하나로 모인다. 파일마다 다르면
   유지가 안 된다.
3. **마커 규율** — promote·work 외 프로토콜에 `SCV:GUIDANCE` 마커가 없고,
   promote·work의 lint가 OK이며 `--mode full`이 원본과 바이트 동일하다.
4. **minimal 생존** — 마커 밖이므로 `--mode minimal` 투영에도 남아 있다.
5. **스코프·무회귀** — `core/scripts/`·`core/actions.json` 무변경, 전체 스위트
   green. `test-guidance.sh`는 커밋 전 [6] 1건만 실패.

## How to run

**`bash`로 실행한다.** 대화형 셸이 zsh면 `set -e`가 루프 안에서 bash처럼
동작하지 않아 실패가 조용히 넘어간다.

```bash
bash -euo pipefail -c '
fail() { echo "FAIL: $1"; exit 1; }
HEAD_MARK="## Plain language first"

# [1] Language preference 를 가진 프로토콜 전부에 존재.
#     set-models.md / update.md 는 어댑터 소유 스텁이라 대상이 아니다.
targets=$(grep -l "^## Language preference" core/protocols/*.md)
n=$(printf "%s\n" "$targets" | wc -l)
have=$(grep -l "^${HEAD_MARK}$" core/protocols/*.md | wc -l)
[ "$n" -eq "$have" ] || fail "누락: 대상 ${n} 개 중 ${have} 개에만 있음"
[ "$n" -ge 13 ] || fail "대상이 ${n} 개로 줄었다 — 프로토콜이 사라졌는지 확인"
echo "OK [1] ${have}/${n} 개 프로토콜에 존재"

# [2] 문구가 서로 동일. 끝 빈 줄은 무시한다 — 절이 파일 끝에 오는 프로토콜
#     (report.md)은 뒤따르는 헤딩이 없어 빈 줄 하나가 덜 붙는다.
hashes=$(printf "%s\n" "$targets" | while read -r f; do
  awk "/^${HEAD_MARK}\$/{f=1} f&&/^## /&&!/^${HEAD_MARK}\$/{exit} f" "$f" \
    | sed -e :a -e "/^\\n*\$/{\$d;N;ba" -e "}" | md5sum | cut -d" " -f1
done | sort -u | wc -l)
[ "$hashes" -eq 1 ] || fail "문구가 파일마다 다름 (서로 다른 판본 ${hashes}종)"
echo "OK [2] ${n}개 문구 동일"

# [3] 마커 규율
for f in core/protocols/*.md; do
  case "$(basename "$f")" in promote.md|work.md) continue;; esac
  grep -qF "SCV:GUIDANCE" "$f" && fail "마커 유출: $f" || true
done
bash core/scripts/guidance-filter.sh --lint core/protocols/promote.md core/protocols/work.md >/dev/null \
  || fail "lint"
for p in promote work; do
  bash core/scripts/guidance-filter.sh --mode full "core/protocols/$p.md" \
    | cmp -s - "core/protocols/$p.md" || fail "full 투영이 원본과 다름: $p"
done
echo "OK [3] 마커 규율"

# [4] minimal 생존
for p in promote work; do
  bash core/scripts/guidance-filter.sh --mode minimal "core/protocols/$p.md" \
    | grep -qF "$HEAD_MARK" || fail "minimal 에서 소실: $p"
done
echo "OK [4] minimal 생존"

# [5] 스코프
[ -z "$(git diff --name-only HEAD -- core/scripts/ core/actions.json)" ] \
  || fail "스크립트/액션 카탈로그 변경됨"

bash core/tests/run-dry.sh >/dev/null || fail "run-dry"
bash tests/run.sh >/dev/null || fail "tests/run.sh"
for t in core/tests/test-*.sh; do
  case "$t" in */test-guidance.sh) continue;; esac
  bash "$t" >/dev/null || fail "$t"
done

OUT=$(bash core/tests/test-guidance.sh 2>&1 || true)
printf "%s\n" "$OUT" | tail -1
if printf "%s" "$OUT" | grep -qE ", 0 failed"; then
  :                                    # 커밋 후 — 정상
elif printf "%s" "$OUT" | grep -qE ", 1 failed"; then
  printf "%s" "$OUT" | grep -qF "phase-1 scope: byte change outside promote/work" \
    || fail "test-guidance 실패 1건이지만 사유가 예상과 다름"
else
  fail "test-guidance 실패 2건 이상"
fi
echo "ALL GATES OK"
'
```

## Pass criteria

- 위 블록이 exit 0.
- `test-guidance.sh`는 **커밋 전** 정확히 1건 실패하며 사유가 phase-1 스코프여야
  한다. 다른 사유거나 2건 이상이면 불합격.
- **커밋 후 수동 1회**: `test-guidance.sh`가 0 failed로 돌아오는 것을 확인한다.
  그 전에는 "스위트 전량 green"이라고 말하지 않는다.
- **명시할 한계**: 에이전트가 실제로 쉽게 말하는지 검증하는 테스트는 없다.
  규칙이 프로토콜에 존재한다는 것까지만 보장된다.

## Related Documents

<!-- 없음 -->
