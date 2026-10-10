function snapshot = save_initialization_snapshot(output_dir, M_, oo_)
%SAVE_INITIALIZATION_SNAPSHOT Save one self-describing pre-reform state.

if ~isfolder(output_dir)
    mkdir(output_dir);
end

snapshot.steady_state = oo_.steady_state(:);
snapshot.parameters = M_.params(:);
snapshot.var_names = cellstr(M_.endo_names);
snapshot.param_names = cellstr(M_.param_names);
snapshot.param_values = M_.params(:);

SS_init = snapshot.steady_state; %#ok<NASGU>
Param_init = snapshot.parameters; %#ok<NASGU>
var_names = snapshot.var_names; %#ok<NASGU>
param_names = snapshot.param_names; %#ok<NASGU>
param_values = snapshot.param_values; %#ok<NASGU>

save(fullfile(output_dir, 'SS_init.mat'), 'SS_init');
save(fullfile(output_dir, 'Param_init.mat'), 'Param_init');
save(fullfile(output_dir, 'Names.mat'), ...
    'var_names', 'param_names', 'param_values');
end
