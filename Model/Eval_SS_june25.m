global M_

@#ifndef iac_value
    @#define iac_value = 4.95
@#endif
@#ifndef gammaw_a_value
    @#define gammaw_a_value = 0.8
@#endif
@#ifndef gammaw_b_value
    @#define gammaw_b_value = 0.8
@#endif
@#ifndef alpha_I_value
    @#define alpha_I_value = 1.0
@#endif
@#ifndef chi_sector_value
    @#define chi_sector_value = 0.5
@#endif
@#ifndef chi_sector_T_value
    @#define chi_sector_T_value = chi_sector_value
@#endif
@#ifndef chi_sector_N_value
    @#define chi_sector_N_value = chi_sector_value
@#endif
@#ifndef recruiting_cost_form
    @#define recruiting_cost_form = 0
@#endif
@#ifndef alpha_G_T_value
    @#define alpha_G_T_value = 0.0
@#endif


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% User-adjustable calibration                                    %%%%%
%%%%% Frequently changed scenario controls are at the top of MAIN.m. %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% symmetric steady state:
% change TS_b_ts, u_b_ts, rrs_b_ts
% Country a retains the maintained patience calibration. Country b is either
% identical (regression mode) or solved to support the empirical NFA anchor.
betta_a = @{betta_a_value};
betta_b = betta_a;
@#for land in country
tax_f_@{land}  = @{tax_f_value};
tax_f2_@{land} = @{tax_f2_value};
delta_@{land}  = @{delta_value};
@#endfor

H4_shock = 0;

% Keep the external-return machinery for accounting, but disable its premium
% in Step-1 validation because no saving or portfolio FOC contains Rf_a_t.
% The anchor fixes the Home external position at zero.  Keep anchor mode on
% so the solver continues to choose betta_b rather than a free NFA position.
psi_nfa = 0.00;
nfa_anchor_a = 0;

% u_a_ts=0.088;

pH_ts   = 1;
pF_ts   = 1;

alpha_a_t = @{alpha_a_t_value};
alpha_b_t = 0.79;

% PLACEHOLDER, to be replaced by an input-output based tradable share of
% gross fixed capital formation. MAIN.m supplies 0.5; an unmodified Dynare
% call defaults to 1.0 and exactly nests the maintained tradables-only model.
alpha_I_a = @{alpha_I_value};
alpha_I_b = alpha_I_a;
chi_sector_T_a = @{chi_sector_T_value};
chi_sector_T_b = chi_sector_T_a;
chi_sector_N_a = @{chi_sector_N_value};
chi_sector_N_b = chi_sector_N_a;
recruiting_cost_form = @{recruiting_cost_form};
assert(ismember(recruiting_cost_form,[0 1 2]), ...
    'RecruitingCosts:UnknownForm', ...
    'recruiting_cost_form must be 0 (current), 1 (KK), or 2 (MY).');
alpha_G_T_a = @{alpha_G_T_value};
alpha_G_T_b = alpha_G_T_a;

% alpha_a_t = 0.80;
% alpha_b_t =0.80;

phi_t=@{phi_t_value};
eta_c=@{eta_c_value};


re_ts  = 1;
rer_ts  = 1;

size_a  = 0.271;

sigmac = @{sigmac_value};
chiV = @{chiV_value};


sub_e   = 0.744;
% phi_t

% Im_share_a_of_b  = 0.05;
% Dom_share_a = 0.4;
Dom_share_a = 0.656;


@#for land in country
CPI_@{land}_ts  = 1;
TPI_@{land}_ts  = 1;
IPI_@{land}_ts  = 1;
qY_@{land}_ts   = 1;
qI_@{land}_ts   = 1;
pN_@{land}_ts   = 1;
qT_@{land}_ts   = 1;
qN_@{land}_ts   = 1;
PY_@{land}_ts   = 1;

CA_@{land}_ts  = 0;

%shocks
rhoG_@{land} = 0.99;
rhoA_@{land} = 0.99;
   
% Tax  
% Tax  
rhoto_@{land} = 0.8;
xi_b_@{land}  = 0.05;


% rhoto_@{land} = 0.8;
% xi_b_@{land}  = 0.05;

% Structural parameters
alphaa_@{land}  = 0.5;
gamman_@{land}  = 1;
B0_@{land}   = 0.1   ; % Gs/Ys

%% Targets
FC_@{land} = 0;
TS_@{land}_ts = 1;
tau_@{land}_ts = 0;

omega_b@{land} = 0.6;



% N_@{land}_ts  = 0.91  ;
%% haromonized unemployment rates of germany (a) and euro area from 1995-2004 (quarterly averages)
u_a_ts=0.089;
u_b_ts=0.096;

N_a_ts  = 1-u_a_ts  ;
N_b_ts  = 1-u_b_ts  ;


q_@{land}_ts = 0.7;

%% Baseline
rrs_a  = @{rrs_a_value};
rrl_a  = @{rrl_a_value};

rrs_b  = @{rrs_b_value};
rrl_b  = @{rrl_b_value};

%% italy style:
% rrs_b  = 0.45;
% rrl_b  = 0.4;

% rrs_a  = 0.9;
% rrl_a  = 0.9*(0.5/0.6);
% 
% rrs_b  = 0.9;
% rrl_b  = 0.9*(0.5/0.6);


%% increase benefit /hagedorn maniovskii style
% rrs_a  = 0.95;
% rrl_a  = 0.95*(0.5/0.6);
% 
% rrs_b  = 0.955;
% rrl_b  = 0.955*(0.5/0.6);

% xoui_@{land}    = 1-0.052;
% xoui_@{land}    = 0.75; %% low worker bargaining power
xoui_@{land}    = @{xoui_value}; %% backward-compatible common default
@#if land == "a"
xoui_@{land}    = @{xoui_a_value};
@#else
xoui_@{land}    = @{xoui_b_value};
@#endif
% xoui_@{land}    = 0.25; %% high worker bargaining power

% delta_@{land}   = 0.05;

cp_@{land}      = 0.33;
% cp_@{land}      = 1/3;
% p_@{land}_ts    = 0.09;
 p_a_ts    = 0.116; % average jfr in 2004
 p_b_ts    = 0.108; % average jfr in 2004

% p_a_ts=(1-(1-0.116)^2);
% p_b_ts=(1-(1-0.108)^2);


@#endfor

% kappaw_a    = 61.36;  % Gadatsch et al, Bursian/Stähler: 61.8;
% kappaw_b	= 61.36; % Gadatsch et al, Bursian/Stähler: 79.9;


kappaw_a    = 0;  % Flexible-wage baseline.
kappaw_b	= 0;

% Hall persistence is controlled from MAIN.m. Zero reproduces the flexible
% sharing rule; 0.8 is the maintained Hall comparison.
gammaw_a = @{gammaw_a_value};
gammaw_b = @{gammaw_b_value};

% kappaw_a    = 100;  % Gadatsch et al, Bursian/Stähler: 61.8;
% kappaw_b	= 100; % Gadatsch et al, Bursian/Stähler: 79.9;


TQ_a_ts     = qI_a_ts;
TQ_b_ts     = qI_b_ts;
% 
% Explicit investment adjustment cost. The maintained repaired baseline uses
% the June22 calibration 4.95; diagnostics can override it with -Diac_value.
iac_a       = @{iac_value};
iac_b       = @{iac_value};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Calculate predetermined values

@#for land in country
s_@{land}         = p_@{land}_ts/(1-p_@{land}_ts)*(1-N_@{land}_ts)/N_@{land}_ts;

