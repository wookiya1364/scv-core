# 숨은 의도를 끌어내 좋은 결과를 내는 법 — 네 분야 문헌 조사 (2026-10-06)

요청(2026-10-06): "어떻게 해야 사람의 숨은 의도를 파악해서 좋은 결과물을 낼 수 있는지 연구 — 사람의 비위를 맞추지 마."
방법: 네 분야를 배경 조사 넷이 동시에 맡았다 — 요구공학 · 소프트웨어 실무 / LLM · NLP 명확화 질문과 의도 이해(코딩 에이전트 · 긴 다중 턴) / 의사결정 · 능동 학습 · 프로그램 합성 / HCI · 아첨 · 사용자 시뮬레이터 타당성 · 사람의 검증.
규칙: 인용은 원문 페이지를 열어 제목 · 저자 · 연도를 확인한 것만 결론에 쓴다(약 120건 확인, 미확인 5건은 결론에서 뺌 — 맨 끝에 적음). 반대 증거와 '우리 실측이 부풀려졌을 가능성'을 같은 무게로 다룬다.
연결: 계획 scv/promote/20261005-wookiya1364-verify-by-sample/ (끝내기 전 견본 확인 · 건너뛰면 막는 검사), 실측 보고서 scv/raw/stale/20261005-research-elicit-exp.md.

## 한 줄 결론

'끝내기 전에 결과를 보여 주고 확인받기'는 방향은 맞지만, 지금 형태로는 근거가 약하고 우리 숫자는 부풀려졌을 가능성이 크다. 문헌이 가장 강하게 지지하는 형태는 (1) 물을지부터 거르고(틀릴 확률 × 틀렸을 때 비용), (2) 물을 때는 일찍 · 짧게 · 결정을 가르는 것만, (3) 확인은 일반 견본이 아니라 그럴듯한 해석들의 결과가 갈리는 칸(경계 사례)만 보여 주고 글 칸으로 교정을 받으며, (4) 사람의 승인은 정답의 증거가 아니므로 성공은 숨은 테스트로만 판정하는 것이다.

## 네 분야가 함께 말하는 것 (확인된 연구 결과)

| 내용 | 숫자 | 대표 출처 |
|---|---|---|
| 숨은 · 불완전 요구는 실무 1위 문제 | 228곳 중 48% | Méndez Fernández 2017 |
| 에이전트는 스스로 거의 묻지 않는다 | 실사용 Claude Code 턴의 3.0–3.2% | SWE-chat 2026 |
| 작은 모델은 지시해도 놓친다 | Haiku 3.5 놓침 0.97 → 강한 독려에도 0.66 | Ambig-SWE 2026 |
| 정보를 얻으면 이득이 크다(시뮬 사용자) | SWE 상대 +64~74%, 협업 함수 16.2→40.4% | Ambig-SWE, ColBench |
| LLM 사용자는 이득을 부풀린다 | 9~17pt, 실사용자 63.6% vs 시뮬 77.8% | Zhou 2026, Naous 2026, Seshadri 2026 |
| 사람은 표본 · 출처를 잘 대조하지 않는다 | 링크 클릭 2.7%, Claude Code 권한 승인 93%, 그럴듯한 오답 39% 간과 | Kim 2024, Anthropic 2026, Kabir 2024 |
| 시안 하나를 보여 주면 평가가 부풀고 제시자 쪽을 고른다 | 제시자 쪽 선호 2.5배 | Tohidi 2006, Dell 2012 |
| 질문의 가치 = 틀릴 확률 × 틀렸을 때 비용 — 결정을 바꾸지 않는 질문은 가치 0 | 이론(증명) | Horvitz 1999, Golovin 2010 |
| 질문을 독려하면 불필요한 질문이 는다 | 불필요 질문 0 → 0.24 → 0.36 | Ambig-SWE, Ask or Assume? 2026 |
| 늦은 질문은 가치가 급감한다 | 목표 질문 10% 지점 0.78, 70% 이후 0.39(안 물음 0.40) | Gulati 2026 |
| 긴 대화에서 초기 가정 고착 · 요구 망각 | 다중 턴 평균 −39% | Laban 2026 |
| 결과가 갈리는 칸만 보여 주는 확인이 가장 효율적 | 성공 12/12 vs 4/12, 보통 1회 | Zhang 2020, Gulwani 2011, Fakhoury 2024 |
| 시제품 · 예시는 요구 '개수'만 늘리고 정답 대비 완전성은 같다 | p=.17 | Rueda 2020 |
| 사람은 아첨하는 응답을 더 좋아하고, 모델은 '확실해?' 한마디에 굴복한다 | 굴복 42–98% | Sharma 2024 |

