function manifest = write_scenario_results(output_dir,scenario_registry, ...
        rows,calibration_history,options)
%WRITE_SCENARIO_RESULTS Write the unified reviewer-suite database.
%
% manifest = write_scenario_results(output_dir,scenario_registry,rows)
% manifest = write_scenario_results(output_dir,scenario_registry, ...
%     rows,calibration_history,options)
%
% rows is the struct array returned by collect_scenario_results. Every
% required output is written even when no scenario solved; failed scenarios
% retain explicit statuses and NaN metrics instead of disappearing.

if nargin < 2, scenario_registry = []; end
if nargin < 3, rows = []; end
if nargin < 4, calibration_history = []; end
if nargin < 5 || isempty(options), options = struct(); end
if ~isfield(options,'make_plots'), options.make_plots = true; end
if ~isfield(options,'plot_horizon'), options.plot_horizon = 50; end
if ~isfolder(output_dir), mkdir(output_dir); end
table_dir = fullfile(output_dir,'paper_tables');
figure_dir = fullfile(output_dir,'paper_figures');
if ~isfolder(table_dir), mkdir(table_dir); end
if ~isfolder(figure_dir), mkdir(figure_dir); end
history = history_table(calibration_history);
if ismember('TargetTolerance',history.Properties.VariableNames)
    history = parameter_checks( ...
        history,history.TargetTolerance);
else
    history = parameter_checks(history,0.01);
end
rows = normalize_rows(rows);
rows = scenario_checks(rows,history);

registry = registry_table(scenario_registry,rows);
solver = record_table(rows,@solver_record);
gates = record_table(rows,@gate_record);
summary = record_table(rows,@summary_record);
averages = record_table(rows,@average_record);
external = record_table(rows,@external_record);
welfare = welfare_table(rows);
assert_solved_incomplete_welfare(rows);
long_run = long_run_table(rows);

paths = struct();
paths.scenario_registry = write_csv(output_dir,'scenario_registry.csv',registry);
paths.solver_status = write_csv(output_dir,'solver_status.csv',solver);
paths.calibration_history = write_csv(output_dir,'parameter_checks.csv',history);
paths.validation_gates = write_csv(output_dir,'validation_gates.csv',gates);
paths.summary_effects = write_csv(output_dir,'summary_effects.csv',summary);
paths.q1_40_averages = write_csv(output_dir,'q1_40_averages.csv',averages);
paths.external_timing = write_csv(output_dir,'external_timing.csv',external);
paths.welfare_by_group = write_csv(output_dir,'welfare_by_group.csv',welfare);
paths.long_run_effects = write_csv(output_dir,'long_run_effects.csv',long_run);

paths.robustness_summary_tex = fullfile(table_dir,'robustness_summary.tex');
write_robustness_tex(paths.robustness_summary_tex,gates);

plots = struct();
if logical(options.make_plots)
    clear_known_plot_outputs(figure_dir);
    try
        plots.fixed = plot_bargaining_comparison(figure_dir,rows, ...
            struct('comparison_type',"fixed_parameter", ...
            'file_stem',"bargaining_comparison_fixed", ...
            'horizon',options.plot_horizon,'visible',false));
    catch ME
        plots.fixed = unavailable_plot(format_plot_error(ME));
        plots.fixed.status = "error";
    end
    try
        plots.wage_moderation = plot_wage_moderation( ...
            figure_dir,rows,struct('file_stem', ...
            "ui_reform_vs_wage_moderation",'horizon',options.plot_horizon, ...
            'visible',false));
    catch ME
        plots.wage_moderation = unavailable_plot(format_plot_error(ME));
        plots.wage_moderation.status = "error";
    end
end

paths.plot_manifest = fullfile(output_dir,'plot_manifest.json');
manifest = struct('output_dir',string(output_dir),'paths',paths, ...
    'plots',plots,'scenario_count',numel(rows), ...
    'written_at',string(datetime('now','TimeZone','local', ...
    'Format','yyyy-MM-dd HH:mm:ss Z')));
write_json(paths.plot_manifest,manifest);
end


function rows = normalize_rows(rows)
if isempty(rows)
    rows = repmat(struct(),0,1);
elseif iscell(rows)
    rows = vertcat(rows{:});
elseif istable(rows)
    rows = table2struct(rows);
end
assert(isstruct(rows),'ReviewerSuite:OutputRows', ...
    'rows must be a struct array, cell array of structs, or table.');
rows = rows(:);
if ~isempty(rows) && isfield(rows,'result') && ~isfield(rows,'path_table')
    collected = cell(numel(rows),1);
    for i = 1:numel(rows)
        scenario = struct();
        if isfield(rows(i),'scenario') && isstruct(rows(i).scenario)
            scenario = rows(i).scenario;
        end
        collected{i} = collect_scenario_results(scenario,rows(i));
    end
    rows = vertcat(collected{:});
end
end


function t = registry_table(registry,rows)
if istable(registry)
    t = sanitize_table(registry);
