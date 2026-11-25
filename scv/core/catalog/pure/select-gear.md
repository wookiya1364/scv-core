# 고르기/gear — 여럿 중 일부를 골라내거나 순서를 매긴다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 2개.

### scv_gear_match_index
- 역할: 기어 사전에서 요청과 낱말이 둘 이상 겹치는 기어 가운데 가장 많이 겹치는 것을 고른다 — "이름<탭>하는 일", 없으면 빈 값
- 위치: scripts/lib/gear.sh · @deterministic · sh
- 예: `"릴리스전에ci검사돌려줘" $'release-ci\tgear\teffect\tnone\tverdict\t릴리스 전 검사\t릴리스 CI 검사\t' → $'release-ci\t릴리스 전 검사'`
- 예: `"대시보드고쳐줘" $'release-ci\tgear\teffect\tnone\tverdict\t릴리스 전 검사\t릴리스 CI 검사\t' → ""`
- 예: `"릴리스검사" $'ci-run\ttooth\teffect\tnone\tresults\t검사를 돌린다\t릴리스 검사\t' → ""`

### scv_gear_match_requests
- 역할: 지난 요청 가운데 점수가 기준을 넘는 것을 세고 대표 한 줄을 고른다 — "수<탭>보이는 글", 없거나 거절한 요청이면 빈 값
- 위치: scripts/lib/gear.sh · @deterministic · sh
- 예: `"릴리스노트를써줘" $'2026-11-24\t릴리스노트써줘\t릴리스 노트 써줘' 60 → $'1\t릴리스 노트 써줘'`
- 예: `"릴리스노트를써줘" $'2026-11-24\t대시보드고쳐줘\t대시보드 고쳐줘' 60 → ""`
- 예: `"릴리스노트를써줘" $'2026-11-24\t릴리스노트써줘\t릴리스 노트 써줘' 60 "릴리스노트써줘" → ""`
