//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%               International linkages                            %%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

@#ifndef nfa_sgu_value
    @#define nfa_sgu_value = 0
@#endif

@#for land in country

// modified, this was the CPI in the original file
[name = 'TPI']
TPI_@{land}_t = (hb1_@{land}*pH_t^(1-eta_c) + (1-hb1_@{land})*pF_t^(1-eta_c) )^(1/(1-eta_c));  // Eq 193 + 199
CPI_@{land}_t = (alpha_@{land}_t*TPI_@{land}_t^(1-phi_t) + (1-alpha_@{land}_t)*pN_@{land}_t^(1-phi_t))^(1/(1-phi_t));  // Eq 193 + 199
IPI_@{land}_t = (alpha_I_@{land}*TPI_@{land}_t^(1-phi_t) + (1-alpha_I_@{land})*pN_@{land}_t^(1-phi_t))^(1/(1-phi_t));
qI_@{land}_t = IPI_@{land}_t/CPI_@{land}_t;
qN_@{land}_t = pN_@{land}_t/CPI_@{land}_t;

[name = 'cH/cF']
 cH_@{land}_t      = hb1_@{land}/(1-hb1_@{land})*(pF_t/pH_t)^eta_c*cF_@{land}_t; // Eq 194 + 200
 iH_@{land}_t      = hb1_@{land}/(1-hb1_@{land})*(pF_t/pH_t)^eta_c*iF_@{land}_t; // Eq 195 + 201

// modified, these equations enter due to T/NT structure
[name = 'cT/cN']
 cT_@{land}_t=((hb1_@{land})^(1/eta_c)*cH_@{land}_t ^((eta_c-1)/eta_c)+(1-hb1_@{land})^(1/eta_c)*cF_@{land}_t^((eta_c-1)/eta_c))^(eta_c/(eta_c-1)); //383
// Take equations from cacciatore et al. JEDC instead (definitely correct!)
 cT_@{land}_t=alpha_@{land}_t*(TPI_@{land}_t/CPI_@{land}_t)^(-phi_t)*C_@{land}_t;
 cN_@{land}_t=(1-alpha_@{land}_t)*(pN_@{land}_t/CPI_@{land}_t)^(-phi_t)*C_@{land}_t;


[name = 'C_@{land}_t, market consmption, composite of T/NT']

//  C_@{land}_t=((alpha_@{land}_t)^(1/phi_t)*cT_@{land}_t ^((phi_t-1)/phi_t)+(1-alpha_@{land}_t)^(1/phi_t)*cN_@{land}_t^((phi_t-1)/phi_t))^(phi_t/(phi_t-1)); //385
  iT_@{land}_t=alpha_I_@{land}*(TPI_@{land}_t/IPI_@{land}_t)^(-phi_t)*I_@{land}_t;
  iN_@{land}_t=(1-alpha_I_@{land})*(pN_@{land}_t/IPI_@{land}_t)^(-phi_t)*I_@{land}_t;
  iT_@{land}_t=((hb1_@{land})^(1/eta_c)*iH_@{land}_t ^((eta_c-1)/eta_c)+(1-hb1_@{land})^(1/eta_c)*iF_@{land}_t^((eta_c-1)/eta_c))^(eta_c/(eta_c-1)); //384
// replaced by those above
//  CPI_@{land}_t*I_@{land}_t = pH_t*iH_@{land}_t + pF_t*iF_@{land}_t; // Eq 197 + 203
// CPI_@{land}_t*C_@{land}_t = pH_t*cH_@{land}_t + pF_t*cF_@{land}_t; // Eq 197 + 203
CA_@{land}_t= NFA_@{land}_t -NFA_@{land}_t(-1); // Eq 198 + 204

@#endfor

