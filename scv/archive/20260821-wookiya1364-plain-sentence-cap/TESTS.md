# Test Plan — 쉬운 말 문장 수 스위치 — SCV_PLAIN_MAX_SENTENCES

## Overview

확인하는 것: 규칙 본문에 cap 문장이 13곳 똑같이 들어갔고(기존 앵커는 그대로),
훅이 값에 따라 숫자를 바꿔 찍되 없음/이상값은 2, `off` 가 우선하며, 템플릿이
변수를 안내하고, 어제 계약(제목·앵커·동일성·비차단·버전 2.3.0)이 그대로라는
것. 모델이 문장을 정확히 세는지는 검사하지 않는다.

## Test scenarios

### T1. 13개 프로토콜 — cap 문장 + 기존 앵커 + 동일성
- **Expected**: Language preference 를 가진 프로토콜 전부에 `SCV_PLAIN_MAX_SENTENCES`
  앵커, 기존 앵커 7종(`1–2 sentences` 포함) 유지, 절 본문 해시 하나, 스텁 제외.
- **Pass criterion**: `OK [T1]`

### T2. 훅 — 값별 출력
- **Setup**: 임시 프로젝트(scv/ 있음)에 `.env` 를 바꿔 가며 실행.
- **Expected**: 없음 → `1–2 sentences`; `=4` → `1–4 sentences`; `=1` → `one sentence`;
  `=abc`/`=0`/`=-3`/`=2.5` → `1–2 sentences`; `SCV_PLAIN_LANGUAGE=off` + `=4` → 출력 없음;
  항상 exit 0, 12줄 이내, journal 에 요약 없음.
- **Pass criterion**: `OK [T2]`

### T3. 템플릿·버전
- **Expected**: `.env.example.scv` 에 `# SCV_PLAIN_MAX_SENTENCES=2`, `scv/SCV.md` 템플릿에
  `SCV_PLAIN_MAX_SENTENCES`, `core/TEMPLATE_VERSION`·루트 `TEMPLATE_VERSION` = 2.3.0.
- **Pass criterion**: `OK [T3]`

### T4. 어블레이션 규율·스코프·스위트
- **Expected**: 마커 규율·lint·full 동일·minimal 생존, 액션 15, run-dry·tests/run.sh·
  core/tests 전부 exit 0.
- **Pass criterion**: `ALL GATES OK`

## How to run

```bash
bash -euo pipefail -c '
fail() { echo "FAIL: $1"; exit 1; }
P=core/protocols; GF=core/scripts/guidance-filter.sh; HEAD="## Plain language first"
# [T1]
targets=$(grep -l "^## Language preference" $P/*.md)
for a in "SCV_PLAIN_MAX_SENTENCES" "1–2 sentences" "one example" "No code values before the user asks" \
         "stay exact, after the plain summary" "Bad:" "Good:" "SCV_PLAIN_LANGUAGE=off"; do
  for f in $targets; do grep -qF -- "$a" "$f" || fail "T1 앵커 없음: [$a] in $f"; done
done
hashes=$(printf "%s\n" "$targets" | while read -r f; do
  awk "/^$HEAD\$/{f=1} f&&/^## /&&!/^$HEAD\$/{exit} f" "$f" | sed -e :a -e "/^\\n*\$/{\$d;N;ba" -e "}" | cksum
done | sort -u | grep -c .)
[ "$hashes" -eq 1 ] || fail "T1 문구 판본 ${hashes}종"
for stub in set-models update; do grep -q "^$HEAD$" $P/$stub.md && fail "T1 스텁에 절: $stub" || true; done
echo "OK [T1]"
# [T2]
TMP=$(mktemp -d); trap "rm -rf $TMP" EXIT; CORE="$(pwd)/core"; mkdir -p "$TMP/p/scv"
run_hook() { ( cd "$TMP/p" && printf "%s" "{\"prompt\":\"hello\"}" | SCV_CORE_ROOT="$CORE" bash "$CORE/template/hooks/on-user-prompt.sh" ); }
expect() { printf "%s\n" "$1" > "$TMP/p/.env"; out=$(run_hook) || fail "T2 exit≠0 ($1)"; printf "%s" "$out" | grep -qF -- "$2" || fail "T2 [$1] → 기대 [$2] 없음: $(printf "%s" "$out" | head -1)"; [ "$(printf "%s\n" "$out" | grep -c .)" -le 12 ] || fail "T2 12줄 초과 ($1)"; }
rm -f "$TMP/p/.env"; run_hook | grep -qF "1–2 sentences" || fail "T2 기본값 1–2"
expect "SCV_PLAIN_MAX_SENTENCES=4" "1–4 sentences"
expect "SCV_PLAIN_MAX_SENTENCES=1" "one sentence"
for v in abc 0 -3 2.5 ""; do expect "SCV_PLAIN_MAX_SENTENCES=$v" "1–2 sentences"; done
printf "SCV_PLAIN_LANGUAGE=off\nSCV_PLAIN_MAX_SENTENCES=4\n" > "$TMP/p/.env"; [ -z "$(run_hook)" ] || fail "T2 off 우선 실패"
if grep -rqF "sentences" "$TMP/p/scv/journal" 2>/dev/null; then fail "T2 요약이 journal 에 섞임"; fi
echo "OK [T2]"
# [T3]
grep -q "^# SCV_PLAIN_MAX_SENTENCES=2" core/template/.env.example.scv || fail "T3 .env 예시 없음"
grep -qF "SCV_PLAIN_MAX_SENTENCES" core/template/scv/SCV.md || fail "T3 SCV.md 안내 없음"
[ "$(tr -d "[:space:]" < core/TEMPLATE_VERSION)" = "2.3.0" ] && [ "$(tr -d "[:space:]" < TEMPLATE_VERSION)" = "2.3.0" ] || fail "T3 TEMPLATE_VERSION ≠ 2.3.0"
echo "OK [T3]"
# [T4]
for f in $P/*.md; do case "$(basename "$f")" in promote.md|work.md) continue;; esac; grep -qF "SCV:GUIDANCE" "$f" && fail "T4 마커 유출: $f" || true; done
bash $GF --lint $P/promote.md $P/work.md >/dev/null || fail "T4 lint"
for p in promote work; do bash $GF --mode full $P/$p.md | cmp -s - $P/$p.md || fail "T4 full 불일치: $p"; bash $GF --mode minimal $P/$p.md | grep -qF "SCV_PLAIN_MAX_SENTENCES" || fail "T4 minimal 소실: $p"; done
[ "$(jq -r ".actions | length" core/actions.json)" -eq 15 ] || fail "T4 액션 수 ≠ 15"
bash core/tests/run-dry.sh >/dev/null || fail "T4 run-dry"
bash tests/run.sh >/dev/null || fail "T4 tests/run.sh"
for t in core/tests/test-*.sh; do bash "$t" >/dev/null || fail "T4 $t"; done
echo "ALL GATES OK"
'
```

## Pass criteria

- 위 블록 exit 0. 어제 보관한 계약(`20260821-wookiya1364-plain-answers-enforcement`)도
  누적 회귀에서 그대로 통과.
- 한계: 모델이 문장 수를 정확히 지키는지는 검사하지 않는다 — 상한은 지침이다.

## Related Documents

- 대화: `scv/conversations/20260821-130311-plain-sentence-cap.md`