u_@{land}_ts      = 1- N_@{land}_ts*(1-s_@{land});
V_@{land}_ts      = s_@{land}*N_@{land}_ts/q_@{land}_ts;

kappae_@{land}    = q_@{land}_ts^(1-alphaa_@{land})*(p_@{land}_ts)^alphaa_@{land};
M_@{land}_ts      = kappae_@{land}*(u_@{land}_ts)^alphaa_@{land}*V_@{land}_ts^(1-alphaa_@{land});

mue_@{land}_ts = N_@{land}_ts;
mueu1_@{land}_ts = s_@{land}*(1-p_@{land}_ts)*mue_@{land}_ts;
@#for state in h
mueu@{state}_@{land}_ts = (1-p_@{land}_ts)*mueu@{state-1}_@{land}_ts;
@#endfor
@#for state in e
muuu_@{land}_ts  = (1-p_@{land}_ts)*mueu@{state}_@{land}_ts/(1-(1-p_@{land}_ts));
@#endfor

@#endfor


% The fifth unknown is betta_b in anchor mode and NFA_a in regression mode.
if @{nfa_anchor_mode}
    InitVals = [1.015919057545442   0.053608359863614   0.569693095001462   1.518937502213150 ...
        betta_a   0.064916957626719   0.557023019222235   1.470593414575956];
else
    % Economically screened candidate from the maintained unanchored solve.
    InitVals = [1.015919057545442   0.053608359863614   0.569693095001462   1.518937502213150 ...
       -1.754202298280678   0.064916957626719   0.557023019222235   1.470593414575956];
end
global steady_solver_seed_override recruiting_ss_share_a_guess recruiting_ss_share_b_guess
if isempty(recruiting_ss_share_a_guess); recruiting_ss_share_a_guess = 0.7878951514; end
if isempty(recruiting_ss_share_b_guess); recruiting_ss_share_b_guess = 0.7878828624; end
if ~isempty(steady_solver_seed_override)
    assert(isnumeric(steady_solver_seed_override) && numel(steady_solver_seed_override) == 8 ...
        && all(isfinite(steady_solver_seed_override)), ...
        'SteadySolver:WarmStart', ...
        'The calibration warm start must contain eight finite values.');
    InitVals = reshape(steady_solver_seed_override,1,8);
end
steady_solver_output_dir = fullfile(pwd, 'Results');
global fix_telescope_ss fix_asset_timing_ss fix_benefit_index_ss fix_cohort_convention_ss nfa_anchor_mode_ss bargaining_mode_ss bargaining_continuation_weight_ss
global bargaining_mode_a_ss bargaining_mode_b_ss bargaining_continuation_weight_a_ss bargaining_continuation_weight_b_ss
global convex_ltu_weight_ss
fix_telescope_ss = @{fix_telescope};
fix_asset_timing_ss = @{fix_asset_timing};
fix_benefit_index_ss = @{fix_benefit_index};
fix_cohort_convention_ss = @{fix_cohort_convention};
nfa_anchor_mode_ss = logical(@{nfa_anchor_mode});
bargaining_mode_ss = @{bargaining_mode};
bargaining_continuation_weight_ss = @{bargaining_continuation_weight};
bargaining_mode_a_ss = @{bargaining_mode_a};
bargaining_mode_b_ss = @{bargaining_mode_b};
bargaining_continuation_weight_a_ss = @{bargaining_continuation_weight_a};
bargaining_continuation_weight_b_ss = @{bargaining_continuation_weight_b};
convex_ltu_weight_ss = @{convex_ltu_weight};
% 
% start_point =  [1.021456843149897,   0.047150668862323,   1.171824056795503,   1.157123772306540,  -0.332595936468400,   0.054932454564817,   1.167088856530281,   1.144537898343937] % [1.0045,    0.0674,   -0.0759,    2.1988,    0.0000,    0.0674,   -0.0759,    2.1988] % [1.02,    0.0622,    0.622,    1.38,   0.0000,   0.0622,     1.3434,    1.0017] % [1.0272,    0.0683,    0.7679,    1.3152,   -3.7114,    0.0869,    0.7840,    0.8968]


displayOpt='iter-detailed';
f = @(InitValues) steadySolver_v2(InitValues);
if nfa_anchor_mode_ss
    lower_bounds = [1.0001  1e-8  1e-4  0.1  0.95    1e-8  1e-4  0.1];
    upper_bounds = [1.05    0.999  10    4.0    0.9995  0.999  10    4.0];
    fifth_unknown = 'betta_b';
else
    % Preserve the maintained unanchored solver behavior exactly.
    lower_bounds = [1.0001  1e-8  1e-4  0.1  -Inf  1e-8  1e-4  0.1];
    upper_bounds = [1.05    0.999  10    4.0    Inf  0.999  10    4.0];
    fifth_unknown = 'NFA_a';
end
options = optimoptions('lsqnonlin','Display',displayOpt, ...
    'FunctionTolerance',1e-12,'StepTolerance',1e-12, ...
    'OptimalityTolerance',1e-12,'MaxFunctionEvaluations',30000, ...
    'MaxIterations',1200,'Algorithm','trust-region-reflective');
[w_ts,resnorm,err,exitflag,solver_output,~,solver_jacobian] = ...
    lsqnonlin(f,InitVals,lower_bounds,upper_bounds,options);
first_attempt = struct('w_ts',w_ts,'resnorm',resnorm,'residual',err, ...
    'exitflag',exitflag,'output',solver_output);
residual_scaling = ones(size(err));
solver_attempt = 'unscaled_trust_region_reflective';
exact_all_unemployed = bargaining_mode_a_ss == 1 ...
    && bargaining_mode_b_ss == 1 ...
    && bargaining_continuation_weight_a_ss == 1 ...
    && bargaining_continuation_weight_b_ss == 1;
if exact_all_unemployed && (exitflag <= 0 || max(abs(err)) > 1e-6)
    % One bounded, pre-declared numerical rescue at the maintained raw
    % residual tolerance. Scaling changes the least-squares geometry only;
    % acceptance below continues to use the unscaled economic equations.
    initial_residual = f(InitVals);
    residual_scaling = max(abs(initial_residual),1e-4);
    f_scaled = @(values) f(values)./residual_scaling;
    retry_start = min(max(w_ts,lower_bounds),upper_bounds);
    [w_ts,~,~,exitflag,solver_output,~,scaled_jacobian] = ...
        lsqnonlin(f_scaled,retry_start,lower_bounds,upper_bounds,options);
    err = f(w_ts);
    resnorm = sum(err.^2);
    solver_jacobian = diag(residual_scaling)*scaled_jacobian;
    solver_attempt = 'scaled_residual_trust_region_reflective_retry';
end
singular_values = svd(full(solver_jacobian));
if isempty(singular_values) || min(singular_values) == 0
    solver_jacobian_condition = Inf;
    solver_jacobian_smallest_singular_value = 0;
else
    solver_jacobian_condition = max(singular_values)/min(singular_values);
    solver_jacobian_smallest_singular_value = min(singular_values);
end
residual_names = {'Home Euler Return','Home Cohort Shares', ...
    'Home Marginal Utility','Home Nash Sharing','Foreign Euler Return', ...
    'Foreign Cohort Shares','Foreign Marginal Utility', ...
    'Foreign Nash Sharing'};
[maximum_raw_residual,maximum_residual_index] = max(abs(err));

