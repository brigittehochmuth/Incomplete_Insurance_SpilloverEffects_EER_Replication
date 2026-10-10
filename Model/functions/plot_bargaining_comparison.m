function files = plot_bargaining_comparison(output_dir,rows,options)
%PLOT_BARGAINING_COMPARISON Plot comparable bargaining transition paths.
%
% files = plot_bargaining_comparison(output_dir,rows)
% files = plot_bargaining_comparison(output_dir,rows,options)
%
% rows is the struct array returned by collect_scenario_results.  The
% figure uses line style as well as color, plots Tradable and Nontradable
% Employment in separate panels, and omits failed scenarios without
% replacing their paths with zeros.

if nargin < 3 || isempty(options)
    options = struct();
end
if ~isfield(options,'comparison_type'), options.comparison_type = "fixed_parameter"; end
if ~isfield(options,'file_stem') || strlength(string(options.file_stem)) == 0
    if contains(lower(string(options.comparison_type)),"target")
        options.file_stem = "bargaining_comparison_targeted";
    else
        options.file_stem = "bargaining_comparison_fixed";
    end
end
if ~isfield(options,'visible'), options.visible = false; end
if ~isfield(options,'horizon'), options.horizon = 50; end
if ~isfolder(output_dir), mkdir(output_dir); end
rows = normalize_rows(rows);

files = struct('available',false,'status',"unavailable", ...
    'message',"No eligible transition paths were available.", ...
    'png',"",'pdf',"",'fig',"",'comparison_type', ...
    string(options.comparison_type),'included_scenarios',strings(0,1), ...
    'missing_modes',strings(0,1));
if isempty(rows)
    return
end

mode_names = ["STU1";"All Unemployed"; ...
    "Labor-Force-Weighted Collective Bargaining"];
selected_indices = zeros(0,1);
included = strings(0,1);
missing = strings(0,1);
for mode = 1:3
    index = find_candidate(rows,options.comparison_type,mode);
    if isempty(index)
        missing(end+1,1) = mode_names(mode); %#ok<AGROW>
    else
        selected_indices(end+1,1) = index; %#ok<AGROW>
        included(end+1,1) = string(rows(index).scenario_id); %#ok<AGROW>
    end
end
if isempty(selected_indices)
    files.missing_modes = missing;
    return
end
selected = rows(selected_indices);

visibility = 'off';
if logical(options.visible), visibility = 'on'; end
fig = figure('Name','Bargaining Outside-Option Comparison', ...
    'Color','w','Visible',visibility,'Position',[60 40 1500 1180]);
cleanup = onCleanup(@() close_if_valid(fig)); %#ok<NASGU>
layout = tiledlayout(fig,4,3,'TileSpacing','compact','Padding','compact');
specs = { ...
    'WagePct','Average Wage','Percent Deviation'; ...
    'HouseholdCashSavingPP','Household Savings Rate','Percentage-Point Change'; ...
    'EmploymentPct','Employment','Percent Deviation'; ...
    'ExportsPct','Exports','Percent Deviation'; ...
    'ConsumptionPct','Consumption','Percent Deviation'; ...
    'InvestmentPct','Investment','Percent Deviation'; ...
    'TradableEmploymentPct','Tradable Employment','Percent Deviation'; ...
    'NontradableEmploymentPct','Nontradable Employment','Percent Deviation'; ...
    'RERPct','Real Exchange Rate','Percent Deviation'; ...
    'NXPctAnnualOutput','Net Exports','Percent of Initial Annual Output'; ...
    'CAPctAnnualOutput','Current Account','Percent of Initial Annual Output'; ...
    'NFAChangePctAnnualOutput','Net Foreign Assets','Percent of Initial Annual Output'};
colors = [0.10 0.32 0.65; 0.88 0.47 0.12; 0.42 0.48 0.17];
styles = {'-','--','-.'};

