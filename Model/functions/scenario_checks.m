function rows = scenario_checks(rows,calibration_history)
%SCENARIO_CHECKS Apply scenario-specific gate contracts.
%   Numerical model outputs are intentionally left unchanged. This helper
%   determines which calibration target and economic profile are relevant
%   for each experiment before results are labeled for tables and figures.

if nargin < 2
    calibration_history = [];
end
rows = normalize_rows(rows);
history = normalize_history(calibration_history);
if ~isempty(rows) && ~isfield(rows,'source_validation_message')
    [rows.source_validation_message] = deal("");
end
for i = 1:numel(rows)
    rows(i) = apply_one(rows(i),history);
end
end


function row = apply_one(row,history)
id = lower(char(row_text(row,'scenario_id',"unspecified")));
solver = struct_field(row,'solver');
gates = struct_field(row,'gates');
averages = struct_field(row,'averages');
registry = struct_field(row,'registry');

steady_solved = logical_field(solver,'steady_state_solved',false);
transition_solved = logical_field(solver,'transition_solved',false);
numerically_available = steady_solved && transition_solved;

gates.target_metric = "not_applicable";
gates.target_role = "not_applicable";
gates.target_applicable = false;
gates.target_value_pct = NaN;
gates.target_response_pct = NaN;
gates.target_gap_pct = NaN;
gates.target_tolerance_pct = NaN;
gates.target_pass = false;
gates.target_status = "not_applicable";

if strcmp(id,'wage_moderation_post_only')
    gates.target_metric = "home_unemployment_q1_40_change_pp";
    gates.target_role = "required_scale_match";
    gates.target_applicable = true;
    gates.target_value_pct = history_target(history,id, ...
        'home_unemployment_q1_40_to_preferred_ui');
    if ~isfinite(gates.target_value_pct)
        gates.target_value_pct = history_target(history,id,'unemployment');
    end
    gates.target_response_pct = number_field(averages,'unemployment_pp',NaN);
    gates.target_tolerance_pct = registry_number(registry, ...
        'target_tolerance_pp',0.01);
    gates = finish_target(gates,numerically_available,row);
elseif target_is_required(id,registry)
    gates.target_metric = "relative_tn_employment_q1_40_pct";
    if strcmp(id,'preferred_baseline')
        gates.target_role = "frozen_calibration_reference";
    else
        gates.target_role = "published_parameter_check";
    end
    gates.target_applicable = true;
    gates.target_value_pct = registry_number(registry,'target_value',2.7);
    if ~isfinite(gates.target_value_pct)
        gates.target_value_pct = 2.7;
    end
    gates.target_response_pct = number_field(averages, ...
        'relative_tn_employment_pct',NaN);
    gates.target_tolerance_pct = registry_number(registry, ...
        'target_tolerance_pp',0.01);
    gates = finish_target(gates,numerically_available,row);
end

gates.economic_profile = "ui_external_adjustment_diagnostic";
gates.economic_validation_role = "reported_diagnostic";
gates.economic_validation_applicable = true;
if strcmp(id,'wage_moderation_post_only')
    gates.economic_profile = "wage_moderation_mechanism";
    gates.economic_validation_role = "not_applicable";
    gates.economic_validation_applicable = false;
    gates.economic_validation_pass = false;
    gates.economic_validation_status = "not_applicable";
elseif ~numerically_available
    gates.economic_validation_pass = false;
    gates.economic_validation_status = unavailable_status(row);
else
    gates.economic_validation_status = pass_fail( ...
        logical_field(gates,'economic_validation_pass',false));
end

paper_facing = registry_logical(registry,'paper_facing',true);
configured_horizon = logical_field(struct_field(registry,'config'), ...
    'horizon_check',false);
gates.horizon_applicable = paper_facing && configured_horizon;
if ~numerically_available
    % A failed pre-state or blocked backend prevents the horizon exercise
    % from starting. Keep that distinct from the failure that blocked it.
    if gates.horizon_applicable
        gates.horizon_status = "not_run";
    else
        gates.horizon_status = "not_applicable";
    end
    gates.horizon_pass = false;
elseif ~gates.horizon_applicable
    gates.horizon_status = "not_applicable";
    gates.horizon_pass = false;
end

row.gates = gates;
existing_source_message = row_text(row,'source_validation_message',"");
if strlength(existing_source_message) == 0
    existing_source_message = row_text(row,'error_message',"");
end
row.source_validation_message = existing_source_message;
if transition_solved
    % A solved transition can carry raw Gate-2/3/4 messages. They are
    % validation evidence, not execution errors.
    row.error_message = "";
end
row.status = overall_status(row);
end


function gates = finish_target(gates,numerically_available,row)
if numerically_available && isfinite(gates.target_value_pct) ...
        && isfinite(gates.target_response_pct)
    gates.target_gap_pct = gates.target_response_pct-gates.target_value_pct;
    gates.target_pass = abs(gates.target_gap_pct) ...
        <= gates.target_tolerance_pct;
    gates.target_status = pass_fail(gates.target_pass);
