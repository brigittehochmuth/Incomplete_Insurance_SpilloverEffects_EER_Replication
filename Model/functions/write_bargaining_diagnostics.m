function output = write_bargaining_diagnostics(run_dir, bargaining_spec)
%WRITE_BARGAINING_DIAGNOSTICS Export time-varying bargaining weights and values.

[mode_a,mode_b,continuation_a,continuation_b,convex_ltu_weight] = ...
    parse_specification(bargaining_spec);

sim_data = load(fullfile(run_dir,'Sim_H42_EB.mat'),'Sim_H42_EB');
names_data = load(fullfile(run_dir,'Names_H42_EB.mat'), ...
    'var_names','param_names','param_values');
names = strtrim(cellstr(names_data.var_names));
% The final column is the terminal boundary, consistent with the report plots.
columns = 1:size(sim_data.Sim_H42_EB,2)-1;

home = country_diagnostics(sim_data.Sim_H42_EB,names,columns,'a',mode_a, ...
    continuation_a,convex_ltu_weight,names_data.param_names, ...
    names_data.param_values,bargaining_spec);
foreign = country_diagnostics(sim_data.Sim_H42_EB,names,columns,'b',mode_b, ...
    continuation_b,convex_ltu_weight,names_data.param_names, ...
    names_data.param_values,bargaining_spec);

home_path = fullfile(run_dir,'bargaining_diagnostics_home.csv');
foreign_path = fullfile(run_dir,'bargaining_diagnostics_foreign.csv');
writetable(home,home_path);
writetable(foreign,foreign_path);

country = ["Home";"Foreign"];
mode = [mode_a;mode_b];
mode_label = string({bargaining_mode_name(mode_a);bargaining_mode_name(mode_b)});
maximum_surplus_identity_gap = [max(abs(home.SelectedSurplusGap)); ...
    max(abs(foreign.SelectedSurplusGap))];
maximum_population_share_gap = [max(abs(home.PopulationShareGap)); ...
    max(abs(foreign.PopulationShareGap))];
maximum_labor_force_identity_gap = [max(abs(home.LaborForceOutsideOptionGap)); ...
    max(abs(foreign.LaborForceOutsideOptionGap))];
maximum_nash_sharing_gap = [max(abs(home.NashSharingGap)); ...
    max(abs(foreign.NashSharingGap))];
minimum_unemployment_share = [min(home.UnemploymentShare); ...
    min(foreign.UnemploymentShare)];
summary = table(country,mode,mode_label,maximum_surplus_identity_gap, ...
    maximum_population_share_gap,maximum_labor_force_identity_gap, ...
    maximum_nash_sharing_gap,minimum_unemployment_share);
summary_path = fullfile(run_dir,'bargaining_diagnostics_summary.csv');
writetable(summary,summary_path);

output = struct('home',home,'foreign',foreign,'summary',summary, ...
    'home_csv',home_path,'foreign_csv',foreign_path,'summary_csv',summary_path);
save(fullfile(run_dir,'bargaining_diagnostics.mat'),'output');
end


function data = country_diagnostics(sim,names,columns,country,bargaining_mode, ...
    continuation_weight,convex_ltu_weight,param_names,param_values,spec)
v = @(stem) sim(require_name(names,sprintf('%s_%s_t',stem,country)),columns)';

employment = v('N');
short_term = zeros(numel(columns),8);
short_term_values = zeros(numel(columns),8);
for state = 1:8
    short_term(:,state) = v(sprintf('mueu%d',state));
    short_term_values(:,state) = v(sprintf('Weu%d',state));
end
long_term = v('muuu');
long_term_value = v('Wuu');
employment_value = v('We');
model_surplus = v('She');

unemployment = sum(short_term,2)+long_term;
membership = employment+unemployment;
if any(unemployment <= 0) || any(membership <= 0)
    error('BaselineModel:BargainingWeights', ...
        'Bargaining weights require positive unemployment and membership masses.');
end

weighted_unemployed_value = ...
    (sum(short_term.*short_term_values,2)+long_term.*long_term_value)./unemployment;
union_value = (employment.*short_term_values(:,1) ...
    +sum(short_term.*short_term_values,2)+long_term.*long_term_value)./membership;
current_value = short_term_values(:,1);
convex_value = (1-convex_ltu_weight)*current_value ...
    +convex_ltu_weight*long_term_value;

current_surplus = employment_value-current_value;
option_a_surplus = employment_value-weighted_unemployed_value;
option_b_surplus = employment_value-union_value;
convex_surplus = employment_value-convex_value;
continued_option_a_value = continuation_weight*weighted_unemployed_value ...
    +(1-continuation_weight)*union_value;
