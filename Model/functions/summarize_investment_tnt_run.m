function row = summarize_investment_tnt_run(run_dir, alpha_I, diagnostics)
%SUMMARIZE_INVESTMENT_TNT_RUN Build the requested one-row sensitivity summary.

sim_data = load(fullfile(run_dir, 'Sim_H42_EB.mat'), 'Sim_H42_EB');
name_data = load(fullfile(run_dir, 'Names_H42_EB.mat'), 'var_names');
sim = sim_data.Sim_H42_EB;
names = strtrim(cellstr(name_data.var_names));
v = @(name, columns) sim(require_name(names, name), columns);

q1_40 = 2:41;
y0_a = v('Y_a_t', 1);
simulation_columns = 2:size(sim, 2)-1;
ae_dev = 100*(v('ae_a_t', simulation_columns)/v('ae_a_t', 1)-1);
ca_path = v('CA_a_t', simulation_columns);
ca_q1_40 = v('CA_a_t', q1_40);
[ca_trough, ca_trough_quarter] = min(ca_q1_40);

row = struct();
row.alpha_I = alpha_I;
row.ae_a_impact_pct = ae_dev(1);
row.ae_a_sign_change_quarter = first_sign_change(ae_dev);
row.C_a_impact_pct = 100*(v('C_a_t', 2)/v('C_a_t', 1)-1);
row.I_a_impact_pct = 100*(v('I_a_t', 2)/v('I_a_t', 1)-1);
row.I_a_q1_40_avg_pct = mean(100*(v('I_a_t', q1_40)/v('I_a_t', 1)-1));
row.CA_a_impact_pct_initial_annual_output = 100*v('CA_a_t', 2)/(4*y0_a);
row.CA_a_q1_40_avg_pct_initial_annual_output = 100*mean(v('CA_a_t', q1_40))/(4*y0_a);
row.CA_a_trough_pct_initial_annual_output = 100*ca_trough/(4*y0_a);
row.CA_a_trough_quarter = ca_trough_quarter;
row.CA_a_negative_quarters_q1_40 = sum(ca_q1_40 < 0);
row.CA_a_positive_quarter = first_positive(ca_path);
row.NX_a_impact_pct_initial_annual_output = 100*v('NX_a_t', 2)/(4*y0_a);
row.EX_a_impact_pct_initial_annual_output = 100*v('EX_a_t', 2)/(4*y0_a);
row.IM_a_impact_pct_initial_annual_output = 100*v('IM_a_t', 2)/(4*y0_a);
row.net_interest_a_impact_pct_initial_annual_output = ...
    row.CA_a_impact_pct_initial_annual_output-row.NX_a_impact_pct_initial_annual_output;
row.iN_a_impact_share_of_I_pct = 100*v('iN_a_t', 2)/v('I_a_t', 2);
row.NFA_a_q40_change_pct_initial_annual_output = ...
    100*(v('NFA_a_t', 41)-v('NFA_a_t', 1))/(4*y0_a);
row.NFA_a_q160_change_pct_initial_annual_output = ...
    100*(v('NFA_a_t', 161)-v('NFA_a_t', 1))/(4*y0_a);

for land = {'a', 'b'}
    x = land{1};
    nt = 100*(v(['NT_' x '_t'],1:41)/v(['NT_' x '_t'],1)-1);
    nn = 100*(v(['NN_' x '_t'],1:41)/v(['NN_' x '_t'],1)-1);
    row.(['NT_' x '_years1_10_avg_pct']) = mean(nt(2:41));
    row.(['NN_' x '_years1_10_avg_pct']) = mean(nn(2:41));
    row.(['NT_minus_NN_' x '_years1_10_avg_pp']) = mean(nt(2:41)-nn(2:41));
    ratio = v(['NT_' x '_t'],1:41)./v(['NN_' x '_t'],1:41);
    row.(['rel_emp_' x '_years1_10_avg_pct']) = ...
        mean(100*(log(ratio(2:41))-log(ratio(1))));
end

sector_metrics = sector_response_metrics(sim,names);
sector_fields = fieldnames(sector_metrics.summary);
for i = 1:numel(sector_fields)
    row.(sector_fields{i}) = sector_metrics.summary.(sector_fields{i});
end
row.private_value_demand_report_label = ...
    string(sector_metrics.private_value_demand_report_label);

row.corr_t_q1_40_max_share = diagnostics.accounting.corr_q1_40_max_share;
row.gate0_pass = diagnostics_gate(diagnostics, 'gate0_pass', true);
row.gate1_pass = diagnostics.interior_convergence_pass;
row.gate2_pass = diagnostics.nfa_direction_pass;
row.gate3_pass = diagnostics.boundary_layer_pass;
row.existence_pass = diagnostics.existence_pass;
row.gate5_pass = diagnostics.accounting.identity_pass;
row.gate6_pass = diagnostics.accounting.corr_gate_pass;
row.all_gates_pass = diagnostics.all_pass;
row.run_dir = string(run_dir);
end

function value = parameter(run_dir, name)
pdata = load(fullfile(run_dir, 'Names_H42_EB.mat'), 'param_names', 'param_values');
pnames = strtrim(cellstr(pdata.param_names));
value = pdata.param_values(require_name(pnames, name));
end

function quarter = first_sign_change(path)
quarter = NaN;
initial_sign = sign(path(1));
if initial_sign == 0
    quarter = 1;
    return
end
index = find(sign(path(2:end)) ~= initial_sign, 1) + 1;
if ~isempty(index)
    quarter = index;
end
end

function quarter = first_positive(path)
quarter = find(path > 0, 1);
if isempty(quarter)
    quarter = NaN;
end
end

function value = diagnostics_gate(diagnostics, field, fallback)
if isfield(diagnostics, field)
    value = diagnostics.(field);
else
    value = fallback;
end
end

function index = require_name(names, name)
index = find(strcmp(names, name), 1);
if isempty(index)
    error('BaselineModel:MissingName', 'Required model name not found: %s', name);
end
end
