function row = collect_scenario_results(scenario, result, options)
%COLLECT_SCENARIO_RESULTS Normalize one reviewer-suite scenario result.
%
% row = collect_scenario_results(scenario, result)
% row = collect_scenario_results(scenario, result, options)
%
% The collector deliberately keeps numerical solution, accounting, target,
% horizon, and economic-validation evidence separate.  A failed or partial
% result is returned as a complete schema with explicit status strings and
% NaN metrics rather than being dropped or treated as a successful run.

if nargin < 1 || isempty(scenario)
    scenario = struct();
end
if nargin < 2 || isempty(result)
    result = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end
if istable(scenario)
    assert(height(scenario) == 1, 'ReviewerSuite:ScenarioRow', ...
        'scenario must be a scalar struct or one table row.');
    scenario = table2struct(scenario);
end
assert(isstruct(scenario) && isscalar(scenario), ...
    'ReviewerSuite:ScenarioType', 'scenario must be a scalar struct.');
assert(isstruct(result) && isscalar(result), ...
    'ReviewerSuite:ResultType', 'result must be a scalar struct.');

% Accept either run_baseline's result directly or run_scenario's outcome.
if isfield(result,'result') && isstruct(result.result) ...
        && isscalar(result.result)
    outcome = result;
    result = outcome.result;
    if ~isfield(result,'configuration') && isfield(outcome,'configuration')
        result.configuration = outcome.configuration;
    end
    if isfield(outcome,'status') && isstruct(outcome.status)
        status_names = {'steady_state_solved','transition_solved', ...
            'accounting_pass','bargaining_identity_pass','target_pass', ...
            'horizon_pass','economic_validation_pass'};
        for status_index = 1:numel(status_names)
            name = status_names{status_index};
            if ~isfield(result,name) && isfield(outcome.status,name)
                result.(name) = outcome.status.(name);
            end
        end
    end
end

options = option_defaults(options);
configuration = struct();
if isfield(result, 'configuration') && isstruct(result.configuration)
    configuration = result.configuration;
end
sources = {scenario, configuration, result};

row = struct();
row.scenario_id = pick_text(sources, ...
    {'scenario_id','ScenarioID','id'}, "UNSPECIFIED");
row.scenario_label = pick_text(sources, ...
    {'scenario_label','label','ScenarioLabel','name'}, row.scenario_id);
row.scenario_group = pick_text(sources, ...
    {'scenario_group','group','section','panel'}, "Unclassified");
row.comparison_type = pick_text(sources, ...
    {'comparison_type','comparison_panel','panel'}, "none");
row.run_dir = pick_text({result, scenario}, {'run_dir','RunDir'}, "");
row.error_message = collect_error_message(result);
row.registry = scenario;
row.configuration = collect_configuration(sources, row.run_dir);

row.path_table = empty_path_table();
row.summary = empty_summary();
row.averages = empty_averages();
row.external = empty_external();
row.long_run = empty_long_run();
row.metric_status = "unavailable";
row.metric_message = "Transition files are unavailable.";

if strlength(row.run_dir) > 0 && transition_files_exist(row.run_dir)
    try
        [row.path_table, row.summary, row.averages, row.external, ...
            row.long_run] = collect_transition_metrics( ...
            row.scenario_id, char(row.run_dir), options);
        row.metric_status = "available";
        row.metric_message = "";
    catch ME
        row.metric_status = "error";
        row.metric_message = string(one_line(ME.message));
    end
end

[row.welfare, row.welfare_status] = calculate_welfare( ...
    row.scenario_id, char(row.run_dir), struct('long_run_quarter', ...
    options.long_run_quarter,'configuration',configuration));

row.solver = collect_solver_status(result, row.run_dir);
row.gates = collect_gate_status(result, row, options);
row.status = overall_status(row);
row = scenario_checks(row,options.calibration_history);
end


function options = option_defaults(options)
defaults = struct('target_value_pct',2.7,'target_tolerance_pct',0.01, ...
    'accounting_tolerance',1e-10,'bargaining_tolerance',1e-10, ...
    'horizon_tolerance',1e-6,'long_run_quarter',160, ...
    'calibration_history',table());
names = fieldnames(defaults);
for i = 1:numel(names)
    if ~isfield(options,names{i}) || isempty(options.(names{i}))
        options.(names{i}) = defaults.(names{i});
    end
end
end


function config = collect_configuration(sources, run_dir)
config = struct();
config.backend = pick_text(sources, {'backend'}, "incomplete");
config.bargaining_mode_a = pick_text(sources, ...
    {'a_bargaining_mode','bargaining_mode_a','bargaining_mode'}, "");
config.bargaining_mode_b = pick_text(sources, ...
    {'b_bargaining_mode','bargaining_mode_b','bargaining_mode'}, "");
config.bargaining_mode_label = pick_text(sources, ...
    {'bargaining_mode_label','bargaining_mode_name_a', ...
     'mode_label','outside_option_label'}, "");
if strlength(config.bargaining_mode_label) == 0
    config.bargaining_mode_label = mode_label(config.bargaining_mode_a);
