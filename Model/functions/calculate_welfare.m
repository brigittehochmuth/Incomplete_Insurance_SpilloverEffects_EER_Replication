function [welfare,status] = calculate_welfare(scenario_id,run_dir,options)
%CALCULATE_WELFARE Reconstruct CEVs for every requested group/country.
%
% [welfare,status] = calculate_welfare(scenario_id,run_dir)
%
% The returned table always has 22 rows: Aggregate, Employed, EU1-EU8,
% and LTU for Home and Foreign. Missing inputs generate explicit unavailable
% rows; the function never substitutes zero or another scenario's welfare.

if nargin < 1 || isempty(scenario_id)
    scenario_id = "UNSPECIFIED";
end
if nargin < 2 || isempty(run_dir)
    run_dir = '';
end
if nargin < 3 || isempty(options)
    options = struct();
end
if ~isfield(options,'weight_tolerance')
    options.weight_tolerance = 1e-10;
end
if ~isfield(options,'long_run_quarter')
    options.long_run_quarter = 160; %#ok<NASGU>
end
if ~isfield(options,'configuration') || ~isstruct(options.configuration)
    options.configuration = struct();
end

groups = ["Aggregate";"Employed";"EU1";"EU2";"EU3";"EU4"; ...
    "EU5";"EU6";"EU7";"EU8";"LTU"];
countries = [repmat("Home",numel(groups),1); ...
    repmat("Foreign",numel(groups),1)];
group_column = [groups;groups];
scenario_column = repmat(string(scenario_id),numel(group_column),1);
cev = NaN(numel(group_column),1);
available = false(numel(group_column),1);
row_status = repmat("unavailable",numel(group_column),1);
message = repmat("Transition welfare inputs are unavailable.", ...
    numel(group_column),1);
method = repmat("Corrected Transition Recursion",numel(group_column),1);

status = struct('available',false,'status',"unavailable", ...
    'message',"Transition welfare inputs are unavailable.", ...
    'home_weight_gap',NaN,'foreign_weight_gap',NaN);
required = {fullfile(run_dir,'Sim_H42_EB.mat'), ...
    fullfile(run_dir,'Names_H42_EB.mat')};
if isempty(run_dir) || any(cellfun(@(p) exist(p,'file') ~= 2,required))
    welfare = make_table();
    return
end

try
    sim_data = load(required{1},'Sim_H42_EB');
    names_data = load(required{2},'var_names','param_names','param_values');
    sim = sim_data.Sim_H42_EB;
    names = strtrim(cellstr(names_data.var_names));
    parameter_names = strtrim(cellstr(names_data.param_names));
    parameter_values = names_data.param_values;
    assert(size(sim,2) >= 3,'ReviewerSuite:WelfareShortPath', ...
        'The saved transition has no post-reform period.');
    columns = 1:size(sim,2)-1; % Exclude the terminal boundary column.
    v = @(name) sim(require_name(names,name),columns)';
    p = @(name) parameter_values(require_name(parameter_names,name));

    home_multiplier = config_number(options.configuration, ...
        'separation_multiplier_a',1.0);
    foreign_multiplier = config_number(options.configuration, ...
        'separation_multiplier_b',1.0);
    [home,home_gap] = country_cev(v,p,'a',options.weight_tolerance, ...
        home_multiplier);
    [foreign,foreign_gap] = country_cev(v,p,'b',options.weight_tolerance, ...
        foreign_multiplier);
    cev = [home;foreign];
    available(:) = isfinite(cev);
    row_status(available) = "available";
    row_status(~available) = "invalid";
    message(:) = "";
    message(~available) = "CEV reconstruction returned a non-finite value.";
    status.available = all(available);
    if status.available
        status.status = "available";
        status.message = "";
    else
        status.status = "partial";
        status.message = "At least one CEV is non-finite.";
    end
    status.home_weight_gap = home_gap;
    status.foreign_weight_gap = foreign_gap;
catch ME
    row_status(:) = "error";
    message(:) = string(one_line(ME.message));
    status.status = "error";
    status.message = string(one_line(ME.message));
end
welfare = make_table();

    function t = make_table()
        t = table(scenario_column,countries,group_column,cev,available, ...
            row_status,message,method, ...
            'VariableNames',{'ScenarioID','Country','Group','CEVPct', ...
            'Available','Status','Message','Method'});
    end
end


function [result,weight_gap] = country_cev(v,p,country,tolerance, ...
        separation_multiplier)
sigma = p('sigmac');
beta = p(['betta_' country]);
post_separation = p(['s_' country]);
validateattributes(separation_multiplier,{'numeric'}, ...
    {'scalar','real','finite','>',0});
pre_separation = post_separation/separation_multiplier;
validateattributes(beta,{'numeric'},{'scalar','real','finite','>',0,'<',1});
validateattributes(post_separation,{'numeric'}, ...
    {'scalar','real','finite','>=',0,'<=',1});
validateattributes(pre_separation,{'numeric'}, ...
    {'scalar','real','finite','>=',0,'<=',1});

