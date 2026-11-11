# 고르기/arrange — 여럿 중 일부를 골라내거나 순서를 매긴다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 2개.

### pa_order
- 역할: 잰 줄들에서 더 빠를 순서를 이름 한 줄씩 낸다 — 벽(head · collect) 사이 구간마다, 놓을 수 있는 단계 가운데 순위 값이 가장 작은 것부터. 바꾸기끼리의 순서와 after 선언은 지킨다. 둘째 인자가 mild 면 바꾸기도 벽으로 본다(이어진 고르기끼리만 바꾼다)
- 위치: scripts/lib/pipe-arrange.sh · @pure · sh
- 예: `$'up\tmap\tA\t-\t0.134\t1.00\ntag\tmap\tB\t-\t0.083\t1.00\nkeep\tfilter\tC\t-\t0.032\t0.41' → $'keep\nup\ntag'`
- 예: `$'up\tmap\tA\t-\t0.134\t1.00\ntag\tmap\tB\t-\t0.083\t1.00\nkeep\tfilter\tC\tup\t0.032\t0.41' → $'up\nkeep\ntag'`
- 예: `$'up\tmap\tA\t-\t0.1\t1.00\nk1\tfilter\tB\t-\t0.05\t0.5\ntop\thead\t10\t-\t0\t0.1\nk2\tfilter\tC\t-\t0.01\t0.1' → $'k1\nup\ntop\nk2'`
- 예: `$'up\tmap\tA\t-\t0.1\t1.00\nsrt\tcollect\tsort\t-\t0.2\t1.00\nk\tfilter\tC\t-\t0.01\t0.1' → $'up\nsrt\nk'`
- 예: `$'k1\tfilter\tA\t-\t0.10\t0.9\nk2\tfilter\tB\t-\t0.01\t0.1\nup\tmap\tC\t-\t0.1\t1.00\nk3\tfilter\tD\t-\t0.01\t0.1' "mild" → $'k2\nk1\nup\nk3'`
- 예: `"" → ""`

### pa_order_mild
- 역할: 잰 줄들에서, 이어진 고르기끼리만 바꾼 순서를 낸다 — 고르기를 바꾸기 앞으로 당긴 순서의 답이 달라졌을 때 쓰는 덜 과감한 순서
- 위치: scripts/lib/pipe-arrange.sh · @pure · sh
- 예: `$'k1\tfilter\tA\t-\t0.10\t0.9\nk2\tfilter\tB\t-\t0.01\t0.1\nup\tmap\tC\t-\t0.1\t1.00' → $'k2\nk1\nup'`
- 예: `$'up\tmap\tA\t-\t0.134\t1.00\nkeep\tfilter\tC\t-\t0.032\t0.41' → $'up\nkeep'`
