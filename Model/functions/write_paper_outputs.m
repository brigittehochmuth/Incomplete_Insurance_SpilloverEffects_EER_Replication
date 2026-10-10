function manifest = write_paper_outputs( ...
        suite_dir,rows,code_dir,output_scope,paper_dir)
%WRITE_PAPER_OUTPUTS Stable manuscript files from suite rows.

arguments
    suite_dir (1,:) char
    rows
    code_dir (1,:) char
    output_scope (1,:) char = 'all'
    paper_dir (1,:) char = ''
end

rows = normalize_rows(rows);
if isempty(paper_dir)
    paper_dir = fullfile(code_dir,'paper_outputs');
end
figure_dir = fullfile(paper_dir,'Figures');
table_dir = fullfile(paper_dir,'Tables');
ensure_folder(paper_dir); ensure_folder(figure_dir); ensure_folder(table_dir);

if strcmpi(output_scope,'main')
    figures = struct();
    figures.figure_11 = copy_wage_moderation_figure(suite_dir,figure_dir);
    tables = struct();
    tables.table_5 = write_contribution_comparison(rows,table_dir,code_dir, ...
        'Table_5_Model_Contributions', ...
        {'preferred_baseline','complete_insurance'}, ...
        {'Baseline','Complete Insurance (SGU 0.001)'}, ...
        'Model Contribution to Empirical Time Series in 2014 (Ten Years After the Reform)', ...
        ['Each entry reports the share of the observed empirical movement explained by the ' ...
         'model-implied average change in calendar year 2014. Complete insurance uses the ' ...
         'maintained SGU closure coefficient 0.001.'], ...
        '0.78\textwidth');
    manifest = struct('created',datestr(now,30), ...
        'scope','main','figures',figures,'tables',tables);
    manifest_path = fullfile(paper_dir,'robustness_output_manifest.json');
    write_json(manifest_path,manifest);
    manifest.path = manifest_path;
    return
end

if strcmpi(output_scope,'separation')
    figures = struct();
    figures.figure_21 = plot_separation_spillovers(rows,figure_dir,false);
    figures.figure_21_ulc = plot_separation_spillovers(rows,figure_dir,true);
    tables = struct();
    tables.table_13 = write_separation_spillovers(rows,table_dir);
    manifest = struct('created',datestr(now,30), ...
        'scope','separation','figures',figures,'tables',tables);
    return
end
assert(strcmpi(output_scope,'all'),'PaperOutputs:Scope', ...
    'output_scope must be ''main'', ''all'', or ''separation''.');

figures = struct();
figures.figure_20 = plot_pair(rows,'preferred_baseline','entitlement_only', ...
    figure_dir,'Figure_20_Entire_Reform_Vs_Entitlement_Cut', ...
    'Entire Reform Vs. Entitlement Cut Only', ...
    {'Entire Reform','Entitlement Cut Only'});
figures.figure_21 = plot_separation_spillovers(rows,figure_dir,false);
figures.figure_21_ulc = plot_separation_spillovers(rows,figure_dir,true);
figures.figure_23 = plot_pair(rows,'preferred_baseline','labor_tax_closure', ...
    figure_dir,'Figure_23_Lump_Sum_Vs_Labor_Tax', ...
    'Lump-Sum Tax Rule Vs. Labor-Tax Rule', ...
    {'Lump-Sum Tax Rule','Labor-Tax Rule'});
figures.bargaining_overlay = plot_pair(rows, ...
    'preferred_baseline','labor_force_weighted_fixed',figure_dir, ...
    'Appendix_Bargaining_Overlay_3x3', ...
    'Baseline Vs. Labor-Force-Weighted Bargaining', ...
    {'Baseline Bargaining','Labor-Force-Weighted Bargaining'}, ...
    'bargaining_six_panels');
figures.figure_22 = plot_asymmetric_foreign(rows,figure_dir);
figures.figure_11 = copy_wage_moderation_figure(suite_dir,figure_dir);
figures.figure_16 = plot_insurance_comparison(rows,figure_dir,'savings_rate');
figures.figure_16_household_wealth = ...
    plot_insurance_comparison(rows,figure_dir,'household_wealth');
figures.figure_17 = plot_insurance_capital_intensity(rows,figure_dir);
figures.insurance_comparison_overleaf = copy_figure_alias( ...
    figures.figure_16,figure_dir,'Insurance_Comparison_SGU_0p001');
figures.insurance_comparison_wealth_overleaf = copy_figure_alias( ...
    figures.figure_16_household_wealth,figure_dir, ...
    'Insurance_Comparison_Household_Wealth_SGU_0p001');
figures.insurance_capital_intensity_overleaf = copy_figure_alias( ...
    figures.figure_17,figure_dir,'Insurance_Capital_Intensity_SGU_0p001');

tables = struct();
tables.table_5 = write_contribution_comparison(rows,table_dir,code_dir, ...
    'Table_5_Model_Contributions', ...
    {'preferred_baseline','complete_insurance'}, ...
    {'Baseline','Complete Insurance (SGU 0.001)'}, ...
    'Model Contribution to Empirical Time Series in 2014 (Ten Years After the Reform)', ...
    ['Each entry reports the share of the observed empirical movement explained by the ' ...
     'model-implied average change in calendar year 2014. Complete insurance uses the ' ...
     'maintained SGU closure coefficient 0.001.'], ...
    '0.78\textwidth');
tables.table_9 = write_contribution_comparison(rows,table_dir,code_dir, ...
    'Table_9_Bargaining_Power_Robustness', ...
    {'preferred_baseline','zeta_low_040','zeta_high_060'}, ...
    {'Baseline','$\zeta=0.4$','$\zeta=0.6$'}, ...
    'Bargaining-Power Robustness: Model Contribution to Empirical Time Series in 2014', ...
    ['Each entry reports the share of the observed empirical movement explained by the ' ...
     'model-implied average change in calendar year 2014. The robustness columns change ' ...
     'worker bargaining power to the displayed value while keeping the reform cut and ' ...
     'all other baseline settings fixed.'], ...
    '0.88\textwidth');
tables.table_11 = write_asymmetric_long_run_case(rows,table_dir, ...
    'asymmetric_foreign_ui','Table_11_Asymmetric_UI_Long_Run', ...
    'Long-Run Effects for the Asymmetric UI Case');
tables.table_12 = write_welfare_case(rows,table_dir,'labor_tax_closure', ...
    'Table_12_Labor_Tax_CEV', ...
    'Consumption Equivalent Variation (CEV) by Group and Country: Labor Tax Fiscal Rule');
tables.table_13 = write_separation_spillovers(rows,table_dir);

manifest = struct('created',datestr(now,30),'suite_dir',suite_dir, ...
    'baseline_contract',struct('reform_cut',0.37891718657, ...
        'chi_T',1.0,'chi_NT',3.5,'investment_adjustment_cost',8.7, ...
        'entitlement_cut_periods',4,'bargaining','STU1'), ...
    'figures',figures,'tables',tables);
