# Test Plan — 쉬운 말 2단계 — 답의 모양, 매 턴 전달, .env 스위치

## Overview

기계로 확인할 수 있는 것: 규칙이 13개 프로토콜에 같은 문구로 제자리에 있고,
훅이 켜짐/꺼짐 규칙대로 요약을 내보내며 비차단을 지키고, 템플릿·스위치·
예시 루틴이 자리에 있고, 어블레이션 규율이 깨지지 않았다는 것까지다.
**모델이 실제로 쉽게 말하는지는 자동으로 보장하지 못한다** — 그 부분은 T7
(사람 판정 3건, 수동)이 닫는다. 숨기지 않고 판정 기준에 적는다.

`git diff`/`git status` 단언은 쓰지 않는다 — 커밋 상태와 무관하게 트리
내용만으로 판정이 성립해야 한다(0818 회귀 계약 보수 T5).

## Test scenarios

### T1. 13개 프로토콜 — 절 존재·동일 문구·위치·앵커·옛 문구 제거

- **Setup**: 저장소 트리
- **Run**: `## Language preference` 를 가진 프로토콜 전부를 대상으로 검사
- **Expected**: 대상 ≥ 13, 전부 `## Plain language first` 절 보유, 절 본문
  해시가 하나(끝 빈 줄 무시), 절이 Language preference 바로 다음 H2, 앵커
  7개(`SCV_PLAIN_LANGUAGE=off` · `1–2 sentences` · `one example` ·
  `No code values before the user asks` · `stay exact, after the plain summary` ·
  `Bad:` · `Good:`) 전부 존재, 옛 문구 `Detail is not owed up front` 는 어느
  프로토콜에도 없음, `set-models.md`·`update.md` 에는 절 없음
- **Pass criterion**: `OK [T1]`

### T2. help 대화 모드 — 매 턴 모양

- **Expected**: `core/protocols/help.md` 에 `one question per turn` 앵커 존재
  (Step B2 대화 루프 안: 짧은 답 → 예시 하나 → 질문 하나)
- **Pass criterion**: `OK [T2]`

### T3. 훅 — 켜짐/꺼짐/이상값/미적용/비차단, journal 오염 없음

- **Setup**: 임시 폴더 5개 — `on`(scv/ 있음, .env 없음) · `off`(`SCV_PLAIN_LANGUAGE=off`)
  · `up`(`=OFF`) · `odd`(`=maybe`) · `none`(scv/ 없음). `SCV_CORE_ROOT` 는 저장소 `core/`.
- **Run**: 각 폴더를 cwd 로 `{"prompt":"hello"}` 를 stdin 으로 `on-user-prompt.sh` 실행
- **Expected**: `on` → exit 0, stdout 에 `1–2 sentences` 와 `SCV_PLAIN_LANGUAGE`
  포함, 12줄 이내, `scv/journal/*.md` 에 기록됨, journal 에 요약 문구 없음.
  `off`·`up` → stdout 비어 있음(exit 0). `odd` → 요약 출력(이상값은 켜짐).
  `none` → stdout 비어 있음. 잘못된 입력(`not-json`) → exit 0.
- **Pass criterion**: `OK [T3]`

### T4. 템플릿 — .env 예시·SCV.md·TEMPLATE_VERSION·예시 루틴

- **Expected**: `core/template/.env.example.scv` 에 `# SCV_PLAIN_LANGUAGE=on`
  (기본 on 으로 주석 문서화), `core/template/scv/SCV.md` 에 `SCV_PLAIN_LANGUAGE` 와
  `1–2 sentences` 포함, `core/TEMPLATE_VERSION` 과 루트 `TEMPLATE_VERSION` 둘 다
  `2.3.0`, `core/template/scv/routines/examples/plain-language-audit.md` 존재 +
  frontmatter 5키(name/cadence/guardrails/exit/report)
- **Pass criterion**: `OK [T4]`

### T5. 어블레이션 규율

- **Expected**: promote·work 외 프로토콜에 `SCV:GUIDANCE` 없음, promote·work
  `--lint` OK, full 투영이 원본과 바이트 동일, minimal 투영에도 절의 앵커
  (`No code values before the user asks`) 생존
- **Pass criterion**: `OK [T5]`

### T6. 스코프·전체 스위트

- **Expected**: `core/actions.json` 의 액션 수 15 (내용 기반), `run-dry.sh` ·
  `tests/run.sh` · `core/tests/test-*.sh` 전부 exit 0
