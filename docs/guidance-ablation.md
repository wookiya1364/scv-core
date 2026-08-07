# 가이던스 어블레이션 — CONTRACT / GUIDANCE 마커 규약 (1단계, v0.22.0+)

SCV 프로토콜 md(`core/protocols/*.md`)는 결정론적 **계약(CONTRACT)** 과 행동
**코칭(GUIDANCE)** 이 섞여 있다. Claude Code 의 `CLAUDE_CODE_SIMPLE=1` 과
동형인 스위치를 SCV 에 만들어, "지우고 → 측정하고 → 필요한 것만 되살리는"
어블레이션 체계를 SCV 자체가 갖춘다. 1단계 범위는 **promote.md · work.md
2개 프로토콜**로 한정한다 (나머지 프로토콜은 바이트 불변 — 2단계는 실사용
피드백 후 별도 계획).

## 마커 규약

프로토콜 md 안에서 GUIDANCE 블록을 HTML 주석 마커로 감싼다:

```markdown
<!-- SCV:GUIDANCE -->
...코칭 줄들 (주입에서 생략해도 안전한 내용)...
<!-- /SCV:GUIDANCE -->
```

- 마커는 **한 줄 전체**여야 한다 (열림/닫힘 마커 문자열 외의 내용이 같은
  줄에 있으면 malformed 에러).
- 열림/닫힘은 반드시 짝이 맞아야 하고, **중첩은 금지**된다.
- 마커 밖의 모든 줄은 CONTRACT 다.
- 마커는 HTML 주석이므로 마크다운 렌더(GitHub 등)에서 보이지 않고,
  `action:deck` 렌더에서도 노출되지 않는다 (deck transform 이 마커 줄을
  드롭한다 — GUIDANCE **본문**은 deck 에서 정상 렌더된다: deck 은 문서
  렌더이지 주입이 아니다).

## 분류 기준

> 블록을 **삭제해도 산출물의 형식·경로·불변식이 변하지 않으면 GUIDANCE,
> 변하면 CONTRACT.**

여기서 "산출물"은 다음 세 가지로 측정한다 (어블레이션 하네스가 비교하는
대상과 동일):

1. **생성 파일 목록** — 프로토콜이 만들거나 옮기는 파일들의 경로.
2. **frontmatter 스키마** — 스캐폴드가 쓰는 키 집합/순서 (`title:`,
   `slug:`, `status: planned`, `raw_sources:`, `refs:` …).
3. **스크립트 호출 시퀀스** — `${SCV_CORE_ROOT}/scripts/*.sh` 호출의 순서.

전형적인 CONTRACT: 스크립트 호출 블록, 파일 경로·스캐폴드 템플릿, 상태
전이 규칙(`planned → in_progress → testing`), Never 목록, Flag semantics,
frontmatter 필드 편집 규칙.

전형적인 GUIDANCE: 사용자 질문의 문구/옵션 설명 예시, 안티패턴 목록,
일러스트용 스켈레톤, 셀프 리뷰 체크리스트, 근거 설명("Why …"), 채팅 출력
전용 코칭(언어 선호, 안내 문구).

목표 비율은 정하지 않는다 — 기준만 따르고 **결과 비율을 CHANGELOG 에
보고**한다 (예측하지 말고 측정하라).

## 주입 필터 — `SCV_GUIDANCE=full|minimal`

주입 지점은 래퍼가 Core 를 벤더링할 때 실행되는
`tools/materialize-profile.sh` (← `tools/vendor-core.sh`) 이다. 여기서
`core/scripts/guidance-filter.sh` 가 프로토콜 **투영본**(materialized
copy)에 적용된다. 저장소의 원본 프로토콜 파일은 절대 수정되지 않는다.

| 모드 | 효과 |
|---|---|
| `SCV_GUIDANCE` 미설정 / `full` (기본) | 주입 내용이 원본과 **바이트 동일** (마커 포함 — 렌더 불가시) |
| `SCV_GUIDANCE=minimal` | GUIDANCE 블록(마커+본문)을 제거하고 주입 |
| 그 외 값 | 명확한 에러로 중단 |

```bash
# 단일 파일 필터 (stdout)
SCV_GUIDANCE=minimal bash core/scripts/guidance-filter.sh core/protocols/promote.md

# 마커 lint + 분류 통계
bash core/scripts/guidance-filter.sh --lint core/protocols/promote.md core/protocols/work.md
# → GUIDANCE_LINT: OK file=... guidance_lines=N total_lines=M ratio=P%

# 래퍼 벤더링 시 minimal 주입
SCV_GUIDANCE=minimal bash tools/vendor-core.sh --source . --target vendor/scv-core --profile <host.env>
```

**Fail-closed**: 모든 호출은 출력/재작성 이전에 **모든** 입력 파일의 마커를
검증한다. 짝이 안 맞거나(닫힘 누락·고아 닫힘), 중첩되거나, malformed 이면
`파일:줄` 을 가리키는 에러로 중단하고, stdout 은 비어 있으며 어떤 파일도
재작성되지 않는다 — **부분 주입은 절대 만들어지지 않는다**. full 모드도
검증은 동일하게 수행한다.

## 어블레이션 하네스 (재분류 강제 안전망)

`core/tests/run-dry.sh` 섹션 [19] 가 promote·work 경로를 full/minimal 두
모드로 실행해 다음이 **동일**함을 비교한다:

- 투영 동등성: full 투영 = 원본 바이트 동일, 스크립트 호출 시퀀스와
  frontmatter 스키마 표면이 두 모드에서 동일.
- 실행 동등성: hydrate → promote-helper `--dry-run` → 스캐폴드 → work →
  archive 를 두 모드로 실행 → 생성 파일 목록·frontmatter 키 시퀀스·정규화된
  호출 트랜스크립트가 동일.

차이가 나면 테스트가 실패한다 — 그 지시는 GUIDANCE 가 아니라 CONTRACT 였던
것이므로 마커 밖으로 재분류하라. 마커 정합·fail-closed·deck 비노출·타
프로토콜 무변 검증은 `core/tests/test-guidance.sh` 에 있다.

## 1단계 분류 결과 (측정치)

| 프로토콜 | GUIDANCE 줄 / 전체 줄 | 비율 |
|---|---|---|
| `core/protocols/promote.md` | 241 / 883 | 27.3% |
| `core/protocols/work.md` | 203 / 521 | 39.0% |

(전체 줄 수는 마커 줄 제외 기준. `--lint` 출력과 동일.)