manifest_path = fullfile(paper_dir,'robustness_output_manifest.json');
write_json(manifest_path,manifest);
manifest.path = manifest_path;
end


function output = plot_pair(rows,id_a,id_b,figure_dir,stem,title_text,labels,panel_scope)
if nargin < 8, panel_scope = 'full'; end
output = unavailable('Required scenario paths are unavailable.');
[a,ok_a] = row_by_id(rows,id_a); [b,ok_b] = row_by_id(rows,id_b);
if ~ok_a || ~ok_b || ~path_ok(a) || ~path_ok(b), return; end

if strcmp(panel_scope,'bargaining_six_panels')
    specs = { ...
        'WagePct','Wage','Percent Deviation'; ...
        'HouseholdCashSavingPP','Household Savings Rate','Percentage-Point Change'; ...
        'EmploymentPct','Employment','Percent Deviation'; ...
        'ConsumptionPct','Consumption','Percent Deviation'; ...
        'RelativeTNEmploymentPct','T/NT Employment','Percent Deviation'; ...
        'NFAChangePctAnnualOutput','Net Foreign Assets','Percent of Initial Annual Output'};
    figure_position = [50 40 1450 720];
    layout_shape = [2 3];
else
    specs = { ...
        'WagePct','Wage','Percent Deviation'; ...
        'HouseholdCashSavingPP','Household Savings Rate','Percentage-Point Change'; ...
        'EmploymentPct','Employment','Percent Deviation'; ...
        'ConsumptionPct','Consumption','Percent Deviation'; ...
        'InvestmentPct','Investment','Percent Deviation'; ...
        'RelativeTNEmploymentPct','T/NT Employment','Percent Deviation'; ...
        'RERPct','Real Exchange Rate','Percent Deviation'; ...
        'CAPctAnnualOutput','Current Account','Percent of Initial Annual Output'; ...
        'NFAChangePctAnnualOutput','Net Foreign Assets','Percent of Initial Annual Output'};
    figure_position = [50 40 1450 1050];
    layout_shape = [3 3];
end
colors = [0.10 0.30 0.62;0.78 0.24 0.18];
styles = {'-','--'}; selected = [a;b];
fig = figure('Color','w','Visible','off','Position',figure_position);
layout = tiledlayout(fig,layout_shape(1),layout_shape(2), ...
    'TileSpacing','compact','Padding','compact');
for p = 1:size(specs,1)
    ax = nexttile(layout); hold(ax,'on'); handles = gobjects(2,1);
    for s = 1:2
        t = selected(s).path_table;
        use = t.Quarter <= 50;
        handles(s) = plot(ax,t.Quarter(use),t.(specs{p,1})(use), ...
            'Color',colors(s,:),'LineStyle',styles{s},'LineWidth',1.8, ...
            'DisplayName',labels{s});
    end
    paper_zero_line(ax); grid(ax,'on'); box(ax,'off');
    title(ax,specs{p,2}); xlabel(ax,'Quarter'); ylabel(ax,specs{p,3});
    if p == 1, legend(ax,handles,labels,'Location','best'); end
end
output = export_figure(fig,figure_dir,stem,{id_a,id_b});
close(fig);
end


function output = plot_separation_spillovers(rows,figure_dir,use_unit_labor_costs)
if nargin < 3, use_unit_labor_costs = false; end
if use_unit_labor_costs
    stem = 'Figure_21_Separation_Rate_Decline_Unit_Labor_Costs';
else
    stem = 'Figure_21_Separation_Rate_Decline';
end
output = unavailable('The immediate target-matched separation-rate transition is unavailable.');
[baseline,ok_baseline] = row_by_id(rows,'preferred_baseline');
[immediate,ok_immediate] = row_by_id( ...
    rows,'separation_decline');
if ~ok_baseline || ~ok_immediate ...
        || ~path_ok(baseline) || ~path_ok(immediate)
    return
end
try
    paths = {separation_figure_paths(char(baseline.run_dir),false); ...
        separation_figure_paths(char(immediate.run_dir),true)};
catch ME
    output.message = string(ME.message);
    return
end
labels = {'Baseline','Immediate Separation Decline'};
colors = [0.10 0.30 0.62;0.78 0.24 0.18];
styles = {'-','--'};
if use_unit_labor_costs
    lower_left_panel = {'RelativeULCPct','Unit Labor Costs Relative to Foreign', ...
        'Percent Deviation'};
else
    lower_left_panel = {'RERPct','Real Exchange Rate','Percent Deviation'};
end
specs = { ...
    'SeparationRatePct','Separation Rate','Percent Change'; ...
    'HouseholdWealthPct','Household Wealth','Percent Deviation'; ...
    'ConsumptionPct','Consumption','Percent Deviation'; ...
    'GNPPct','GNP','Percent Deviation'; ...
    lower_left_panel{:}; ...
    'RelativeTNEmploymentPct','Tradable Minus Non-Tradable Employment', ...
        'Percentage-Point Difference'; ...
    'COMPONENTS','Tradable and Non-Tradable Employment','Percent Deviation'; ...
    'NFAChangePctAnnualOutput','Net Foreign Assets', ...
        'Percent of Initial Annual Output'};
fig = figure('Color','w','Visible','off','Position',[35 40 1550 770]);
layout = tiledlayout(fig,2,4,'TileSpacing','compact','Padding','compact');
for p = 1:size(specs,1)
    ax = nexttile(layout);
    hold(ax,'on');
    use = paths{1}.Quarter <= 140;
    if strcmp(specs{p,1},'COMPONENTS')
        component_handles = gobjects(4,1);
        component_handles(1) = plot(ax,paths{1}.Year(use), ...
            paths{1}.TradableEmploymentPct(use), ...
            'Color',colors(1,:),'LineStyle','-','LineWidth',1.8, ...
            'DisplayName','Baseline: T');
        component_handles(2) = plot(ax,paths{1}.Year(use), ...
            paths{1}.NonTradableEmploymentPct(use), ...
            'Color',colors(1,:),'LineStyle',':','LineWidth',2.0, ...
            'DisplayName','Baseline: NT');
        component_handles(3) = plot(ax,paths{2}.Year(use), ...
            paths{2}.TradableEmploymentPct(use), ...
            'Color',colors(2,:),'LineStyle','--','LineWidth',1.8, ...
            'DisplayName','Immediate: T');
        component_handles(4) = plot(ax,paths{2}.Year(use), ...
            paths{2}.NonTradableEmploymentPct(use), ...
            'Color',colors(2,:),'LineStyle','-.','LineWidth',1.8, ...
            'DisplayName','Immediate: NT');
        legend(ax,component_handles,'Location','best','Box','off', ...
            'FontSize',7.5);
    else
        handles = gobjects(2,1);
        for s = 1:2
            handles(s) = plot(ax,paths{s}.Year(use), ...
                paths{s}.(specs{p,1})(use), ...
                'Color',colors(s,:),'LineStyle',styles{s}, ...
                'LineWidth',1.9,'DisplayName',labels{s});
        end
        if p == 1
            legend(ax,handles,labels,'Location','best','Box','off', ...
                'FontSize',8);
        end
    end
    format_separation_axis(ax,specs{p,2},specs{p,3});
