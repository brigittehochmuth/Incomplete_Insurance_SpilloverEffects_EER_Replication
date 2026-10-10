function MAIN_DESCRIPTIVES()
% Regenerate Figures 2-5 and 11-13 from retained plotting inputs.
root = fileparts(mfilename('fullpath'));
original_dir = pwd;
original_path = path;
original_axes_font = get(groot,'DefaultAxesFontName');
original_text_font = get(groot,'DefaultTextFontName');
cleanup = onCleanup(@() restore_environment(original_dir,original_path, ...
    original_axes_font,original_text_font)); %#ok<NASGU>
cd(root);
addpath(root,fullfile(root,'descriptive_figures'));
output = fullfile(root,'Generated');
[~,FigureDir,~] = get_results_paths(output);
G_Y_a = []; %#ok<NASGU> Legacy plotting script reads only its unused length.
figure_intro_precsaving;
figure_ca_euro;
figure_ca_savings(output);
AustriaFranceGermany_version2_BH;
create_figure;
mapping = {
    'Intro_fig_U_NFA_NX','Figure_02_Unemployment_NFA_Trade';
    'CA_Euro_ULC_2','Figure_03_Current_Account_ULC';
    'ca_savings1','Figure_04_Current_Account_Savings_1991_2021';
    'Intro_comp_VA_Service','Figure_05_Labor_Costs';
    'AUT_FRA_GER','Figure_11_Austria_France_Germany';
    'figure_appendix','Figure_12_Sector_Net_Savings';
    'figure_current_account','Figure_13_Current_Account_Groups'};
for i = 1:size(mapping,1)
    for extension = {'.eps','.png'}
        source = fullfile(FigureDir,[mapping{i,1} extension{1}]);
        assert(isfile(source),'Missing descriptive export: %s',source);
        copyfile(source,fullfile(output,[mapping{i,2} extension{1}]));
    end
end
accounts = load(fullfile(root,'data','differentaccounts.mat'));
correlation = corrcoef(accounts.households,accounts.eurozone);
fid = fopen(fullfile(output,'Descriptive_Run_Report.txt'),'w');
fprintf(fid,'MATLAB: %s\nGenerated: %s\n',version,datestr(now,30));
fprintf(fid,'1991-2019 household net savings / Eurozone CA correlation: %.10f\n',correlation(1,2));
fprintf(fid,'Figure 3 retains the accepted series; its labels now state 2015 normalization.\n');
fprintf(fid,'Figure 4 uses 1991-2021 OECD Main Economic Indicators current-account and IMF April 2024 savings inputs.\n');
fprintf(fid,'The accepted Figure 4 values match these inputs at plotted precision; exact original download dates remain unverified.\n');
fprintf(fid,'Data-to-plot execution is separate from upstream source-vintage verification. See ReadMe.md.\n');
fclose(fid);
end

function restore_environment(folder,paths,axes_font,text_font)
cd(folder);
path(paths);
set(groot,'DefaultAxesFontName',axes_font,'DefaultTextFontName',text_font);
end
