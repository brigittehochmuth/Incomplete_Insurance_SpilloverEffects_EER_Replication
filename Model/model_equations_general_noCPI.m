@#ifndef fix_telescope
    @#define fix_telescope = 1
@#endif
@#ifndef fix_asset_timing
    @#define fix_asset_timing = 1
@#endif
@#ifndef fix_cohort_convention
    @#define fix_cohort_convention = 1
@#endif
@#ifndef fix_capital_financing
    @#define fix_capital_financing = 1
@#endif
@#ifndef nfa_sgu_value
    @#define nfa_sgu_value = 0
@#endif

@#for land in country

// Eq 1 + 86
We_@{land}_t  = Ue_@{land}_t - lambdae_@{land}_t*Ce_@{land}_t + lambdae_@{land}_t*(1-tauw_@{land}_t)*w_@{land}_t - lambdae_@{land}_t*ae_@{land}_t - lambdae_@{land}_t*tau_@{land}_t + betta_@{land}*lambdae_@{land}_t(+1)*(1-s_@{land}*(1+sep_timing_@{land})*(1-tax_f_@{land})*(1-p_@{land}_t(+1)))*ae_@{land}_t*R_w_t + betta_@{land}*(1-s_@{land}*(1+sep_timing_@{land})*(1-p_@{land}_t(+1)))*We_@{land}_t(+1) + betta_@{land}*s_@{land}*(1+sep_timing_@{land})*(1-p_@{land}_t(+1))*Weu1_@{land}_t(+1);

// Eq 2 + 87
@#if fix_asset_timing == 1
DRe_@{land}_t = betta_@{land}*((1-s_@{land}*(1+sep_timing_@{land})*(1-tax_f_@{land})*(1-p_@{land}_t(+1)))*N_@{land}_t/N_@{land}_t(+1)*lambdae_@{land}_t(+1)/lambdae_@{land}_t
@#for state in m
+betta_@{land}^(@{state})*lambdae_@{land}_t(+@{state+1})/lambdae_@{land}_t*p_@{land}_t(+@{state+1})/N_@{land}_t(+@{state+1})*(mueu@{state}_@{land}_t(+@{state})*Rest@{state}_@{land}_t(+@{state+1})*(1-tax_f_@{land}-tax_f2_@{land}))
@#endfor
@#else
DRe_@{land}_t = betta_@{land}*((1-s_@{land}*(1+sep_timing_@{land})*(1-tax_f_@{land})*(1-p_@{land}_t(+1)))*lambdae_@{land}_t(+1)/lambdae_@{land}_t
@#for state in m
+betta_@{land}^(@{state-1})*lambdae_@{land}_t(+@{state})/lambdae_@{land}_t*p_@{land}_t(+@{state})/N_@{land}_t(+@{state})*(mueu@{state}_@{land}_t(+@{state-1})*Rest@{state}_@{land}_t(+@{state})*(1-tax_f_@{land}-tax_f2_@{land}))
@#endfor
@#endif
+ s_@{land}*(1+sep_timing_@{land})*(1-p_@{land}_t(+1))*lambdaeu1_@{land}_t(+1)/lambdae_@{land}_t*(share1_@{land}_t(+1)*(1-tax_f_@{land}-tax_f2_@{land}) 
@#for state in k
@#if fix_telescope == 1
// Normalize each continuation by the preceding unemployment state's marginal utility so the ratios telescope.
+ betta_@{land}*(1-p_@{land}_t(+@{state}))*lambdaeu@{state}_@{land}_t(+@{state})/lambdaeu@{state-1}_@{land}_t(+@{state-1})*(share@{state}_@{land}_t(+@{state})*(1-tax_f_@{land}-tax_f2_@{land})
@#else
+ betta_@{land}*(1-p_@{land}_t(+@{state}))*lambdaeu@{state}_@{land}_t(+@{state})/lambdae_@{land}_t*(share@{state}_@{land}_t(+@{state})*(1-tax_f_@{land}-tax_f2_@{land})
@#endif
@#endfor
)))))))));


