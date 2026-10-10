function output = write_extended_baseline_outputs(run_dir, settings)
%WRITE_EXTENDED_BASELINE_OUTPUTS Export all extended baseline figures and tables.

arguments
    run_dir (1,:) char
    settings.visible (1,1) logical = true
    settings.target_year (1,1) double {mustBeInteger,mustBeGreaterThanOrEqual(settings.target_year,2005)} = 2014
    settings.empirical_data_path (1,:) char = ''
    settings.output_dir (1,:) char = ''
    settings.figure_dir (1,:) char = ''
    settings.table_dir (1,:) char = ''
end

code_dir = fileparts(fileparts(mfilename('fullpath')));
[~, run_name] = fileparts(run_dir);
if isempty(settings.output_dir)
    output_dir = fullfile(code_dir, 'output', run_name);
else
    output_dir = settings.output_dir;
end
if ~isfolder(output_dir), mkdir(output_dir); end
if isempty(settings.figure_dir), figure_dir = output_dir; else, figure_dir = settings.figure_dir; end
if isempty(settings.table_dir), table_dir = output_dir; else, table_dir = settings.table_dir; end
if ~isfolder(figure_dir), mkdir(figure_dir); end
if ~isfolder(table_dir), mkdir(table_dir); end

s = load(fullfile(run_dir, 'Sim_H42_EB.mat'), 'Sim_H42_EB');
n = load(fullfile(run_dir, 'Names_H42_EB.mat'), 'var_names', 'param_names', 'param_values');
sim = s.Sim_H42_EB;
names = strtrim(cellstr(n.var_names));
parameters = strtrim(cellstr(n.param_names));
values = n.param_values;
last = size(sim,2)-1;
columns = 1:last;
quarters = (0:last-1)';
v = @(name) sim(require_name(names,name),columns)';
p = @(name) values(require_name(parameters,name));
visibility = on_off(settings.visible);
accounts_a = savings_accounts(sim,n.var_names,n.param_values,n.param_names,'a');
accounts_b = savings_accounts(sim,n.var_names,n.param_values,n.param_names,'b');
cash_a = 100*(accounts_a.household_cash_rate-accounts_a.household_cash_rate(1))';
cash_b = 100*(accounts_b.household_cash_rate-accounts_b.household_cash_rate(1))';

sector = sector_series(v);
sector_table = table(quarters,sector.tradable,sector.nontradable,sector.ratio, ...
    'VariableNames',{'Quarter','TradableEmploymentPct','NontradableEmploymentPct','TradableNontradableRatioPct'});
sector_csv = fullfile(table_dir,'sector_employment_paths.csv'); writetable(sector_table,sector_csv);
[sector_png,sector_eps,sector_fig] = ...
    plot_sector(quarters,sector,visibility,figure_dir);

foreign = foreign_series(v,cash_b);
foreign_csv = fullfile(table_dir,'foreign_economy_paths.csv'); writetable(foreign,foreign_csv);
[foreign_png,foreign_eps,foreign_fig] = ...
    plot_foreign(foreign,visibility,figure_dir);

fiscal = fiscal_series(v);
fiscal_csv = fullfile(table_dir,'fiscal_space_paths.csv'); writetable(fiscal,fiscal_csv);
fiscal_annual = annualize_fiscal(fiscal);
fiscal_annual_csv = fullfile(table_dir,'fiscal_space_annual_paths.csv');
writetable(fiscal_annual,fiscal_annual_csv);
[fiscal_png,fiscal_eps,fiscal_fig] = ...
    plot_fiscal(fiscal_annual,visibility,figure_dir);

cev = cev_table(v,p);
cev_csv = fullfile(table_dir,'cev_by_group_and_country.csv'); writetable(cev,cev_csv);
cev_tex = fullfile(table_dir,'cev_by_group_and_country.tex'); write_cev_tex(cev_tex,cev);

if isempty(settings.empirical_data_path)
    settings.empirical_data_path = fullfile(code_dir,'empirical_data.csv');
