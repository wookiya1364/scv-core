# Test Plan — 원격 화면에도 비우기 전 직전 대화가 보인다

## Overview

대화에 저장되는 출력 줄이 한 줄 안내 대신 줄인 직전 대화를 담는지, 줄이는 규칙(앞 150자 + 끝 150자, 300자 이하면 전체)이 맞는지, 호스트 화면에 그리는 글이 그대로인지를 본다.

## Test scenarios

### T1. 300자 이하인 글은 그대로다

- **Setup**: 300자인 글
- **Run**: `trimTalk(글)`
- **Expected**: 받은 글과 같다
- **Pass criterion**: 돌려준 글 === 받은 글

### T2. 300자를 넘는 글은 앞 150자 + 줄임표 + 끝 150자다

- **Setup**: 400자인 글(앞 · 가운데 · 끝이 서로 다른 글자)
- **Run**: `trimTalk(글)`
- **Expected**: 앞 150자로 시작하고 끝 150자로 끝나며, 가운데에 `…` 줄이 하나 있다
- **Pass criterion**: 시작 · 끝 글자열이 일치하고 가운데 글자는 없다

### T3. 저장할 글에 직전 대화가 모두 들어간다

- **Setup**: 직전 대화 3개(하나는 답이 400자, 하나는 내 글이 없는 턴)
- **Run**: `storedTalkPage(직전 대화들)`
- **Expected**: 머리말 한 줄(표시용이며 할 일이 아님) + `── 직전 대화 1 / 3 ──` ~ `3 / 3`, 긴 답은 줄여져 있고, 내 글이 없는 턴은 지금의 안내 글을 쓴다
- **Pass criterion**: 구분 줄 3개, 긴 답의 가운데 글자 없음, 머리말에 "할 일이 아닙니다" 포함

### T4. 직전 대화가 없으면 지금의 한 줄 안내다

- **Setup**: 빈 목록
- **Run**: `storedTalkPage([])`
- **Expected**: 지금의 한 줄 안내 글
- **Pass criterion**: `TALK_STORED` 와 같다

### T5. 저장될 때 출력 줄이 줄인 직전 대화로 바뀐다

- **Setup**: 기억해 둔 직전 대화 2개, 모드의 명령 줄 뒤에 온 출력 줄
- **Run**: 저장 훅
- **Expected**: 출력 줄의 글이 줄인 직전 대화이고, 앞뒤 표시(출력 줄 태그)는 그대로다
- **Pass criterion**: 저장된 글에 `── 직전 대화 1 / 2 ──` 가 있고 태그가 남아 있다

### T6. 호스트 화면에 그리는 글은 그대로다

- **Setup**: 답이 400자인 직전 대화
- **Run**: `talkPage(직전 대화들, 기록 자리)`
- **Expected**: 답 전체가 들어 있다(줄이지 않음)
- **Pass criterion**: 400자가 모두 있다

### T7. 다른 명령의 출력 줄은 바뀌지 않는다

- **Setup**: 다른 명령의 명령 줄 뒤에 온 출력 줄
- **Run**: 저장 훅
- **Expected**: 받은 그대로 넘긴다
- **Pass criterion**: 글이 같다

## How to run

scv-mods 저장소에서:

```bash
claude plugin test marketplace/mods/scv-dashboard
```

## Pass criteria

- T1–T7 통과, 모드 시험 전부 통과
- 실제 저장 글 하나가 보고에 남아 있다

## Related Documents