// Eq 3 + 88 
N_@{land}_t*(Ce_@{land}_t+ae_@{land}_t+tau_@{land}_t) = (1-tauw_@{land}_t)*N_@{land}_t*w_@{land}_t + PSI_@{land}_t + (1-s_@{land}*(1+sep_timing_@{land})*(1-tax_f_@{land})*(1-p_@{land}_t))*mue_@{land}_t(-1)*ae_@{land}_t(-1)*R_w_t(-1) 
+ p_@{land}_t*(
@#for state in m
@#if fix_asset_timing == 1
+mueu@{state}_@{land}_t(-1)*Rest@{state}_@{land}_t*ae_@{land}_t(-@{state+1})*(1-tax_f_@{land}-tax_f2_@{land})*R_w_t(-@{state+1})
@#else
+mueu@{state}_@{land}_t(-1)*Rest@{state}_@{land}_t*ae_@{land}_t(-@{state})*(1-tax_f_@{land}-tax_f2_@{land})*R_w_t(-@{state})
@#endif
@#endfor
       );

// Eq 4 + 89. With the matched SGU experiment active, Home households face
// the same next-period external return that enters the complete-insurance
// Euler equation. At zero, the maintained common-return model is unchanged.
@#if nfa_sgu_value > 0 && land == "a"
DRe_@{land}_t = 1/Rf_a_t(+1);
@#else
DRe_@{land}_t = 1/R_w_t;
@#endif

@#for state in m
    @#if state==1
    Rest@{state}_@{land}_t = 1-share@{state}_@{land}_t(-1);    // Eq 5 + 90
    @#else
    Rest@{state}_@{land}_t = Rest@{state-1}_@{land}_t(-1)-share@{state}_@{land}_t(-1); // Eq 6-12 + 91-97
    @#endif
@#endfor


//Euler conditions and consumption levels ok


lambdae_@{land}_t   =   Ce_@{land}_t^(-sigmac); // Eq 13 + 98
@#for state in g
lambdaeu@{state}_@{land}_t  =   Ceu@{state}_@{land}_t^(-sigmac); // Eq 14-21 + 99-106
@#endfor
lambdauu_@{land}_t  =   Cuu_@{land}_t^(-sigmac); // Eq 22 + 107


// Eq 23-30 + 108-115
@#for state in j  
Ceu@{state}_@{land}_t = kappaBS@{state}_@{land}_t  + share@{state}_@{land}_t*ae_@{land}_t(-@{state})*R_w_t(-@{state})*(1-tax_f_@{land}-tax_f2_@{land}) - tau_@{land}_t;  
@#endfor     


// Eq 31 + 116
Cuu_@{land}_t  = kappaBL_@{land}_t - tau_@{land}_t; 

//Aggregate consumption ok, Eq 32 + 117
C_@{land}_t = mue_@{land}_t*Ce_@{land}_t
 @#for state in g
+ mueu@{state}_@{land}_t*Ceu@{state}_@{land}_t %% here are 12 states 
@#endfor
+ muuu_@{land}_t*Cuu_@{land}_t;

// Two-sector labor market with aggregate undirected search.
NT_@{land}_t = (1-s_@{land}*(1+sep_timing_@{land}))*NT_@{land}_t(-1) + q_@{land}_t*VT_@{land}_t;
NN_@{land}_t = (1-s_@{land}*(1+sep_timing_@{land}))*NN_@{land}_t(-1) + q_@{land}_t*VN_@{land}_t;
N_@{land}_t = NT_@{land}_t + NN_@{land}_t;
V_@{land}_t = VT_@{land}_t + VN_@{land}_t;

// Eq 34 + 119
M_@{land}_t = kappae_@{land}*(1-(1-s_@{land}*(1+sep_timing_@{land}))*N_@{land}_t(-1))^alphaa_@{land}*V_@{land}_t^(1-alphaa_@{land});


// Probability of filling a vacancy ok, Eq 35 + 120
q_@{land}_t = M_@{land}_t/V_@{land}_t;

// Probability to find a job ok, Eq 36 + 121

p_@{land}_t = M_@{land}_t/(1-(1-s_@{land}*(1+sep_timing_@{land}))*N_@{land}_t(-1));