continued_option_a_surplus = employment_value-continued_option_a_value;
selected_values = {current_value,continued_option_a_value,union_value,convex_value};
selected_surpluses = {current_surplus,continued_option_a_surplus, ...
    option_b_surplus,convex_surplus};
selected_value = selected_values{bargaining_mode+1};
selected_surplus = selected_surpluses{bargaining_mode+1};

data = table((0:numel(columns)-1)',employment,unemployment, ...
    'VariableNames',{'Quarter','EmploymentShare','UnemploymentShare'});
for state = 1:8
    data.(sprintf('STU%dShare',state)) = short_term(:,state);
end
data.LTUShare = long_term;
for state = 1:8
    data.(sprintf('STU%dWeightAmongUnemployed',state)) = ...
        short_term(:,state)./unemployment;
end
data.LTUWeightAmongUnemployed = long_term./unemployment;
data.EmploymentWeightInUnion = employment./membership;
for state = 1:8
    data.(sprintf('STU%dWeightInUnion',state)) = short_term(:,state)./membership;
end
data.LTUWeightInUnion = long_term./membership;
data.EmploymentValue = employment_value;
data.STU1Value = current_value;
data.AllUnemployedOutsideOption = weighted_unemployed_value;
data.LaborForceWeightedOutsideOption = union_value;
data.UnionOutsideOption = union_value; % Legacy machine-readable alias only.
data.ConvexSTU1LTUOutsideOption = convex_value;
data.SelectedOutsideOption = selected_value;
data.CurrentSurplus = current_surplus;
data.OptionASurplus = option_a_surplus;
data.OptionBSurplus = option_b_surplus;
data.ConvexSurplus = convex_surplus;
data.ModelSurplus = model_surplus;
data.SelectedSurplusGap = model_surplus-selected_surplus;
data.PopulationShareGap = membership-1;
data.LaborForceOutsideOptionGap = union_value ...
    -(employment.*current_value+unemployment.*weighted_unemployed_value)./membership;

parameter_names = strtrim(cellstr(param_names));
p = @(name) param_values(require_parameter(parameter_names,name));
tauw = v('tauw');
lambdae = v('lambdae');
firm_surplus = v('Sf');
zeta = repmat(p(['xoui_' country]),numel(columns),1);
if isstruct(spec)
    pre_field = ['bargaining_power_pre_' country];
    post_field = ['bargaining_power_post_' country];
    if isfield(spec,pre_field)
        zeta(1) = spec.(pre_field);
    end
    if isfield(spec,post_field)
        zeta(2:end) = spec.(post_field);
    end
end
data.BargainingPower = zeta;
data.NashSharingGap = model_surplus ...
    -zeta./(1-zeta).*(1-tauw).*lambdae.*firm_surplus;
end


function index = require_name(names,name)
index = find(strcmp(names,name),1);
if isempty(index)
    error('BaselineModel:MissingBargainingVariable', ...
        'Required bargaining variable is missing: %s',name);
end
end


function label = bargaining_mode_name(mode)
labels = {'Current STU1','Option A All Unemployed', ...
    'Labor-Force-Weighted Collective Bargaining', ...
    'Convex STU1/LTU Fallback'};
label = labels{mode+1};
end


function [mode_a,mode_b,continuation_a,continuation_b,convex_weight] = ...
        parse_specification(spec)
if isstruct(spec)
    mode_a = field_or(spec,'bargaining_mode_a',field_or(spec,'bargaining_mode',0));
    mode_b = field_or(spec,'bargaining_mode_b',field_or(spec,'bargaining_mode',0));
    continuation_a = field_or(spec,'bargaining_continuation_weight_a', ...
        field_or(spec,'bargaining_continuation_weight',1));
    continuation_b = field_or(spec,'bargaining_continuation_weight_b', ...
        field_or(spec,'bargaining_continuation_weight',1));
    convex_weight = field_or(spec,'convex_ltu_weight',0.25);
else
    validateattributes(spec, {'numeric'}, ...
        {'scalar','real','finite','integer','>=',0,'<=',3});
    mode_a = spec; mode_b = spec;
    continuation_a = 1; continuation_b = 1; convex_weight = 0.25;
end
end


function value = field_or(source,name,fallback)
if isfield(source,name), value=source.(name); else, value=fallback; end
end


function index = require_parameter(names,name)
index = find(strcmp(names,name),1);
if isempty(index)
    error('BaselineModel:MissingBargainingParameter', ...
        'Required bargaining parameter is missing: %s',name);
end
end
