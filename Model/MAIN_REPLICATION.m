function result = MAIN_REPLICATION(resume_run_id)
%MAIN_REPLICATION Recompute only the figures and tables in the paper and OA.
% Run MAIN_REPLICATION() for a new isolated run. To resume an interrupted
% run created by this entry point, use MAIN_REPLICATION('printed_run_id').
% Add Dynare 5.4 to the MATLAB path before running.
% The main paper and online appendix are computed together.

if nargin < 1
    resume_run_id = '';
end

model_dir = fileparts(mfilename('fullpath'));
original_dir = pwd;
original_path = path;
restore_environment = onCleanup(@() restore_matlab_environment( ...
    original_dir,original_path)); %#ok<NASGU>
cd(model_dir);
addpath(model_dir,fullfile(model_dir,'functions'),'-begin');

matlab_release = version('-release');
assert(any(strcmpi(matlab_release,{'2024b','2026a'})), ...
    'EERReplication:MATLABRelease', ...
    'Use MATLAB R2024b or the verified R2026a environment.');
assert(~isempty(which('dynare')), 'EERReplication:DynareMissing', ...
    'Add Dynare 5.4 to the MATLAB path before running this function.');

if strlength(string(resume_run_id)) == 0
    run_id = ['eer_paper_' datestr(now,'yyyymmddTHHMMSS')];
    resume = false;
else
    run_id = char(string(resume_run_id));
    resume = true;
end

options = struct( ...
    'run_id',run_id, ...
    'resume',resume, ...
    'paper_outputs_only',true, ...
    'main_paper_only',false, ...
    'publish_latest',false, ...
    'figures_visible',false, ...
    'require_matlab_release',matlab_release);

result = run_paper_outputs(options);
fprintf('Paper-output run: %s\n',run_id);
fprintf('Inspect paper_outputs/Full_Runs/%s/full_run_manifest.json.\n',run_id);
end

function restore_matlab_environment(original_dir,original_path)
cd(original_dir);
path(original_path);
end