// Sectoral production and contemporaneous allocation of installed capital.
YT_@{land}_t = TS_@{land}_t*KTuse_@{land}_t^cp_@{land}*NT_@{land}_t^(1-cp_@{land});
YN_@{land}_t = TS_@{land}_t*KNuse_@{land}_t^cp_@{land}*NN_@{land}_t^(1-cp_@{land});
KTuse_@{land}_t + KNuse_@{land}_t = k_@{land}_t(-1);

MPLT_@{land}_t = (1-cp_@{land})*TS_@{land}_t*(KTuse_@{land}_t/NT_@{land}_t)^cp_@{land};
MPLN_@{land}_t = (1-cp_@{land})*TS_@{land}_t*(KNuse_@{land}_t/NN_@{land}_t)^cp_@{land};
MPKT_@{land}_t = cp_@{land}*TS_@{land}_t*(NT_@{land}_t/KTuse_@{land}_t)^(1-cp_@{land});
MPKN_@{land}_t = cp_@{land}*TS_@{land}_t*(NN_@{land}_t/KNuse_@{land}_t)^(1-cp_@{land});
qT_@{land}_t*MPKT_@{land}_t = RK_@{land}_t;
qN_@{land}_t*MPKN_@{land}_t = RK_@{land}_t;

Y_@{land}_t = YT_@{land}_t + YN_@{land}_t;
qY_@{land}_t*Y_@{land}_t = qT_@{land}_t*YT_@{land}_t + qN_@{land}_t*YN_@{land}_t;
PY_@{land}_t = qY_@{land}_t*CPI_@{land}_t;
 
// Labor-producer profits and the named tax_f2 internal transfer, 38 + 123.
J_@{land}_t = tax_f2_@{land}*(k_@{land}_t(-1)+b_@{land}_t(-1)+NFA_@{land}_t(-1))/mue_@{land}_t(-1)*R_w_t(-1)*(p_@{land}_t*(1-mue_@{land}_t(-1)-muuu_@{land}_t(-1)-mueu8_@{land}_t(-1)) + mueu8_@{land}_t(-1));
@#if fix_capital_financing == 1
PSI_@{land}_t = qT_@{land}_t*(YT_@{land}_t-RCT_@{land}_t-FCT_@{land}) + qN_@{land}_t*(YN_@{land}_t-RCN_@{land}_t-FCN_@{land}) - w_@{land}_t*N_@{land}_t - qI_@{land}_t*I_@{land}_t + k_@{land}_t - R_w_t(-1)*k_@{land}_t(-1) + J_@{land}_t + nfa_spread_@{land}_t;
@#else
// Attribution only: reproduce the old implicit tax on net capital issuance.
PSI_@{land}_t = qT_@{land}_t*(YT_@{land}_t-RCT_@{land}_t-FCT_@{land}) + qN_@{land}_t*(YN_@{land}_t-RCN_@{land}_t-FCN_@{land}) - w_@{land}_t*N_@{land}_t - qI_@{land}_t*I_@{land}_t - k_@{land}_t(-1)*(R_w_t(-1)-1) + J_@{land}_t + nfa_spread_@{land}_t;
@#endif
@#if recruiting_cost_form == 0
// Current form: vacancy costs relative to the fixed pre-reform vacancy stock.
RCT_@{land}_t = kappav_@{land}*VT_@{land}_ts/(1+chi_sector_T_@{land})*(VT_@{land}_t/VT_@{land}_ts)^(1+chi_sector_T_@{land}) + chi_sector_T_@{land}/(1+chi_sector_T_@{land})*kappav_@{land}*VT_@{land}_ts;
RCN_@{land}_t = kappav_@{land}*VN_@{land}_ts/(1+chi_sector_N_@{land})*(VN_@{land}_t/VN_@{land}_ts)^(1+chi_sector_N_@{land}) + chi_sector_N_@{land}/(1+chi_sector_N_@{land})*kappav_@{land}*VN_@{land}_ts;
@#elseif recruiting_cost_form == 1
// Kaas-Kircher: vacancy intensity is V_t/N_{t-1}; incumbent employment is predetermined.
RCT_@{land}_t = kappavT_@{land}*(VT_@{land}_ts/NT_@{land}_ts)/(1+chi_sector_T_@{land})*NT_@{land}_t(-1)*((VT_@{land}_t/NT_@{land}_t(-1))/(VT_@{land}_ts/NT_@{land}_ts))^(1+chi_sector_T_@{land});
RCN_@{land}_t = kappavN_@{land}*(VN_@{land}_ts/NN_@{land}_ts)/(1+chi_sector_N_@{land})*NN_@{land}_t(-1)*((VN_@{land}_t/NN_@{land}_t(-1))/(VN_@{land}_ts/NN_@{land}_ts))^(1+chi_sector_N_@{land});
@#elseif recruiting_cost_form == 2
// Restricted Merz-Yashiv: realized-hire intensity q_t V_t/N_{t-1}.
RCT_@{land}_t = kappavT_@{land}*(q_@{land}_ts*VT_@{land}_ts/NT_@{land}_ts)/(1+chi_sector_T_@{land})*NT_@{land}_t(-1)*((q_@{land}_t*VT_@{land}_t/NT_@{land}_t(-1))/(q_@{land}_ts*VT_@{land}_ts/NT_@{land}_ts))^(1+chi_sector_T_@{land});
RCN_@{land}_t = kappavN_@{land}*(q_@{land}_ts*VN_@{land}_ts/NN_@{land}_ts)/(1+chi_sector_N_@{land})*NN_@{land}_t(-1)*((q_@{land}_t*VN_@{land}_t/NN_@{land}_t(-1))/(q_@{land}_ts*VN_@{land}_ts/NN_@{land}_ts))^(1+chi_sector_N_@{land});
@#endif
CV_@{land}_t = RCT_@{land}_t + RCN_@{land}_t;

