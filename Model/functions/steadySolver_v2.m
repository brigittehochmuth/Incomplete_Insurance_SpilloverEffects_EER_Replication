function [residual, state] = ...
	steadySolver(InitVals)



global M_ fix_telescope_ss fix_asset_timing_ss fix_benefit_index_ss fix_cohort_convention_ss nfa_anchor_mode_ss bargaining_mode_ss bargaining_continuation_weight_ss
global bargaining_mode_a_ss bargaining_mode_b_ss bargaining_continuation_weight_a_ss bargaining_continuation_weight_b_ss
global convex_ltu_weight_ss recruiting_ss_share_a_guess recruiting_ss_share_b_guess
if isempty(fix_telescope_ss); fix_telescope_ss = 1; end
if isempty(fix_asset_timing_ss); fix_asset_timing_ss = 1; end
if isempty(fix_benefit_index_ss); fix_benefit_index_ss = 1; end
if isempty(fix_cohort_convention_ss); fix_cohort_convention_ss = 1; end
if isempty(nfa_anchor_mode_ss); nfa_anchor_mode_ss = 0; end
if isempty(bargaining_mode_ss); bargaining_mode_ss = 0; end
if isempty(bargaining_continuation_weight_ss); bargaining_continuation_weight_ss = 1; end
if isempty(bargaining_mode_a_ss); bargaining_mode_a_ss = bargaining_mode_ss; end
if isempty(bargaining_mode_b_ss); bargaining_mode_b_ss = bargaining_mode_ss; end
if isempty(bargaining_continuation_weight_a_ss); bargaining_continuation_weight_a_ss = bargaining_continuation_weight_ss; end
if isempty(bargaining_continuation_weight_b_ss); bargaining_continuation_weight_b_ss = bargaining_continuation_weight_ss; end
if isempty(convex_ltu_weight_ss); convex_ltu_weight_ss = 0.25; end
if isempty(recruiting_ss_share_a_guess); recruiting_ss_share_a_guess = 0.7878951514; end
if isempty(recruiting_ss_share_b_guess); recruiting_ss_share_b_guess = 0.7878828624; end
assert(ismember(bargaining_mode_a_ss,0:3) && ismember(bargaining_mode_b_ss,0:3), ...
    'SteadySolver:BargainingMode', ...
    'Country bargaining modes must be one of the implemented named modes 0 through 3.');
assert(bargaining_continuation_weight_a_ss >= 0 && bargaining_continuation_weight_a_ss <= 1 ...
    && bargaining_continuation_weight_b_ss >= 0 && bargaining_continuation_weight_b_ss <= 1, ...
    'SteadySolver:BargainingContinuation', ...
    'Country continuation weights must lie in [0,1].');
assert(convex_ltu_weight_ss >= 0 && convex_ltu_weight_ss <= 1, ...
    'SteadySolver:ConvexLTUWeight', ...
    'The convex STU1/LTU weight must lie in [0,1].');
% Read out parameters to access them with their name
for iParameter = 1:M_.param_nbr
  paramname = deblank(M_.param_names{iParameter,:});
  eval(['global ' paramname]);
  eval([ paramname ' = M_.params(' int2str(iParameter) ');']);
% disp(paramname)
end



R_w_ts        =InitVals(1);
share8_a_ts   =InitVals(2);
lambdae_a_ts  =InitVals(3);
w_a_ts           =InitVals(4);
fifth_unknown_ts =InitVals(5);
share8_b_ts   =InitVals(6);
lambdae_b_ts  =InitVals(7);
w_b_ts      =InitVals(8);

if recruiting_cost_form == 0
    recruiting_ss_multiplier_a = 1;
    recruiting_ss_multiplier_b = 1;
else
    recruiting_ss_multiplier_a = NaN;
    recruiting_ss_multiplier_b = NaN;
end

%% Home
k_a_ts = ((R_w_ts*TQ_a_ts-(1-delta_a)*TQ_a_ts)/(qY_a_ts*cp_a*TS_a_ts*N_a_ts^(1-cp_a)))^(1/(cp_a-1));
Y_a_ss = TS_a_ts*(k_a_ts^cp_a*N_a_ts^(1-cp_a));
if nfa_anchor_mode_ss
    betta_b_ts = fifth_unknown_ts;
    NFA_a_ts = nfa_anchor_a*Y_a_ss;
else
    betta_b_ts = betta_a;
    NFA_a_ts = fifth_unknown_ts;
end
NFA_b = -size_a/(1-size_a)*NFA_a_ts;
Rf_a_ss = R_w_ts*exp(-psi_nfa*(NFA_a_ts/Y_a_ss-nfa_anchor_a));
nfa_spread_a_ss = (Rf_a_ss-R_w_ts)*NFA_a_ts;
nfa_spread_b_ss = -size_a/(1-size_a)*CPI_a_ts/CPI_b_ts*nfa_spread_a_ss;

tauw_a_ts = (omega_ba*TS_a_ts*(k_a_ts^cp_a*N_a_ts^(1-cp_a))*(R_w_ts - 1) + B0_a*TS_a_ts*(k_a_ts^cp_a*N_a_ts^(1-cp_a))- tau_a_ts + muuu_a_ts*rrl_a*w_a_ts...
+ mueu1_a_ts*rrs_a*w_a_ts...
+ mueu2_a_ts*rrs_a*w_a_ts...
+ mueu3_a_ts*rrs_a*w_a_ts...
+ mueu4_a_ts*rrs_a*w_a_ts...
+ mueu5_a_ts*rrs_a*w_a_ts...
+ mueu6_a_ts*rrs_a*w_a_ts...
+ mueu7_a_ts*rrs_a*w_a_ts...
+ mueu8_a_ts*rrs_a*w_a_ts...
)/(w_a_ts*N_a_ts +muuu_a_ts*rrl_a*w_a_ts...
+ mueu1_a_ts*rrs_a*w_a_ts...
+ mueu2_a_ts*rrs_a*w_a_ts...
+ mueu3_a_ts*rrs_a*w_a_ts...
+ mueu4_a_ts*rrs_a*w_a_ts...
+ mueu5_a_ts*rrs_a*w_a_ts...
+ mueu6_a_ts*rrs_a*w_a_ts...
+ mueu7_a_ts*rrs_a*w_a_ts...
+ mueu8_a_ts*rrs_a*w_a_ts...
);

