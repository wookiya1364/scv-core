# 순수함수 전체를 한 번 잰 표 — bash 3 (2026-11-11)

- 이 맥(Apple M3 Pro)에서 `pure-bench.sh bench` 로 잼. 입력 1배 = 사전의 예시를 25번 되풀이, 4배 = 100번.
- 잰 환경: bash 3.2.57(1)-release · LC_ALL= · GPU 도구 none
- 잰 함수 362 · 못 잰 함수 1(불러오지 못함 0 · 셸 함수 아님 0 · 재지 못함 1) · 늘려 재지 못함 154 · 배수 한도 넘음 15 · 입력만큼 부름 1

## 눈에 띄는 것

| 함수 | 하는 일 | 한 번(ms) | 4배 입력(ms) | 배수 | 부른 횟수 | 비고 |
|---|---|---|---|---|---|---|
| key_of | 폴더 경로를 사진 파일 이름으로 바꾼다 | 0.307 | 6.140 | 20.0 | 0 → 0 | 배수 한도(8배) 넘음 |
| settings_merge_defaults | 사용자 JSON 에 기본값 JSON 을 깔아 병합한다 | 15.182 | - | - | 2 → - | 재지 못함 |
| scv_as_count_terms | 한 줄에 낱말 목록 중 몇 개가 들어… | 102.250 | 375.000 | 3.7 | 51 → 201 | 입력만큼 부름 |
| scv_lint_hangul_ratio | 글에서 한글 글자가 한글 · 영문 글자 중… | 19.867 | 409.000 | 20.6 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_mx_aggregate | 지표 줄들을 값 있는 수 · 전체 수… | 4.433 | 42.750 | 9.6 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_reg_split_chain | 한 줄을 &&, //, ; 로 이은 조각들로… | 13.318 | 108.667 | 8.2 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_is_rewrite_quote | 한 줄이 다시 쓴 요청 인용 줄 | 0.910 | 28.091 | 30.9 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_lint_lang_turn | 마지막 답과 이번 턴 글 전체에서, 한국어 설정인데… | 167.500 | 2560.000 | 15.3 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_mp_answer_shows_rewrite | 답의 코드 블록 밖 인용 줄에 다시 쓴… | 4.817 | 81.750 | 17.0 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_mp_scope_forbid | 범위 칸이 변경을 막는 첫머리면 그 문구를, 아니면… | 15.368 | 164.500 | 10.7 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_plan_conflict_after | 뒤쪽 충돌 검사 | 117.000 | 22051.000 | 188.5 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_plan_conflict_before | 앞쪽 충돌 검사 | 616.000 | - | - | 0 → - | 4배 입력에서 너무 오래 걸려 끊음 · 배수 한도(8배) 넘음 |
| pc_duplicate_pairs | '지문<탭>함수' 줄들에서 지문이 같은 함수 짝을 들어온 순서대로… | 22.538 | 364.000 | 16.2 | 0 → 0 | 배수 한도(8배) 넘음 |
| pc_mutual_pairs | 방향 있는 '가<탭>나' 줄들에서 양쪽 방향이 다 있는… | 17.222 | 275.000 | 16.0 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_lang_drop_machine | 사람이 쓰지 않은 기계 글 블록 | 1.146 | 12.227 | 10.7 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_lint_strip_quoted | 글에서 따옴표 · 괄호 안을 비워 인용문 속… | 0.607 | 5.833 | 9.6 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_tc_words | 글을 맞대기용 낱말들로 나눈다 | 22.000 | 385.000 | 17.5 | 0 → 0 | 배수 한도(8배) 넘음 |

## 엮은 함수 (다른 순수함수를 2개 이상 부르는 함수)

