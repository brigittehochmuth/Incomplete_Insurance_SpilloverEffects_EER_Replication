function output = write_paper_long_run_table(run_dir,quarter160_csv,table_dir)
%WRITE_PAPER_LONG_RUN_TABLE Write steady-state and quarter-160 Table 4 panels.

arguments
    run_dir (1,:) char
    quarter160_csv (1,:) char
    table_dir (1,:) char
end
required_files = {'Names.mat','SS_init.mat','Names_H42_EB.mat','SS_H42_EB.mat'};
for i = 1:numel(required_files)
    assert(isfile(fullfile(run_dir,required_files{i})), ...
        'PaperOutputs:Table4Source', ...
        'Missing steady-state source file: %s.', ...
        fullfile(run_dir,required_files{i}));
end
assert(isfile(quarter160_csv),'PaperOutputs:Table4Quarter160Source', ...
    'Missing model-derived quarter-160 table: %s.',quarter160_csv);
if ~isfolder(table_dir), mkdir(table_dir); end

pre_names_data = load(fullfile(run_dir,'Names.mat'),'var_names');
pre_data = load(fullfile(run_dir,'SS_init.mat'),'SS_init');
post_names_data = load(fullfile(run_dir,'Names_H42_EB.mat'),'var_names');
post_data = load(fullfile(run_dir,'SS_H42_EB.mat'),'SS_H42_EB');
pre_names = strtrim(cellstr(pre_names_data.var_names));
post_names = strtrim(cellstr(post_names_data.var_names));
pre_values = pre_data.SS_init(:);
post_values = post_data.SS_H42_EB(:);
assert(numel(pre_names) == numel(pre_values), ...
    'PaperOutputs:Table4PreNames','Pre-reform names and values differ in length.');
assert(numel(post_names) == numel(post_values), ...
    'PaperOutputs:Table4PostNames','Post-reform names and values differ in length.');
pre = @(name) pre_values(require_name(pre_names,name));
post = @(name) post_values(require_name(post_names,name));
pct = @(post_level,pre_level) 100*(post_level/pre_level-1);

indicator = { ...
    'GDP';'GNP';'Aggr. Consumption';'Unemployment'; ...
    'C: Tradable';'C: Non-tradable'; ...
    'Tradable-to-non-tradable expenditure ratio'; ...
    'CPI';'TPI';'Wage';'Interest Rate';'Real Exchange Rate'; ...
    'Capital-Labor Ratio';'NFA/Output'};
home = country_effects('a',false,pre,post,pct);
foreign = country_effects('b',true,pre,post,pct);
steady_state = table(indicator,home,foreign, ...
    'VariableNames',{'Indicator','Home','Foreign'});
quarter160 = quarter160_table(quarter160_csv,indicator);

steady_caption = ['Long-run Reform Effects in Home and Foreign Economy ' ...
    '(\% dev. from steady state)'];
steady_notes = ['Changes compare the saved post-reform steady state with ' ...
    'the saved pre-reform steady state. The interest rate and NFA/output ' ...
    'are percentage-point changes.'];
quarter160_caption = ['Reform Effects in Home and Foreign Economy After ' ...
    '160 Quarters (\% dev. from pre-reform steady state)'];
quarter160_notes = ['Effects at quarter 160 (40 years) relative to the ' ...
    'pre-reform steady state. Unemployment, the interest rate, and ' ...
    'NFA/output are percentage-point changes.'];

table4a = write_formatted_table(steady_state,table_dir, ...
    'Table_4a_Steady_State_Reform_Effects',steady_caption, ...
    'table:tradable_eff',steady_notes);
table4b = write_formatted_table(quarter160,table_dir, ...
    'Table_4b_Quarter_160_Reform_Effects',quarter160_caption, ...
    'table:tradable_eff_q160',quarter160_notes);

compatibility_csv = fullfile(table_dir,'Table_4_Long_Run_Reform_Effects.csv');
compatibility_tex = fullfile(table_dir,'Table_4_Long_Run_Reform_Effects.tex');
copyfile(table4a.csv,compatibility_csv,'f');
copyfile(table4a.tex,compatibility_tex,'f');
compatibility = struct('csv',compatibility_csv,'tex',compatibility_tex, ...
    'alias_of','Table_4a_Steady_State_Reform_Effects');
output = struct('table4a',table4a,'table4b',table4b, ...
    'compatibility',compatibility,'run_dir',run_dir, ...
    'quarter160_source_csv',quarter160_csv);
end