end
output = export_figure(fig,figure_dir,stem, ...
    {'preferred_baseline','separation_decline'});
close(fig);
end


function format_separation_axis(ax,title_text,y_label)
paper_zero_line(ax); grid(ax,'on'); box(ax,'off');
set(ax,'FontName','Times New Roman','FontSize',9.5, ...
    'XLim',[2005 2040],'XTick',2005:5:2040,'TickDir','out', ...
    'XGrid','off','GridColor',[0.85 0.85 0.85], ...
    'GridAlpha',0.45);
title(ax,title_text); xlabel(ax,'Year'); ylabel(ax,y_label);
end


function t = separation_figure_paths(run_dir,is_immediate)
s = load(fullfile(run_dir,'Sim_H42_EB.mat'),'Sim_H42_EB');
n = load(fullfile(run_dir,'Names_H42_EB.mat'), ...
    'var_names','param_names','param_values');
sim = s.Sim_H42_EB;
names = strtrim(cellstr(n.var_names));
columns = 1:size(sim,2)-1;
v = @(name) sim(require_name(names,name),columns)';
accounts = scenario_savings_accounts(run_dir,sim,n.var_names, ...
    n.param_values,n.param_names,'a');
quarter = (0:numel(v('N_a_t'))-1)';
year = 2005+quarter/4;
separation_rate = zeros(size(quarter));
if is_immediate
    separation_rate(quarter>=1) = -22;
end
household_wealth = 100*(accounts.total_household_wealth(:) ...
    /accounts.total_household_wealth(1)-1);
consumption = pct(v('C_a_t'));
gnp = pct(v('GNP_a_t'));
rer = pct(v('rer_cpi_t'));
ulc_home = v('w_a_t')./(v('Y_a_t')./v('N_a_t'));
ulc_foreign = v('w_b_t')./(v('Y_b_t')./v('N_b_t'));
relative_ulc = pct(ulc_home./ulc_foreign);
tradable_employment = pct(v('NT_a_t'));
nontradable_employment = pct(v('NN_a_t'));
relative_employment = tradable_employment-nontradable_employment;
nfa = v('NFA_a_t');
output = v('Y_a_t');
nfa_change = 100*(nfa-nfa(1))/(4*output(1));
t = table(quarter,year,separation_rate,household_wealth,consumption, ...
    gnp,rer,relative_ulc,relative_employment,tradable_employment, ...
    nontradable_employment,nfa_change, ...
    'VariableNames',{'Quarter','Year','SeparationRatePct', ...
    'HouseholdWealthPct','ConsumptionPct','GNPPct','RERPct', ...
    'RelativeULCPct', ...
    'RelativeTNEmploymentPct','TradableEmploymentPct', ...
    'NonTradableEmploymentPct','NFAChangePctAnnualOutput'});
end


function output = plot_asymmetric_foreign(rows,figure_dir)
stem = 'Figure_22_Asymmetric_UI_Foreign_Economy';
output = unavailable('The asymmetric-UI transition is unavailable.');
[row,ok] = row_by_id(rows,'asymmetric_foreign_ui');
if ~ok || ~path_ok(row), return; end
try
    t = foreign_paths(char(row.run_dir));
catch ME
    output.message = string(ME.message); return
end
fig = figure('Color','w','Visible','off','Position',[50 40 1200 800]);
layout = tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
use = t.Quarter <= 140;

ax = nexttile(layout);
plot(ax,t.Year(use),t.CashSavingsRateChangePP(use),'k-','LineWidth',1.8);
format_asymmetric_axis(ax,'Household Savings Rate','Percentage-Point Change');

ax = nexttile(layout); hold(ax,'on');
plot(ax,t.Year(use),t.ConsumptionPct(use),'k-','LineWidth',1.8, ...
    'DisplayName','Consumption');
plot(ax,t.Year(use),t.GNPPct(use),'k--','LineWidth',1.8, ...
    'DisplayName','GNP');
format_asymmetric_axis(ax,'Consumption and GNP','Percent Deviation');
legend(ax,'Location','best','Box','off');

ax = nexttile(layout);
plot(ax,t.Year(use),t.CurrentAccountPctAnnualOutput(use), ...
    'k-','LineWidth',1.8);
format_asymmetric_axis(ax,'Current Account', ...
    'Percent of Initial Annual Output');

ax = nexttile(layout);
plot(ax,t.Year(use),t.InterestRatePP(use),'k-','LineWidth',1.8);
format_asymmetric_axis(ax,'Interest Rate','Percentage-Point Change');

ax = nexttile(layout);
plot(ax,t.Year(use),t.WagePct(use),'k-','LineWidth',1.8);
format_asymmetric_axis(ax,'Wages','Percent Deviation');

ax = nexttile(layout);
plot(ax,t.Year(use),t.UnemploymentPct(use),'k-','LineWidth',1.8);
format_asymmetric_axis(ax,'Unemployment Rate','Percent Change');

output = export_figure(fig,figure_dir,stem,{'asymmetric_foreign_ui'});
close(fig);
end


function format_asymmetric_axis(ax,title_text,y_label)
paper_zero_line(ax); grid(ax,'on'); box(ax,'off');
set(ax,'FontName','Times New Roman','FontSize',10, ...
    'XLim',[2005 2040],'XTick',2005:5:2040,'TickDir','out', ...
    'XGrid','off','GridColor',[0.85 0.85 0.85], ...
    'GridAlpha',0.45);
title(ax,title_text); xlabel(ax,'Year'); ylabel(ax,y_label);
end


function output = copy_wage_moderation_figure(suite_dir,figure_dir)
source_dir = fullfile(suite_dir,'paper_figures');
source_stem = fullfile(source_dir,'ui_reform_vs_wage_moderation');
target_stem = fullfile(figure_dir,'Figure_11_UI_Reform_Vs_Wage_Moderation');
output = unavailable('The wage-moderation figure is unavailable.');
extensions = {'.png','.pdf','.eps','.fig'};
if ~all(cellfun(@(x) isfile([source_stem x]),extensions)), return; end
for i = 1:numel(extensions)
    copyfile([source_stem extensions{i}],[target_stem extensions{i}],'f');
end
output = struct('available',true,'message',"", ...
    'png',[target_stem '.png'],'pdf',[target_stem '.pdf'], ...
    'eps',[target_stem '.eps'],'fig',[target_stem '.fig'],'scenarios', ...
    {{'preferred_baseline','wage_moderation_post_only'}});
end


function output = write_contribution_comparison(rows,table_dir,code_dir, ...
    stem,ids,labels,caption,notes,width)
