# Test Plan — 회귀 계약 보수

## Overview

이 문서가 곧 산출물이다. 옛 4개 슬러그의 검증 중 **아카이브 후에도 참인 것**만
남겨 한 계약으로 합친다. 규칙 둘을 스스로 지킨다: 커밋 전 상태 단언 없음
(`git diff` 범위 검사 금지), 존재하지 않는 파일 참조 없음, 슬러그 내부의 전체
스위트 재실행 없음. 어느 커밋에서 돌려도 같은 판정이 나와야 한다 — 그것이 이
계획의 존재 이유다.

## Test scenarios

### T1. provenance 게이트가 판정한다 (구 ci-provenance-gate)

- **Setup**: 없음 — 스위트가 자체 픽스처(실제 git 저장소)를 만든다
- **Run**: `bash core/tests/test-provenance-gates.sh`
- **Expected**: 게이트 두 개가 통과 케이스를 통과시키고 거부 케이스를 거부한다
- **Pass criterion**: exit 0. 원본이 부르던 `test-provenance.sh` 는 존재한 적이
  없다 — 실존 스위트(18케이스) 호출로 교체

### T2. 결정 로그가 살아 있다 (구 decision-log-activation)

- **Setup**: 저장소 그대로
- **Expected**: `scv/DECISIONS.md` 존재, 날짜 달린 엔트리 5+ 건, `path delta:`
  5+ 건(둘 다 단조 증가라 내구), status 액션이 최근 결정을 노출, work.md 의
  guidance 마커가 lint 를 통과하고 full 투영이 원본과 바이트 동일하며 minimal
  투영에 `- path delta:` 가 생존, 그 필드가 Step 9b.0 구간에 정확히 1회
- **Pass criterion**: How-to-run 의 [T2] 블록 전부 통과

### T3. 구현 원칙이 살아 있다 (구 implementation-principles)

- **Expected**: 원칙 절이 work.md 에 존재하고 codegen.md 가 참조, minimal
  투영에서 6개 핵심 구절 생존, full/minimal 투영의 스크립트 호출 시퀀스 동일
- **Pass criterion**: [T3] 블록 전부 통과

### T4. 쉬운 말 절이 살아 있다 (구 plain-language)

- **Expected**: Language preference 를 가진 프로토콜 전부(13+)에 절이 존재,
  문구가 서로 동일(끝 빈 줄 무시), GUIDANCE 마커는 promote/work 에만, 두 파일의
  full 투영 바이트 동일 + minimal 에서 절 생존
- **Pass criterion**: [T4] 블록 전부 통과

### T5. 이 계약 자체가 내구적이다

- **Setup**: 저장소 사본을 만들어 아무 과거 커밋으로 `git reset --hard`
- **Run**: 사본에서 How-to-run 블록 실행
- **Expected**: 판정이 현재 트리와 동일하게 성립한다 (통과/실패가 트리 내용에만
  의존하고, 커밋 여부·diff 상태에 의존하지 않는다)
- **Pass criterion**: 사본 실행이 정상 종료 — 옛 4건은 이 검사에서 즉사한다

### T6. 재발 방지 장치가 실제로 문다

- **Run**: `bash core/scripts/tests-smell.sh <옛 4건 각각의 TESTS.md>` 와
  `bash core/scripts/tests-smell.sh <이 파일>`
- **Expected**: 옛 3건(git-diff 단언)과 1건(부재 스크립트)에 warn, 이 파일에는
  해당 warn 없음. tests-smell 은 warn 전용 — exit 코드로 막지 않는다
- **Pass criterion**: warn 유/무가 위와 일치

### T7. supersede 마킹이 규칙대로다 (아카이브 후 확인)

- **Expected**: 옛 4건의 PLAN.md 에 `status: obsolete`·`obsoleted_at`·
  `obsoleted_by: 20260818-wookiya1364-regression-contract-repair` 세 필드만 추가,
  TESTS.md·ARCHIVED_AT.md 바이트 동일. `regression.sh` 스킵 목록에 4건 등장
- **Pass criterion**: git diff 가 frontmatter 3필드 외 무변경을 보이고, 회귀
  요약이 스킵 4를 보고

## How to run