end
config.zeta_pre_a = pick_number(sources, ...
    {'zeta_pre_a','bargaining_power_pre_a','bargaining_power'}, NaN);
config.zeta_post_a = pick_number(sources, ...
    {'zeta_post_a','bargaining_power_post_a','bargaining_power'}, ...
    config.zeta_pre_a);
config.zeta_pre_b = pick_number(sources, ...
    {'zeta_pre_b','bargaining_power_pre_b','bargaining_power'}, NaN);
config.zeta_post_b = pick_number(sources, ...
    {'zeta_post_b','bargaining_power_post_b','bargaining_power'}, ...
    config.zeta_pre_b);
config.reform_cut = pick_number(sources, ...
    {'reform_cut','requested_reform_cut'}, NaN);
config.actual_reform_cut = pick_number(sources, ...
    {'actual_reform_cut'}, config.reform_cut);
config.rrl_before = pick_number(sources, {'rrl_before','rrl_a'}, NaN);
config.rrl_after = pick_number(sources, {'rrl_after'}, NaN);
if ~isfinite(config.rrl_after) && isfinite(config.rrl_before) ...
        && isfinite(config.actual_reform_cut)
    config.rrl_after = config.rrl_before*(1-config.actual_reform_cut);
end
config.entitlement_cut_periods = pick_number(sources, ...
    {'entitlement_cut_periods'}, NaN);
config.chi_T = pick_number(sources, ...
    {'chi_T','sector_recruiting_congestion_T'}, NaN);
config.chi_N = pick_number(sources, ...
    {'chi_N','sector_recruiting_congestion_N'}, NaN);
config.investment_adjustment_cost = pick_number(sources, ...
    {'investment_adjustment_cost','iac'}, NaN);
config.hall_wage_persistence = pick_number(sources, ...
    {'hall_wage_persistence','hall_persistence_a'}, NaN);
config.alpha_I = pick_number(sources, {'alpha_I'}, NaN);
config.calibration_policy = pick_text(sources, ...
    {'calibration_policy'}, "none");
config.horizon = pick_number(sources, ...
    {'horizon','simulation_periods'}, NaN);
config.run_dir = string(run_dir);
end


function solver = collect_solver_status(result, run_dir)
solver = struct('steady_state_solved',false, ...
    'steady_state_status',"not_run",'transition_solved',false, ...
    'transition_status',"not_run",'max_static_residual',NaN, ...
    'static_jacobian_rank',NaN,'static_jacobian_full_rank',false, ...
    'unstable_roots',NaN,'forward_variables',NaN,'phase',"", ...
    'message',"",'nonlinear_solver_attempt',"", ...
    'nonlinear_max_raw_residual',NaN, ...
    'nonlinear_jacobian_condition',NaN, ...
    'nonlinear_smallest_singular_value',NaN);
solver.phase = string(field_or(result,'phase',''));
solver.message = string(collect_error_message(result));

[explicit_steady, has_explicit_steady] = logical_field(result, ...
    {'steady_state_solved'});
gate0 = struct();
if isfield(result,'gate0') && isstruct(result.gate0)
    gate0 = result.gate0;
end
solver.max_static_residual = number_field(gate0, ...
    {'max_static_residual'},NaN);
solver.static_jacobian_rank = number_field(gate0, ...
    {'static_jacobian_rank'},NaN);
solver.static_jacobian_full_rank = logical_value( ...
    field_or(gate0,'static_jacobian_full_rank',false),false);
solver.unstable_roots = number_field(gate0, {'unstable_roots'},NaN);
solver.forward_variables = number_field(gate0, {'forward_variables'},NaN);
anchor = struct();
if isfield(result,'anchor') && isstruct(result.anchor)
    anchor = result.anchor;
end
solver.nonlinear_solver_attempt = struct_text(anchor,'solver_attempt',"");
solver.nonlinear_max_raw_residual = ...
    number_field(anchor,{'maximum_raw_residual'},NaN);
solver.nonlinear_jacobian_condition = ...
    number_field(anchor,{'jacobian_condition'},NaN);
solver.nonlinear_smallest_singular_value = ...
    number_field(anchor,{'smallest_singular_value'},NaN);

steady_files = strlength(run_dir) > 0 ...
    && exist(fullfile(char(run_dir),'SS_init.mat'),'file') == 2 ...
    && (exist(fullfile(char(run_dir),'SS_H42_EB.mat'),'file') == 2 ...
        || strcmpi(char(solver.phase),'steady_state_only'));
if has_explicit_steady
    solver.steady_state_solved = explicit_steady;
elseif isfield(gate0,'pass')
    solver.steady_state_solved = logical_value(gate0.pass,false) && steady_files;
else
    solver.steady_state_solved = steady_files;
end
solver.steady_state_status = pass_status(solver.steady_state_solved, ...
    has_explicit_steady || steady_files || isfield(gate0,'pass'));

[explicit_transition, has_explicit_transition] = logical_field(result, ...
    {'transition_solved'});
