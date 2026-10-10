function outcome = run_scenario(scenario,context)
%RUN_SCENARIO Execute one isolated reviewer-suite scenario.
%   This is the suite's only model-execution interface.  It normalizes
%   failure handling, validated pre-reform artifact reuse, independent status
%   fields, bargaining diagnostics, and per-scenario checkpoint files.

assert(isstruct(scenario) && isscalar(scenario),'ReviewerSuite:Scenario', ...
    'scenario must be a scalar struct.');
assert(isstruct(context) && isscalar(context) && isfield(context,'output_dir'), ...
    'ReviewerSuite:Context','context.output_dir is required.');
context = fill_context_defaults(context);
master_diary_cleanup = onCleanup(@() restore_master_diary( ...
    context.master_log_path)); %#ok<NASGU>

scenario_id = char(require_scenario_field(scenario,'scenario_id'));
scenario_id = regexprep(scenario_id,'[^A-Za-z0-9_-]','_');
if isempty(context.scenario_mat_dir)
    context.scenario_mat_dir = fullfile(context.output_dir,'scenario_mat');
end
if isempty(context.cache_dir)
    context.cache_dir = fullfile(context.output_dir,'steady_state_cache');
end
ensure_folder(context.output_dir);
ensure_folder(context.scenario_mat_dir);

config = scenario_config(scenario);
config.throw_on_failure = false;
config.scenario_id = scenario_id;
[config.pre_reform_code_fingerprint,source_fingerprints,source_manifest] = ...
    numerical_code_fingerprint();
checkpoint_inputs = config;
checkpoint_inputs.suite_target_relative_employment_pct = ...
    context.target_relative_employment_pct;
checkpoint_inputs.suite_target_tolerance_pct = context.target_tolerance_pct;
checkpoint_inputs.suite_identity_tolerance = context.identity_tolerance;
checkpoint_inputs.suite_numerical_code_fingerprint = ...
    config.pre_reform_code_fingerprint;
[fingerprint_key,fingerprint_payload,fingerprint_fields] = ...
    configuration_hash(checkpoint_inputs,fieldnames(checkpoint_inputs));
checkpoint_fingerprint = struct('key',fingerprint_key, ...
    'payload',fingerprint_payload,'fields',{fingerprint_fields});

backend = char(string(field_or(config,'backend','incomplete')));
if strcmpi(backend,'complete')
    checkpoint_path = fullfile(context.scenario_mat_dir, ...
        [scenario_id '_complete_insurance.mat']);
else
    checkpoint_path = fullfile(context.scenario_mat_dir,[scenario_id '.mat']);
end

if context.resume && ~context.force && exist(checkpoint_path,'file') == 2
    saved = load(checkpoint_path,'outcome');
    if isfield(saved,'outcome') && isfield(saved.outcome,'checkpoint_complete') ...
            && saved.outcome.checkpoint_complete ...
            && checkpoint_fingerprint_matches( ...
                saved.outcome,checkpoint_fingerprint)
        outcome = saved.outcome;
        outcome.scenario_id = scenario_id;
        outcome.scenario_label = scenario_label(scenario);
        outcome.scenario = scenario;
        outcome.resumed = true;
        fprintf('PAPER SCENARIO RESUME %s from %s\n',scenario_id,checkpoint_path);
        return
    end
    fprintf(['PAPER SCENARIO CHECKPOINT STALE %s: full configuration ' ...
        'fingerprint changed; rerunning.\n'],scenario_id);
end

if strcmpi(backend,'complete')
    dispatch_scenario = scenario;
    dispatch_scenario.config = config;
    % The full source/configuration fingerprint was already checked above.
    % Reaching this branch means an old dispatcher checkpoint is stale or a
    % forced run was requested; do not resume it under the dispatcher's
    % weaker transition-only guard.
    dispatch_context = context;
    dispatch_context.resume = false;
    outcome = run_complete_insurance_scenario( ...
        dispatch_scenario,dispatch_context);
    outcome.result.checkpoint_fingerprint = checkpoint_fingerprint;
    outcome.checkpoint_path = checkpoint_path;
    save(checkpoint_path,'outcome','-v7.3');
    return