end
contribution = contribution_table(v,cash_a,cash_b,settings.target_year,settings.empirical_data_path);
contribution_csv = fullfile(table_dir,'model_contribution_2014.csv'); writetable(contribution,contribution_csv);
contribution_tex = fullfile(table_dir,'model_contribution_2014.tex');
write_contribution_tex(contribution_tex,contribution,settings.target_year);

long_run = long_run_table(v,160);
long_run_csv = fullfile(table_dir,'long_run_reform_effects.csv'); writetable(long_run,long_run_csv);
long_run_tex = fullfile(table_dir,'long_run_reform_effects.tex'); write_long_run_tex(long_run_tex,long_run);

calibration = calibration_table(parameters,values);
calibration_csv = fullfile(table_dir,'current_calibration_snapshot.csv'); writetable(calibration,calibration_csv);
calibration_tex = fullfile(table_dir,'current_calibration_snapshot.tex');
write_calibration_tex(calibration_tex,calibration);

manifest = struct('run_dir',run_dir,'output_dir',output_dir, ...
    'target_year',settings.target_year,'empirical_data_path',settings.empirical_data_path, ...
    'figure_dir',figure_dir,'table_dir',table_dir, ...
    'series_definition','All figure series are deviations from the pre-reform steady state.', ...
    'fiscal_space_definition',['Fixed-policy level change in labor-tax revenue minus ', ...
    'unemployment-benefit spending, normalized by pre-reform GDP. Overall fiscal space ', ...
    'also subtracts the change in lagged government debt service. Figure 6 reports annual averages.']);
write_json(fullfile(output_dir,'output_manifest.json'),manifest);
output = struct('directory',output_dir,'sector_csv',sector_csv,'sector_png',sector_png, ...
    'sector_eps',sector_eps,'sector_fig',sector_fig, ...
    'foreign_csv',foreign_csv,'foreign_png',foreign_png, ...
    'foreign_eps',foreign_eps,'foreign_fig',foreign_fig, ...
    'fiscal_csv',fiscal_csv,'fiscal_png',fiscal_png, ...
    'fiscal_eps',fiscal_eps, ...
    'fiscal_annual_csv',fiscal_annual_csv,'fiscal_fig',fiscal_fig, ...
    'cev_csv',cev_csv,'cev_tex',cev_tex, ...
    'contribution_csv',contribution_csv,'contribution_tex',contribution_tex, ...
    'long_run_csv',long_run_csv,'long_run_tex',long_run_tex, ...
    'calibration_csv',calibration_csv,'calibration_tex',calibration_tex);
end

function s = sector_series(v)
tradable = v('NT_a_t');
nontradable = v('NN_a_t');
ratio_level = tradable./nontradable;
s.tradable = pct(tradable);
s.nontradable = pct(nontradable);
s.ratio = 100*(log(ratio_level)-log(ratio_level(1)));
end

function t = foreign_series(v,cash_savings)
q = (0:numel(v('N_b_t'))-1)';
unemployment = 1-v('N_b_t');
t = table(q,cash_savings,pct(v('C_b_t')),pct(v('GNP_b_t')), ...
    annual_output_change(v('CA_b_t'),v('Y_b_t')),100*(v('R_w_t')-first(v('R_w_t'))), ...
    pct(v('w_b_t')),100*(unemployment-unemployment(1)), ...
    100*(unemployment/unemployment(1)-1), ...
    'VariableNames',{'Quarter','CashSavingsRateChangePP','ConsumptionPct','GNPPct', ...
    'CurrentAccountPctAnnualOutput','InterestRateChangePP','WagePct', ...
    'UnemploymentRateChangePP','UnemploymentRatePct'});
end

function t = fiscal_series(v)
q = (0:numel(v('Y_a_t'))-1)';
a = fiscal_country(v,'a'); b = fiscal_country(v,'b');
t = table(q,a(:,1),a(:,2),b(:,1),b(:,2),'VariableNames', ...
    {'Quarter','HomePrimaryFiscalSpacePP','HomeOverallFiscalSpacePP', ...
    'ForeignPrimaryFiscalSpacePP','ForeignOverallFiscalSpacePP'});
