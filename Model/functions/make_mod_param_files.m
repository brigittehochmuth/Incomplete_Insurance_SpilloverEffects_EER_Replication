function make_mod_param_files(M_)
%MAKE_MOD_PARAM_FILES Write the baseline parameter initialization file.

required = {'betta_a', 'betta_b', 'alpha_I_a', 'alpha_I_b', ...
    'iT_a_ts', 'iN_a_ts', 'IPI_a_ts', ...
    'iT_b_ts', 'iN_b_ts', 'IPI_b_ts'};
registered = strtrim(cellstr(M_.param_names));
missing = required(~ismember(required, registered));
assert(isempty(missing), 'BaselineModel:GeneratedFile', ...
    'Missing investment T/NT parameters: %s', strjoin(missing, ', '));

fid = fopen('Param_init.mod', 'w');
if fid < 0
    error('BaselineModel:GeneratedFile', 'Could not write Param_init.mod.');
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:M_.param_nbr
    fprintf(fid, '%s = Param_init(%d);\n', M_.param_names{i, :}, i);
end
end
