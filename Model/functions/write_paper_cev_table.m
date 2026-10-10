function output = write_paper_cev_table(run_dir,table_dir)
%WRITE_PAPER_CEV_TABLE Write manuscript Table 6 from a solved baseline path.

arguments
    run_dir (1,:) char
    table_dir (1,:) char
end
if ~isfolder(table_dir), mkdir(table_dir); end

configuration = struct('separation_multiplier_a',1.0, ...
    'separation_multiplier_b',1.0);
[welfare,status] = calculate_welfare('preferred_baseline',run_dir, ...
    struct('configuration',configuration,'weight_tolerance',1e-10));
assert(status.available && strcmpi(string(status.status),'available'), ...
    'PaperOutputs:Table6Welfare', ...
    'Baseline welfare reconstruction is unavailable: %s',status.message);

groups = ["Aggregate";"Employed";"EU1";"EU2";"EU3";"EU4"; ...
    "EU5";"EU6";"EU7";"EU8";"LTU"];
home = values_for_country(welfare,groups,"Home");
foreign = values_for_country(welfare,groups,"Foreign");
table6 = table(groups,home,foreign, ...
    'VariableNames',{'Group','Home','Foreign'});

csv_path = fullfile(table_dir,'Table_6_CEV_Home_Foreign.csv');
tex_path = fullfile(table_dir,'Table_6_CEV_Home_Foreign.tex');
writetable(table6,csv_path);

fid = fopen(tex_path,'w');
assert(fid >= 0,'PaperOutputs:Table6Open','Could not write %s.',tex_path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'\\begin{table}[!htbp]\n\\centering\n');
fprintf(fid,'\\caption{Consumption Equivalent Variation (CEV) by Group and Country}\n');
fprintf(fid,'\\label{table:cev_groups}\n');
fprintf(fid,'\\resizebox{0.78\\textwidth}{!}{\\begin{tabular}{lrr}\n\\toprule\n');
fprintf(fid,'Group & Reforming Economy (A) & Non-Reforming Economy (B) \\\\');
fprintf(fid,'\n\\midrule\n');
for i = 1:height(table6)
    if strcmp(table6.Group(i),"EU1")
        fprintf(fid,'\\multicolumn{3}{l}{\\textit{Short-Term Unemployed}} \\\\');
        fprintf(fid,'\n');
    end
    if strcmp(table6.Group(i),"LTU")
        label = 'Long-Term Unemployed (LTU)';
    else
        label = char(table6.Group(i));
    end
    fprintf(fid,'%s & %.2f & %.2f \\\\',label,table6.Home(i),table6.Foreign(i));
    fprintf(fid,'\n');
    if ismember(table6.Group(i),["Aggregate","Employed","EU8"])
        fprintf(fid,'\\midrule\n');
    end
end
fprintf(fid,'\\bottomrule\n\\end{tabular}}\n');
fprintf(fid,['\\begin{flushleft}\\footnotesize \\textit{Notes:} Entries are ', ...
    'percent changes in permanent consumption relative to the pre-reform ', ...
    'steady state. The aggregate row uses pre-reform population weights. ', ...
    'The transition recursion uses next-period job-finding probabilities ', ...
    'and advances unmatched workers from EU1 through EU8 and then to LTU.', ...
    '\\end{flushleft}\n\\end{table}\n']);

output = struct('csv',csv_path,'tex',tex_path, ...
    'source_scenario','preferred_baseline','source_run_dir',run_dir, ...
    'method','Corrected Transition Recursion', ...
    'home_weight_gap',status.home_weight_gap, ...
    'foreign_weight_gap',status.foreign_weight_gap);
end


function values = values_for_country(welfare,groups,country)
values = NaN(numel(groups),1);
for i = 1:numel(groups)
    mask = strcmpi(string(welfare.Country),country) ...
        & strcmpi(string(welfare.Group),groups(i)) ...
        & logical(welfare.Available);
    assert(sum(mask) == 1,'PaperOutputs:Table6Grid', ...
        'Expected one available %s/%s welfare row.',country,groups(i));
    values(i) = welfare.CEVPct(mask);
end
assert(all(isfinite(values)),'PaperOutputs:Table6Finite', ...
    'Table 6 contains a non-finite CEV.');
end