## 서로 엇갈리는 것

- **끝에서 확인 vs 늦은 질문은 해롭다.** 우리 실측은 끝에서 확인해 정확도가 올랐고, Gulati 2026 은 늦은 질문이 안 묻느니만 못하다고 했다. 우리 과제가 짧고 고치는 비용이 싸서일 수 있다(추정) — 긴 예제 실측이 이것을 가른다.
- **예시(보여 주기) vs 열린 질문.** 예시는 '알려진 대안 중 고르기', 열린 질문은 '빠진 차원 찾기'에 맞다(Peleg 2018 증명, Handa 2024). 견본은 '만든 것'만 보여 주고 '빠진 것'은 못 보여 준다 — 우리 실측의 '빠진 입력 형식'(18→15)과 같은 방향.
- **가정 목록 · 설명.** 검증을 돕기도 하지만, 맞든 틀리든 수용을 늘리기도 한다(Bansal 2021). 검증 비용을 충분히 낮출 때만 과신이 준다(Vasconcelos 2023).
- **실사용 질문 빈도.** Anthropic 보고(복잡한 작업에서 사람이 끊는 것보다 2배 이상 자주 질문)와 SWE-chat(턴의 3%)이 엇갈린다 — 정의 차이로 보이나 미확인.

## 우리 실측을 다시 읽으면 (듣기 좋은 해석 없이)

- **통계(네 조사가 따로 계산해 같은 값):** 12/18 → 18/18 은 실행을 서로 독립으로 볼 때 p≈0.019 이지만, 같은 과제 6개를 세 번씩 돌린 것이라 실제 독립 단위는 6에 가깝다 — 근거가 약하다. 18 → 15(p≈0.23), 다시 쓰기 끔 8/8 · 켬 6/8(p≈0.47)은 우연과 구분되지 않는다. 18/18 은 천장이라 더 나은 방법을 가를 수 없다.
- **부풀림 경로:** 사용자 역할이 숨은 의도를 목록으로 들고 '한 줄씩 대조'하라는 지시까지 받았다 · 에이전트와 같은 계열 모델 · 과제와 숨은 테스트를 우리가 만들었다 · 숨은 의도가 견본에 '보이는' 형식(열 이름 · 날짜) 위주 · 질문해도 지치지 않는 사용자.
- **할인 추정:** 사람이 차이를 알아챌 확률을 61%(Kabir 2024)로 두면, 18/18 이 아니라 15~16/18 정도다(추정, 미검증).
- **가르지 못한 것:** 이득이 '견본' 때문인지, 확인 단계가 숨은 의도를 덤으로 말할 기회를 준 '대화 횟수' 때문인지, 견본을 만들며 생기는 '자기 점검' 때문인지 지금 실측으로는 가를 수 없다.
- **모델별 차이(Sonnet · Haiku 의 확인 생략)는 알려진 현상과 같은 방향**이다(Ambig-SWE: 작은 모델은 독려해도 놓침).

## SCV 에 대한 시사점 (제안 — 계획은 바꾸지 않음)

| 단위 | 해결책 | 추천 |
|---|---|---|
| 부풀린 숫자 | ① 게으른 사용자 · 함정 표본으로 재기 | ① 다른 개선보다 먼저 |
| 일반 견본 | ① 갈리는 칸만 보여 주는 확인 | ① 부풀림 확인 뒤 |
| 늘어난 질문 | ① 미해결 가정이 있을 때만 묻기 | ① 갈리는 칸과 함께 |
| 막는 검사 | ① 생략만 막고 '항상 묻기'는 강요 안 함 | ① 계획 목표 9 그대로 |
| 판정 | ① 숨은 테스트 + 틀린 견본 잡은 비율 | ① 만족 · 승인은 쓰지 않음 |