end

ensure_folder(context.cache_dir);
[cache_key,cache_payload,cache_fields] = configuration_hash(config);
cache_path = fullfile(context.cache_dir,[cache_key '.mat']);
cache_artifact_dir = fullfile(context.cache_dir,[cache_key '_artifacts']);
cache_hit = false;
cache_validation_message = 'No cache entry exists for this pre-reform hash.';
reported_config = config;
if exist(cache_path,'file') == 2
    try
        cached = load(cache_path,'cache_entry');
        if isfield(cached,'cache_entry')
            [cache_hit,cache_validation_message] = validate_cache_entry( ...
                cached.cache_entry,cache_key,cache_payload,cache_artifact_dir);
        else
            cache_validation_message = ...
                'Cache MAT file does not contain cache_entry.';
        end
    catch ME
        cache_validation_message = sprintf('%s: %s',ME.identifier,ME.message);
    end
    if cache_hit
        cached.cache_entry.artifact_dir = cache_artifact_dir;
        config.pre_reform_cache = cached.cache_entry;
        cache_hit = true;
    end
end

started = datestr(now,30);
fprintf('\nPAPER SCENARIO START %s: %s\n',scenario_id,scenario_label(scenario));
fprintf('Pre-reform cache: %s (validated hit=%d; %s)\n', ...
    cache_key,cache_hit,cache_validation_message);
result = failure_result(config,'not_started','Scenario was not started.');
try
    % Dynare uses global state.  Clearing it at scenario boundaries plus the
    % package purge inside run_baseline prevents one registry row from using
    % another row's M_, oo_, or options_.  Numerical evidence remains in the
    % scenario-specific run directory created by run_baseline.
    clear global M_ oo_ options_ steady_solver_seed_override
    result = run_baseline(config);
catch ME
    result = failure_result(config,'execution_exception', ...
        getReport(ME,'extended','hyperlinks','off'));
end
restore_master_diary(context.master_log_path);
config = reported_config;

cache_reused = logical_scalar(field_or(result,'pre_reform_cache_reused',false));
cache_source = char(string(field_or(result,'pre_reform_cache_source','')));
if cache_reused
    cache_validation_message = char(string(field_or(result, ...
        'pre_reform_cache_restore_message','Validated cache restored.')));
end
if ~cache_reused && cacheable_pre_reform_result(result)
    try
        cache_entry = write_pre_reform_cache(cache_path,cache_artifact_dir, ...
            cache_key,cache_payload,cache_fields,config,result);
        cache_source = cache_entry.source_run_dir;
        cache_validation_message = 'Fresh validated Gate-0 artifacts cached.';
    catch ME
        cache_validation_message = sprintf( ...
            'Validated Gate-0 cache write failed: %s: %s', ...
            ME.identifier,ME.message);
        fprintf(2,'%s\n',cache_validation_message);
    end
end
result.pre_reform_cache_reused = cache_reused;
result.pre_reform_cache_key = cache_key;
result.pre_reform_cache_source = cache_source;
result.pre_reform_cache_status = cache_validation_message;
result.source_code_fingerprints = source_fingerprints;
result.source_code_manifest = source_manifest;

bargaining = struct('available',false,'pass',false,'maximum_residual',NaN, ...
    'message','Transition did not solve.');
if transition_solved(result) && isfield(result,'run_dir') ...
        && isfolder(result.run_dir)
    try
        bargaining_output = write_bargaining_diagnostics( ...
            result.run_dir,config);
        residual_columns = [ ...
            bargaining_output.summary.maximum_surplus_identity_gap; ...
            bargaining_output.summary.maximum_population_share_gap; ...
            bargaining_output.summary.maximum_labor_force_identity_gap; ...
            bargaining_output.summary.maximum_nash_sharing_gap];
        bargaining.available = true;
        bargaining.maximum_residual = max(abs(residual_columns));
        bargaining.pass = bargaining.maximum_residual <= context.identity_tolerance;
        bargaining.message = '';
        bargaining.output = bargaining_output;
    catch ME
        bargaining.message = getReport(ME,'basic','hyperlinks','off');
    end