indicator = strings(0,1); values = NaN(0,numel(ids)); available = false(1,numel(ids));
for i = 1:numel(ids)
    [row,ok] = row_by_id(rows,ids{i});
    if ~ok || ~path_ok(row), continue; end
    try
        t = contribution_from_run(char(row.run_dir),code_dir);
        if isempty(indicator)
            indicator = string(t.Indicator); values = NaN(height(t),numel(ids));
        end
        values(:,i) = t.ContributionPercent; available(i) = true;
    catch
        available(i) = false;
    end
end
csv_path = fullfile(table_dir,[stem '.csv']);
tex_path = fullfile(table_dir,[stem '.tex']);
data = table(indicator,'VariableNames',{'Indicator'});
for i = 1:numel(ids)
    data.(matlab.lang.makeValidName(ids{i})) = values(:,i);
end
writetable(data,csv_path);
fid = fopen(tex_path,'w'); assert(fid>=0,'PaperOutputs:ContributionTable','Could not write %s.',tex_path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'\\begin{table}[!htbp]\n\\centering\n');
fprintf(fid,'\\caption{%s}\n',caption);
fprintf(fid,'\\label{%s}\n\\resizebox{%s}{!}{%%\n', ...
    strrep(lower(stem),'_','-'),width);
fprintf(fid,'\\begin{tabular}{l%s}\n\\toprule\nIndicator',repmat('r',1,numel(ids)));
for i=1:numel(labels), fprintf(fid,' & %s',labels{i}); end
fprintf(fid,' \\\\');
fprintf(fid,'\n\\midrule\n');
for r=1:numel(indicator)
    fprintf(fid,'%s',char(indicator(r)));
    for c=1:numel(ids)
        if isfinite(values(r,c)), fprintf(fid,' & %.1f\\%%',values(r,c));
        else, fprintf(fid,' & --'); end
    end
    fprintf(fid,' \\\\');
    fprintf(fid,'\n');
end
fprintf(fid,'\\bottomrule\n\\end{tabular}}\n');
fprintf(fid,'\\begin{flushleft}\\footnotesize \\textit{Notes:} %s\\end{flushleft}\n',notes);
fprintf(fid,'\\end{table}\n');
output = struct('csv',csv_path,'tex',tex_path,'scenario_ids',{ids}, ...
    'available',available);
end


function t = contribution_from_run(run_dir,code_dir)
s = load(fullfile(run_dir,'Sim_H42_EB.mat'),'Sim_H42_EB');
n = load(fullfile(run_dir,'Names_H42_EB.mat'),'var_names','param_names','param_values');
sim=s.Sim_H42_EB; names=strtrim(cellstr(n.var_names)); columns=1:size(sim,2)-1;
v=@(name) sim(require_name(names,name),columns)';
accounts_a=scenario_savings_accounts(run_dir,sim,n.var_names, ...
    n.param_values,n.param_names,'a');
accounts_b=scenario_savings_accounts(run_dir,sim,n.var_names, ...
    n.param_values,n.param_names,'b');
cash_a=100*(accounts_a.household_cash_rate-accounts_a.household_cash_rate(1))';
cash_b=100*(accounts_b.household_cash_rate-accounts_b.household_cash_rate(1))';
emp=readtable(fullfile(code_dir,'empirical_data.csv'));
base=emp(emp.year==2004,:); target=emp(emp.year==2014,:); q=38:41;
avg=@(x) mean(x(q)); u=1-v('N_a_t'); unemployment=100*(u/u(1)-1);
nfa_level=v('NFA_a_t'); output_level=v('Y_a_t'); ca_level=v('CA_a_t');
nfa=100*(nfa_level./(4*output_level)-nfa_level(1)/(4*output_level(1)));
ca=100*(ca_level./output_level-ca_level(1)/output_level(1));
ulc=100*((v('w_a_t')./(v('Y_a_t')./v('N_a_t'))) ./ ...
    (v('w_b_t')./(v('Y_b_t')./v('N_b_t')))-1);
model=[avg(unemployment);avg(cash_a);avg(nfa);avg(ca);avg(ca);avg(ulc);avg(cash_b)];
denom=[100*(target.unemployment_rate-base.unemployment_rate)/base.unemployment_rate; ...
    target.savings_rate_soep_percent-base.savings_rate_soep_percent; ...
    target.NFA_percent_GDP-base.NFA_percent_GDP;target.CA_percent_GDP; ...
    target.CA_Euro_percent_GDP;target.ULC_relative_EZ; ...
    target.savings_rate_EZ-base.savings_rate_EZ];
indicator={'Unemployment';'Private Savings Rate';'Net Foreign Assets/GDP'; ...
    'Current Account/GDP';'Current Account vis-a-vis Eurozone/GDP'; ...
    'Unit Labor Costs Relative to Eurozone';'Private Savings Rate Rest of Eurozone'};
t=table(indicator,100*model./denom,'VariableNames',{'Indicator','ContributionPercent'});
end


function output = write_long_run_case(rows,table_dir,id,stem,caption)
[row,ok] = row_by_id(rows,id); csv_path=fullfile(table_dir,[stem '.csv']); tex_path=fullfile(table_dir,[stem '.tex']);
if ~ok || ~isfield(row,'long_run') || ~istable(row.long_run)
    output=unavailable('Long-run results are unavailable.'); return
end
t=row.long_run; writetable(t,csv_path);
metrics=unique(string(t.Metric),'stable'); fid=fopen(tex_path,'w'); assert(fid>=0,'PaperOutputs:LongRun','Could not write %s.',tex_path); cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'\\begin{table}[!htbp]\n\\centering\n\\caption{%s}\n',caption);
fprintf(fid,'\\label{%s}\n\\resizebox{0.62\\textwidth}{!}{\\begin{tabular}{lrr}\n\\toprule\n & Home & Foreign \\\\',strrep(lower(stem),'_','-'));
fprintf(fid,'\n\\midrule\n');
for i=1:numel(metrics)
    home=case_value(t,metrics(i),'Home'); foreign=case_value(t,metrics(i),'Foreign');
    fprintf(fid,'%s & %s & %s \\\\',char(metrics(i)),num_or_dash(home),num_or_dash(foreign));
    fprintf(fid,'\n');
end
fprintf(fid,'\\bottomrule\n\\end{tabular}}\n\\end{table}\n');
output=struct('csv',csv_path,'tex',tex_path,'available',true);
end


function output = write_asymmetric_long_run_case(rows,table_dir,id,stem,caption)
[row,ok] = row_by_id(rows,id);
csv_path = fullfile(table_dir,[stem '.csv']);
tex_path = fullfile(table_dir,[stem '.tex']);
if ~ok || ~path_ok(row)
    output = unavailable('The asymmetric-UI saved transition is unavailable.');
    return
end
try
    t = asymmetric_steady_state_table(char(row.run_dir));
catch ME
    output = unavailable(string(ME.message));
    return