end

function output = fiscal_country(v,country)
y = v(['Y_' country '_t']); r = v('R_w_t'); debt = v(['b_' country '_t']);
tax = v(['tauw_' country '_t']).*v(['w_' country '_t']).*v(['N_' country '_t']);
ui = v(['muuu_' country '_t']).*v(['kappaBL_' country '_t']);
for k = 1:8
    ui = ui + v(sprintf('mueu%d_%s_t',k,country)).*v(sprintf('kappaBS%d_%s_t',k,country));
end
% Fiscal space is the reform-generated fiscal dividend before endogenous
% lump-sum-tax financing. Fixed lump-sum taxes and government purchases
% cancel from the level change. A fixed pre-reform GDP denominator prevents
% changes in their GDP shares from being misclassified as fiscal savings.
primary = 100*((tax-tax(1))-(ui-ui(1)))/y(1);

% Period-t debt service is predetermined by R_{t-1} and b_{t-1}.
interest = zeros(size(primary));
interest(2:end) = -100*(((r(1:end-1)-1).*debt(1:end-1)) ...
    -(r(1)-1)*debt(1))/y(1);
overall = primary+interest;
output = [primary,overall];
end

function annual = annualize_fiscal(t)
% The paper figure ends in 2039. Limiting the companion CSV to the same
% horizon also excludes the known terminal-boundary years of the long solve.
n_years = min(floor(max(t.Quarter)/4),35);
year = (2004:2004+n_years)';
names = t.Properties.VariableNames(2:end);
values = zeros(n_years+1,numel(names));
for j = 1:n_years
    rows = t.Quarter >= 4*(j-1)+1 & t.Quarter <= 4*j;
    for k = 1:numel(names)
        values(j+1,k) = mean(t.(names{k})(rows));
    end
end
annual = array2table([year values], ...
    'VariableNames',[{'Year'} names]);
end

function t = cev_table(v,p)
group = {'Aggregate';'Employed';'EU1';'EU2';'EU3';'EU4';'EU5';'EU6';'EU7';'EU8';'Long-Term Unemployed'};
home = country_cev(v,p,'a');
foreign = country_cev(v,p,'b');
t = table(group,home,foreign,'VariableNames',{'Group','ReformingEconomyA','NonReformingEconomyB'});
end

function result = country_cev(v,p,country)
% Reconstruct lifetime utility from the saved equilibrium paths. This keeps
% old saved transitions usable after correcting the reporting-only welfare
% block and makes the t -> t+1 timing and EU-duration progression explicit.
sigma = p('sigmac');
beta = p(['betta_' country]);
separation = p(['s_' country]);
consumption = [v(['Ce_' country '_t'])'; ...
    v(['Ceu1_' country '_t'])'; v(['Ceu2_' country '_t'])'; ...
    v(['Ceu3_' country '_t'])'; v(['Ceu4_' country '_t'])'; ...
    v(['Ceu5_' country '_t'])'; v(['Ceu6_' country '_t'])'; ...
    v(['Ceu7_' country '_t'])'; v(['Ceu8_' country '_t'])'; ...
    v(['Cuu_' country '_t'])'];
job_finding = v(['p_' country '_t']);
utility = consumption.^(1-sigma)/(1-sigma);
periods = size(consumption,2);
value = zeros(size(consumption));
pre_value = (eye(10)-beta*welfare_transition(job_finding(1),separation))\utility(:,1);
value(:,periods) = (eye(10)-beta*welfare_transition(job_finding(end),separation))\utility(:,end);
for period = periods-1:-1:2
    transition = welfare_transition(job_finding(period+1),separation);
    value(:,period) = utility(:,period)+beta*transition*value(:,period+1);
end
state_cev = 100*((value(:,2)./pre_value).^(1/(1-sigma))-1);
weights = [first(v(['mue_' country '_t'])); ...
    first(v(['mueu1_' country '_t'])); first(v(['mueu2_' country '_t'])); ...
    first(v(['mueu3_' country '_t'])); first(v(['mueu4_' country '_t'])); ...
    first(v(['mueu5_' country '_t'])); first(v(['mueu6_' country '_t'])); ...
    first(v(['mueu7_' country '_t'])); first(v(['mueu8_' country '_t'])); ...
    first(v(['muuu_' country '_t']))];
assert(abs(sum(weights)-1)<1e-10,'BaselineModel:CEVWeights', ...
    'Initial welfare weights for country %s sum to %.16g.',country,sum(weights));
aggregate_cev = 100*((weights'*value(:,2)/(weights'*pre_value))^(1/(1-sigma))-1);
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

