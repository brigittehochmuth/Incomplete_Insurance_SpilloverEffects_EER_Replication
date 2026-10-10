function make_mod_files(M_)
%MAKE_MOD_FILES Write the baseline pre- and post-reform initialization files.

require_registered_names(M_.endo_names, { ...
    'iT_a_t', 'iN_a_t', 'IPI_a_t', 'iT_b_t', 'iN_b_t', 'IPI_b_t'});
write_vector_file('SS_init.mod', 'SS_init', M_.endo_names, M_.orig_endo_nbr);
write_vector_file('newss.mod', 'newss', M_.endo_names, M_.orig_endo_nbr);
end

function require_registered_names(names, required)
registered = strtrim(cellstr(names));
missing = required(~ismember(required, registered));
assert(isempty(missing), 'BaselineModel:GeneratedFile', ...
    'Missing investment T/NT variables: %s', strjoin(missing, ', '));
end

function write_vector_file(filename, vector_name, names, count)
fid = fopen(filename, 'w');
if fid < 0
    error('BaselineModel:GeneratedFile', 'Could not write %s.', filename);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:count
    fprintf(fid, '%s = %s(%d);\n', names{i, :}, vector_name, i);
end
end