end
writetable(t,csv_path);
fid = fopen(tex_path,'w');
assert(fid >= 0,'PaperOutputs:AsymmetricLongRun', ...
    'Could not write %s.',tex_path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'\\begin{table}[!htbp]\n\\centering\n\\caption{%s}\n',caption);
fprintf(fid,'\\label{%s}\n',strrep(lower(stem),'_','-'));
fprintf(fid,'\\resizebox{0.62\\textwidth}{!}{\\begin{tabular}{lrr}\n');
fprintf(fid,'\\toprule\n & Home & Foreign \\\\\n\\midrule\n');
for i = 1:height(t)
    home = t.Home(i); foreign = t.Foreign(i);
    if abs(home) < 0.005, home = 0; end
    if abs(foreign) < 0.005, foreign = 0; end
    fprintf(fid,'%s & %.2f & %.2f \\\\\n', ...
        t.Indicator{i},home,foreign);
    if ismember(i,[4 7 12])
        fprintf(fid,'\\midrule\n');
    end
end
fprintf(fid,'\\bottomrule\n\\end{tabular}}\n');
fprintf(fid,['\\begin{flushleft}\\footnotesize Notes: Changes compare the saved ' ...
    'post-reform steady state with the saved asymmetric pre-reform steady ' ...
    'state. The interest rate and NFA/output are percentage-point changes; ' ...
    'all other entries are percent deviations.\\end{flushleft}\n']);
fprintf(fid,'\\end{table}\n');
output = struct('csv',csv_path,'tex',tex_path,'available',true, ...
    'comparison','post_vs_pre_steady_state','run_dir',char(row.run_dir));
end


function t = asymmetric_steady_state_table(run_dir)
pre_names_data = load(fullfile(run_dir,'Names.mat'),'var_names');
pre_data = load(fullfile(run_dir,'SS_init.mat'),'SS_init');
post_names_data = load(fullfile(run_dir,'Names_H42_EB.mat'),'var_names');
post_data = load(fullfile(run_dir,'SS_H42_EB.mat'),'SS_H42_EB');
pre_names = strtrim(cellstr(pre_names_data.var_names));
post_names = strtrim(cellstr(post_names_data.var_names));
pre_values = pre_data.SS_init(:);
post_values = post_data.SS_H42_EB(:);
pre = @(name) pre_values(require_name(pre_names,name));
post = @(name) post_values(require_name(post_names,name));
indicator = { ...
    'GDP';'GNP';'Aggr. Consumption';'Unemployment Rate Change'; ...
    'C: Tradable';'C: Non-Tradable'; ...
    'Tradable-to-non-tradable expenditure ratio'; ...
    'CPI';'TPI';'Wage';'Interest Rate';'Real Exchange Rate'; ...
    'Capital-Labor Ratio';'NFA/Output'};
home = asymmetric_country_steady_effects(pre,post,'a',false);
foreign = asymmetric_country_steady_effects(pre,post,'b',true);
unit = repmat({'Percent Deviation'},numel(indicator),1);
unit(ismember(indicator,{'Interest Rate','NFA/Output'})) = ...
    {'Percentage Points'};
t = table(indicator,home,foreign,unit, ...
    'VariableNames',{'Indicator','Home','Foreign','Unit'});
end


function values = asymmetric_country_steady_effects( ...
    pre,post,country,invert_rer)
pct_change = @(post_level,pre_level) 100*(post_level/pre_level-1);
employment_pre = pre(['N_' country '_t']);
employment_post = post(['N_' country '_t']);
output_pre = pre(['Y_' country '_t']);
output_post = post(['Y_' country '_t']);
rer_pre = pre('rer_cpi_t');
rer_post = post('rer_cpi_t');
if invert_rer
    rer_change = pct_change(1/rer_post,1/rer_pre);
else
    rer_change = pct_change(rer_post,rer_pre);
end
values = [ ...
    pct_change(output_post,output_pre); ...
    pct_change(post(['GNP_' country '_t']),pre(['GNP_' country '_t'])); ...
    pct_change(post(['C_' country '_t']),pre(['C_' country '_t'])); ...
    100*((1-employment_post)-(1-employment_pre))/(1-employment_pre); ...
    pct_change(post(['cT_' country '_t']),pre(['cT_' country '_t'])); ...
    pct_change(post(['cN_' country '_t']),pre(['cN_' country '_t'])); ...
    pct_change(post(['trdb_vs_nontrdb_' country '_t']), ...
        pre(['trdb_vs_nontrdb_' country '_t'])); ...
    pct_change(post(['CPI_' country '_t']),pre(['CPI_' country '_t'])); ...
    pct_change(post(['TPI_' country '_t']),pre(['TPI_' country '_t'])); ...
    pct_change(post(['w_' country '_t']),pre(['w_' country '_t'])); ...
    100*(post('R_w_t')-pre('R_w_t')); ...
    rer_change; ...
    pct_change(post(['k_' country '_t'])/employment_post, ...
        pre(['k_' country '_t'])/employment_pre); ...
    100*(post(['NFA_' country '_t'])/(4*output_post) ...
        -pre(['NFA_' country '_t'])/(4*output_pre))];
end


function output = write_welfare_case(rows,table_dir,id,stem,caption)
[row,ok]=row_by_id(rows,id); csv_path=fullfile(table_dir,[stem '.csv']); tex_path=fullfile(table_dir,[stem '.tex']);
if ~ok || ~isfield(row,'welfare') || ~istable(row.welfare)
    output=unavailable('Welfare results are unavailable.'); return
end
t=row.welfare; writetable(t,csv_path); groups=unique(string(t.Group),'stable');
fid=fopen(tex_path,'w'); assert(fid>=0,'PaperOutputs:Welfare','Could not write %s.',tex_path); cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'\\begin{table}[!htbp]\n\\centering\n\\caption{%s}\n',caption);
fprintf(fid,'\\label{%s}\n\\resizebox{0.78\\textwidth}{!}{\\begin{tabular}{lrr}\n\\toprule\nGroup & Reforming Economy (A) & Non-Reforming Economy (B) \\\\',strrep(lower(stem),'_','-'));
fprintf(fid,'\n\\midrule\n');
for i=1:numel(groups)
    home=welfare_value(t,groups(i),'Home'); foreign=welfare_value(t,groups(i),'Foreign');
    if groups(i) == "EU1"
        fprintf(fid,'\\multicolumn{3}{l}{\\textit{Short-Term Unemployed}} \\\\\n');
    end
    if groups(i) == "LTU"
        label = 'Long-Term Unemployed (LTU)';
    else
        label = char(groups(i));
    end
    fprintf(fid,'%s & %s & %s \\\\',label,num_or_dash(home),num_or_dash(foreign));
    fprintf(fid,'\n');
    if ismember(groups(i),["Aggregate","Employed","EU8"])
        fprintf(fid,'\\midrule\n');
    end
end
fprintf(fid,'\\bottomrule\n\\end{tabular}}\n\\end{table}\n');
output=struct('csv',csv_path,'tex',tex_path,'available',true);
end


