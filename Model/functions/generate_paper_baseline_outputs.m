function output = generate_paper_baseline_outputs( ...
        run_dir,code_dir,visible,paper_dir)
%GENERATE_PAPER_BASELINE_OUTPUTS Create stable manuscript-ready baseline files.
%   This function reports from an existing solved transition and never calls
%   Dynare. The expensive robustness suite is dispatched separately.

arguments
    run_dir (1,:) char
    code_dir (1,:) char
    visible (1,1) logical = false
    paper_dir (1,:) char = ''
end

if isempty(paper_dir)
    paper_dir = fullfile(code_dir,'paper_outputs');
end
figure_dir = fullfile(paper_dir,'Figures');
table_dir = fullfile(paper_dir,'Tables');
staging_dir = fullfile(code_dir,'Results','paper_output_staging','baseline');
staging_figure_dir = fullfile(staging_dir,'Figures');
staging_table_dir = fullfile(staging_dir,'Tables');
if ~isfolder(paper_dir), mkdir(paper_dir); end
if ~isfolder(figure_dir), mkdir(figure_dir); end
if ~isfolder(table_dir), mkdir(table_dir); end
if ~isfolder(staging_figure_dir), mkdir(staging_figure_dir); end
if ~isfolder(staging_table_dir), mkdir(staging_table_dir); end

extended = write_extended_baseline_outputs(run_dir,visible=visible, ...
    target_year=2014,output_dir=staging_dir,figure_dir=staging_figure_dir, ...
    table_dir=staging_table_dir);
current = write_current_calibration_exhibit(run_dir,staging_dir,visible);

figures = { ...
    'savings_and_production_selected_calibration','Figure_2_Savings_And_Production'; ...
    'savings_and_production_selected_calibration_unit_labor_costs', ...
        'Figure_2_Savings_And_Production_Unit_Labor_Costs'; ...
    'savings_and_production_selected_calibration_unit_labor_costs_only', ...
        'Figure_2_Savings_And_Production_Unit_Labor_Costs_Only'; ...
    'domestic_labor_market_selected_calibration','Figure_3_Domestic_Labor_Market'; ...
    'foreign_economy_selected_calibration','Figure_5_Foreign_Economy'; ...
    'fiscal_space_selected_calibration','Figure_6_Fiscal_Space'};
stable = repmat(struct('stem','','png','','pdf','','eps','','fig',''), ...
    size(figures,1),1);
for i = 1:size(figures,1)
    source_stem = fullfile(staging_figure_dir,figures{i,1});
    target_stem = fullfile(figure_dir,figures{i,2});
    copyfile([source_stem '.png'],[target_stem '.png'],'f');
    copyfile([source_stem '.eps'],[target_stem '.eps'],'f');
    copyfile([source_stem '.fig'],[target_stem '.fig'],'f');
    handle = openfig([source_stem '.fig'],'invisible');
    exportgraphics(handle,[target_stem '.pdf'],'ContentType','vector');
    close(handle);
    stable(i).stem = figures{i,2};
    stable(i).png = [target_stem '.png'];
    stable(i).pdf = [target_stem '.pdf'];
    stable(i).eps = [target_stem '.eps'];
    stable(i).fig = [target_stem '.fig'];
end

table4 = write_paper_long_run_table(run_dir,extended.long_run_csv,table_dir);
table6 = write_paper_cev_table(run_dir,table_dir);
calibration_tables = write_paper_calibration_tables(run_dir,table_dir);
manifest = struct('created',datestr(now,30),'reporting_only',true, ...
    'model_solve',false,'baseline_run_dir',run_dir, ...
    'baseline_calibration',struct('bargaining','STU1','reform_cut', ...
        0.37891718657,'chi_T',1.0,'chi_NT',3.5, ...
    'investment_adjustment_cost',8.7,'entitlement_cut_periods',4), ...
    'zero_line',struct('style','dashed','color',[0.28 0.28 0.28], ...
        'line_width',1.15),'figures',stable, ...
    'table4',table4.compatibility,'table4a',table4.table4a, ...
    'table4b',table4.table4b,'table6',table6, ...
    'calibration_tables',calibration_tables);
manifest_path = fullfile(paper_dir,'baseline_output_manifest.json');
fid = fopen(manifest_path,'w');
assert(fid >= 0,'PaperOutputs:ManifestOpen','Could not write %s.',manifest_path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s\n',jsonencode(manifest,'PrettyPrint',true));

output = struct('directory',paper_dir,'figures',stable, ...
    'table4',table4.compatibility,'table4a',table4.table4a, ...
    'table4b',table4.table4b,'table6',table6, ...
    'calibration_tables',calibration_tables, ...
    'manifest',manifest_path,'extended',extended,'current',current);
end