steady_solver_realized_tax_f2_b = NaN;
steady_solver_realized_omega_bb = omega_bb;
steady_solver_nfa_zero_target = 0;
steady_solver_last_run = struct('w_ts',w_ts,'residual',err, ...
    'resnorm',resnorm,'exitflag',exitflag,'output',solver_output, ...
    'lower_bounds',lower_bounds,'upper_bounds',upper_bounds, ...
    'nfa_anchor_mode',nfa_anchor_mode_ss,'bargaining_mode',bargaining_mode_ss, ...
    'bargaining_continuation_weight',bargaining_continuation_weight_ss, ...
    'bargaining_mode_a',bargaining_mode_a_ss, ...
    'bargaining_mode_b',bargaining_mode_b_ss, ...
    'bargaining_continuation_weight_a',bargaining_continuation_weight_a_ss, ...
    'bargaining_continuation_weight_b',bargaining_continuation_weight_b_ss, ...
    'convex_ltu_weight',convex_ltu_weight_ss, ...
    'fifth_unknown',fifth_unknown, ...
    'realized_tax_f2_b',steady_solver_realized_tax_f2_b, ...
    'realized_omega_bb',steady_solver_realized_omega_bb, ...
    'nfa_zero_target',steady_solver_nfa_zero_target, ...
    'solver_attempt',solver_attempt,'first_attempt',first_attempt, ...
    'residual_scaling',residual_scaling, ...
    'residual_names',{residual_names}, ...
    'maximum_raw_residual',maximum_raw_residual, ...
    'maximum_raw_residual_name',residual_names{maximum_residual_index}, ...
    'jacobian_condition',solver_jacobian_condition, ...
    'smallest_singular_value',solver_jacobian_smallest_singular_value, ...
    'singular_values',singular_values, ...
    'timestamp',datestr(now,30));
save(fullfile(steady_solver_output_dir, 'steady_solver_last_run.mat'), ...
    'steady_solver_last_run');
if exitflag <= 0 || max(abs(err)) > 1e-6
    error('SteadySolver:NoAdmissibleRoot', ...
        ['The bounded steady-state solver did not find an admissible root. ', ...
         'Inspect steady_solver_last_run.mat in the active output folder; do not use the candidate.']);
end

disp(w_ts)

R_w_ts        =w_ts(1);
share8_a_ts   =w_ts(2);
lambdae_a_ts  =w_ts(3);
w_a_ts           =w_ts(4);
share8_b_ts   =w_ts(6);
lambdae_b_ts  =w_ts(7);
w_b_ts      =w_ts(8);

[~, solver_internal_state] = steadySolver_v2(w_ts);
steady_outside_option_identity_max = max(abs([ ...
    solver_internal_state.labor_force_mass_gap_a, ...
    solver_internal_state.labor_force_mass_gap_b, ...
    solver_internal_state.labor_force_weighted_identity_gap_a, ...
    solver_internal_state.labor_force_weighted_identity_gap_b, ...
    solver_internal_state.selected_surplus_gap_a, ...
    solver_internal_state.selected_surplus_gap_b]));
assert(steady_outside_option_identity_max <= 1e-10, ...
    'SteadySolver:OutsideOptionIdentity', ...
    'Outside-option static identity gap %.12g exceeds 1e-10.', ...
    steady_outside_option_identity_max);
steady_solver_last_run.outside_option_state = solver_internal_state;
steady_solver_last_run.outside_option_identity_max = steady_outside_option_identity_max;
save(fullfile(steady_solver_output_dir, 'steady_solver_last_run.mat'), ...
    'steady_solver_last_run');
k_a_for_nfa = ((R_w_ts*TQ_a_ts-(1-delta_a)*TQ_a_ts)/(qY_a_ts*cp_a*TS_a_ts*N_a_ts^(1-cp_a)))^(1/(cp_a-1));
Y_a_for_nfa = TS_a_ts*(k_a_for_nfa^cp_a*N_a_ts^(1-cp_a));
if nfa_anchor_mode_ss
    betta_b_ts = w_ts(5);
    if betta_b_ts < 0.975 || betta_b_ts > 0.995
        error('SteadySolver:ForeignDiscountFactor', ...
            'Solved betta_b %.12g lies outside the admissible [0.975, 0.995] interval.', betta_b_ts);
    end
    betta_b = betta_b_ts;
    NFA_a_ts = nfa_anchor_a*Y_a_for_nfa;
    assert(abs(NFA_a_ts-solver_internal_state.NFA_a_ts) <= 1e-12, ...
        'SteadySolver:NFAAnchorMismatch', ...
        'Recomputed NFA_a differs from the solver-internal anchor by %.12g.', ...
        abs(NFA_a_ts-solver_internal_state.NFA_a_ts));
    assert(abs(NFA_a_ts) <= 1e-12, ...
        'SteadySolver:HomeNFAZeroTarget', ...
        'Anchor mode must impose a zero Home steady-state NFA position.');
else
    betta_b_ts = betta_a;
    betta_b = betta_a;
    NFA_a_ts = w_ts(5);
end
NFA_b_ts = -(size_a*NFA_a_ts)/(1-size_a);

% The external return is distinct from the common domestic return and the
% spread is rebated through firm profits. In anchor mode Home NFA is fixed
% at zero; psi_nfa remains zero in both modes.
Rf_a_ts = R_w_ts*exp(-psi_nfa*(NFA_a_ts/Y_a_for_nfa-nfa_anchor_a));
nfa_spread_a_ts = (Rf_a_ts-R_w_ts)*NFA_a_ts;
nfa_spread_b_ts = -size_a/(1-size_a)*nfa_spread_a_ts;