function output = write_separation_spillovers(rows,table_dir)
stem = 'Table_13_Separation_Rate_Spillovers';
csv_path = fullfile(table_dir,[stem '.csv']);
tex_path = fullfile(table_dir,[stem '.tex']);
[baseline,ok_baseline] = row_by_id(rows,'preferred_baseline');
[separation,ok_separation] = row_by_id( ...
    rows,'separation_decline');
if ~ok_baseline || ~ok_separation ...
        || ~path_ok(baseline) || ~path_ok(separation)
    output = unavailable('The immediate target-matched separation-rate results are unavailable.');
    return
end
try
    separation_run_dir = char(separation.run_dir);
    separation_welfare = separation.welfare;
    separation_welfare_status = separation.welfare_status;
    assert(separation_welfare_status.available, ...
        'PaperOutputs:ImmediateSeparationWelfare', ...
        'Immediate-separation CEVs could not be reconstructed.');
catch ME
    output = unavailable(ME.message);
    return
end
panel = [repmat("Post-Reform Steady State",8,1); ...
    repmat("Consumption-Equivalent Variation",2,1)];
indicator = { ...
    'Home Output (%)'; ...
    'Home Consumption (%)'; ...
    'Home Unemployment Rate (%)'; ...
    'Home NFA/Output (pp)'; ...
    'Foreign Output (%)'; ...
    'Foreign Consumption (%)'; ...
    'Foreign Unemployment Rate (%)'; ...
    'Foreign NFA/Output (pp)'; ...
    'Home Aggregate CEV (%)'; ...
    'Foreign Aggregate CEV (%)'};
values = [ ...
    separation_steady_state_values(char(baseline.run_dir)), ...
    separation_steady_state_values(separation_run_dir); ...
    welfare_value(baseline.welfare,'Aggregate','Home'), ...
    welfare_value(separation_welfare,'Aggregate','Home'); ...
    welfare_value(baseline.welfare,'Aggregate','Foreign'), ...
    welfare_value(separation_welfare,'Aggregate','Foreign')];
data = table(panel,indicator,values(:,1),values(:,2), ...
    'VariableNames',{'Panel','Indicator','Baseline', ...
    'ImmediateSeparationDecline'});
writetable(data,csv_path);

fid = fopen(tex_path,'w');
assert(fid>=0,'PaperOutputs:SeparationTable','Could not write %s.',tex_path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'\\begin{table}[!htbp]\n\\centering\n');
fprintf(fid,['\\caption{Separation-Rate Decline: Domestic Adjustment ' ...
    'and International Spillovers}\n']);
fprintf(fid,'\\label{table:separation-spillovers}\n');
fprintf(fid,'\\begin{threeparttable}\n\\small\n');
fprintf(fid,'\\renewcommand{\\arraystretch}{1.08}\n');
fprintf(fid,'\\begin{tabular}{@{}lrr@{}}\n');
fprintf(fid,['\\toprule\n & Baseline Reform & Immediate Separation ' ...
    'Decline \\\\\n\\midrule\n']);
panel_starts = [1 9];
panel_titles = { ...
    'Panel A: Post-Reform Steady-State Effects', ...
    'Panel B: Consumption-Equivalent Variation'};
for i = 1:numel(indicator)
    panel_index = find(panel_starts==i,1);
    if ~isempty(panel_index)
        if i > 1, fprintf(fid,'\\addlinespace[3pt]\n'); end
        fprintf(fid,'\\multicolumn{3}{@{}l}{\\textit{%s}} \\\\\n', ...
            panel_titles{panel_index});
        fprintf(fid,'\\addlinespace[1pt]\n');
    end
    latex_indicator = strrep(indicator{i},'%','\%');
    fprintf(fid,'%s & %s & %s \\\\\n',latex_indicator, ...
        num_or_dash(values(i,1)),num_or_dash(values(i,2)));
end
fprintf(fid,'\\bottomrule\n\\end{tabular}\n');
fprintf(fid,'\\begin{tablenotes}[flushleft]\\footnotesize\n');
fprintf(fid,['\\item Notes: Panel A compares the saved post-reform and ' ...
    'pre-reform steady states. Unemployment entries are relative percent ' ...
    'changes; NFA/output entries are percentage-point changes. Panel B reports ex-ante ' ...
    'consumption-equivalent variation. In the separation experiment, ' ...
    'the Home separation rate declines immediately by 22\\%%. ' ...
    'The experiment retargets only ' ...
    'the long-term replacement-rate cut to the 2.7 percentage-point ' ...
    'sectoral-employment target.\n']);
fprintf(fid,'\\end{tablenotes}\n\\end{threeparttable}\n');
fprintf(fid,'\\end{table}\n');
output = struct('csv',csv_path,'tex',tex_path,'available',true, ...
    'scenario_ids',{{'preferred_baseline', ...
    'separation_decline'}});
end


function t = home_paths_with_wealth(row)
t = row.path_table;
if ismember('HouseholdWealthPct',t.Properties.VariableNames)
    return
end
run_dir = char(row.run_dir);
s = load(fullfile(run_dir,'Sim_H42_EB.mat'),'Sim_H42_EB');
n = load(fullfile(run_dir,'Names_H42_EB.mat'), ...
    'var_names','param_names','param_values');
accounts = scenario_savings_accounts(run_dir,s.Sim_H42_EB,n.var_names, ...
    n.param_values,n.param_names,'a');
household_wealth = 100*(accounts.total_household_wealth(:) ...
    /accounts.total_household_wealth(1)-1);
assert(numel(household_wealth)==height(t), ...
    'PaperOutputs:HouseholdWealthLength', ...
    'Reconstructed Home household wealth has the wrong path length.');
t.HouseholdWealthPct = household_wealth;
end


function values = separation_steady_state_values(run_dir)
pre_names_data = load(fullfile(run_dir,'Names.mat'),'var_names');
pre_data = load(fullfile(run_dir,'SS_init.mat'),'SS_init');
post_names_data = load(fullfile(run_dir,'Names_H42_EB.mat'),'var_names');
post_data = load(fullfile(run_dir,'SS_H42_EB.mat'),'SS_H42_EB');
pre_names = strtrim(cellstr(pre_names_data.var_names));
post_names = strtrim(cellstr(post_names_data.var_names));
pre_values = pre_data.SS_init(:);
post_values = post_data.SS_H42_EB(:);
pre = @(name) pre_values(require_name(pre_names,name));
post = @(name) post_values(require_name(post_names,name));
pct_change = @(name) 100*(post(name)/pre(name)-1);
unemployment_change = @(country) 100*( ...
    (1-post(['N_' country '_t']))/(1-pre(['N_' country '_t']))-1);
nfa_output_change = @(country) 100*( ...
    post(['NFA_' country '_t'])/(4*post(['Y_' country '_t'])) ...
    -pre(['NFA_' country '_t'])/(4*pre(['Y_' country '_t'])));
