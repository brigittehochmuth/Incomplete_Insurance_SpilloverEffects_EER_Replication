//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//%%%%%       Corrected Complete-Insurance International Linkages       %%%%%
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

@#for land in country

[name = 'TPI']
TPI_@{land}_t = (hb1_@{land}*pH_t^(1-eta_c) + (1-hb1_@{land})*pF_t^(1-eta_c) )^(1/(1-eta_c));
CPI_@{land}_t = (alpha_@{land}_t*TPI_@{land}_t^(1-phi_t) + (1-alpha_@{land}_t)*pN_@{land}_t^(1-phi_t))^(1/(1-phi_t));
IPI_@{land}_t = (alpha_I_@{land}*TPI_@{land}_t^(1-phi_t) + (1-alpha_I_@{land})*pN_@{land}_t^(1-phi_t))^(1/(1-phi_t));
qI_@{land}_t = IPI_@{land}_t/CPI_@{land}_t;
qN_@{land}_t = pN_@{land}_t/CPI_@{land}_t;

[name = 'cH/cF']
cH_@{land}_t = hb1_@{land}/(1-hb1_@{land})*(pF_t/pH_t)^eta_c*cF_@{land}_t;
iH_@{land}_t = hb1_@{land}/(1-hb1_@{land})*(pF_t/pH_t)^eta_c*iF_@{land}_t;

[name = 'cT/cN']
cT_@{land}_t=((hb1_@{land})^(1/eta_c)*cH_@{land}_t^((eta_c-1)/eta_c)+(1-hb1_@{land})^(1/eta_c)*cF_@{land}_t^((eta_c-1)/eta_c))^(eta_c/(eta_c-1));
cT_@{land}_t=alpha_@{land}_t*(TPI_@{land}_t/CPI_@{land}_t)^(-phi_t)*C_@{land}_t;
cN_@{land}_t=(1-alpha_@{land}_t)*(pN_@{land}_t/CPI_@{land}_t)^(-phi_t)*C_@{land}_t;

[name = 'C_@{land}_t, market consmption, composite of T/NT']
iT_@{land}_t=alpha_I_@{land}*(TPI_@{land}_t/IPI_@{land}_t)^(-phi_t)*I_@{land}_t;
iN_@{land}_t=(1-alpha_I_@{land})*(pN_@{land}_t/IPI_@{land}_t)^(-phi_t)*I_@{land}_t;
iT_@{land}_t=((hb1_@{land})^(1/eta_c)*iH_@{land}_t^((eta_c-1)/eta_c)+(1-hb1_@{land})^(1/eta_c)*iF_@{land}_t^((eta_c-1)/eta_c))^(eta_c/(eta_c-1));
CA_@{land}_t = NFA_@{land}_t-NFA_@{land}_t(-1);

@#endfor

[name = 'NFA']
// Preserve the original complete-insurance SGU stationarity device while
// applying it to inherited NFA under the maintained return timing.
NFA_a_t = Rf_a_t*NFA_a_t(-1) + pH_t/CPI_a_t*(1-size_a)/size_a*(cH_b_t+iH_b_t) - pF_t/CPI_a_t*(cF_a_t+iF_a_t);
Rf_a_t = R_w_t(-1)*exp(-@{phi_SGU_value}*(NFA_a_t(-1)-NFA_a_ts));
nfa_spread_a_t = (Rf_a_t-R_w_t(-1))*NFA_a_t(-1);
nfa_spread_b_t = -size_a/(1-size_a)*CPI_a_t/CPI_b_t*nfa_spread_a_t;

pF_t = 1;
qT_a_t = pH_t/CPI_a_t;
qT_b_t = pF_t/CPI_b_t;

// The maintained Walras closure retains both nontradable market equations.
YN_a_t = cN_a_t+iN_a_t+RCN_a_t+FCN_a+(1-alpha_G_T_a)*DG_a_t/qN_a_t;
YN_b_t = cN_b_t+iN_b_t+RCN_b_t+FCN_b+(1-alpha_G_T_b)*DG_b_t/qN_b_t;

[name = 'Tradeable/Nontradeable']
trdb_vs_nontrdb_a_t=pH_t*(cH_a_t+iH_a_t + (1-size_a)/size_a*(cH_b_t + iH_b_t))/(pN_a_t*(cN_a_t+iN_a_t));
trdb_vs_nontrdb_b_t=pF_t*(cF_b_t+iF_b_t + size_a/(1-size_a)*(cF_a_t + iF_a_t))/(pN_b_t*(cN_b_t+iN_b_t));

rel_pT_t = pH_t/pF_t;
rer_t = rel_pT_t;
rer_cpi_t = CPI_a_t/CPI_b_t;

CPI_a_t*size_a*NFA_a_t + CPI_b_t*(1-size_a)*NFA_b_t = 0;

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
