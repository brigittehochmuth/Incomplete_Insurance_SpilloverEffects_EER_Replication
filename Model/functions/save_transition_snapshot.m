function snapshot = save_transition_snapshot(output_dir, M_, oo_)
%SAVE_TRANSITION_SNAPSHOT Save one self-describing transition result.

if ~isfolder(output_dir)
    mkdir(output_dir);
end

snapshot.steady_state = oo_.steady_state(:);
snapshot.endo_simul = oo_.endo_simul;
snapshot.var_names = cellstr(M_.endo_names);
snapshot.param_names = cellstr(M_.param_names);
snapshot.param_values = M_.params(:);

SS_H42_EB = snapshot.steady_state; %#ok<NASGU>
Sim_H42_EB = snapshot.endo_simul; %#ok<NASGU>
var_names = snapshot.var_names; %#ok<NASGU>
param_names = snapshot.param_names; %#ok<NASGU>
param_values = snapshot.param_values; %#ok<NASGU>

save(fullfile(output_dir, 'SS_H42_EB.mat'), 'SS_H42_EB');
save(fullfile(output_dir, 'Sim_H42_EB.mat'), 'Sim_H42_EB');
save(fullfile(output_dir, 'Names_H42_EB.mat'), ...
    'var_names', 'param_names', 'param_values');
end