kappaBS1_a_ts     = (1-tauw_a_ts)*rrs_a*w_a_ts;
kappaBS2_a_ts     = (1-tauw_a_ts)*rrs_a*w_a_ts;
kappaBS3_a_ts     = (1-tauw_a_ts)*rrs_a*w_a_ts;
kappaBS4_a_ts     = (1-tauw_a_ts)*rrs_a*w_a_ts;
kappaBS5_a_ts     = (1-tauw_a_ts)*rrs_a*w_a_ts;
kappaBS6_a_ts     = (1-tauw_a_ts)*rrs_a*w_a_ts;
kappaBS7_a_ts     = (1-tauw_a_ts)*rrs_a*w_a_ts;
kappaBS8_a_ts     = (1-tauw_a_ts)*rrs_a*w_a_ts;

kappaBL_a_ts      = (1-tauw_a_ts)*rrl_a*w_a_ts;

job_flow_a_ts = -(w_a_ts + ...
    (TS_a_ts*(k_a_ts/N_a_ts)^cp_a*(cp_a - 1))/CPI_a_ts);
if recruiting_cost_form == 0
    Sf_a_ts = job_flow_a_ts/(1-(1/R_w_ts)*(1-s_a));
    recruiting_resource_a_ts = Sf_a_ts*q_a_ts*V_a_ts;
else
    SfT_a_ts = job_flow_a_ts/(1-(1/R_w_ts)*(1-s_a/(1+chi_sector_T_a)));
    SfN_a_ts = job_flow_a_ts/(1-(1/R_w_ts)*(1-s_a/(1+chi_sector_N_a)));
    Sf_a_ts = recruiting_ss_share_a_guess*SfT_a_ts ...
        +(1-recruiting_ss_share_a_guess)*SfN_a_ts;
    recruiting_resource_a_ts = s_a*N_a_ts*( ...
        recruiting_ss_share_a_guess*SfT_a_ts/(1+chi_sector_T_a) ...
        +(1-recruiting_ss_share_a_guess)*SfN_a_ts/(1+chi_sector_N_a));
end

J_a_ss = tax_f2_a*(k_a_ts+omega_ba*Y_a_ss+NFA_a_ts)/mue_a_ts*R_w_ts*(p_a_ts*(1-mue_a_ts-muuu_a_ts-mueu8_a_ts) + mueu8_a_ts);
PSI_a_ts = qY_a_ts*Y_a_ss - w_a_ts*N_a_ts - qI_a_ts*delta_a*k_a_ts - recruiting_resource_a_ts + k_a_ts - R_w_ts*k_a_ts + J_a_ss + nfa_spread_a_ss;

ae_a_ts = (k_a_ts+omega_ba*TS_a_ts*(k_a_ts^cp_a*N_a_ts^(1-cp_a))+NFA_a_ts)/mue_a_ts;

if fix_benefit_index_ss
    next_benefit_a = [kappaBS2_a_ts kappaBS3_a_ts kappaBS4_a_ts kappaBS5_a_ts kappaBS6_a_ts kappaBS7_a_ts kappaBS8_a_ts];
else
    next_benefit_a = [kappaBS8_a_ts kappaBS7_a_ts kappaBS6_a_ts kappaBS5_a_ts kappaBS4_a_ts kappaBS3_a_ts kappaBS2_a_ts];
end
if fix_cohort_convention_ss
    cohort_probability_a = p_a_ts;
else
    cohort_probability_a = 1;
end
share7_a_ts  = (1/(ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a)))*(-kappaBS7_a_ts+tau_a_ts +((betta_a*cohort_probability_a*lambdae_a_ts*p_a_ts/N_a_ts*mueu7_a_ts+betta_a*(1-p_a_ts)*(next_benefit_a(7) + share8_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts)^(-sigmac)))^(-1/sigmac));
share6_a_ts  = (1/(ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a)))*(-kappaBS6_a_ts+tau_a_ts +((betta_a*cohort_probability_a*lambdae_a_ts*p_a_ts/N_a_ts*mueu6_a_ts+betta_a*(1-p_a_ts)*(next_benefit_a(6) + share7_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts)^(-sigmac)))^(-1/sigmac));
share5_a_ts  = (1/(ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a)))*(-kappaBS5_a_ts+tau_a_ts +((betta_a*cohort_probability_a*lambdae_a_ts*p_a_ts/N_a_ts*mueu5_a_ts+betta_a*(1-p_a_ts)*(next_benefit_a(5) + share6_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts)^(-sigmac)))^(-1/sigmac));
share4_a_ts  = (1/(ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a)))*(-kappaBS4_a_ts+tau_a_ts +((betta_a*cohort_probability_a*lambdae_a_ts*p_a_ts/N_a_ts*mueu4_a_ts+betta_a*(1-p_a_ts)*(next_benefit_a(4) + share5_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts)^(-sigmac)))^(-1/sigmac));
share3_a_ts  = (1/(ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a)))*(-kappaBS3_a_ts+tau_a_ts +((betta_a*cohort_probability_a*lambdae_a_ts*p_a_ts/N_a_ts*mueu3_a_ts+betta_a*(1-p_a_ts)*(next_benefit_a(3) + share4_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts)^(-sigmac)))^(-1/sigmac));
share2_a_ts  = (1/(ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a)))*(-kappaBS2_a_ts+tau_a_ts +((betta_a*cohort_probability_a*lambdae_a_ts*p_a_ts/N_a_ts*mueu2_a_ts+betta_a*(1-p_a_ts)*(next_benefit_a(2) + share3_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts)^(-sigmac)))^(-1/sigmac));
share1_a_ts  = (1/(ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a)))*(-kappaBS1_a_ts+tau_a_ts +((betta_a*cohort_probability_a*lambdae_a_ts*p_a_ts/N_a_ts*mueu1_a_ts+betta_a*(1-p_a_ts)*(next_benefit_a(1) + share2_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts)^(-sigmac)))^(-1/sigmac));

Rest1_a_ts = (1         -share1_a_ts);
Rest2_a_ts = (Rest1_a_ts-share2_a_ts);
Rest3_a_ts = (Rest2_a_ts-share3_a_ts);
Rest4_a_ts = (Rest3_a_ts-share4_a_ts);
Rest5_a_ts = (Rest4_a_ts-share5_a_ts);
Rest6_a_ts = (Rest5_a_ts-share6_a_ts);
Rest7_a_ts = (Rest6_a_ts-share7_a_ts);