transition_evidence = transition_files_exist(run_dir);
if has_explicit_transition
    solver.transition_solved = explicit_transition;
elseif isfield(result,'transition_status')
    solver.transition_solved = logical_value(result.transition_status,false) ...
        && transition_evidence;
else
    solver.transition_solved = transition_evidence;
end
solver.transition_status = pass_status(solver.transition_solved, ...
    has_explicit_transition || transition_evidence ...
    || isfield(result,'transition_status'));
end


function gates = collect_gate_status(result, row, options)
gates = struct('accounting_pass',false,'accounting_status',"not_run", ...
    'accounting_max_residual',NaN,'bargaining_identity_pass',false, ...
    'bargaining_identity_status',"not_run", ...
    'bargaining_identity_max_residual',NaN,'target_pass',false, ...
    'target_status',"not_run",'target_value_pct',options.target_value_pct, ...
    'target_response_pct',row.averages.relative_tn_employment_pct, ...
    'target_gap_pct',NaN,'horizon_pass',false, ...
    'horizon_status',"not_run",'horizon_max_gap',NaN, ...
    'economic_validation_pass',false, ...
    'economic_validation_status',"not_run", ...
    'depreciation_pass',false,'export_q5_40_avg_pct',NaN, ...
    'export_increase_pass',false, ...
    'nx_increase_pass',false,'ca_surplus_pass',false, ...
    'positive_nfa_accumulation_pass',false,'positivity_pass',false);

diagnostics = struct();
if isfield(result,'diagnostics') && isstruct(result.diagnostics)
    diagnostics = result.diagnostics;
end

[accounting_explicit, accounting_known] = logical_field(result, ...
    {'accounting_pass'});
accounting = struct();
if isfield(diagnostics,'accounting') && isstruct(diagnostics.accounting)
    accounting = diagnostics.accounting;
end
if ~isempty(fieldnames(accounting))
    identity_pass = logical_value(field_or(accounting,'identity_pass',false),false);
    exact_pass = logical_value(field_or(accounting,'exact_gate_pass',false),false);
    accounting_explicit = accounting_explicit && identity_pass && exact_pass;
    if ~accounting_known
        accounting_explicit = identity_pass && exact_pass;
    end
    accounting_known = isfield(accounting,'identity_pass') ...
        || isfield(accounting,'exact_gate_pass');
end
if ~row.solver.transition_solved && isempty(fieldnames(accounting))
    accounting_known = false;
    accounting_explicit = false;
end
gates.accounting_pass = accounting_explicit;
gates.accounting_status = pass_status(accounting_explicit,accounting_known);
gates.accounting_max_residual = max_finite([ ...
    number_field(accounting,{'max_identity_residual'},NaN), ...
    number_field(accounting,{'max_augmented_resource_residual'},NaN), ...
    number_field(accounting,{'max_raw_flow_reconciliation_error'},NaN), ...
    number_field(accounting,{'max_frozen_stock_law_error'},NaN), ...
    number_field(accounting,{'max_walras_reconciliation'},NaN)]);

[bargaining_pass,bargaining_known,bargaining_max] = ...
    bargaining_evidence(result,row.run_dir,options.bargaining_tolerance);
if ~row.solver.transition_solved && ~isfinite(bargaining_max)
    bargaining_known = false;
    bargaining_pass = false;
end
gates.bargaining_identity_pass = bargaining_pass;
gates.bargaining_identity_status = pass_status(bargaining_pass,bargaining_known);
gates.bargaining_identity_max_residual = bargaining_max;

[target_explicit,target_known] = logical_field(result, {'target_pass'});
if isfinite(gates.target_response_pct)
    gates.target_gap_pct = gates.target_response_pct-options.target_value_pct;
    if ~target_known
        target_explicit = abs(gates.target_gap_pct) <= options.target_tolerance_pct;
        target_known = true;
    end
end
if ~row.solver.transition_solved && ~isfinite(gates.target_response_pct)
    target_known = false;
    target_explicit = false;
end
gates.target_pass = target_explicit;
gates.target_status = pass_status(target_explicit,target_known);

[horizon_pass,horizon_known] = logical_field(result, {'horizon_pass'});
if isfield(diagnostics,'horizon_check_enabled') ...
        && ~logical_value(diagnostics.horizon_check_enabled,false)
    horizon_known = false;
    horizon_pass = false;
elseif isfield(result,'configuration') ...
        && isfield(result.configuration,'horizon_check') ...
        && ~logical_value(result.configuration.horizon_check,false) ...
        && ~isfield(diagnostics,'horizon_insensitivity_pass')
    horizon_known = false;
    horizon_pass = false;
elseif ~horizon_known && isfield(diagnostics,'horizon_insensitivity_pass') ...
        && ~isempty(diagnostics.horizon_insensitivity_pass) ...
        && isfinite(double(diagnostics.horizon_insensitivity_pass))
    horizon_pass = logical_value(diagnostics.horizon_insensitivity_pass,false);
    horizon_known = true;