```bash
bash -euo pipefail -c '
fail() { echo "FAIL: $1"; exit 1; }
GF="core/scripts/guidance-filter.sh"

# [T1] provenance 게이트 — 실존 스위트
bash core/tests/test-provenance-gates.sh >/dev/null || fail "T1 provenance gates"

# [T2] 결정 로그
test -f scv/DECISIONS.md || fail "T2 DECISIONS.md 없음"
test "$(grep -cE "^## \[[0-9]{4}-[0-9]{2}-[0-9]{2}" scv/DECISIONS.md)" -ge 5 || fail "T2 엔트리 5건 미만"
test "$(grep -cE "^- path delta:" scv/DECISIONS.md)" -ge 5 || fail "T2 path delta 5건 미만"
bash core/scripts/status.sh | grep -A2 "recent decisions" | grep -qv "does not exist" || fail "T2 status 노출"
bash "$GF" --lint core/protocols/work.md >/dev/null || fail "T2 lint work.md"
bash "$GF" --mode full core/protocols/work.md | cmp -s - core/protocols/work.md || fail "T2 full 투영 불일치"
bash "$GF" --mode minimal core/protocols/work.md | grep -qF -- "- path delta:" || fail "T2 minimal 소실"
test "$(awk "/^#### Step 9b\.0/{f=1} /^#### Step 9b\.1/{f=0} f" core/protocols/work.md | grep -cE "^- path delta:")" -eq 1 || fail "T2 구간 내 1회 아님"

# [T3] 구현 원칙
grep -qF -- "Implementation principles" core/protocols/work.md    || fail "T3 work.md 원칙 없음"
grep -qF -- "Implementation principles" core/protocols/codegen.md || fail "T3 codegen.md 참조 없음"
M="$(bash "$GF" --mode minimal core/protocols/work.md)"
for s in "Implementation principles" "reuse what is there" "simplest implementation" \
         "one clear concern" "costly to reverse" "Guardrails override them"; do
  printf "%s" "$M" | grep -qF -- "$s" || fail "T3 minimal 소실: $s"
done
for m in full minimal; do
  bash "$GF" --mode "$m" core/protocols/work.md \
    | grep -oE "\{[A-Z_]+\}/scripts/[a-z0-9-]+\.sh" | sed "s|.*/||" > "/tmp/rcr.$m"
done
cmp -s /tmp/rcr.full /tmp/rcr.minimal || fail "T3 호출 시퀀스 불일치"

# [T4] 쉬운 말
HEAD_MARK="## Plain language first"
targets="$(grep -l "^## Language preference" core/protocols/*.md)"
n=$(printf "%s\n" "$targets" | wc -l)
have=$(grep -l "^${HEAD_MARK}$" core/protocols/*.md | wc -l)
[ "$n" -eq "$have" ] || fail "T4 누락: ${n}개 대상 중 ${have}개"
[ "$n" -ge 13 ] || fail "T4 대상이 ${n}개로 줄었다"
hashes=$(printf "%s\n" "$targets" | while read -r f; do
  awk "/^${HEAD_MARK}\$/{f=1} f&&/^## /&&!/^${HEAD_MARK}\$/{exit} f" "$f" \
    | sed -e :a -e "/^\n*\$/{\$d;N;ba" -e "}" | cksum
done | sort -u | wc -l)
[ "$hashes" -eq 1 ] || fail "T4 문구 판본 ${hashes}종"
for f in core/protocols/*.md; do
  case "$(basename "$f")" in promote.md|work.md) continue;; esac
  grep -qF "SCV:GUIDANCE" "$f" && fail "T4 마커 유출: $f" || true
done
bash "$GF" --lint core/protocols/promote.md core/protocols/work.md >/dev/null || fail "T4 lint"
for p in promote work; do
  bash "$GF" --mode full "core/protocols/$p.md" | cmp -s - "core/protocols/$p.md" || fail "T4 full 불일치: $p"
  bash "$GF" --mode minimal "core/protocols/$p.md" | grep -qF "$HEAD_MARK" || fail "T4 minimal 소실: $p"
done
echo "ALL CONTRACTS OK"
'
```

## Pass criteria

- How-to-run 이 초록이고, 과거 커밋 사본 트리에서도 같은 판정 (T5)
- tests-smell 이 옛 4건에 warn, 이 파일에 무경고 (T6)
- 아카이브 후 옛 4건 obsolete 마킹 + 회귀 스킵 4 (T7)
- 이 블록 어디에도 `git diff` 단언·부재 파일 참조·전체 스위트 재실행이 없다

## Related Documents

- [`PLAN.md`](./PLAN.md)