Ce_a_ts   = (1-tauw_a_ts)*w_a_ts + PSI_a_ts/N_a_ts + (1-s_a*(1-tax_f_a)*(1-p_a_ts))*ae_a_ts*R_w_ts - ae_a_ts - tau_a_ts ...
+ p_a_ts*(mueu1_a_ts*Rest1_a_ts + mueu2_a_ts*Rest2_a_ts + mueu3_a_ts*Rest3_a_ts  + mueu4_a_ts*Rest4_a_ts + mueu5_a_ts*Rest5_a_ts  + mueu6_a_ts*Rest6_a_ts + mueu7_a_ts*Rest7_a_ts)*ae_a_ts*(1-tax_f_a-tax_f2_a)*R_w_ts/mue_a_ts;

Ceu1_a_ts  = kappaBS1_a_ts  + share1_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts; 
Ceu2_a_ts  = kappaBS2_a_ts  + share2_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts; 
Ceu3_a_ts  = kappaBS3_a_ts  + share3_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts; 
Ceu4_a_ts  = kappaBS4_a_ts  + share4_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts;
Ceu5_a_ts  = kappaBS5_a_ts  + share5_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts;
Ceu6_a_ts  = kappaBS6_a_ts  + share6_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts;
Ceu7_a_ts  = kappaBS7_a_ts  + share7_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts;
Ceu8_a_ts  = kappaBS8_a_ts  + share8_a_ts*ae_a_ts*R_w_ts*(1-tax_f_a-tax_f2_a) - tau_a_ts;

Cuu_a_ts   = kappaBL_a_ts - tau_a_ts;

C_a_ts = Ce_a_ts*N_a_ts + mueu1_a_ts*Ceu1_a_ts+mueu2_a_ts*Ceu2_a_ts+mueu3_a_ts*Ceu3_a_ts+mueu4_a_ts*Ceu4_a_ts...
    +mueu5_a_ts*Ceu5_a_ts+mueu6_a_ts*Ceu6_a_ts+mueu7_a_ts*Ceu7_a_ts+mueu8_a_ts*Ceu8_a_ts...
    +muuu_a_ts*Cuu_a_ts;

lambdaeu1_a_ts =   Ceu1_a_ts^(-sigmac); 
lambdaeu2_a_ts =   Ceu2_a_ts^(-sigmac); 
lambdaeu3_a_ts =   Ceu3_a_ts^(-sigmac); 
lambdaeu4_a_ts =   Ceu4_a_ts^(-sigmac);
lambdaeu5_a_ts =   Ceu5_a_ts^(-sigmac);
lambdaeu6_a_ts =   Ceu6_a_ts^(-sigmac);
lambdaeu7_a_ts =   Ceu7_a_ts^(-sigmac);
lambdaeu8_a_ts =   Ceu8_a_ts^(-sigmac);

lambdauu_a_ts  =   Cuu_a_ts^(-sigmac); 


if fix_asset_timing_ss
    returned_discount_a = betta_a.^(1:7);
else
    returned_discount_a = betta_a.^(0:6);
end
if fix_telescope_ss
    continuation_denominator_a = [lambdaeu1_a_ts lambdaeu2_a_ts lambdaeu3_a_ts lambdaeu4_a_ts lambdaeu5_a_ts lambdaeu6_a_ts lambdaeu7_a_ts];
else
    continuation_denominator_a = repmat(lambdae_a_ts, 1, 7);
end
DRe_a_ts = (betta_a*((1-s_a*(1-tax_f_a)*(1-p_a_ts))*lambdae_a_ts/lambdae_a_ts*CPI_a_ts/CPI_a_ts... 
+ returned_discount_a(1)*p_a_ts/N_a_ts*(mueu1_a_ts*Rest1_a_ts*(1-tax_f_a-tax_f2_a)*CPI_a_ts/CPI_a_ts)...
+ returned_discount_a(2)*p_a_ts/N_a_ts*(mueu2_a_ts*Rest2_a_ts*(1-tax_f_a-tax_f2_a)*CPI_a_ts/CPI_a_ts)...
+ returned_discount_a(3)*p_a_ts/N_a_ts*(mueu3_a_ts*Rest3_a_ts*(1-tax_f_a-tax_f2_a)*CPI_a_ts/CPI_a_ts)...
+ returned_discount_a(4)*p_a_ts/N_a_ts*(mueu4_a_ts*Rest4_a_ts*(1-tax_f_a-tax_f2_a)*CPI_a_ts/CPI_a_ts)...
+ returned_discount_a(5)*p_a_ts/N_a_ts*(mueu5_a_ts*Rest5_a_ts*(1-tax_f_a-tax_f2_a)*CPI_a_ts/CPI_a_ts)...
+ returned_discount_a(6)*p_a_ts/N_a_ts*(mueu6_a_ts*Rest6_a_ts*(1-tax_f_a-tax_f2_a)*CPI_a_ts/CPI_a_ts)...
+ returned_discount_a(7)*p_a_ts/N_a_ts*(mueu7_a_ts*Rest7_a_ts*(1-tax_f_a-tax_f2_a)*CPI_a_ts/CPI_a_ts)...
+ s_a*(1-p_a_ts)  *lambdaeu1_a_ts/lambdae_a_ts*(CPI_a_ts/CPI_a_ts*share1_a_ts*(1-tax_f_a-tax_f2_a)... 
+ betta_a*(1-p_a_ts)*lambdaeu2_a_ts/continuation_denominator_a(1)*(CPI_a_ts/CPI_a_ts*share2_a_ts*(1-tax_f_a-tax_f2_a)...
+ betta_a*(1-p_a_ts)*lambdaeu3_a_ts/continuation_denominator_a(2)*(CPI_a_ts/CPI_a_ts*share3_a_ts*(1-tax_f_a-tax_f2_a)...
+ betta_a*(1-p_a_ts)*lambdaeu4_a_ts/continuation_denominator_a(3)*(CPI_a_ts/CPI_a_ts*share4_a_ts*(1-tax_f_a-tax_f2_a)...
+ betta_a*(1-p_a_ts)*lambdaeu5_a_ts/continuation_denominator_a(4)*(CPI_a_ts/CPI_a_ts*share5_a_ts*(1-tax_f_a-tax_f2_a)...
+ betta_a*(1-p_a_ts)*lambdaeu6_a_ts/continuation_denominator_a(5)*(CPI_a_ts/CPI_a_ts*share6_a_ts*(1-tax_f_a-tax_f2_a)...
+ betta_a*(1-p_a_ts)*lambdaeu7_a_ts/continuation_denominator_a(6)*(CPI_a_ts/CPI_a_ts*share7_a_ts*(1-tax_f_a-tax_f2_a)...
+ betta_a*(1-p_a_ts)*lambdaeu8_a_ts/continuation_denominator_a(7)*(CPI_a_ts/CPI_a_ts*share8_a_ts*(1-tax_f_a-tax_f2_a)...
))))))))));