end


status = independent_status(result,bargaining,context);
result.steady_state_solved = status.steady_state_solved;
result.transition_solved = status.transition_solved;
result.accounting_pass = status.accounting_pass;
result.bargaining_identity_pass = status.bargaining_identity_pass;
result.target_pass = status.target_pass;
result.horizon_pass = status.horizon_pass;
result.economic_validation_pass = status.economic_validation_pass;
result.suite_status = status;
result.bargaining_diagnostics = bargaining;
result.checkpoint_fingerprint = checkpoint_fingerprint;

outcome = struct('scenario_id',scenario_id,'scenario_label',scenario_label(scenario), ...
    'scenario',scenario,'configuration',config,'result',result,'status',status, ...
    'cache_key',cache_key,'cache_hit',cache_hit,'cache_reused',cache_reused, ...
    'cache_source',cache_source,'cache_status',cache_validation_message, ...
    'cache_path',cache_path, ...
    'started',started,'finished',datestr(now,30),'resumed',false, ...
    'checkpoint_complete',true,'checkpoint_path',checkpoint_path);
save(checkpoint_path,'outcome','-v7.3');
fprintf('PAPER SCENARIO END %s: steady=%d transition=%d accounting=%d bargaining=%d target=%d horizon=%d economic=%d\n', ...
    scenario_id,status.steady_state_solved,status.transition_solved, ...
    status.accounting_pass,status.bargaining_identity_pass,status.target_pass, ...
    status.horizon_pass,status.economic_validation_pass);
clear global M_ oo_ options_ steady_solver_seed_override
end


function config = scenario_config(scenario)
if isfield(scenario,'config')
    config = scenario.config;
else
    config = scenario;
end
end


function label = scenario_label(scenario)
if isfield(scenario,'scenario_label')
    label = char(string(scenario.scenario_label));
elseif isfield(scenario,'label')
    label = char(string(scenario.label));
else
    label = char(string(scenario.scenario_id));
end
end


function value = require_scenario_field(scenario,name)
assert(isfield(scenario,name),'ReviewerSuite:ScenarioField', ...
    'Scenario is missing required field %s.',name);
value = scenario.(name);
end


function status = independent_status(result,bargaining,context)
status = struct();
status.steady_state_solved = steady_state_solved(result);
status.transition_solved = transition_solved(result);
status.accounting_pass = false;
status.bargaining_identity_pass = bargaining.pass;
status.target_pass = false;
status.horizon_pass = false;
status.economic_validation_pass = false;
status.relative_employment_pct = NaN;
status.target_gap_pct = NaN;
status.message = field_or(result,'message','');

if isfield(result,'diagnostics')
    d = result.diagnostics;
    if isfield(d,'accounting')
        identity_pass = logical_scalar(field_or( ...
            d.accounting,'identity_pass',false));
        exact_pass = logical_scalar(field_or( ...
            d.accounting,'exact_gate_pass',false));
        status.accounting_pass = identity_pass && exact_pass;
    end
    if isfield(d,'sector')
        status.relative_employment_pct = field_or( ...
            d.sector,'rel_emp_a_q1_40_avg_pct',NaN);
        status.target_gap_pct = status.relative_employment_pct ...
            -context.target_relative_employment_pct;
        status.target_pass = isfinite(status.target_gap_pct) ...
            && abs(status.target_gap_pct) <= context.target_tolerance_pct;
        rer_average = field_or(d.sector,'rer_cpi_q1_40_avg_pct',NaN);
        export_average = field_or( ...
            d.sector,'export_volume_q5_40_avg_pct',NaN);
        nx_impact = field_or( ...
            d.sector,'nx_impact_pct_annual_output',NaN);
        ca_impact = field_or( ...
            d.sector,'ca_impact_pct_annual_output',NaN);
        nfa_q40 = NaN;
        if isfield(d,'accounting')
            nfa_q40 = field_or(d.accounting, ...
                'home_nfa_q40_change_pct_annual_output',NaN);
        end
        positivity_pass = logical_scalar(field_or( ...
            d.sector,'positivity_pass',false));
        status.economic_validation_pass = all(isfinite([ ...
            rer_average,export_average,nx_impact,ca_impact,nfa_q40])) ...
            && rer_average < 0 && export_average > 0 ...
            && nx_impact > 0 && ca_impact > 0 && nfa_q40 > 0 ...
            && positivity_pass;
    end
    if isfield(d,'horizon_insensitivity_pass')
        status.horizon_pass = isequal(d.horizon_insensitivity_pass,true);
    end
