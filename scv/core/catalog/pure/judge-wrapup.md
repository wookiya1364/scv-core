# 판정/wrapup — 입력을 보고 예/아니오나 판정 이름 하나를 낸다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 2개.

### scv_wu_points
- 역할: 계획 문서 글이 마무리 보고 파일(WRAPUP.md)을 가리키는지 가린다 — 가리키지 않으면 이 기능 전에 세운 옛 계획이다
- 위치: scripts/lib/wrapup.sh · @pure · sh
- 예: `$'## Links\n- 마무리 보고: [`WRAPUP.md`](./WRAPUP.md)' → "yes"`
- 예: `$'## Links\n- Related PRs:' → "no"`
- 예: `"" → "no"`

### scv_wu_verdict
- 역할: 보관해도 되는지 가린다 — 첫 줄은 pass(다 채움) · legacy(보고 파일도 가리킴도 없는 옛 계획) · block(막음), block 이면 그 아래에 이유를 한 줄씩 붙인다
- 위치: scripts/lib/wrapup.sh · @pure · sh
- 예: `"" "" yes yes → "pass"`
- 예: `"" "" no no → "legacy"`
- 예: `"" "" no yes → $'block\n마무리 보고 파일 없음 — 계획 문서가 WRAPUP.md 를 가리킨다'`
- 예: `$'7\t다른 곳에도 쓸 수 있는 것\t빈 칸' $'3\t-\t이유 없음' yes yes → $'block\n묶음 7 · 다른 곳에도 쓸 수 있는 것 — 빈 칸\n묶음 3 — 이유 없음'`
- 예: `$'6\t-\t칸 2개 · 필요 3개' "" yes no → $'block\n묶음 6 — 칸 2개 · 필요 3개'`
