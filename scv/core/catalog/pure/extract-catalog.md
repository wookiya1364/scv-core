# 꺼내기/catalog — 글 · JSON · 표에서 값이나 필드를 뽑는다

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 2개.

### cm_field
- 역할: 탭으로 나뉜 '이름=값' 줄에서 한 이름의 값을 꺼낸다(없으면 빈 값)
- 위치: scripts/comments-migrate.sh · @pure · sh
- 예: `$'MIGRATE\tfiles=3\tnotes=2' "notes" → "2"`
- 예: `$'MIGRATE\tfiles=3' "x" → ""`

### pc_entries_from_catalog
- 역할: 사전 파일 글들(@@FILE 줄로 나뉨)을 거꾸로 읽어 함수 항목 줄로 낸다 — 사전이 원본인 프로젝트(코드에 주석 없음)의 입구
- 위치: scripts/lib/pure-catalog.sh · @deterministic · sh
- 예: `$'@@FILE count.md\n# 세기 — 센다\n\n### f\n- 역할: 센다\n- 위치: lib/a.sh · @pure · sh\n- 예: `"a" → "1"`' → $'lib/a.sh\tpure\tf\t센다\t세기\t"a" → "1"'`
- 예: `$'@@FILE INDEX.md\n# 차례\n### x\n- 위치: a.sh · @pure · sh' → ""`
