function output = write_current_calibration_exhibit(run_dir, output_dir, visible)
%WRITE_CURRENT_CALIBRATION_EXHIBIT Assemble Current Figures And Tables.
%   Reuses a solved transition; it never invokes Dynare.

arguments
    run_dir (1,:) char
    output_dir (1,:) char
    visible (1,1) logical = false
end

figure_dir = fullfile(output_dir,'figures');
table_dir = fullfile(output_dir,'tables');
assert(isfolder(figure_dir),'BaselineModel:MissingFigureDirectory', ...
    'Missing figure directory: %s',figure_dir);
assert(isfolder(table_dir),'BaselineModel:MissingTableDirectory', ...
    'Missing table directory: %s',table_dir);

saved = load(fullfile(run_dir,'Sim_H42_EB.mat'),'Sim_H42_EB');
names_data = load(fullfile(run_dir,'Names_H42_EB.mat'),'var_names','param_names','param_values');
sim = saved.Sim_H42_EB;
names = strtrim(cellstr(names_data.var_names));
parameters = strtrim(cellstr(names_data.param_names));
values = names_data.param_values;
report_columns = 1:size(sim,2)-1;
v = @(name) sim(require_series(names,name),report_columns)';
accounts = savings_accounts(sim,names_data.var_names,names_data.param_values, ...
    names_data.param_names,'a');

main_png = fullfile(run_dir,'baseline_home_economy.png');
main_fig = fullfile(run_dir,'baseline_home_economy.fig');
main_output_png = fullfile(figure_dir,'home_economy_main_3x3.png');
main_output_fig = fullfile(figure_dir,'home_economy_main_3x3.fig');
if isfile(main_png)
    copyfile(main_png,main_output_png,'f');
else
    main_output_png = '';
end
if isfile(main_fig)
    copyfile(main_fig,main_output_fig,'f');
else
    main_output_fig = '';
end

visibility = visible_token(visible);
[savings_png,savings_eps,savings_fig] = ...
    plot_savings_and_production(v,accounts,visibility,figure_dir,'cpi_rer');
[savings_ulc_png,savings_ulc_eps,savings_ulc_fig] = ...
    plot_savings_and_production(v,accounts,visibility,figure_dir,'ulc_and_cpi_rer');
[savings_ulc_only_png,savings_ulc_only_eps,savings_ulc_only_fig] = ...
    plot_savings_and_production(v,accounts,visibility,figure_dir,'ulc_only');
[labor_png,labor_eps,labor_fig] = ...
    plot_domestic_labor_market(v,visibility,figure_dir);
tex_path = write_exhibit_tex(output_dir,isfile(fullfile(figure_dir,'home_economy_main_3x3.png')));

output = struct('main_png',main_output_png,'main_fig',main_output_fig, ...
    'savings_png',savings_png,'savings_eps',savings_eps, ...
    'savings_fig',savings_fig,'savings_ulc_png',savings_ulc_png, ...
    'savings_ulc_eps',savings_ulc_eps,'savings_ulc_fig',savings_ulc_fig, ...
    'savings_ulc_only_png',savings_ulc_only_png, ...
    'savings_ulc_only_eps',savings_ulc_only_eps, ...
    'savings_ulc_only_fig',savings_ulc_only_fig, ...
    'labor_png',labor_png,'labor_eps',labor_eps, ...
    'labor_fig',labor_fig,'tex',tex_path);
end

function [png_path,eps_path,fig_path] = plot_savings_and_production( ...
        v,accounts,visibility,figure_dir,lower_left_panel)
last = min(141,numel(v('Y_a_t')));
q = (0:last-1)';
year = 2004+q/4;

fig = figure('Color','w','Visible',visibility,'Position',[100 100 1100 700]);
layout = tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');

make_panel(nexttile(layout),year,100*(accounts.household_cash_rate(1:last) ...
    -accounts.household_cash_rate(1))','Household Savings Rate', ...
    'Percentage-Point Change','k-',{});
make_panel(nexttile(layout),year,pct(v('C_a_t'),last),'Consumption and GNP', ...
    'Percent Deviation','k-',{'Consumption',pct(v('GNP_a_t'),last),'r--','GNP'});
make_panel(nexttile(layout),year,annual_output(v('CA_a_t'),v('Y_a_t'),last), ...
    'Current Account','Percent Of Initial Annual Output','k-',{});
