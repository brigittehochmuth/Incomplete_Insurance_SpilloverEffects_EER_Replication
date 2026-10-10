function [SaveDir, FigureDir, TableDir] = get_results_paths(SaveDir)
if nargin < 1 || isempty(SaveDir)
    SaveDir = fullfile(pwd, 'Results');
end

FigureDir = fullfile(SaveDir, 'Figures');
TableDir = fullfile(SaveDir, 'Tables');

if ~exist(SaveDir, 'dir')
    mkdir(SaveDir);
end
if ~exist(FigureDir, 'dir')
    mkdir(FigureDir);
end
if ~exist(TableDir, 'dir')
    mkdir(TableDir);
end
end
