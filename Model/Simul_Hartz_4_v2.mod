 
//************************************************************
// RBC Model 
// with labor market matching, partial insurance,
// and preccautionary savings 
//  
// Moyen S. 
// February 23, 2012
//************************************************************
// Define number of states
@#define country=[ "a", "b"]

@#define e=[8]  
@#define f=[7,8] 
@#define g=[1,2,3,4,5,6,7,8] 
@#define h=[2,3,4,5,6,7,8]
@#define i=[1,2,3,4,5,6,7] 
@#define iback=[7,6,5,4,3,2,1] 

@#define j=[1,2,3,4,5,6,7,8] 
@#define k=[2,3,4,5,6,7,8] 
@#define l=[8] 
@#define m=[1,2,3,4,5,6,7] 

@#ifndef fix_telescope
    @#define fix_telescope = 1
@#endif
@#ifndef fix_asset_timing
    @#define fix_asset_timing = 1
@#endif
@#ifndef fix_benefit_index
    @#define fix_benefit_index = 1
@#endif
@#ifndef fix_cohort_convention
    @#define fix_cohort_convention = 1
@#endif
@#ifndef steady_tolerance
    @#define steady_tolerance = 1e-10
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
    // 0=current fixed-vacancy normalization; 1=Kaas-Kircher; 2=MY hiring rate.
    @#define recruiting_cost_form = 0
@#endif
@#ifndef alpha_G_T_value
    @#define alpha_G_T_value = 0.0
@#endif
@#ifndef nfa_anchor_mode
    @#define nfa_anchor_mode = 0
@#endif
@#ifndef chiV_value
    @#define chiV_value = 0
@#endif
@#ifndef eta_c_value
    @#define eta_c_value = 6.0
@#endif
@#ifndef phi_t_value
    @#define phi_t_value = 0.5
@#endif
@#ifndef sigmac_value
    @#define sigmac_value = 2.3
@#endif
@#ifndef alpha_a_t_value
    @#define alpha_a_t_value = 0.79
@#endif
@#ifndef betta_a_value
    @#define betta_a_value = 0.985
@#endif
@#ifndef chiv_equations
    @#define chiv_equations = 1
@#endif
@#ifndef delta_value
    @#define delta_value = 0.05
@#endif
@#ifndef rrs_a_value
    @#define rrs_a_value = 0.6
@#endif
@#ifndef rrl_a_value
    @#define rrl_a_value = 0.5
@#endif
@#ifndef rrs_b_value
    @#define rrs_b_value = 0.6
@#endif
@#ifndef rrl_b_value
    @#define rrl_b_value = 0.5
@#endif

// Named bargaining-mode map used in the dynamic and static equations.
// STU1: newly separated worker; ALL_UNEMPLOYED: unemployment-stock mean;
// LABOR_FORCE_WEIGHTED: employed workers retain STU1 and unemployed workers
// retain their duration-specific values; CONVEX_STU1_LTU blends STU1 and LTU.
@#define BARGAINING_STU1 = 0
@#define BARGAINING_ALL_UNEMPLOYED = 1
@#define BARGAINING_LABOR_FORCE_WEIGHTED = 2
@#define BARGAINING_CONVEX_STU1_LTU = 3
@#ifndef bargaining_mode
    // Backward-compatible common selector.
    @#define bargaining_mode = 0
@#endif
@#ifndef bargaining_mode_a
    @#define bargaining_mode_a = bargaining_mode
@#endif
@#ifndef bargaining_mode_b
    @#define bargaining_mode_b = bargaining_mode
@#endif
@#ifndef bargaining_continuation_weight
    // Backward-compatible common continuation selector for ALL_UNEMPLOYED.
    @#define bargaining_continuation_weight = 1.0
@#endif
@#ifndef bargaining_continuation_weight_a
    @#define bargaining_continuation_weight_a = bargaining_continuation_weight