function t = contribution_table(v,cash_a,cash_b,target_year,empirical_path)
if exist(empirical_path,'file') ~= 2
    error('BaselineModel:EmpiricalData','Missing empirical contribution input: %s',empirical_path);
end

emp = readtable(empirical_path);
base = emp(emp.year==2004,:); target = emp(emp.year==target_year,:);
if height(base)~=1 || height(target)~=1
    error('BaselineModel:EmpiricalData','Empirical data requires unique 2004 and %d rows.',target_year);
end
q = (2+4*(target_year-2005)):(5+4*(target_year-2005));
if q(end)>numel(v('N_a_t')), error('BaselineModel:ContributionHorizon','Run is too short for %d.',target_year); end
avg = @(x) mean(x(q));
unemployment = 100*((1-v('N_a_t'))-(1-first(v('N_a_t'))))/(1-first(v('N_a_t')));
nfa = 100*(v('NFA_a_t')./(4*v('Y_a_t'))-first(v('NFA_a_t'))/(4*first(v('Y_a_t'))));
ca = 100*(v('CA_a_t')./v('Y_a_t')-first(v('CA_a_t'))/first(v('Y_a_t')));
ulc = 100*((v('w_a_t')./(v('Y_a_t')./v('N_a_t'))) ./ ...
    (v('w_b_t')./(v('Y_b_t')./v('N_b_t')))-1);
model = [avg(unemployment);avg(cash_a);avg(nfa);avg(ca);avg(ca);avg(ulc);avg(cash_b)];
denom = [100*(target.unemployment_rate-base.unemployment_rate)/base.unemployment_rate; ...
    target.savings_rate_soep_percent-base.savings_rate_soep_percent; ...
    target.NFA_percent_GDP-base.NFA_percent_GDP; target.CA_percent_GDP; ...
    target.CA_Euro_percent_GDP; target.ULC_relative_EZ; target.savings_rate_EZ-base.savings_rate_EZ];
indicator = {'Unemployment';'Private Savings Rate';'Net Foreign Assets/GDP'; ...
    'Current Account/GDP';'Current Account vis-a-vis Eurozone/GDP'; ...
    'Unit Labor Costs Relative to Eurozone';'Private Savings Rate Rest of Eurozone'};
t = table(indicator,model,denom,100*model./denom,'VariableNames', ...
    {'Indicator','ModelChange','EmpiricalChange','BaselineContributionPercent'});
end

function t = long_run_table(v,horizon_quarter)
%LONG_RUN_TABLE Collect Home/Foreign effects at a common post-reform horizon.
q = min(horizon_quarter+1,numel(v('Y_a_t')));
home_rer = pct(v('rer_cpi_t'));
foreign_rer = 100*(first(v('rer_cpi_t'))./v('rer_cpi_t')-1);
row = {'GDP';'GNP';'Aggregate Consumption';'Employment';'Unemployment Rate Change'; ...
    'Tradable Consumption';'Nontradable Consumption'; ...
    'Tradables/Nontradables';'CPI';'TPI';'Wage';'Interest Rate'; ...
    'Real Exchange Rate';'Capital-Labor Ratio';'NFA/Output'};