// Agent shares
mue_@{land}_t = N_@{land}_t;  // Eq 39 + 124
mueu1_@{land}_t = s_@{land}*(1+sep_timing_@{land})*(1-p_@{land}_t)*mue_@{land}_t(-1);   // Eq 40 + 125
@#for state in h 
mueu@{state}_@{land}_t = (1-p_@{land}_t)*mueu@{state-1}_@{land}_t(-1);  // Eq 41-47 + 126-132
@#endfor
@#for state in e
muuu_@{land}_t = (1-p_@{land}_t)*(mueu@{state}_@{land}_t(-1) + muuu_@{land}_t(-1));   // Eq 48 + 133
@#endfor

// Sectoral firm surpluses share the maintained economy-wide wage.
@#if recruiting_cost_form == 0
SfT_@{land}_t = qT_@{land}_t*MPLT_@{land}_t - w_@{land}_t + 1/R_w_t*(1-s_@{land}*(1+sep_timing_@{land}))*SfT_@{land}_t(+1);
SfN_@{land}_t = qN_@{land}_t*MPLN_@{land}_t - w_@{land}_t + 1/R_w_t*(1-s_@{land}*(1+sep_timing_@{land}))*SfN_@{land}_t(+1);
@#elseif recruiting_cost_form == 1
// An incumbent raises next period's recruiting capacity: -q^j R_B enters continuation value.
SfT_@{land}_t = qT_@{land}_t*MPLT_@{land}_t - w_@{land}_t + 1/R_w_t*((1-s_@{land}*(1+sep_timing_@{land}))*SfT_@{land}_t(+1) + qT_@{land}_t(+1)*chi_sector_T_@{land}/(1+chi_sector_T_@{land})*kappavT_@{land}*(VT_@{land}_ts/NT_@{land}_ts)*((VT_@{land}_t(+1)/NT_@{land}_t)/(VT_@{land}_ts/NT_@{land}_ts))^(1+chi_sector_T_@{land}));
SfN_@{land}_t = qN_@{land}_t*MPLN_@{land}_t - w_@{land}_t + 1/R_w_t*((1-s_@{land}*(1+sep_timing_@{land}))*SfN_@{land}_t(+1) + qN_@{land}_t(+1)*chi_sector_N_@{land}/(1+chi_sector_N_@{land})*kappavN_@{land}*(VN_@{land}_ts/NN_@{land}_ts)*((VN_@{land}_t(+1)/NN_@{land}_t)/(VN_@{land}_ts/NN_@{land}_ts))^(1+chi_sector_N_@{land}));
@#elseif recruiting_cost_form == 2
SfT_@{land}_t = qT_@{land}_t*MPLT_@{land}_t - w_@{land}_t + 1/R_w_t*((1-s_@{land}*(1+sep_timing_@{land}))*SfT_@{land}_t(+1) + qT_@{land}_t(+1)*chi_sector_T_@{land}/(1+chi_sector_T_@{land})*kappavT_@{land}*(q_@{land}_ts*VT_@{land}_ts/NT_@{land}_ts)*((q_@{land}_t(+1)*VT_@{land}_t(+1)/NT_@{land}_t)/(q_@{land}_ts*VT_@{land}_ts/NT_@{land}_ts))^(1+chi_sector_T_@{land}));
SfN_@{land}_t = qN_@{land}_t*MPLN_@{land}_t - w_@{land}_t + 1/R_w_t*((1-s_@{land}*(1+sep_timing_@{land}))*SfN_@{land}_t(+1) + qN_@{land}_t(+1)*chi_sector_N_@{land}/(1+chi_sector_N_@{land})*kappavN_@{land}*(q_@{land}_ts*VN_@{land}_ts/NN_@{land}_ts)*((q_@{land}_t(+1)*VN_@{land}_t(+1)/NN_@{land}_t)/(q_@{land}_ts*VN_@{land}_ts/NN_@{land}_ts))^(1+chi_sector_N_@{land}));
@#endif
Sf_@{land}_t = (NT_@{land}_t*SfT_@{land}_t + NN_@{land}_t*SfN_@{land}_t)/N_@{land}_t;