elseif isstruct(registry) && ~isempty(registry)
    t = record_table(registry(:),@flat_registry_record);
elseif isempty(registry)
    t = record_table(rows,@registry_record);
else
    error('ReviewerSuite:RegistryType', ...
        'scenario_registry must be a table or struct array.');
end
if width(t) == 0
    t = empty_registry_table();
end
t = attach_selected_registry_values(t,rows);
end


function t = attach_selected_registry_values(t,rows)
count = height(t);
t.selected_parameter_name = strings(count,1);
t.selected_parameter_value = NaN(count,1);
t.selected_reform_cut = NaN(count,1);
t.selected_zeta_post_a = NaN(count,1);
t.selected_run_dir = strings(count,1);
t.selected_overall_status = strings(count,1);
if isempty(rows) || ~ismember('scenario_id',t.Properties.VariableNames)
    return
end
for i = 1:count
    index = find(strcmpi(string({rows.scenario_id}), ...
        string(t.scenario_id(i))),1);
    if isempty(index), continue; end
    row = rows(index);
    config = nested_struct(row,'configuration');
    registry = nested_struct(row,'registry');
    parameter = struct_text(registry,'calibration_parameter',"");
    t.selected_parameter_name(i) = parameter;
    result_available = strcmpi(row_text(row,'metric_status',"unavailable"), ...
        "available");
    if result_available
        if strcmp(parameter,"reform_cut")
            t.selected_parameter_value(i) = struct_number(config, ...
                'actual_reform_cut',struct_number(config,'reform_cut',NaN));
        elseif strcmp(parameter,"bargaining_power_post_a")
            t.selected_parameter_value(i) = struct_number(config,'zeta_post_a',NaN);
        elseif strlength(parameter) > 0 && isfield(config,char(parameter))
            t.selected_parameter_value(i) = ...
                struct_number(config,char(parameter),NaN);
        end
        t.selected_reform_cut(i) = struct_number(config,'actual_reform_cut', ...
            struct_number(config,'reform_cut',NaN));
        t.selected_zeta_post_a(i) = struct_number(config,'zeta_post_a', ...
            struct_number(config,'bargaining_power_post_a',NaN));
    end
    t.selected_run_dir(i) = row_text(row,'run_dir',"");
    t.selected_overall_status(i) = row_text(row,'status',"not_run");
end
end


function record = flat_registry_record(entry)
config = struct();
if isfield(entry,'config') && isstruct(entry.config)
    config = entry.config;
end
record = struct( ...
    'scenario_id',struct_text(entry,'scenario_id',"UNSPECIFIED"), ...
    'scenario_label',struct_text(entry,'scenario_label',""), ...
    'panel',struct_text(entry,'panel',""), ...
    'backend',struct_text(entry,'backend',struct_text(config,'backend',"")), ...
    'calibration_policy',struct_text(entry,'calibration_policy',"none"), ...
    'calibration_parameter',struct_text(entry,'calibration_parameter',""), ...
    'calibration_target',struct_text(entry,'calibration_target',""), ...
    'declared_changes',json_text(field_default(entry,'declared_changes',{})), ...
    'calibration_initial_value',struct_number(entry,'calibration_initial_value',NaN), ...
    'calibration_lower_bound',struct_number(entry,'calibration_lower_bound',NaN), ...
    'calibration_upper_bound',struct_number(entry,'calibration_upper_bound',NaN), ...
    'target_value',struct_number(entry,'target_value',NaN), ...
    'target_tolerance_pp',struct_number(entry,'target_tolerance_pp',NaN), ...
    'paper_facing',struct_logical(entry,'paper_facing',false), ...
    'bargaining_mode_a',struct_number(config,'bargaining_mode_a', ...
        struct_number(config,'bargaining_mode',NaN)), ...
    'bargaining_mode_b',struct_number(config,'bargaining_mode_b', ...
        struct_number(config,'bargaining_mode',NaN)), ...
    'bargaining_mode_name_a',struct_text(config,'bargaining_mode_name_a',""), ...
    'bargaining_mode_name_b',struct_text(config,'bargaining_mode_name_b',""), ...
    'zeta_pre_a',struct_number(config,'bargaining_power_pre_a', ...
        struct_number(config,'bargaining_power',NaN)), ...
    'zeta_post_a',struct_number(config,'bargaining_power_post_a', ...
        struct_number(config,'bargaining_power',NaN)), ...
    'zeta_pre_b',struct_number(config,'bargaining_power_pre_b', ...
        struct_number(config,'bargaining_power',NaN)), ...
    'zeta_post_b',struct_number(config,'bargaining_power_post_b', ...
        struct_number(config,'bargaining_power',NaN)), ...
    'reform_cut',struct_number(config,'reform_cut',NaN), ...
    'entitlement_cut_periods',struct_number(config,'entitlement_cut_periods',NaN), ...
    'apply_replacement_cut',struct_logical(config,'apply_replacement_cut',false), ...
    'apply_entitlement_cut',struct_logical(config,'apply_entitlement_cut',false), ...
    'separation_multiplier_a',struct_number(config,'separation_multiplier_a',NaN), ...
    'rrs_b',struct_number(config,'rrs_b',NaN), ...
    'rrl_b',struct_number(config,'rrl_b',NaN), ...
    'labor_tax_closure',struct_logical(config,'labor_tax_closure',false), ...
    'chi_T',struct_number(config,'sector_recruiting_congestion_T',NaN), ...
    'chi_N',struct_number(config,'sector_recruiting_congestion_N',NaN), ...
    'investment_adjustment_cost', ...
        struct_number(config,'investment_adjustment_cost',NaN), ...
    'hall_wage_persistence',struct_number(config,'hall_persistence_a',NaN), ...
    'alpha_I',struct_number(config,'alpha_I',NaN), ...
    'horizon',struct_number(config,'simulation_periods',NaN), ...
    'configuration_json',json_text(config));