home = [pct(v('Y_a_t')), pct(v('GNP_a_t')), pct(v('C_a_t')), pct(v('N_a_t')), ...
    100*((1-v('N_a_t'))-(1-first(v('N_a_t')))), pct(v('cT_a_t')), ...
    pct(v('cN_a_t')), log_pct(v('trdb_vs_nontrdb_a_t')), pct(v('CPI_a_t')), ...
    pct(v('TPI_a_t')), pct(v('w_a_t')), 100*(v('R_w_t')-first(v('R_w_t'))), ...
    home_rer, capital_labor_pct(v,'a'), nfa_output_pp(v,'a')];
foreign = [pct(v('Y_b_t')), pct(v('GNP_b_t')), pct(v('C_b_t')), pct(v('N_b_t')), ...
    100*((1-v('N_b_t'))-(1-first(v('N_b_t')))), pct(v('cT_b_t')), ...
    pct(v('cN_b_t')), log_pct(v('trdb_vs_nontrdb_b_t')), pct(v('CPI_b_t')), ...
    pct(v('TPI_b_t')), pct(v('w_b_t')), 100*(v('R_w_t')-first(v('R_w_t'))), ...
    foreign_rer, capital_labor_pct(v,'b'), nfa_output_pp(v,'b')];
unit = repmat({'Percent Deviation'},numel(row),1);
unit(ismember(row,{'Unemployment Rate Change','Interest Rate','NFA/Output'})) = {'Percentage Points'};
t = table(row,home(q,:)',foreign(q,:)',unit,'VariableNames', ...
    {'Indicator','Home','Foreign','Unit'});
end

function x = capital_labor_pct(v,country)
x = pct(v(['k_' country '_t'])./v(['N_' country '_t']));
end

function x = nfa_output_pp(v,country)
x = 100*(v(['NFA_' country '_t'])./(4*v(['Y_' country '_t'])) ...
    -first(v(['NFA_' country '_t']))/(4*first(v(['Y_' country '_t']))));
end

function t = calibration_table(parameters,values)
%CALIBRATION_TABLE Current saved-run inputs and internally implied values.
p = @(name) parameter_or_nan(parameters,values,name);
panel = [repmat({'Panel A: Externally Set'},14,1); ...
    repmat({'Panel B: Calibrated Internally'},6,1)];
name = {'Country Size';'Discount Factor';'Risk Aversion'; ...
    'Tradables Share In Consumption';'T/N Consumption Elasticity'; ...
    'Tradables Share In Investment';'Capital Depreciation'; ...
    'Capital Share In Production';'Matching Elasticity'; ...
    'Workers Bargaining Power';'Replacement Rate, Short-Term Unemployed'; ...
    'Replacement Rate, Long-Term Unemployed';'Job-Finding Rate'; ...
    'Investment Adjustment Cost';'Matching Efficiency'; ...
    'Vacancy-Posting Cost';'Separation Rate'; ...
    'Tradable Recruiting Curvature';'Nontradable Recruiting Curvature'; ...
    'Hall Wage Persistence'};
symbol = {'s^A';'\beta';'\sigma_C';'\alpha_T';'\phi_T';'\alpha_I'; ...
    '\delta';'\alpha';'\eta';'\zeta';'rr_s';'rr_l';'q';'\iota'; ...
    '\kappa^E';'\kappa^V';'s';'\chi_T';'\chi_N';'\gamma_w'};
home = [p('size_a'); p('betta_a'); p('sigmac'); p('alpha_a_t'); p('phi_t'); ...
    p('alpha_I_a'); p('delta_a'); p('cp_a'); p('alphaa_a'); p('xoui_a'); ...
    p('rrs_a'); p('rrl_a'); p('p_a_ts'); p('iac_a'); p('kappae_a'); ...
    p('kappav_a'); p('s_a'); p('chi_sector_T_a'); p('chi_sector_N_a'); p('gammaw_a')];
