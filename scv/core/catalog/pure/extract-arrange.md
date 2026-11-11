# 꺼내기/arrange — 글 · JSON · 표에서 값이나 필드를 뽑는다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 1개.

### pa_parse_steps
- 역할: 단계 글(한 줄에 "이름<탭>종류<탭>명령[<탭>after:이름]")을 단계 줄들로 가린다 — 빈 줄과 # 줄은 버리고, 틀린 줄이 있으면 "오류: …" 한 줄과 1
- 위치: scripts/lib/pipe-arrange.sh · @pure · sh
- 예: `$'# 주석\nup\tmap\ttr a-z A-Z\n\nkeep\tfilter\tgrep 7\tafter:up' → $'up\tmap\ttr a-z A-Z\t-\nkeep\tfilter\tgrep 7\tup'`
- 예: `$'top\thead\t100' → $'top\thead\t100\t-'`
- 예: `$'up\tmop\ttr a b' → "오류: 2번째 칸은 map · filter · head · collect 가운데 하나여야 한다 — up" [1]`
- 예: `$'a\tmap\tcat\na\tfilter\tgrep x' → "오류: 이름이 겹친다 — a" [1]`
- 예: `$'top\thead\t많이' → "오류: head 의 3번째 칸은 줄 수(숫자)여야 한다 — top" [1]`
- 예: `$'k\tfilter\tgrep x\tafter:없는것' → "오류: after 가 가리키는 단계가 없다 — k" [1]`