@#for land in country
k_@{land}_ts = ((R_w_ts*TQ_@{land}_ts - (1-delta_@{land})*TQ_@{land}_ts)/(qY_@{land}_ts*cp_@{land}*TS_@{land}_ts*N_@{land}_ts^(1-cp_@{land})))^(1/(cp_@{land}-1));
Y_@{land}_ts = TS_@{land}_ts*(k_@{land}_ts^cp_@{land}*N_@{land}_ts^(1-cp_@{land}));
b_@{land}_ts = omega_b@{land}*Y_@{land}_ts;
ae_@{land}_ts = (k_@{land}_ts+b_@{land}_ts+NFA_@{land}_ts)/mue_@{land}_ts;
I_@{land}_ts = delta_@{land}*k_@{land}_ts;
DG_@{land}_ts = B0_@{land}*Y_@{land}_ts;
job_flow_@{land}_ts = -(w_@{land}_ts + (TS_@{land}_ts*(k_@{land}_ts/N_@{land}_ts)^cp_@{land}*(cp_@{land} - 1)));
@#if recruiting_cost_form == 0
% Fixed-steady-state-vacancy costs have R_B=0.
Sf_@{land}_ts = job_flow_@{land}_ts/(1-(1/R_w_ts)*(1-s_@{land}));
SfT_@{land}_ts = Sf_@{land}_ts;
SfN_@{land}_ts = Sf_@{land}_ts;
@#else
% KK/MY: each sector's capacity value changes its filled-job recursion.
SfT_@{land}_ts = job_flow_@{land}_ts/(1-(1/R_w_ts)*(1-s_@{land}/(1+chi_sector_T_@{land})));
SfN_@{land}_ts = job_flow_@{land}_ts/(1-(1/R_w_ts)*(1-s_@{land}/(1+chi_sector_N_@{land})));
Sf_@{land}_ts = recruiting_ss_share_@{land}_guess*SfT_@{land}_ts+(1-recruiting_ss_share_@{land}_guess)*SfN_@{land}_ts;
@#endif
@#if recruiting_cost_form == 2
// In the hiring-rate form kappa is the cost per realized match.
kappavT_@{land} = SfT_@{land}_ts/qT_@{land}_ts;
kappavN_@{land} = SfN_@{land}_ts/qN_@{land}_ts;
@#else
// Current and KK forms price a posted vacancy: kappa_v=q*S^f/p_j.
kappavT_@{land} = SfT_@{land}_ts*q_@{land}_ts/qT_@{land}_ts;
kappavN_@{land} = SfN_@{land}_ts*q_@{land}_ts/qN_@{land}_ts;
@#endif
kappav_@{land} = recruiting_ss_share_@{land}_guess*kappavT_@{land}+(1-recruiting_ss_share_@{land}_guess)*kappavN_@{land};
J_@{land}_ts = tax_f2_@{land}*(k_@{land}_ts+b_@{land}_ts+NFA_@{land}_ts)/mue_@{land}_ts*R_w_ts*(p_@{land}_ts*(1-mue_@{land}_ts-muuu_@{land}_ts-mueu8_@{land}_ts) + mueu8_@{land}_ts);
@#if recruiting_cost_form == 0
CV_@{land}_ts = kappav_@{land}*V_@{land}_ts;
@#elseif recruiting_cost_form == 1
CV_@{land}_ts = V_@{land}_ts*(recruiting_ss_share_@{land}_guess*kappavT_@{land}/(1+chi_sector_T_@{land})+(1-recruiting_ss_share_@{land}_guess)*kappavN_@{land}/(1+chi_sector_N_@{land}));
@#elseif recruiting_cost_form == 2
CV_@{land}_ts = q_@{land}_ts*V_@{land}_ts*(recruiting_ss_share_@{land}_guess*kappavT_@{land}/(1+chi_sector_T_@{land})+(1-recruiting_ss_share_@{land}_guess)*kappavN_@{land}/(1+chi_sector_N_@{land}));
@#endif
PSI_@{land}_ts = qY_@{land}_ts*Y_@{land}_ts - w_@{land}_ts*N_@{land}_ts - qI_@{land}_ts*I_@{land}_ts - qY_@{land}_ts*(CV_@{land}_ts + FC_@{land}) + k_@{land}_ts - R_w_ts*k_@{land}_ts + J_@{land}_ts + nfa_spread_@{land}_ts;

tauw_@{land}_ts = (b_@{land}_ts*(R_w_ts - 1) + DG_@{land}_ts - tau_@{land}_ts  + muuu_@{land}_ts*rrl_@{land}*w_@{land}_ts
@#for state in g
+ mueu@{state}_@{land}_ts*rrs_@{land}*w_@{land}_ts 
@#endfor
)/(w_@{land}_ts*N_@{land}_ts +muuu_@{land}_ts*rrl_@{land}*w_@{land}_ts
@#for state in g
+ mueu@{state}_@{land}_ts*rrs_@{land}*w_@{land}_ts 
@#endfor
);

@#for state in g
kappaBS@{state}_@{land}_ts    = (1-tauw_@{land}_ts)*rrs_@{land}*w_@{land}_ts;
@#endfor
kappaBL_@{land}_ts     = (1-tauw_@{land}_ts)*rrl_@{land}*w_@{land}_ts;

@#for state in iback
@#if fix_cohort_convention == 1 && fix_benefit_index == 1
share@{state}_@{land}_ts = (1/(ae_@{land}_ts*R_w_ts*(1-tax_f_@{land}-tax_f2_@{land})))*(-kappaBS@{state}_@{land}_ts+tau_@{land}_ts +((betta_@{land}*p_@{land}_ts*lambdae_@{land}_ts*p_@{land}_ts/N_@{land}_ts*mueu@{state}_@{land}_ts+betta_@{land}*(1-p_@{land}_ts)*(kappaBS@{state+1}_@{land}_ts  + share@{state+1}_@{land}_ts*ae_@{land}_ts*R_w_ts*(1-tax_f_@{land}-tax_f2_@{land}) - tau_@{land}_ts)^(-sigmac)))^(-1/sigmac));
@#elseif fix_cohort_convention == 1 && fix_benefit_index == 0
share@{state}_@{land}_ts = (1/(ae_@{land}_ts*R_w_ts*(1-tax_f_@{land}-tax_f2_@{land})))*(-kappaBS@{state}_@{land}_ts+tau_@{land}_ts +((betta_@{land}*p_@{land}_ts*lambdae_@{land}_ts*p_@{land}_ts/N_@{land}_ts*mueu@{state}_@{land}_ts+betta_@{land}*(1-p_@{land}_ts)*(kappaBS@{9-state}_@{land}_ts  + share@{state+1}_@{land}_ts*ae_@{land}_ts*R_w_ts*(1-tax_f_@{land}-tax_f2_@{land}) - tau_@{land}_ts)^(-sigmac)))^(-1/sigmac));
@#elseif fix_cohort_convention == 0 && fix_benefit_index == 1
share@{state}_@{land}_ts = (1/(ae_@{land}_ts*R_w_ts*(1-tax_f_@{land}-tax_f2_@{land})))*(-kappaBS@{state}_@{land}_ts+tau_@{land}_ts +((betta_@{land}*lambdae_@{land}_ts*p_@{land}_ts/N_@{land}_ts*mueu@{state}_@{land}_ts+betta_@{land}*(1-p_@{land}_ts)*(kappaBS@{state+1}_@{land}_ts  + share@{state+1}_@{land}_ts*ae_@{land}_ts*R_w_ts*(1-tax_f_@{land}-tax_f2_@{land}) - tau_@{land}_ts)^(-sigmac)))^(-1/sigmac));
@#else
share@{state}_@{land}_ts = (1/(ae_@{land}_ts*R_w_ts*(1-tax_f_@{land}-tax_f2_@{land})))*(-kappaBS@{state}_@{land}_ts+tau_@{land}_ts +((betta_@{land}*lambdae_@{land}_ts*p_@{land}_ts/N_@{land}_ts*mueu@{state}_@{land}_ts+betta_@{land}*(1-p_@{land}_ts)*(kappaBS@{9-state}_@{land}_ts  + share@{state+1}_@{land}_ts*ae_@{land}_ts*R_w_ts*(1-tax_f_@{land}-tax_f2_@{land}) - tau_@{land}_ts)^(-sigmac)))^(-1/sigmac));
@#endif
@#endfor

@#endfor



@#for land in country
    
@#for state in m
    @#if state==1
    Rest@{state}_@{land}_ts = 1-share@{state}_@{land}_ts;  
    @#else
    Rest@{state}_@{land}_ts = Rest@{state-1}_@{land}_ts-share@{state}_@{land}_ts;
    @#endif
@#endfor

@#endfor



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%               Resulting endogenous variables                    %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%               Endogenous variables                              %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

@#for land in country

Ce_@{land}_ts =        (1-tauw_@{land}_ts)*w_@{land}_ts + PSI_@{land}_ts/N_@{land}_ts + (1-s_@{land}*(1-tax_f_@{land})*(1-p_@{land}_ts))*ae_@{land}_ts*R_w_ts - ae_@{land}_ts - tau_@{land}_ts +
p_@{land}_ts*(
@#for state in m
+mueu@{state}_@{land}_ts*Rest@{state}_@{land}_ts*ae_@{land}_ts*(1-tax_f_@{land}-tax_f2_@{land})*CPI_@{land}_ts/CPI_@{land}_ts*R_w_ts
@#endfor
       )/mue_@{land}_ts;