foreign = [1-p('size_a'); p('betta_b'); p('sigmac'); p('alpha_b_t'); p('phi_t'); ...
    p('alpha_I_b'); p('delta_b'); p('cp_b'); p('alphaa_b'); p('xoui_b'); ...
    p('rrs_b'); p('rrl_b'); p('p_b_ts'); p('iac_b'); p('kappae_b'); ...
    p('kappav_b'); p('s_b'); p('chi_sector_T_b'); p('chi_sector_N_b'); p('gammaw_b')];
t = table(panel,name,symbol,home,foreign,'VariableNames', ...
    {'Panel','ParameterName','Symbol','Home','Foreign'});
end

function x = parameter_or_nan(parameters,values,name)
index = find(strcmp(parameters,name),1);
if isempty(index), x = NaN; else, x = values(index); end
end

function [png_path,eps_path,fig_path] = plot_sector(q,s,visibility,out_dir)
fig = figure('Color','w','Visible',visibility,'Position',[100 100 900 500]);
plot(q,s.ratio,'k-','LineWidth',1.8,'DisplayName','T/N Employment Ratio'); hold on
plot(q,s.tradable,'b-','LineWidth',1.8,'DisplayName','Tradable Employment');
plot(q,s.nontradable,'r-','LineWidth',1.8,'DisplayName','Non-Tradable Employment');
yline(2.7,'k--','DisplayName','Q1-Q40 Relative-Employment Target');
paper_zero_line(gca); xlim([0 min(140,q(end))]); grid on
xlabel('Quarter'); ylabel('Log Response, Percent'); legend('Location','best');
png_path=fullfile(out_dir,'sector_level_employment.png'); eps_path=fullfile(out_dir,'sector_level_employment.eps'); fig_path=fullfile(out_dir,'sector_level_employment.fig'); exportgraphics(fig,png_path,'Resolution',600); exportgraphics(fig,eps_path,'ContentType','vector'); savefig(fig,fig_path); close(fig);
end

function [png_path,eps_path,fig_path] = plot_foreign(t,visibility,out_dir)
fig=figure('Color','w','Visible',visibility,'Position',[100 100 1100 700]); layout=tiledlayout(2,3,'TileSpacing','compact','Padding','compact');
spec = {'CashSavingsRateChangePP','Household Savings Rate','Percentage-Point Change';'CurrentAccountPctAnnualOutput','Current Account','Percent of Initial Annual Output';'InterestRateChangePP','Interest Rate','Percentage-Point Change';'WagePct','Wages','Percent Deviation';'UnemploymentRatePct','Unemployment Rate','Percent Change'};
year = 2004+t.Quarter/4;
last_year = min(2039,year(end));
ax=nexttile; plot(ax,year,t.CashSavingsRateChangePP,'k-','LineWidth',1.7, ...
    'DisplayName','Household Savings Rate'); paper_zero_line(ax); ...
    xlim(ax,[2004 last_year]); grid(ax,'on'); title(ax,'Household Savings Rate'); ...
    xlabel(ax,'Year'); ylabel(ax,'Percentage-Point Change');
ax=nexttile; plot(ax,year,t.ConsumptionPct,'k-','LineWidth',1.7,'DisplayName','Consumption'); hold(ax,'on'); plot(ax,year,t.GNPPct,'k--','LineWidth',1.5,'DisplayName','GNP'); paper_zero_line(ax); xlim(ax,[2004 last_year]); grid(ax,'on'); title(ax,'Consumption and GNP'); xlabel(ax,'Year'); ylabel(ax,'Percent Deviation'); legend(ax,'Location','best');
for i=2:5
    ax=nexttile; plot(ax,year,t.(spec{i,1}),'k-','LineWidth',1.7); paper_zero_line(ax); xlim(ax,[2004 last_year]); grid(ax,'on'); title(ax,spec{i,2}); xlabel(ax,'Year'); ylabel(ax,spec{i,3});