end
gates.horizon_max_gap = number_field(diagnostics, ...
    {'horizon_insensitivity_max'},NaN);
if ~row.solver.transition_solved && ~isfinite(gates.horizon_max_gap)
    horizon_known = false;
    horizon_pass = false;
end
gates.horizon_pass = horizon_pass;
gates.horizon_status = pass_status(horizon_pass,horizon_known);

if strcmp(row.metric_status,"available")
    gates.depreciation_pass = row.averages.rer_pct < 0;
    export_q5_40 = NaN;
    if isfield(diagnostics,'sector') && isstruct(diagnostics.sector)
        export_q5_40 = number_field(diagnostics.sector, ...
            {'export_volume_q5_40_avg_pct'},NaN);
    end
    gates.export_q5_40_avg_pct = export_q5_40;
    gates.export_increase_pass = isfinite(export_q5_40) && export_q5_40 > 0;
    gates.nx_increase_pass = row.external.nx_impact_pct_annual_output > 0;
    gates.ca_surplus_pass = row.external.ca_impact_pct_annual_output > 0;
    gates.positive_nfa_accumulation_pass = ...
        row.external.nfa_q40_pct_annual_output > 0;
    gates.positivity_pass = true;
    if isfield(diagnostics,'sector') && isstruct(diagnostics.sector) ...
            && isfield(diagnostics.sector,'positivity_pass')
        gates.positivity_pass = logical_value( ...
            diagnostics.sector.positivity_pass,false);
    end
    gates.economic_validation_pass = gates.depreciation_pass ...
        && gates.export_increase_pass && gates.nx_increase_pass ...
        && gates.ca_surplus_pass && gates.positive_nfa_accumulation_pass;
    gates.economic_validation_pass = gates.economic_validation_pass ...
        && gates.positivity_pass;
    gates.economic_validation_status = pass_status( ...
        gates.economic_validation_pass,true);
else
    [economic_pass,economic_known] = logical_field(result, ...
        {'economic_validation_pass'});
    if ~row.solver.transition_solved
        economic_known = false;
        economic_pass = false;
    end
    gates.economic_validation_pass = economic_pass;
    gates.economic_validation_status = pass_status(economic_pass,economic_known);
end
end


function [pass,known,max_gap] = bargaining_evidence(result,run_dir,tolerance)
[pass,known] = logical_field(result, {'bargaining_identity_pass'});
max_gap = NaN;
if known
    max_gap = number_field(result,{'bargaining_identity_max_residual'},NaN);
    if ~isfinite(max_gap) && isfield(result,'bargaining_diagnostics') ...
            && isstruct(result.bargaining_diagnostics)
        max_gap = number_field(result.bargaining_diagnostics, ...
            {'maximum_residual'},NaN);
    end
    if isfinite(max_gap)
        return
    end
end
if strlength(run_dir) == 0
    return
end
path = fullfile(char(run_dir),'bargaining_diagnostics_summary.csv');
if exist(path,'file') ~= 2
    return
end
try
    t = readtable(path,'VariableNamingRule','preserve');
    candidates = {'maximum_surplus_identity_gap', ...
        'maximum_population_share_gap','maximum_labor_force_identity_gap', ...
        'maximum_nash_sharing_gap','MaximumSurplusIdentityGap', ...
        'MaximumPopulationShareGap','MaximumLaborForceIdentityGap', ...
        'MaximumNashSharingGap','maximum_option_b_identity_gap'};
    values = [];
    for i = 1:numel(candidates)
        index = find(strcmpi(t.Properties.VariableNames,candidates{i}),1);
        if ~isempty(index) && isnumeric(t{:,index})
            values = [values; abs(t{:,index})]; %#ok<AGROW>
        end
    end
    if ~isempty(values)
        max_gap = max(values,[],'omitnan');
        known = isfinite(max_gap);
        pass = known && max_gap <= tolerance;
    end
catch
    % Missing or malformed diagnostics remain explicitly not run.
end
end


function [paths,summary,averages,external,long_run] = ...
        collect_transition_metrics(scenario_id,run_dir,options)
s = load(fullfile(run_dir,'Sim_H42_EB.mat'),'Sim_H42_EB');
n = load(fullfile(run_dir,'Names_H42_EB.mat'), ...
    'var_names','param_names','param_values');
sim = s.Sim_H42_EB;
names = strtrim(cellstr(n.var_names));
assert(size(sim,2) >= 42,'ReviewerSuite:ShortPath', ...
    'The transition must contain at least 40 simulated quarters.');
last = size(sim,2)-1;
columns = 1:last;
quarter = (0:last-1)';
v = @(name) sim(require_name(names,name),columns)';
y0 = v('Y_a_t'); y0 = y0(1);
annual_y0 = 4*y0;