@#for state in j
Ceu@{state}_@{land}_ts = kappaBS@{state}_@{land}_ts  + share@{state}_@{land}_ts*ae_@{land}_ts*(1-tax_f_@{land}-tax_f2_@{land})*R_w_ts*CPI_@{land}_ts/CPI_@{land}_ts - tau_@{land}_ts; 
@#endfor  

Cuu_@{land}_ts     = kappaBL_@{land}_ts - tau_@{land}_ts;

C_@{land}_ts = mue_@{land}_ts*Ce_@{land}_ts
 @#for state in g
+ mueu@{state}_@{land}_ts*Ceu@{state}_@{land}_ts
@#endfor
+ muuu_@{land}_ts*Cuu_@{land}_ts;

%% Checks
Check1 = Y_a_ts- DG_a_ts -I_a_ts-CV_a_ts -((R_w_ts-1)*b_a_ts- tau_a_ts)  + ae_a_ts*(R_w_ts-1)*N_a_ts - tau_a_ts*N_a_ts
-mueu1_a_ts*(1-tax_f_a)*ae_a_ts*R_w_ts+ p_a_ts*(
@#for state in m
+mueu@{state}_a_ts*Rest@{state}_a_ts*(1-tax_f_a-tax_f2_a)*ae_a_ts*R_w_ts
@#endfor
       ) - (muuu_a_ts*kappaBL_a_ts
 @#for state in g
+mueu@{state}_a_ts*kappaBS@{state}_a_ts 
@#endfor
)-Ce_a_ts*N_a_ts;

Check3 = -mueu1_a_ts*(1-tax_f_a)*ae_a_ts*R_w_ts+ (1-tax_f_a-tax_f2_a)*ae_a_ts*R_w_ts*(p_a_ts*(
@#for state in m
+mueu@{state}_a_ts*Rest@{state}_a_ts
@#endfor
       ) + (
 @#for state in g
+mueu@{state}_a_ts*share@{state}_a_ts 
@#endfor
));

% Check4 = -tax_f2_a*ae_a_ts*R_w_ts*(p_a_ts*(1-mue_a_ts-muuu_a_ts-mueu8_a_ts) + mueu8_a_ts)-Check3;
% 
% Check2 = Y_a_ts-C_a_ts-I_a_ts-DG_a_ts-kappav_a*V_a_ts + NFA_a_ts*(R_w_ts-1) 
%     -tax_f2_a*(k_a_ts+b_a_ts+NFA_a_ts)/mue_a_ts*R_w_ts*(p_a_ts*(1-mue_a_ts-muuu_a_ts-mueu8_a_ts) + mueu8_a_ts);
% %% Continue


% lambdae_@{land}_ts    =   Ce_@{land}_ts^(-sigmac); 
@#for state in g
lambdaeu@{state}_@{land}_ts  =   Ceu@{state}_@{land}_ts^(-sigmac); 
@#endfor
lambdauu_@{land}_ts   =   Cuu_@{land}_ts^(-sigmac); 


@#if fix_asset_timing == 1
DRe_@{land}_ts = betta_@{land}*((1-s_@{land}*(1-tax_f_@{land})*(1-p_@{land}_ts))*lambdae_@{land}_ts/lambdae_@{land}_ts*CPI_@{land}_ts/CPI_@{land}_ts
@#for state in m
+betta_@{land}^(@{state})*lambdae_@{land}_ts/lambdae_@{land}_ts*p_@{land}_ts/N_@{land}_ts*(mueu@{state}_@{land}_ts*Rest@{state}_@{land}_ts*(1-tax_f_@{land}-tax_f2_@{land})*CPI_@{land}_ts/CPI_@{land}_ts)
@#endfor
@#else
DRe_@{land}_ts = betta_@{land}*((1-s_@{land}*(1-tax_f_@{land})*(1-p_@{land}_ts))*lambdae_@{land}_ts/lambdae_@{land}_ts*CPI_@{land}_ts/CPI_@{land}_ts
@#for state in m
+betta_@{land}^(@{state-1})*lambdae_@{land}_ts/lambdae_@{land}_ts*p_@{land}_ts/N_@{land}_ts*(mueu@{state}_@{land}_ts*Rest@{state}_@{land}_ts*(1-tax_f_@{land}-tax_f2_@{land})*CPI_@{land}_ts/CPI_@{land}_ts)
@#endfor
@#endif
+ s_@{land}*(1-p_@{land}_ts)*lambdaeu1_@{land}_ts/lambdae_@{land}_ts*(CPI_@{land}_ts/CPI_@{land}_ts*share1_@{land}_ts*(1-tax_f_@{land}-tax_f2_@{land})
@#for state in k
@#if fix_telescope == 1
+ betta_@{land}*(1-p_@{land}_ts)*lambdaeu@{state}_@{land}_ts/lambdaeu@{state-1}_@{land}_ts*(CPI_@{land}_ts/CPI_@{land}_ts*share@{state}_@{land}_ts*(1-tax_f_@{land}-tax_f2_@{land})
@#else
+ betta_@{land}*(1-p_@{land}_ts)*lambdaeu@{state}_@{land}_ts/lambdae_@{land}_ts*(CPI_@{land}_ts/CPI_@{land}_ts*share@{state}_@{land}_ts*(1-tax_f_@{land}-tax_f2_@{land})
@#endif
@#endfor
)))))))));


Ue_@{land}_ts   = Ce_@{land}_ts^(1-sigmac)/(1-sigmac);
@#for state in g
Ueu@{state}_@{land}_ts = Ceu@{state}_@{land}_ts^(1-sigmac)/(1-sigmac);
@#endfor
Uuu_@{land}_ts  = Cuu_@{land}_ts^(1-sigmac)/(1-sigmac);

// Lifetime utility uses the same employment-duration Markov chain as the
// dynamic welfare equations: EU1 -> ... -> EU8 -> UU when no job is found.
welf_transition_@{land} = zeros(10,10);
welf_transition_@{land}(1,1) = 1-s_@{land}*(1-p_@{land}_ts);
welf_transition_@{land}(1,2) = s_@{land}*(1-p_@{land}_ts);
@#for state in i
welf_transition_@{land}(@{state+1},1) = p_@{land}_ts;
welf_transition_@{land}(@{state+1},@{state+2}) = 1-p_@{land}_ts;
@#endfor
welf_transition_@{land}(9,1) = p_@{land}_ts;
welf_transition_@{land}(9,10) = 1-p_@{land}_ts;
welf_transition_@{land}(10,1) = p_@{land}_ts;
welf_transition_@{land}(10,10) = 1-p_@{land}_ts;
welf_utility_@{land} = [Ue_@{land}_ts; Ueu1_@{land}_ts; Ueu2_@{land}_ts; ...
    Ueu3_@{land}_ts; Ueu4_@{land}_ts; Ueu5_@{land}_ts; Ueu6_@{land}_ts; ...
    Ueu7_@{land}_ts; Ueu8_@{land}_ts; Uuu_@{land}_ts];
welf_value_@{land} = (eye(10)-betta_@{land}*welf_transition_@{land})\welf_utility_@{land};
Welfe_@{land}_ts = welf_value_@{land}(1);
@#for state in g
Welfeu@{state}_@{land}_ts = welf_value_@{land}(@{state+1});
@#endfor
Welfuu_@{land}_ts = welf_value_@{land}(10);