end


function t = sanitize_table(t)
for column = 1:width(t)
    name = t.Properties.VariableNames{column};
    values = t.(name);
    if iscell(values)
        for row = 1:numel(values)
            value = values{row};
            if isstruct(value) || iscell(value)
                values{row} = jsonencode(value);
            elseif isstring(value)
                values{row} = char(value);
            end
        end
        t.(name) = values;
    elseif isstruct(values)
        encoded = strings(numel(values),1);
        for row = 1:numel(values)
            encoded(row) = json_text(values(row));
        end
        t.(name) = encoded;
    end
end
end


function t = record_table(rows,builder)
if isempty(rows)
    sample = builder(struct());
    t = struct2table(sample);
    t(1,:) = [];
    return
end
records = repmat(builder(rows(1)),numel(rows),1);
for i = 2:numel(rows)
    records(i) = builder(rows(i));
end
t = struct2table(records);
end


function record = registry_record(row)
record = base_record(row);
record.backend = config_text(row,'backend',"");
record.bargaining_mode_a = config_text(row,'bargaining_mode_a',"");
record.bargaining_mode_b = config_text(row,'bargaining_mode_b',"");
record.zeta_pre_a = config_number(row,'zeta_pre_a',NaN);
record.zeta_post_a = config_number(row,'zeta_post_a',NaN);
record.zeta_pre_b = config_number(row,'zeta_pre_b',NaN);
record.zeta_post_b = config_number(row,'zeta_post_b',NaN);
record.reform_cut = config_number(row,'reform_cut',NaN);
record.actual_reform_cut = config_number(row,'actual_reform_cut',NaN);
record.rrl_before = config_number(row,'rrl_before',NaN);
record.rrl_after = config_number(row,'rrl_after',NaN);
record.entitlement_cut_periods = ...
    config_number(row,'entitlement_cut_periods',NaN);
record.chi_T = config_number(row,'chi_T',NaN);
record.chi_N = config_number(row,'chi_N',NaN);
record.investment_adjustment_cost = ...
    config_number(row,'investment_adjustment_cost',NaN);
record.hall_wage_persistence = ...
    config_number(row,'hall_wage_persistence',NaN);
record.alpha_I = config_number(row,'alpha_I',NaN);
record.calibration_policy = config_text(row,'calibration_policy',"none");
record.horizon = config_number(row,'horizon',NaN);
record.run_dir = row_text(row,'run_dir',"");
end


function record = solver_record(row)
record = base_record(row);
solver = nested_struct(row,'solver');
record.steady_state_solved = struct_logical(solver,'steady_state_solved',false);
record.steady_state_status = struct_text(solver,'steady_state_status',"not_run");
record.transition_solved = struct_logical(solver,'transition_solved',false);
record.transition_status = struct_text(solver,'transition_status',"not_run");
record.max_static_residual = struct_number(solver,'max_static_residual',NaN);
record.static_jacobian_rank = struct_number(solver,'static_jacobian_rank',NaN);
record.static_jacobian_full_rank = ...
    struct_logical(solver,'static_jacobian_full_rank',false);
record.unstable_roots = struct_number(solver,'unstable_roots',NaN);
record.forward_variables = struct_number(solver,'forward_variables',NaN);
record.nonlinear_solver_attempt = ...
    struct_text(solver,'nonlinear_solver_attempt',"");
record.nonlinear_max_raw_residual = ...
    struct_number(solver,'nonlinear_max_raw_residual',NaN);
record.nonlinear_jacobian_condition = ...
    struct_number(solver,'nonlinear_jacobian_condition',NaN);
record.nonlinear_smallest_singular_value = ...
    struct_number(solver,'nonlinear_smallest_singular_value',NaN);
record.phase = struct_text(solver,'phase',"");
record.run_dir = row_text(row,'run_dir',"");
record.message = struct_text(solver,'message',row_text(row,'error_message',""));
end