wage = percent_path(v('w_a_t'));
employment = percent_path(v('N_a_t'));
employment_level = v('N_a_t');
unemployment = 100*((1-employment_level)-(1-employment_level(1)));
job_finding = percent_path(v('p_a_t'));
vacancies = optional_sum_percent(sim,names,columns,{'V_a_t'}, {'VT_a_t','VN_a_t'});
tradable_level = v('NT_a_t');
nontradable_level = v('NN_a_t');
tradable = percent_path(tradable_level);
nontradable = percent_path(nontradable_level);
relative_tn = tradable-nontradable;
consumption = percent_path(v('C_a_t'));
investment = percent_path(v('I_a_t'));
exports = percent_path(v('EX_a_t'));
imports = percent_path(v('IM_a_t'));
export_volume = optional_percent(sim,names,columns,'EXVOL_a_t');
rer = optional_percent(sim,names,columns,'rer_cpi_t');
terms_trade = optional_percent(sim,names,columns,'rel_pT_t');
nx_level = v('NX_a_t');
nx = 100*(nx_level-nx_level(1))/annual_y0;
ca = 100*v('CA_a_t')/annual_y0;
nfa_level = v('NFA_a_t');
nfa = 100*(nfa_level-nfa_level(1))/annual_y0;

household_saving = NaN(last,1);
household_wealth = NaN(last,1);
national_saving = NaN(last,1);
corporate_saving = NaN(last,1);
government_saving = NaN(last,1);
investment_flow = NaN(last,1);
household_flow = NaN(last,1);
national_flow = NaN(last,1);
try
    accounts = scenario_savings_accounts(run_dir,sim,n.var_names, ...
        n.param_values,n.param_names,'a');
    household_saving = 100*(accounts.household_cash_rate(:) ...
        -accounts.household_cash_rate(1));
    household_wealth = 100*(accounts.total_household_wealth(:) ...
        /accounts.total_household_wealth(1)-1);
    national_saving = 100*(accounts.national_saving_rate(:) ...
        -accounts.national_saving_rate(1));
    corporate_saving = 100*(accounts.corporate_saving(:) ...
        -accounts.corporate_saving(1))/annual_y0;
    household_flow = 100*(accounts.household_cash_saving(:) ...
        -accounts.household_cash_saving(1))/annual_y0;
    national_flow = 100*(accounts.national_saving(:) ...
        -accounts.national_saving(1))/annual_y0;
    government_saving = national_flow-household_flow-corporate_saving;
    investment_flow = 100*(accounts.investment_expenditure(:) ...
        -accounts.investment_expenditure(1))/annual_y0;
catch
    % Saving rows remain unavailable without invalidating other metrics.
end

paths = table(quarter,wage,household_saving,household_wealth, ...
    employment,unemployment, ...
    job_finding,vacancies,consumption,investment,exports,imports, ...
    tradable,nontradable,relative_tn,export_volume,rer,terms_trade, ...
    nx,ca,nfa,national_saving,corporate_saving,government_saving, ...
    'VariableNames',{'Quarter','WagePct','HouseholdCashSavingPP', ...
    'HouseholdWealthPct', ...
    'EmploymentPct','UnemploymentPP','JobFindingPct','VacanciesPct', ...
    'ConsumptionPct','InvestmentPct','ExportsPct','ImportsPct', ...
    'TradableEmploymentPct','NontradableEmploymentPct', ...
    'RelativeTNEmploymentPct','ExportVolumePct','RERPct', ...
    'TermsOfTradePct','NXPctAnnualOutput','CAPctAnnualOutput', ...
    'NFAChangePctAnnualOutput','NationalSavingPP', ...
    'CorporateSavingPctAnnualOutput','GovernmentSavingPctAnnualOutput'});

q1 = 2; q4 = min(5,last); q12 = min(13,last); q40 = min(41,last);
q1_40 = 2:q40;
summary = empty_summary();
summary.wage_q1_pct = wage(q1); summary.wage_q4_pct = wage(q4);
summary.wage_q12_pct = wage(q12); summary.wage_q40_pct = wage(q40);
summary.wage_trough_q1_40_pct = min(wage(q1_40));
[~,trough_index] = min(wage(q1_40));
summary.wage_trough_quarter = trough_index;
summary.employment_q1_pct = employment(q1);
summary.unemployment_q1_pp = unemployment(q1);
summary.job_finding_q1_pct = job_finding(q1);
summary.vacancies_q1_pct = vacancies(q1);
summary.tradable_employment_q1_pct = tradable(q1);
summary.nontradable_employment_q1_pct = nontradable(q1);
summary.relative_tn_employment_q1_pct = relative_tn(q1);
summary.household_cash_saving_q1_pp = household_saving(q1);
summary.household_wealth_q1_pct = household_wealth(q1);
summary.national_saving_q1_pp = national_saving(q1);
summary.consumption_q1_pct = consumption(q1);
summary.investment_q1_pct = investment(q1);
summary.exports_q1_pct = exports(q1);
summary.imports_q1_pct = imports(q1);
summary.rer_q1_pct = rer(q1);
summary.terms_of_trade_q1_pct = terms_trade(q1);