if strcmp(lower_left_panel,'ulc_and_cpi_rer') || strcmp(lower_left_panel,'ulc_only')
    ulc_home = v('w_a_t')./(v('Y_a_t')./v('N_a_t'));
    ulc_foreign = v('w_b_t')./(v('Y_b_t')./v('N_b_t'));
    relative_ulc = ulc_home./ulc_foreign;
end
if strcmp(lower_left_panel,'ulc_and_cpi_rer')
    make_ulc_rer_panel(nexttile(layout),year,pct(relative_ulc,last), ...
        pct(v('rer_cpi_t'),last));
    stem = 'savings_and_production_selected_calibration_unit_labor_costs';
elseif strcmp(lower_left_panel,'ulc_only')
    make_panel(nexttile(layout),year,pct(relative_ulc,last), ...
        'Unit Labor Costs Relative to Foreign','Percent Deviation','k-',{});
    stem = 'savings_and_production_selected_calibration_unit_labor_costs_only';
elseif strcmp(lower_left_panel,'cpi_rer')
    make_panel(nexttile(layout),year,pct(v('rer_cpi_t'),last), ...
        'CPI Real Exchange Rate','Percent Deviation','k-',{});
    stem = 'savings_and_production_selected_calibration';
else
    error('BaselineModel:UnknownFigureTwoPanel', ...
        'Unknown Figure 2 lower-left panel selection: %s',lower_left_panel);
end
make_panel(nexttile(layout),year,pct(v('NT_a_t'),last), ...
    'Tradable/Nontradable Employment','Percent Response','b-', ...
    {'Tradable Employment',pct(v('NN_a_t'),last),'r-','Nontradable Employment'; ...
     [],log_pct(v('NT_a_t')./v('NN_a_t'),last),'k--','Relative T/NT Employment'});
make_panel(nexttile(layout),year,annual_output(v('NFA_a_t'),v('Y_a_t'),last), ...
    'Net Foreign Assets','Percent Of Initial Annual Output','k-',{});

png_path = fullfile(figure_dir,[stem '.png']);
eps_path = fullfile(figure_dir,[stem '.eps']);
fig_path = fullfile(figure_dir,[stem '.fig']);
exportgraphics(fig,png_path,'Resolution',600);
exportgraphics(fig,eps_path,'ContentType','vector');
savefig(fig,fig_path);
close(fig);
end

function [png_path,eps_path,fig_path] = plot_domestic_labor_market( ...
        v,visibility,figure_dir)
last = min(141,numel(v('N_a_t')));
q = (0:last-1)';
year = 2004+q/4;