else
    gates.target_pass = false;
    gates.target_status = unavailable_status(row);
end
end


function flag = target_is_required(id,registry)
policy = lower(char(registry_text(registry,'calibration_policy','none')));
flag = strcmp(id,'preferred_baseline') ...
    || strcmp(policy,'cut_to_tnt') ...
    || strcmp(id,'separation_decline');
end


function status = unavailable_status(row)
id = lower(char(row_text(row,'scenario_id',"")));
phase = lower(char(solver_phase(row)));
message = lower(char(row_text(row,'error_message',"")));
if contains(phase,'backend') ...
        || contains(message,'backend_compatibility_blocked')
    status = "backend_blocked";
elseif contains(id,'all_unemployed') ...
        && (contains(message,'bounded steady-state solver') ...
            || contains(message,'prestate') || contains(message,'pre-state'))
    status = "intrinsic_prestate_failure";
else
    status = "not_run";
end
end


function phase = solver_phase(row)
solver = struct_field(row,'solver');
phase = string_field(solver,'phase',"");
end


function status = overall_status(row)
solver = struct_field(row,'solver');
gates = struct_field(row,'gates');
if ~logical_field(solver,'steady_state_solved',false)
    if strcmp(unavailable_status(row),"backend_blocked")
        status = "backend_blocked";
    elseif strcmp(unavailable_status(row),"intrinsic_prestate_failure")
        status = "intrinsic_prestate_failure";
    else
        status = "steady_state_failed";
    end
elseif ~logical_field(solver,'transition_solved',false)
    status = "transition_failed";
elseif ~logical_field(gates,'accounting_pass',false) ...
        || ~logical_field(gates,'bargaining_identity_pass',false)
    status = "solved_identity_failed";
elseif logical_field(gates,'target_applicable',false) ...
        && ~logical_field(gates,'target_pass',false)
    status = "solved_target_failed";
elseif logical_field(gates,'horizon_applicable',true) ...
        && ~logical_field(gates,'horizon_pass',false)
    status = "solved_horizon_not_validated";
else
    status = "validated_for_reported_gates";
end
end


function value = history_target(history,id,name_fragment)
value = NaN;
if isempty(history) || ~istable(history)
    return
end
scenario_name = history_variable(history,{'scenario_id','ScenarioID'});
target_name = history_variable(history,{'target_name','TargetMetric'});
value_name = history_variable(history,{'target_value','Target'});
if isempty(scenario_name) || isempty(target_name) || isempty(value_name)
    return
end
mask = strcmpi(string(history.(scenario_name)),string(id)) ...
    & contains(lower(string(history.(target_name))),lower(string(name_fragment)));
values = double(history.(value_name)(mask));
values = values(isfinite(values));
if ~isempty(values)
    value = values(end);
end


function name = history_variable(history,candidates)
name = '';
variables = history.Properties.VariableNames;
for i = 1:numel(candidates)
    index = find(strcmpi(variables,candidates{i}),1);
    if ~isempty(index)
        name = variables{index};
        return
    end
end
end
end


function rows = normalize_rows(rows)
if isempty(rows)
    rows = repmat(struct(),0,1);
elseif iscell(rows)
    rows = vertcat(rows{:});
elseif istable(rows)
    rows = table2struct(rows);
end
assert(isstruct(rows),'ReviewerSuite:ReportingRows', ...
    'rows must be a struct array, cell array of structs, or table.');
rows = rows(:);
end


function history = normalize_history(history)
if isempty(history)
    history = table();
elseif isstruct(history)
    history = struct2table(history(:));
end
assert(istable(history),'ReviewerSuite:ReportingHistory', ...
    'calibration_history must be a table or struct array.');
end


function value = struct_field(source,name)
value = struct();
if isstruct(source) && isfield(source,name) && isstruct(source.(name))
    value = source.(name);
end
end


function value = number_field(source,name,default)
value = default;
if isstruct(source) && isfield(source,name) && isnumeric(source.(name)) ...
        && isscalar(source.(name))
    value = double(source.(name));
end
end


function value = logical_field(source,name,default)
value = default;
if isstruct(source) && isfield(source,name)
    candidate = source.(name);
    if (islogical(candidate) || isnumeric(candidate)) && isscalar(candidate) ...
            && isfinite(double(candidate))
        value = logical(candidate);
    end
end
end


function value = string_field(source,name,default)
value = string(default);
if isstruct(source) && isfield(source,name) && ~isempty(source.(name))
    value = string(source.(name));
    value = value(1);
end
end


function value = row_text(row,name,default)
value = string_field(row,name,default);
end


function value = registry_number(registry,name,default)
value = number_field(registry,name,default);
end


function value = registry_text(registry,name,default)
value = string_field(registry,name,default);
end


function value = registry_logical(registry,name,default)
value = logical_field(registry,name,default);
end


function status = pass_fail(pass)
if pass
    status = "pass";
else
    status = "fail";
end
end