Ue_a_ts   = Ce_a_ts^(1-sigmac)/(1-sigmac);
Ueu1_a_ts = Ceu1_a_ts^(1-sigmac)/(1-sigmac);
Ueu2_a_ts = Ceu2_a_ts^(1-sigmac)/(1-sigmac);
Ueu3_a_ts = Ceu3_a_ts^(1-sigmac)/(1-sigmac);
Ueu4_a_ts = Ceu4_a_ts^(1-sigmac)/(1-sigmac);
Ueu5_a_ts = Ceu5_a_ts^(1-sigmac)/(1-sigmac);
Ueu6_a_ts = Ceu6_a_ts^(1-sigmac)/(1-sigmac);
Ueu7_a_ts = Ceu7_a_ts^(1-sigmac)/(1-sigmac);
Ueu8_a_ts = Ceu8_a_ts^(1-sigmac)/(1-sigmac);

Uuu_a_ts  = Cuu_a_ts^(1-sigmac)/(1-sigmac);

We_a_ts   =((betta_a*p_a_ts - betta_a + 1)*(Ce_a_ts*lambdae_a_ts - Ue_a_ts + ae_a_ts*lambdae_a_ts + lambdae_a_ts*tau_a_ts + lambdae_a_ts*w_a_ts*(tauw_a_ts - 1) + betta_a*s_a*(Ueu1_a_ts - betta_a*(Ueu2_a_ts - betta_a*(Ueu3_a_ts - betta_a*(Ueu4_a_ts - betta_a*(Ueu5_a_ts - betta_a*(Ueu6_a_ts - betta_a*(p_a_ts - 1)*(Ueu7_a_ts - (betta_a*(p_a_ts - 1)*(Ueu8_a_ts - Ueu8_a_ts*betta_a + Uuu_a_ts*betta_a + Ueu8_a_ts*betta_a*p_a_ts - Uuu_a_ts*betta_a*p_a_ts))/(betta_a*p_a_ts - betta_a + 1)))*(p_a_ts - 1))*(p_a_ts - 1))*(p_a_ts - 1))*(p_a_ts - 1))*(p_a_ts - 1))*(p_a_ts - 1) -R_w_ts*ae_a_ts*betta_a*lambdae_a_ts*(p_a_ts*(1-tax_f_a)*s_a - s_a*(1-tax_f_a) + 1)))/((betta_a - 1)*(betta_a*p_a_ts - betta_a + betta_a*s_a - betta_a*p_a_ts*s_a + 1));

Wuu_a_ts  = (Uuu_a_ts + betta_a*p_a_ts*We_a_ts)/(1-betta_a*(1-p_a_ts));
 Weu8_a_ts = Ueu8_a_ts + betta_a*(1-p_a_ts)*Wuu_a_ts + betta_a*p_a_ts*We_a_ts;
 Weu7_a_ts = Ueu7_a_ts + betta_a*(1-p_a_ts)*Weu8_a_ts + betta_a*p_a_ts*We_a_ts;
 Weu6_a_ts = Ueu6_a_ts + betta_a*(1-p_a_ts)*Weu7_a_ts + betta_a*p_a_ts*We_a_ts;
 Weu5_a_ts = Ueu5_a_ts + betta_a*(1-p_a_ts)*Weu6_a_ts + betta_a*p_a_ts*We_a_ts;
 Weu4_a_ts = Ueu4_a_ts + betta_a*(1-p_a_ts)*Weu5_a_ts + betta_a*p_a_ts*We_a_ts;
 Weu3_a_ts = Ueu3_a_ts + betta_a*(1-p_a_ts)*Weu4_a_ts + betta_a*p_a_ts*We_a_ts;
 Weu2_a_ts = Ueu2_a_ts + betta_a*(1-p_a_ts)*Weu3_a_ts + betta_a*p_a_ts*We_a_ts;
 Weu1_a_ts = Ueu1_a_ts + betta_a*(1-p_a_ts)*Weu2_a_ts + betta_a*p_a_ts*We_a_ts;
unemployment_mass_a = mueu1_a_ts+mueu2_a_ts+mueu3_a_ts+mueu4_a_ts ...
    +mueu5_a_ts+mueu6_a_ts+mueu7_a_ts+mueu8_a_ts+muuu_a_ts;
unemployed_value_numerator_a = mueu1_a_ts*Weu1_a_ts ...
    +mueu2_a_ts*Weu2_a_ts+mueu3_a_ts*Weu3_a_ts ...
    +mueu4_a_ts*Weu4_a_ts+mueu5_a_ts*Weu5_a_ts ...
    +mueu6_a_ts*Weu6_a_ts+mueu7_a_ts*Weu7_a_ts ...
    +mueu8_a_ts*Weu8_a_ts+muuu_a_ts*Wuu_a_ts;
labor_force_mass_a = N_a_ts+unemployment_mass_a;
Wout_all_unemployed_a_ts = unemployed_value_numerator_a/unemployment_mass_a;
Wout_labor_force_weighted_a_ts = ...
    (N_a_ts*Weu1_a_ts+unemployed_value_numerator_a)/labor_force_mass_a;
Wout_convex_stu1_ltu_a_ts = ...
    (1-convex_ltu_weight_ss)*Weu1_a_ts+convex_ltu_weight_ss*Wuu_a_ts;
% Backward-compatible diagnostic aliases. The active selector is country-specific.
Wout_unemployed_a_ts = Wout_all_unemployed_a_ts;
Wout_union_a_ts = Wout_labor_force_weighted_a_ts;
% Legacy scalar signatures: if bargaining_mode_ss == 1 and elseif bargaining_mode_ss == 2.
% Legacy blend: bargaining_continuation_weight_ss*Wout_unemployed_a_ts.
if bargaining_mode_a_ss == 1
    Wout_a_ts = bargaining_continuation_weight_a_ss*Wout_all_unemployed_a_ts ...
        +(1-bargaining_continuation_weight_a_ss)*Wout_labor_force_weighted_a_ts;
elseif bargaining_mode_a_ss == 2
    Wout_a_ts = Wout_labor_force_weighted_a_ts;
elseif bargaining_mode_a_ss == 3
    Wout_a_ts = Wout_convex_stu1_ltu_a_ts;
else
    Wout_a_ts = Weu1_a_ts;