@#if recruiting_cost_form == 0
qT_@{land}_t*kappav_@{land}*(VT_@{land}_t/VT_@{land}_ts)^chi_sector_T_@{land}/q_@{land}_t = SfT_@{land}_t;
qN_@{land}_t*kappav_@{land}*(VN_@{land}_t/VN_@{land}_ts)^chi_sector_N_@{land}/q_@{land}_t = SfN_@{land}_t;
@#elseif recruiting_cost_form == 1
qT_@{land}_t*kappavT_@{land}*((VT_@{land}_t/NT_@{land}_t(-1))/(VT_@{land}_ts/NT_@{land}_ts))^chi_sector_T_@{land}/q_@{land}_t = SfT_@{land}_t;
qN_@{land}_t*kappavN_@{land}*((VN_@{land}_t/NN_@{land}_t(-1))/(VN_@{land}_ts/NN_@{land}_ts))^chi_sector_N_@{land}/q_@{land}_t = SfN_@{land}_t;
@#elseif recruiting_cost_form == 2
// q cancels between vacancy creation and realized hires.
qT_@{land}_t*kappavT_@{land}*((q_@{land}_t*VT_@{land}_t/NT_@{land}_t(-1))/(q_@{land}_ts*VT_@{land}_ts/NT_@{land}_ts))^chi_sector_T_@{land} = SfT_@{land}_t;
qN_@{land}_t*kappavN_@{land}*((q_@{land}_t*VN_@{land}_t/NN_@{land}_t(-1))/(q_@{land}_ts*VN_@{land}_ts/NN_@{land}_ts))^chi_sector_N_@{land} = SfN_@{land}_t;
@#endif

// Households value functions in utility terms