We_@{land}_ts   =((betta_@{land}*p_@{land}_ts - betta_@{land} + 1)*(Ce_@{land}_ts*lambdae_@{land}_ts - Ue_@{land}_ts + ae_@{land}_ts*lambdae_@{land}_ts + lambdae_@{land}_ts*tau_@{land}_ts + lambdae_@{land}_ts*w_@{land}_ts*(tauw_@{land}_ts - 1) + betta_@{land}*s_@{land}*(Ueu1_@{land}_ts - betta_@{land}*(Ueu2_@{land}_ts - betta_@{land}*(Ueu3_@{land}_ts - betta_@{land}*(Ueu4_@{land}_ts - betta_@{land}*(Ueu5_@{land}_ts - betta_@{land}*(Ueu6_@{land}_ts - betta_@{land}*(p_@{land}_ts - 1)*(Ueu7_@{land}_ts - (betta_@{land}*(p_@{land}_ts - 1)*(Ueu8_@{land}_ts - Ueu8_@{land}_ts*betta_@{land} + Uuu_@{land}_ts*betta_@{land} + Ueu8_@{land}_ts*betta_@{land}*p_@{land}_ts - Uuu_@{land}_ts*betta_@{land}*p_@{land}_ts))/(betta_@{land}*p_@{land}_ts - betta_@{land} + 1)))*(p_@{land}_ts - 1))*(p_@{land}_ts - 1))*(p_@{land}_ts - 1))*(p_@{land}_ts - 1))*(p_@{land}_ts - 1))*(p_@{land}_ts - 1) - R_w_ts*ae_@{land}_ts*betta_@{land}*lambdae_@{land}_ts*(p_@{land}_ts*(1-tax_f_@{land})*s_@{land} - s_@{land}*(1-tax_f_@{land}) + 1)))/((betta_@{land} - 1)*(betta_@{land}*p_@{land}_ts - betta_@{land} + betta_@{land}*s_@{land} - betta_@{land}*p_@{land}_ts*s_@{land} + 1));

Wuu_@{land}_ts  = (Uuu_@{land}_ts + betta_@{land}*p_@{land}_ts*We_@{land}_ts)/(1-betta_@{land}*(1-p_@{land}_ts));
 Weu8_@{land}_ts = Ueu8_@{land}_ts + betta_@{land}*(1-p_@{land}_ts)*Wuu_@{land}_ts + betta_@{land}*p_@{land}_ts*We_@{land}_ts;
@#for state in iback
Weu@{state}_@{land}_ts = Ueu@{state}_@{land}_ts + betta_@{land}*(1-p_@{land}_ts)*Weu@{state+1}_@{land}_ts + betta_@{land}*p_@{land}_ts*We_@{land}_ts;
@#endfor
@#if 0
    // Inactive scalar-selector signatures retained for source-level regression
    // compatibility. The active selectors below are country specific.
    @#if bargaining_mode == 1
    0 = @{bargaining_continuation_weight};
    @#elseif bargaining_mode == 2
    @#endif
@#endif
@#if (land == "a" && bargaining_mode_a == BARGAINING_ALL_UNEMPLOYED) || (land == "b" && bargaining_mode_b == BARGAINING_ALL_UNEMPLOYED)
% ALL_UNEMPLOYED: STU1-STU8 and LTU use current unemployment-stock masses.
She_@{land}_ts = We_@{land}_ts - (
@#if land == "a"
@{bargaining_continuation_weight_a}
@#else
@{bargaining_continuation_weight_b}
@#endif
*((
@#for state in g
+ mueu@{state}_@{land}_ts*Weu@{state}_@{land}_ts
@#endfor
+ muuu_@{land}_ts*Wuu_@{land}_ts) / (
@#for state in g
+ mueu@{state}_@{land}_ts
@#endfor
+ muuu_@{land}_ts)) + (1-
@#if land == "a"
@{bargaining_continuation_weight_a}
@#else
@{bargaining_continuation_weight_b}
@#endif
)*((N_@{land}_ts*Weu1_@{land}_ts
@#for state in g
+ mueu@{state}_@{land}_ts*Weu@{state}_@{land}_ts
@#endfor
+ muuu_@{land}_ts*Wuu_@{land}_ts) / (N_@{land}_ts
@#for state in g
+ mueu@{state}_@{land}_ts
@#endfor
+ muuu_@{land}_ts)));
@#elseif (land == "a" && bargaining_mode_a == BARGAINING_LABOR_FORCE_WEIGHTED) || (land == "b" && bargaining_mode_b == BARGAINING_LABOR_FORCE_WEIGHTED)
% LABOR_FORCE_WEIGHTED COLLECTIVE BARGAINING: employed workers use STU1;
% unemployed workers retain their duration-specific values.
She_@{land}_ts = We_@{land}_ts - ((N_@{land}_ts*Weu1_@{land}_ts
@#for state in g
+ mueu@{state}_@{land}_ts*Weu@{state}_@{land}_ts
@#endfor
+ muuu_@{land}_ts*Wuu_@{land}_ts) / (N_@{land}_ts
@#for state in g
+ mueu@{state}_@{land}_ts
@#endfor
+ muuu_@{land}_ts));
@#elseif (land == "a" && bargaining_mode_a == BARGAINING_CONVEX_STU1_LTU) || (land == "b" && bargaining_mode_b == BARGAINING_CONVEX_STU1_LTU)
% CONVEX_STU1_LTU: optional fixed blend of the first-unemployment and LTU values.
She_@{land}_ts = We_@{land}_ts - ((1-@{convex_ltu_weight})*Weu1_@{land}_ts + @{convex_ltu_weight}*Wuu_@{land}_ts);
@#else
% STU1: a newly separated worker's first-unemployment-state value.
She_@{land}_ts = We_@{land}_ts - Weu1_@{land}_ts;
@#endif

Welf_@{land}_ts=(C_@{land}_ts^(1-sigmac)/(1-sigmac))/(1-betta_@{land});


MPL_@{land}_ts=(1-cp_@{land})*TS_@{land}_ts*k_@{land}_ts^cp_@{land}*N_@{land}_ts^(-cp_@{land});
MPK_@{land}_ts=(cp_@{land})*TS_@{land}_ts*k_@{land}_ts^(cp_@{land}-1)*N_@{land}_ts^(1-cp_@{land});

dissavings_@{land}_ts=
@#for state in g
+ mueu@{state}_@{land}_ts*share@{state}_@{land}_ts*ae_@{land}_ts*R_w_ts*(1-tax_f_@{land}-tax_f2_@{land})
@#endfor
;

@#endfor


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%               International linkages                            %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
@#for land in country
iT_@{land}_ts = alpha_I_@{land}*I_@{land}_ts;
iN_@{land}_ts = (1-alpha_I_@{land})*I_@{land}_ts;
@#endfor

cT_a_ts=alpha_a_t*(pH_ts/CPI_a_ts)^(-phi_t)*C_a_ts;  % // 378 - 388 OK 
% cN_a_ts=Y_a_ts  - CPI_a_ts/pH_ts*kappav_a*V_a_ts;  % // 378 - 388 OK 
%  cN_a_ts=Y_a_ts-DG_a_ts -cT_a_ts - I_a_ts- CPI_a_ts/pH_ts*kappav_a*V_a_ts;  % // 378 - 388 OK 
cN_a_ts=(1-alpha_a_t)*(alpha_a_t*(TPI_a_ts/pH_ts)^(1-phi_t)+(1-alpha_a_t))^(phi_t/(1-phi_t))*C_a_ts;% // 390 OK 

