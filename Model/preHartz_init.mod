 
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
@#ifndef tax_f_value
    @#define tax_f_value = 0.70
@#endif
@#ifndef tax_f2_value
    @#define tax_f2_value = 0.10
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
@#ifndef xoui_value
    // Backward-compatible common worker bargaining power.
    @#define xoui_value = 0.5
@#endif
@#ifndef xoui_a_value
    @#define xoui_a_value = xoui_value
@#endif
@#ifndef xoui_b_value
    @#define xoui_b_value = xoui_value
@#endif
@#ifndef entitlement_cut_periods
    // Maintained reform duration, mirrored here for one-source audit checks.
    // The pre-reform model itself applies no entitlement cut.
    @#define entitlement_cut_periods = 4
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

// Include Variables and Parameters
@#include "var_params.m"

// Fixed baseline calibration and steady-state solve.
@#include "Eval_SS_june25.m"

xoui_a  = @{xoui_value};
xoui_b  = @{xoui_value};
xoui_a  = @{xoui_a_value};
xoui_b  = @{xoui_b_value};


model;

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%             General equations                                   %%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

@#include "model_equations_general_noCPI.m"

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%              UI benefits                                    %%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


// Eq 171 - 188
@#for land in country
@#for state in g
@#if fix_benefit_index == 1
kappaBS@{state}_@{land}_t  =   (1-tauw_@{land}_t(-@{state}))*rrs_@{land}*w_@{land}_t(-@{state}); %% here are 12 states
@#else
// The submitted dynamic benefit equation is identical. The off branch reproduces the proven reversed continuation index in the steady-state initializer.
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

end;


initval;

@#include "initvals_ss.m"

end;


steady(tolf=@{steady_tolerance}, maxit=100);
resid(1);
oo_.fix_decomposition.pre_static_residual = max(abs( ...
    preHartz_init.static(oo_.steady_state, zeros(M_.exo_nbr, 1), M_.params)));
assert(oo_.fix_decomposition.pre_static_residual <= 1e-10, ...
    'FixDecomposition:StaticResidual', ...
    'Pre-reform static residual %.12g exceeds 1e-10.', ...
    oo_.fix_decomposition.pre_static_residual);
check;
oo_.fix_decomposition.pre_bk_pass = ...
    sum(abs(oo_.dr.eigval) > 1.000001) == M_.nfwrd + M_.nboth;

initialss = oo_.steady_state;

var_names = M_.endo_names;
param_names = M_.param_names;
param_values = M_.params;

disp(['Ce=' num2str(Ce_a_ts)])
disp(['Ceu1=' num2str(Ceu1_a_ts)])
disp(['Ce=' num2str(Ce_b_ts)])
disp(['Ceu1=' num2str(Ceu1_b_ts)])
disp(['Rwt=' num2str(R_w_ts)])
disp(['ae_a_t=' num2str(ae_a_ts)])
disp(['kappav_a=' num2str(kappav_a(1))])
disp(['xoui_a=' num2str(xoui_a)])
