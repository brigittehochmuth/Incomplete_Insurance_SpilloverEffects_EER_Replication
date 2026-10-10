function metrics = sector_response_metrics(sim, names)
%SECTOR_RESPONSE_METRICS Exact dynamic counterparts to the sector estimates.

names = strtrim(cellstr(names));
v = @(name) sim(require_name(names,name),:);
last = size(sim,2)-1;
assert(last >= 41, 'BaselineModel:ShortSectorPath', ...
    'Sector diagnostics require at least 40 simulated quarters.');

nt = v('NT_a_t');
nn = v('NN_a_t');
yt = v('YT_a_t');
yn = v('YN_a_t');
qt = v('qT_a_t');
qn = v('qN_a_t');
private_value_demand = v('trdb_vs_nontrdb_a_t');

series = struct();
series.rel_emp_a_pct = 100*(log(nt./nn)-log(nt(1)/nn(1)));
series.NT_a_pct = 100*(nt/nt(1)-1);
series.NN_a_pct = 100*(nn/nn(1)-1);
series.rel_output_a_pct = 100*(log(yt./yn)-log(yt(1)/yn(1)));
series.rel_value_output_a_pct = 100*( ...
    log((qt.*yt)./(qn.*yn))-log((qt(1)*yt(1))/(qn(1)*yn(1))));
series.rel_private_value_demand_a_pct = 100*( ...
    log(private_value_demand)-log(private_value_demand(1)));

summary = struct();
summary = add_windows(summary,series.rel_emp_a_pct,'rel_emp_a');
summary = add_windows(summary,series.NT_a_pct,'NT_a');
summary = add_windows(summary,series.NN_a_pct,'NN_a');
summary = add_windows(summary,series.rel_output_a_pct,'rel_output_a');
summary = add_windows(summary,series.rel_value_output_a_pct,'rel_value_output_a');
summary = add_windows(summary,series.rel_private_value_demand_a_pct, ...
    'rel_private_value_demand_a');

summary.rel_emp_target_pct = 2.7;
summary.NT_soft_target_pct = 2.1;
summary.NN_soft_target_pct = -0.6;
for window = {'impact','q1_4_avg','q1_12_avg','q1_20_avg','q1_40_avg'}
    suffix = window{1};
    summary.(['rel_emp_a_' suffix '_distance_pct']) = ...
        summary.(['rel_emp_a_' suffix '_pct'])-summary.rel_emp_target_pct;
    summary.(['NT_a_' suffix '_distance_pct']) = ...
        summary.(['NT_a_' suffix '_pct'])-summary.NT_soft_target_pct;
    summary.(['NN_a_' suffix '_distance_pct']) = ...
        summary.(['NN_a_' suffix '_pct'])-summary.NN_soft_target_pct;
end

metrics = struct();
metrics.summary = summary;
metrics.series = series;
metrics.private_value_demand_report_label = ...
    'private_value_demand_T_over_N';
metrics.private_value_demand_definition = [ ...
    'Value of private demand for the Home tradable good divided by ' ...
    'private nontradable consumption and investment demand. It is not ' ...
    'an employment ratio and excludes some components of total absorption.'];
metrics.production_measure = 'gross sectoral output';
metrics.value_output_definition = [ ...
    'qT*YT relative to qN*YN. With no intermediate inputs in the ' ...
    'production block this is the closest sectoral value-output measure; ' ...
    'it is not labeled value added.'];
end

function output = add_windows(output,series,prefix)
output.([prefix '_impact_pct']) = series(2);
output.([prefix '_q1_4_avg_pct']) = mean(series(2:5));
output.([prefix '_q1_12_avg_pct']) = mean(series(2:13));
output.([prefix '_q1_20_avg_pct']) = mean(series(2:21));
output.([prefix '_q1_40_avg_pct']) = mean(series(2:41));
end

function index = require_name(names,name)
index = find(strcmp(names,name),1);
if isempty(index)
    error('BaselineModel:MissingName','Required model name not found: %s',name);
end
end