1. 부풀린 숫자 위에 다음 개선을 쌓으면 같은 착시가 커진다 — 측정 장치에 '게으른 사용자(확률 p 로 대조 없이 승인)'와 '함정 견본(일부러 한 곳을 틀리게)'을 먼저 넣는다.
2. '갈리는 칸'은 그럴듯한 해석 2~3개를 실제로 돌려 결과가 다른 칸만 보여 주는 방식이다. 모든 해석이 같은 결과를 내면 확인을 건너뛴다(질문 감소).
3. 막는 검사는 문헌상 작은 모델의 생략을 줄일 수 있지만(구조적 강제), 질문 자체를 독려하면 불필요한 질문이 는다 — 검사는 '결과물이 바뀌었는데 확인도 선언도 없음'만 막는다.

## 시험할 가설 (네 분야의 가설을 합쳐 우선순위로)

1. **부풀림 점검** — 사용자 역할을 '게으른'(확률 p∈{0, 0.5, 1}로 대조 없이 승인) · '물은 것만 답함' · '보이지 않는 항목은 모름'으로 바꾸고 함정 견본을 넣어 지금의 이득(+6/18)이 얼마나 남는지. 판정: +3 이하로 줄면 기존 결과는 사용자 역할 덕분. (요구공학 H5 · 의사결정 H5 · HCI H1 · H2 · LLM H3)
2. **갈리는 칸 확인** — 일반 견본 대 '해석이 갈리는 칸 + 가정 + 글 칸' 확인. 지표: 숨은 테스트 모두 통과, 질문 수, 틀린 견본 승인율. 예측: 정답 ≥17/18, 질문 ≤33. (의사결정 H1 · 요구공학 H2 · HCI H3)
3. **묻기 거르기** — 미해결 가정이 있을 때만 확인 · 질문. 예측: 질문 51 → ≤30, 손실 ≤1/18, '건너뛰었는데 틀림' 비율을 함께 잼. (의사결정 H2 · HCI H5 · 요구공학 H1 · LLM H2)
4. **보이지 않는 요구** — 숨은 항목을 견본에 '보임'과 '안 보임'(입력 형식 · 비기능 · 바꾸면 안 되는 것)으로 나눠 항목별 통과율. 예측: 이득이 '보임' 쪽에 몰리고, '안 보임'은 앞단 질문 3개 이하로 회복. (요구공학 H3 · LLM H4 · 의사결정 H3)
5. **구조적 강제** — 확인 생략을 종료 훅으로 막으면 Sonnet · Haiku 생략률(3/12 · 8/12)이 1/12 이하로. 계획 목표 9 를 구현한 뒤 세 모델 측정에서. (LLM H1)
6. **긴 세션 망각** — 마지막 확인에 '누적 요구 목록 대조'를 넣으면 긴 예제에서 망각이 줄어드는지. (LLM H5)
7. **아첨 저항 · 교정 반영** — 맞는 견본에 '확실해요?', 틀린 기술적 교정, 정당한 지적 1회에 대한 굴복률 · 반영률을 모델별로. (HCI H4)

## 진행 중인 긴 예제 실측과의 관계

긴 예제는 공개 벤치마크 SWE-Interact 의 과제 내용(실제 오픈소스 저장소 · 숨은 명세 · 숨은 테스트)을 이 맥에서 지난 장치로 돌린다(사용자 결정 2026-10-06). 그 과제의 관리자는 '바쁜 동료 · 대충 시키는 사람' — 처음엔 모호하게, 구현을 검토하며 요구를 하나씩만 드러낸다. 숨은 의도가 형식 · 취향이 아니라 기능 명세라서 가설 4(보이지 않는 요구)와 '끝에서 확인 vs 늦은 질문'의 엇갈림을 직접 시험한다. 절차 · 판정 기준은 그 장치의 기준 파일에 돌리기 전에 고정했다.

## 출처 (분야별 · 모두 원문 확인)