end
She_a_ts = We_a_ts-Wout_a_ts;
labor_force_mass_gap_a = labor_force_mass_a-1;
labor_force_weighted_identity_gap_a = ...
    labor_force_mass_a*Wout_labor_force_weighted_a_ts ...
    -(N_a_ts*Weu1_a_ts+unemployment_mass_a*Wout_all_unemployed_a_ts);
selected_surplus_gap_a = She_a_ts-(We_a_ts-Wout_a_ts);

%% Foreign
k_b_ts = ((R_w_ts*TQ_b_ts-(1-delta_b)*TQ_b_ts)/(qY_b_ts*cp_b*TS_b_ts*N_b_ts^(1-cp_b)))^(1/(cp_b-1));
Y_b_ss = TS_b_ts*(k_b_ts^cp_b*N_b_ts^(1-cp_b));

tauw_b_ts = (omega_bb*TS_b_ts*(k_b_ts^cp_b*N_b_ts^(1-cp_b))*(R_w_ts - 1) + B0_b*TS_b_ts*(k_b_ts^cp_b*N_b_ts^(1-cp_b))- tau_b_ts + muuu_b_ts*rrl_b*w_b_ts...
+ mueu1_b_ts*rrs_b*w_b_ts...
+ mueu2_b_ts*rrs_b*w_b_ts...
+ mueu3_b_ts*rrs_b*w_b_ts...
+ mueu4_b_ts*rrs_b*w_b_ts...
+ mueu5_b_ts*rrs_b*w_b_ts...
+ mueu6_b_ts*rrs_b*w_b_ts...
+ mueu7_b_ts*rrs_b*w_b_ts...
+ mueu8_b_ts*rrs_b*w_b_ts...
)/(w_b_ts*N_b_ts +muuu_b_ts*rrl_b*w_b_ts...
+ mueu1_b_ts*rrs_b*w_b_ts...
+ mueu2_b_ts*rrs_b*w_b_ts...
+ mueu3_b_ts*rrs_b*w_b_ts...
+ mueu4_b_ts*rrs_b*w_b_ts...
+ mueu5_b_ts*rrs_b*w_b_ts...
+ mueu6_b_ts*rrs_b*w_b_ts...
+ mueu7_b_ts*rrs_b*w_b_ts...
+ mueu8_b_ts*rrs_b*w_b_ts...
);

kappaBS1_b_ts     = (1-tauw_b_ts)*rrs_b*w_b_ts;
kappaBS2_b_ts     = (1-tauw_b_ts)*rrs_b*w_b_ts;
kappaBS3_b_ts     = (1-tauw_b_ts)*rrs_b*w_b_ts;
kappaBS4_b_ts     = (1-tauw_b_ts)*rrs_b*w_b_ts;
kappaBS5_b_ts     = (1-tauw_b_ts)*rrs_b*w_b_ts;
kappaBS6_b_ts     = (1-tauw_b_ts)*rrs_b*w_b_ts;
kappaBS7_b_ts     = (1-tauw_b_ts)*rrs_b*w_b_ts;
kappaBS8_b_ts     = (1-tauw_b_ts)*rrs_b*w_b_ts;

kappaBL_b_ts      = (1-tauw_b_ts)*rrl_b*w_b_ts;

job_flow_b_ts = -(w_b_ts + ...
    (TS_b_ts*(k_b_ts/N_b_ts)^cp_b*(cp_b - 1))/CPI_b_ts);
if recruiting_cost_form == 0
    Sf_b_ts = job_flow_b_ts/(1-(1/R_w_ts)*(1-s_b));
    recruiting_resource_b_ts = Sf_b_ts*q_b_ts*V_b_ts;
else
    SfT_b_ts = job_flow_b_ts/(1-(1/R_w_ts)*(1-s_b/(1+chi_sector_T_b)));
    SfN_b_ts = job_flow_b_ts/(1-(1/R_w_ts)*(1-s_b/(1+chi_sector_N_b)));
    Sf_b_ts = recruiting_ss_share_b_guess*SfT_b_ts ...
        +(1-recruiting_ss_share_b_guess)*SfN_b_ts;
    recruiting_resource_b_ts = s_b*N_b_ts*( ...
        recruiting_ss_share_b_guess*SfT_b_ts/(1+chi_sector_T_b) ...
        +(1-recruiting_ss_share_b_guess)*SfN_b_ts/(1+chi_sector_N_b));
end

J_b_ss = tax_f2_b*(k_b_ts+omega_bb*Y_b_ss+NFA_b)/mue_b_ts*R_w_ts*(p_b_ts*(1-mue_b_ts-muuu_b_ts-mueu8_b_ts) + mueu8_b_ts);
PSI_b_ts = qY_b_ts*Y_b_ss - w_b_ts*N_b_ts - qI_b_ts*delta_b*k_b_ts - recruiting_resource_b_ts + k_b_ts - R_w_ts*k_b_ts + J_b_ss + nfa_spread_b_ss;

ae_b_ts = (k_b_ts+omega_bb*TS_b_ts*(k_b_ts^cp_b*N_b_ts^(1-cp_b))+NFA_b)/mue_b_ts;

if fix_benefit_index_ss
    next_benefit_b = [kappaBS2_b_ts kappaBS3_b_ts kappaBS4_b_ts kappaBS5_b_ts kappaBS6_b_ts kappaBS7_b_ts kappaBS8_b_ts];
else
    next_benefit_b = [kappaBS8_b_ts kappaBS7_b_ts kappaBS6_b_ts kappaBS5_b_ts kappaBS4_b_ts kappaBS3_b_ts kappaBS2_b_ts];
end
if fix_cohort_convention_ss
    cohort_probability_b = p_b_ts;
else
    cohort_probability_b = 1;