% Keep this expression scalar: Dynare preprocesses this file and cannot parse
% MATLAB structs, function calls, or field access here.  The reporting-layer
% tnt_target function implements the same accounting outside the model file.
    % Current-form nesting: hb1_a = Dom_share_a*(Y_a_ts-DG_a_ts-CPI_a_ts/pH_ts*kappav_a*V_a_ts-cN_a_ts-iN_a_ts)/(cT_a_ts+iT_a_ts);
    hb1_a = Dom_share_a*(Y_a_ts-DG_a_ts-CPI_a_ts/pH_ts*CV_a_ts-cN_a_ts-iN_a_ts)/(cT_a_ts+iT_a_ts);
% hb1_a = Dom_share_a*(Y_a_ts-DG_a_ts-kappav_a*V_a_ts)/(C_a_ts+I_a_ts);

cF_a_ts     = (1-hb1_a)*cT_a_ts;
iF_a_ts     = (1-hb1_a)*iT_a_ts;
cH_a_ts     = hb1_a*cT_a_ts;
iH_a_ts     = hb1_a*iT_a_ts;

% C_a_ts=((alpha_a_t)^(1/phi_t)*cT_a_ts ^((phi_t-1)/phi_t)+(1-alpha_a_t)^(1/phi_t)*cN_a_ts^((phi_t-1)/phi_t))^(phi_t/(phi_t-1)); //385


cT_b_ts=alpha_b_t*(alpha_b_t+(1-alpha_b_t)*(1/(TPI_b_ts/pF_ts))^(1-phi_t))^(phi_t/(1-phi_t))*C_b_ts; %// 389 OK 
cN_b_ts=(1-alpha_b_t)*(alpha_b_t*((TPI_b_ts/pF_ts))^(1-phi_t)+(1-alpha_b_t))^(phi_t/(1-phi_t))*C_b_ts;% // 390 OK 

Aux = size_a/(1-size_a)*(NFA_a_ts*(1-Rf_a_ts) + pF_ts/CPI_a_ts*(cF_a_ts+iF_a_ts));
hb1_b    = Aux/(pH_ts/CPI_a_ts*(cT_b_ts+iT_b_ts));

cF_b_ts     = (1-hb1_b)*cT_b_ts;
iF_b_ts     = (1-hb1_b)*iT_b_ts;
cH_b_ts     = hb1_b*cT_b_ts;
iH_b_ts     = hb1_b*iT_b_ts;

% cF_b_ts     = (1-hb1_b)*C_b_ts;
% iF_b_ts     = (1-hb1_b)*I_b_ts;
% cH_b_ts     = hb1_b*C_b_ts;
% iH_b_ts     = hb1_b*I_b_ts;


EX_a_ts = pH_ts/CPI_a_ts*(1-size_a)/size_a*(cH_b_ts+iH_b_ts); 
IM_a_ts = pF_ts/CPI_a_ts*(cF_a_ts+iF_a_ts);
NX_a_ts = EX_a_ts-IM_a_ts;

if nfa_anchor_mode_ss
    assert(abs(NX_a_ts) <= 1e-8, ...
        'SteadySolver:HomeNXZeroTarget', ...
        'Zero Home steady-state NFA requires zero Home net exports; got %.12g.', NX_a_ts);
end

EX_b_ts = pF_ts/CPI_b_ts*(size_a)/(1-size_a)*(cF_a_ts+iF_a_ts); 
IM_b_ts = pH_ts/CPI_b_ts*(cH_b_ts+iH_b_ts);
NX_b_ts = EX_b_ts-IM_b_ts;

% The explicit sector block nests the aggregate steady state. The sector
% share is implied by existing demand and resource allocation, not targeted.
sT_a_ts = (cH_a_ts+iH_a_ts+(1-size_a)/size_a*(cH_b_ts+iH_b_ts)+alpha_G_T_a*DG_a_ts)/(Y_a_ts-CV_a_ts-FC_a);
sT_b_ts = (cF_b_ts+iF_b_ts+size_a/(1-size_a)*(cF_a_ts+iF_a_ts)+alpha_G_T_b*DG_b_ts)/(Y_b_ts-CV_b_ts-FC_b);

@#for land in country
NT_@{land}_ts = sT_@{land}_ts*N_@{land}_ts;
NN_@{land}_ts = (1-sT_@{land}_ts)*N_@{land}_ts;
VT_@{land}_ts = sT_@{land}_ts*V_@{land}_ts;
VN_@{land}_ts = (1-sT_@{land}_ts)*V_@{land}_ts;
KTuse_@{land}_ts = sT_@{land}_ts*k_@{land}_ts;
KNuse_@{land}_ts = (1-sT_@{land}_ts)*k_@{land}_ts;
YT_@{land}_ts = sT_@{land}_ts*Y_@{land}_ts;
YN_@{land}_ts = (1-sT_@{land}_ts)*Y_@{land}_ts;
MPLT_@{land}_ts = (1-cp_@{land})*TS_@{land}_ts*(KTuse_@{land}_ts/NT_@{land}_ts)^cp_@{land};
MPLN_@{land}_ts = (1-cp_@{land})*TS_@{land}_ts*(KNuse_@{land}_ts/NN_@{land}_ts)^cp_@{land};
MPKT_@{land}_ts = cp_@{land}*TS_@{land}_ts*(NT_@{land}_ts/KTuse_@{land}_ts)^(1-cp_@{land});
MPKN_@{land}_ts = cp_@{land}*TS_@{land}_ts*(NN_@{land}_ts/KNuse_@{land}_ts)^(1-cp_@{land});
RK_@{land}_ts = qT_@{land}_ts*MPKT_@{land}_ts;
@#if recruiting_cost_form == 0
RCT_@{land}_ts = kappav_@{land}*VT_@{land}_ts;
RCN_@{land}_ts = kappav_@{land}*VN_@{land}_ts;
@#elseif recruiting_cost_form == 1
RCT_@{land}_ts = kappavT_@{land}*VT_@{land}_ts/(1+chi_sector_T_@{land});
RCN_@{land}_ts = kappavN_@{land}*VN_@{land}_ts/(1+chi_sector_N_@{land});
@#elseif recruiting_cost_form == 2
RCT_@{land}_ts = kappavT_@{land}*q_@{land}_ts*VT_@{land}_ts/(1+chi_sector_T_@{land});
RCN_@{land}_ts = kappavN_@{land}*q_@{land}_ts*VN_@{land}_ts/(1+chi_sector_N_@{land});
@#endif
FCT_@{land} = sT_@{land}_ts*FC_@{land};
FCN_@{land} = (1-sT_@{land}_ts)*FC_@{land};
@#endfor

EXVOL_a_ts = (1-size_a)/size_a*(cH_b_ts+iH_b_ts);
EXVAL_a_ts = qT_a_ts*EXVOL_a_ts;
IMVOL_a_ts = cF_a_ts+iF_a_ts;
IMVAL_a_ts = pF_ts/CPI_a_ts*IMVOL_a_ts;
EXVOL_b_ts = size_a/(1-size_a)*(cF_a_ts+iF_a_ts);
EXVAL_b_ts = qT_b_ts*EXVOL_b_ts;
IMVOL_b_ts = cH_b_ts+iH_b_ts;
IMVAL_b_ts = pH_ts/CPI_b_ts*IMVOL_b_ts;

