function history = parameter_checks(history,tolerance)
%PARAMETER_CHECKS Relabel final calibration evidence.
%   HISTORY = PARAMETER_CHECKS(HISTORY,TOLERANCE)
%   classifies every calibration evaluation without changing its numerical
%   evidence. TOLERANCE is an optional scalar or one value per row and
%   defaults to 0.01 percentage point.
%
%   Solved in-tolerance evaluations are target_matched. Other solved finite
%   evaluations are evaluated_off_target, except that the best solved row in
%   a group with no match is marked
%   target_not_matched_within_bounds_or_budget. Unsolved evaluations are
%   separated into backend_blocked, intrinsic_prestate_failure, and
%   numerical_failure. A group is defined by scenario, parameter, and target
%   metric so histories containing more than one calibration problem remain
%   distinct.

assert(istable(history),'ReviewerSuite:CalibrationHistoryType', ...
    'Calibration history must be a table.');
if isempty(history)
    return
end
if nargin < 2 || isempty(tolerance)
    tolerance = 0.01;
end
validateattributes(tolerance,{'numeric'}, ...
    {'vector','real','finite','nonnegative'},mfilename,'tolerance');
if isscalar(tolerance)
    tolerance = repmat(double(tolerance),height(history),1);
else
    assert(numel(tolerance) == height(history), ...
        'ReviewerSuite:CalibrationToleranceSize', ...
        'Tolerance must be scalar or have one value per history row.');
    tolerance = double(tolerance(:));
end

scenario_name = find_variable(history,{'scenario_id','ScenarioID'},true);
parameter_name = find_variable(history, ...
    {'parameter_name','Parameter'},false);
target_name = find_variable(history,{'target_name','TargetMetric'},false);
solved_name = find_variable(history,{'solved','Solved'},true);
gap_name = find_variable(history,{'target_gap','Gap'},true);
status_name = find_variable(history,{'status','Status'},false);
message_name = find_variable(history,{'message','Message'},false);

solved = logical_column(history.(solved_name),solved_name);
gap = double(history.(gap_name));
assert(isnumeric(history.(gap_name)) && isvector(gap), ...
    'ReviewerSuite:CalibrationGapType', ...
    'Calibration target gap must be a numeric vector.');
gap = gap(:);

if isempty(status_name)
    status_name = 'status';
    history.(status_name) = strings(height(history),1);
end
if isempty(message_name)
    message_name = 'message';
    history.(message_name) = strings(height(history),1);
end
old_status = clean_string(history.(status_name));
old_message = clean_string(history.(message_name));
evidence = lower(join_evidence(history,old_status,old_message));

intrinsic_name = find_variable(history, ...
    {'intrinsic_prestate_failure','IntrinsicPrestateFailure'},false);
intrinsic = false(height(history),1);
if ~isempty(intrinsic_name)
    intrinsic = logical_column(history.(intrinsic_name),intrinsic_name);
end
intrinsic = intrinsic ...
    | contains(evidence,"pre_reform_infeasible") ...
    | contains(evidence,"intrinsic_prestate_failure") ...
    | contains(evidence,"prior_fixed_prestate_failure");
backend_blocked = contains(evidence,"backend_compatibility_blocked") ...
    | contains(evidence,"backend_blocked") ...
    | contains(evidence,"backend blocked");

in_tolerance = solved & isfinite(gap) & abs(gap) <= tolerance;
off_target = solved & isfinite(gap) & ~in_tolerance;
new_status = repmat("numerical_failure",height(history),1);
new_status(off_target) = "evaluated_off_target";
new_status(in_tolerance) = "target_matched";
new_status(~solved & intrinsic & ~backend_blocked) = ...
    "intrinsic_prestate_failure";
new_status(~solved & backend_blocked) = "backend_blocked";

scenario = clean_string(history.(scenario_name));
parameter = optional_string(history,parameter_name);
target = optional_string(history,target_name);
group_id = scenario + "|" + parameter + "|" + target;
groups = findgroups(group_id);
for group = 1:max(groups)
    members = find(groups == group);
    if any(new_status(members) == "target_matched")
        continue
    end
    candidates = members(new_status(members) == "evaluated_off_target");
    if isempty(candidates)
        continue
    end
    minimum_gap = min(abs(gap(candidates)));
    tied = candidates(abs(gap(candidates))-minimum_gap <= ...
        max(eps(minimum_gap),eps));
    best = tied(end);
    new_status(best) = "target_not_matched_within_bounds_or_budget";
end

new_message = old_message;
for i = 1:height(history)
    new_message(i) = relabel_message(old_message(i),old_status(i), ...
        new_status(i));
end
history.(status_name) = new_status;
history.(message_name) = new_message;
end


function name = find_variable(history,candidates,required)
name = '';
variables = history.Properties.VariableNames;
for i = 1:numel(candidates)
    index = find(strcmpi(variables,candidates{i}),1);
    if ~isempty(index)
        name = variables{index};
        return
    end
end
if required
    error('ReviewerSuite:CalibrationHistoryColumn', ...
        'Calibration history is missing required column %s.',candidates{1});
end
end


function value = logical_column(value,name)
assert((islogical(value) || isnumeric(value)) && isvector(value), ...
    'ReviewerSuite:CalibrationLogicalColumn', ...
    'Calibration history column %s must be a logical vector.',name);
if isnumeric(value)
    assert(all(isfinite(value(:))) && all(value(:) == 0 | value(:) == 1), ...
        'ReviewerSuite:CalibrationLogicalColumn', ...
        'Calibration history column %s must contain only zero or one.',name);
end
value = logical(value(:));
end


function value = optional_string(history,name)
if isempty(name)
    value = repmat("",height(history),1);
else
    value = clean_string(history.(name));
end
end


function value = clean_string(value)
value = string(value(:));
value(ismissing(value)) = "";
end


function evidence = join_evidence(history,status,message)
evidence = status + " " + message;
names = {'failure_phase','FailurePhase','failure_identifier', ...
    'FailureIdentifier','failure_message','FailureMessage'};
for i = 1:numel(names)
    name = find_variable(history,names(i),false);
    if ~isempty(name)
        evidence = evidence + " " + clean_string(history.(name));
    end
end
end


function message = relabel_message(message,old_status,new_status)
message = strtrim(message);
old_status = strtrim(old_status);
if strlength(message) == 0 || message == old_status
    message = new_status;
    return
end
prefix = old_status + ":";
if strlength(old_status) > 0 && startsWith(message,prefix)
    message = new_status + extractAfter(message,strlength(old_status));
end
end
