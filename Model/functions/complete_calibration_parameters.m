function parameters = complete_calibration_parameters(configuration)
%COMPLETE_CALIBRATION_PARAMETERS Expand and validate complete-model overrides.

parameters = struct();
if isfield(configuration,'complete_calibration_parameters') ...
        && isstruct(configuration.complete_calibration_parameters)
    parameters = configuration.complete_calibration_parameters;
end
if isfield(parameters,'betta_complete')
    parameters.betta_a = parameters.betta_complete;
    parameters.betta_b = parameters.betta_complete;
    parameters = rmfield(parameters,'betta_complete');
else
    parameters.betta_a = field_or(configuration,'betta_a',0.985);
    parameters.betta_b = field_or(configuration,'betta_b',parameters.betta_a);
end
allowed = {'betta_a','betta_b','nfa_anchor_a','kappae_a','kappae_b', ...
    'kappavT_a','kappavN_a','kappavT_b','kappavN_b', ...
    'TS_a_ts','TS_b_ts','DG_a_ts','DG_b_ts','alpha_a_t','alpha_b_t', ...
    'tax_f2_a','tax_f2_b','B0_a','B0_b','omega_ba','omega_bb'};
names = fieldnames(parameters);
unknown = setdiff(names,allowed);
assert(isempty(unknown),'CompleteInsurance:CalibrationParameter', ...
    'Unsupported complete-insurance calibration parameter: %s.', ...
    strjoin(unknown,','));
for i = 1:numel(names)
    validateattributes(parameters.(names{i}),{'numeric'}, ...
        {'scalar','real','finite'});
end
end


function value = field_or(source,name,default)
if isfield(source,name), value=source.(name); else, value=default; end
end