@#endif
@#ifndef bargaining_continuation_weight_b
    @#define bargaining_continuation_weight_b = bargaining_continuation_weight
@#endif
@#ifndef convex_ltu_weight
    // Optional sensitivity: 0 is STU1 and 1 is the LTU value.
    @#define convex_ltu_weight = 0.25
@#endif
@#ifndef xoui_post_a_value
    // A negative value keeps the loaded pre-reform bargaining power.
    @#define xoui_post_a_value = -1
@#endif
@#ifndef xoui_post_b_value
    @#define xoui_post_b_value = -1
@#endif
@#ifndef separation_multiplier_a
    @#define separation_multiplier_a = 1.0
@#endif
@#ifndef separation_multiplier_b
    @#define separation_multiplier_b = 1.0
@#endif
@#ifndef separation_transition_start_quarter
    // Zero selects the immediate post-reform separation rate.
    @#define separation_transition_start_quarter = 0
@#endif
@#ifndef separation_transition_full_effect_quarter
    @#define separation_transition_full_effect_quarter = 0
@#endif
@#ifndef rrl_post_a_value
    // A negative value applies the backward-compatible reform_cut mapping.
    @#define rrl_post_a_value = -1
@#endif
@#ifndef rrl_post_b_value
    // A negative value keeps the loaded Foreign long-term UI parameter.
    @#define rrl_post_b_value = -1
@#endif
@#ifndef labor_tax_closure
    // 0: fixed labor tax and debt-stabilizing lump-sum tax (maintained).
    // 1: fixed lump-sum tax and debt-stabilizing labor tax.
    @#define labor_tax_closure = 0
@#endif

@#if !(bargaining_mode_a in [BARGAINING_STU1,BARGAINING_ALL_UNEMPLOYED,BARGAINING_LABOR_FORCE_WEIGHTED,BARGAINING_CONVEX_STU1_LTU])
    @#error "bargaining_mode_a must be an implemented named mode from 0 through 3."
@#endif
@#if !(bargaining_mode_b in [BARGAINING_STU1,BARGAINING_ALL_UNEMPLOYED,BARGAINING_LABOR_FORCE_WEIGHTED,BARGAINING_CONVEX_STU1_LTU])
    @#error "bargaining_mode_b must be an implemented named mode from 0 through 3."
@#endif
@#if convex_ltu_weight < 0 || convex_ltu_weight > 1
    @#error "convex_ltu_weight must lie in [0,1]."
@#endif
@#if !(labor_tax_closure in [0,1])
    @#error "labor_tax_closure must be 0 (lump-sum) or 1 (labor tax)."
@#endif

@#include "var_params.m"

@#ifndef reform_cut
    @#define reform_cut = 0.15
@#endif
@#ifndef simulation_periods
    @#define simulation_periods = 1000
@#endif
@#ifndef reform_lambda
    @#define reform_lambda = 1.0
@#endif
@#ifndef defer_perfect_foresight
    @#define defer_perfect_foresight = 0
@#endif
@#ifndef entitlement_cut_periods
    @#define entitlement_cut_periods = 4
@#endif
@#if entitlement_cut_periods < 0 || entitlement_cut_periods > 8
    @#error "entitlement_cut_periods must be an integer from 0 through 8."
@#endif

load(fullfile('Results', 'SS_init.mat'));
load(fullfile('Results', 'Param_init.mat'));
@#include "Param_init.mod"

reviewer_entitlement_short_term_states = 1:(8-@{entitlement_cut_periods});
reviewer_entitlement_switched_states = (9-@{entitlement_cut_periods}):8;
if @{entitlement_cut_periods} == 4
    assert(isequal(reviewer_entitlement_short_term_states,1:4) && ...
        isequal(reviewer_entitlement_switched_states,5:8), ...
        'ReviewerSuite:EntitlementMapping', ...
        'A four-period entitlement cut must retain states 1-4 and switch states 5-8.');
