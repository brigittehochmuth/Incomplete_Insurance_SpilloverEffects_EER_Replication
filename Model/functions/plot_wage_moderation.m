function files = plot_wage_moderation(output_dir,rows,options)
%PLOT_WAGE_MODERATION Compare distinct matched-scale shocks.
%   The UI reform and wage-moderation counterfactual are compared because
%   their q1-q40 unemployment changes are matched. No UI policy is applied
%   in the wage-moderation row, and no UI external-sign gate is imposed.

if nargin < 3 || isempty(options), options = struct(); end
if ~isfield(options,'file_stem'), options.file_stem = "ui_reform_vs_wage_moderation"; end
if ~isfield(options,'visible'), options.visible = false; end
if ~isfield(options,'horizon'), options.horizon = 50; end
if ~isfolder(output_dir), mkdir(output_dir); end
rows = normalize_rows(rows);

files = struct('available',false,'status',"unavailable", ...
    'message',"Required saved transition paths were unavailable.", ...
    'png',"",'pdf',"",'fig',"", ...
    'included_scenarios',strings(0,1));
ui_index = find_id(rows,'preferred_baseline');
wage_index = find_id(rows,'wage_moderation_post_only');
if isempty(ui_index) || isempty(wage_index)
    return
end
selected = rows([ui_index wage_index]);
if any(arrayfun(@(x) ~path_available(x),selected))
    return
end

visibility = 'off';
if logical(options.visible), visibility = 'on'; end
fig = figure('Name','UI Reform and Wage Moderation', ...
    'Color','w','Visible',visibility,'Position',[60 40 1500 1180]);
cleanup = onCleanup(@() close_if_valid(fig)); %#ok<NASGU>
layout = tiledlayout(fig,4,3,'TileSpacing','compact','Padding','compact');

specs = { ...
    'WagePct','Average Wage','Percent Deviation'; ...
    'UnemploymentPP','Unemployment','Percentage-Point Change'; ...
    'HouseholdCashSavingPP','Household Savings Rate','Percentage-Point Change'; ...
    'NationalSavingPP','National Saving','Percentage-Point Change'; ...
    'ConsumptionPct','Consumption','Percent Deviation'; ...
    'InvestmentPct','Investment','Percent Deviation'; ...
    'TradableEmploymentPct','Tradable Employment','Percent Deviation'; ...
    'NontradableEmploymentPct','Nontradable Employment','Percent Deviation'; ...
    'RERPct','Real Exchange Rate','Percent Deviation'; ...
    'ExportsPct','Exports','Percent Deviation'; ...
    'NXPctAnnualOutput','Net Exports','Percent of Initial Annual Output'; ...
    'NFAChangePctAnnualOutput','Net Foreign Assets','Percent of Initial Annual Output'};
colors = [0.10 0.32 0.65; 0.78 0.24 0.20];
styles = {'-','--'};
labels = {'UI Reform'; 'Wage Moderation'};

for panel = 1:size(specs,1)
    ax = nexttile(layout);
    hold(ax,'on');
    handles = gobjects(0);
    for i = 1:2
        path = selected(i).path_table;
        variable = specs{panel,1};
        use = path.Quarter <= options.horizon;
        if sum(use) < 8, use(:) = true; end
        panel_series = path.(variable);
        handles(end+1) = plot(ax,path.Quarter(use),panel_series(use), ...
            'Color',colors(i,:),'LineStyle',styles{i},'LineWidth',1.8, ...
            'DisplayName',labels{i}); %#ok<AGROW>
    end
    paper_zero_line(ax);
    title(ax,specs{panel,2});
    xlabel(ax,'Quarter'); ylabel(ax,specs{panel,3});
    grid(ax,'on'); box(ax,'off');
    if panel == 1
        legend(ax,handles,labels,'Location','best','Interpreter','none');
    end
end

stem = char(string(options.file_stem));
png_path = fullfile(output_dir,[stem '.png']);
pdf_path = fullfile(output_dir,[stem '.pdf']);
eps_path = fullfile(output_dir,[stem '.eps']);
fig_path = fullfile(output_dir,[stem '.fig']);
exportgraphics(fig,png_path,'Resolution',600);
exportgraphics(fig,pdf_path,'ContentType','vector');
exportgraphics(fig,eps_path,'ContentType','vector');
savefig(fig,fig_path);

files.available = true;
files.status = "available";
files.message = "";
files.png = string(png_path);
files.pdf = string(pdf_path);
files.eps = string(eps_path);
files.fig = string(fig_path);
files.included_scenarios = ["preferred_baseline";"wage_moderation_post_only"];
end


function rows = normalize_rows(rows)
if isempty(rows)
    rows = repmat(struct(),0,1);
elseif iscell(rows)
    rows = vertcat(rows{:});
elseif istable(rows)
    rows = table2struct(rows);
end
assert(isstruct(rows),'ReviewerSuite:WagePlotRows', ...
    'rows must be a struct array, cell array of structs, or table.');
rows = rows(:);
end


function index = find_id(rows,id)
index = [];
for i = 1:numel(rows)
    if isfield(rows(i),'scenario_id') ...
            && strcmpi(char(string(rows(i).scenario_id)),id)
        index = i;
        return
    end
end
end


function flag = path_available(row)
flag = isfield(row,'path_table') && istable(row.path_table) ...
    && height(row.path_table) >= 8;
if flag && isfield(row,'solver') && isstruct(row.solver) ...
        && isfield(row.solver,'transition_solved')
    flag = isequal(row.solver.transition_solved,true);
end
end


function close_if_valid(fig)
if isgraphics(fig), close(fig); end
end