values = [ ...
    pct_change('Y_a_t'); ...
    pct_change('C_a_t'); ...
    unemployment_change('a'); ...
    nfa_output_change('a'); ...
    pct_change('Y_b_t'); ...
    pct_change('C_b_t'); ...
    unemployment_change('b'); ...
    nfa_output_change('b')];
end


function t = foreign_paths(run_dir)
s=load(fullfile(run_dir,'Sim_H42_EB.mat'),'Sim_H42_EB'); n=load(fullfile(run_dir,'Names_H42_EB.mat'),'var_names','param_names','param_values');
sim=s.Sim_H42_EB; names=strtrim(cellstr(n.var_names)); columns=1:size(sim,2)-1; v=@(name) sim(require_name(names,name),columns)';
accounts=scenario_savings_accounts(run_dir,sim,n.var_names, ...
    n.param_values,n.param_names,'b'); q=(0:numel(v('N_b_t'))-1)'; u=1-v('N_b_t');
ca_level=v('CA_b_t'); nfa_level=v('NFA_b_t'); output_level=v('Y_b_t');
year=2005+q/4; interest=v('R_w_t');
t=table(q,year,100*(accounts.household_cash_rate-accounts.household_cash_rate(1))', ...
    pct(v('C_b_t')),pct(v('GNP_b_t')),pct(output_level),pct(v('N_b_t')), ...
    100*(u-u(1)),100*(ca_level-ca_level(1))/(4*output_level(1)), ...
    100*(nfa_level-nfa_level(1))/(4*output_level(1)), ...
    100*(interest-interest(1)),pct(v('w_b_t')),100*(u/u(1)-1), ...
    'VariableNames',{'Quarter','Year','CashSavingsRateChangePP', ...
    'ConsumptionPct','GNPPct','OutputPct','EmploymentPct', ...
    'UnemploymentPP','CurrentAccountPctAnnualOutput', ...
    'NFAChangePctAnnualOutput', ...
    'InterestRatePP','WagePct','UnemploymentPct'});
end


function output = plot_insurance_comparison(rows,figure_dir,variant)
if strcmpi(variant,'savings_rate')
    stem = 'Figure_16_Incomplete_Vs_Complete_Insurance';
elseif strcmpi(variant,'household_wealth')
    stem = 'Figure_16_Incomplete_Vs_Complete_Insurance_Household_Wealth';
else
    error('PaperOutputs:InsuranceVariant', ...
        'Unknown insurance comparison variant %s.',variant);
end
output = unavailable('The complete-insurance comparison is unavailable.');
[baseline,ok_baseline] = row_by_id(rows,'incomplete_insurance_sgu');
[complete,ok_complete] = row_by_id(rows,'complete_insurance');
if ~ok_baseline || ~ok_complete || ~path_ok(baseline) || ~path_ok(complete)
    return
end
try
    paths = {insurance_paths(char(baseline.run_dir)); ...
        insurance_paths(char(complete.run_dir))};
catch ME
    output.message = string(ME.message);
    return
end
if strcmpi(variant,'savings_rate')
    home_savings = { ...
        'HomeSavingsRateChangePP','Home Household Savings Rate', ...
        'Percentage-Point Change'};
    foreign_savings = { ...
        'ForeignSavingsRateChangePP','Foreign Household Savings Rate', ...
        'Percentage-Point Change'};
else
    home_savings = { ...
        'HomeWealthPct','Home Total Household Wealth','Percent Deviation'};
    foreign_savings = { ...
        'ForeignWealthPct','Foreign Total Household Wealth','Percent Deviation'};
end
% Reading order groups every Home panel before the Foreign panels.
specs = { ...
    'HomeUnemploymentPct','Home Unemployment','Percent Change'; ...
    home_savings{:}; ...
    'RelativeTNEmploymentPct','Home Tradable/Non-Tradable Employment','Percent Deviation'; ...
    'NFAChangePctAnnualOutput','Home Net Foreign Assets','Percent of Initial Annual Output'; ...
    'ForeignUnemploymentPct','Foreign Unemployment','Percent Change'; ...
    foreign_savings{:}};
labels = {'Incomplete Insurance','Complete Insurance'};
styles = {'-','--'};
colors = [0.12 0.32 0.58; 0.82 0.39 0.13];
fig = figure('Color','w','Visible','off','Position',[40 40 1280 790]);
layout = tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
legend_handles = gobjects(2,1);
for p = 1:size(specs,1)
    ax = nexttile(layout); hold(ax,'on'); handles = gobjects(2,1);
    for s = 1:2
        t = paths{s}; use = t.Quarter <= 50;
        handles(s) = plot(ax,t.Quarter(use),t.(specs{p,1})(use), ...
            'Color',colors(s,:),'LineStyle',styles{s},'LineWidth',2.1, ...
            'DisplayName',labels{s});
    end
    if p == 1, legend_handles = handles; end
    paper_zero_line(ax); grid(ax,'on'); box(ax,'off');
    set(ax,'FontName','Times New Roman','FontSize',10, ...
        'XLim',[0 50],'XTick',0:10:50,'TickDir','out', ...
        'XGrid','off','GridColor',[0.85 0.85 0.85], ...
        'GridAlpha',0.45);
    title(ax,specs{p,2}); xlabel(ax,'Quarter'); ylabel(ax,specs{p,3});
end
legend_box = legend(legend_handles,labels,'Orientation','horizontal', ...
    'Box','off');
legend_box.Layout.Tile = 'south';
output = export_figure(fig,figure_dir,stem, ...
    {'incomplete_insurance_sgu','complete_insurance'});
close(fig);
end


function output = plot_insurance_capital_intensity(rows,figure_dir)
stem = 'Figure_17_Capital_Intensity_Incomplete_Vs_Complete_Insurance';
output = unavailable('The complete-insurance capital comparison is unavailable.');
[baseline,ok_baseline] = row_by_id(rows,'incomplete_insurance_sgu');
[complete,ok_complete] = row_by_id(rows,'complete_insurance');
if ~ok_baseline || ~ok_complete || ~path_ok(baseline) || ~path_ok(complete)
    return
end
try
    paths = {insurance_paths(char(baseline.run_dir)); ...
        insurance_paths(char(complete.run_dir))};
catch ME
    output.message = string(ME.message);
    return
end
labels = {'Incomplete Insurance','Complete Insurance'};
styles = {'-','--'}; variables = {'HomeCapitalIntensityPct', ...
    'ForeignCapitalIntensityPct'};