for panel = 1:size(specs,1)
    ax = nexttile(layout);
    hold(ax,'on');
    handles = gobjects(0); labels = strings(0,1);
    for i = 1:numel(selected)
        path = selected(i).path_table;
        variable = specs{panel,1};
        if ~istable(path) || ~all(ismember({'Quarter',variable}, ...
                path.Properties.VariableNames)) || height(path) < 8
            continue
        end
        mode = classify_mode(selected(i));
        if isnan(mode), mode = min(i,3); end
        use = path.Quarter <= options.horizon;
        if sum(use) < 8, use(:) = true; end
        panel_series = path.(variable);
        h = plot(ax,path.Quarter(use),panel_series(use), ...
            'Color',colors(mode,:),'LineStyle',styles{mode}, ...
            'LineWidth',1.8,'DisplayName',char(mode_names(mode)));
        handles(end+1) = h; %#ok<AGROW>
        labels(end+1,1) = mode_names(mode); %#ok<AGROW>
    end
    paper_zero_line(ax);
    title(ax,specs{panel,2});
    xlabel(ax,'Quarter'); ylabel(ax,specs{panel,3});
    grid(ax,'on'); box(ax,'off');
    if ~isempty(handles) && panel == 1
        legend(ax,handles,cellstr(labels),'Location','best', ...
            'Interpreter','none');
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

files.available = isempty(missing);
if files.available
    files.status = "available";
    files.message = "";
else
    files.status = "partial";
    files.message = "At least one bargaining mode had no eligible path.";
end
files.png = string(png_path);
files.pdf = string(pdf_path);
files.eps = string(eps_path);
files.fig = string(fig_path);
files.included_scenarios = included;
files.missing_modes = missing;
end


function rows = normalize_rows(rows)
if isempty(rows)
    rows = repmat(struct(),0,1);
elseif iscell(rows)
    rows = vertcat(rows{:});
elseif istable(rows)
    rows = table2struct(rows);
end
assert(isstruct(rows),'ReviewerSuite:PlotRows', ...
    'rows must be a struct array, cell array of structs, or table.');
rows = rows(:);
end


function index = find_candidate(rows,comparison_type,mode)
index = [];
for i = 1:numel(rows)
    if ~isfield(rows(i),'comparison_type') ...
            || ~comparison_matches(rows(i).comparison_type,comparison_type)
        continue
    end
    if classify_mode(rows(i)) ~= mode
        continue
    end
    if ~isfield(rows(i),'path_table') || ~istable(rows(i).path_table) ...
            || height(rows(i).path_table) < 8
        continue
    end
    if isfield(rows(i),'solver') && isstruct(rows(i).solver) ...
            && isfield(rows(i).solver,'transition_solved') ...
            && ~rows(i).solver.transition_solved
        continue
    end
    index = i;
    return
end
end


function tf = comparison_matches(candidate,requested)
candidate = normalize_text(candidate);
requested = normalize_text(requested);
candidate_auxiliary = contains(candidate,"auxiliary");
requested_auxiliary = contains(requested,"auxiliary");
if candidate_auxiliary ~= requested_auxiliary
    tf = false;
    return
end
if contains(requested,"target")
    tf = contains(candidate,"target");
elseif contains(requested,"fixed")
    tf = contains(candidate,"fixed");
else
    tf = candidate == requested;
end
end


function mode = classify_mode(row)
mode = NaN;
texts = strings(0,1);
if isfield(row,'configuration') && isstruct(row.configuration)
    for field = {'bargaining_mode_label','bargaining_mode_a'}
        if isfield(row.configuration,field{1})
            texts(end+1,1) = string(row.configuration.(field{1})); %#ok<AGROW>
        end
    end
end
if isfield(row,'scenario_label')
    texts(end+1,1) = string(row.scenario_label);
end
text = upper(strjoin(texts,' '));
if contains(text,"ALL_UNEMPLOYED") || contains(text,"ALL UNEMPLOYED") ...
        || contains(text,"OPTION A") || text == "1"
    mode = 2;
elseif contains(text,"LABOR_FORCE") || contains(text,"LABOR-FORCE") ...
        || contains(text,"COLLECTIVE") || contains(text,"OPTION B") ...
        || text == "2"
    mode = 3;
elseif contains(text,"STU1") || contains(text,"CURRENT") || text == "0"
    mode = 1;
end
end


function text = normalize_text(value)
text = lower(strtrim(string(value)));
text = regexprep(text,'[^a-z0-9]+','_');
end


function close_if_valid(fig)
if isgraphics(fig)
    close(fig);
end
end