/*
Ue_@{land}_t  = Ce_@{land}_t^(1-sigmac)/(1-sigmac);  // Eq 51 + 136
Welfe_@{land}_t = Ue_@{land}_t  + DRe_@{land}_t*((1-s_@{land}*(1-p_@{land}_t(+1)))*Welfe_@{land}_t(+1) + (s_@{land}*(1-p_@{land}_t(+1)))*Welfeu1_@{land}_t(+1));
@#for state in g
Ueu@{state}_@{land}_t = Ceu@{state}_@{land}_t^(1-sigmac)/(1-sigmac); // Eq 52-59 + 137-144
@#endfor
@#for state in i
Welfeu@{state}_@{land}_t=Ueu@{state}_@{land}_t + DRe_@{land}_t*((1-p_@{land}_t(+1))*Welfeu@{state+1}_@{land}_t(+1) + p_@{land}_t(+1)*Welfe_@{land}_t(+1));
@#endfor
@#for state in e
Welfeu@{state}_@{land}_t=Ueu@{state}_@{land}_t + DRe_@{land}_t*((1-p_@{land}_t(+1))*Welfuu_@{land}_t(+1) + p_@{land}_t(+1)*Welfe_@{land}_t(+1));
@#endfor
Uuu_@{land}_t  = Cuu_@{land}_t^(1-sigmac)/(1-sigmac);  // Eq 60 + 145
Welfuu_@{land}_t=Uuu_@{land}_t + DRe_@{land}_t*((1-p_@{land}_t(+1))*Welfuu_@{land}_t(+1)+ p_@{land}_t(+1)*Welfe_@{land}_t(+1));
*/


Ue_@{land}_t  = Ce_@{land}_t^(1-sigmac)/(1-sigmac);  // Eq 51 + 136
Welfe_@{land}_t = Ue_@{land}_t  + betta_@{land}*((1-s_@{land}*(1+sep_timing_@{land})*(1-p_@{land}_t(+1)))*Welfe_@{land}_t(+1) + (s_@{land}*(1+sep_timing_@{land})*(1-p_@{land}_t(+1)))*Welfeu1_@{land}_t(+1));
@#for state in g
Ueu@{state}_@{land}_t = Ceu@{state}_@{land}_t^(1-sigmac)/(1-sigmac); // Eq 52-59 + 137-144
@#endfor
@#for state in i
Welfeu@{state}_@{land}_t=Ueu@{state}_@{land}_t + betta_@{land}*((1-p_@{land}_t(+1))*Welfeu@{state+1}_@{land}_t(+1) + p_@{land}_t(+1)*Welfe_@{land}_t(+1));
@#endfor
@#for state in e
Welfeu@{state}_@{land}_t=Ueu@{state}_@{land}_t + betta_@{land}*((1-p_@{land}_t(+1))*Welfuu_@{land}_t(+1) + p_@{land}_t(+1)*Welfe_@{land}_t(+1));
@#endfor
Uuu_@{land}_t  = Cuu_@{land}_t^(1-sigmac)/(1-sigmac);  // Eq 60 + 145
Welfuu_@{land}_t=Uuu_@{land}_t + betta_@{land}*((1-p_@{land}_t(+1))*Welfuu_@{land}_t(+1)+ p_@{land}_t(+1)*Welfe_@{land}_t(+1));

// Marginal value functions

@#for state in i
Weu@{state}_@{land}_t = Ueu@{state}_@{land}_t + betta_@{land}*(1-p_@{land}_t(+1))*Weu@{state+1}_@{land}_t(+1) + betta_@{land}*p_@{land}_t(+1)*We_@{land}_t(+1); // Eq 61-67 + 146-152
@#endfor

@#for state in e
Weu@{state}_@{land}_t = Ueu@{state}_@{land}_t + betta_@{land}*(1-p_@{land}_t(+1))*Wuu_@{land}_t(+1) + betta_@{land}*p_@{land}_t(+1)*We_@{land}_t(+1); // Eq 68 + 153
@#endfor

Wuu_@{land}_t = Uuu_@{land}_t + betta_@{land}*(1-p_@{land}_t(+1))*Wuu_@{land}_t(+1) + betta_@{land}*p_@{land}_t(+1)*We_@{land}_t(+1);  // Eq 69 + 154
@#if 0
    // Inactive scalar-selector signatures retained for source-level regression
    // compatibility. The active selectors below are country specific.
    @#if bargaining_mode == 1
    0 = @{bargaining_continuation_weight};
    @#elseif bargaining_mode == 2
    @#endif