function output = write_formatted_table(data,table_dir,stem,caption,label,notes)
csv_path = fullfile(table_dir,[stem '.csv']);
tex_path = fullfile(table_dir,[stem '.tex']);
writetable(data,csv_path);
fid = fopen(tex_path,'w');
assert(fid >= 0,'PaperOutputs:Table4Open','Could not write %s.',tex_path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'\\begin{table}[h]\n');
fprintf(fid,'\\caption{%s}\n',caption);
fprintf(fid,'\\centering\n');
fprintf(fid,'\\resizebox{0.5\\textwidth}{!}{\\begin{tabular}{l|rr}\n');
fprintf(fid,'\\toprule\n');
fprintf(fid,' & Home & Foreign \\\\');
fprintf(fid,'\n\\midrule\n');
for i = 1:height(data)
    row_label = data.Indicator{i};
    if strcmp(row_label,'Aggr. Consumption')
        row_label = ['\textbf{' row_label '}'];
        fprintf(fid,'%s & \\textbf{%.2f} & \\textbf{%.2f} \\\\', ...
            row_label,data.Home(i),data.Foreign(i));
        fprintf(fid,'\n');
    else
        fprintf(fid,'%s & %.2f & %.2f \\\\', ...
            row_label,data.Home(i),data.Foreign(i));
        fprintf(fid,'\n');
    end
    if ismember(i,[4 7 12])
        fprintf(fid,'\\midrule\n');
    end
end
fprintf(fid,'\\bottomrule\n\\end{tabular}}\n');
fprintf(fid,'\\label{%s}\n',label);
fprintf(fid,'\\begin{flushleft}\\footnotesize Notes: %s\\end{flushleft}\n',notes);
fprintf(fid,'\\end{table}\n');
output = struct('csv',csv_path,'tex',tex_path,'label',label);
end


function data = quarter160_table(source_csv,indicator)
source = readtable(source_csv,'TextType','string');
source_names = string(source.Indicator);
source_rows = [ ...
    "GDP";"GNP";"Aggregate Consumption";"Unemployment Rate Change"; ...
    "Tradable Consumption";"Nontradable Consumption"; ...
    "Tradables/Nontradables";"CPI";"TPI";"Wage";"Interest Rate"; ...
    "Real Exchange Rate";"Capital-Labor Ratio";"NFA/Output"];
home = NaN(numel(source_rows),1);
foreign = NaN(numel(source_rows),1);
for i = 1:numel(source_rows)
    index = find(source_names == source_rows(i));
    assert(isscalar(index),'PaperOutputs:Table4Quarter160Row', ...
        'Expected one row named "%s" in %s.',source_rows(i),source_csv);
    home(i) = source.Home(index);
    foreign(i) = source.Foreign(index);
end
data = table(indicator,home,foreign, ...
    'VariableNames',{'Indicator','Home','Foreign'});
end


function values = country_effects(country,invert_rer,pre,post,pct)
employment_pre = pre(['N_' country '_t']);
employment_post = post(['N_' country '_t']);
output_pre = pre(['Y_' country '_t']);
output_post = post(['Y_' country '_t']);
rer_pre = pre('rer_cpi_t');
rer_post = post('rer_cpi_t');
if invert_rer
    rer_change = pct(1/rer_post,1/rer_pre);
else
    rer_change = pct(rer_post,rer_pre);
end
values = [ ...
    pct(output_post,output_pre); ...
    pct(post(['GNP_' country '_t']),pre(['GNP_' country '_t'])); ...
    pct(post(['C_' country '_t']),pre(['C_' country '_t'])); ...
    100*((1-employment_post)-(1-employment_pre))/(1-employment_pre); ...
    pct(post(['cT_' country '_t']),pre(['cT_' country '_t'])); ...
    pct(post(['cN_' country '_t']),pre(['cN_' country '_t'])); ...
    pct(post(['trdb_vs_nontrdb_' country '_t']), ...
        pre(['trdb_vs_nontrdb_' country '_t'])); ...
    pct(post(['CPI_' country '_t']),pre(['CPI_' country '_t'])); ...
    pct(post(['TPI_' country '_t']),pre(['TPI_' country '_t'])); ...
    pct(post(['w_' country '_t']),pre(['w_' country '_t'])); ...
    100*(post('R_w_t')-pre('R_w_t')); ...
    rer_change; ...
    pct(post(['k_' country '_t'])/employment_post, ...
        pre(['k_' country '_t'])/employment_pre); ...
    100*(post(['NFA_' country '_t'])/(4*output_post) ...
        -pre(['NFA_' country '_t'])/(4*output_pre))];
end


function index = require_name(names,name)
index = find(strcmp(names,name),1);
assert(~isempty(index),'PaperOutputs:Table4Variable', ...
    'Missing steady-state variable %s.',name);
end
