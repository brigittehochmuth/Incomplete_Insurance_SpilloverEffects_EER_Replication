function [key,payload,fields] = configuration_hash(config,fields)
%CONFIGURATION_HASH Deterministic hash of pre-reform model inputs.
%   The cache deliberately excludes policy changes that occur only after the
%   initial steady state.  Callers may provide an explicit field list when a
%   backend has additional pre-reform inputs.

if nargin < 2 || isempty(fields)
    if isfield(config,'sector_recruiting_congestion_T')
        config.sector_recruiting_congestion_T_a = config.sector_recruiting_congestion_T;
        config.sector_recruiting_congestion_T_b = config.sector_recruiting_congestion_T;
    end
    if isfield(config,'sector_recruiting_congestion_N')
        config.sector_recruiting_congestion_N_a = config.sector_recruiting_congestion_N;
        config.sector_recruiting_congestion_N_b = config.sector_recruiting_congestion_N;
    end
    fields = { ...
        'backend','investment_adjustment_cost','hall_persistence_a', ...
        'hall_persistence_b','alpha_I','sector_recruiting_congestion', ...
        'sector_recruiting_congestion_T','sector_recruiting_congestion_N', ...
        'sector_recruiting_congestion_T_a','sector_recruiting_congestion_N_a', ...
        'sector_recruiting_congestion_T_b','sector_recruiting_congestion_N_b', ...
        'recruiting_cost_form', ...
        'government_tradable_share','nfa_anchor_mode','nfa_sgu', ...
        'fix_capital_financing','vacancy_adjustment_cost','eta_c', ...
        'phi_t','sigmac','alpha_a_t','betta_a','chiv_equations', ...
        'single_tau_mode','tax_f','tax_f2', ...
        'depreciation_rate','rrs_a','rrl_a','rrs_b','rrl_b', ...
        'bargaining_power','bargaining_power_pre_a', ...
        'bargaining_power_pre_b','bargaining_mode','bargaining_mode_a', ...
        'bargaining_mode_b','bargaining_continuation_weight', ...
        'bargaining_continuation_weight_a', ...
        'bargaining_continuation_weight_b','convex_ltu_weight', ...
        'separation_pre_multiplier_a','separation_pre_multiplier_b', ...
        'complete_insurance_sgu','complete_calibration_parameters', ...
        'pre_reform_code_fingerprint'};
    fields{end+1} = 'labor_tax_closure';
end

fields = sort(fields(:));
canonical = struct();
for i = 1:numel(fields)
    name = fields{i};
    if isfield(config,name)
        canonical.(name) = canonical_value(config.(name));
    else
        canonical.(name) = '__MISSING__';
    end
end
payload = jsonencode(canonical);

% MATLAB ships with a JVM in the supported Dynare desktop workflow.  Keep a
% deterministic numeric fallback for -nojvm diagnostic sessions.
try
    engine = java.security.MessageDigest.getInstance('SHA-256');
    engine.update(uint8(payload));
    bytes = typecast(engine.digest(),'uint8');
    hex = lower(reshape(dec2hex(bytes,2).',1,[]));
    key = ['sha256_' hex];
catch
    codes = double(uint8(payload));
    first = mod(sum(codes.*(1:numel(codes))),4294967291);
    second = mod(sum(codes.*mod((1:numel(codes)).^2,4294967279)),4294967279);
    key = sprintf('fallback_%08x_%08x',uint32(first),uint32(second));
end
end


function value = canonical_value(value)
if isstring(value)
    value = cellstr(value);
elseif ischar(value) || isnumeric(value) || islogical(value) || iscell(value)
    % jsonencode already has a stable representation for these values.
elseif isstruct(value)
    if numel(value) > 1
        elements = cell(size(value));
        for element = 1:numel(value)
            elements{element} = canonical_value(value(element));
        end
        value = elements;
        return
    end
    names = sort(fieldnames(value));
    ordered = struct();
    for i = 1:numel(names)
        ordered.(names{i}) = canonical_value(value.(names{i}));
    end
    value = ordered;
else
    value = char(string(value));
end
end