@#endif
@#if (land == "a" && bargaining_mode_a == BARGAINING_ALL_UNEMPLOYED) || (land == "b" && bargaining_mode_b == BARGAINING_ALL_UNEMPLOYED)
// ALL_UNEMPLOYED: weight 1 is the unemployment-stock-weighted value across
// STU1-STU8 and LTU. Weight 0 nests LABOR_FORCE_WEIGHTED for continuation.
She_@{land}_t = We_@{land}_t - (
@#if land == "a"
@{bargaining_continuation_weight_a}
@#else
@{bargaining_continuation_weight_b}
@#endif
*((
@#for state in g
+ mueu@{state}_@{land}_t*Weu@{state}_@{land}_t
@#endfor
+ muuu_@{land}_t*Wuu_@{land}_t) / (
@#for state in g
+ mueu@{state}_@{land}_t
@#endfor
+ muuu_@{land}_t)) + (1-
@#if land == "a"
@{bargaining_continuation_weight_a}
@#else
@{bargaining_continuation_weight_b}
@#endif
)*((N_@{land}_t*Weu1_@{land}_t
@#for state in g
+ mueu@{state}_@{land}_t*Weu@{state}_@{land}_t
@#endfor
+ muuu_@{land}_t*Wuu_@{land}_t) / (N_@{land}_t
@#for state in g
+ mueu@{state}_@{land}_t
@#endfor
+ muuu_@{land}_t)));
@#elseif (land == "a" && bargaining_mode_a == BARGAINING_LABOR_FORCE_WEIGHTED) || (land == "b" && bargaining_mode_b == BARGAINING_LABOR_FORCE_WEIGHTED)
// LABOR_FORCE_WEIGHTED COLLECTIVE BARGAINING: employed workers carry mass N
// and retain STU1; unemployed workers carry current duration-state masses.
She_@{land}_t = We_@{land}_t - ((N_@{land}_t*Weu1_@{land}_t
@#for state in g
+ mueu@{state}_@{land}_t*Weu@{state}_@{land}_t
@#endfor
+ muuu_@{land}_t*Wuu_@{land}_t) / (N_@{land}_t
@#for state in g
+ mueu@{state}_@{land}_t
@#endfor
+ muuu_@{land}_t));
@#elseif (land == "a" && bargaining_mode_a == BARGAINING_CONVEX_STU1_LTU) || (land == "b" && bargaining_mode_b == BARGAINING_CONVEX_STU1_LTU)
// CONVEX_STU1_LTU: optional fixed blend of the first-unemployment and LTU values.
She_@{land}_t = We_@{land}_t - ((1-@{convex_ltu_weight})*Weu1_@{land}_t + @{convex_ltu_weight}*Wuu_@{land}_t);
@#else
// STU1: a newly separated worker's first-unemployment-state value.
She_@{land}_t = We_@{land}_t - Weu1_@{land}_t;
@#endif

// Flexible-wage sharing rule recovered exactly when gammaw=0:
// She_@{land}_t = xoui_@{land}/(1-xoui_@{land})*(1-tauw_@{land}_t)*(lambdae_@{land}_t*Sf_@{land}_t);

// Nash target wage: sharing rule evaluated at wnash via shadow surpluses.
She_@{land}_t + lambdae_@{land}_t*(1-tauw_@{land}_t)*(wnash_@{land}_t-w_@{land}_t) = xoui_@{land}/(1-xoui_@{land})*(1-tauw_@{land}_t)*lambdae_@{land}_t*(Sf_@{land}_t+(w_@{land}_t-wnash_@{land}_t));

// Hall (2005) backward-looking wage norm.
w_@{land}_t = gammaw_@{land}*w_@{land}_t(-1) + (1-gammaw_@{land})*wnash_@{land}_t;

// Government Budget Constraint ok
b_@{land}_t + NFA_@{land}_t + k_@{land}_t = mue_@{land}_t*ae_@{land}_t; // Eq 71 + 156

// Eq 72 + 157
tauw_@{land}_t*N_@{land}_t*w_@{land}_t + tau_@{land}_t + b_@{land}_t = R_w_t(-1)*b_@{land}_t(-1) + DG_@{land}_t + (muuu_@{land}_t*kappaBL_@{land}_t
 @#for state in g
+mueu@{state}_@{land}_t*kappaBS@{state}_@{land}_t
@#endfor
);   