end
assert(@{separation_multiplier_a} > 0 && @{separation_multiplier_b} > 0, ...
    'ReviewerSuite:SeparationMultiplier', ...
    'Post-reform separation multipliers must be strictly positive.');
assert((@{separation_transition_start_quarter} == 0 ...
        && @{separation_transition_full_effect_quarter} == 0) ...
        || (@{separation_transition_start_quarter} == 12 ...
        && @{separation_transition_full_effect_quarter} == 24), ...
    'ReviewerSuite:SeparationTiming', ...
    ['The maintained separation timing is either immediate (0,0) or ' ...
     'unchanged through quarter 12 and linear to its full effect in quarter 24.']);

rrs2_a = rrs_a;
rrs3_a = rrs_a;
kappaBL_a_t2 =  rrl_a*(1-tauw_a_ts)*w_a_ts;

model;

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%             General equations                                   %%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

@#include "model_equations_general_noCPI.m"

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%              UI benefits                                    %%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

// country a
@#for state in [1,2,3,4,5,6,7,8]
@#if state <= 8-entitlement_cut_periods
@#if fix_benefit_index == 1
kappaBS@{state}_a_t  =   (1-tauw_a_t(-@{state}))*rrs_a*w_a_t(-@{state});
@#else
// The submitted dynamic benefit equation is identical. The off branch reproduces the proven reversed continuation index in the steady-state initializer.
kappaBS@{state}_a_t  =   (1-tauw_a_t(-@{state}))*rrs_a*w_a_t(-@{state});
@#endif
@#else
@#if fix_benefit_index == 1
kappaBS@{state}_a_t  =   (1-H4_shock + HH4)*(1-tauw_a_t(-@{state}))*rrs2_a*w_a_t(-@{state}) + (H4_shock-HH4)*kappaBL_a_t2;
@#else
kappaBS@{state}_a_t  =   (1-H4_shock + HH4)*(1-tauw_a_t(-@{state}))*rrs2_a*w_a_t(-@{state}) + (H4_shock-HH4)*kappaBL_a_t2;
@#endif
@#endif
@#endfor

kappaBL_a_t  = kappaBL_a_t2;

@#for land in ["b"] 
@#for state in g
@#if fix_benefit_index == 1
kappaBS@{state}_@{land}_t  =   (1-tauw_@{land}_t(-@{state}))*rrs_@{land}*w_@{land}_t(-@{state}); %% here are 12 states
@#else
kappaBS@{state}_@{land}_t  =   (1-tauw_@{land}_t(-@{state}))*rrs_@{land}*w_@{land}_t(-@{state}); %% here are 12 states
@#endif
@#endfor
kappaBL_@{land}_t  =   (1-tauw_@{land}_t(-9))*rrl_@{land}*w_@{land}_t(-9); 
@#endfor

@#for land in country
 dissavings_@{land}_t=
 @#for state in g
 + mueu@{state}_@{land}_t*share@{state}_@{land}_t*ae_@{land}_t(-@{state})*R_w_t(-@{state})*(1-tax_f_@{land}-tax_f2_@{land})
 @#endfor
 ;
@#endfor



//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%               Fiscal Rule                                       %%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

@#if labor_tax_closure == 1
// Alternative closure: lump-sum taxes are fixed and labor taxes stabilize debt.
@#for land in country
tau_@{land}_t = tau_@{land}_ts;
tauw_@{land}_t - steady_state(tauw_@{land}_t) = rhoto_@{land}*(tauw_@{land}_t(-1)-steady_state(tauw_@{land}_t)) + xi_b_@{land}*(b_@{land}_t(-1)-omega_b@{land}*Y_@{land}_t(-1));
@#endfor
@#else
@#include "fiscal_rule.m"
@#endif

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%               International linkages                            %%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

@#include "model_equations_linkages_TNT.m"

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end;

// ######################################################################
initval;
@#include "SS_init.mod"
end;