averages = empty_averages();
averages.wage_pct = mean(wage(q1_40),'omitnan');
averages.employment_pct = mean(employment(q1_40),'omitnan');
averages.unemployment_pp = mean(unemployment(q1_40),'omitnan');
averages.job_finding_pct = mean(job_finding(q1_40),'omitnan');
averages.vacancies_pct = mean(vacancies(q1_40),'omitnan');
averages.tradable_employment_pct = mean(tradable(q1_40),'omitnan');
averages.nontradable_employment_pct = mean(nontradable(q1_40),'omitnan');
averages.relative_tn_employment_pct = mean(relative_tn(q1_40),'omitnan');
averages.household_cash_saving_pp = mean(household_saving(q1_40),'omitnan');
averages.household_wealth_pct = mean(household_wealth(q1_40),'omitnan');
averages.national_saving_pp = mean(national_saving(q1_40),'omitnan');
averages.consumption_pct = mean(consumption(q1_40),'omitnan');
averages.investment_pct = mean(investment(q1_40),'omitnan');
averages.exports_pct = mean(exports(q1_40),'omitnan');
averages.imports_pct = mean(imports(q1_40),'omitnan');
averages.nx_pct_annual_output = mean(nx(q1_40),'omitnan');
averages.ca_pct_annual_output = mean(ca(q1_40),'omitnan');
averages.rer_pct = mean(rer(q1_40),'omitnan');
averages.terms_of_trade_pct = mean(terms_trade(q1_40),'omitnan');
averages.export_volume_pct = mean(export_volume(q1_40),'omitnan');

external = empty_external();
external.ca_impact_pct_annual_output = ca(q1);
external.ca_first_positive_quarter = first_positive_quarter(ca);
external.ca_cumulative_q1_40_pct_annual_output = sum(ca(q1_40),'omitnan');
[external.nfa_minimum_pct_annual_output,min_index] = min(nfa(q1_40));
external.nfa_minimum_quarter = min_index;
external.nfa_first_positive_quarter = first_positive_quarter(nfa);
external.nfa_q40_pct_annual_output = nfa(q40);
external.household_saving_impact_pct_annual_output = ...
    household_flow(q1);
external.corporate_saving_impact_pct_annual_output = corporate_saving(q1);
external.government_saving_impact_pct_annual_output = government_saving(q1);
external.national_saving_impact_pct_annual_output = ...
    national_flow(q1);
external.investment_impact_pct_annual_output = investment_flow(q1);
external.nx_impact_pct_annual_output = nx(q1);
[interest_impact,valuation_impact] = external_components(sim,names,annual_y0);
external.net_interest_impact_pct_annual_output = interest_impact;
external.valuation_residual_impact_pct_annual_output = valuation_impact;

long_run = collect_long_run(scenario_id,sim,names,options.long_run_quarter);
end


function [interest,valuation] = external_components(sim,names,annual_y0)
interest = NaN; valuation = NaN;
try
    ca = value(sim,names,'CA_a_t',2);
    nx = value(sim,names,'NX_a_t',2)-value(sim,names,'NX_a_t',1);
    nfa0 = value(sim,names,'NFA_a_t',1);
    if has_name(names,'Rf_a_t')
        gross_return = value(sim,names,'Rf_a_t',2);
    else
        gross_return = value(sim,names,'R_w_t',1);
    end
    interest_level = (gross_return-1)*nfa0;
    interest = 100*interest_level/annual_y0;
    valuation = 100*(ca-nx-interest_level)/annual_y0;
catch
    % Keep unavailable components as NaN.
end
end


function long_run = collect_long_run(scenario_id,sim,names,horizon)
groups = ["Output";"GNP";"Consumption";"Unemployment";"NFA/Output"];
countries = [repmat("Home",5,1);repmat("Foreign",5,1)];
metrics = [groups;groups];
available = false(10,1); values = NaN(10,1);
status = repmat("unavailable",10,1); message = repmat("",10,1);
last = size(sim,2)-1;
column = min(horizon+1,last);
actual_horizon = column-1;
for c = 1:2
    country = char('a'+c-1);
    offset = (c-1)*5;
    try
        y = series(sim,names,['Y_' country '_t']);
        gnp = series(sim,names,['GNP_' country '_t']);
        consumption = series(sim,names,['C_' country '_t']);
        employment = series(sim,names,['N_' country '_t']);
        nfa = series(sim,names,['NFA_' country '_t']);
        block = [percent_at(y,column);percent_at(gnp,column); ...
            percent_at(consumption,column); ...
            100*((1-employment(column))-(1-employment(1))); ...
            100*(nfa(column)/(4*y(column))-nfa(1)/(4*y(1)))];
        values(offset+(1:5)) = block;
        available(offset+(1:5)) = true;
        if actual_horizon < horizon
            status(offset+(1:5)) = "truncated";
            message(offset+(1:5)) = "Requested horizon exceeds saved path.";
        else
            status(offset+(1:5)) = "available";
        end
    catch ME
        message(offset+(1:5)) = string(one_line(ME.message));
    end