end
end


function flag = checkpoint_fingerprint_matches(outcome,expected)
flag = false;
if ~isstruct(outcome) || ~isscalar(outcome) ...
        || ~isfield(outcome,'result') || ~isstruct(outcome.result) ...
        || ~isscalar(outcome.result) ...
        || ~isfield(outcome.result,'checkpoint_fingerprint')
    return
end
actual = outcome.result.checkpoint_fingerprint;
if ~isstruct(actual) || ~isscalar(actual) ...
        || ~isfield(actual,'key') || ~isfield(actual,'payload')
    return
end
flag = strcmp(char(string(actual.key)),char(string(expected.key))) ...
    && strcmp(char(string(actual.payload)),char(string(expected.payload)));
end


function flag = logical_scalar(value)
flag = (islogical(value) || isnumeric(value)) ...
    && isscalar(value) && isfinite(double(value)) && logical(value);
end


function flag = steady_state_solved(result)
flag = isfield(result,'gate0') && logical(field_or(result.gate0,'pass',false));
end


function flag = transition_solved(result)
flag = isfield(result,'transition_status') ...
    && isequal(result.transition_status,true) ...
    && isfield(result,'run_dir') ...
    && exist(fullfile(result.run_dir,'Sim_H42_EB.mat'),'file') == 2;
end


function [valid,message] = validate_cache_entry(entry,expected_key, ...
        expected_payload,artifact_dir)
valid = false;
message = 'Cache entry validation did not complete.';
try
    required_fields = {'schema_version','key','payload','fields', ...
        'configuration','source_run_dir','created','artifacts', ...
        'gate0','anchor','anchor_validation','initialization'};
    assert(isstruct(entry) && isscalar(entry) ...
        && all(isfield(entry,required_fields)), ...
        'ReviewerSuite:PreReformCacheSchema', ...
        'Cache entry is incomplete.');
    assert(isequal(entry.schema_version,2), ...
        'ReviewerSuite:PreReformCacheSchema', ...
        'Cache schema version is unsupported.');
    assert(strcmp(char(string(entry.key)),expected_key) ...
        && strcmp(char(string(entry.payload)),expected_payload), ...
        'ReviewerSuite:PreReformCacheHash', ...
        'Cache hash or canonical payload does not match current pre inputs.');
    assert(isstruct(entry.gate0) && isscalar(entry.gate0) ...
        && isfield(entry.gate0,'pass') && isequal(entry.gate0.pass,true), ...
        'ReviewerSuite:PreReformCacheGate', ...
        'Cache was not created from a passing Gate-0 solve.');
    assert(isstruct(entry.anchor_validation) ...
        && isscalar(entry.anchor_validation) ...
        && isfield(entry.anchor_validation,'pass') ...
        && isequal(entry.anchor_validation.pass,true), ...
        'ReviewerSuite:PreReformCacheAnchor', ...
        'Cached anchor evidence is not validated.');
    validate_cache_artifacts(artifact_dir,entry.artifacts,entry.initialization);
    valid = true;
    message = sprintf('Validated cache entry from %s.', ...
        char(string(entry.source_run_dir)));