- **Pass criterion**: `ALL GATES OK`

### T7. 사람 판정 3건 (수동 — 자동화 안 함)

- **Setup**: SCV 가 hydrate 된 샘플 프로젝트, 스위치 기본(on)
- **Run**: ① 명령 없이 일반 대화 질문 1건(예: "SCV 가 뭐야?") ② `/scv:help`
  진단 1건 ③ `/scv:help "<작은 아이디어>"` 대화 1턴
- **Expected**: 각 첫 답이 "2문장 이내 + 예시 1 + 코드값 없음(필수 식별자는
  요약 뒤에)". 대표님이 눈으로 판정.
- **Pass criterion**: 3건 모두 통과. 결과를 archive 의 `ARCHIVED_AT.md` 또는
  `CHECK.md` 에 체크리스트로 남긴다. 1건이라도 반려면 문구를 고쳐 다시 3건.

## How to run

**`bash` 로 실행한다.** (대화형 셸이 zsh 면 `set -e` 가 루프 안에서 bash 처럼
동작하지 않는다.) T1–T6 만 기계 실행이다. T7 은 수동.

```bash
bash -euo pipefail -c '
fail() { echo "FAIL: $1"; exit 1; }
P=core/protocols; GF=core/scripts/guidance-filter.sh
HEAD="## Plain language first"

# [T1] 13개 프로토콜
targets=$(grep -l "^## Language preference" $P/*.md)
n=$(printf "%s\n" "$targets" | grep -c .)
have=$(grep -l "^$HEAD$" $P/*.md | grep -c .)
[ "$n" -ge 13 ] || fail "T1 대상이 ${n}개로 줄었다"
[ "$n" -eq "$have" ] || fail "T1 절 누락 ($have/$n)"
hashes=$(printf "%s\n" "$targets" | while read -r f; do
  awk "/^$HEAD\$/{f=1} f&&/^## /&&!/^$HEAD\$/{exit} f" "$f" \
    | sed -e :a -e "/^\\n*\$/{\$d;N;ba" -e "}" | cksum
done | sort -u | grep -c .)
[ "$hashes" -eq 1 ] || fail "T1 문구 판본 ${hashes}종"
for a in "SCV_PLAIN_LANGUAGE=off" "1–2 sentences" "one example" \
         "No code values before the user asks" "stay exact, after the plain summary" \
         "Bad:" "Good:"; do
  for f in $targets; do grep -qF -- "$a" "$f" || fail "T1 앵커 없음: [$a] in $f"; done
done
for f in $targets; do
  nxt=$(awk "/^## Language preference/{f=1;next} f&&/^## /{print;exit}" "$f")
  [ "$nxt" = "$HEAD" ] || fail "T1 위치: $f → 다음 H2 가 [$nxt]"
done
if grep -lF "Detail is not owed up front" $P/*.md >/dev/null 2>&1; then fail "T1 옛 문구 잔존"; fi
for stub in set-models update; do
  grep -q "^$HEAD$" $P/$stub.md && fail "T1 어댑터 스텁에 절: $stub" || true
done
echo "OK [T1]"

# [T2] help 대화 모드
grep -qF "one question per turn" $P/help.md || fail "T2 help 대화 모드 앵커 없음"
echo "OK [T2]"

# [T3] 훅
TMP=$(mktemp -d); trap "rm -rf $TMP" EXIT
CORE="$(pwd)/core"
run_hook() { ( cd "$1" && printf "%s" "$2" | SCV_CORE_ROOT="$CORE" bash "$CORE/template/hooks/on-user-prompt.sh" ); }
mkdir -p "$TMP/on/scv" "$TMP/off/scv" "$TMP/up/scv" "$TMP/odd/scv" "$TMP/none"
printf "SCV_PLAIN_LANGUAGE=off\n"   > "$TMP/off/.env"
printf "SCV_PLAIN_LANGUAGE=OFF\n"   > "$TMP/up/.env"
printf "SCV_PLAIN_LANGUAGE=maybe\n" > "$TMP/odd/.env"
out=$(run_hook "$TMP/on" "{\"prompt\":\"hello\"}") || fail "T3 켜짐 exit≠0"
printf "%s" "$out" | grep -qF "1–2 sentences" || fail "T3 켜짐: 요약 미출력"
printf "%s" "$out" | grep -qF "SCV_PLAIN_LANGUAGE" || fail "T3 켜짐: 스위치 안내 없음"
[ "$(printf "%s\n" "$out" | grep -c .)" -le 12 ] || fail "T3 요약이 12줄 초과"
ls "$TMP/on/scv/journal/"*.md >/dev/null 2>&1 || fail "T3 켜짐: journal 미기록"
if grep -rqF "1–2 sentences" "$TMP/on/scv/journal/"; then fail "T3 요약이 journal 에 섞여 들어감"; fi
[ -z "$(run_hook "$TMP/off" "{\"prompt\":\"hello\"}")" ] || fail "T3 off 인데 출력"
[ -z "$(run_hook "$TMP/up" "{\"prompt\":\"hello\"}")" ]  || fail "T3 OFF(대문자) 인데 출력"
run_hook "$TMP/odd" "{\"prompt\":\"hello\"}" | grep -qF "1–2 sentences" || fail "T3 이상값은 켜짐이어야"
[ -z "$(run_hook "$TMP/none" "{\"prompt\":\"hello\"}")" ] || fail "T3 SCV 없는 폴더에서 출력"
run_hook "$TMP/on" "not-json" >/dev/null || fail "T3 잘못된 입력에 exit≠0"
echo "OK [T3]"

# [T4] 템플릿·스위치·버전·예시 루틴
grep -q "^# SCV_PLAIN_LANGUAGE=on" core/template/.env.example.scv || fail "T4 .env 예시에 스위치 없음"
grep -qF "SCV_PLAIN_LANGUAGE" core/template/scv/SCV.md || fail "T4 SCV.md 템플릿에 스위치 안내 없음"
grep -qF "1–2 sentences" core/template/scv/SCV.md || fail "T4 SCV.md 템플릿에 답의 모양 없음"
[ "$(tr -d "[:space:]" < core/TEMPLATE_VERSION)" = "2.3.0" ] || fail "T4 core/TEMPLATE_VERSION ≠ 2.3.0"
[ "$(tr -d "[:space:]" < TEMPLATE_VERSION)" = "2.3.0" ] || fail "T4 TEMPLATE_VERSION ≠ 2.3.0"
R=core/template/scv/routines/examples/plain-language-audit.md
[ -f "$R" ] || fail "T4 예시 루틴 없음"
for k in "^name: plain-language-audit" "^cadence:" "^guardrails:" "^exit:" "^report:"; do
  grep -q "$k" "$R" || fail "T4 루틴 키 없음: $k"
done
echo "OK [T4]"

# [T5] 어블레이션 규율
for f in $P/*.md; do
  case "$(basename "$f")" in promote.md|work.md) continue;; esac
  grep -qF "SCV:GUIDANCE" "$f" && fail "T5 마커 유출: $f" || true
done
bash $GF --lint $P/promote.md $P/work.md >/dev/null || fail "T5 lint"
for p in promote work; do
  bash $GF --mode full $P/$p.md | cmp -s - $P/$p.md || fail "T5 full 불일치: $p"
  bash $GF --mode minimal $P/$p.md | grep -qF "No code values before the user asks" || fail "T5 minimal 소실: $p"
done
echo "OK [T5]"

# [T6] 스코프·전체 스위트
[ "$(jq -r ".actions | length" core/actions.json)" -eq 15 ] || fail "T6 액션 수 ≠ 15"
bash core/tests/run-dry.sh >/dev/null || fail "T6 run-dry"
bash tests/run.sh >/dev/null || fail "T6 tests/run.sh"
for t in core/tests/test-*.sh; do bash "$t" >/dev/null || fail "T6 $t"; done
echo "ALL GATES OK"
'
```

## Pass criteria

- 위 블록이 exit 0 (`OK [T1]`…`OK [T5]`, `ALL GATES OK`).
- **T7 수동 3건 통과** — 체크리스트가 archive 에 남아 있어야 "완료" 라고 말한다.
  그 전에는 "규칙은 배치됐지만 말투 검증은 미완" 으로 보고한다.
- **명시할 한계**: 모델이 실제로 쉽게 말하는지 자동 보장하는 테스트는 없다.
  보장되는 것은 "규칙이 매 턴 모델 눈앞에 있고 답의 모양이 구체적" 까지다.

## Related Documents

- 대화: `scv/conversations/20260821-103405-plain-answers-enforcement.md`