**요구공학 · 실무(29)** — Méndez Fernández 2017 doi.org/10.1007/s10664-016-9451-7 · Davis 2006 doi.org/10.1109/RE.2006.17 · Dieste & Juristo 2011 doi.org/10.1109/TSE.2010.33 · Rueda 2020 doi.org/10.1016/j.infsof.2020.106361 · Boehm 1984 doi.org/10.1109/TSE.1984.5010238 · Gordon & Bieman 1995 doi.org/10.1109/52.363162 · Ricca 2009 doi.org/10.1016/j.infsof.2008.01.007 · Fakhoury 2024 doi.org/10.1109/TSE.2024.3428972 · Binamungu & Maro 2023 doi.org/10.1016/j.jss.2023.111749 · Adzic 2011 manning.com/books/specification-by-example · Polanyi 1966 · Gervasi 2013 doi.org/10.1007/978-3-642-34419-0_2 · Ferrari 2016 doi.org/10.1007/s00766-016-0249-3 · Spoletini 2018 doi.org/10.1007/978-3-319-77243-1_7 · Berry 2003 cs.uwaterloo.ca/~dberry/handbook/ambiguityHandbook.pdf · Chantree 2006 doi.org/10.1109/RE.2006.31 · Philippo 2013 doi.org/10.1007/978-3-642-37422-7_5 · de Bruijn & Dekkers 2010 doi.org/10.1007/978-3-642-14192-8_21 · Tohidi 2006 doi.org/10.1145/1124772.1124960 · Dell 2012 doi.org/10.1145/2207676.2208589 · Appan & Browne 2012 doi.org/10.2307/41410407 · Appan & Browne 2010 doi.org/10.17705/1jais.00228 · Browne & Rogich 2001 doi.org/10.1080/07421222.2001.11045665 · Pitts & Browne 2007 doi.org/10.1111/j.1365-2575.2006.00240.x · Aranda 2016 doi.org/10.1109/TSE.2015.2494588 · Bano 2019 doi.org/10.1007/s00766-019-00313-0 · Mohanani 2014 doi.org/10.1145/2568225.2568235 · Martin 2004 doi.org/10.1109/ADEVC.2004.23

**LLM · NLP · 코딩 에이전트(30)** — CLAM arxiv.org/abs/2212.07769 · Clarify When Necessary aclanthology.org/2025.findings-naacl.306 · GATE arxiv.org/abs/2310.11589 · STaR-GATE arxiv.org/abs/2403.19154 · ClarifyGPT arxiv.org/abs/2310.10996 · HumanEvalComm arxiv.org/abs/2406.00215 · Ambig-SWE arxiv.org/abs/2502.13069 · SWEET-RL/ColBench arxiv.org/abs/2503.15478 · Herlihy 2024 arxiv.org/abs/2406.01633 · Laban 2026 arxiv.org/abs/2505.06120 · CollabLLM arxiv.org/abs/2502.00640 · MediQ arxiv.org/abs/2406.00922 · What Prompts Don't Say aclanthology.org/2026.findings-acl.441 · TiCoder arxiv.org/abs/2404.10100 · MINT arxiv.org/abs/2309.10691 · Ask or Assume? arxiv.org/abs/2603.26233 · CLARITI arxiv.org/abs/2604.14624 · HiL-Bench arxiv.org/abs/2604.09408 · Ask Early, Ask Late, Ask Right arxiv.org/abs/2605.07937 · UnderSpecBench arxiv.org/abs/2607.02294 · SWE-Interact arxiv.org/abs/2606.30573 · SWE-Together arxiv.org/abs/2606.29957 · Asuka-Bench arxiv.org/abs/2606.05920 · Lost in Simulation aclanthology.org/2026.acl-long.2192 · Flipping the Dialogue arxiv.org/abs/2510.06552 · SWE-chat arxiv.org/abs/2604.20779 · Anthropic 2026 anthropic.com/research/measuring-agent-autonomy · DriftBench arxiv.org/abs/2604.28031 · TheAgentCompany arxiv.org/abs/2412.14161 · CodeAssistBench arxiv.org/abs/2507.10646