assert(sT_a_ts > 0 && sT_a_ts < 1 && sT_b_ts > 0 && sT_b_ts < 1, ...
    'SectorExtension:SteadyShare', ...
    'Implied sector employment shares must lie strictly between zero and one.');

trdb_vs_nontrdb_a_ts=pH_ts*(cH_a_ts+iH_a_ts + (1-size_a)/size_a*(cH_b_ts + iH_b_ts))/(pH_ts*(cN_a_ts+iN_a_ts));
trdb_vs_nontrdb_b_ts=pF_ts*(cF_b_ts+iF_b_ts + (size_a)/(1-size_a)*(cF_a_ts + iF_a_ts))/(pF_ts*(cN_b_ts+iN_b_ts));

GNP_a_ts = qT_a_ts*YT_a_ts+qN_a_ts*YN_a_ts+(Rf_a_ts-1)*NFA_a_ts;
GNP_b_ts = qT_b_ts*YT_b_ts+qN_b_ts*YN_b_ts+(R_w_ts-1)*NFA_b_ts+nfa_spread_b_ts;

nfa_a_to_annual_output = NFA_a_ts/(4*Y_a_ts);
nfa_b_to_annual_output = NFA_b_ts/(4*Y_b_ts);
nfa_a_annual_ratio_limit = NaN;
nfa_a_economic_pass = true;
tax_f2_b_economic_pass = true;
economic_steady_state_pass = R_w_ts > 1 && share8_a_ts > 0 && share8_a_ts < 1 ...
    && share8_b_ts > 0 && share8_b_ts < 1 && lambdae_a_ts > 0 ...
    && lambdae_b_ts > 0 && w_a_ts > 0 && w_b_ts > 0 && ae_a_ts > 0 ...
    && ae_b_ts > 0 && Ce_a_ts > 0 && Ce_b_ts > 0 && Cuu_a_ts > 0 ...
    && Cuu_b_ts > 0 && hb1_b > 0 && hb1_b < 1 && nfa_a_economic_pass ...
    && tax_f2_b_economic_pass;
steady_solver_last_run.economic_steady_state_pass = economic_steady_state_pass;
steady_solver_last_run.betta_a = betta_a;
steady_solver_last_run.betta_b = betta_b;
steady_solver_last_run.betta_b_gap = betta_b-betta_a;
steady_solver_last_run.initial_values = InitVals;
steady_solver_last_run.chiV = chiV;
steady_solver_last_run.hb1_b = hb1_b;
steady_solver_last_run.NFA_a_to_Y_a = NFA_a_ts/Y_a_ts;
steady_solver_last_run.NFA_b_to_Y_b = NFA_b_ts/Y_b_ts;
steady_solver_last_run.NFA_a_to_annual_output = nfa_a_to_annual_output;
steady_solver_last_run.NFA_b_to_annual_output = nfa_b_to_annual_output;
save(fullfile(steady_solver_output_dir, 'steady_solver_last_run.mat'), ...
    'steady_solver_last_run');
if ~economic_steady_state_pass
    error('SteadySolver:EconomicAdmissibility', ...
        'The numerical root violates the steady-state economic admissibility checks.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Employed consumption must exceed every short- and long-term
% unemployment state, symmetrically by country.
unemployed_state_labels = {'eu1','eu2','eu3','eu4','eu5','eu6','eu7','eu8','uu'};
unemployed_consumption_a = [Ceu1_a_ts Ceu2_a_ts Ceu3_a_ts Ceu4_a_ts ...
    Ceu5_a_ts Ceu6_a_ts Ceu7_a_ts Ceu8_a_ts Cuu_a_ts];
unemployed_consumption_b = [Ceu1_b_ts Ceu2_b_ts Ceu3_b_ts Ceu4_b_ts ...
    Ceu5_b_ts Ceu6_b_ts Ceu7_b_ts Ceu8_b_ts Cuu_b_ts];
consumption_gaps_a = Ce_a_ts-unemployed_consumption_a;
consumption_gaps_b = Ce_b_ts-unemployed_consumption_b;
[minimum_consumption_gap_a, worst_state_index_a] = min(consumption_gaps_a);
[minimum_consumption_gap_b, worst_state_index_b] = min(consumption_gaps_b);
worst_unemployed_state_a = unemployed_state_labels{worst_state_index_a};
worst_unemployed_state_b = unemployed_state_labels{worst_state_index_b};
existence_condition_a_pass = minimum_consumption_gap_a > 0;
existence_condition_b_pass = minimum_consumption_gap_b > 0;

% Preserve the superseded conditions as diagnostics only.
EC_a  = Ce_a_ts-Ceu1_a_ts;
EC2_a = lambdauu_a_ts - betta_a*R_w_ts *(p_a_ts*lambdae_a_ts+(1-p_a_ts)*lambdauu_a_ts);
EC_b  = (lambdaeu1_b_ts+lambdaeu2_b_ts+lambdaeu3_b_ts) - betta_b_ts*R_w_ts *(p_b_ts*lambdae_b_ts+(1-p_b_ts)*lambdauu_b_ts);
EC2_b = lambdauu_b_ts - betta_b_ts*R_w_ts *(p_b_ts*lambdae_b_ts+(1-p_b_ts)*lambdauu_b_ts);
steady_solver_last_run.EC_a = EC_a;
steady_solver_last_run.EC2_a = EC2_a;
steady_solver_last_run.EC_b = EC_b;
steady_solver_last_run.EC2_b = EC2_b;
steady_solver_last_run.legacy_EC_a = EC_a;
steady_solver_last_run.legacy_EC2_a = EC2_a;
steady_solver_last_run.legacy_EC_b = EC_b;
steady_solver_last_run.legacy_EC2_b = EC2_b;
steady_solver_last_run.consumption_gaps_a = consumption_gaps_a;
steady_solver_last_run.consumption_gaps_b = consumption_gaps_b;
steady_solver_last_run.minimum_consumption_gap_a = minimum_consumption_gap_a;
steady_solver_last_run.minimum_consumption_gap_b = minimum_consumption_gap_b;
steady_solver_last_run.worst_unemployed_state_a = worst_unemployed_state_a;
steady_solver_last_run.worst_unemployed_state_b = worst_unemployed_state_b;
steady_solver_last_run.existence_condition_a_pass = existence_condition_a_pass;
steady_solver_last_run.existence_condition_b_pass = existence_condition_b_pass;
save(fullfile(steady_solver_output_dir, 'steady_solver_last_run.mat'), ...
    'steady_solver_last_run');
if nfa_anchor_mode_ss && (~existence_condition_a_pass || ~existence_condition_b_pass)
    error('SteadySolver:ExistenceCondition', ...
        ['Employed consumption does not exceed every unemployment state: ' ...
         'home=%d (minimum gap=%.12g, state=%s), foreign=%d ' ...
         '(minimum gap=%.12g, state=%s).'], ...
        existence_condition_a_pass, minimum_consumption_gap_a, worst_unemployed_state_a, ...
        existence_condition_b_pass, minimum_consumption_gap_b, worst_unemployed_state_b);
end

fprintf('Minimum employed-minus-unemployed consumption gap: home %.12g (%s), foreign %.12g (%s).\n', ...
    minimum_consumption_gap_a, worst_unemployed_state_a, ...
    minimum_consumption_gap_b, worst_unemployed_state_b);
   

           