end
png_path=fullfile(out_dir,'foreign_economy_selected_calibration.png'); eps_path=fullfile(out_dir,'foreign_economy_selected_calibration.eps'); fig_path=fullfile(out_dir,'foreign_economy_selected_calibration.fig'); exportgraphics(fig,png_path,'Resolution',600); exportgraphics(fig,eps_path,'ContentType','vector'); savefig(fig,fig_path); close(fig);
end

function [png_path,eps_path,fig_path] = plot_fiscal(t,visibility,out_dir)
fig=figure('Color','w','Visible',visibility,'Position',[100 100 900 500]);
plot(t.Year,t.HomePrimaryFiscalSpacePP,'k-','LineWidth',1.8,'DisplayName','Reforming (Primary)'); hold on
plot(t.Year,t.ForeignPrimaryFiscalSpacePP,'k--','LineWidth',1.5,'DisplayName','Non-Reforming (Primary)');
plot(t.Year,t.HomeOverallFiscalSpacePP,'b-','LineWidth',1.8,'DisplayName','Reforming (Overall)');
plot(t.Year,t.ForeignOverallFiscalSpacePP,'b--','LineWidth',1.5,'DisplayName','Non-Reforming (Overall)');
paper_zero_line(gca); xlim([2004 min(2039,t.Year(end))]); grid on
xlabel('Year'); ylabel('Percentage Points Of Pre-Reform GDP'); legend('Location','best');
png_path=fullfile(out_dir,'fiscal_space_selected_calibration.png'); eps_path=fullfile(out_dir,'fiscal_space_selected_calibration.eps'); fig_path=fullfile(out_dir,'fiscal_space_selected_calibration.fig'); exportgraphics(fig,png_path,'Resolution',600); exportgraphics(fig,eps_path,'ContentType','vector'); savefig(fig,fig_path); close(fig);
end

function write_cev_tex(path,t)
fid=fopen(path,'w'); assert(fid>=0,'BaselineModel:Output','Could not write %s.',path); cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,['\\begin{table}[!htbp]\n\\centering\n\\caption{Consumption Equivalent Variation by Group and Country}\\label{tab:cev-current-calibration}\n', ...
    '\\begin{tabular}{lrr}\n\\toprule\nGroup & Reforming Economy (A) & Non-Reforming Economy (B) \\\\']);
fprintf(fid,'\n\\midrule\n');
for i=1:height(t)
    fprintf(fid,'%s & %.2f\\%% & %.2f\\%% \\\\',t.Group{i},t.ReformingEconomyA(i),t.NonReformingEconomyB(i));
    fprintf(fid,'\n');
    if i==1 || i==2 || i==10, fprintf(fid,'\\midrule\n'); end
end
fprintf(fid,['\\bottomrule\n\\end{tabular}\n\\begin{flushleft}\\footnotesize ', ...
    'Notes: Consumption-equivalent variation relative to the pre-reform steady state. ', ...
    'The aggregate row weights state-contingent lifetime utility by pre-reform population shares. ', ...
    'Welfare transitions use the next-period job-finding rate; an unmatched worker advances from ', ...
    'EU1 through EU8 and then enters long-term unemployment.\\end{flushleft}\n\\end{table}\n']);
end

function write_contribution_tex(path,t,target_year)
fid=fopen(path,'w'); assert(fid>=0,'BaselineModel:Output','Could not write %s.',path); cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,['\\begin{table}[!htbp]\n\\centering\n\\caption{Baseline Model Contributions to Empirical Changes}\\label{tab:model-contribution-current-calibration}\n', ...
    '\\begin{tabular}{lr}\n\\toprule\nIndicator & Baseline Contribution (\\%%) \\\\']);
fprintf(fid,'\n\\midrule\n');
for i=1:height(t)
    fprintf(fid,'%s & %.1f\\%% \\\\',t.Indicator{i},t.BaselineContributionPercent(i));
    fprintf(fid,'\n');
end
fprintf(fid,['\\bottomrule\n\\end{tabular}\n\\begin{flushleft}\\footnotesize ', ...
    'Notes: The reported model contribution uses only the current selected baseline calibration and ', ...
    'the average model response over calendar year %d.\\end{flushleft}\n\\end{table}\n'],target_year);