catch ME
    message = sprintf('%s: %s',ME.identifier,ME.message);
end
end


function flag = cacheable_pre_reform_result(result)
flag = isstruct(result) && isscalar(result) ...
    && steady_state_solved(result) ...
    && isfield(result,'anchor_validation') ...
    && isstruct(result.anchor_validation) ...
    && isscalar(result.anchor_validation) ...
    && isfield(result.anchor_validation,'pass') ...
    && isequal(result.anchor_validation.pass,true) ...
    && isfield(result,'initialization') ...
    && isstruct(result.initialization) ...
    && isscalar(result.initialization) ...
    && logical_scalar(field_or(result,'pre_reform_artifacts_ready',false)) ...
    && isfield(result,'run_dir') && isfolder(result.run_dir);
end


function entry = write_pre_reform_cache(cache_path,artifact_dir,key,payload, ...
        fields,config,result)
required = required_cache_artifacts();
ensure_folder(artifact_dir);
manifest = repmat(struct('name','','bytes',0,'sha256',''),numel(required),1);
for i = 1:numel(required)
    source = fullfile(result.run_dir,required{i});
    assert(exist(source,'file') == 2, ...
        'ReviewerSuite:PreReformCacheArtifact', ...
        'Validated pre-reform artifact is missing: %s',source);
    destination = fullfile(artifact_dir,required{i});
    copyfile(source,destination,'f');
    info = dir(destination);
    manifest(i).name = required{i};
    manifest(i).bytes = info.bytes;
    manifest(i).sha256 = file_sha256(destination);
end
validate_cache_artifacts(artifact_dir,manifest,result.initialization);
entry = struct();
entry.schema_version = 2;
entry.key = key;
entry.payload = payload;
entry.fields = fields;
entry.configuration = config;
entry.source_run_dir = result.run_dir;
entry.created = datestr(now,30);
entry.artifacts = manifest;
entry.gate0 = result.gate0;
entry.anchor = result.anchor;
entry.anchor_validation = result.anchor_validation;
entry.initialization = result.initialization;
if isfield(result.anchor,'w_ts') && numel(result.anchor.w_ts) == 8
    entry.steady_solver_seed = reshape(result.anchor.w_ts,1,[]);
else
    entry.steady_solver_seed = [];
end
cache_entry = entry; %#ok<NASGU>
save(cache_path,'cache_entry','-v7.3');
end


function validate_cache_artifacts(artifact_dir,manifest,initialization)
required = required_cache_artifacts();
assert(isfolder(artifact_dir), ...
    'ReviewerSuite:PreReformCacheArtifact', ...
    'Cache artifact directory is missing.');
assert(isstruct(manifest) && numel(manifest) == numel(required), ...
    'ReviewerSuite:PreReformCacheManifest', ...
    'Cache artifact manifest has the wrong size.');
names = cellstr(string({manifest.name}));
assert(numel(unique(names)) == numel(required) ...
    && all(ismember(required,names)), ...
    'ReviewerSuite:PreReformCacheManifest', ...
    'Cache artifact manifest does not contain the required file set.');
for i = 1:numel(required)
    index = find(strcmp(names,required{i}),1);
    path = fullfile(artifact_dir,required{i});
    info = dir(path);
    assert(exist(path,'file') == 2 && isscalar(info) ...
        && info.bytes == manifest(index).bytes ...
        && strcmp(file_sha256(path),char(string(manifest(index).sha256))), ...
        'ReviewerSuite:PreReformCacheArtifact', ...
        'Cache artifact %s is missing or does not match its manifest.', ...
        required{i});
end
required_initialization = {'steady_state','parameters','var_names', ...
    'param_names','param_values'};
assert(isstruct(initialization) && isscalar(initialization) ...
    && all(isfield(initialization,required_initialization)), ...
    'ReviewerSuite:PreReformCacheInitialization', ...
    'Cache initialization evidence is incomplete.');