function record = gate_record(row)
record = base_record(row);
solver = nested_struct(row,'solver');
record.steady_state_solved = struct_logical(solver,'steady_state_solved',false);
record.steady_state_status = struct_text(solver,'steady_state_status',"not_run");
record.transition_solved = struct_logical(solver,'transition_solved',false);
record.transition_status = struct_text(solver,'transition_status',"not_run");
gates = nested_struct(row,'gates');
record.accounting_pass = struct_logical(gates,'accounting_pass',false);
record.accounting_status = struct_text(gates,'accounting_status',"not_run");
record.accounting_max_residual = ...
    struct_number(gates,'accounting_max_residual',NaN);
record.bargaining_identity_pass = ...
    struct_logical(gates,'bargaining_identity_pass',false);
record.bargaining_identity_status = ...
    struct_text(gates,'bargaining_identity_status',"not_run");
record.bargaining_identity_max_residual = ...
    struct_number(gates,'bargaining_identity_max_residual',NaN);
record.target_pass = struct_logical(gates,'target_pass',false);
record.target_status = struct_text(gates,'target_status',"not_run");
record.target_metric = struct_text(gates,'target_metric',"not_applicable");
record.target_role = struct_text(gates,'target_role',"not_applicable");
record.target_applicable = struct_logical(gates,'target_applicable',false);
record.target_value_pct = struct_number(gates,'target_value_pct',NaN);
record.target_response_pct = struct_number(gates,'target_response_pct',NaN);
record.target_gap_pct = struct_number(gates,'target_gap_pct',NaN);
record.target_tolerance_pct = ...
    struct_number(gates,'target_tolerance_pct',NaN);
record.horizon_pass = struct_logical(gates,'horizon_pass',false);
record.horizon_status = struct_text(gates,'horizon_status',"not_run");
record.horizon_max_gap = struct_number(gates,'horizon_max_gap',NaN);
record.horizon_applicable = ...
    struct_logical(gates,'horizon_applicable',true);
record.economic_validation_pass = ...
    struct_logical(gates,'economic_validation_pass',false);
record.economic_validation_status = ...
    struct_text(gates,'economic_validation_status',"not_run");
record.economic_profile = ...
    struct_text(gates,'economic_profile',"not_applicable");
record.economic_validation_role = ...
    struct_text(gates,'economic_validation_role',"not_applicable");
record.economic_validation_applicable = ...
    struct_logical(gates,'economic_validation_applicable',false);
record.depreciation_pass = struct_logical(gates,'depreciation_pass',false);
record.export_q5_40_avg_pct = ...
    struct_number(gates,'export_q5_40_avg_pct',NaN);
record.export_increase_pass = struct_logical(gates,'export_increase_pass',false);
record.nx_increase_pass = struct_logical(gates,'nx_increase_pass',false);
record.ca_surplus_pass = struct_logical(gates,'ca_surplus_pass',false);
record.positive_nfa_accumulation_pass = ...
    struct_logical(gates,'positive_nfa_accumulation_pass',false);
record.positivity_pass = struct_logical(gates,'positivity_pass',false);
end


function record = summary_record(row)
record = registry_record(row);
record.overall_status = row_text(row,'status',"not_run");
record.metric_status = row_text(row,'metric_status',"unavailable");
record.metric_message = row_text(row,'metric_message',"");
record.error_message = row_text(row,'error_message',"");
record.source_validation_message = ...
    row_text(row,'source_validation_message',"");
summary = nested_struct(row,'summary');
names = fieldnames(summary_template());
for i = 1:numel(names)
    record.(names{i}) = struct_number(summary,names{i},NaN);
end
averages = nested_struct(row,'averages');
record.wage_q1_40_avg_pct = struct_number(averages,'wage_pct',NaN);
record.tradable_employment_q1_40_avg_pct = ...
    struct_number(averages,'tradable_employment_pct',NaN);
record.nontradable_employment_q1_40_avg_pct = ...
    struct_number(averages,'nontradable_employment_pct',NaN);
record.relative_tn_employment_q1_40_avg_pct = ...
    struct_number(averages,'relative_tn_employment_pct',NaN);
external = nested_struct(row,'external');
record.ca_impact_pct_annual_output = ...
    struct_number(external,'ca_impact_pct_annual_output',NaN);
record.nfa_q40_pct_annual_output = ...
    struct_number(external,'nfa_q40_pct_annual_output',NaN);
gates = nested_struct(row,'gates');
record.accounting_pass = struct_logical(gates,'accounting_pass',false);
record.bargaining_identity_pass = ...
    struct_logical(gates,'bargaining_identity_pass',false);
record.target_pass = struct_logical(gates,'target_pass',false);
record.target_status = struct_text(gates,'target_status',"not_run");
record.target_metric = struct_text(gates,'target_metric',"not_applicable");
record.target_role = struct_text(gates,'target_role',"not_applicable");
record.target_applicable = struct_logical(gates,'target_applicable',false);
record.target_value_pct = struct_number(gates,'target_value_pct',NaN);
record.target_response_pct = struct_number(gates,'target_response_pct',NaN);
record.target_gap_pct = struct_number(gates,'target_gap_pct',NaN);
record.horizon_pass = struct_logical(gates,'horizon_pass',false);
record.horizon_status = struct_text(gates,'horizon_status',"not_run");
record.horizon_applicable = ...
    struct_logical(gates,'horizon_applicable',true);