end

function write_long_run_tex(path,t)
fid=fopen(path,'w'); assert(fid>=0,'BaselineModel:Output','Could not write %s.',path); cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,['\\begin{table}[!htbp]\n\\centering\n\\caption{Long-Run Reform Effects in Home and Foreign Economy}\\label{tab:long-run-current-calibration}\n', ...
    '\\begin{tabular}{lrr}\n\\toprule\n & Home & Foreign \\\\']);
fprintf(fid,'\n\\midrule\n');
for i=1:height(t)
    fprintf(fid,'%s & %.2f & %.2f \\\\',t.Indicator{i},t.Home(i),t.Foreign(i));
    fprintf(fid,'\n');
end
fprintf(fid,['\\bottomrule\n\\end{tabular}\n\\begin{flushleft}\\footnotesize ', ...
    'Notes: Effects at quarter 160 (40 years) relative to the pre-reform steady state. ', ...
    'All rows are percent deviations except the unemployment-rate change, interest rates, and NFA/output, ', ...
    'which are percentage-point changes. The foreign real-exchange-rate entry is the inverse ', ...
    'of the Home CPI real exchange rate.\\end{flushleft}\n\\end{table}\n']);
end

function write_calibration_tex(path,t)
fid=fopen(path,'w'); assert(fid>=0,'BaselineModel:Output','Could not write %s.',path); cleanup=onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,['\\begin{table}[!htbp]\n\\centering\n\\caption{Current Baseline Model Parameters}\\label{tab:current-calibration}\n', ...
    '\\begin{tabular}{llrr}\n\\toprule\nParameter Name & Symbol & Home & Foreign \\\\']);
fprintf(fid,'\n\\midrule\n');
last_panel = '';
for i=1:height(t)
    if ~strcmp(t.Panel{i},last_panel)
        if i>1, fprintf(fid,'\\midrule\n'); end
        fprintf(fid,'\\multicolumn{4}{l}{\\textit{%s}} \\\\',t.Panel{i});
        fprintf(fid,'\n');
        last_panel = t.Panel{i};
    end
    fprintf(fid,'%s & $%s$ & %s & %s \\\\',t.ParameterName{i},t.Symbol{i}, ...
        format_parameter(t.Home(i)),format_parameter(t.Foreign(i)));
    fprintf(fid,'\n');
end
fprintf(fid,['\\bottomrule\n\\end{tabular}\n\\begin{flushleft}\\footnotesize ', ...
    'Notes: Values are read directly from the selected saved calibration. Panel A contains ', ...
    'externally set inputs; Panel B reports steady-state values implied by the calibration. ', ...
    'The separate tradable and nontradable recruiting-curvature parameters are included in Panel B.\\end{flushleft}\n\\end{table}\n']);
end

function out = format_parameter(x)
if isnan(x), out = '--'; return; end
if abs(x)>=100, out = sprintf('%.1f',x);
elseif abs(x)>=10, out = sprintf('%.3f',x);
else, out = sprintf('%.4f',x);
end
end

function result = annual_output_change(x,y)
result = 100*(x-x(1))/(4*y(1));
end

function result = pct(x)
result = 100*(x/x(1)-1);
end

function result = log_pct(x)
result = 100*(log(x)-log(x(1)));
end

function result = cev(w,sigma)
result = 100*((w(2)/w(1))^(1/(1-sigma))-1);
end

function result = first(x)
result = x(1);
end

function index = require_name(names,name)
index = find(strcmp(names,name),1);
assert(~isempty(index),'BaselineModel:MissingVariable','Missing %s.',name);
end

function value = on_off(flag)
if flag
    value = 'on';
else
    value = 'off';
end
end

function write_json(path,value)
fid = fopen(path,'w');
assert(fid>=0,'BaselineModel:Output','Could not write %s.',path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(value,'PrettyPrint',true));
end
