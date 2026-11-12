# 조립/wrapup — 조각을 받아 정해진 모양의 글을 만든다 — 줄 · 표 · 메시지

> 생성물 — 원본은 각 함수 위 주석(역할 · 종류 · 예). 3개.

### scv_wu_digest
- 역할: 칸 줄들로 끝 답에 실을 마무리 보고 글을 만든다 — 묶음 제목 한 줄, 그 아래 칸은 "   - 이름: 값", 건너뛴 묶음은 건너뜀 줄 그대로
- 위치: scripts/lib/wrapup.sh · @pure · sh
- 예: `$'1\t#\t문제\n1\t상황\t느리다\n2\t#\t관찰\n2\t-\t해당 없음 — 새 기능' → $'1. 문제\n   - 상황: 느리다\n2. 관찰\n   해당 없음 — 새 기능'`
- 예: `"" → ""`

### scv_wu_head
- 역할: 새 마무리 보고 파일의 머리를 만든다 — 제목 줄과, 언제 무엇을 채우는지 적은 안내 주석. korean 이면 한국어, 그 밖은 영어
- 위치: scripts/lib/wrapup.sh · @pure · sh
- 예: `korean "로그인 고침" → $'# 마무리 보고 — 로그인 고침\n\n<!-- 계획을 세울 때 아는 만큼(적어도 1번) 채우고, 일이 끝난 뒤 모든 칸을 채운다.\n     고장을 고치는 계획이 아니면 2 ~ 5번은 묶음마다 "해당 없음 — 이유" 한 줄로 건너뛴다.\n     1 · 6 · 7번은 모든 계획이 채운다. 빈 칸이 있으면 보관되지 않는다. -->'`
- 예: `english "Login fix" → $'# Wrap-up — Login fix\n\n<!-- Fill what is known when the plan is written (at least group 1), and every field once the work is done.\n     A plan that does not fix something that went wrong skips groups 2-5 with one line each: "N/A — reason".\n     Groups 1, 6 and 7 are filled by every plan. The archive is refused while a field is empty. -->'`

### scv_wu_skeleton
- 역할: 묶음 제목과 칸 이름 줄들로 새 마무리 보고 파일의 몸을 만든다 — 묶음마다 "## 번호. 제목" 머리와 채울 자리(TODO)만 있는 칸 줄
- 위치: scripts/lib/wrapup.sh · @pure · sh
- 예: `$'1\t문제\t상황;기대\n3\t가설\tH1' → $'## 1. 문제\n\n- 상황: <TODO>\n- 기대: <TODO>\n\n## 3. 가설\n\n- H1: <TODO>'`
- 예: `"" → ""`