end
unit = repmat("Percent Deviation",10,1);
unit(ismember(metrics,["Unemployment","NFA/Output"])) = "Percentage Points";
long_run = table(repmat(string(scenario_id),10,1),countries, ...
    repmat(actual_horizon,10,1),metrics,values,unit,available,status,message, ...
    'VariableNames',{'ScenarioID','Country','HorizonQuarter','Metric', ...
    'Value','Unit','Available','Status','Message'});
end


function path = empty_path_table()
path = table([],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[], ...
    [],[],[],[],[], 'VariableNames',{'Quarter','WagePct', ...
    'HouseholdCashSavingPP','HouseholdWealthPct', ...
    'EmploymentPct','UnemploymentPP', ...
    'JobFindingPct','VacanciesPct','ConsumptionPct','InvestmentPct', ...
    'ExportsPct','ImportsPct','TradableEmploymentPct', ...
    'NontradableEmploymentPct','RelativeTNEmploymentPct', ...
    'ExportVolumePct','RERPct','TermsOfTradePct','NXPctAnnualOutput', ...
    'CAPctAnnualOutput','NFAChangePctAnnualOutput','NationalSavingPP', ...
    'CorporateSavingPctAnnualOutput','GovernmentSavingPctAnnualOutput'});
end


function s = empty_summary()
s = struct('wage_q1_pct',NaN,'wage_q4_pct',NaN,'wage_q12_pct',NaN, ...
    'wage_q40_pct',NaN,'wage_trough_q1_40_pct',NaN, ...
    'wage_trough_quarter',NaN,'employment_q1_pct',NaN, ...
    'unemployment_q1_pp',NaN,'job_finding_q1_pct',NaN, ...
    'vacancies_q1_pct',NaN,'tradable_employment_q1_pct',NaN, ...
    'nontradable_employment_q1_pct',NaN, ...
    'relative_tn_employment_q1_pct',NaN, ...
    'household_cash_saving_q1_pp',NaN,'household_wealth_q1_pct',NaN, ...
    'national_saving_q1_pp',NaN, ...
    'consumption_q1_pct',NaN,'investment_q1_pct',NaN, ...
    'exports_q1_pct',NaN,'imports_q1_pct',NaN,'rer_q1_pct',NaN, ...
    'terms_of_trade_q1_pct',NaN);
end


function s = empty_averages()
s = struct('wage_pct',NaN,'employment_pct',NaN,'unemployment_pp',NaN, ...
    'job_finding_pct',NaN,'vacancies_pct',NaN, ...
    'tradable_employment_pct',NaN,'nontradable_employment_pct',NaN, ...
    'relative_tn_employment_pct',NaN,'household_cash_saving_pp',NaN, ...
    'household_wealth_pct',NaN,'national_saving_pp',NaN, ...
    'consumption_pct',NaN, ...
    'investment_pct',NaN,'exports_pct',NaN,'imports_pct',NaN, ...
    'nx_pct_annual_output',NaN,'ca_pct_annual_output',NaN, ...
    'rer_pct',NaN,'terms_of_trade_pct',NaN,'export_volume_pct',NaN);
end


