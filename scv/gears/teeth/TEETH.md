# 톱니 사전

톱니마다 역할 · 표시(pure | effect | outward) · 값(받는 값 → 돌려주는 값) · 예시를 적는다.
순수 톱니의 예시는 gear.sh check 가 실제로 돌려 맞춰 본다.

### ci-run
- 역할: 한 저장소의 빠른 검사 명령 목록을 이 컴퓨터에서 하나씩 돌려 결과 줄을 낸다(전체 검사와 리눅스는 깃허브가 한다)
- 표시: effect
- 값: none → results
- 인자: repo=core — 저장소: core · claude · codex · selftest
- 인자: jobs=4 — 한 번에 겹쳐 돌릴 시험 수

### ci-gate
- 역할: 결과 줄에 실패가 하나도 없고 결과가 있으면 RELEASE_OK, 아니면 실패한 명령을 알리고 끝낸다(종료 1)
- 표시: pure
- 값: results → verdict
- 예: $'local\tok\ta\tx' → "RELEASE_OK: 1개 통과"