record.economic_validation_pass = ...
    struct_logical(gates,'economic_validation_pass',false);
record.economic_validation_status = ...
    struct_text(gates,'economic_validation_status',"not_run");
record.economic_profile = ...
    struct_text(gates,'economic_profile',"not_applicable");
record.economic_validation_applicable = ...
    struct_logical(gates,'economic_validation_applicable',false);
end


function record = average_record(row)
record = base_record(row);
record.bargaining_mode_label = ...
    config_text(row,'bargaining_mode_label',"");
averages = nested_struct(row,'averages');
template = average_template();
names = fieldnames(template);
for i = 1:numel(names)
    record.(names{i}) = struct_number(averages,names{i},NaN);
end
end


function record = external_record(row)
record = base_record(row);
record.bargaining_mode_label = ...
    config_text(row,'bargaining_mode_label',"");
external = nested_struct(row,'external');
template = external_template();
names = fieldnames(template);
for i = 1:numel(names)
    record.(names{i}) = struct_number(external,names{i},NaN);
end
record.metric_status = row_text(row,'metric_status',"unavailable");
end


function record = base_record(row)
record = struct('scenario_id',row_text(row,'scenario_id',"UNSPECIFIED"), ...
    'scenario_label',row_text(row,'scenario_label',""), ...
    'scenario_group',row_text(row,'scenario_group',"Unclassified"), ...
    'comparison_type',row_text(row,'comparison_type',"none"));
end


function welfare = welfare_table(rows)
welfare = empty_welfare_table();
for i = 1:numel(rows)
    if isfield(rows(i),'welfare') && istable(rows(i).welfare)
        block = rows(i).welfare;
    else
        [block,~] = calculate_welfare( ...
            row_text(rows(i),'scenario_id',"UNSPECIFIED"), ...
            char(row_text(rows(i),'run_dir',"")));
    end
    welfare = [welfare;block]; %#ok<AGROW>
end
end


function assert_solved_incomplete_welfare(rows)
% Every solved incomplete-markets transition must have the full welfare grid.
expected_groups = ["Aggregate";"Employed";"EU1";"EU2";"EU3"; ...
    "EU4";"EU5";"EU6";"EU7";"EU8";"LTU"];
for i = 1:numel(rows)
    solver = nested_struct(rows(i),'solver');
    transition_solved = struct_logical(solver,'transition_solved',false);
    backend = lower(config_text(rows(i),'backend',"incomplete"));
    if ~transition_solved || backend == "complete"
        continue
    end
    scenario_id = row_text(rows(i),'scenario_id',"UNSPECIFIED");
    assert(isfield(rows(i),'welfare') && istable(rows(i).welfare), ...
        'ReviewerSuite:MissingSolvedWelfare', ...
        'Solved incomplete-markets scenario %s has no welfare table.', ...
        scenario_id);
    block = rows(i).welfare;
    required = {'Country','Group','CEVPct','Available'};
    assert(all(ismember(required,block.Properties.VariableNames)), ...
        'ReviewerSuite:MalformedSolvedWelfare', ...
        'Solved incomplete-markets scenario %s has a malformed welfare table.', ...
        scenario_id);
    assert(height(block) == 22 && all(logical(block.Available)) ...
            && all(isfinite(block.CEVPct)), ...
        'ReviewerSuite:IncompleteSolvedWelfare', ...
        ['Solved incomplete-markets scenario %s must have exactly 22 ' ...
         'available finite welfare rows.'],scenario_id);
    countries = string(block.Country);
    groups = string(block.Group);
    assert(sum(countries == "Home") == 11 ...
            && sum(countries == "Foreign") == 11 ...
            && isequal(sort(groups(countries == "Home")),sort(expected_groups)) ...
            && isequal(sort(groups(countries == "Foreign")),sort(expected_groups)), ...
        'ReviewerSuite:IncompleteSolvedWelfareGrid', ...
        ['Solved incomplete-markets scenario %s does not contain the ' ...
         'required Home and Foreign welfare groups.'],scenario_id);
end
end


function long_run = long_run_table(rows)
long_run = empty_long_run_table();
for i = 1:numel(rows)
    if isfield(rows(i),'long_run') && istable(rows(i).long_run)
        long_run = [long_run;rows(i).long_run]; %#ok<AGROW>
    end
end
long_run.Definition = repmat( ...
    "Quarter-160 (40-Year) finite-horizon snapshot when HorizonQuarter " + ...
    "equals 160; not an asymptotic steady-state effect.",height(long_run),1);
end


function history = history_table(input)
if istable(input)
    history = sanitize_table(input);
elseif isstruct(input) && ~isempty(input)
    history = sanitize_table(struct2table(input(:)));
