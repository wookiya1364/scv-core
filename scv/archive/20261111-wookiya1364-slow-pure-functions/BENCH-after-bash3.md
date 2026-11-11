잰 환경: bash 3.2.57(1)-release · LC_ALL= · GPU 도구 none

| 함수 | 하는 일 | 잣대 | 한 번(ms) | 4배 입력(ms) | 배수 | 메모리(MB) | 부른 횟수 | 비고 |
|---|---|---|---|---|---|---|---|---|
| pb_block_text | 한도를 넘은 것의 사람이 읽는 줄들에서, 멈춘 턴에… | cpu | 0.089 | 0.228 | 2.6 | 3.2 | 0 → 0 |  |
| pb_fail_lines | 판정 줄들 | cpu | 2.060 | 6.120 | 3.0 | 3.2 | 0 → 0 |  |
| pb_render | 표의 줄들 | cpu | 1.100 | 1.727 | 1.6 | 3.5 | 0 → 0 |  |
| pb_render_compare | 앞뒤 잰 줄들과 판정 줄들에서 사람이 읽는 표… | cpu | 1.807 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| pb_render_composed | 엮은 함수 줄들 | cpu | 2.700 | 3.360 | 1.2 | 3.4 | 0 → 0 |  |
| pb_row | 한 함수의 1배 줄과 4배 줄 | cpu | 1.749 | 1.967 | 1.1 | 3.2 | 0 → 0 |  |
| env_settings_unset_args | SCV_ENV_LOADED_KEYS 의 키마다 "-u 키" 두 줄을 내… | cpu | 0.037 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| pc_render_catalog | 항목 · 종류 표 · 다른 언어 짝으로… | cpu | 2.487 | 2.513 | 1.0 | 3.1 | 1 → 1 |  |
| record_index_entry | 종류 · 키 · 파일 · 오프셋 ·… | cpu | 0.983 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| run_manifest_path | 계획 슬러그로 실행 매니페스트 파일 경로를 만든다 | cpu | 0.037 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_as_render | 묶음 줄들을 사람이 읽는 검색 결과 글로 만든다 | cpu | 0.054 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_choice_line | 선택지 도구 이름으로 매 턴 싣는 안내 한… | cpu | 0.035 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_choice_reason | 글로 묻고 끝낸 턴을 막을 때 모델에게 보이는… | cpu | 0.041 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_delegate_block | 위임 스위치가 켜진 프로젝트에 싣는 고정 지시 블록 | cpu | 0.068 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_dreams_judge_prompt | 개선점 줄 하나와 가린 발췌들로 판정자에게 보낼 질문… | cpu | 1.259 | 1.240 | 1.0 | 3.2 | 0 → 0 |  |
| scv_dreams_ratio | 두 수로 비율 "n.n" | cpu | 0.043 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_dreams_render_html | 기간 · 분포 · 개선점 · 근거 ·… | cpu | 1.997 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_dreams_render_summary | 기간 · 개선점 줄들로 다음 턴에 싣는 [SCV… | cpu | 0.690 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_dreams_svg_bars | 제목과 "라벨 탭 값" 줄들로 막대 차트 SVG… | cpu | 27.636 | 110.000 | 4.0 | 3.4 | 0 → 0 |  |
| scv_dreams_tip_text | 개선점 줄 하나를 사람이 읽는 한 문장으로 만든다 | cpu | 0.068 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_drift_line | 시각 · 턴 · 메아리 판정 · 위반… | cpu | 0.667 | 1.893 | 2.8 | 3.1 | 0 → 0 |  |
| scv_evidence_render | 근거 목록을 사람이 읽을 기록용 불릿 줄들로 만든다 | cpu | 0.423 | 0.829 | 2.0 | 3.2 | 0 → 0 |  |
| scv_finish_note | 끝 보고 문제 줄들을 설정 언어로 된 교정… | cpu | 1.637 | 7.947 | 4.9 | 3.3 | 0 → 0 |  |
| scv_finish_rule_line | 매 턴 맨 앞에 실을 확인 범위 안내… | cpu | 0.038 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_force_banner | 준비가 켜져 있으면 | cpu | 0.034 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_force_routing | 매 턴 맨 앞에 싣는 고정 지시 블록 | cpu | 0.051 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_gates_reason | 받은 막는 이유들 | cpu | 0.054 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_gates_record | 막은 검사들을 이어 새 전달 기록 한 줄을… | cpu | 0.061 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_graft_notice | Graft 상태와 지원 파일 수를 보고 안내 한… | cpu | 0.051 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_graft_render_ask | ask 후보 줄들을 사람이 읽을 줄들로 풀어 쓴다 | cpu | 0.198 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_graft_render_blast | blast 요약 레코드를 사람이 읽을 줄들로 풀어 쓴다 | cpu | 0.185 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_graph_build | links · touches · refs · 존재 목록… | cpu | 19.600 | - | - | 3.0 | 1 → - | 늘려 재지 못함 |
| scv_graph_impact | graph.json 에서 경로마다 함께 바뀐 파일 · 계획… | cpu | 45.429 | - | - | 3.0 | 3 → - | 늘려 재지 못함 |
| scv_graph_report | graph.json 텍스트를 GRAPH_REPORT.md 마크다운 | cpu | 16.579 | - | - | 3.0 | 1 → - | 늘려 재지 못함 |
| scv_hstate_brief_line | 진단이 안 바뀐 턴에 진단 전체 대신 싣는… | cpu | 0.038 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_hstate_render | \x1f 로 구분한 상태를 표식 JSON 한 줄로… | cpu | 0.194 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_lang_fix_note | 다른 언어 줄 수와 자리 | cpu | 0.058 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_lang_rule_line | 설정 언어로 쓴 언어 규칙 한 줄을 만든다 | cpu | 0.041 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_mp_effort_block | effort 를 한 번 물으라는 안내 줄을 만든다 | cpu | 0.048 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_first_turn_lines | 새 컨텍스트 첫 턴에 실을 가이드 안내 블록을… | cpu | 1.127 | 3.747 | 3.3 | 3.4 | 0 → 0 |  |
| scv_mp_gate_reason | 편집 거절 판정에 맞는 사유 한 줄을 만든다 | cpu | 0.053 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_gate_reason_sub | 하위 에이전트의 쓰기를 거절하는 사유 한 줄을 만든다 | cpu | 0.044 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_guide_lines | 결정 · 키 · 경로 · 경과 일수로… | cpu | 0.069 | - | - | 3.5 | 0 → - | 늘려 재지 못함 |
| scv_mp_guides_candidates | 가이드 폴더 후보 경로들을 한 줄씩 낸다 | cpu | 0.043 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_help_reason | help 를 부르기 전 도구를 거절할 때 쓸… | cpu | 0.040 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_candidates | 코어 루트로 원칙 파일 후보 경로 두 개를… | cpu | 0.052 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_reason | 문제 표를 넣어 막힐 때 모델에게 주는 원칙… | cpu | 0.037 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_speaker_label | 대화 기록의 모델 id 로 저널 화자 이름 | cpu | 0.144 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_stop_reason | 종료를 막는 이유 한 줄을 만든다 | cpu | 0.053 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_turn_block | 매 턴 훅이 싣는 "가이드대로 다시 쓰기 ·… | cpu | 0.061 | - | - | 3.4 | 0 → - | 늘려 재지 못함 |
| scv_mp_turn_dir | 저널 폴더와 세션 이름으로 이번 턴 상태 폴더… | cpu | 0.042 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_warn_lines | 판정 줄들을 다음 턴에 실을 경고 문장으로 바꾼다 | cpu | 0.196 | - | - | 3.4 | 0 → - | 늘려 재지 못함 |
| scv_mx_render_models | 모델별 답 수 줄들을 표의 "모델별 답 수"… | cpu | 1.430 | 5.260 | 3.7 | 3.3 | 0 → 0 |  |
| scv_mx_render_table | 네 요약 줄 | cpu | 2.573 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_mx_render_tsv | 지표 이름과 지표 줄들을 | cpu | 1.180 | 3.947 | 3.3 | 3.1 | 0 → 0 |  |
| scv_plan_history_add | PLAN.md 글의 `## 변경 이력` 절 끝에 사건… | cpu | 6.380 | 33.900 | 5.3 | 3.3 | 0 → 0 |  |
| scv_plan_redo_step | 끝난 단계 n 의 요건이 바뀌었을 때 맨… | cpu | 3.750 | 15.600 | 4.2 | 3.3 | 0 → 0 |  |
| scv_resume_header | 컨텍스트가 비워진 이유 한 줄 머리말을 만든다 | cpu | 0.050 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_show_real_excerpts | 애매한 턴 줄마다 보인 출력과 끝 글 마지막… | cpu | 15.316 | 15.600 | 1.0 | 3.3 | 1 → 1 |  |
| scv_show_real_judge_prompt | 물을 턴 줄들로 판정자에게 보낼 질문 글을 만든다 | cpu | 2.107 | - | - | 3.4 | 1 → - | 늘려 재지 못함 |
| scv_show_real_pct | 부분과 전체로 "N% | cpu | 0.040 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_show_real_per | 합과 세션 수로 세션당 값 "A.BC | cpu | 0.043 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_show_real_render | 셈 두 줄과 언어 · 기간 · 파일… | cpu | 64.200 | 278.000 | 4.3 | 3.4 | 0 → 0 |  |
| scv_show_real_rule | 실체 보여 주기 켬 여부와 통로로 매 턴… | cpu | 0.044 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_show_real_zip | 물을 턴 줄들과 판정자 답 줄들을 짝지어 A… | cpu | 0.388 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_step_line | 단계 보고 도구 이름과 구현 중인 계획 이름으로… | cpu | 0.050 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_tc_block_msg | 막을 때 모델에게 줄 말을 만든다 | cpu | 0.054 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_tc_choice_entry | 선택 답 한 개를 계획 변경 이력 항목으로… | cpu | 0.086 | 0.172 | 2.0 | 3.2 | 0 → 0 |  |
| scv_tc_exempt_entry | 예외 기록 한 줄 | cpu | 0.100 | 0.255 | 2.6 | 3.2 | 0 → 0 |  |
| scv_tc_progress_entry | 계획 안 일의 진행 한 줄 | cpu | 0.103 | 0.278 | 2.7 | 3.3 | 0 → 0 |  |
| pb_changed_names | 앞 코드와 뒤 코드의 함수 본문 글 | cpu | 2.237 | 3.000 | 1.3 | 3.2 | 1 → 1 |  |
| scv_tc_diff | 시작 사진과 끝 사진 | cpu | 6.105 | 18.579 | 3.0 | 3.2 | 1 → 1 |  |
| scv_tc_new_lines | 정렬된 두 묶음에서 뒤 묶음에만 있는 줄을 낸다 | cpu | 1.820 | 7.368 | 4.0 | 3.2 | 0 → 0 |  |
| scv_ver_lt | 첫 버전이 둘째 버전보다 낮으면 참 | cpu | 0.416 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| below_raw_root | 경로에서 원자료 폴더 뿌리까지를 떼어 낸다 | cpu | 0.052 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| key_of | 폴더 경로를 사진 파일 이름으로 바꾼다 | cpu | 0.214 | 0.759 | 3.5 | 3.0 | 0 → 0 |  |
| pb_scale_args | 예시의 인자 글에서 여러 줄 값은 줄을, 여러… | cpu | 4.053 | 18.875 | 4.7 | 3.2 | 0 → 0 |  |
| pb_times_secs | 셸의 times 출력 글 | cpu | 1.940 | 2.250 | 1.2 | 3.2 | 1 → 1 |  |
| pb_to_milli | 소수 글을 천분의 일 단위 정수로 바꾼다 | cpu | 0.056 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_as_group_of | 파일 경로에서 묶음 이름을 낸다 | cpu | 0.043 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_dreams_day | YYYYMMDD 를 YYYY-MM-DD 로 바꾼다 | cpu | 0.051 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_dreams_period_ord | 날짜 YYYYMMDD 를 기간 단위 | cpu | 0.062 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_dreams_period_range | 기간 순번과 단위로 "시작 끝" YYYYMMDD 를 낸다 | cpu | 2.213 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_dreams_tag | « » 로 적은 짧은 HTML 조각을 꺾쇠… | cpu | 0.042 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_evidence_build | 사건 줄들을 근거 목록으로 바꾼다 | cpu | 0.797 | 1.491 | 1.9 | 3.9 | 0 → 0 |  |
| scv_graph_normpath | 경로의 "./" 와 "a/../" 를 접고 겹친 슬래시를… | cpu | 0.189 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_hstate_mark | 상태를 "규약을 읽었다" | cpu | 0.191 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_hstate_reload | 상태 · 세션 번호 · 사건 | cpu | 0.207 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_guides_dir | 프로필 값이 절대 경로면 그대로, 상대 경로면 코어… | cpu | 0.040 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_lang | SCV_LANG 값을 원칙 구역 이름 | cpu | 0.484 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_restamp | 읽음 기록의 옛 지문을 새 지문으로 바꾼 줄을… | cpu | 0.512 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_turn_restamp | 이번 턴 기록의 옛 지문을 새 지문으로 바꾼… | cpu | 0.502 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mx_civil_to_minutes | "YYYY-MM-DD HH:MM" 을 1970-01-01 00:00 기준 분 수로… | cpu | 0.071 | 0.128 | 1.8 | 3.4 | 0 → 0 |  |
| scv_mx_fmt10 | 10배 한 정수를 소수 한 자리 "d.d" 로… | cpu | 0.042 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mx_resolve_conv_path | 계획서에 적힌 대화 경로를 SCV_DIR 기준 후보 경로… | cpu | 0.045 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_obsolete_frontmatter | PLAN.md 글의 앞머리에서 세 칸 | cpu | 3.160 | 14.091 | 4.5 | 3.2 | 0 → 0 |  |
| scv_plan_fm_drop | PLAN.md 글의 앞머리에서 한 칸의 줄을 지운다 | cpu | 2.987 | 14.409 | 4.8 | 3.3 | 0 → 0 |  |
| scv_plan_fm_set | PLAN.md 글의 앞머리에서 한 칸을 바꾼다 | cpu | 3.070 | 11.429 | 3.7 | 3.3 | 0 → 0 |  |
| scv_plan_insert_step | Suggested path 의 after 번 단계 뒤에 새… | cpu | 10.367 | 43.250 | 4.2 | 3.5 | 0 → 0 |  |
| scv_plan_link_return | 새 계획 B 에 끝나면 돌아갈 계획 A… | cpu | 6.380 | 23.286 | 3.6 | 3.3 | 0 → 0 |  |
| scv_plan_mark_pause | 계획 A 를 보류로 바꾼다 | cpu | 13.167 | 48.571 | 3.7 | 3.2 | 0 → 0 |  |
| scv_plan_mark_resume | 보류였던 계획 A 를 진행 중으로 되돌린다 | cpu | 17.556 | 81.500 | 4.6 | 3.3 | 0 → 0 |  |
| scv_plan_shift_progress | 단계를 after 번 뒤에 끼운 뒤, 변경 이력의… | cpu | 2.480 | 12.080 | 4.9 | 3.6 | 0 → 0 |  |
| scv_reg_rewrite_line | 시험 줄이면 그 명령을 기록된 종료 코드 ' | cpu | 14.000 | 52.833 | 3.8 | 3.4 | 0 → 0 |  |
| scv_show_real_lines | \x1e 로 이은 글을 줄바꿈으로 나눈 글로 바꾼다 | cpu | 0.176 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_show_real_local_date | 기록 시각 | cpu | 0.112 | - | - | 3.6 | 0 → - | 늘려 재지 못함 |
| scv_show_real_merge | 분류된 턴 줄들에서 답이 yes 인 턴의 보여… | cpu | 1.863 | - | - | 3.2 | 1 → - | 늘려 재지 못함 |
| scv_show_real_offset | +HHMM · -HHMM 모양의 오프셋을 분으로 바꾼다 | cpu | 0.049 | - | - | 3.4 | 0 → - | 늘려 재지 못함 |
| scv_show_real_range | 기간 글 YYYY-MM-DD..YYYY-MM-DD 를 "시작 끝" YYYYMMDD 두… | cpu | 0.933 | - | - | 3.5 | 0 → - | 늘려 재지 못함 |
| scv_stop_notice | 막는 이유들을 다음 턴 안내 줄들로 바꾼다 | cpu | 1.177 | 4.013 | 3.4 | 3.2 | 0 → 0 |  |
| scv_tc_abs_paths | 저장소 맨 위 경로와 그 안의 상대 경로… | cpu | 1.103 | 4.387 | 4.0 | 3.2 | 0 → 0 |  |
| scv_tc_plan_lines | 계획 글 여러 개의 이력 · 단계 줄을… | cpu | 3.990 | 13.125 | 3.3 | 3.4 | 1 → 1 |  |
| scv_tc_record_globs | 기록 폴더의 실제 경로들 중 이 저장소 뿌리… | cpu | 1.820 | 7.824 | 4.3 | 3.3 | 0 → 0 |  |
| scv_tc_req_tag | 기록 줄에 붙일 요청 꼬리를 만든다 | cpu | 0.142 | 0.553 | 3.9 | 3.3 | 0 → 0 |  |
| settings_merge_defaults | 사용자 JSON 에 기본값 JSON 을 깔아 병합한다 | unmeasured | 14.273 | - | - | 2.9 | 2 → - | 재지 못함 |
| pb_gpu_summary | GPU 표본 줄들 | cpu | 1.827 | 6.420 | 3.5 | 3.4 | 0 → 0 |  |
| pb_median | 빈칸으로 나눈 수들의 가운데값을 소수 셋째 자리로 낸다 | cpu | 37.000 | 223.000 | 6.0 | 3.2 | 0 → 0 |  |
| pb_ratio | 앞 값과 뒤 값에서 뒤 ÷ 앞을 소수… | cpu | 0.930 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| pb_reps_next | 잰 CPU 초와 되풀이 수를 보고 다음 되풀이… | cpu | 0.060 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| pb_scale_ratio | 1배 값과 4배 값에서 배수를 소수 한 자리로… | cpu | 0.972 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_as_count_terms | 한 줄에 낱말 목록 중 몇 개가 들어… | cpu | 7.500 | 16.526 | 2.2 | 3.1 | 2 → 2 |  |
| scv_dreams_distribution | 계획마다 보관까지의 사람 질의 수와 근거 턴 id… | cpu | 37.750 | 145.667 | 3.9 | 3.3 | 0 → 0 |  |
| scv_dreams_periods | 사람 턴 줄들과 보관 줄들을 기간별 질의 ·… | cpu | 36.111 | 145.000 | 4.0 | 3.3 | 0 → 0 |  |
| scv_dreams_totals | 기간 줄들에서 마지막 보관이 있는 기간까지의 질의 합과… | cpu | 1.900 | 5.840 | 3.1 | 3.3 | 0 → 0 |  |
| scv_graft_ext_histogram | 표준입력 파일 경로들에서 "확장자 개수" 표를 만든다 | cpu | 1.663 | 1.900 | 1.1 | 3.0 | 1 → 1 |  |
| scv_graft_supported_count | 확장자 히스토그램에서 지원 언어 파일 수의 합을 낸다 | cpu | 1.827 | 6.740 | 3.7 | 3.2 | 0 → 0 |  |
| scv_graph_cochange | 계획별 파일 목록 | cpu | 16.000 | 18.368 | 1.1 | 3.1 | 1 → 1 |  |
| scv_lint_hangul_ratio | 글에서 한글 글자가 한글 · 영문 글자 중… | cpu | 1.600 | 6.340 | 4.0 | 3.2 | 0 → 0 |  |
| scv_lint_sentences | 한 덩어리 글의 문장 수를 센다 | cpu | 2.680 | 21.067 | 7.9 | 3.5 | 0 → 0 |  |
| scv_mp_age_days | 가져온 날짜부터 오늘까지 지난 일수를 센다 | cpu | 1.151 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mx_aggregate | 지표 줄들을 값 있는 수 · 전체 수… | cpu | 3.693 | 16.722 | 4.5 | 3.3 | 0 → 0 |  |
| scv_mx_count_answers | 저널에서 답 기록 머리줄을 모델 id 별로 세어… | cpu | 3.150 | 11.833 | 3.8 | 3.5 | 0 → 0 |  |
| scv_mx_count_turns | 대화 파일 텍스트의 "## Turn N" 헤딩 수를… | cpu | 2.820 | 10.607 | 3.8 | 3.4 | 0 → 0 |  |
| scv_mx_metric_lead_time | 색인의 slug 마다 가장 이른 adopted 에서 archived… | cpu | 2.867 | 9.767 | 3.4 | 3.2 | 0 → 0 |  |
| scv_show_real_count | 분류된 턴 줄들을 두 기간 | cpu | 35.300 | 140.000 | 4.0 | 3.6 | 0 → 0 |  |
| scv_show_real_judge_count | 판정자 답 줄들에서 기간마다 판정한 턴 · 그중… | cpu | 2.053 | 7.526 | 3.7 | 3.4 | 0 → 0 |  |
| scv_tc_overlap_count | 항목 낱말들 중 메모 낱말에 있는 것의 수와… | cpu | 0.068 | 0.113 | 1.7 | 3.1 | 0 → 0 |  |
| scv_tc_req_count | 계획 글에서 새로 생긴 줄들 중 이번 턴… | cpu | 1.099 | 3.827 | 3.5 | 3.3 | 0 → 0 |  |
| scv_tc_struct_count | 계획 글에서 새로 생긴 줄들 중 구조 줄 | cpu | 3.133 | 12.720 | 4.1 | 3.7 | 0 → 0 |  |
| pb_calls | 함수 본문 글 | cpu | 2.580 | 7.372 | 2.9 | 3.3 | 1 → 1 |  |
| pb_parse_ioreg | 맥의 그래픽 장치 정보 글에서 "사용률 %<탭>쓰는 메모리… | cpu | 2.000 | 2.490 | 1.2 | 3.2 | 1 → 1 |  |
| pb_parse_nvidia | nvidia-smi 의 "사용률, 메모리 MiB" 줄들에서 "사용률 %<탭>쓰는… | cpu | 0.227 | 0.243 | 1.1 | 3.3 | 0 → 0 |  |
| pb_parse_time | 시간 재는 명령의 출력 글에서 "벽시계 초<탭>CPU 초<탭>메모리… | cpu | 2.067 | 2.730 | 1.3 | 3.2 | 1 → 1 |  |
| pb_roles | 사전 글에서 "함수<탭>하는 일 | cpu | 3.983 | 15.100 | 3.8 | 3.4 | 0 → 0 |  |
| pb_targets | 사전 글에서 잴 목록 "함수<탭>파일<탭>언어<탭>1배 인자<탭>4배 인자<탭>늘림 | cpu | 45.857 | 184.500 | 4.0 | 3.3 | 0 → 0 |  |
| pc_extract_entries | 소스 글에서 표식 | cpu | 2.400 | 3.230 | 1.3 | 3.2 | 1 → 1 |  |
| pc_kinds_from_contract | 계약 문서의 종류 표에서 종류 · 파일 이름… | cpu | 1.800 | 2.087 | 1.2 | 3.1 | 1 → 1 |  |
| pc_lang_of | 파일 경로의 확장자로 언어 표시를 낸다 | cpu | 0.040 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| pc_split_example | 예시 한 줄을 인자 · 기대 출력 ·… | cpu | 0.256 | 0.545 | 2.1 | 3.4 | 0 → 0 |  |
| plan_title | 계획 글의 제목 | cpu | 0.847 | 0.923 | 1.1 | 3.1 | 0 → 0 |  |
| record_index_fields | 색인 레코드 한 줄을 표시 · 키 ·… | cpu | 0.206 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_as_parse_terms | 물음 한 줄을 낱말 목록 | cpu | 3.347 | 4.080 | 1.2 | 3.0 | 2 → 2 |  |
| scv_choice_q_after | 줄에서 사용자에게 묻는 마지막 문장 끝 물음표 뒤의… | cpu | 1.086 | 1.857 | 1.7 | 3.2 | 0 → 0 |  |
| scv_dreams_archive_dates | "계획 이름 탭 archived_at" 줄들에서 보관 날짜 줄… | cpu | 55.667 | 222.000 | 4.0 | 3.2 | 1 → 1 |  |
| scv_dreams_entries | 세션 기록 JSONL | cpu | 20.071 | 22.500 | 1.1 | 3.4 | 1 → 1 |  |
| scv_dreams_human_turns | 기록 항목 줄들에서 모델이 일한 사람 턴만 "세션… | cpu | 37.500 | 152.500 | 4.1 | 3.2 | 0 → 0 |  |
| scv_dreams_judge_parse | 판정자 답 글에서 rule · advice 가 있는… | cpu | 15.182 | 16.100 | 1.1 | 3.3 | 1 → 1 |  |
| scv_dreams_register_features | 기록 항목 줄들에서 사람 턴마다 마지막 등록 하나 | cpu | 20.000 | 76.000 | 3.8 | 3.3 | 0 → 0 |  |
| scv_evidence_test_first | 근거 목록에서 시험 파일을 바꾼 뒤 실패하는 시험… | cpu | 8.821 | 33.667 | 3.8 | 3.5 | 0 → 0 |  |
| scv_finish_scan | 끝 답에서 확인 범위 줄 | cpu | 6.300 | 24.462 | 3.9 | 3.5 | 0 → 0 |  |
| scv_graft_ask_summary | ask JSON 에서 점수 높은 후보 n 개를… | cpu | 17.056 | - | - | 3.0 | 1 → - | 늘려 재지 못함 |
| scv_graft_blast_summary | blast JSON 을 "파일수 US 심볼수 US 상위"… | cpu | 16.789 | - | - | 2.9 | 1 → - | 늘려 재지 못함 |
| scv_graph_decision_refs | DECISIONS.md 에서 결정 제목과 그 결정이 참조한 계획… | cpu | 2.633 | 9.786 | 3.7 | 3.5 | 0 → 0 |  |
| scv_graph_doc_links | 마크다운 본문에서 상대 .md 링크만 뽑아 "문서\x1f대상 | cpu | 35.111 | 142.000 | 4.0 | 3.5 | 0 → 0 |  |
| scv_graph_plan_records | awk 가 뽑은 T/E/S/B 레코드에서 경로 모양 토큰만… | cpu | 7.280 | 28.000 | 3.8 | 3.5 | 0 → 0 |  |
| scv_graph_plan_touches | PLAN.md 본문에서 건드리는 파일 | cpu | 8.868 | 21.267 | 2.4 | 3.5 | 1 → 1 |  |
| scv_graph_plans_batch | 여러 계획의 awk 레코드 | cpu | 24.545 | 91.000 | 3.7 | 3.2 | 0 → 0 |  |
| scv_hstate_nonce | 상태에서 규약 지문 | cpu | 0.186 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_hstate_parse | 표식 JSON 한 줄 | cpu | 0.102 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_lang_first_other | 글에서 설정 언어가 아닌 첫 줄을 꺼내 앞… | cpu | 36.556 | 146.667 | 4.0 | 3.1 | 0 → 0 |  |
| scv_lang_new_text | 이번 턴 어시스턴트 글 목록에서 지난 검사 id… | cpu | 2.427 | 8.882 | 3.7 | 3.1 | 0 → 0 |  |
| scv_mp_common | 색인에서 모든 모델에 붙는 공통 원문의 파일과 날짜를… | cpu | 0.185 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_common_key | 색인에서 공통 | cpu | 0.177 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_guide_fold | 모델이 실행한 mark 명령 사건들로 읽은 모델 집합을… | cpu | 2.220 | 10.400 | 4.7 | 3.6 | 0 → 0 |  |
| scv_mp_harm_line | 구역에서 통로 | cpu | 0.233 | 0.348 | 1.5 | 3.5 | 0 → 0 |  |
| scv_mp_lookup | 색인에서 모델 id 가 정확히 맞는 첫 행의… | cpu | 1.339 | 1.640 | 1.2 | 3.5 | 0 → 0 |  |
| scv_mp_meta | 색인의 "@이름" 행 | cpu | 0.185 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_pick | 원칙 파일 본문에서 이름이 맞는 구역의 전문을 꺼낸다 | cpu | 0.358 | 0.631 | 1.8 | 3.5 | 0 → 0 |  |
| scv_mp_principle_section | 원칙 파일 본문에서 언어에 맞는 구역을 꺼낸다 | cpu | 1.693 | 2.080 | 1.2 | 3.5 | 0 → 0 |  |
| scv_mp_read_parse | 읽음 기록 한 줄을 "지문 모델id" 두 칸으로… | cpu | 0.049 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_reg_seq | 등록 첫 줄에서 세 번째 칸 | cpu | 0.043 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_register_rewrite | 제출 텍스트에서 rewrite 행의 값 | cpu | 0.238 | 0.378 | 1.6 | 3.5 | 0 → 0 |  |
| scv_mp_register_value | 제출 텍스트 | cpu | 0.225 | 0.277 | 1.2 | 3.5 | 0 → 0 |  |
| scv_mp_turn_parse | 이번 턴 기록 한 줄을 "지문 모델 결정… | cpu | 0.061 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mx_parse_decisions | DECISIONS.md 에서 | cpu | 29.833 | 127.333 | 4.3 | 3.6 | 0 → 0 |  |
| scv_mx_parse_index | INDEX.yaml 텍스트에서 slug · status · obsoleted_by 를… | cpu | 152.000 | 609.000 | 4.0 | 3.2 | 0 → 0 |  |
| scv_mx_parse_plan | PLAN.md 프런트매터에서 대화 경로 · supersedes 개수 ·… | cpu | 10.029 | 19.333 | 1.9 | 3.3 | 0 → 0 |  |
| scv_pd_declared | 본문에서 순수 · 부수효과 선언 | cpu | 15.895 | 63.400 | 4.0 | 3.3 | 0 → 0 |  |
| scv_pd_functions | 본문에서 이름 있는 함수 선언의 이름들을 나온 순서대로… | cpu | 25.833 | 104.000 | 4.0 | 3.0 | 0 → 0 |  |
| scv_pd_line_function | 본문 한 줄이 이름 있는 함수 선언이면 그… | cpu | 0.112 | 0.123 | 1.1 | 3.3 | 0 → 0 |  |
| scv_plan_fm_get | PLAN.md 글의 앞머리에서 한 칸의 값을 꺼낸다 | cpu | 0.279 | 0.434 | 1.6 | 3.2 | 0 → 0 |  |
| scv_plan_goal_items | `## Goals / Non-Goals` 절에서 Goals 또는 Non-Goals… | cpu | 5.267 | 21.429 | 4.1 | 3.5 | 0 → 0 |  |
| scv_plan_steps | PLAN.md 글의 Suggested path | cpu | 4.640 | 22.357 | 4.8 | 3.5 | 0 → 0 |  |
| scv_reg_line_key | 실행 줄이 '시험 파일 하나를 bash 로 부르는… | cpu | 0.158 | 0.407 | 2.6 | 3.4 | 0 → 0 |  |
| scv_reg_split_chain | 한 줄을 &&, //, ; 로 이은 조각들로… | cpu | 1.293 | 7.186 | 5.6 | 3.1 | 0 → 0 |  |
| scv_show_real_entries | 세션 기록 JSONL | cpu | 28.333 | 30.500 | 1.1 | 3.5 | 1 → 1 |  |
| scv_show_real_judge_parse | 판정자 답 글에서 길이가 n 인 yes ·… | cpu | 15.000 | 16.200 | 1.1 | 3.5 | 1 → 1 |  |
| scv_show_real_split | 기록 항목 줄들을 사람 턴 줄들 | cpu | 20.667 | 80.500 | 3.9 | 3.4 | 0 → 0 |  |
| scv_turn_group | 원본 줄들에서 마지막 사람 글 뒤의 이번 턴… | cpu | 27.143 | 26.167 | 1.0 | 3.4 | 1 → 1 |  |
| scv_turn_slice | 턴 스트림에서 마지막 사람 프롬프트 뒤의 어시스턴트 텍스트만… | cpu | 6.474 | 26.300 | 4.1 | 3.2 | 0 → 0 |  |
| scv_writing_paragraphs | 마크다운에서 코드 블록 · 제목 · 표 ·… | cpu | 2.280 | 4.147 | 1.8 | 3.0 | 1 → 1 |  |
| scv_writing_pass_criteria | 시험서에서 통과 기준 줄 | cpu | 2.347 | 2.439 | 1.0 | 3.0 | 1 → 1 |  |
| scv_writing_table_cells | 마크다운에서 코드 블록 밖 표 칸을 꺼낸다 | cpu | 2.247 | 3.090 | 1.4 | 3.0 | 1 → 1 |  |
| settings_index_json | JSON 객체의 모든 최상위 키를 "키 탭 값"… | cpu | 14.909 | - | - | 2.9 | 1 → - | 늘려 재지 못함 |
| settings_lookup_json | JSON 객체에서 키 하나의 값을 문자열로 꺼낸다 | cpu | 14.636 | - | - | 2.9 | 1 → - | 늘려 재지 못함 |
| settings_lookup_many_json | JSON 객체에서 공백으로 나눈 키 여럿의 값을 "키… | cpu | 16.158 | 29.000 | 1.8 | 2.9 | 1 → 1 |  |
| decisions_slug | 제목에서 부를 이름을 만든다 | cpu | 0.817 | 0.907 | 1.1 | 3.0 | 0 → 0 |  |
| scv_digest_fold | 표준입력 줄들을 정렬한 뒤 sha256 지문 하나로 접는다 | cpu | 5.349 | 4.980 | 0.9 | 2.8 | 3 → 3 |  |
| scv_graph_community | 노드 종류 · id · epic 으로 군집… | cpu | 0.052 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_rc_demand_keys | 표준입력 "파일 줄번호 본문" 줄에서 앞 8단어 키를… | cpu | 3.180 | 3.627 | 1.1 | 3.0 | 2 → 2 |  |
| scv_show_real_hash | 글의 SHA-256 16진 지문을 낸다 | cpu | 2.393 | - | - | 3.2 | 1 → - | 늘려 재지 못함 |
| scv_show_real_keys | 발췌 줄마다 | cpu | 2.967 | - | - | 3.3 | 1 → - | 늘려 재지 못함 |
| _scv_choice_blank | 줄이 빈 줄 | cpu | 0.038 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| _scv_choice_cue_real | 글 속 요청 말이 "언제든지 · 얼마든지" 같은… | cpu | 0.092 | 0.248 | 2.7 | 3.1 | 0 → 0 |  |
| _scv_choice_has_text | 글에 공백 · 굵게 · 닫는 괄호 말고… | cpu | 0.034 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_answer_lint | 답 본문의 골격 | cpu | 43.000 | 229.000 | 5.3 | 3.6 | 0 → 0 |  |
| scv_as_kind_of | 파일 경로 모양만 보고 기록의 종류 | cpu | 0.035 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_asks_in_text | 답이 사용자에게 글로 고르게 하거나 묻는 꼴로 끝나면… | cpu | 4.117 | 14.273 | 3.5 | 3.6 | 0 → 0 |  |
| scv_choice_q_asks | 물음표 뒤 글이 사용자에게 답을 요청하거나 추천을 달고… | cpu | 0.767 | 1.177 | 1.5 | 3.1 | 0 → 0 |  |
| scv_dreams_pasted | 사람 메시지가 붙여 넣은 글로 보이면 종료 0,… | cpu | 0.048 | 0.079 | 1.6 | 3.1 | 0 → 0 |  |
| scv_echo_check | 이번 턴 기록의 지문과 표식 지문을 견줘 skip… | cpu | 0.044 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_finish_check | 찾은 칸 · 근거 목록 · 실패를 못… | cpu | 0.550 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_is_rewrite_quote | 한 줄이 다시 쓴 요청 인용 줄 | cpu | 0.111 | 0.246 | 2.2 | 3.1 | 0 → 0 |  |
| scv_lint_bullet_polite | 불릿 한 줄이 존댓말 서술형 | cpu | 0.056 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_lint_lang_turn | 마지막 답과 이번 턴 글 전체에서, 한국어 설정인데… | cpu | 3.733 | 10.821 | 2.9 | 3.3 | 0 → 0 |  |
| scv_lint_lang_verdict | 설정 언어가 한국어인데 답 글에 한글이 거의 없으면… | cpu | 0.043 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_mp_answer_has_problem_table | 답에 "문제 표" | cpu | 0.270 | 0.367 | 1.4 | 4.2 | 0 → 0 |  |
| scv_mp_answer_has_quote | 답 본문의 코드 블록 밖에 ">" 인용 줄이… | cpu | 0.223 | 0.258 | 1.2 | 3.4 | 0 → 0 |  |
| scv_mp_answer_rewrite_on_top | 답의 첫 내용 줄 | cpu | 0.810 | 1.027 | 1.3 | 3.5 | 0 → 0 |  |
| scv_mp_answer_shows_rewrite | 답의 코드 블록 밖 인용 줄에 다시 쓴… | cpu | 0.345 | 0.837 | 2.4 | 3.5 | 0 → 0 |  |
| scv_mp_prompt_kind | 프롬프트가 알림 태그 블록뿐이면 auto, 사람이 쓴 글이… | cpu | 0.110 | - | - | 3.5 | 0 → - | 늘려 재지 못함 |
| scv_rc_is_normative | 본문에 규범 동사 | cpu | 0.086 | 0.136 | 1.6 | 3.3 | 0 → 0 |  |
| scv_rc_is_precedence | 본문에 우선순위 어휘 | cpu | 0.102 | 0.180 | 1.8 | 3.4 | 0 → 0 |  |
| scv_rc_is_reference | 본문이 Top-level rules 를 가리키는 참조형이면 참 | cpu | 0.053 | 0.110 | 2.1 | 2.9 | 0 → 0 |  |
| scv_show_real_classify | 사람 턴 줄마다 바뀜 · 보여 줌 ·… | cpu | 2.940 | 3.653 | 1.2 | 3.4 | 0 → 0 |  |
| scv_show_real_is_confirm | 질문이 계속할지와 고칠 점을 함께 묻는 확인인지 1… | cpu | 0.120 | 0.299 | 2.5 | 3.3 | 0 → 0 |  |
| scv_show_real_is_correction | 사람 메시지가 고쳐 달라는 말인지 단서 낱말 | cpu | 0.150 | 0.314 | 2.1 | 3.4 | 0 → 0 |  |
| scv_show_real_is_nochange | 모델의 글에 결과물 변화 없음 표시가 있는지 1… | cpu | 0.075 | 0.153 | 2.0 | 3.4 | 0 → 0 |  |
| scv_show_real_quotes | 실행 출력이 묻는 글 안에 그대로 인용됐는지 1… | cpu | 3.983 | 5.017 | 1.3 | 3.3 | 2 → 2 |  |
| scv_choice_gate | 묻는지 · 도구 이름 · 이미 전달 여부로… | cpu | 0.042 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_choice_off_when | "이름=값" 조건과 지금 그 이름의 환경 값이 같으면… | cpu | 0.051 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_dreams_day_trigger | 지난 드림 날짜와 오늘 날짜가 달라 드림을 띄울… | cpu | 0.045 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_dreams_start_trigger | 훅 입력의 source 값이 드림을 띄울 때 | cpu | 0.035 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_drift_decide | 메아리 판정 · 린트 위반 · 스위치로 규약을… | cpu | 0.057 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_finish_needed | 근거 목록으로 이번 턴 끝 보고에 무엇이 필요한지… | cpu | 0.195 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_gates_delivered | 이 검사가 이 세션 · 이 턴에 이미… | cpu | 0.065 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_gates_drop | 첫 멈춤에서 이 세션의 지난 기록이나 깨진 기록을… | cpu | 0.051 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_lang_stop_decide | 최종 답의 다른 언어 줄 수와 이번 턴… | cpu | 0.043 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_lang_user_other | 이번 턴 사용자 글이 다른 언어를 요청하거나 다른… | cpu | 0.615 | 0.863 | 1.4 | 3.0 | 0 → 0 |  |
| scv_mp_decision | 색인 행 유무 · 읽음 기록 · 지금… | cpu | 0.051 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_guide_decide | 읽은 모델 집합에 이 모델이 있으면 loaded, 없으면… | cpu | 0.050 | 0.076 | 1.5 | 3.2 | 0 → 0 |  |
| scv_mp_guide_from_events | 사건 줄들을 접어 이 모델 원문을 읽었는지 | cpu | 2.564 | 10.033 | 3.9 | 3.4 | 0 → 0 |  |
| scv_mp_help_needed | 이번 사람 턴에 help 를 아직 부르지 않아… | cpu | 0.044 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_gate | 문제 표 · 스위치 · 이미 전달 여부로… | cpu | 0.060 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_show | 원칙 전문을 이번 등록에 다시 실을지 | cpu | 0.038 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_register_problems | 제출 텍스트에 다시 쓴 요청과 범위가 있는지 보고… | cpu | 1.157 | 3.933 | 3.4 | 3.5 | 0 → 0 |  |
| scv_mp_rewrite_recorded | 대화 블록에 "다시 쓴 요청" 단락이 있는지 1/0… | cpu | 0.227 | 0.299 | 1.3 | 3.4 | 0 → 0 |  |
| scv_mp_scope_forbid | 범위 칸이 변경을 막는 첫머리면 그 문구를, 아니면… | cpu | 0.820 | 1.567 | 1.9 | 4.7 | 0 → 0 |  |
| scv_mp_stop_gate | 등록 · 보임 · 이미 전달 · 맨… | cpu | 0.046 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_turn_verdict | 결정 · 읽음 · 기록 · 인용 여부로… | cpu | 0.045 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_write_gate | 이번 턴 등록 상태로 파일 쓰기를 허용할지 | cpu | 0.050 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_pd_write_verdict | 편집 전에는 없던, 편집으로 새로 선언이 빠진 함수… | cpu | 1.100 | 3.653 | 3.3 | 3.0 | 0 → 0 |  |
| scv_reg_block_memo_ok | 블록이 다른 폴더로 옮겨 가면 | cpu | 0.075 | 0.179 | 2.4 | 3.2 | 0 → 0 |  |
| scv_tc_judge | 턴 끝 판정 | cpu | 0.055 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_template_decide | 도장 · 꾸러미의 지문과 버전을 보고 템플릿을 어떻게… | cpu | 0.365 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| pb_accept_covers | 사용자가 받아들인 이유들과 지금의 이유들을 견줘, 지금 것이… | cpu | 0.900 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| pb_compare | 한 함수의 앞뒤 잰 줄 | cpu | 2.510 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| pb_pick_measure | 잰 값 | cpu | 1.437 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| pc_validate_entries | 항목마다 빠진 칸 | cpu | 0.512 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_delegate_switch | 위임 스위치 값을 해석한다 | cpu | 0.042 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_dreams_tip_rule | 개선점 줄의 종류로 판정자에게 권할 가이드 규칙 이름 | cpu | 0.037 | - | - | 3.1 | 0 → - | 늘려 재지 못함 |
| scv_dreams_tips | 등록 · 사람 턴 · 분포 줄들에서 개선점… | cpu | 6.000 | 21.714 | 3.6 | 3.4 | 0 → 0 |  |
| scv_dreams_unit | 사람 턴 수로 기간 단위를 정한다 | cpu | 0.040 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_graft_status | graft 실행 파일 · 그래프 유무와 스위치로 absent… | cpu | 0.045 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_graph_is_path | 토큰이 저장소 상대 파일 경로처럼 보이는지 판정한다 | cpu | 0.064 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_graph_status_of | 그래프 존재 여부와 파일 시각으로 missing / stale… | cpu | 0.040 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_hstate_diag | 진단 본문의 해시를 직전과 견줘 "full" | cpu | 3.710 | 3.750 | 1.0 | 3.1 | 2 → 2 |  |
| scv_hstate_protocol_line | 상태와 스위치로 "PROTOCOL: load" | cpu | 0.186 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_mp_effort_verdict | effort 를 물을지 정한다 | cpu | 1.547 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mp_effort_word | effort 값 낱말이 맞는지 가려, 맞으면 소문자로 낸다 | cpu | 0.520 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_has_guides | 색인에 가이드 행 | cpu | 0.263 | 0.461 | 1.8 | 3.5 | 0 → 0 |  |
| scv_mp_read_name | 가이드 원문 이름과 그 발췌본이 있는지로, help 가… | cpu | 0.041 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_safe_name | 색인 폴더 안의 평범한 파일 이름이면 그대로, 경로… | cpu | 0.100 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_session_key | 세션 id 가 폴더 이름으로 안전하면 그대로, 아니면… | cpu | 0.077 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_switch | 스위치 값을 on/off 로 정한다 | cpu | 0.525 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_turn_dir_ok | 넘겨받은 폴더가 저널 폴더나 그 아래 세션 폴더면… | cpu | 0.493 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_was_read | 이 컨텍스트에서 그 모델 원문을 이미 읽었는지 1/0… | cpu | 0.056 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_mx_metric_followup | 색인의 slug 마다 후속 계획이 있으면 1, 없으면… | cpu | 2.413 | 7.907 | 3.3 | 3.2 | 0 → 0 |  |
| scv_plan_conflict_after | 뒤쪽 충돌 검사 | cpu | 12.625 | 123.000 | 9.7 | 3.4 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_plan_conflict_before | 앞쪽 충돌 검사 | cpu | 39.500 | 242.000 | 6.1 | 3.3 | 0 → 0 |  |
| scv_plan_fm_has | PLAN.md 글의 앞머리에 그 칸이 있으면 "1" 을… | cpu | 0.260 | 0.395 | 1.5 | 3.1 | 0 → 0 |  |
| scv_privacy_email_ok | 공개해도 되는 메일 주소 | cpu | 0.035 | - | - | 2.8 | 0 → - | 늘려 재지 못함 |
| scv_reg_is_core_loop | '코어 시험 전부' 반복 줄 | cpu | 0.153 | 0.446 | 2.9 | 3.4 | 0 → 0 |  |
| scv_show_real_channel | 쓸 수 있는 선택 창과 실행 상태로 질문… | cpu | 0.043 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_show_real_valid_day | 연 · 월 · 일이 있는 날인지 | cpu | 0.048 | - | - | 3.2 | 0 → - | 늘려 재지 못함 |
| scv_stop_mode | 설정 값으로 종료 검사가 어긋난 답을 어떻게 다룰지 | cpu | 0.036 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_switch | 설정 값을 on/off 로 정한다 | cpu | 0.042 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_tc_exempt_ok | 계획 없이 해도 되는 정한 예외 종류인지 가린다 | cpu | 0.034 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_tc_nongoal_hits | 덧붙이거나 진행으로 적으려는 글에 계획의 '하지 않음' | cpu | 47.500 | 158.000 | 3.3 | 3.4 | 0 → 0 |  |
| scv_tc_receipt | 도구가 돌린 명령 글이 계획 기록 명령 | cpu | 0.152 | 0.368 | 2.4 | 3.7 | 0 → 0 |  |
| scv_tc_step_on | 호스트 설정 글에 대시보드 | cpu | 0.128 | 0.391 | 3.1 | 3.3 | 0 → 0 |  |
| scv_tc_tool_kind | 도구 입력에 어떤 칸이 있는지로 이 도구가 파일을… | cpu | 0.039 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| scv_writing_limits | README 파일 이름으로 칸 · 문단 길이 한도 | cpu | 0.034 | - | - | 2.8 | 0 → - | 늘려 재지 못함 |
| scv_writing_pick_locale | 쓸 수 있는 UTF-8 지역 설정 이름 하나를… | cpu | 0.062 | 0.124 | 2.0 | 3.1 | 0 → 0 |  |
| settings_is_secret | 설정 키가 비밀 키 목록 | cpu | 0.043 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| attachment_scope_filter | 표준입력 줄들에서 슬러그가 든 줄만 남긴다 | cpu | 1.045 | 3.540 | 3.4 | 3.0 | 0 → 0 |  |
| pb_accept_pick | '한도를 넘은 것' 줄들 | cpu | 1.433 | 5.083 | 3.5 | 3.4 | 0 → 0 |  |
| pb_baseline_next | '입력이 커지면 위험한 함수' 기준 목록 | cpu | 2.087 | 7.579 | 3.6 | 3.1 | 0 → 0 |  |
| pb_callers | 엮은 함수 줄들 | cpu | 1.316 | 5.400 | 4.1 | 3.1 | 0 → 0 |  |
| pb_composed | "함수<탭>부르는 함수들" 줄들에서 다른 사전 함수를 N개 | cpu | 1.270 | 4.347 | 3.4 | 3.1 | 0 → 0 |  |
| pc_allowed_filter | 짝 목록에서 예외 목록에 이유와 함께 적힌 짝을… | cpu | 16.357 | 61.800 | 3.8 | 3.1 | 0 → 0 |  |
| pc_duplicate_pairs | '지문<탭>함수' 줄들에서 지문이 같은 함수 짝을 들어온 순서대로… | cpu | 12.591 | 180.500 | 14.3 | 3.1 | 0 → 0 | 배수 한도(8배) 넘음 |
| pc_mutual_pairs | 방향 있는 '가<탭>나' 줄들에서 양쪽 방향이 다 있는… | cpu | 7.882 | 88.500 | 11.2 | 3.2 | 0 → 0 | 배수 한도(8배) 넘음 |
| pc_oversize_files | 사전 파일 글들에서 줄 수가 한도를 넘는 파일… | cpu | 2.390 | 2.327 | 1.0 | 3.1 | 1 → 1 |  |
| pc_text_duplicates | 항목들의 예시를 글로 비교해, 같은 입력에 같은 출력인… | cpu | 83.500 | 340.000 | 4.1 | 3.3 | 1 → 1 |  |
| record_index_filter | 색인 텍스트에서 종류가 맞는 레코드만, 키마다 최신 하나씩… | cpu | 3.827 | 15.263 | 4.0 | 3.1 | 0 → 0 |  |
| record_index_lookup | 색인 텍스트에서 키가 같은 레코드를 낸다 | cpu | 1.307 | 4.547 | 3.5 | 3.2 | 0 → 0 |  |
| scv_as_drop_weak | 점수 매긴 줄들에서 두 낱말 이상 맞은 줄이… | cpu | 3.800 | 4.260 | 1.1 | 3.1 | 2 → 2 |  |
| scv_as_group_best | 점수 매긴 줄들에서 묶음마다 가장 높은 점수 줄… | cpu | 6.140 | 6.744 | 1.1 | 3.1 | 4 → 4 |  |
| scv_as_score_lines | 훑은 "파일:줄번호:내용" 줄들에 낱말 맞은 수 점수를 매겨… | cpu | 4.100 | 4.317 | 1.1 | 3.0 | 2 → 2 |  |
| scv_deck_source_dir | 코어 루트와 설정 값으로 덱 엔진 폴더 경로를… | cpu | 0.043 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_dreams_evidence | 개선점 줄들이 가리킨 턴 id 의 사람 메시지를… | cpu | 30.700 | 31.100 | 1.0 | 3.3 | 2 → 2 |  |
| scv_force_refresh_note | 표준입력 점검 stderr 에서 템플릿 자동 갱신에 관한… | cpu | 1.767 | 7.947 | 4.5 | 3.2 | 0 → 0 |  |
| scv_graph_god_nodes | 그래프 JSON 에서 연결 | cpu | 14.500 | - | - | 3.0 | 1 → - | 늘려 재지 못함 |
| scv_mp_effort_from_log | 세션 기록에서 뽑은 줄들 | cpu | 0.624 | 0.724 | 1.2 | 3.6 | 0 → 0 |  |
| scv_mp_effort_row | 권장 effort 표에서 이 모델의 줄을 골라 "권장<TAB>조건<TAB>근거<TAB>출처"… | cpu | 1.193 | 1.345 | 1.1 | 3.5 | 0 → 0 |  |
| scv_mp_warn_keep | 경고 파일에서 "[SCV 가이드]" 줄과 그 뒤 두… | cpu | 1.653 | 6.395 | 3.9 | 3.5 | 0 → 0 |  |
| scv_pd_lang | 파일 이름의 확장자로 함수 찾기 규칙 | cpu | 0.034 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_pr_base_branch | PR 대상 브랜치를 정한다 | cpu | 0.045 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_pr_stray_changes | git 상태 기록에서 허용 경로 밖의 변경 경로만… | cpu | 9.125 | 34.556 | 3.8 | 3.0 | 0 → 0 |  |
| scv_rc_allowed_out | 후보 키에서 허용목록에 있는 키를 뺀 나머지를 낸다 | cpu | 1.500 | 5.360 | 3.6 | 3.0 | 0 → 0 |  |
| scv_rc_duplicate_keys | 표준입력 "키 파일" 줄에서 두 파일 이상에 나온… | cpu | 4.390 | 4.360 | 1.0 | 3.0 | 3 → 3 |  |
| scv_rc_normative_rows | 표준입력 "파일 줄번호 본문" 표에서 규범 동사가 든… | cpu | 3.090 | 11.321 | 3.7 | 3.4 | 0 → 0 |  |
| scv_rc_precedence_violations | 우선순위 어휘를 담은 줄 중 참조형 · 허용… | cpu | 0.360 | 0.594 | 1.7 | 3.5 | 0 → 0 |  |
| scv_reg_collect_keys | 여러 블록의 줄에서 시험 줄 키를 처음 나온… | cpu | 107.000 | 453.000 | 4.2 | 3.0 | 0 → 0 |  |
| scv_resume_other_active | 고른 경로를 뺀 나머지 active 경로들을 한 줄씩… | cpu | 1.170 | 3.960 | 3.4 | 3.1 | 0 → 0 |  |
| scv_resume_pick_active | "경로 status mtime" 줄들 중 active 이고 mtime… | cpu | 1.759 | 6.421 | 3.7 | 3.2 | 0 → 0 |  |
| scv_show_real_lookup | 열쇠 붙은 발췌 줄마다 저장된 답이 있으면 A… | cpu | 2.053 | 2.200 | 1.1 | 3.3 | 1 → 1 |  |
| scv_show_real_pick | 사람 턴 줄들에서 두 기간 안에서 출력을 보였으나… | cpu | 3.400 | 4.080 | 1.2 | 3.6 | 0 → 0 |  |
| scv_step_active_plan | "계획<TAB>상태" 줄들 중 구현 중 | cpu | 1.203 | 4.267 | 3.5 | 3.1 | 0 → 0 |  |
| scv_stop_pick_source | 호스트가 넘긴 답을 먼저, 없으면 원본의 이번 턴… | cpu | 0.062 | 0.122 | 2.0 | 3.2 | 0 → 0 |  |
| scv_tc_filter | 바뀐 경로 목록에서 SCV 기록 폴더 · graft… | cpu | 13.588 | 52.667 | 3.9 | 3.4 | 0 → 0 |  |
| scv_tc_mine_only | 경로 줄들 중 '이 세션이 쓴 파일' 목록에… | cpu | 1.120 | 4.933 | 4.4 | 3.2 | 0 → 0 |  |
| scv_writing_over_limit | 줄들 중 글자 수가 한도를 넘는 줄을 "글자수<탭>줄"… | cpu | 1.107 | 3.787 | 3.4 | 3.0 | 0 → 0 |  |
| scv_writing_vague_criteria | 통과 기준 줄 중 값 · 정확한 문구가… | cpu | 1.120 | 3.800 | 3.4 | 3.1 | 0 → 0 |  |
| settings_resolve | 환경변수 · 설정 파일 · 프로젝트 · 기본값… | cpu | 0.042 | - | - | 3.0 | 0 → - | 늘려 재지 못함 |
| record_kind_normalize | 기록 종류 이름의 앞뒤 공백을 떼고 소문자로 맞춘다 | cpu | 0.518 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_answer_body | 답에서 코드 블록 | cpu | 3.213 | 12.080 | 3.8 | 3.2 | 0 → 0 |  |
| scv_as_excerpt | 아주 긴 줄에서 낱말이 맞은 자리 앞뒤만 남긴… | cpu | 2.220 | 2.153 | 1.0 | 3.2 | 1 → 1 |  |
| scv_dreams_esc | 글의 & · 꺾쇠 · 따옴표 · «… | cpu | 0.102 | 0.562 | 5.5 | 3.1 | 0 → 0 |  |
| scv_dreams_mask | 글을 한 줄로 줄이고 경로 · 메일 ·… | cpu | 17.053 | 26.833 | 1.6 | 3.2 | 1 → 1 |  |
| scv_force_trim_diagnosis | 표준입력 점검 출력에서 진단부터 끝까지만 남긴다 | cpu | 0.225 | 0.269 | 1.2 | 3.0 | 0 → 0 |  |
| scv_lang_drop_machine | 사람이 쓰지 않은 기계 글 블록 | cpu | 1.154 | 12.417 | 10.8 | 3.2 | 0 → 0 | 배수 한도(8배) 넘음 |
| scv_lint_strip_quoted | 글에서 따옴표 · 괄호 안을 비워 인용문 속… | cpu | 0.352 | 2.680 | 7.6 | 3.1 | 0 → 0 |  |
| scv_lower | ASCII 대문자만 소문자로 바꾼다 | cpu | 0.117 | - | - | 2.9 | 0 → - | 늘려 재지 못함 |
| scv_mp_guide_rebase | 기록된 가이드 경로 · 표시 명령을 지금 설치본… | cpu | 2.027 | 7.316 | 3.6 | 3.7 | 0 → 0 |  |
| scv_mp_normalize_id | 모델 id 를 앞뒤 공백 없이 소문자로 바꾸고… | cpu | 0.117 | - | - | 3.3 | 0 → - | 늘려 재지 못함 |
| scv_mp_principle_text | 구역에서 표식 줄과 통로별 해로운 변경 줄을 뺀… | cpu | 1.540 | 5.960 | 3.9 | 3.5 | 0 → 0 |  |
| scv_mp_register_normalize | 제출 텍스트를 탭 구분 세 칸으로 맞춘다 | cpu | 5.814 | 21.929 | 3.8 | 3.5 | 0 → 0 |  |
| scv_mx_strip_comment | 값 뒤의 " # 주석" 과 감싼 따옴표를… | cpu | 0.525 | 0.586 | 1.1 | 3.1 | 0 → 0 |  |
| scv_mx_trim | 앞뒤 공백 · 탭 · 줄바꿈을 지운다 | cpu | 0.074 | 0.178 | 2.4 | 3.0 | 0 → 0 |  |
| scv_plan_norm_req | 요건 글 하나를 맞대기 좋게 다듬는다 | cpu | 0.531 | 3.040 | 5.7 | 3.2 | 0 → 0 |  |
| scv_tc_words | 글을 맞대기용 낱말들로 나눈다 | cpu | 1.587 | 7.853 | 4.9 | 3.3 | 0 → 0 |  |

잰 함수 362 · 못 잰 함수 1(불러오지 못함 0 · 셸 함수 아님 0 · 재지 못함 1) · 늘려 재지 못함 154 · 배수 한도 넘음 4 · 입력만큼 부름 0

기준 목록: 4개
