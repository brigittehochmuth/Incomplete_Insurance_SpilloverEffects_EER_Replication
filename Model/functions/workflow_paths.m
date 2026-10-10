function paths = workflow_paths()
%WORKFLOW_PATHS Resolve the baseline source and output folders.

paths.functions_dir = fileparts(mfilename('fullpath'));
paths.code_dir = fileparts(paths.functions_dir);
paths.results_dir = fullfile(paths.code_dir, 'Results');
if ~isfolder(paths.results_dir)
    mkdir(paths.results_dir);
end
end
