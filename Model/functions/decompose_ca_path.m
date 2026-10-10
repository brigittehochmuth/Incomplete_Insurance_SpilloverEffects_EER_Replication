function output = decompose_ca_path(run_dir, output_dir)
%DECOMPOSE_CA_PATH Decompose Home CA into interest and trade components.
% All reported flows are percentages of initial annual Home output. The
% identity checked is CA = interest + consumption exports + investment
% exports - consumption imports - investment imports.

if nargin < 2 || isempty(output_dir)
    output_dir = run_dir;
end
if ~isfolder(output_dir)
    mkdir(output_dir);
end

[sim, names, param_values, param_names] = load_run(run_dir);
v = @(name, columns) sim(require_name(names, name), columns);
p = @(name) param_values(require_name(param_names, name));

q = 1:40;
c = q + 1;
lag = c - 1;
annual_y0 = 4*v('Y_a_t', 1);
scale = 100/annual_y0;

ca = v('NFA_a_t', c)-v('NFA_a_t', lag);
anchor_active = read_anchor_mode(run_dir);
if anchor_active && any(strcmp(names, 'Rf_a_t'))
    external_return = v('Rf_a_t', c);
    return_label = 'Rf_a_t';
else
    external_return = v('R_w_t', lag);
    return_label = 'R_w_t(-1)';
end
interest = (external_return-1).*v('NFA_a_t', lag);

size_a = p('size_a');
ex_consumption = v('pH_t', c)./v('CPI_a_t', c) ...
    .*(1-size_a)/size_a.*v('cH_b_t', c);
ex_investment = v('pH_t', c)./v('CPI_a_t', c) ...
    .*(1-size_a)/size_a.*v('iH_b_t', c);
im_consumption = v('pF_t', c)./v('CPI_a_t', c).*v('cF_a_t', c);
im_investment = v('pF_t', c)./v('CPI_a_t', c).*v('iF_a_t', c);
nx = ex_consumption+ex_investment-im_consumption-im_investment;
residual = ca-interest-nx;
max_residual_share = max(abs(residual))/abs(annual_y0);
assert(max_residual_share < 1e-10, 'BaselineModel:CADecomposition', ...
    'CA decomposition residual %.12g exceeds 1e-10 of annual output.', ...
    max_residual_share);

T = table(q', scale*ca', scale*interest', scale*ex_consumption', ...
    scale*ex_investment', scale*im_consumption', scale*im_investment', ...
    scale*nx', scale*residual', scale*cumsum(ca)', ...
    'VariableNames', {'Quarter','CA','Interest','ConsumptionExports', ...
    'InvestmentExports','ConsumptionImports','InvestmentImports','NX', ...
    'Residual','CumulativeCA'});
csv_path = fullfile(output_dir, 'ca_decomposition_q1_40.csv');
writetable(T, csv_path);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1000 620]);
plot(q, T.CA, 'k-', 'LineWidth', 2); hold on;
plot(q, T.Interest, '-', 'Color', [0.75 0.20 0.15], 'LineWidth', 1.6);
plot(q, T.NX, '-', 'Color', [0.00 0.40 0.70], 'LineWidth', 1.6);
yline(0, ':', 'Color', [0.45 0.45 0.45]);
grid on; xlim([1 40]);
xlabel('Quarter'); ylabel('Percent of Initial Annual Output');
title('Home Current Account Decomposition');
legend({'Current Account','Net Interest','Net Exports'}, 'Location', 'best');
png_path = fullfile(output_dir, 'ca_decomposition_q1_40.png');
exportgraphics(fig, png_path, 'Resolution', 200);
close(fig);

impact_interest_share = NaN;
if abs(ca(1)) > eps
    impact_interest_share = interest(1)/ca(1);
end
cumulative_interest_share = NaN;
if abs(sum(ca)) > eps
    cumulative_interest_share = sum(interest)/sum(ca);
end
report_path = fullfile(output_dir, 'CA_DECOMPOSITION_REPORT.txt');
fid = fopen(report_path, 'w');
assert(fid >= 0, 'BaselineModel:ReportOpen', 'Could not open %s.', report_path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, 'Home Current Account Decomposition\n');
fprintf(fid, 'Run folder: %s\n', run_dir);
fprintf(fid, 'External return used: %s\n', return_label);
fprintf(fid, 'Impact CA: %.12g percent of initial annual output\n', T.CA(1));
fprintf(fid, 'Impact interest: %.12g percent of initial annual output\n', T.Interest(1));
fprintf(fid, 'Impact NX: %.12g percent of initial annual output\n', T.NX(1));
fprintf(fid, 'Impact interest share of CA: %.12g\n', impact_interest_share);
fprintf(fid, 'Cumulative q1-40 CA: %.12g percent of initial annual output\n', T.CumulativeCA(end));
fprintf(fid, 'Cumulative q1-40 interest share of CA: %.12g\n', cumulative_interest_share);
fprintf(fid, 'Maximum residual share of initial annual output: %.12g\n', max_residual_share);

output = struct('table',T,'csv_path',csv_path,'png_path',png_path, ...
    'report_path',report_path,'impact_interest_share',impact_interest_share, ...
    'cumulative_interest_share',cumulative_interest_share, ...
    'max_residual_share',max_residual_share,'anchor_active',anchor_active);
end

function [sim, names, param_values, param_names] = load_run(run_dir)
s = load(fullfile(run_dir, 'Sim_H42_EB.mat'), 'Sim_H42_EB');
n = load(fullfile(run_dir, 'Names_H42_EB.mat'), ...
    'var_names', 'param_values', 'param_names');
sim = s.Sim_H42_EB;
names = strtrim(cellstr(n.var_names));
param_values = n.param_values;
param_names = strtrim(cellstr(n.param_names));
assert(size(sim, 2) >= 42, 'BaselineModel:ShortPath', ...
    'Run must contain at least 40 simulated quarters.');
end

function active = read_anchor_mode(run_dir)
active = contains(run_dir, 'nfaAnchor1');
path = fullfile(run_dir, 'run_metadata.mat');
if exist(path, 'file') == 2
    loaded = load(path, 'result');
    if isfield(loaded, 'result') && isfield(loaded.result, 'configuration') ...
            && isfield(loaded.result.configuration, 'nfa_anchor_mode')
        active = logical(loaded.result.configuration.nfa_anchor_mode);
    end
end
end

function index = require_name(names, name)
index = find(strcmp(names, name), 1);
if isempty(index)
    error('BaselineModel:MissingName', 'Required model name not found: %s', name);
end
end