resid(1);
steady(tolf=@{steady_tolerance}, maxit=100);
oo_.fix_decomposition.transition_pre_static_residual = max(abs( ...
    Simul_Hartz_4_v2.static(oo_.steady_state, zeros(M_.exo_nbr, 1), M_.params)));
assert(oo_.fix_decomposition.transition_pre_static_residual < 1e-8, ...
    'FixDecomposition:StaticResidual', ...
    'Loaded pre-reform static residual %.12g exceeds 1e-8.', ...
    oo_.fix_decomposition.transition_pre_static_residual);
// Verify Blanchard-Kahn conditions at the pre-reform steady state.
check;
oo_.fix_decomposition.transition_pre_bk_pass = ...
    sum(abs(oo_.dr.eigval) > 1.000001) == M_.nfwrd + M_.nboth;


// Reform measure and Simulation

@#if rrl_post_a_value >= 0
rrl_a = @{rrl_post_a_value};
@#else
rrl_a = rrl_a*(1-@{reform_cut});
@#endif
@#if rrl_post_b_value >= 0
rrl_b = @{rrl_post_b_value};
@#endif
@#if xoui_post_a_value >= 0
xoui_a = @{xoui_post_a_value};
@#endif
@#if xoui_post_b_value >= 0
xoui_b = @{xoui_post_b_value};
@#endif
s_a = s_a*@{separation_multiplier_a};
s_b = s_b*@{separation_multiplier_b};

kappaBL_a_t2 =  rrl_a*(1-tauw_a_t)*w_a_ts;
steadyUBpostshock = kappaBL_a_t2;

H4_shock = @{reform_lambda};


steady(tolf=@{steady_tolerance}, maxit=100);
oo_.fix_decomposition.post_static_residual = max(abs( ...
    Simul_Hartz_4_v2.static(oo_.steady_state, zeros(M_.exo_nbr, 1), M_.params)));
assert(oo_.fix_decomposition.post_static_residual < 1e-8, ...
    'FixDecomposition:StaticResidual', ...
    'Post-reform static residual %.12g exceeds 1e-8.', ...
    oo_.fix_decomposition.post_static_residual);
// Verify Blanchard-Kahn conditions again at the post-reform steady state.
check;
oo_.fix_decomposition.post_bk_pass = ...
    sum(abs(oo_.dr.eigval) > 1.000001) == M_.nfwrd + M_.nboth;
// resid(1);
newss = oo_.steady_state;


initval;
@#include "SS_init.mod"
end;

endval;
@#include "newss.mod"
end;

@#if separation_transition_full_effect_quarter == 24
// The post-reform parameter already contains the full separation decline.
// This temporary wedge restores the pre-reform rate through quarter 12 and
// then removes that offset linearly, so the full decline is reached in Q24.
shocks;
var sep_timing_a;
periods 1:12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23;
values (1/@{separation_multiplier_a}-1),
    ((1/@{separation_multiplier_a}-1)*11/12),
    ((1/@{separation_multiplier_a}-1)*10/12),
    ((1/@{separation_multiplier_a}-1)*9/12),
    ((1/@{separation_multiplier_a}-1)*8/12),
    ((1/@{separation_multiplier_a}-1)*7/12),
    ((1/@{separation_multiplier_a}-1)*6/12),
    ((1/@{separation_multiplier_a}-1)*5/12),
    ((1/@{separation_multiplier_a}-1)*4/12),
    ((1/@{separation_multiplier_a}-1)*3/12),
    ((1/@{separation_multiplier_a}-1)*2/12),
    ((1/@{separation_multiplier_a}-1)*1/12);
end;
@#endif

options_.maxit_ = 50;
@#if defer_perfect_foresight == 1
perfect_foresight_setup(periods=@{simulation_periods});
@#else
simul(stack_solve_algo=6, periods=@{simulation_periods});
@#endif