| 엮은 함수 | 하는 일 | 부르는 함수 | 묶음 한 번(ms) | 부품 합(ms) | 4배 배수 | 부른 횟수 |
|---|---|---|---|---|---|---|
| pb_targets | 사전 글에서 잴 목록 "함수<탭>파일<탭>언어<탭>1배 인자<탭>4배 인자<탭>늘림 | pc_split_example · pb_scale_args | 47.000 | 3.991 | 3.8 | 0 → 0 |
| pb_compare | 한 함수의 앞뒤 잰 줄 | pb_to_milli · pb_ratio | 2.427 | 0.939 | - | 0 → - |
| pc_text_duplicates | 항목들의 예시를 글로 비교해, 같은 입력에 같은 출력인… | pc_split_example · pc_lang_of | 79.250 | 0.289 | 4.1 | 1 → 1 |
| scv_asks_in_text | 답이 사용자에게 글로 고르게 하거나 묻는 꼴로 끝나면… | _scv_choice_blank · _scv_choice_cue_real · scv_choice_q_after · scv_choice_q_asks · _scv_choice_has_text | 4.117 | 1.928 | 3.4 | 0 → 0 |
| scv_dreams_periods | 사람 턴 줄들과 보관 줄들을 기간별 질의 ·… | scv_show_real_local_date · scv_dreams_period_ord · scv_dreams_period_range · scv_dreams_ratio | 35.000 | 2.260 | 3.9 | 0 → 0 |
| scv_dreams_distribution | 계획마다 보관까지의 사람 질의 수와 근거 턴 id… | scv_show_real_local_date · scv_dreams_pasted | 35.444 | 0.158 | 4.1 | 0 → 0 |
| scv_dreams_evidence | 개선점 줄들이 가리킨 턴 id 의 사람 메시지를… | scv_dreams_pasted · scv_dreams_mask | 30.000 | 16.625 | 1.0 | 2 → 2 |
| scv_dreams_judge_prompt | 개선점 줄 하나와 가린 발췌들로 판정자에게 보낼 질문… | scv_dreams_tip_text · scv_dreams_tip_rule | 1.156 | 0.102 | 1.0 | 0 → 0 |
| scv_dreams_render_summary | 기간 · 개선점 줄들로 다음 턴에 싣는 [SCV… | scv_dreams_totals · scv_dreams_tip_text · scv_dreams_ratio | 0.671 | 1.728 | - | 0 → - |
| scv_dreams_svg_bars | 제목과 "라벨 탭 값" 줄들로 막대 차트 SVG… | scv_dreams_tag · scv_dreams_esc | 27.000 | 0.142 | 4.0 | 0 → 0 |
| scv_dreams_render_html | 기간 · 분포 · 개선점 · 근거 ·… | scv_dreams_totals · scv_dreams_tag · scv_dreams_esc · scv_dreams_ratio · scv_dreams_day · scv_dreams_svg_bars · scv_dreams_tip_text | 1.899 | 28.914 | - | 0 → - |
| scv_answer_lint | 답 본문의 골격 | scv_lint_sentences · scv_is_rewrite_quote · scv_lint_bullet_polite · scv_lint_lang_verdict · scv_lint_hangul_ratio | 41.250 | 23.512 | 4.2 | 0 → 0 |
| scv_mp_principle_section | 원칙 파일 본문에서 언어에 맞는 구역을 꺼낸다 | scv_mp_principle_lang · scv_mp_principle_pick | 1.613 | 0.815 | 1.3 | 0 → 0 |
| scv_mp_guide_from_events | 사건 줄들을 접어 이 모델 원문을 읽었는지 | scv_mp_guide_decide · scv_mp_guide_fold | 2.431 | 2.196 | 4.1 | 0 → 0 |
| scv_mp_effort_verdict | effort 를 물을지 정한다 | scv_mp_switch · scv_mp_effort_word | 1.561 | 0.988 | - | 0 → - |
| scv_mx_parse_index | INDEX.yaml 텍스트에서 slug · status · obsoleted_by 를… | scv_mx_trim · scv_mx_strip_comment | 153.000 | 0.565 | 3.8 | 0 → 0 |
| scv_mx_parse_plan | PLAN.md 프런트매터에서 대화 경로 · supersedes 개수 ·… | scv_mx_trim · scv_mx_strip_comment | 9.567 | 0.565 | 1.9 | 0 → 0 |
| scv_mx_parse_decisions | DECISIONS.md 에서 | scv_mx_civil_to_minutes · scv_mx_trim | 26.833 | 0.146 | 4.1 | 0 → 0 |
| scv_plan_mark_pause | 계획 A 를 보류로 바꾼다 | scv_plan_fm_set · scv_plan_history_add | 12.917 | 9.263 | 3.7 | 0 → 0 |
| scv_plan_link_return | 새 계획 B 에 끝나면 돌아갈 계획 A… | scv_plan_fm_set · scv_plan_history_add | 6.100 | 9.263 | 3.7 | 0 → 0 |
| scv_plan_mark_resume | 보류였던 계획 A 를 진행 중으로 되돌린다 | scv_plan_fm_get · scv_plan_fm_set · scv_plan_fm_drop · scv_plan_history_add | 17.125 | 12.443 | 4.7 | 0 → 0 |
| scv_plan_conflict_before | 앞쪽 충돌 검사 | scv_plan_goal_items · scv_plan_steps · scv_plan_norm_req | 616.000 | 10.051 | - | 0 → - |
| scv_show_real_split | 기록 항목 줄들을 사람 턴 줄들 | scv_mp_prompt_kind · scv_show_real_is_confirm · scv_show_real_quotes | 19.800 | 3.826 | 3.9 | 0 → 0 |
| scv_show_real_classify | 사람 턴 줄마다 바뀜 · 보여 줌 ·… | scv_asks_in_text · scv_answer_body · scv_show_real_lines · scv_show_real_is_nochange · scv_show_real_is_correction | 2.770 | 7.680 | 1.2 | 0 → 0 |
| scv_show_real_pick | 사람 턴 줄들에서 두 기간 안에서 출력을 보였으나… | scv_show_real_is_nochange · scv_asks_in_text · scv_answer_body · scv_show_real_lines · scv_show_real_local_date | 3.400 | 7.643 | 1.2 | 0 → 0 |
| scv_show_real_render | 셈 두 줄과 언어 · 기간 · 파일… | scv_show_real_pct · scv_show_real_per | 61.600 | 0.081 | 3.9 | 0 → 0 |
| scv_tc_nongoal_hits | 덧붙이거나 진행으로 적으려는 글에 계획의 '하지 않음' | scv_tc_words · scv_tc_overlap_count · scv_plan_norm_req · scv_plan_goal_items | 37.750 | 27.740 | 4.0 | 0 → 0 |
| scv_reg_collect_keys | 여러 블록의 줄에서 시험 줄 키를 처음 나온… | scv_reg_line_key · scv_reg_split_chain | 112.000 | 13.467 | 4.2 | 0 → 0 |
| scv_reg_rewrite_line | 시험 줄이면 그 명령을 기록된 종료 코드 ' | scv_reg_line_key · scv_reg_split_chain | 26.000 | 13.467 | 5.8 | 0 → 0 |
| scv_rc_precedence_violations | 우선순위 어휘를 담은 줄 중 참조형 · 허용… | scv_rc_is_precedence · scv_rc_is_reference | 0.363 | 0.153 | 1.6 | 0 → 0 |

## 전체

| 함수 | 하는 일 | 잣대 | 한 번(ms) | 4배 입력(ms) | 배수 | 메모리(MB) | 부른 횟수 | 비고 |
|---|---|---|---|---|---|---|---|---|
| pb_block_text | 한도를 넘은 것의 사람이 읽는 줄들에서, 멈춘 턴에… | cpu | 0.083 | 0.233 | 2.8 | 3.2 | 0 → 0 |  |
| pb_fail_lines | 판정 줄들 | cpu | 1.700 | 5.860 | 3.4 | 3.2 | 0 → 0 |  |
| pb_render | 표의 줄들 | cpu | 1.028 | 1.267 | 1.2 | 3.5 | 0 → 0 |  |
| pb_render_compare | 앞뒤 잰 줄들과 판정 줄들에서 사람이 읽는 표… | cpu | 1.700 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| pb_render_composed | 엮은 함수 줄들 | cpu | 2.580 | 3.213 | 1.2 | 3.4 | 0 → 0 |  |
| pb_row | 한 함수의 1배 줄과 4배 줄 | cpu | 1.693 | 1.767 | 1.0 | 3.2 | 0 → 0 |  |
| env_settings_unset_args | SCV_ENV_LOADED_KEYS 의 키마다 "-u 키" 두 줄을 내… | cpu | 0.032 | - | - | 2.8 | 0 → - | 늘려 재지 못함 |
| pc_render_catalog | 항목 · 종류 표 · 다른 언어 짝으로… | cpu | 2.000 | 2.260 | 1.1 | 3.1 | 1 → 1 |  |
| record_index_entry | 종류 · 키 · 파일 · 오프셋 ·… | cpu | 0.960 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| run_manifest_path | 계획 슬러그로 실행 매니페스트 파일 경로를 만든다 | cpu | 0.038 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_as_render | 묶음 줄들을 사람이 읽는 검색 결과 글로 만든다 | cpu | 0.053 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_choice_line | 선택지 도구 이름으로 매 턴 싣는 안내 한… | cpu | 0.034 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_choice_reason | 글로 묻고 끝낸 턴을 막을 때 모델에게 보이는… | cpu | 0.041 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_delegate_block | 위임 스위치가 켜진 프로젝트에 싣는 고정 지시 블록 | cpu | 0.064 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_dreams_judge_prompt | 개선점 줄 하나와 가린 발췌들로 판정자에게 보낼 질문… | cpu | 1.156 | 1.197 | 1.0 | 3.2 | 0 → 0 |  |
| scv_dreams_ratio | 두 수로 비율 "n.n" | cpu | 0.041 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_dreams_render_html | 기간 · 분포 · 개선점 · 근거 ·… | cpu | 1.899 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_dreams_render_summary | 기간 · 개선점 줄들로 다음 턴에 싣는 [SCV… | cpu | 0.671 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_dreams_svg_bars | 제목과 "라벨 탭 값" 줄들로 막대 차트 SVG… | cpu | 27.000 | 107.667 | 4.0 | 3.4 | 0 → 0 |  |
| scv_dreams_tip_text | 개선점 줄 하나를 사람이 읽는 한 문장으로 만든다 | cpu | 0.067 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_drift_line | 시각 · 턴 · 메아리 판정 · 위반… | cpu | 0.668 | 1.943 | 2.9 | 3.1 | 0 → 0 |  |
| scv_evidence_render | 근거 목록을 사람이 읽을 기록용 불릿 줄들로 만든다 | cpu | 0.430 | 0.782 | 1.8 | 3.2 | 0 → 0 |  |
| scv_finish_note | 끝 보고 문제 줄들을 설정 언어로 된 교정… | cpu | 1.607 | 7.651 | 4.8 | 3.3 | 0 → 0 |  |
| scv_finish_rule_line | 매 턴 맨 앞에 실을 확인 범위 안내… | cpu | 0.038 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_force_banner | 준비가 켜져 있으면 | cpu | 0.034 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_force_routing | 매 턴 맨 앞에 싣는 고정 지시 블록 | cpu | 0.050 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_gates_reason | 받은 막는 이유들 | cpu | 0.052 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_gates_record | 막은 검사들을 이어 새 전달 기록 한 줄을… | cpu | 0.059 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_graft_notice | Graft 상태와 지원 파일 수를 보고 안내 한… | cpu | 0.049 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_graft_render_ask | ask 후보 줄들을 사람이 읽을 줄들로 풀어 쓴다 | cpu | 0.199 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_graft_render_blast | blast 요약 레코드를 사람이 읽을 줄들로 풀어 쓴다 | cpu | 0.182 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_graph_build | links · touches · refs · 존재 목록… | cpu | 18.867 | - | - | 3.1 | 1 → - | 늘려 재지 못함 |
| scv_graph_impact | graph.json 에서 경로마다 함께 바뀐 파일 · 계획… | cpu | 43.857 | - | - | 3.0 | 3 → - | 늘려 재지 못함 |
| scv_graph_report | graph.json 텍스트를 GRAPH_REPORT.md 마크다운 | cpu | 15.944 | - | - | 3.1 | 1 → - | 늘려 재지 못함 |
| scv_hstate_brief_line | 진단이 안 바뀐 턴에 진단 전체 대신 싣는… | cpu | 0.037 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_hstate_render | \x1f 로 구분한 상태를 표식 JSON 한 줄로… | cpu | 0.189 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_lang_fix_note | 다른 언어 줄 수와 자리 | cpu | 0.053 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_lang_rule_line | 설정 언어로 쓴 언어 규칙 한 줄을 만든다 | cpu | 0.040 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_mp_effort_block | effort 를 한 번 물으라는 안내 줄을 만든다 | cpu | 0.047 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_first_turn_lines | 새 컨텍스트 첫 턴에 실을 가이드 안내 블록을… | cpu | 1.103 | 3.700 | 3.4 | 3.4 | 0 → 0 |  |
| scv_mp_gate_reason | 편집 거절 판정에 맞는 사유 한 줄을 만든다 | cpu | 0.051 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_gate_reason_sub | 하위 에이전트의 쓰기를 거절하는 사유 한 줄을 만든다 | cpu | 0.043 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_guide_lines | 결정 · 키 · 경로 · 경과 일수로… | cpu | 0.067 | - | - | 3.4 | 0 → - | 늘려 재지 못함 |
| scv_mp_guides_candidates | 가이드 폴더 후보 경로들을 한 줄씩 낸다 | cpu | 0.042 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_help_reason | help 를 부르기 전 도구를 거절할 때 쓸… | cpu | 0.038 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_candidates | 코어 루트로 원칙 파일 후보 경로 두 개를… | cpu | 0.042 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_reason | 문제 표를 넣어 막힐 때 모델에게 주는 원칙… | cpu | 0.036 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_speaker_label | 대화 기록의 모델 id 로 저널 화자 이름 | cpu | 0.140 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_stop_reason | 종료를 막는 이유 한 줄을 만든다 | cpu | 0.053 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_turn_block | 매 턴 훅이 싣는 "가이드대로 다시 쓰기 ·… | cpu | 0.059 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_turn_dir | 저널 폴더와 세션 이름으로 이번 턴 상태 폴더… | cpu | 0.040 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_warn_lines | 판정 줄들을 다음 턴에 실을 경고 문장으로 바꾼다 | cpu | 0.196 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mx_render_models | 모델별 답 수 줄들을 표의 "모델별 답 수"… | cpu | 1.407 | 5.080 | 3.6 | 3.3 | 0 → 0 |  |
| scv_mx_render_table | 네 요약 줄 | cpu | 2.360 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_mx_render_tsv | 지표 이름과 지표 줄들을 | cpu | 1.140 | 3.867 | 3.4 | 3.0 | 0 → 0 |  |
| scv_plan_history_add | PLAN.md 글의 `## 변경 이력` 절 끝에 사건… | cpu | 6.233 | 33.556 | 5.4 | 3.3 | 0 → 0 |  |
| scv_plan_redo_step | 끝난 단계 n 의 요건이 바뀌었을 때 맨… | cpu | 3.550 | 15.227 | 4.3 | 3.2 | 0 → 0 |  |
| scv_resume_header | 컨텍스트가 비워진 이유 한 줄 머리말을 만든다 | cpu | 0.047 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_show_real_excerpts | 애매한 턴 줄마다 보인 출력과 끝 글 마지막… | cpu | 14.591 | 14.875 | 1.0 | 3.3 | 1 → 1 |  |
| scv_show_real_judge_prompt | 물을 턴 줄들로 판정자에게 보낼 질문 글을 만든다 | cpu | 1.979 | - | - | 3.4 | 1 → - | 늘려 재지 못함 |
| scv_show_real_pct | 부분과 전체로 "N% | cpu | 0.038 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_show_real_per | 합과 세션 수로 세션당 값 "A.BC | cpu | 0.043 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_show_real_render | 셈 두 줄과 언어 · 기간 · 파일… | cpu | 61.600 | 243.000 | 3.9 | 3.4 | 0 → 0 |  |
| scv_show_real_rule | 실체 보여 주기 켬 여부와 통로로 매 턴… | cpu | 0.038 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_show_real_zip | 물을 턴 줄들과 판정자 답 줄들을 짝지어 A… | cpu | 0.367 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_step_line | 단계 보고 도구 이름과 구현 중인 계획 이름으로… | cpu | 0.048 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_tc_block_msg | 막을 때 모델에게 줄 말을 만든다 | cpu | 0.051 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_tc_choice_entry | 선택 답 한 개를 계획 변경 이력 항목으로… | cpu | 0.082 | 0.164 | 2.0 | 3.2 | 0 → 0 |  |
| scv_tc_exempt_entry | 예외 기록 한 줄 | cpu | 0.093 | 0.234 | 2.5 | 3.2 | 0 → 0 |  |
| scv_tc_progress_entry | 계획 안 일의 진행 한 줄 | cpu | 0.099 | 0.245 | 2.5 | 3.2 | 0 → 0 |  |
| pb_changed_names | 앞 코드와 뒤 코드의 함수 본문 글 | cpu | 1.810 | 2.350 | 1.3 | 3.2 | 1 → 1 |  |
| scv_tc_diff | 시작 사진과 끝 사진 | cpu | 4.617 | 13.773 | 3.0 | 3.1 | 1 → 1 |  |
| scv_tc_new_lines | 정렬된 두 묶음에서 뒤 묶음에만 있는 줄을 낸다 | cpu | 1.597 | 6.740 | 4.2 | 3.2 | 0 → 0 |  |
| scv_ver_lt | 첫 버전이 둘째 버전보다 낮으면 참 | cpu | 0.329 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| below_raw_root | 경로에서 원자료 폴더 뿌리까지를 떼어 낸다 | cpu | 0.042 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| key_of | 폴더 경로를 사진 파일 이름으로 바꾼다 | cpu | 0.307 | 6.140 | 20.0 | 2.9 | 0 → 0 | 배수 한도(8배) 넘음 |
| pb_scale_args | 예시의 인자 글에서 여러 줄 값은 줄을, 여러… | cpu | 3.740 | 17.471 | 4.7 | 3.2 | 0 → 0 |  |
| pb_times_secs | 셸의 times 출력 글 | cpu | 1.613 | 2.100 | 1.3 | 3.1 | 1 → 1 |  |
| pb_to_milli | 소수 글을 천분의 일 단위 정수로 바꾼다 | cpu | 0.051 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_as_group_of | 파일 경로에서 묶음 이름을 낸다 | cpu | 0.041 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_dreams_day | YYYYMMDD 를 YYYY-MM-DD 로 바꾼다 | cpu | 0.044 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_dreams_period_ord | 날짜 YYYYMMDD 를 기간 단위 | cpu | 0.060 | - | - | 3.4 | 0 → - | 늘려 재지 못함 |
| scv_dreams_period_range | 기간 순번과 단위로 "시작 끝" YYYYMMDD 를 낸다 | cpu | 2.047 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_dreams_tag | « » 로 적은 짧은 HTML 조각을 꺾쇠… | cpu | 0.040 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_evidence_build | 사건 줄들을 근거 목록으로 바꾼다 | cpu | 0.764 | 1.266 | 1.7 | 3.8 | 0 → 0 |  |
| scv_graph_normpath | 경로의 "./" 와 "a/../" 를 접고 겹친 슬래시를… | cpu | 0.183 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_hstate_mark | 상태를 "규약을 읽었다" | cpu | 0.185 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_hstate_reload | 상태 · 세션 번호 · 사건 | cpu | 0.204 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_guides_dir | 프로필 값이 절대 경로면 그대로, 상대 경로면 코어… | cpu | 0.040 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_lang | SCV_LANG 값을 원칙 구역 이름 | cpu | 0.469 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_restamp | 읽음 기록의 옛 지문을 새 지문으로 바꾼 줄을… | cpu | 0.475 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_turn_restamp | 이번 턴 기록의 옛 지문을 새 지문으로 바꾼… | cpu | 0.479 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mx_civil_to_minutes | "YYYY-MM-DD HH:MM" 을 1970-01-01 00:00 기준 분 수로… | cpu | 0.071 | 0.126 | 1.8 | 3.3 | 0 → 0 |  |
| scv_mx_fmt10 | 10배 한 정수를 소수 한 자리 "d.d" 로… | cpu | 0.042 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_mx_resolve_conv_path | 계획서에 적힌 대화 경로를 SCV_DIR 기준 후보 경로… | cpu | 0.043 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_obsolete_frontmatter | PLAN.md 글의 앞머리에서 세 칸 | cpu | 3.200 | 13.955 | 4.4 | 3.2 | 0 → 0 |  |
| scv_plan_fm_drop | PLAN.md 글의 앞머리에서 한 칸의 줄을 지운다 | cpu | 2.900 | 14.300 | 4.9 | 3.2 | 0 → 0 |  |
| scv_plan_fm_set | PLAN.md 글의 앞머리에서 한 칸을 바꾼다 | cpu | 3.030 | 11.143 | 3.7 | 3.2 | 0 → 0 |  |
| scv_plan_insert_step | Suggested path 의 after 번 단계 뒤에 새… | cpu | 10.333 | 48.375 | 4.7 | 3.5 | 0 → 0 |  |
| scv_plan_link_return | 새 계획 B 에 끝나면 돌아갈 계획 A… | cpu | 6.100 | 22.429 | 3.7 | 3.3 | 0 → 0 |  |
| scv_plan_mark_pause | 계획 A 를 보류로 바꾼다 | cpu | 12.917 | 47.429 | 3.7 | 3.2 | 0 → 0 |  |
| scv_plan_mark_resume | 보류였던 계획 A 를 진행 중으로 되돌린다 | cpu | 17.125 | 80.750 | 4.7 | 3.3 | 0 → 0 |  |
| scv_plan_shift_progress | 단계를 after 번 뒤에 끼운 뒤, 변경 이력의… | cpu | 2.440 | 11.720 | 4.8 | 3.6 | 0 → 0 |  |
| scv_reg_rewrite_line | 시험 줄이면 그 명령을 기록된 종료 코드 ' | cpu | 26.000 | 151.500 | 5.8 | 3.3 | 0 → 0 |  |
| scv_show_real_lines | \x1e 로 이은 글을 줄바꿈으로 나눈 글로 바꾼다 | cpu | 0.170 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_show_real_local_date | 기록 시각 | cpu | 0.112 | - | - | 3.6 | 0 → - | 늘려 재지 못함 |
| scv_show_real_merge | 분류된 턴 줄들에서 답이 yes 인 턴의 보여… | cpu | 1.800 | - | - | 3.2 | 1 → - | 늘려 재지 못함 |
| scv_show_real_offset | +HHMM · -HHMM 모양의 오프셋을 분으로 바꾼다 | cpu | 0.047 | - | - | 3.4 | 0 → - | 늘려 재지 못함 |
| scv_show_real_range | 기간 글 YYYY-MM-DD..YYYY-MM-DD 를 "시작 끝" YYYYMMDD 두… | cpu | 0.913 | - | - | 3.5 | 0 → - | 늘려 재지 못함 |
| scv_stop_notice | 막는 이유들을 다음 턴 안내 줄들로 바꾼다 | cpu | 1.155 | 3.973 | 3.4 | 3.2 | 0 → 0 |  |
| scv_tc_abs_paths | 저장소 맨 위 경로와 그 안의 상대 경로… | cpu | 1.087 | 4.383 | 4.0 | 3.2 | 0 → 0 |  |
| scv_tc_plan_lines | 계획 글 여러 개의 이력 · 단계 줄을… | cpu | 3.917 | 11.920 | 3.0 | 3.4 | 1 → 1 |  |
| scv_tc_record_globs | 기록 폴더의 실제 경로들 중 이 저장소 뿌리… | cpu | 1.813 | 7.488 | 4.1 | 3.3 | 0 → 0 |  |
| scv_tc_req_tag | 기록 줄에 붙일 요청 꼬리를 만든다 | cpu | 0.141 | 0.546 | 3.9 | 3.2 | 0 → 0 |  |
| settings_merge_defaults | 사용자 JSON 에 기본값 JSON 을 깔아 병합한다 | unmeasured | 15.182 | - | - | 2.9 | 2 → - | 재지 못함 |
| pb_gpu_summary | GPU 표본 줄들 | cpu | 1.793 | 6.300 | 3.5 | 3.4 | 0 → 0 |  |
| pb_median | 빈칸으로 나눈 수들의 가운데값을 소수 셋째 자리로 낸다 | cpu | 37.125 | 219.000 | 5.9 | 3.2 | 0 → 0 |  |
| pb_ratio | 앞 값과 뒤 값에서 뒤 ÷ 앞을 소수… | cpu | 0.888 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| pb_reps_next | 잰 CPU 초와 되풀이 수를 보고 다음 되풀이… | cpu | 0.059 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| pb_scale_ratio | 1배 값과 4배 값에서 배수를 소수 한 자리로… | cpu | 0.867 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_as_count_terms | 한 줄에 낱말 목록 중 몇 개가 들어… | cpu | 102.250 | 375.000 | 3.7 | 3.6 | 51 → 201 | 입력만큼 부름 |
| scv_dreams_distribution | 계획마다 보관까지의 사람 질의 수와 근거 턴 id… | cpu | 35.444 | 143.667 | 4.1 | 3.4 | 0 → 0 |  |
| scv_dreams_periods | 사람 턴 줄들과 보관 줄들을 기간별 질의 ·… | cpu | 35.000 | 137.667 | 3.9 | 3.3 | 0 → 0 |  |
| scv_dreams_totals | 기간 줄들에서 마지막 보관이 있는 기간까지의 질의 합과… | cpu | 1.620 | 5.800 | 3.6 | 3.3 | 0 → 0 |  |
| scv_graft_ext_histogram | 표준입력 파일 경로들에서 "확장자 개수" 표를 만든다 | cpu | 1.653 | 1.853 | 1.1 | 3.0 | 1 → 1 |  |
| scv_graft_supported_count | 확장자 히스토그램에서 지원 언어 파일 수의 합을 낸다 | cpu | 2.100 | 6.520 | 3.1 | 3.2 | 0 → 0 |  |
| scv_graph_cochange | 계획별 파일 목록 | cpu | 15.150 | 16.737 | 1.1 | 3.2 | 1 → 1 |  |
| scv_lint_hangul_ratio | 글에서 한글 글자가 한글 · 영문 글자 중… | cpu | 19.867 | 409.000 | 20.6 | 3.1 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_lint_sentences | 한 덩어리 글의 문장 수를 센다 | cpu | 2.640 | 20.625 | 7.8 | 3.4 | 0 → 0 |  |
| scv_mp_age_days | 가져온 날짜부터 오늘까지 지난 일수를 센다 | cpu | 0.931 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mx_aggregate | 지표 줄들을 값 있는 수 · 전체 수… | cpu | 4.433 | 42.750 | 9.6 | 3.3 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_mx_count_answers | 저널에서 답 기록 머리줄을 모델 id 별로 세어… | cpu | 3.080 | 11.786 | 3.8 | 3.5 | 0 → 0 |  |
| scv_mx_count_turns | 대화 파일 텍스트의 "## Turn N" 헤딩 수를… | cpu | 2.720 | 10.000 | 3.7 | 3.4 | 0 → 0 |  |
| scv_mx_metric_lead_time | 색인의 slug 마다 가장 이른 adopted 에서 archived… | cpu | 2.720 | 9.357 | 3.4 | 3.2 | 0 → 0 |  |
| scv_show_real_count | 분류된 턴 줄들을 두 기간 | cpu | 31.800 | 128.667 | 4.0 | 3.7 | 0 → 0 |  |
| scv_show_real_judge_count | 판정자 답 줄들에서 기간마다 판정한 턴 · 그중… | cpu | 1.987 | 7.120 | 3.6 | 3.4 | 0 → 0 |  |
| scv_tc_overlap_count | 항목 낱말들 중 메모 낱말에 있는 것의 수와… | cpu | 0.062 | 0.104 | 1.7 | 3.1 | 0 → 0 |  |
| scv_tc_req_count | 계획 글에서 새로 생긴 줄들 중 이번 턴… | cpu | 1.047 | 3.550 | 3.4 | 3.2 | 0 → 0 |  |
| scv_tc_struct_count | 계획 글에서 새로 생긴 줄들 중 구조 줄 | cpu | 3.000 | 11.200 | 3.7 | 3.6 | 0 → 0 |  |
| pb_calls | 함수 본문 글 | cpu | 2.160 | 5.617 | 2.6 | 3.3 | 1 → 1 |  |
| pb_parse_ioreg | 맥의 그래픽 장치 정보 글에서 "사용률 %<탭>쓰는 메모리… | cpu | 1.723 | 2.190 | 1.3 | 3.2 | 1 → 1 |  |
| pb_parse_nvidia | nvidia-smi 의 "사용률, 메모리 MiB" 줄들에서 "사용률 %<탭>쓰는… | cpu | 0.214 | 0.241 | 1.1 | 3.3 | 0 → 0 |  |
| pb_parse_time | 시간 재는 명령의 출력 글에서 "벽시계 초<탭>CPU 초<탭>메모리… | cpu | 2.020 | 2.850 | 1.4 | 3.2 | 1 → 1 |  |
| pb_roles | 사전 글에서 "함수<탭>하는 일 | cpu | 3.800 | 14.350 | 3.8 | 3.4 | 0 → 0 |  |
| pb_targets | 사전 글에서 잴 목록 "함수<탭>파일<탭>언어<탭>1배 인자<탭>4배 인자<탭>늘림 | cpu | 47.000 | 180.500 | 3.8 | 3.3 | 0 → 0 |  |
| pc_extract_entries | 소스 글에서 표식 | cpu | 2.076 | 3.013 | 1.5 | 3.2 | 1 → 1 |  |
| pc_kinds_from_contract | 계약 문서의 종류 표에서 종류 · 파일 이름… | cpu | 1.683 | 1.953 | 1.2 | 3.1 | 1 → 1 |  |
| pc_lang_of | 파일 경로의 확장자로 언어 표시를 낸다 | cpu | 0.038 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| pc_split_example | 예시 한 줄을 인자 · 기대 출력 ·… | cpu | 0.251 | 0.526 | 2.1 | 3.3 | 0 → 0 |  |
| plan_title | 계획 글의 제목 | cpu | 0.781 | 0.880 | 1.1 | 3.1 | 0 → 0 |  |
| record_index_fields | 색인 레코드 한 줄을 표시 · 키 ·… | cpu | 0.193 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_as_parse_terms | 물음 한 줄을 낱말 목록 | cpu | 3.020 | 3.730 | 1.2 | 3.0 | 2 → 2 |  |
| scv_choice_q_after | 줄에서 사용자에게 묻는 마지막 문장 끝 물음표 뒤의… | cpu | 1.017 | 1.767 | 1.7 | 3.2 | 0 → 0 |  |
| scv_dreams_archive_dates | "계획 이름 탭 archived_at" 줄들에서 보관 날짜 줄… | cpu | 54.667 | 211.000 | 3.9 | 3.2 | 1 → 1 |  |
| scv_dreams_entries | 세션 기록 JSONL | cpu | 19.353 | 21.333 | 1.1 | 3.4 | 1 → 1 |  |
| scv_dreams_human_turns | 기록 항목 줄들에서 모델이 일한 사람 턴만 "세션… | cpu | 35.667 | 145.333 | 4.1 | 3.2 | 0 → 0 |  |
| scv_dreams_judge_parse | 판정자 답 글에서 rule · advice 가 있는… | cpu | 16.500 | 15.421 | 0.9 | 3.3 | 1 → 1 |  |
| scv_dreams_register_features | 기록 항목 줄들에서 사람 턴마다 마지막 등록 하나 | cpu | 18.059 | 71.800 | 4.0 | 3.3 | 0 → 0 |  |
| scv_evidence_test_first | 근거 목록에서 시험 파일을 바꾼 뒤 실패하는 시험… | cpu | 8.714 | 34.300 | 3.9 | 3.5 | 0 → 0 |  |
| scv_finish_scan | 끝 답에서 확인 범위 줄 | cpu | 6.120 | 24.077 | 3.9 | 3.5 | 0 → 0 |  |
| scv_graft_ask_summary | ask JSON 에서 점수 높은 후보 n 개를… | cpu | 16.105 | - | - | 3.0 | 1 → - | 늘려 재지 못함 |
| scv_graft_blast_summary | blast JSON 을 "파일수 US 심볼수 US 상위"… | cpu | 15.000 | - | - | 2.9 | 1 → - | 늘려 재지 못함 |
| scv_graph_decision_refs | DECISIONS.md 에서 결정 제목과 그 결정이 참조한 계획… | cpu | 2.580 | 9.567 | 3.7 | 3.6 | 0 → 0 |  |
| scv_graph_doc_links | 마크다운 본문에서 상대 .md 링크만 뽑아 "문서\x1f대상 | cpu | 34.778 | 136.333 | 3.9 | 3.5 | 0 → 0 |  |
| scv_graph_plan_records | awk 가 뽑은 T/E/S/B 레코드에서 경로 모양 토큰만… | cpu | 6.860 | 27.364 | 4.0 | 3.5 | 0 → 0 |  |
| scv_graph_plan_touches | PLAN.md 본문에서 건드리는 파일 | cpu | 7.053 | 20.375 | 2.9 | 3.5 | 1 → 1 |  |
| scv_graph_plans_batch | 여러 계획의 awk 레코드 | cpu | 21.000 | 84.000 | 4.0 | 3.3 | 0 → 0 |  |
| scv_hstate_nonce | 상태에서 규약 지문 | cpu | 0.179 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_hstate_parse | 표식 JSON 한 줄 | cpu | 0.102 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_lang_first_other | 글에서 설정 언어가 아닌 첫 줄을 꺼내 앞… | cpu | 35.333 | 143.667 | 4.1 | 3.1 | 0 → 0 |  |
| scv_lang_new_text | 이번 턴 어시스턴트 글 목록에서 지난 검사 id… | cpu | 2.390 | 9.933 | 4.2 | 3.1 | 0 → 0 |  |
| scv_mp_common | 색인에서 모든 모델에 붙는 공통 원문의 파일과 날짜를… | cpu | 0.181 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_common_key | 색인에서 공통 | cpu | 0.174 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_guide_fold | 모델이 실행한 mark 명령 사건들로 읽은 모델 집합을… | cpu | 2.147 | 10.067 | 4.7 | 3.6 | 0 → 0 |  |
| scv_mp_harm_line | 구역에서 통로 | cpu | 0.233 | 0.347 | 1.5 | 3.5 | 0 → 0 |  |
| scv_mp_lookup | 색인에서 모델 id 가 정확히 맞는 첫 행의… | cpu | 1.270 | 1.503 | 1.2 | 3.5 | 0 → 0 |  |
| scv_mp_meta | 색인의 "@이름" 행 | cpu | 0.184 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_pick | 원칙 파일 본문에서 이름이 맞는 구역의 전문을 꺼낸다 | cpu | 0.346 | 0.615 | 1.8 | 3.5 | 0 → 0 |  |
| scv_mp_principle_section | 원칙 파일 본문에서 언어에 맞는 구역을 꺼낸다 | cpu | 1.613 | 2.091 | 1.3 | 3.4 | 0 → 0 |  |
| scv_mp_read_parse | 읽음 기록 한 줄을 "지문 모델id" 두 칸으로… | cpu | 0.048 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_reg_seq | 등록 첫 줄에서 세 번째 칸 | cpu | 0.043 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_register_rewrite | 제출 텍스트에서 rewrite 행의 값 | cpu | 0.231 | 0.344 | 1.5 | 3.5 | 0 → 0 |  |
| scv_mp_register_value | 제출 텍스트 | cpu | 0.218 | 0.275 | 1.3 | 3.4 | 0 → 0 |  |
| scv_mp_turn_parse | 이번 턴 기록 한 줄을 "지문 모델 결정… | cpu | 0.060 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mx_parse_decisions | DECISIONS.md 에서 | cpu | 26.833 | 109.000 | 4.1 | 3.6 | 0 → 0 |  |
| scv_mx_parse_index | INDEX.yaml 텍스트에서 slug · status · obsoleted_by 를… | cpu | 153.000 | 578.000 | 3.8 | 3.2 | 0 → 0 |  |
| scv_mx_parse_plan | PLAN.md 프런트매터에서 대화 경로 · supersedes 개수 ·… | cpu | 9.567 | 18.250 | 1.9 | 3.3 | 0 → 0 |  |
| scv_pd_declared | 본문에서 순수 · 부수효과 선언 | cpu | 15.650 | 61.800 | 3.9 | 3.3 | 0 → 0 |  |
| scv_pd_functions | 본문에서 이름 있는 함수 선언의 이름들을 나온 순서대로… | cpu | 25.583 | 103.000 | 4.0 | 3.0 | 0 → 0 |  |
| scv_pd_line_function | 본문 한 줄이 이름 있는 함수 선언이면 그… | cpu | 0.085 | 0.121 | 1.4 | 3.3 | 0 → 0 |  |
| scv_plan_fm_get | PLAN.md 글의 앞머리에서 한 칸의 값을 꺼낸다 | cpu | 0.280 | 0.423 | 1.5 | 3.2 | 0 → 0 |  |
| scv_plan_goal_items | `## Goals / Non-Goals` 절에서 Goals 또는 Non-Goals… | cpu | 5.167 | 20.867 | 4.0 | 3.4 | 0 → 0 |  |
| scv_plan_steps | PLAN.md 글의 Suggested path | cpu | 4.373 | 20.733 | 4.7 | 3.5 | 0 → 0 |  |
| scv_reg_line_key | 실행 줄이 '시험 파일 하나를 bash 로 부르는… | cpu | 0.149 | 0.400 | 2.7 | 3.3 | 0 → 0 |  |
| scv_reg_split_chain | 한 줄을 &&, //, ; 로 이은 조각들로… | cpu | 13.318 | 108.667 | 8.2 | 3.1 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_show_real_entries | 세션 기록 JSONL | cpu | 27.167 | 30.091 | 1.1 | 3.5 | 1 → 1 |  |
| scv_show_real_judge_parse | 판정자 답 글에서 길이가 n 인 yes ·… | cpu | 14.400 | 15.632 | 1.1 | 3.5 | 1 → 1 |  |
| scv_show_real_split | 기록 항목 줄들을 사람 턴 줄들 | cpu | 19.800 | 77.000 | 3.9 | 3.4 | 0 → 0 |  |
| scv_turn_group | 원본 줄들에서 마지막 사람 글 뒤의 이번 턴… | cpu | 23.500 | 25.250 | 1.1 | 3.4 | 1 → 1 |  |
| scv_turn_slice | 턴 스트림에서 마지막 사람 프롬프트 뒤의 어시스턴트 텍스트만… | cpu | 6.368 | 24.250 | 3.8 | 3.2 | 0 → 0 |  |
| scv_writing_paragraphs | 마크다운에서 코드 블록 · 제목 · 표 ·… | cpu | 2.003 | 2.720 | 1.4 | 3.1 | 1 → 1 |  |
| scv_writing_pass_criteria | 시험서에서 통과 기준 줄 | cpu | 1.873 | 2.233 | 1.2 | 3.0 | 1 → 1 |  |
| scv_writing_table_cells | 마크다운에서 코드 블록 밖 표 칸을 꺼낸다 | cpu | 2.047 | 2.770 | 1.4 | 3.0 | 1 → 1 |  |
| settings_index_json | JSON 객체의 모든 최상위 키를 "키 탭 값"… | cpu | 14.045 | - | - | 2.9 | 1 → - | 늘려 재지 못함 |
| settings_lookup_json | JSON 객체에서 키 하나의 값을 문자열로 꺼낸다 | cpu | 13.750 | - | - | 2.9 | 1 → - | 늘려 재지 못함 |
| settings_lookup_many_json | JSON 객체에서 공백으로 나눈 키 여럿의 값을 "키… | cpu | 15.364 | 27.417 | 1.8 | 2.9 | 1 → 1 |  |
| decisions_slug | 제목에서 부를 이름을 만든다 | cpu | 0.777 | 0.870 | 1.1 | 3.0 | 0 → 0 |  |
| scv_digest_fold | 표준입력 줄들을 정렬한 뒤 sha256 지문 하나로 접는다 | cpu | 4.600 | 4.653 | 1.0 | 2.8 | 3 → 3 |  |
| scv_graph_community | 노드 종류 · id · epic 으로 군집… | cpu | 0.051 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_rc_demand_keys | 표준입력 "파일 줄번호 본문" 줄에서 앞 8단어 키를… | cpu | 2.913 | 3.320 | 1.1 | 3.0 | 2 → 2 |  |
| scv_show_real_hash | 글의 SHA-256 16진 지문을 낸다 | cpu | 2.120 | - | - | 3.2 | 1 → - | 늘려 재지 못함 |
| scv_show_real_keys | 발췌 줄마다 | cpu | 2.787 | - | - | 3.3 | 1 → - | 늘려 재지 못함 |
| _scv_choice_blank | 줄이 빈 줄 | cpu | 0.038 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| _scv_choice_cue_real | 글 속 요청 말이 "언제든지 · 얼마든지" 같은… | cpu | 0.090 | 0.242 | 2.7 | 3.1 | 0 → 0 |  |
| _scv_choice_has_text | 글에 공백 · 굵게 · 닫는 괄호 말고… | cpu | 0.033 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_answer_lint | 답 본문의 골격 | cpu | 41.250 | 175.000 | 4.2 | 3.5 | 0 → 0 |  |
| scv_as_kind_of | 파일 경로 모양만 보고 기록의 종류 | cpu | 0.057 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_asks_in_text | 답이 사용자에게 글로 고르게 하거나 묻는 꼴로 끝나면… | cpu | 4.117 | 13.864 | 3.4 | 3.6 | 0 → 0 |  |
| scv_choice_q_asks | 물음표 뒤 글이 사용자에게 답을 요청하거나 추천을 달고… | cpu | 0.750 | 1.117 | 1.5 | 3.2 | 0 → 0 |  |
| scv_dreams_pasted | 사람 메시지가 붙여 넣은 글로 보이면 종료 0,… | cpu | 0.046 | 0.077 | 1.7 | 3.1 | 0 → 0 |  |
| scv_echo_check | 이번 턴 기록의 지문과 표식 지문을 견줘 skip… | cpu | 0.043 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_finish_check | 찾은 칸 · 근거 목록 · 실패를 못… | cpu | 0.544 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_is_rewrite_quote | 한 줄이 다시 쓴 요청 인용 줄 | cpu | 0.910 | 28.091 | 30.9 | 3.1 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_lint_bullet_polite | 불릿 한 줄이 존댓말 서술형 | cpu | 0.054 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_lint_lang_turn | 마지막 답과 이번 턴 글 전체에서, 한국어 설정인데… | cpu | 167.500 | 2560.000 | 15.3 | 3.3 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_lint_lang_verdict | 설정 언어가 한국어인데 답 글에 한글이 거의 없으면… | cpu | 0.041 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_mp_answer_has_problem_table | 답에 "문제 표" | cpu | 0.239 | 0.356 | 1.5 | 3.4 | 0 → 0 |  |
| scv_mp_answer_has_quote | 답 본문의 코드 블록 밖에 ">" 인용 줄이… | cpu | 0.219 | 0.259 | 1.2 | 3.3 | 0 → 0 |  |
| scv_mp_answer_rewrite_on_top | 답의 첫 내용 줄 | cpu | 0.757 | 1.033 | 1.4 | 3.5 | 0 → 0 |  |
| scv_mp_answer_shows_rewrite | 답의 코드 블록 밖 인용 줄에 다시 쓴… | cpu | 4.817 | 81.750 | 17.0 | 3.4 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_mp_prompt_kind | 프롬프트가 알림 태그 블록뿐이면 auto, 사람이 쓴 글이… | cpu | 0.106 | - | - | 3.5 | 0 → - | 늘려 재지 못함 |
| scv_rc_is_normative | 본문에 규범 동사 | cpu | 0.086 | 0.132 | 1.5 | 3.3 | 0 → 0 |  |
| scv_rc_is_precedence | 본문에 우선순위 어휘 | cpu | 0.101 | 0.175 | 1.7 | 3.4 | 0 → 0 |  |
| scv_rc_is_reference | 본문이 Top-level rules 를 가리키는 참조형이면 참 | cpu | 0.052 | 0.108 | 2.1 | 3.0 | 0 → 0 |  |
| scv_show_real_classify | 사람 턴 줄마다 바뀜 · 보여 줌 ·… | cpu | 2.770 | 3.250 | 1.2 | 3.4 | 0 → 0 |  |
| scv_show_real_is_confirm | 질문이 계속할지와 고칠 점을 함께 묻는 확인인지 1… | cpu | 0.120 | 0.293 | 2.4 | 3.3 | 0 → 0 |  |
| scv_show_real_is_correction | 사람 메시지가 고쳐 달라는 말인지 단서 낱말 | cpu | 0.149 | 0.306 | 2.1 | 3.4 | 0 → 0 |  |
| scv_show_real_is_nochange | 모델의 글에 결과물 변화 없음 표시가 있는지 1… | cpu | 0.074 | 0.146 | 2.0 | 3.4 | 0 → 0 |  |
| scv_show_real_quotes | 실행 출력이 묻는 글 안에 그대로 인용됐는지 1… | cpu | 3.600 | 4.683 | 1.3 | 3.3 | 2 → 2 |  |
| scv_choice_gate | 묻는지 · 도구 이름 · 이미 전달 여부로… | cpu | 0.041 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_choice_off_when | "이름=값" 조건과 지금 그 이름의 환경 값이 같으면… | cpu | 0.050 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_dreams_day_trigger | 지난 드림 날짜와 오늘 날짜가 달라 드림을 띄울… | cpu | 0.045 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_dreams_start_trigger | 훅 입력의 source 값이 드림을 띄울 때 | cpu | 0.033 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_drift_decide | 메아리 판정 · 린트 위반 · 스위치로 규약을… | cpu | 0.056 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_finish_needed | 근거 목록으로 이번 턴 끝 보고에 무엇이 필요한지… | cpu | 0.183 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_gates_delivered | 이 검사가 이 세션 · 이 턴에 이미… | cpu | 0.064 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_gates_drop | 첫 멈춤에서 이 세션의 지난 기록이나 깨진 기록을… | cpu | 0.051 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_lang_stop_decide | 최종 답의 다른 언어 줄 수와 이번 턴… | cpu | 0.042 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_lang_user_other | 이번 턴 사용자 글이 다른 언어를 요청하거나 다른… | cpu | 0.575 | 0.833 | 1.4 | 3.0 | 0 → 0 |  |
| scv_mp_decision | 색인 행 유무 · 읽음 기록 · 지금… | cpu | 0.049 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_guide_decide | 읽은 모델 집합에 이 모델이 있으면 loaded, 없으면… | cpu | 0.049 | 0.075 | 1.5 | 3.2 | 0 → 0 |  |
| scv_mp_guide_from_events | 사건 줄들을 접어 이 모델 원문을 읽었는지 | cpu | 2.431 | 9.929 | 4.1 | 3.4 | 0 → 0 |  |
| scv_mp_help_needed | 이번 사람 턴에 help 를 아직 부르지 않아… | cpu | 0.044 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_gate | 문제 표 · 스위치 · 이미 전달 여부로… | cpu | 0.041 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_show | 원칙 전문을 이번 등록에 다시 실을지 | cpu | 0.037 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_register_problems | 제출 텍스트에 다시 쓴 요청과 범위가 있는지 보고… | cpu | 1.287 | 3.840 | 3.0 | 3.5 | 0 → 0 |  |
| scv_mp_rewrite_recorded | 대화 블록에 "다시 쓴 요청" 단락이 있는지 1/0… | cpu | 0.218 | 0.295 | 1.4 | 3.4 | 0 → 0 |  |
| scv_mp_scope_forbid | 범위 칸이 변경을 막는 첫머리면 그 문구를, 아니면… | cpu | 15.368 | 164.500 | 10.7 | 3.5 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_mp_stop_gate | 등록 · 보임 · 이미 전달 · 맨… | cpu | 0.046 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_turn_verdict | 결정 · 읽음 · 기록 · 인용 여부로… | cpu | 0.044 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_write_gate | 이번 턴 등록 상태로 파일 쓰기를 허용할지 | cpu | 0.048 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_pd_write_verdict | 편집 전에는 없던, 편집으로 새로 선언이 빠진 함수… | cpu | 1.077 | 3.570 | 3.3 | 3.0 | 0 → 0 |  |
| scv_reg_block_memo_ok | 블록이 다른 폴더로 옮겨 가면 | cpu | 0.073 | 0.177 | 2.4 | 3.2 | 0 → 0 |  |
| scv_tc_judge | 턴 끝 판정 | cpu | 0.054 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_template_decide | 도장 · 꾸러미의 지문과 버전을 보고 템플릿을 어떻게… | cpu | 0.354 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| pb_accept_covers | 사용자가 받아들인 이유들과 지금의 이유들을 견줘, 지금 것이… | cpu | 0.917 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| pb_compare | 한 함수의 앞뒤 잰 줄 | cpu | 2.427 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| pb_pick_measure | 잰 값 | cpu | 1.367 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| pc_validate_entries | 항목마다 빠진 칸 | cpu | 0.505 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_delegate_switch | 위임 스위치 값을 해석한다 | cpu | 0.040 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_dreams_tip_rule | 개선점 줄의 종류로 판정자에게 권할 가이드 규칙 이름 | cpu | 0.035 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_dreams_tips | 등록 · 사람 턴 · 분포 줄들에서 개선점… | cpu | 5.920 | 21.000 | 3.5 | 3.3 | 0 → 0 |  |
| scv_dreams_unit | 사람 턴 수로 기간 단위를 정한다 | cpu | 0.039 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_graft_status | graft 실행 파일 · 그래프 유무와 스위치로 absent… | cpu | 0.044 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_graph_is_path | 토큰이 저장소 상대 파일 경로처럼 보이는지 판정한다 | cpu | 0.064 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_graph_status_of | 그래프 존재 여부와 파일 시각으로 missing / stale… | cpu | 0.040 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_hstate_diag | 진단 본문의 해시를 직전과 견줘 "full" | cpu | 3.490 | 3.500 | 1.0 | 3.1 | 2 → 2 |  |
| scv_hstate_protocol_line | 상태와 스위치로 "PROTOCOL: load" | cpu | 0.178 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_mp_effort_verdict | effort 를 물을지 정한다 | cpu | 1.561 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_effort_word | effort 값 낱말이 맞는지 가려, 맞으면 소문자로 낸다 | cpu | 0.494 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_has_guides | 색인에 가이드 행 | cpu | 0.257 | 0.450 | 1.8 | 3.4 | 0 → 0 |  |
| scv_mp_read_name | 가이드 원문 이름과 그 발췌본이 있는지로, help 가… | cpu | 0.044 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_safe_name | 색인 폴더 안의 평범한 파일 이름이면 그대로, 경로… | cpu | 0.099 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_session_key | 세션 id 가 폴더 이름으로 안전하면 그대로, 아니면… | cpu | 0.076 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_switch | 스위치 값을 on/off 로 정한다 | cpu | 0.494 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_turn_dir_ok | 넘겨받은 폴더가 저널 폴더나 그 아래 세션 폴더면… | cpu | 0.502 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_was_read | 이 컨텍스트에서 그 모델 원문을 이미 읽었는지 1/0… | cpu | 0.056 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mx_metric_followup | 색인의 slug 마다 후속 계획이 있으면 1, 없으면… | cpu | 2.360 | 7.765 | 3.3 | 3.1 | 0 → 0 |  |
| scv_plan_conflict_after | 뒤쪽 충돌 검사 | cpu | 117.000 | 22051.000 | 188.5 | 4.0 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_plan_conflict_before | 앞쪽 충돌 검사 | cpu | 616.000 | - | - | 4.7 | 0 → - | 4배 입력에서 너무 오래 걸려 끊음 · 배수 한도(8배) 넘음 |
| scv_plan_fm_has | PLAN.md 글의 앞머리에 그 칸이 있으면 "1" 을… | cpu | 0.258 | 0.384 | 1.5 | 3.1 | 0 → 0 |  |
| scv_privacy_email_ok | 공개해도 되는 메일 주소 | cpu | 0.034 | - | - | 2.8 | 0 → - | 늘려 재지 못함 |
| scv_reg_is_core_loop | '코어 시험 전부' 반복 줄 | cpu | 0.167 | 0.441 | 2.6 | 3.4 | 0 → 0 |  |
| scv_show_real_channel | 쓸 수 있는 선택 창과 실행 상태로 질문… | cpu | 0.043 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_show_real_valid_day | 연 · 월 · 일이 있는 날인지 | cpu | 0.048 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_stop_mode | 설정 값으로 종료 검사가 어긋난 답을 어떻게 다룰지 | cpu | 0.036 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_switch | 설정 값을 on/off 로 정한다 | cpu | 0.040 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_tc_exempt_ok | 계획 없이 해도 되는 정한 예외 종류인지 가린다 | cpu | 0.034 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_tc_nongoal_hits | 덧붙이거나 진행으로 적으려는 글에 계획의 '하지 않음' | cpu | 37.750 | 149.333 | 4.0 | 3.4 | 0 → 0 |  |
| scv_tc_receipt | 도구가 돌린 명령 글이 계획 기록 명령 | cpu | 0.184 | 0.813 | 4.4 | 3.6 | 0 → 0 |  |
| scv_tc_step_on | 호스트 설정 글에 대시보드 | cpu | 0.130 | 0.392 | 3.0 | 3.3 | 0 → 0 |  |
| scv_tc_tool_kind | 도구 입력에 어떤 칸이 있는지로 이 도구가 파일을… | cpu | 0.038 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_writing_limits | README 파일 이름으로 칸 · 문단 길이 한도 | cpu | 0.034 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_writing_pick_locale | 쓸 수 있는 UTF-8 지역 설정 이름 하나를… | cpu | 0.061 | 0.121 | 2.0 | 3.1 | 0 → 0 |  |
| settings_is_secret | 설정 키가 비밀 키 목록 | cpu | 0.042 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| attachment_scope_filter | 표준입력 줄들에서 슬러그가 든 줄만 남긴다 | cpu | 1.035 | 3.480 | 3.4 | 3.0 | 0 → 0 |  |
| pb_accept_pick | '한도를 넘은 것' 줄들 | cpu | 1.433 | 4.973 | 3.5 | 3.4 | 0 → 0 |  |
| pb_baseline_next | '입력이 커지면 위험한 함수' 기준 목록 | cpu | 2.080 | 8.526 | 4.1 | 3.1 | 0 → 0 |  |
| pb_callers | 엮은 함수 줄들 | cpu | 1.277 | 5.240 | 4.1 | 3.1 | 0 → 0 |  |
| pb_composed | "함수<탭>부르는 함수들" 줄들에서 다른 사전 함수를 N개 | cpu | 1.247 | 4.307 | 3.5 | 3.1 | 0 → 0 |  |
| pc_allowed_filter | 짝 목록에서 예외 목록에 이유와 함께 적힌 짝을… | cpu | 15.867 | 61.000 | 3.8 | 3.1 | 0 → 0 |  |
| pc_duplicate_pairs | '지문<탭>함수' 줄들에서 지문이 같은 함수 짝을 들어온 순서대로… | cpu | 22.538 | 364.000 | 16.2 | 3.1 | 0 → 0 | 배수 한도(8배) 넘음 |
| pc_mutual_pairs | 방향 있는 '가<탭>나' 줄들에서 양쪽 방향이 다 있는… | cpu | 17.222 | 275.000 | 16.0 | 3.1 | 0 → 0 | 배수 한도(8배) 넘음 |
| pc_oversize_files | 사전 파일 글들에서 줄 수가 한도를 넘는 파일… | cpu | 1.900 | 2.287 | 1.2 | 3.1 | 1 → 1 |  |
| pc_text_duplicates | 항목들의 예시를 글로 비교해, 같은 입력에 같은 출력인… | cpu | 79.250 | 324.000 | 4.1 | 3.3 | 1 → 1 |  |
| record_index_filter | 색인 텍스트에서 종류가 맞는 레코드만, 키마다 최신 하나씩… | cpu | 3.693 | 15.000 | 4.1 | 3.1 | 0 → 0 |  |
| record_index_lookup | 색인 텍스트에서 키가 같은 레코드를 낸다 | cpu | 1.287 | 4.453 | 3.5 | 3.2 | 0 → 0 |  |
| scv_as_drop_weak | 점수 매긴 줄들에서 두 낱말 이상 맞은 줄이… | cpu | 3.600 | 4.100 | 1.1 | 3.1 | 2 → 2 |  |
| scv_as_group_best | 점수 매긴 줄들에서 묶음마다 가장 높은 점수 줄… | cpu | 5.820 | 6.395 | 1.1 | 3.1 | 4 → 4 |  |
| scv_as_score_lines | 훑은 "파일:줄번호:내용" 줄들에 낱말 맞은 수 점수를 매겨… | cpu | 3.653 | 4.220 | 1.2 | 3.0 | 2 → 2 |  |
| scv_deck_source_dir | 코어 루트와 설정 값으로 덱 엔진 폴더 경로를… | cpu | 0.044 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_dreams_evidence | 개선점 줄들이 가리킨 턴 id 의 사람 메시지를… | cpu | 30.000 | 30.100 | 1.0 | 3.4 | 2 → 2 |  |
| scv_force_refresh_note | 표준입력 점검 stderr 에서 템플릿 자동 갱신에 관한… | cpu | 1.747 | 7.816 | 4.5 | 3.2 | 0 → 0 |  |
| scv_graph_god_nodes | 그래프 JSON 에서 연결 | cpu | 14.182 | - | - | 3.1 | 1 → - | 늘려 재지 못함 |
| scv_mp_effort_from_log | 세션 기록에서 뽑은 줄들 | cpu | 0.601 | 0.707 | 1.2 | 3.5 | 0 → 0 |  |
| scv_mp_effort_row | 권장 effort 표에서 이 모델의 줄을 골라 "권장<TAB>조건<TAB>근거<TAB>출처"… | cpu | 1.143 | 1.257 | 1.1 | 3.5 | 0 → 0 |  |
| scv_mp_warn_keep | 경고 파일에서 "[SCV 가이드]" 줄과 그 뒤 두… | cpu | 1.633 | 6.080 | 3.7 | 3.5 | 0 → 0 |  |
| scv_pd_lang | 파일 이름의 확장자로 함수 찾기 규칙 | cpu | 0.035 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_pr_base_branch | PR 대상 브랜치를 정한다 | cpu | 0.045 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_pr_stray_changes | git 상태 기록에서 허용 경로 밖의 변경 경로만… | cpu | 8.800 | 33.111 | 3.8 | 3.0 | 0 → 0 |  |
| scv_rc_allowed_out | 후보 키에서 허용목록에 있는 키를 뺀 나머지를 낸다 | cpu | 1.487 | 5.260 | 3.5 | 3.0 | 0 → 0 |  |
| scv_rc_duplicate_keys | 표준입력 "키 파일" 줄에서 두 파일 이상에 나온… | cpu | 4.080 | 4.187 | 1.0 | 3.1 | 3 → 3 |  |
| scv_rc_normative_rows | 표준입력 "파일 줄번호 본문" 표에서 규범 동사가 든… | cpu | 3.053 | 11.357 | 3.7 | 3.4 | 0 → 0 |  |
| scv_rc_precedence_violations | 우선순위 어휘를 담은 줄 중 참조형 · 허용… | cpu | 0.363 | 0.594 | 1.6 | 3.4 | 0 → 0 |  |
| scv_reg_collect_keys | 여러 블록의 줄에서 시험 줄 키를 처음 나온… | cpu | 112.000 | 466.000 | 4.2 | 3.0 | 0 → 0 |  |
| scv_resume_other_active | 고른 경로를 뺀 나머지 active 경로들을 한 줄씩… | cpu | 1.163 | 3.933 | 3.4 | 3.1 | 0 → 0 |  |
| scv_resume_pick_active | "경로 status mtime" 줄들 중 active 이고 mtime… | cpu | 1.736 | 6.279 | 3.6 | 3.2 | 0 → 0 |  |
| scv_show_real_lookup | 열쇠 붙은 발췌 줄마다 저장된 답이 있으면 A… | cpu | 1.847 | 2.147 | 1.2 | 3.3 | 1 → 1 |  |
| scv_show_real_pick | 사람 턴 줄들에서 두 기간 안에서 출력을 보였으나… | cpu | 3.400 | 3.920 | 1.2 | 3.6 | 0 → 0 |  |
| scv_step_active_plan | "계획<TAB>상태" 줄들 중 구현 중 | cpu | 1.186 | 4.093 | 3.5 | 3.1 | 0 → 0 |  |
| scv_stop_pick_source | 호스트가 넘긴 답을 먼저, 없으면 원본의 이번 턴… | cpu | 0.060 | 0.120 | 2.0 | 3.1 | 0 → 0 |  |
| scv_tc_filter | 바뀐 경로 목록에서 SCV 기록 폴더 · graft… | cpu | 14.833 | 51.500 | 3.5 | 3.3 | 0 → 0 |  |
| scv_tc_mine_only | 경로 줄들 중 '이 세션이 쓴 파일' 목록에… | cpu | 1.127 | 4.880 | 4.3 | 3.1 | 0 → 0 |  |
| scv_writing_over_limit | 줄들 중 글자 수가 한도를 넘는 줄을 "글자수<탭>줄"… | cpu | 1.092 | 3.693 | 3.4 | 3.0 | 0 → 0 |  |
| scv_writing_vague_criteria | 통과 기준 줄 중 값 · 정확한 문구가… | cpu | 1.124 | 3.740 | 3.3 | 3.1 | 0 → 0 |  |
| settings_resolve | 환경변수 · 설정 파일 · 프로젝트 · 기본값… | cpu | 0.043 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| record_kind_normalize | 기록 종류 이름의 앞뒤 공백을 떼고 소문자로 맞춘다 | cpu | 0.492 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_answer_body | 답에서 코드 블록 | cpu | 3.170 | 12.083 | 3.8 | 3.2 | 0 → 0 |  |
| scv_as_excerpt | 아주 긴 줄에서 낱말이 맞은 자리 앞뒤만 남긴… | cpu | 1.967 | 2.080 | 1.1 | 3.2 | 1 → 1 |  |
| scv_dreams_esc | 글의 & · 꺾쇠 · 따옴표 · «… | cpu | 0.102 | 0.541 | 5.3 | 3.1 | 0 → 0 |  |
| scv_dreams_mask | 글을 한 줄로 줄이고 경로 · 메일 ·… | cpu | 16.579 | 26.167 | 1.6 | 3.2 | 1 → 1 |  |
| scv_force_trim_diagnosis | 표준입력 점검 출력에서 진단부터 끝까지만 남긴다 | cpu | 0.207 | 0.268 | 1.3 | 3.0 | 0 → 0 |  |
| scv_lang_drop_machine | 사람이 쓰지 않은 기계 글 블록 | cpu | 1.146 | 12.227 | 10.7 | 3.2 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_lint_strip_quoted | 글에서 따옴표 · 괄호 안을 비워 인용문 속… | cpu | 0.607 | 5.833 | 9.6 | 3.3 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_lower | ASCII 대문자만 소문자로 바꾼다 | cpu | 0.113 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_mp_guide_rebase | 기록된 가이드 경로 · 표시 명령을 지금 설치본… | cpu | 2.007 | 7.279 | 3.6 | 3.6 | 0 → 0 |  |
| scv_mp_normalize_id | 모델 id 를 앞뒤 공백 없이 소문자로 바꾸고… | cpu | 0.116 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_text | 구역에서 표식 줄과 통로별 해로운 변경 줄을 뺀… | cpu | 1.527 | 5.860 | 3.8 | 3.5 | 0 → 0 |  |
| scv_mp_register_normalize | 제출 텍스트를 탭 구분 세 칸으로 맞춘다 | cpu | 5.737 | 22.286 | 3.9 | 3.4 | 0 → 0 |  |
| scv_mx_strip_comment | 값 뒤의 " # 주석" 과 감싼 따옴표를… | cpu | 0.490 | 0.556 | 1.1 | 3.0 | 0 → 0 |  |
| scv_mx_trim | 앞뒤 공백 · 탭 · 줄바꿈을 지운다 | cpu | 0.075 | 0.179 | 2.4 | 3.0 | 0 → 0 |  |
| scv_plan_norm_req | 요건 글 하나를 맞대기 좋게 다듬는다 | cpu | 0.511 | 3.030 | 5.9 | 3.1 | 0 → 0 |  |
| scv_tc_words | 글을 맞대기용 낱말들로 나눈다 | cpu | 22.000 | 385.000 | 17.5 | 3.2 | 0 → 0 | 배수 한도(8배) 넘음 |

잰 함수 362 · 못 잰 함수 1(불러오지 못함 0 · 셸 함수 아님 0 · 재지 못함 1) · 늘려 재지 못함 154 · 배수 한도 넘음 15 · 입력만큼 부름 1