panel_titles = {'Home Capital Intensity','Foreign Capital Intensity'};
colors = [0.12 0.32 0.58; 0.82 0.39 0.13];
fig = figure('Color','w','Visible','off','Position',[50 40 1040 440]);
layout = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
legend_handles = gobjects(2,1);
for p = 1:2
    ax = nexttile(layout); hold(ax,'on'); handles = gobjects(2,1);
    for s = 1:2
        t = paths{s}; use = t.Quarter <= 50;
        handles(s) = plot(ax,t.Quarter(use),t.(variables{p})(use), ...
            'Color',colors(s,:),'LineStyle',styles{s},'LineWidth',2.1, ...
            'DisplayName',labels{s});
    end
    if p == 1, legend_handles = handles; end
    paper_zero_line(ax); grid(ax,'on'); box(ax,'off');
    set(ax,'FontName','Times New Roman','FontSize',10, ...
        'XLim',[0 50],'XTick',0:10:50,'TickDir','out', ...
        'XGrid','off','GridColor',[0.85 0.85 0.85], ...
        'GridAlpha',0.45);
    title(ax,panel_titles{p}); xlabel(ax,'Quarter');
    ylabel(ax,'Percent Deviation');
end
legend_box = legend(legend_handles,labels,'Orientation','horizontal', ...
    'Box','off');
legend_box.Layout.Tile = 'south';
output = export_figure(fig,figure_dir,stem, ...
    {'incomplete_insurance_sgu','complete_insurance'});
close(fig);
end


function t = insurance_paths(run_dir)
s = load(fullfile(run_dir,'Sim_H42_EB.mat'),'Sim_H42_EB');
n = load(fullfile(run_dir,'Names_H42_EB.mat'), ...
    'var_names','param_names','param_values');
sim = s.Sim_H42_EB; names = strtrim(cellstr(n.var_names));
columns = 1:size(sim,2)-1; v = @(name) sim(require_name(names,name),columns)';
accounts_a = scenario_savings_accounts(run_dir,sim,n.var_names, ...
    n.param_values,n.param_names,'a');
accounts_b = scenario_savings_accounts(run_dir,sim,n.var_names, ...
    n.param_values,n.param_names,'b');
quarter = (0:numel(v('N_a_t'))-1)';
u_a = 1-v('N_a_t'); u_b = 1-v('N_b_t');
nt_home = v('NT_a_t'); nn_home = v('NN_a_t');
relative_tn = 100*(log(nt_home./nn_home) ...
    -log(nt_home(1)/nn_home(1)));
nfa = v('NFA_a_t'); y0 = v('Y_a_t'); y0 = y0(1);
capital_home = lag_vector(v('k_a_t'),1)./v('N_a_t');
capital_foreign = lag_vector(v('k_b_t'),1)./v('N_b_t');
t = table(quarter,100*(u_a/u_a(1)-1), ...
    100*(accounts_a.total_household_wealth(:) ...
        /accounts_a.total_household_wealth(1)-1), ...
    100*(accounts_a.household_cash_rate(:) ...
        -accounts_a.household_cash_rate(1)), ...
    relative_tn,100*(u_b/u_b(1)-1), ...
    100*(accounts_b.total_household_wealth(:) ...
        /accounts_b.total_household_wealth(1)-1), ...
    100*(accounts_b.household_cash_rate(:) ...
        -accounts_b.household_cash_rate(1)), ...
    100*(nfa-nfa(1))/(4*y0),100*(capital_home/capital_home(1)-1), ...
    100*(capital_foreign/capital_foreign(1)-1), ...
    'VariableNames',{'Quarter','HomeUnemploymentPct','HomeWealthPct', ...
    'HomeSavingsRateChangePP','RelativeTNEmploymentPct', ...
    'ForeignUnemploymentPct','ForeignWealthPct', ...
    'ForeignSavingsRateChangePP', ...
    'NFAChangePctAnnualOutput','HomeCapitalIntensityPct', ...
    'ForeignCapitalIntensityPct'});
end


function values = lag_vector(values,lag)
values = [repmat(values(1),lag,1);values(1:end-lag)];
end


function [row,ok] = row_by_id(rows,id)
index=find(strcmpi(string({rows.scenario_id}),string(id)),1); ok=~isempty(index);
if ok, row=rows(index); else, row=struct(); end
end

function flag = path_ok(row)
flag=isfield(row,'path_table') && istable(row.path_table) && height(row.path_table)>=42 ...
    && isfield(row,'run_dir') && isfolder(char(row.run_dir));
end


function output = copy_figure_alias(source,figure_dir,alias_stem)
output = unavailable('The source figure for this alias is unavailable.');
if ~isstruct(source) || ~isfield(source,'available') || ~source.available
    return
end
extensions = {'.png','.pdf','.eps','.fig'};
source_paths = {source.png,source.pdf,source.eps,source.fig};
target_stem = fullfile(figure_dir,alias_stem);
for i = 1:numel(extensions)
    assert(isfile(source_paths{i}),'PaperOutputs:FigureAliasSource', ...
        'Missing alias source %s.',source_paths{i});
    copyfile(source_paths{i},[target_stem extensions{i}],'f');
end
output = struct('available',true,'message',"", ...
    'png',[target_stem '.png'],'pdf',[target_stem '.pdf'], ...
    'eps',[target_stem '.eps'],'fig',[target_stem '.fig'], ...
    'scenarios',{source.scenarios});
end


function output = export_figure(fig,dir_path,stem,ids)
png=fullfile(dir_path,[stem '.png']); pdf=fullfile(dir_path,[stem '.pdf']); eps=fullfile(dir_path,[stem '.eps']); fig_path=fullfile(dir_path,[stem '.fig']);
exportgraphics(fig,png,'Resolution',600); exportgraphics(fig,pdf,'ContentType','vector'); exportgraphics(fig,eps,'ContentType','vector'); savefig(fig,fig_path);
output=struct('available',true,'message',"",'png',png,'pdf',pdf,'eps',eps,'fig',fig_path,'scenarios',{ids});
end

function output = unavailable(message)
output=struct('available',false,'message',string(message),'png','','pdf','','eps','','fig','','scenarios',{{}});
end

function rows = normalize_rows(rows)
if isempty(rows), rows=repmat(struct(),0,1); elseif iscell(rows), rows=vertcat(rows{:}); elseif istable(rows), rows=table2struct(rows); end
rows=rows(:);
end

function value = case_value(t,metric,country)
mask=strcmpi(string(t.Metric),metric)&strcmpi(string(t.Country),country)&logical(t.Available); value=NaN; if any(mask), value=t.Value(find(mask,1)); end
end

function value = welfare_value(t,group,country)
mask=strcmpi(string(t.Group),group)&strcmpi(string(t.Country),country)&logical(t.Available); value=NaN; if any(mask), value=t.CEVPct(find(mask,1)); end
end

function text = num_or_dash(value)
if isfinite(value), text=sprintf('%.2f',value); else, text='--'; end
end

function value = pct(x), value=100*(x/x(1)-1); end
function index = require_name(names,name), index=find(strcmp(names,name),1); assert(~isempty(index),'PaperOutputs:Variable','Missing %s.',name); end
function ensure_folder(path), if ~isfolder(path), mkdir(path); end, end
function write_json(path,value), fid=fopen(path,'w'); assert(fid>=0,'PaperOutputs:JSON','Could not write %s.',path); cleanup=onCleanup(@() fclose(fid)); fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true)); end