elseif isempty(input)
    history = table(strings(0,1),zeros(0,1),strings(0,1),zeros(0,1), ...
        strings(0,1),zeros(0,1),zeros(0,1),zeros(0,1),false(0,1), ...
        false(0,1),strings(0,1),strings(0,1),strings(0,1),strings(0,1), ...
        'VariableNames',{'scenario_id','evaluation','parameter_name', ...
        'parameter_value','target_name','target_value','target_response', ...
        'target_gap','feasible','solved','run_dir','checkpoint_path', ...
        'status','message'});
else
    error('ReviewerSuite:HistoryType', ...
        'calibration_history must be a table or struct array.');
end
end


function filtered = filter_comparison(summary,kind)
if isempty(summary)
    filtered = summary;
    return
end
comparison = lower(string(summary.comparison_type));
kind = lower(string(kind));
ids = lower(string(summary.scenario_id));
if contains(kind,"auxiliary") && contains(kind,"target")
    requested = ["stu1_rr_retarget_zeta0525_aux"; ...
        "all_unemployed_rr_retarget_zeta0525_aux"; ...
        "labor_force_weighted_rr_retarget_zeta0525_aux"];
elseif contains(kind,"auxiliary")
    requested = ["stu1_fixed_zeta0525_aux"; ...
        "all_unemployed_fixed_zeta0525_aux"; ...
        "labor_force_weighted_fixed_zeta0525_aux"];
elseif contains(kind,"target")
    requested = ["stu1_rr_retarget";"all_unemployed_rr_retarget"; ...
        "labor_force_weighted_rr_retarget"];
else
    requested = ["stu1_fixed";"all_unemployed_fixed"; ...
        "labor_force_weighted_fixed"];
end
mask = ismember(ids,requested) & strlength(comparison) > 0;
filtered = summary(mask,:);
end


function path = write_csv(output_dir,name,t)
path = fullfile(output_dir,name);
writetable(t,path);
end