function s = empty_external()
s = struct('ca_impact_pct_annual_output',NaN, ...
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


function t = empty_long_run()
t = table(strings(0,1),strings(0,1),zeros(0,1),strings(0,1), ...
    zeros(0,1),strings(0,1),false(0,1),strings(0,1),strings(0,1), ...
    'VariableNames',{'ScenarioID','Country','HorizonQuarter','Metric', ...
    'Value','Unit','Available','Status','Message'});
end


function status = overall_status(row)
if ~row.solver.steady_state_solved
    status = "steady_state_failed";
elseif ~row.solver.transition_solved
    status = "transition_failed";
elseif ~row.gates.accounting_pass || ~row.gates.bargaining_identity_pass
    status = "solved_identity_failed";
elseif ~row.gates.target_pass
    status = "solved_target_failed";
elseif ~row.gates.horizon_pass
    status = "solved_horizon_not_validated";
elseif ~row.gates.economic_validation_pass
    status = "solved_economic_validation_failed";
else
    status = "validated";
end
end


function tf = transition_files_exist(run_dir)
tf = strlength(string(run_dir)) > 0 ...
    && exist(fullfile(char(run_dir),'Sim_H42_EB.mat'),'file') == 2 ...
    && exist(fullfile(char(run_dir),'Names_H42_EB.mat'),'file') == 2;
end


function out = percent_path(x)
x = x(:);
if isempty(x) || ~isfinite(x(1)) || abs(x(1)) <= eps
    out = NaN(size(x));
else
    out = 100*(x/x(1)-1);
end
end


function out = optional_percent(sim,names,columns,name)
if has_name(names,name)
    out = percent_path(sim(require_name(names,name),columns)');
else
    out = NaN(numel(columns),1);
end
end


function out = optional_sum_percent(sim,names,columns,direct_names,sum_names)
out = NaN(numel(columns),1);
for i = 1:numel(direct_names)
    if has_name(names,direct_names{i})
        out = percent_path(sim(require_name(names,direct_names{i}),columns)');
        return
    end
end
if all(cellfun(@(name) has_name(names,name),sum_names))
    raw = zeros(numel(columns),1);
    for i = 1:numel(sum_names)
        raw = raw+sim(require_name(names,sum_names{i}),columns)';
    end
    out = percent_path(raw);
end
end


function quarter = first_positive_quarter(path)
path = path(:);
index = find(path(2:end) > 0,1);
if isempty(index)
    quarter = NaN;
else
    quarter = index;
end
end


function x = series(sim,names,name)
x = sim(require_name(names,name),1:size(sim,2)-1)';
end


function x = value(sim,names,name,column)
x = sim(require_name(names,name),column);
end


function x = percent_at(path,column)
x = 100*(path(column)/path(1)-1);
end


function index = require_name(names,name)
index = find(strcmp(names,name),1);
if isempty(index)
    error('ReviewerSuite:MissingVariable', ...
        'Required transition variable is missing: %s.',name);
end
end


function tf = has_name(names,name)
tf = any(strcmp(names,name));
end


function label = mode_label(mode)
text = upper(strtrim(string(mode)));
if text == "0" || text == "STU1" || contains(text,"CURRENT")
    label = "STU1";
elseif text == "1" || contains(text,"ALL_UNEMPLOYED") ...
        || contains(text,"ALL UNEMPLOYED") || contains(text,"OPTION A")
    label = "All Unemployed";
elseif text == "2" || contains(text,"LABOR_FORCE") ...
        || contains(text,"LABOR-FORCE") || contains(text,"OPTION B")
    label = "Labor-Force-Weighted Collective Bargaining";
elseif text == "3" || contains(text,"CONVEX")
    label = "Convex STU1/LTU Fallback";
else
    label = string(mode);
end
end


function text = collect_error_message(result)
text = "";
for name = {'error_message','message'}
    if isfield(result,name{1}) && ~isempty(result.(name{1}))
        text = string(one_line(char(string(result.(name{1})))));
        return
    end
end
if isfield(result,'diagnostics') && isstruct(result.diagnostics) ...
        && isfield(result.diagnostics,'failure_messages') ...
        && ~isempty(result.diagnostics.failure_messages)
    text = strjoin(string(result.diagnostics.failure_messages),' | ');
end
end


function [value,found] = logical_field(source,names)
value = false; found = false;
for i = 1:numel(names)
    [candidate,has_candidate] = case_field(source,names{i});
    if has_candidate && ~isempty(candidate)
        if isnumeric(candidate) && any(isnan(candidate(:)))
            continue
        end
        value = logical_value(candidate,false);
        found = true;
        return
    end
end
end


function value = logical_value(candidate,default)
value = default;
if islogical(candidate) || isnumeric(candidate)
    if isscalar(candidate) && isfinite(double(candidate))
        value = logical(candidate);
    end
elseif ischar(candidate) || isstring(candidate)
    text = lower(strtrim(string(candidate)));
    if any(text == ["true","pass","passed","1","yes"])
        value = true;
    elseif any(text == ["false","fail","failed","0","no"])
        value = false;
    end
end
end


function status = pass_status(pass,known)
if ~known
    status = "not_run";
elseif pass
    status = "pass";
else
    status = "fail";
end
end


function value = number_field(source,names,default)
value = default;
for i = 1:numel(names)
    [candidate,found] = case_field(source,names{i});
    if found && isnumeric(candidate) && isscalar(candidate)
        value = double(candidate);
        return
    end
end
end


function value = field_or(source,name,default)
[candidate,found] = case_field(source,name);
if found
    value = candidate;
else
    value = default;
end
end


function value = struct_text(source,name,default)
value = string(default);
[candidate,found] = case_field(source,name);
if found && ~isempty(candidate)
    candidate = string(candidate);
    if isscalar(candidate)
        value = candidate;
    end
end
end


function [value,found] = case_field(source,name)
value = []; found = false;
if ~isstruct(source) || ~isscalar(source)
    return
end
fields = fieldnames(source);
index = find(strcmpi(fields,name),1);
if ~isempty(index)
    value = source.(fields{index});
    found = true;
end
end


function value = pick_text(sources,names,default)
value = string(default);
for i = 1:numel(sources)
    source = sources{i};
    for j = 1:numel(names)
        [candidate,found] = case_field(source,names{j});
        if found && ~isempty(candidate)
            candidate = string(candidate);
            if isscalar(candidate) && strlength(candidate) > 0
                value = candidate;
                return
            end
        end
    end
end
end


function value = pick_number(sources,names,default)
value = default;
for i = 1:numel(sources)
    source = sources{i};
    for j = 1:numel(names)
        [candidate,found] = case_field(source,names{j});
        if found && isnumeric(candidate) && isscalar(candidate) ...
                && ~isempty(candidate)
            value = double(candidate);
            return
        end
    end
end
end


function value = max_finite(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = max(abs(values));
end
end


function text = one_line(text)
text = regexprep(char(text),'[\r\n\t]+',' ');
text = regexprep(text,'\s+',' ');
text = strtrim(text);
end