ss = load(fullfile(artifact_dir,'SS_init.mat'),'SS_init');
parameters = load(fullfile(artifact_dir,'Param_init.mat'),'Param_init');
loaded_names = load(fullfile(artifact_dir,'Names.mat'), ...
    'var_names','param_names','param_values');
assert(isfield(ss,'SS_init') && isfield(parameters,'Param_init') ...
    && all(isfield(loaded_names,{'var_names','param_names','param_values'})) ...
    && isvector(ss.SS_init) && isvector(parameters.Param_init) ...
    && all(isfinite(ss.SS_init(:))) ...
    && ~any(isinf(parameters.Param_init(:))) ...
    && numel(ss.SS_init) == numel(loaded_names.var_names) ...
    && numel(parameters.Param_init) == numel(loaded_names.param_names) ...
    && numel(parameters.Param_init) == numel(loaded_names.param_values) ...
    && isequal(ss.SS_init(:),initialization.steady_state(:)) ...
    && isequaln(parameters.Param_init(:),initialization.parameters(:)) ...
    && isequaln(parameters.Param_init(:),loaded_names.param_values(:)), ...
    'ReviewerSuite:PreReformCacheInitialization', ...
    'Cache MAT artifacts and initialization evidence are inconsistent.');
end


function names = required_cache_artifacts()
names = {'SS_init.mat','Param_init.mat','Names.mat', ...
    'SS_init.mod','Param_init.mod'};
end


function [fingerprint,fingerprints,manifest] = numerical_code_fingerprint()
[fingerprints,manifest] = source_fingerprint();
fingerprint = fingerprints.numerical;
end


function hex = file_sha256(path)
fid = fopen(path,'rb');
assert(fid >= 0,'ReviewerSuite:PreReformCacheArtifact', ...
    'Could not open cache artifact %s.',path);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
bytes = fread(fid,Inf,'*uint8');
try
    engine = java.security.MessageDigest.getInstance('SHA-256');
    engine.update(bytes);
    digest = typecast(engine.digest(),'uint8');
    hex = lower(reshape(dec2hex(digest,2).',1,[]));
catch
    codes = double(bytes(:)');
    first = mod(sum(codes.*(1:numel(codes))),4294967291);
    second = mod(sum(codes.*mod((1:numel(codes)).^2,4294967279)),4294967279);
    hex = sprintf('fallback_%08x_%08x',uint32(first),uint32(second));
end
end


function value = field_or(source,name,fallback)
if isstruct(source) && isfield(source,name)
    value = source.(name);
else
    value = fallback;
end
end


function result = failure_result(config,phase,message)
if isfield(config,'pre_reform_cache')
    config = rmfield(config,'pre_reform_cache');
end
result = struct('complete',false,'phase',phase,'timestamp',datestr(now,30), ...
    'run_dir','','configuration',config,'message',message, ...
    'gate0',struct('pass',false),'stage_checks',struct(), ...
    'anchor',struct(),'anchor_validation',struct('pass',false), ...
    'pre_reform_cache_reused',false,'pre_reform_cache_key','', ...
    'pre_reform_cache_source','','pre_reform_artifacts_ready',false);
end


function ensure_folder(path)
if ~isfolder(path)
    mkdir(path);
end
end


function context = fill_context_defaults(context)
defaults = struct('cache_dir','','scenario_mat_dir','','resume',true, ...
    'force',false,'target_relative_employment_pct',2.7, ...
    'target_tolerance_pct',0.01,'identity_tolerance',1e-10, ...
    'master_log_path','');
names = fieldnames(defaults);
for i = 1:numel(names)
    if ~isfield(context,names{i})
        context.(names{i}) = defaults.(names{i});
    end
end
end


function restore_master_diary(path)
if isempty(path)
    return
end
try
    diary off
    diary(path);
catch
    % Logging restoration must not change a numerical scenario status.
end
end