end
share7_b_ts  = (1/(ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b)))*(-kappaBS7_b_ts+tau_b_ts +((betta_b_ts*cohort_probability_b*lambdae_b_ts*p_b_ts/N_b_ts*mueu7_b_ts+betta_b_ts*(1-p_b_ts)*(next_benefit_b(7) + share8_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts)^(-sigmac)))^(-1/sigmac));
share6_b_ts  = (1/(ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b)))*(-kappaBS6_b_ts+tau_b_ts +((betta_b_ts*cohort_probability_b*lambdae_b_ts*p_b_ts/N_b_ts*mueu6_b_ts+betta_b_ts*(1-p_b_ts)*(next_benefit_b(6) + share7_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts)^(-sigmac)))^(-1/sigmac));
share5_b_ts  = (1/(ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b)))*(-kappaBS5_b_ts+tau_b_ts +((betta_b_ts*cohort_probability_b*lambdae_b_ts*p_b_ts/N_b_ts*mueu5_b_ts+betta_b_ts*(1-p_b_ts)*(next_benefit_b(5) + share6_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts)^(-sigmac)))^(-1/sigmac));
share4_b_ts  = (1/(ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b)))*(-kappaBS4_b_ts+tau_b_ts +((betta_b_ts*cohort_probability_b*lambdae_b_ts*p_b_ts/N_b_ts*mueu4_b_ts+betta_b_ts*(1-p_b_ts)*(next_benefit_b(4) + share5_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts)^(-sigmac)))^(-1/sigmac));
share3_b_ts  = (1/(ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b)))*(-kappaBS3_b_ts+tau_b_ts +((betta_b_ts*cohort_probability_b*lambdae_b_ts*p_b_ts/N_b_ts*mueu3_b_ts+betta_b_ts*(1-p_b_ts)*(next_benefit_b(3) + share4_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts)^(-sigmac)))^(-1/sigmac));
share2_b_ts  = (1/(ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b)))*(-kappaBS2_b_ts+tau_b_ts +((betta_b_ts*cohort_probability_b*lambdae_b_ts*p_b_ts/N_b_ts*mueu2_b_ts+betta_b_ts*(1-p_b_ts)*(next_benefit_b(2) + share3_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts)^(-sigmac)))^(-1/sigmac));
share1_b_ts  = (1/(ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b)))*(-kappaBS1_b_ts+tau_b_ts +((betta_b_ts*cohort_probability_b*lambdae_b_ts*p_b_ts/N_b_ts*mueu1_b_ts+betta_b_ts*(1-p_b_ts)*(next_benefit_b(1) + share2_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts)^(-sigmac)))^(-1/sigmac));

Rest1_b_ts = (1         -share1_b_ts);
Rest2_b_ts = (Rest1_b_ts-share2_b_ts);
Rest3_b_ts = (Rest2_b_ts-share3_b_ts);
Rest4_b_ts = (Rest3_b_ts-share4_b_ts);
Rest5_b_ts = (Rest4_b_ts-share5_b_ts);
Rest6_b_ts = (Rest5_b_ts-share6_b_ts);
Rest7_b_ts = (Rest6_b_ts-share7_b_ts);



Ce_b_ts   = (1-tauw_b_ts)*w_b_ts + PSI_b_ts/N_b_ts + (1-s_b*(1-tax_f_b)*(1-p_b_ts))*ae_b_ts*R_w_ts - ae_b_ts - tau_b_ts ...
+ p_b_ts*(mueu1_b_ts*Rest1_b_ts + mueu2_b_ts*Rest2_b_ts + mueu3_b_ts*Rest3_b_ts  + mueu4_b_ts*Rest4_b_ts + mueu5_b_ts*Rest5_b_ts  + mueu6_b_ts*Rest6_b_ts + mueu7_b_ts*Rest7_b_ts)*ae_b_ts*(1-tax_f_b-tax_f2_b)*R_w_ts/mue_b_ts;

Ceu1_b_ts  = kappaBS1_b_ts  + share1_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts; 
Ceu2_b_ts  = kappaBS2_b_ts  + share2_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts; 
Ceu3_b_ts  = kappaBS3_b_ts  + share3_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts; 
Ceu4_b_ts  = kappaBS4_b_ts  + share4_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts;
Ceu5_b_ts  = kappaBS5_b_ts  + share5_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts;
Ceu6_b_ts  = kappaBS6_b_ts  + share6_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts;
Ceu7_b_ts  = kappaBS7_b_ts  + share7_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts;
Ceu8_b_ts  = kappaBS8_b_ts  + share8_b_ts*ae_b_ts*R_w_ts*(1-tax_f_b-tax_f2_b) - tau_b_ts;

Cuu_b_ts   = kappaBL_b_ts - tau_b_ts;

C_b_ts = Ce_b_ts*N_b_ts + mueu1_b_ts*Ceu1_b_ts+mueu2_b_ts*Ceu2_b_ts+mueu3_b_ts*Ceu3_b_ts+mueu4_b_ts*Ceu4_b_ts...
    +mueu5_b_ts*Ceu5_b_ts+mueu6_b_ts*Ceu6_b_ts+mueu7_b_ts*Ceu7_b_ts+mueu8_b_ts*Ceu8_b_ts...
    +muuu_b_ts*Cuu_b_ts;

lambdaeu1_b_ts =   Ceu1_b_ts^(-sigmac); 
lambdaeu2_b_ts =   Ceu2_b_ts^(-sigmac); 
lambdaeu3_b_ts =   Ceu3_b_ts^(-sigmac); 
lambdaeu4_b_ts =   Ceu4_b_ts^(-sigmac);
lambdaeu5_b_ts =   Ceu5_b_ts^(-sigmac);
lambdaeu6_b_ts =   Ceu6_b_ts^(-sigmac);
lambdaeu7_b_ts =   Ceu7_b_ts^(-sigmac);
lambdaeu8_b_ts =   Ceu8_b_ts^(-sigmac);

lambdauu_b_ts  =   Cuu_b_ts^(-sigmac); 

if fix_asset_timing_ss
    returned_discount_b = betta_b_ts.^(1:7);
else
    returned_discount_b = betta_b_ts.^(0:6);
end
if fix_telescope_ss
    continuation_denominator_b = [lambdaeu1_b_ts lambdaeu2_b_ts lambdaeu3_b_ts lambdaeu4_b_ts lambdaeu5_b_ts lambdaeu6_b_ts lambdaeu7_b_ts];
else
    continuation_denominator_b = repmat(lambdae_b_ts, 1, 7);