fig = figure('Color','w','Visible',visibility,'Position',[100 100 900 700]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');

make_panel(nexttile(layout),year,pct(v('w_a_t'),last),'Wage', ...
    'Percent Deviation','k-',{});
make_panel(nexttile(layout),year,pct(v('V_a_t'),last),'Vacancies And Job-Finding Rate', ...
    'Percent Deviation','k-',{'Vacancies',pct(v('p_a_t'),last),'k--','Job-Finding Rate'});
employment = v('N_a_t');
unemployment_rate = 1-employment;
unemployment = 100*(unemployment_rate/unemployment_rate(1)-1);
make_panel(nexttile(layout),year,unemployment(1:last),'Unemployment Rate', ...
    'Percent Change','k-',{});

ax = nexttile(layout);
duration_names = {'mueu1_a_t','mueu4_a_t','mueu8_a_t','muuu_a_t'};
duration_labels = {'EU1','EU4','EU8','LTU'};
duration_styles = {'k-','k--','b-.','r:'};
hold(ax,'on');
for i = 1:numel(duration_names)
    plot(ax,year,log_pct(v(duration_names{i}),last),duration_styles{i}, ...
        'LineWidth',1.5,'DisplayName',duration_labels{i});
end
paper_zero_line(ax);
title(ax,'Unemployed By Duration'); xlabel(ax,'Year'); ylabel(ax,'Percent Deviation');
grid(ax,'on'); xlim(ax,[year(1) year(end)]); legend(ax,'Location','best');

png_path = fullfile(figure_dir,'domestic_labor_market_selected_calibration.png');
eps_path = fullfile(figure_dir,'domestic_labor_market_selected_calibration.eps');
fig_path = fullfile(figure_dir,'domestic_labor_market_selected_calibration.fig');
exportgraphics(fig,png_path,'Resolution',600);
exportgraphics(fig,eps_path,'ContentType','vector');
savefig(fig,fig_path);
close(fig);
end

function make_ulc_rer_panel(ax,year,relative_ulc,cpi_rer)
yyaxis(ax,'left');
ulc_line = plot(ax,year,relative_ulc,'k-','LineWidth',1.6, ...
    'DisplayName','Unit Labor Costs Relative to Foreign');
paper_zero_line(ax);
ylabel(ax,'ULC: Percent Deviation');
ax.YAxis(1).Color = [0 0 0];

yyaxis(ax,'right');
rer_line = plot(ax,year,cpi_rer,'r--','LineWidth',1.6, ...
    'DisplayName','CPI Real Exchange Rate');
paper_zero_line(ax);
ylabel(ax,'CPI-RER: Percent Deviation');
ax.YAxis(2).Color = [0.75 0.10 0.10];

title(ax,'Unit Labor Costs and CPI Real Exchange Rate');
xlabel(ax,'Year'); grid(ax,'on'); xlim(ax,[year(1) year(end)]);
legend(ax,[ulc_line rer_line],'Location','best');
end

function make_panel(ax,year,main,title_text,y_label,main_style,additional)
if isempty(additional)
    main_label = 'Response';
else
    main_label = additional{1};
end
plot(ax,year,main,main_style,'LineWidth',1.6,'DisplayName',main_label);
hold(ax,'on');
if ~isempty(additional)
    for row = 1:size(additional,1)
        label = additional{row,4};
        plot(ax,year,additional{row,2},additional{row,3},'LineWidth',1.5, ...
            'DisplayName',label);
    end
    legend(ax,'Location','best');
end
paper_zero_line(ax);
title(ax,title_text); xlabel(ax,'Year'); ylabel(ax,y_label);
grid(ax,'on'); xlim(ax,[year(1) year(end)]);
end

function path = write_exhibit_tex(output_dir,has_main_figure)
path = fullfile(output_dir,'current_calibration_figures_and_tables.tex');
fid = fopen(path,'w');
assert(fid>=0,'BaselineModel:Output','Could not write %s.',path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,['\\documentclass[11pt]{article}\n\\usepackage[margin=0.8in]{geometry}\n', ...
    '\\usepackage{graphicx}\n\\usepackage{booktabs}\n', ...
    '\\graphicspath{{figures/}}\n\\begin{document}\n', ...
    '\\begin{center}\\Large Current Calibration: Figures And Tables\\end{center}\n']);
if has_main_figure
    write_figure_tex(fid,'home_economy_main_3x3.png', ...
        'Home Economy Responses In The Selected Calibration.');
end
write_figure_tex(fid,'savings_and_production_selected_calibration.png', ...
    'Consequences Of The Benefit Reform For Savings And Production.');
write_figure_tex(fid,'domestic_labor_market_selected_calibration.png', ...
    'Consequences Of The Benefit Reform For The Domestic Labor Market.');
write_figure_tex(fid,'sector_level_employment.png', ...
    'Sector-Level Employment Responses In The Selected Calibration.');
write_figure_tex(fid,'foreign_economy_selected_calibration.png', ...
    'Effects Of The Home Reform On The Foreign Economy.');
write_figure_tex(fid,'fiscal_space_selected_calibration.png', ...
    'Government Fiscal Space In The Selected Calibration.');
fprintf(fid,'\\clearpage\n\\section*{Tables}\n');
table_files = {'long_run_reform_effects.tex','cev_by_group_and_country.tex', ...
    'model_contribution_2014.tex','current_calibration_snapshot.tex'};
for i = 1:numel(table_files)
    fprintf(fid,'\\input{tables/%s}\n\\clearpage\n',table_files{i});
end
fprintf(fid,'\\end{document}\n');
end

function write_figure_tex(fid,file_name,caption)
fprintf(fid,['\\begin{figure}[!htbp]\n\\centering\n', ...
    '\\includegraphics[width=0.98\\textwidth]{%s}\n', ...
    '\\caption{%s}\n\\end{figure}\n\\clearpage\n'],file_name,caption);
end

function value = pct(x,last)
value = 100*(x(1:last)/x(1)-1);
end

function value = log_pct(x,last)
value = 100*(log(x(1:last))-log(x(1)));
end

function value = annual_output(x,y,last)
value = 100*(x(1:last)-x(1))/(4*y(1));
end

function index = require_series(names,name)
index = find(strcmp(names,name),1);
assert(~isempty(index),'BaselineModel:MissingVariable','Missing %s.',name);
end

function token = visible_token(flag)
if flag, token = 'on'; else, token = 'off'; end
end