function write_comparison_tex(path,t,caption)
fid = fopen(path,'w');
assert(fid >= 0,'ReviewerSuite:TeXOpen','Could not open %s.',path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
line(fid,'\begin{table}[!htbp]');
line(fid,'\centering');
fprintf(fid,'\\caption{%s}\n',tex_escape(caption));
[~,stem] = fileparts(path);
fprintf(fid,'\\label{tab:%s}\n',strrep(stem,'_','-'));
line(fid,'\resizebox{\textwidth}{!}{%');
line(fid,'\begin{tabular}{lrrrrrrrrrccc}');
line(fid,'\toprule');
line(fid,['Specification & $\zeta$ & $\chi_N$ & RR Cut (\%) & ' ...
    'Post-Reform $rr^l$ & Entitlement Cut & Wage Q1--40 & T Employment & ' ...
    'N Employment & Relative T/N & Calibration Target & Horizon & UI Profile \\']);
line(fid,'\midrule');
if height(t) == 0
    line(fid,'No eligible scenarios & -- & -- & -- & -- & -- & -- & -- & -- & -- & -- & -- & -- \\');
else
    for i = 1:height(t)
        id = lower(table_text(t,i,'scenario_id',''));
        unavailable_retarget = contains(id,"_rr_retarget") ...
            && ~strcmpi(table_text(t,i,'metric_status','unavailable'),"available");
        cut_value = 100*table_number(t,i,'actual_reform_cut');
        post_rr_value = table_number(t,i,'rrl_after');
        if unavailable_retarget
            cut_value = NaN;
            post_rr_value = NaN;
        end
        fprintf(fid,['%s & %s & %s & %s & %s & %s & %s & ' ...
            '%s & %s & %s & %s & %s & %s \\\\\n'], ...
            tex_escape(table_text(t,i,'scenario_label','')), ...
            number_tex(table_number(t,i,'zeta_pre_a'),3), ...
            number_tex(table_number(t,i,'chi_N'),3), ...
            number_tex(cut_value,3),number_tex(post_rr_value,3), ...
            number_tex(table_number(t,i,'entitlement_cut_periods'),0), ...
            number_tex(table_number(t,i,'wage_q1_40_avg_pct'),3), ...
            number_tex(table_number(t,i,'tradable_employment_q1_40_avg_pct'),3), ...
            number_tex(table_number(t,i,'nontradable_employment_q1_40_avg_pct'),3), ...
            number_tex(table_number(t,i,'relative_tn_employment_q1_40_avg_pct'),3), ...
            status_tex(table_text(t,i,'target_status','not_run')), ...
            status_tex(table_text(t,i,'horizon_status','not_run')), ...
            status_tex(table_text(t,i,'economic_validation_status','not_run')));
    end
end
line(fid,'\bottomrule');
line(fid,'\end{tabular}%');
line(fid,'}');
line(fid,['\begin{minipage}{0.98\textwidth}\footnotesize ' ...
    '\textit{Notes:} Fixed-policy rows have no calibration target and therefore ' ...
    'show N/A in that column. The UI profile is a reported diagnostic, not a ' ...
    'numerical-solution gate. A dash in an unavailable retargeted row means ' ...
    'that no policy cut was selected. Missing values are unavailable and ' ...
    'are not imputed.\end{minipage}']);
line(fid,'\end{table}');
end


function write_robustness_tex(path,gates)
fid = fopen(path,'w');
assert(fid >= 0,'ReviewerSuite:TeXOpen','Could not open %s.',path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
line(fid,'\begin{table}[!htbp]');
line(fid,'\centering');
line(fid,'\caption{Reviewer Robustness Suite Status}');
line(fid,'\label{tab:reviewer-robustness-suite-status}');
line(fid,'\begin{tabular}{lccccccc}');
line(fid,'\toprule');
line(fid,['Scenario & Steady State & Transition & Accounting & Bargaining & ' ...
    'Target & Horizon & Reported Profile \\']);
line(fid,'\midrule');
if height(gates) == 0
    line(fid,'No scenarios registered & -- & -- & -- & -- & -- & -- & -- \\');
else
    for i = 1:height(gates)
        fprintf(fid,'%s & %s & %s & %s & %s & %s & %s & %s \\\\\n', ...
            tex_escape(table_text(gates,i,'scenario_label','')), ...
            status_tex(table_text(gates,i,'steady_state_status','not_run')), ...
            status_tex(table_text(gates,i,'transition_status','not_run')), ...
            status_tex(table_text(gates,i,'accounting_status','not_run')), ...
            status_tex(table_text(gates,i,'bargaining_identity_status','not_run')), ...
            status_tex(table_text(gates,i,'target_status','not_run')), ...
            status_tex(table_text(gates,i,'horizon_status','not_run')), ...
            status_tex(table_text(gates,i,'economic_validation_status','not_run')));
    end
end
line(fid,'\bottomrule');
line(fid,'\end{tabular}');
line(fid,'\end{table}');
end


function value = table_number(t,row,name)
index = find(strcmpi(t.Properties.VariableNames,name),1);
if isempty(index)
    value = NaN;
else
    raw = t{row,index};
    if isnumeric(raw) || islogical(raw)
        value = double(raw(1));
    else
        value = str2double(string(raw(1)));
    end
end
end


function value = table_logical(t,row,name)
number = table_number(t,row,name);
value = isfinite(number) && logical(number);
end


function value = table_text(t,row,name,default)
index = find(strcmpi(t.Properties.VariableNames,name),1);
if isempty(index)
    value = string(default);
else
    value = string(t{row,index});
    value = value(1);
end
end


function text = status_tex(status)
status = lower(string(status));
if status == "pass"
    text = 'Pass';
elseif status == "fail"
    text = 'Fail';
elseif status == "not_applicable"
    text = 'N/A';
elseif status == "not_run"
    text = 'Not Run';
elseif status == "backend_blocked"
    text = 'Backend Unavailable';
elseif status == "intrinsic_prestate_failure"
    text = 'Pre-State Failure';
else
    text = '--';
end
end


function text = number_tex(value,digits)
if isfinite(value)
    text = sprintf(['%0.' num2str(digits) 'f'],value);
else
    text = '\textemdash{}';
end
end


function text = yes_no(flag)
if flag, text = 'Yes'; else, text = 'No'; end
end


function line(fid,text)
fprintf(fid,'%s\n',text);
end


function value = tex_escape(value)
value = char(string(value));
value = strrep(value,'\','\textbackslash{}');
value = strrep(value,'&','\&');
value = strrep(value,'%','\%');
value = strrep(value,'_','\_');
value = strrep(value,'#','\#');
end


function record = summary_template()
record = struct('wage_q1_pct',NaN,'wage_q4_pct',NaN, ...
    'wage_q12_pct',NaN,'wage_q40_pct',NaN, ...
    'wage_trough_q1_40_pct',NaN,'wage_trough_quarter',NaN, ...
    'employment_q1_pct',NaN,'unemployment_q1_pp',NaN, ...
    'job_finding_q1_pct',NaN,'vacancies_q1_pct',NaN, ...
    'tradable_employment_q1_pct',NaN, ...
    'nontradable_employment_q1_pct',NaN, ...
    'relative_tn_employment_q1_pct',NaN, ...
    'household_cash_saving_q1_pp',NaN,'national_saving_q1_pp',NaN, ...
    'consumption_q1_pct',NaN,'investment_q1_pct',NaN, ...
    'exports_q1_pct',NaN,'imports_q1_pct',NaN,'rer_q1_pct',NaN, ...
    'terms_of_trade_q1_pct',NaN);
end


function record = average_template()
record = struct('wage_pct',NaN,'employment_pct',NaN, ...
    'unemployment_pp',NaN,'job_finding_pct',NaN,'vacancies_pct',NaN, ...
    'tradable_employment_pct',NaN,'nontradable_employment_pct',NaN, ...
    'relative_tn_employment_pct',NaN,'household_cash_saving_pp',NaN, ...
    'national_saving_pp',NaN,'consumption_pct',NaN, ...
    'investment_pct',NaN,'exports_pct',NaN,'imports_pct',NaN, ...
    'nx_pct_annual_output',NaN,'ca_pct_annual_output',NaN, ...
    'rer_pct',NaN,'terms_of_trade_pct',NaN,'export_volume_pct',NaN);
end


function record = external_template()
record = struct('ca_impact_pct_annual_output',NaN, ...
    'ca_first_positive_quarter',NaN, ...
    'ca_cumulative_q1_40_pct_annual_output',NaN, ...
    'nfa_minimum_pct_annual_output',NaN,'nfa_minimum_quarter',NaN, ...
    'nfa_first_positive_quarter',NaN,'nfa_q40_pct_annual_output',NaN, ...
    'household_saving_impact_pct_annual_output',NaN, ...
    'corporate_saving_impact_pct_annual_output',NaN, ...
    'government_saving_impact_pct_annual_output',NaN, ...
    'national_saving_impact_pct_annual_output',NaN, ...
    'investment_impact_pct_annual_output',NaN, ...
    'nx_impact_pct_annual_output',NaN, ...
    'net_interest_impact_pct_annual_output',NaN, ...
    'valuation_residual_impact_pct_annual_output',NaN);
end


function t = empty_registry_table()
t = record_table(repmat(struct(),0,1),@registry_record);
end


function t = empty_welfare_table()
t = table(strings(0,1),strings(0,1),strings(0,1),zeros(0,1), ...
    false(0,1),strings(0,1),strings(0,1),strings(0,1), ...
    'VariableNames',{'ScenarioID','Country','Group','CEVPct', ...
    'Available','Status','Message','Method'});
end


function t = empty_long_run_table()
t = table(strings(0,1),strings(0,1),zeros(0,1),strings(0,1), ...
    zeros(0,1),strings(0,1),false(0,1),strings(0,1),strings(0,1), ...
    'VariableNames',{'ScenarioID','Country','HorizonQuarter','Metric', ...
    'Value','Unit','Available','Status','Message'});
end


function plot = unavailable_plot(message)
plot = struct('available',false,'status',"unavailable", ...
    'message',string(message),'png',"",'pdf',"",'fig',"");
end


function value = nested_struct(row,name)
value = struct();
if isstruct(row) && isfield(row,name) && isstruct(row.(name))
    value = row.(name);
end
end


function value = field_default(source,name,default)
value = default;
if isstruct(source) && isfield(source,name)
    value = source.(name);
end
end


function text = json_text(value)
try
    text = string(jsonencode(value));
catch
    text = "";
end
end


function value = row_text(row,name,default)
value = string(default);
if isstruct(row) && isfield(row,name) && ~isempty(row.(name))
    candidate = string(row.(name));
    if isscalar(candidate), value = candidate; end
end
end


function value = config_text(row,name,default)
value = struct_text(nested_struct(row,'configuration'),name,default);
end


function value = config_number(row,name,default)
value = struct_number(nested_struct(row,'configuration'),name,default);
end


function value = struct_text(source,name,default)
value = string(default);
if isstruct(source) && isfield(source,name) && ~isempty(source.(name))
    candidate = string(source.(name));
    if isscalar(candidate), value = candidate; end
end
end


function value = struct_number(source,name,default)
value = default;
if isstruct(source) && isfield(source,name) && isnumeric(source.(name)) ...
        && isscalar(source.(name)) && ~isempty(source.(name))
    value = double(source.(name));
end
end


function value = struct_logical(source,name,default)
value = default;
if isstruct(source) && isfield(source,name) && ~isempty(source.(name))
    candidate = source.(name);
    if (islogical(candidate) || isnumeric(candidate)) && isscalar(candidate) ...
            && isfinite(double(candidate))
        value = logical(candidate);
    end
end
end


function text = one_line(text)
text = regexprep(char(text),'[\r\n\t]+',' ');
text = regexprep(text,'\s+',' ');
text = strtrim(text);
end


function clear_known_plot_outputs(figure_dir)
stems = {'bargaining_comparison_fixed', ...
    'bargaining_comparison_targeted', ...
    'bargaining_comparison_zeta0525_auxiliary_fixed', ...
    'bargaining_comparison_zeta0525_auxiliary_targeted', ...
    'ui_reform_vs_wage_moderation'};
extensions = {'.png','.pdf','.eps','.fig'};
for i = 1:numel(stems)
    for j = 1:numel(extensions)
        path = fullfile(figure_dir,[stems{i} extensions{j}]);
        if exist(path,'file') == 2
            delete(path);
        end
    end
end
end


function message = format_plot_error(exception)
identifier = string(exception.identifier);
if strlength(identifier) == 0
    identifier = "MATLAB:UnknownPlotError";
end
message = identifier+": "+string(one_line(exception.message));
end


function write_json(path,value)
fid = fopen(path,'w');
assert(fid >= 0,'ReviewerSuite:JSONOpen','Could not open %s.',path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