[name = 'NFA']
// Optional SGU stationarity closure. The default zero preserves the maintained
// incomplete-insurance case; the insurance comparison sets the same positive
// coefficient and inherited-NFA normalization as complete insurance.
NFA_a_t = Rf_a_t*NFA_a_t(-1) + pH_t/CPI_a_t*(1-size_a)/size_a*(cH_b_t+iH_b_t) - pF_t/CPI_a_t*(cF_a_t+iF_a_t);   // EQ 205
Rf_a_t = R_w_t(-1)*exp(-@{nfa_sgu_value}*(NFA_a_t(-1)-NFA_a_ts));
nfa_spread_a_t = (Rf_a_t-R_w_t(-1))*NFA_a_t(-1);
nfa_spread_b_t = -size_a/(1-size_a)*CPI_a_t/CPI_b_t*nfa_spread_a_t;


// Sector producer prices: the Foreign tradable good is the numeraire.
pF_t = 1;
qT_a_t = pH_t/CPI_a_t;
qT_b_t = pF_t/CPI_b_t;

// Independent sectoral goods markets. DG is CPI-real expenditure, so
// division by the sector's CPI-relative price converts expenditure into
// physical quantity. The tradable markets are Walras diagnostics, not
// equilibrium equations, under the protected frozen-cohort/NFA closure.
// Diagnostic Home tradable residual (supply minus demand):
// goods_T_a = YT_a_t-(cH_a_t+iH_a_t+(1-size_a)/size_a*(cH_b_t+iH_b_t)
//     +RCT_a_t+FCT_a+alpha_G_T_a*DG_a_t/qT_a_t).
YN_a_t = cN_a_t+iN_a_t+RCN_a_t+FCN_a+(1-alpha_G_T_a)*DG_a_t/qN_a_t;
// Diagnostic Foreign tradable residual (supply minus demand):
// goods_T_b = YT_b_t-(cF_b_t+iF_b_t+size_a/(1-size_a)*(cF_a_t+iF_a_t)
//     +RCT_b_t+FCT_b+alpha_G_T_b*DG_b_t/qT_b_t).
YN_b_t = cN_b_t+iN_b_t+RCN_b_t+FCN_b+(1-alpha_G_T_b)*DG_b_t/qN_b_t;

[name = 'Tradeable/Nontradeable']

trdb_vs_nontrdb_a_t=pH_t*(cH_a_t+iH_a_t + (1-size_a)/size_a*(cH_b_t + iH_b_t))/(pN_a_t*(cN_a_t+iN_a_t));
trdb_vs_nontrdb_b_t=pF_t*(cF_b_t+iF_b_t + (size_a)/(1-size_a)*(cF_a_t + iF_a_t))/(pN_b_t*(cN_b_t+iN_b_t));


// Separate producer-price and CPI-relative-price reporting objects.
rel_pT_t = pH_t/pF_t;
rer_t = rel_pT_t; // Legacy alias; this is not the CPI real exchange rate.
rer_cpi_t = CPI_a_t/CPI_b_t;


// NFA also include investment in exports/imports, Eq 208
CPI_a_t*size_a*NFA_a_t + CPI_b_t*(1-size_a)*NFA_b_t  = 0;

// Trade volumes and values. Legacy EX/IM series are explicit value aliases.
EXVOL_a_t = (1-size_a)/size_a*(cH_b_t+iH_b_t);
EXVAL_a_t = qT_a_t*EXVOL_a_t;
IMVOL_a_t = cF_a_t+iF_a_t;
IMVAL_a_t = pF_t/CPI_a_t*IMVOL_a_t;
EX_a_t = EXVAL_a_t;
IM_a_t = IMVAL_a_t;
NX_a_t = EXVAL_a_t-IMVAL_a_t;

EXVOL_b_t = size_a/(1-size_a)*(cF_a_t+iF_a_t);
EXVAL_b_t = qT_b_t*EXVOL_b_t;
IMVOL_b_t = cH_b_t+iH_b_t;
IMVAL_b_t = pH_t/CPI_b_t*IMVOL_b_t;
EX_b_t = EXVAL_b_t;
IM_b_t = IMVAL_b_t;
NX_b_t = EXVAL_b_t-IMVAL_b_t;


GNP_a_t = qT_a_t*YT_a_t+qN_a_t*YN_a_t+(Rf_a_t-1)*NFA_a_t(-1);
GNP_b_t = qT_b_t*YT_b_t+qN_b_t*YN_b_t+(R_w_t(-1)-1)*NFA_b_t(-1)+nfa_spread_b_t;
