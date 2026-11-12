# 고르기/wrapup — 여럿 중 일부를 골라내거나 순서를 매긴다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 3개.

### scv_wu_empty
- 역할: 칸 줄들에서 값이 비었거나 채울 자리 표시(TODO)가 남은 칸, 칸 수가 모자란 묶음, 아예 없는 묶음을 고른다 — 건너뛴 묶음은 보지 않는다. 묶음마다 필요한 칸 수는 4 · 2 · 1 · 2 · 2 · 3 · 2
- 위치: scripts/lib/wrapup.sh · @pure · sh
- 예: `$'1\t#\t문제\n1\t상황\t느리다\n1\t기대\t' → $'1\t기대\t빈 칸\n1\t-\t칸 2개 · 필요 4개\n2\t-\t묶음 없음\n3\t-\t묶음 없음\n4\t-\t묶음 없음\n5\t-\t묶음 없음\n6\t-\t묶음 없음\n7\t-\t묶음 없음'`
- 예: `$'1\t#\tP\n1\ta\tx\n1\tb\tx\n1\tc\tx\n1\td\tx\n2\t-\tN/A — r\n3\t-\tN/A — r\n4\t-\tN/A — r\n5\t-\tN/A — r\n6\t#\tS\n6\ta\tx\n6\tb\tx\n6\tc\tx\n7\t#\tL\n7\ta\tx\n7\tb\tx' → ""`
- 예: `"" → $'1\t-\t묶음 없음\n2\t-\t묶음 없음\n3\t-\t묶음 없음\n4\t-\t묶음 없음\n5\t-\t묶음 없음\n6\t-\t묶음 없음\n7\t-\t묶음 없음'`

### scv_wu_names
- 역할: 마무리 보고의 묶음 제목과 칸 이름 표를 언어로 고른다 — 묶음마다 "번호<TAB>제목<TAB>칸 이름;칸 이름…" 한 줄, 일곱 묶음 16칸. korean 이면 한국어, 그 밖은 영어
- 위치: scripts/lib/wrapup.sh · @pure · sh
- 예: `korean → $'1\t문제\t상황;기대;실제;재현 조건\n2\t관찰\t관찰한 사실과 측정값;정상일 때와 차이\n3\t가설\tH1\n4\t실험\t방법과 같게 둔 것;결과와 가설별 판정\n5\t원인\t직접 원인과 일어난 길;근본 원인\n6\t해결과 검증\t해결책과 고른 이유;고치기 전후 값;부작용과 회귀 시험\n7\t배운 것\t다음에 같은 문제를 만나면 진단하는 법;다른 곳에도 쓸 수 있는 것'`
- 예: `english → $'1\tProblem\tSituation;Expected;Actual;How to reproduce\n2\tObservation\tFacts and measurements;Difference from the normal case\n3\tHypothesis\tH1\n4\tExperiment\tMethod and what was held equal;Result and verdict per hypothesis\n5\tRoot cause\tDirect cause and how it happens;Underlying cause\n6\tSolution and validation\tSolution and why it was chosen;Before and after values;Side effects and regression tests\n7\tLearning\tHow to diagnose it next time;What applies elsewhere'`

### scv_wu_skip_bad
- 역할: 칸 줄들의 건너뜀 줄 가운데 건너뛸 수 없는 묶음(1 · 6 · 7번)의 것과 이유가 없는 것을 고른다
- 위치: scripts/lib/wrapup.sh · @pure · sh
- 예: `$'2\t-\t해당 없음 — 새 기능이라 고장이 없다' → ""`
- 예: `$'3\t-\t해당 없음' → $'3\t-\t이유 없음'`
- 예: `$'4\t-\tN/A —  ' → $'4\t-\t이유 없음'`
- 예: `$'1\t-\t해당 없음 — 문제 없음\n5\t-\tN/A: new feature' → $'1\t-\t건너뛸 수 없는 묶음'`
- 예: `"" → ""`