//Shocks
//Technology shock, Eq 73 + 158
TS_@{land}_t/TS_@{land}_ts-(TS_@{land}_t(-1)/TS_@{land}_ts)^rhoA_@{land}*exp(-epsiA_@{land});

//Government spending shock, Eq 74 + 159
 DG_@{land}_t/DG_@{land}_ts-(DG_@{land}_t(-1)/DG_@{land}_ts)^rhoG_@{land}*exp(epsiG_@{land});
// DG_@{land}_t-DG_@{land}_ts-(DG_@{land}_t(-1)-DG_@{land}_ts)*rhoG_@{land} + (epsiG_@{land});

// FOCs: Eq 75-81 + 160-166
@#for state in m
@#if fix_cohort_convention == 1
// Common-cohort policy: one p is the member's employment probability and one p is the cohort return flow.
lambdaeu@{state}_@{land}_t=betta_@{land}*p_@{land}_t(+1)*lambdae_@{land}_t(+1)*p_@{land}_t(+1)/N_@{land}_t(+1)*mueu@{state}_@{land}_t+betta_@{land}*(1-p_@{land}_t(+1))*lambdaeu@{state+1}_@{land}_t(+1);
@#else
// Aggregate-family alternative with one job-finding probability.
lambdaeu@{state}_@{land}_t=betta_@{land}*lambdae_@{land}_t(+1)*p_@{land}_t(+1)/N_@{land}_t(+1)*mueu@{state}_@{land}_t+betta_@{land}*(1-p_@{land}_t(+1))*lambdaeu@{state+1}_@{land}_t(+1);
@#endif
@#endfor

// Eq 82 + 167
1 = 0
@#for state in j
+ share@{state}_@{land}_t(-@{8-state})
@#endfor
;

// Investment. At exactly iac_value = 0, remove the investment-growth
// leads/lags from the model instead of leaving a zero-coefficient dynamic
// equation in Dynare's lead-lag incidence structure.
@#if iac_value == 0
k_@{land}_t = (1-delta_@{land})*k_@{land}_t(-1) + I_@{land}_t;
@#else
k_@{land}_t = (1-delta_@{land})*k_@{land}_t(-1) + (1-iac_@{land}/2*(I_@{land}_t/I_@{land}_t(-1)-1)^2)*I_@{land}_t;
@#endif
R_w_t*TQ_@{land}_t = RK_@{land}_t(+1) + (1-delta_@{land})*TQ_@{land}_t(+1);
@#if iac_value == 0
qI_@{land}_t = TQ_@{land}_t;
@#else
qI_@{land}_t = TQ_@{land}_t*(1-iac_@{land}/2*(I_@{land}_t/I_@{land}_t(-1)-1)^2-iac_@{land}*(I_@{land}_t/I_@{land}_t(-1)-1)*I_@{land}_t/I_@{land}_t(-1))+TQ_@{land}_t(+1)/R_w_t*iac_@{land}*(I_@{land}_t(+1)/I_@{land}_t-1)*(I_@{land}_t(+1)/I_@{land}_t)^2;
@#endif
Pi_@{land}_t= CPI_@{land}_t(+1)/CPI_@{land}_t;

// do the welfare calculation (at the aggregate level)
//Welf_@{land}_t=(C_@{land}_t^(1-sigmac))/(1-sigmac) + DRe_@{land}_t*Welf_@{land}_t(+1);
Welf_@{land}_t=(C_@{land}_t^(1-sigmac))/(1-sigmac) + betta_@{land}*Welf_@{land}_t(+1);

// Legacy aggregate marginal products retained only as reporting identities.
MPL_@{land}_t=(NT_@{land}_t*MPLT_@{land}_t+NN_@{land}_t*MPLN_@{land}_t)/N_@{land}_t;
MPK_@{land}_t=(KTuse_@{land}_t*MPKT_@{land}_t+KNuse_@{land}_t*MPKN_@{land}_t)/k_@{land}_t(-1);


@#endfor

