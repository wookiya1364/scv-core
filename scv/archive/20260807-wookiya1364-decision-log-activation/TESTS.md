# TESTS — 결정 로그 실작동

## Overview

두 층을 구분해서 검증한다. **기계 검증층**은 "프로토콜에 지시가 존재하고, 그 지시가
`SCV_GUIDANCE=minimal` 투영에서 사라지지 않는다"까지를 보장한다. **행동층**("에이전트가
실제로 델타를 적었는가")은 이 저장소에 DECISIONS.md 를 쓰는 스크립트가 없으므로 자동
검증 수단이 없다 — 시나리오 8~10 은 수동 확인이며, 이 한계를 Pass criteria 에 그대로
쓴다. guidance-ablation 계획이 "LLM 행동은 테스트하지 않고 측정치를 보고"로 처리한
선례를 따른다.

## Test scenarios

### 기계 검증 (자동)

1. **베이스라인 존재** — `scv/DECISIONS.md` 가 존재하고, `## [YYYY-MM-DD HH:MM]`
   헤더가 5건 이상이며, 각 엔트리에 `- verdict:` / `- why:` / `- path delta:` 가
   있다. `status.sh` 의 결정 블록이 `(file does not exist …)` 도
   `(no entries yet …)` 도 아닌 실제 건수를 보고한다.
2. **필드가 프로토콜 원본에 존재** — `core/tests/run-dry.sh` [16] 이
   `- path delta:` 를 assert 하고 통과한다.
3. **필드가 CONTRACT 다 (오분류 탐지)** — `core/tests/test-guidance.sh` 의
   work.min.md 생존 배열에 `- path delta:` 가 등록돼 있고 통과한다.
   **역방향 확인 1회**: 그 줄을 일부러 `<!-- SCV:GUIDANCE -->` 안으로 옮기면
   `contract lost: - path delta:` 로 **실패해야** 한다. 실패가 재현되지 않으면
   안전망이 작동하지 않는 것이다.
4. **마커 정합 + full 바이트 동일성** — `guidance-filter.sh --lint
   core/protocols/work.md` 가 `GUIDANCE_LINT: OK` 로 끝나고, `--mode full` 출력이
   원본과 `cmp -s` 동일하다.
5. **어블레이션 동등성 무회귀** — run-dry [19a](full==원본 / minimal 에 마커 문자열
   부재 / 스크립트 호출 시퀀스 diff 0 / 컬럼0 frontmatter diff 0)와 [19b](생성 파일
   목록 / PLAN frontmatter 키 시퀀스 / 정규화 트랜스크립트) 전부 통과.
   **주의**: 이 시나리오는 통과해도 오분류를 잡지 못한다 — 그건 3번의 몫이다.
6. **필드 배치 격리** — `- path delta:` 가 정확히 1줄 존재하고 그 줄이 Step 9b.0
   구간(`#### Step 9b.0` ~ `#### Step 9b.1`) 안에 있다. 두 카운트가 어긋나면 다른
   스텝에 중복 삽입된 것이다.
7. **편집 스코프 격리 + 전체 스위트 무회귀** — `git diff --name-only HEAD --
   core/protocols/` 가 `core/protocols/work.md` 단 하나이고,
   `-- core/scripts/ core/actions.json` 이 비어 있다. 세 스위트 전량 exit 0.
   새 문안에 호스트 종속 토큰이 섞이면 `test-host-neutral.sh` 가 잡는다.

### 행동 검증 (수동 · 자동 불가)

8. **end-to-end 실증** — 이 계획을 `bash core/scripts/work.sh <slug> --archive`
   로 아카이브한다. `scv/archive/INDEX.yaml` 이 생성되고(= 이 저장소 최초의
   `work.sh --archive` 실행), `scv/DECISIONS.md` 에 이 계획의 엔트리가 append 되며
   `- path delta:` 가 **`as planned` 가 아닌 실제 이탈 내용**으로 채워져 있다.
   (이 계획은 조사 과정에서 원래 구상이 반증돼 범위가 바뀌었으므로 이탈이 실재한다.)