**의사결정 · 능동 학습 · 프로그램 합성(29)** — Horvitz 1999 doi.org/10.1145/302979.303030 · Tsvilodub 2026 arxiv.org/abs/2602.02843 · Golovin 2010 arxiv.org/abs/1010.3091 · Hadfield-Menell 2016 arxiv.org/abs/1606.03137 · Shah 2020 aima.cs.berkeley.edu/~russell/papers/neurips20ws-assistance.pdf · Gulati 2026 arxiv.org/abs/2605.07937 · Jha 2010 doi.org/10.1145/1806799.1806833 · Gulwani 2011 doi.org/10.1145/1926385.1926423 · Mayer 2015 doi.org/10.1145/2807442.2807459 · Zhang 2020 doi.org/10.1145/3379337.3415900 · Peleg 2018 doi.org/10.1145/3180155.3180189 · Ji 2020 doi.org/10.1145/3385412.3386025 · Barnaby 2026 arxiv.org/abs/2604.08792 · Fakhoury 2024 arxiv.org/abs/2404.10100 · Mu 2023 arxiv.org/abs/2310.10996 · Kobalczyk 2025 arxiv.org/abs/2502.04485 · Rothe 2017 arxiv.org/abs/1711.06351 · Grand 2024 arxiv.org/abs/2402.19471 · Bıyık 2019 arxiv.org/abs/1910.04365 · Piriyakulkij 2023 arxiv.org/abs/2312.12009 · Handa 2024 arxiv.org/abs/2403.05534 · Hu 2024 arxiv.org/abs/2402.03271 · Vijayvargiya 2026 arxiv.org/abs/2502.13069 · Edwards 2026 arxiv.org/abs/2603.26233 · Li 2025 arxiv.org/abs/2310.11589 · Choudhury 2026 arxiv.org/abs/2508.21184 · Rainforth 2024 arxiv.org/abs/2302.14545 · Sloman 2022 arxiv.org/abs/2205.13698 · Shah 2019 arxiv.org/abs/1902.04198

**HCI · 아첨 · 사용자 시뮬레이터 · 사람의 검증(35)** — Clark & Brennan 1991 · Horvitz 1999 · Amershi 2019 · Zou 2023 TOIS · Zou 2023 IP&M · Chen CHI'25 arxiv.org/abs/2410.04596 · CollabLLM · TiCoder · Sharma ICLR'24 arxiv.org/abs/2310.13548 · Perez 2023 arxiv.org/abs/2212.09251 · Wei 2023 arxiv.org/abs/2308.03958 · SYCON-Bench arxiv.org/abs/2505.23840 · Cheng 2025 arxiv.org/abs/2510.01395 · XYEval arxiv.org/abs/2609.23939 · Laban 2026 · Kim FAccT'24 arxiv.org/abs/2405.00623 · Kabir CHI'24 arxiv.org/abs/2308.02312 · Perry CCS'23 arxiv.org/abs/2211.03622 · Anthropic 2026 anthropic.com/engineering/claude-code-auto-mode · Parasuraman & Manzey 2010 · Goddard 2012 · Buçinca 2021 arxiv.org/abs/2102.09692 · Bansal 2021 arxiv.org/abs/2006.14779 · Vasconcelos 2023 arxiv.org/abs/2212.06823 · Vasconcelos 2024 arxiv.org/abs/2302.07248 · Ferdowsi 2024 arxiv.org/abs/2306.09541 · Zhou COLM'26 arxiv.org/abs/2603.11245 · Naous ICLR'26 arxiv.org/abs/2510.06552 · Seshadri 2026 arxiv.org/abs/2601.17087 · SimulatorArena arxiv.org/abs/2510.05444 · Ambig-SWE · Panickssery 2024 arxiv.org/abs/2404.13076 · METR 2025 arxiv.org/abs/2507.09089 · Wen ICLR'25 arxiv.org/abs/2409.12822(재분석 반박으로 결론에서 뺌) · Chandna ICLR'26

**미확인(결론에 쓰지 않음):** Howard 1966 'Information Value Theory'(원문 접근 실패) · Clark & Schaefer 1989 · Kiesel 외 2018 · Davis 2006 의 '중간 표현물' 정의 · Appan 2012 의 효과 크기.
