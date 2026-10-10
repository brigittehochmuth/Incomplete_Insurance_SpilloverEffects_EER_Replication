function figure_ca_savings(SaveDir)
% Recreate Figure 4 from the retained 1991-2021 OECD/IMF plotting inputs.
% See data/figure4_oecd_imf_1991_2021.csv and ReadMe.md for provenance.

if nargin < 1
    SaveDir = fullfile(pwd, 'Results');
end

[~, FigureDir, ~] = get_results_paths(SaveDir);

code_dir = fileparts(mfilename('fullpath'));
input_file = fullfile(code_dir, 'data', 'figure4_oecd_imf_1991_2021.csv');

if ~isfile(input_file)
    error('Figure 4 input not found: %s', input_file);
end

inputs = readtable(input_file);
year = inputs.Year;
% The accepted current-account path was plotted to one decimal place.
current_account = round(inputs.CurrentAccount_OECD_MEI_Raw, 1);
savings = inputs.Savings_IMF_WEO_Apr2024;
assert(isequal(year(:), (1991:2021)'), ...
    'Figure 4 inputs must cover every year from 1991 through 2021 exactly once.');
assert(all(isfinite(current_account)) && all(isfinite(savings)), ...
    'Figure 4 inputs contain missing or nonfinite values.');

fig_tit = 'ca_savings1';
f = figure('Name', fig_tit);
set(f, ...
    'Color', [1 1 1], ...
    'Units', 'pixels', ...
    'Position', [100 100 1440 720], ...
    'PaperUnits', 'inches', ...
    'PaperPosition', [0 0 10 5], ...
    'PaperSize', [10 5], ...
    'PaperPositionMode', 'auto', ...
    'InvertHardcopy', 'off');

ax = axes('Parent', f, 'Units', 'normalized', 'Position', [0.14 0.17 0.72 0.68]);
set(ax, ...
    'FontName', 'Times', ...
    'FontSize', 9, ...
    'LineWidth', 1.0, ...
    'Box', 'on', ...
    'Layer', 'top', ...
    'TickDir', 'in', ...
    'TickLength', [0.01 0.01], ...
    'XColor', [0.20 0.20 0.20], ...
    'YColor', [0.20 0.20 0.20]);

yyaxis(ax, 'left')
h1 = plot(ax, year, current_account, '--', 'Color', [0 0 0], 'LineWidth', 1.45);
ylabel(ax, 'Current Account', 'FontName', 'Times', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.20 0.20 0.20]);
ylim(ax, [-5 10]);
yticks(ax, -5:5:10);
ax.YColor = [0.20 0.20 0.20];

yyaxis(ax, 'right')
h2 = plot(ax, year, savings, '-', 'Color', [0 0 0], 'LineWidth', 1.45);
ylabel(ax, 'Savings Rate', 'FontName', 'Times', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.20 0.20 0.20]);
ylim(ax, [20 35]);
yticks(ax, 20:5:35);
ax.YColor = [0.20 0.20 0.20];

xlim(ax, [1991 2021]);
xticks(ax, [1995 2000 2005 2010 2015 2020]);
xlabel(ax, 'Years', 'FontName', 'Times', 'FontSize', 11, 'FontWeight', 'bold');

grid(ax, 'on');
ax.GridColor = [0.85 0.85 0.85];
ax.GridAlpha = 0.8;

lgd = legend(ax, [h1 h2], ...
    {'Current Account (in Percent of GDP)', 'Savings Rate (in Percent of GDP)'}, ...
    'Location', 'northwest', ...
    'FontName', 'Times', ...
    'FontSize', 7, ...
    'Box', 'off', ...
    'Color', 'none');

lgd.Position(1) = lgd.Position(1) + 0.01;
lgd.Position(2) = lgd.Position(2) - 0.02;

print(fullfile(FigureDir, fig_tit), '-painters', '-depsc', '-r300');
print(fullfile(FigureDir, fig_tit), '-painters', '-dpng', '-r300');
end