9. **저비용 경로가 실제로 저비용** — Suggested path 를 그대로 따라간 계획을
   아카이브했을 때 `- path delta: as planned` 한 줄로 끝난다. 에이전트가 억지로
   문단을 지어내면 형식주의(Guardrails 위반), 두 줄을 통째로 생략하면 의무 문장이
   약한 것 — 어느 쪽이든 work.md 문안을 조정한다.
10. **탐지 루틴이 누락을 잡는다** — `decision-log-integrity` 루틴을 실행해, 엔트리가
    없는 아카이브 슬러그를 일부러 만든 상태에서 그 슬러그가 보고되는지 확인한다.

## How to run

```bash
set -e
# [1] 베이스라인 — 파일 존재 + 엔트리 5건 이상 + 필수 필드
test -f scv/DECISIONS.md
test "$(grep -cE '^## \[[0-9]{4}-[0-9]{2}-[0-9]{2}' scv/DECISIONS.md)" -ge 5
test "$(grep -cE '^- path delta:' scv/DECISIONS.md)" -ge 5
bash core/scripts/status.sh | grep -A2 'recent decisions' | grep -qv 'does not exist'

# [4] 마커 정합 + full 투영 바이트 동일성
bash core/scripts/guidance-filter.sh --lint core/protocols/work.md
bash core/scripts/guidance-filter.sh --mode full core/protocols/work.md \
  | cmp -s - core/protocols/work.md

# [3] minimal 투영에서 CONTRACT 생존
bash core/scripts/guidance-filter.sh --mode minimal core/protocols/work.md \
  | grep -qF -- '- path delta:'

# [6] 필드가 Step 9b.0 구간 안에 정확히 1줄
test "$(awk '/^#### Step 9b\.0/{f=1} /^#### Step 9b\.1/{f=0} f' core/protocols/work.md \
  | grep -cE '^- path delta:')" -eq 1
test "$(grep -cE '^- path delta:' core/protocols/work.md)" -eq 1

# [7] 편집 스코프 격리
test "$(git diff --name-only HEAD -- core/protocols/)" = "core/protocols/work.md"
test -z "$(git diff --name-only HEAD -- core/scripts/ core/actions.json)"

# [2][5][7] 전체 스위트 — 하나라도 실패하면 set -e 로 중단
bash core/tests/run-dry.sh
for t in core/tests/test-*.sh; do bash "$t"; done
bash tests/run.sh
```

> `set -e` + 개별 `test` 로 각 단계가 실제 게이트가 되게 했다. 마지막 커맨드의 exit
> 코드만 보는 다중 라인 블록은 앞 단계 실패를 삼킨다.

## Pass criteria

- **자동**: 위 `How to run` 블록이 exit 0. 즉 시나리오 1~7 전부 통과하고 기존
  스위트(`run-dry.sh` · `test-*.sh` · `tests/run.sh`)가 무회귀다.
- **수동 1회**: 시나리오 3의 역방향 확인(필드를 GUIDANCE 안으로 옮기면 실패 재현)이
  성립한다. 이 확인 없이는 안전망이 작동한다고 주장하지 않는다.
- **수동 1회**: 시나리오 8 의 end-to-end — `scv/archive/INDEX.yaml` 생성과
  `- path delta:` 의 실제 내용 기입을 육안 확인한다.
- **CHANGELOG 보고**: `guidance-filter.sh --lint core/protocols/work.md` 의 실측
  `guidance_lines` / `total_lines` / `ratio` 를 CHANGELOG 에 기재하고,
  `docs/guidance-ablation.md` 의 work.md 행을 같은 값으로 맞춘다. **예측값이 아니라
  실측값**을 쓴다.
- **명시할 한계**: 시나리오 9·10 은 실사용 인스턴스가 누적돼야 판정 가능하다. 이번
  릴리스에서는 미검증 상태로 두고, "에이전트가 필드를 빠뜨려도 실패하는 테스트는
  없다"는 사실을 CHANGELOG 에 그대로 적는다.

## Related Documents

<!-- 없음. 검증 근거는 PLAN.md 본문에 파일:줄로 인라인했다. -->