end
DRe_b_ts = (betta_b_ts*((1-s_b*(1-tax_f_b)*(1-p_b_ts))*lambdae_b_ts/lambdae_b_ts*CPI_b_ts/CPI_b_ts... 
+ returned_discount_b(1)*p_b_ts/N_b_ts*(mueu1_b_ts*Rest1_b_ts*(1-tax_f_b-tax_f2_b)*CPI_b_ts/CPI_b_ts)...
+ returned_discount_b(2)*p_b_ts/N_b_ts*(mueu2_b_ts*Rest2_b_ts*(1-tax_f_b-tax_f2_b)*CPI_b_ts/CPI_b_ts)...
+ returned_discount_b(3)*p_b_ts/N_b_ts*(mueu3_b_ts*Rest3_b_ts*(1-tax_f_b-tax_f2_b)*CPI_b_ts/CPI_b_ts)...
+ returned_discount_b(4)*p_b_ts/N_b_ts*(mueu4_b_ts*Rest4_b_ts*(1-tax_f_b-tax_f2_b)*CPI_b_ts/CPI_b_ts)...
+ returned_discount_b(5)*p_b_ts/N_b_ts*(mueu5_b_ts*Rest5_b_ts*(1-tax_f_b-tax_f2_b)*CPI_b_ts/CPI_b_ts)...
+ returned_discount_b(6)*p_b_ts/N_b_ts*(mueu6_b_ts*Rest6_b_ts*(1-tax_f_b-tax_f2_b)*CPI_b_ts/CPI_b_ts)...
+ returned_discount_b(7)*p_b_ts/N_b_ts*(mueu7_b_ts*Rest7_b_ts*(1-tax_f_b-tax_f2_b)*CPI_b_ts/CPI_b_ts)...
+ s_b*(1-p_b_ts)  *lambdaeu1_b_ts/lambdae_b_ts*(CPI_b_ts/CPI_b_ts*share1_b_ts*(1-tax_f_b-tax_f2_b)... 
+ betta_b_ts*(1-p_b_ts)*lambdaeu2_b_ts/continuation_denominator_b(1)*(CPI_b_ts/CPI_b_ts*share2_b_ts*(1-tax_f_b-tax_f2_b)...
+ betta_b_ts*(1-p_b_ts)*lambdaeu3_b_ts/continuation_denominator_b(2)*(CPI_b_ts/CPI_b_ts*share3_b_ts*(1-tax_f_b-tax_f2_b)...
+ betta_b_ts*(1-p_b_ts)*lambdaeu4_b_ts/continuation_denominator_b(3)*(CPI_b_ts/CPI_b_ts*share4_b_ts*(1-tax_f_b-tax_f2_b)...
+ betta_b_ts*(1-p_b_ts)*lambdaeu5_b_ts/continuation_denominator_b(4)*(CPI_b_ts/CPI_b_ts*share5_b_ts*(1-tax_f_b-tax_f2_b)...
+ betta_b_ts*(1-p_b_ts)*lambdaeu6_b_ts/continuation_denominator_b(5)*(CPI_b_ts/CPI_b_ts*share6_b_ts*(1-tax_f_b-tax_f2_b)...
+ betta_b_ts*(1-p_b_ts)*lambdaeu7_b_ts/continuation_denominator_b(6)*(CPI_b_ts/CPI_b_ts*share7_b_ts*(1-tax_f_b-tax_f2_b)...
+ betta_b_ts*(1-p_b_ts)*lambdaeu8_b_ts/continuation_denominator_b(7)*(CPI_b_ts/CPI_b_ts*share8_b_ts*(1-tax_f_b-tax_f2_b)...
))))))))));

Ue_b_ts   = Ce_b_ts^(1-sigmac)/(1-sigmac);
Ueu1_b_ts = Ceu1_b_ts^(1-sigmac)/(1-sigmac);
Ueu2_b_ts = Ceu2_b_ts^(1-sigmac)/(1-sigmac);
Ueu3_b_ts = Ceu3_b_ts^(1-sigmac)/(1-sigmac);
Ueu4_b_ts = Ceu4_b_ts^(1-sigmac)/(1-sigmac);
Ueu5_b_ts = Ceu5_b_ts^(1-sigmac)/(1-sigmac);
Ueu6_b_ts = Ceu6_b_ts^(1-sigmac)/(1-sigmac);
Ueu7_b_ts = Ceu7_b_ts^(1-sigmac)/(1-sigmac);
Ueu8_b_ts = Ceu8_b_ts^(1-sigmac)/(1-sigmac);

Uuu_b_ts  = Cuu_b_ts^(1-sigmac)/(1-sigmac);

We_b_ts   =((betta_b_ts*p_b_ts - betta_b_ts + 1)*(Ce_b_ts*lambdae_b_ts - Ue_b_ts + ae_b_ts*lambdae_b_ts + lambdae_b_ts*tau_b_ts + lambdae_b_ts*w_b_ts*(tauw_b_ts - 1) + betta_b_ts*s_b*(Ueu1_b_ts - betta_b_ts*(Ueu2_b_ts - betta_b_ts*(Ueu3_b_ts - betta_b_ts*(Ueu4_b_ts - betta_b_ts*(Ueu5_b_ts - betta_b_ts*(Ueu6_b_ts - betta_b_ts*(p_b_ts - 1)*(Ueu7_b_ts - (betta_b_ts*(p_b_ts - 1)*(Ueu8_b_ts - Ueu8_b_ts*betta_b_ts + Uuu_b_ts*betta_b_ts + Ueu8_b_ts*betta_b_ts*p_b_ts - Uuu_b_ts*betta_b_ts*p_b_ts))/(betta_b_ts*p_b_ts - betta_b_ts + 1)))*(p_b_ts - 1))*(p_b_ts - 1))*(p_b_ts - 1))*(p_b_ts - 1))*(p_b_ts - 1))*(p_b_ts - 1) -R_w_ts*ae_b_ts*betta_b_ts*lambdae_b_ts*(p_b_ts*(1-tax_f_b)*s_b - s_b*(1-tax_f_b) + 1)))/((betta_b_ts - 1)*(betta_b_ts*p_b_ts - betta_b_ts + betta_b_ts*s_b - betta_b_ts*p_b_ts*s_b + 1));

Wuu_b_ts  = (Uuu_b_ts + betta_b_ts*p_b_ts*We_b_ts)/(1-betta_b_ts*(1-p_b_ts));
 Weu8_b_ts = Ueu8_b_ts + betta_b_ts*(1-p_b_ts)*Wuu_b_ts + betta_b_ts*p_b_ts*We_b_ts;
 Weu7_b_ts = Ueu7_b_ts + betta_b_ts*(1-p_b_ts)*Weu8_b_ts + betta_b_ts*p_b_ts*We_b_ts;
 Weu6_b_ts = Ueu6_b_ts + betta_b_ts*(1-p_b_ts)*Weu7_b_ts + betta_b_ts*p_b_ts*We_b_ts;
 Weu5_b_ts = Ueu5_b_ts + betta_b_ts*(1-p_b_ts)*Weu6_b_ts + betta_b_ts*p_b_ts*We_b_ts;
 Weu4_b_ts = Ueu4_b_ts + betta_b_ts*(1-p_b_ts)*Weu5_b_ts + betta_b_ts*p_b_ts*We_b_ts;
 Weu3_b_ts = Ueu3_b_ts + betta_b_ts*(1-p_b_ts)*Weu4_b_ts + betta_b_ts*p_b_ts*We_b_ts;
 Weu2_b_ts = Ueu2_b_ts + betta_b_ts*(1-p_b_ts)*Weu3_b_ts + betta_b_ts*p_b_ts*We_b_ts;
 Weu1_b_ts = Ueu1_b_ts + betta_b_ts*(1-p_b_ts)*Weu2_b_ts + betta_b_ts*p_b_ts*We_b_ts;
