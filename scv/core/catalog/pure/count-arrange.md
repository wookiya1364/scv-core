# 세기/arrange — 개수 · 길이 · 합계를 센다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 3개.

### pa_count_orders
- 역할: 단계 수에서, 순서를 전부 돌려 볼 때의 가짓수(계승)를 낸다 — 20을 넘으면 "아주 많음"
- 위치: scripts/lib/pipe-arrange.sh · @pure · sh
- 예: `3 → "6"`
- 예: `6 → "720"`
- 예: `0 → "1"`
- 예: `21 → "아주 많음"`

### pa_expected
- 역할: 잰 줄들과 순서(이름 한 줄씩)에서 그 엮음의 예상 시간(초, 소수 셋째 자리)을 계산한다 — Σ 단계 시간 × 그 단계까지 살아남은 줄의 비율. head 는 살아남은 비율을 그 값으로 깎는다
- 위치: scripts/lib/pipe-arrange.sh · @pure · sh
- 예: `$'up\tmap\tA\t-\t0.134\t1.00\ntag\tmap\tB\t-\t0.083\t1.00\nkeep\tfilter\tC\t-\t0.032\t0.41' $'up\ntag\nkeep' → "0.249"`
- 예: `$'up\tmap\tA\t-\t0.134\t1.00\ntag\tmap\tB\t-\t0.083\t1.00\nkeep\tfilter\tC\t-\t0.032\t0.41' $'keep\nup\ntag' → "0.121"`
- 예: `$'up\tmap\tA\t-\t0.100\t1.00\ntop\thead\t10\t-\t0\t0.10\nk\tfilter\tC\t-\t0.050\t0.50' $'up\ntop\nk' → "0.105"`
- 예: `"" "" → "0.000"`

### pa_rank
- 역할: 한 단계의 순위 값 "(통과 비율 − 1) ÷ 걸린 시간"을 천 배 한 정수로 낸다 — 작을수록 앞에 놓는다(시간이 0이면 0.001초로 본다)
- 위치: scripts/lib/pipe-arrange.sh · @pure · sh
- 예: `0.030 0.41 → "-19666"`
- 예: `0.134 1.00 → "0"`
- 예: `0 0.5 → "-500000"`
- 예: `0.5 1.20 → "400"`
- 예: `x 1 → "0"`
