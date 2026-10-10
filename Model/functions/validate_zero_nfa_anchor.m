function validation = validate_zero_nfa_anchor(anchor, nfa_anchor_mode)
%VALIDATE_ZERO_NFA_ANCHOR Reject a run that misses the explicit zero-NFA target.

validation = struct('required',logical(nfa_anchor_mode), 'pass',true, ...
    'home_nfa_to_annual_output',NaN, 'message','Not required.');
if ~validation.required
    return
end
if ~isfield(anchor, 'NFA_a_to_annual_output')
    validation.pass = false;
    validation.message = 'The steady-state solver did not save the Home NFA diagnostic.';
    return
end
validation.home_nfa_to_annual_output = anchor.NFA_a_to_annual_output;
validation.pass = abs(validation.home_nfa_to_annual_output) <= 1e-12;
if validation.pass
    validation.message = 'Home NFA steady-state anchor equals zero.';
else
    validation.message = sprintf(['Home NFA steady-state anchor is %.12g of annual output, ' ...
        'not zero.'], validation.home_nfa_to_annual_output);
end
end