unemployment_mass_b = mueu1_b_ts+mueu2_b_ts+mueu3_b_ts+mueu4_b_ts ...
    +mueu5_b_ts+mueu6_b_ts+mueu7_b_ts+mueu8_b_ts+muuu_b_ts;
unemployed_value_numerator_b = mueu1_b_ts*Weu1_b_ts ...
    +mueu2_b_ts*Weu2_b_ts+mueu3_b_ts*Weu3_b_ts ...
    +mueu4_b_ts*Weu4_b_ts+mueu5_b_ts*Weu5_b_ts ...
    +mueu6_b_ts*Weu6_b_ts+mueu7_b_ts*Weu7_b_ts ...
    +mueu8_b_ts*Weu8_b_ts+muuu_b_ts*Wuu_b_ts;
labor_force_mass_b = N_b_ts+unemployment_mass_b;
Wout_all_unemployed_b_ts = unemployed_value_numerator_b/unemployment_mass_b;
Wout_labor_force_weighted_b_ts = ...
    (N_b_ts*Weu1_b_ts+unemployed_value_numerator_b)/labor_force_mass_b;
Wout_convex_stu1_ltu_b_ts = ...
    (1-convex_ltu_weight_ss)*Weu1_b_ts+convex_ltu_weight_ss*Wuu_b_ts;
% Backward-compatible diagnostic aliases. The active selector is country-specific.
Wout_unemployed_b_ts = Wout_all_unemployed_b_ts;
Wout_union_b_ts = Wout_labor_force_weighted_b_ts;
% Legacy scalar blend: bargaining_continuation_weight_ss*Wout_unemployed_b_ts.
if bargaining_mode_b_ss == 1
    Wout_b_ts = bargaining_continuation_weight_b_ss*Wout_all_unemployed_b_ts ...
        +(1-bargaining_continuation_weight_b_ss)*Wout_labor_force_weighted_b_ts;
elseif bargaining_mode_b_ss == 2
    Wout_b_ts = Wout_labor_force_weighted_b_ts;
elseif bargaining_mode_b_ss == 3
    Wout_b_ts = Wout_convex_stu1_ltu_b_ts;
else
    Wout_b_ts = Weu1_b_ts;
end
She_b_ts = We_b_ts-Wout_b_ts;
labor_force_mass_gap_b = labor_force_mass_b-1;
labor_force_weighted_identity_gap_b = ...
    labor_force_mass_b*Wout_labor_force_weighted_b_ts ...
    -(N_b_ts*Weu1_b_ts+unemployment_mass_b*Wout_all_unemployed_b_ts);
selected_surplus_gap_b = She_b_ts-(We_b_ts-Wout_b_ts);



%% Solution

residual(1) = 1/R_w_ts-DRe_a_ts;
residual(2) =  1-share1_a_ts-share2_a_ts-share3_a_ts-share4_a_ts-share5_a_ts-share6_a_ts-share7_a_ts-share8_a_ts;
residual(3) =    lambdae_a_ts- Ce_a_ts^(-sigmac);
residual(4) =   She_a_ts- xoui_a/(1-xoui_a)*(1-tauw_a_ts)*lambdae_a_ts*Sf_a_ts;
residual(5) =  1/R_w_ts-DRe_b_ts;
residual(6) =  1-share1_b_ts-share2_b_ts-share3_b_ts-share4_b_ts-share5_b_ts-share6_b_ts-share7_b_ts-share8_b_ts;
residual(7) =  lambdae_b_ts- Ce_b_ts^(-sigmac);
residual(8) =     She_b_ts- xoui_b/(1-xoui_b)*(1-tauw_b_ts)*lambdae_b_ts*Sf_b_ts;

state = struct('NFA_a_ts',NFA_a_ts,'NFA_b_ts',NFA_b, ...
    'Y_a_ss',Y_a_ss,'Y_b_ss',Y_b_ss,'betta_a',betta_a, ...
    'betta_b_ts',betta_b_ts,'DRe_a_ts',DRe_a_ts,'DRe_b_ts',DRe_b_ts, ...
    'bargaining_mode',bargaining_mode_ss, ...
    'bargaining_continuation_weight',bargaining_continuation_weight_ss, ...
    'bargaining_mode_a',bargaining_mode_a_ss, ...
    'bargaining_mode_b',bargaining_mode_b_ss, ...
    'bargaining_continuation_weight_a',bargaining_continuation_weight_a_ss, ...
    'bargaining_continuation_weight_b',bargaining_continuation_weight_b_ss, ...
    'convex_ltu_weight',convex_ltu_weight_ss, ...
    'Wout_stu1_a_ts',Weu1_a_ts, ...
    'Wout_all_unemployed_a_ts',Wout_all_unemployed_a_ts, ...
    'Wout_labor_force_weighted_a_ts',Wout_labor_force_weighted_a_ts, ...
    'Wout_convex_stu1_ltu_a_ts',Wout_convex_stu1_ltu_a_ts, ...
    'labor_force_mass_a',labor_force_mass_a, ...
    'labor_force_mass_gap_a',labor_force_mass_gap_a, ...
    'labor_force_weighted_identity_gap_a',labor_force_weighted_identity_gap_a, ...
    'selected_surplus_gap_a',selected_surplus_gap_a, ...
    'Wout_stu1_b_ts',Weu1_b_ts, ...
    'Wout_all_unemployed_b_ts',Wout_all_unemployed_b_ts, ...
    'Wout_labor_force_weighted_b_ts',Wout_labor_force_weighted_b_ts, ...
    'Wout_convex_stu1_ltu_b_ts',Wout_convex_stu1_ltu_b_ts, ...
    'labor_force_mass_b',labor_force_mass_b, ...
    'labor_force_mass_gap_b',labor_force_mass_gap_b, ...
    'labor_force_weighted_identity_gap_b',labor_force_weighted_identity_gap_b, ...
    'selected_surplus_gap_b',selected_surplus_gap_b, ...
    'Wout_a_ts',Wout_a_ts, ...
    'Wout_b_ts',Wout_b_ts);
end
