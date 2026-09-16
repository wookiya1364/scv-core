---
topic: 답 모양 린트가 한 턴 늦게 본다 (on-stop.sh transcript 읽기 시점)
source: scv/conversations/20260914-092553-install-check-0-47-0.md (Turn 55, 2026-09-16)
---
# 관찰 (확인)
- .help-drift: `turn=3 echo=skip lint=0` → `turn=4 echo=skip lint=1 reload=1`, 경고 `lead-code=/reload-plugins`.
- `/reload-plugins` 는 53턴 답의 첫 문단에 있고 54턴 답에는 없다. 즉 turn 4 의 Stop 훅이 본 "마지막 assistant 텍스트" 는 한 턴 전 답.
- on-stop.sh: `tail -n 400 "$TRANSCRIPT" | jq … select(.type=="assistant") … | last` 로 추출.
# 원인 (추정)
- Stop 훅 실행 시점에 transcript JSONL 에 직전 답이 아직 flush 되지 않았거나, 마지막 assistant 항목이 텍스트 없는 도구 호출 블록이라 `select(length>0)` 에서 빠지고 그 앞 텍스트가 잡힘. 둘 중 무엇인지 확인 필요 (transcript 타임스탬프 vs Stop 훅 시각 비교).
# 영향
- 린트 경고와 재읽기(≈6k 토큰)가 한 턴 늦게, 엉뚱한 턴에 발생. 지문(echo) 검사는 대화 파일을 읽으므로 무관.
# 후보
- Stop 훅 stdin JSON 에 마지막 답 본문이 있는지 확인(`last_assistant_message` 류 필드) → 있으면 그것을 우선.
- 없으면: 마지막 assistant 항목들 중 "이 턴의 user 메시지 이후" 것만 합쳐서 보기 (턴 경계 기준), 또는 텍스트 블록을 이어붙여 마지막 텍스트를 취함.
# 검증 기준
- 시뮬레이션 transcript 에서 N턴 답의 위반이 N턴 Stop 에서 잡힘 (test-help-echo 에 케이스 추가).

# 추가 관찰 (2026-09-16 21:24, 확인)
- 지연은 간헐적. .help-drift: turn=4 는 두 턴 전 답을 봤고(lead-code=/reload-plugins), turn=9 는 직전 답을 제대로 봤다(lead-sentences=3>2 — 58턴 답의 첫 문단, 따옴표 안 마침표가 문장으로 세어짐 → 린트 근사의 오탐 사례).
- turn=8 echo=skip: 사용자가 턴 중간에 메시지(이미지)를 보내 UserPromptSubmit 이 한 턴에 두 번 돌았고, 기록은 한 번 붙었다. appended 판정이 mid-turn 프롬프트에 흔들리는 것으로 보임(추정). 케이스로 추가.