consumption = [v(['Ce_' country '_t'])'; ...
    v(['Ceu1_' country '_t'])';v(['Ceu2_' country '_t'])'; ...
    v(['Ceu3_' country '_t'])';v(['Ceu4_' country '_t'])'; ...
    v(['Ceu5_' country '_t'])';v(['Ceu6_' country '_t'])'; ...
    v(['Ceu7_' country '_t'])';v(['Ceu8_' country '_t'])'; ...
    v(['Cuu_' country '_t'])'];
assert(all(isfinite(consumption(:))) && all(consumption(:) > 0), ...
    'ReviewerSuite:WelfareConsumption', ...
    'Country %s has non-positive or non-finite consumption.',country);
job_finding = v(['p_' country '_t']);
assert(all(isfinite(job_finding)) && all(job_finding >= 0) ...
    && all(job_finding <= 1),'ReviewerSuite:WelfareJobFinding', ...
    'Country %s has an invalid job-finding probability.',country);
employment = v(['mue_' country '_t']);
newly_unemployed = v(['mueu1_' country '_t']);
separation_path = repmat(post_separation,size(job_finding));
separation_path(1) = pre_separation;
separation_denominator = (1-job_finding(2:end)).*employment(1:end-1);
assert(all(isfinite(separation_denominator)) ...
        && all(separation_denominator > 0), ...
    'ReviewerSuite:WelfareSeparationDenominator', ...
    'Country %s has an invalid separation-rate denominator.',country);
separation_path(2:end) = newly_unemployed(2:end)./separation_denominator;
assert(all(isfinite(separation_path)) && all(separation_path >= -1e-10) ...
        && all(separation_path <= 1+1e-10), ...
    'ReviewerSuite:WelfareSeparationPath', ...
    'Country %s has an invalid separation-rate path.',country);
separation_path = min(max(separation_path,0),1);

if abs(sigma-1) <= 1e-10
    utility = log(consumption);
else
    utility = consumption.^(1-sigma)/(1-sigma);
end
periods = size(consumption,2);
values = zeros(size(consumption));
pre_value = (eye(10)-beta*welfare_transition(job_finding(1),pre_separation)) ...
    \ utility(:,1);
values(:,periods) = ...
    (eye(10)-beta*welfare_transition(job_finding(end),separation_path(end))) ...
    \ utility(:,end);
for period = periods-1:-1:2
    transition = welfare_transition(job_finding(period+1), ...
        separation_path(period));
    values(:,period) = utility(:,period)+beta*transition*values(:,period+1);
end

weights = [first_value(v(['mue_' country '_t'])); ...
    first_value(v(['mueu1_' country '_t'])); ...
    first_value(v(['mueu2_' country '_t'])); ...
    first_value(v(['mueu3_' country '_t'])); ...
    first_value(v(['mueu4_' country '_t'])); ...
    first_value(v(['mueu5_' country '_t'])); ...
    first_value(v(['mueu6_' country '_t'])); ...
    first_value(v(['mueu7_' country '_t'])); ...
    first_value(v(['mueu8_' country '_t'])); ...
    first_value(v(['muuu_' country '_t']))];
weight_gap = abs(sum(weights)-1);
assert(all(weights >= -tolerance) && weight_gap <= tolerance, ...
    'ReviewerSuite:WelfareWeights', ...
    'Country %s initial welfare weights have gap %.12g.',country,weight_gap);

if abs(sigma-1) <= 1e-10
    state_cev = 100*(exp((1-beta)*(values(:,2)-pre_value))-1);
    aggregate_cev = 100*(exp((1-beta)*(weights'*(values(:,2)-pre_value)))-1);
else
    ratios = values(:,2)./pre_value;
    assert(all(ratios > 0),'ReviewerSuite:WelfareRatio', ...
        'Country %s has a non-positive welfare-value ratio.',country);
    state_cev = 100*(ratios.^(1/(1-sigma))-1);
    aggregate_ratio = (weights'*values(:,2))/(weights'*pre_value);
    assert(aggregate_ratio > 0,'ReviewerSuite:WelfareAggregateRatio', ...
        'Country %s has a non-positive aggregate welfare ratio.',country);
    aggregate_cev = 100*(aggregate_ratio^(1/(1-sigma))-1);
end
result = [aggregate_cev;state_cev];
end


function transition = welfare_transition(job_finding,separation)
transition = zeros(10,10);
transition(1,1) = 1-separation*(1-job_finding);
transition(1,2) = separation*(1-job_finding);
for state = 2:8
    transition(state,1) = job_finding;
    transition(state,state+1) = 1-job_finding;
end
transition(9,1) = job_finding;
transition(9,10) = 1-job_finding;
transition(10,1) = job_finding;
transition(10,10) = 1-job_finding;
end


function index = require_name(names,name)
index = find(strcmp(names,name),1);
if isempty(index)
    error('ReviewerSuite:MissingWelfareInput', ...
        'Required welfare input is missing: %s.',name);
end
end


function value = first_value(path)
value = path(1);
end


function text = one_line(text)
text = regexprep(char(text),'[\r\n\t]+',' ');
text = regexprep(text,'\s+',' ');
text = strtrim(text);
end


function value = config_number(configuration,name,default)
value = default;
if isstruct(configuration) && isfield(configuration,name) ...
        && isnumeric(configuration.(name)) && isscalar(configuration.(name)) ...
        && isfinite(configuration.(name))
    value = double(configuration.(name));
end
end
