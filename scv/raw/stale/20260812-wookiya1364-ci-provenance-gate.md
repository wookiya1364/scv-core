# CI 프로버넌스 게이트 — 측정 기록

2026-08-12, scv-core / scv-claude-code / scv-codex 세 저장소에서 직접 확인한 사실.
"계획 없이 구현만 들어간 PR 을 CI 가 막는다" 고 믿어 왔는데, 막는 장치가 실제로는
하나도 없다는 것을 확인했다.

## 확인 1 — 프로버넌스 게이트라는 워크플로가 존재하지 않는다

세 저장소의 `.github/workflows/` 전체 목록:

```
scv-core         branch-flow.yml  core-ci.yml  promote.yml  release.yml  token-health.yml
scv-claude-code  branch-flow.yml  core-contract.yml  core-sync.yml  promote.yml  test-model-policy.yml
scv-codex        branch-flow.yml  core-sync.yml  plugin-ci.yml  promote.yml
```

`grep -rln "provenance\|PLAN.md"` 를 세 저장소의 워크플로 디렉터리에 돌리면 결과가
없다. 계획 문서를 보는 워크플로가 애초에 없다.

## 확인 2 — check-frontmatter.sh 는 실제 저장소에 한 번도 돌지 않는다

`core-ci.yml` 의 `contracts` 잡이 실행하는 것은 다음 넷뿐이다.

```
bash -n (셸 문법)      tests/run.sh      core/tests/run-dry.sh      core/tests/test-*.sh
```

`check-frontmatter.sh` 를 호출하는 곳은 `core/tests/run-dry.sh` 하나이고, 거기서는
`--project-dir` 로 임시 디렉터리에 만든 합성 픽스처를 검사한다. 저장소 자신의
계획 문서는 검사 대상이 아니다.

## 확인 3 — 검사 대상 glob 이 promote/ 하나뿐이라 지금은 공회전한다

`core/scripts/check-frontmatter.sh:101`

```bash
for f in "$PROJECT_DIR/scv/promote"/*/PLAN.md; do
```

scv-core 저장소에서 지금 그대로 돌리면:

```
$ bash core/scripts/check-frontmatter.sh --project-dir .
✓ All frontmatter valid
  exit=0
```

`scv/promote/` 가 비어 있어서 통과한 것이다. 같은 시점에 `scv/archive/` 에는 계획
8 개가 있고, 그중 무엇도 검사되지 않았다.

## 확인 4 — work 는 PR 을 만들기 전에 아카이브한다

`core/protocols/work.md` 의 단계 순서:

```
Step 9b — Archive decision      (line 316)
Step 9d — PR auto-creation      (line 477)
```

아카이브가 PR 생성보다 앞선다. 그래서 PR 시점의 diff 에는 `scv/promote/<slug>` 가
**삭제**로, `scv/archive/<slug>` 가 **추가**로 찍힌다. `scv/promote/` 만 보는 검사는
정작 감시해야 할 그 PR 에서 볼 것이 없다. 봐야 하는 것은 "이 PR 이 추가한
`scv/archive/*/PLAN.md`" 다.

## 확인 5 — flow 스타일 파싱은 Core 에 이미 있다 (내 앞선 진술을 정정)

아카이브된 PLAN 8 개의 `raw_sources` 표기:

```
raw_sources: []      7 개  (flow 스타일, 인라인)
raw_sources:         1 개  (block 스타일, 다음 줄부터 - 항목)
```

flow 스타일이 다수다. 앞서 나는 "인라인 flow 스타일을 파서가 못 읽는 버그가
있다" 고 말했는데, Core 코드를 읽어 보니 **틀렸다**.
`core/scripts/lib/yaml.sh` 의 `yaml_get_list` 는 두 형식을 이미 다 처리한다.

```awk
if (rest ~ /^\[.*\]$/) {                 # flow  — [a, b]
  ...split on comma...
} else if (rest == "") {
  in_block = 1                            # block — 다음 줄부터 - 항목
}
```

거짓 실패는 그때 임시로 쓴 grep 기반 파서에서 났던 것이고, Core 라이브러리에는
그 버그가 없다. 따라서 고칠 버그가 아니라 **지켜야 할 제약**이다: 새 게이트는
자기 파서를 새로 쓰지 말고 `lib/yaml.sh` 를 그대로 쓴다. (재사용 우선 원칙)

## 확인 6 — claude-code 에 죽은 중복 사본이 있다

`scv-claude-code/scripts/check-branch-flow.sh` (59 줄) 와
`scv-claude-code/vendor/scv-core/core/scripts/check-branch-flow.sh` (59 줄) 는
바이트 단위로 같다. 벤더 트리에 Core 스크립트 28 개가 통째로 들어오는데도
자체 사본을 따로 들고 있고, `branch-flow.yml` 은 자체 사본 쪽을 부른다.
codex 는 벤더 경로를 직접 부른다.

## 지금 켜져 있는 것 (2026-08-12 적용)

세 저장소 ruleset 에 `required_status_checks` 를 켰다. 경로 필터가 없어 모든 PR 에
반드시 도는 체크만 골랐다 — 그렇지 않으면 문서만 고친 PR 이 영구히 머지 불가가
된다.

```
scv-core         check · Contracts (ubuntu-latest) · Contracts (macos-latest)
                 · DeckUI · Deterministic release artifact
scv-claude-code  check-branch-flow
scv-codex        check-branch-flow
```

즉 게이트를 새로 만들면 그 체크는 **모든 PR 에서 도는 잡 안에** 있어야 필수로
걸 수 있다. 경로 필터가 걸린 워크플로에 넣으면 필수 지정이 불가능하다.

## 게이트를 만들 때 반드시 피해야 할 것

`promote.yml` 이 여는 `develop → stage`, `stage → main` PR 은 계획 문서를 담지
않는다. 게이트가 이 둘까지 막으면 릴리스 체인 전체가 멈춘다. `core-sync.yml` 이
여는 봇 PR 도 마찬가지다.
