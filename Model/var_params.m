// Endogenous variables
var
TPI_a_t,  % eq
TPI_b_t, % eq
GNP_a_t,  % eq
GNP_b_t, % eq
MPL_a_t,  % eq
MPL_b_t, % eq
MPK_a_t,  % eq
MPK_b_t, % eq
cT_a_t, % eq
cN_a_t, % eq
cT_b_t, % eq
cN_b_t,% eq
EX_b_t,
IM_b_t,
NX_b_t,
Rf_a_t,
nfa_spread_a_t,
nfa_spread_b_t,
@#for land in country  
ae_@{land}_t, 
dissavings_@{land}_t,
trdb_vs_nontrdb_@{land}_t,
iT_@{land}_t,
iN_@{land}_t,
IPI_@{land}_t,
b_@{land}_t,
C_@{land}_t,              
Ce_@{land}_t,
Welf_@{land}_t,
Welfe_@{land}_t,              
@#for state in g      
Ceu@{state}_@{land}_t,
@#endfor         
Cuu_@{land}_t,       
DRe_@{land}_t,
lambdae_@{land}_t,
@#for state in g
Welfeu@{state}_@{land}_t,
lambdaeu@{state}_@{land}_t,
@#endfor         
lambdauu_@{land}_t,
Welfuu_@{land}_t,
M_@{land}_t,              
mue_@{land}_t,
@#for state in g
mueu@{state}_@{land}_t,          
@#endfor  
muuu_@{land}_t,
pN_@{land}_t,
qY_@{land}_t,
qI_@{land}_t,
qT_@{land}_t,
qN_@{land}_t,
PY_@{land}_t,
N_@{land}_t,
NT_@{land}_t,
NN_@{land}_t,
//u_@{land}_t,                    
PSI_@{land}_t,
CV_@{land}_t,
J_@{land}_t,
p_@{land}_t,              
q_@{land}_t,              
R_w_t,              
Sf_@{land}_t,
She_@{land}_t,         
wnash_@{land}_t,
tauw_@{land}_t,           
Ue_@{land}_t,
@#for state in g      
Ueu@{state}_@{land}_t,       
@#endfor         
Uuu_@{land}_t,
V_@{land}_t,              
VT_@{land}_t,
VN_@{land}_t,
w_@{land}_t,         
Y_@{land}_t,
YT_@{land}_t,
YN_@{land}_t,
KTuse_@{land}_t,
KNuse_@{land}_t,
MPLT_@{land}_t,
MPLN_@{land}_t,
MPKT_@{land}_t,
MPKN_@{land}_t,
RK_@{land}_t,
SfT_@{land}_t,
SfN_@{land}_t,
RCT_@{land}_t,
RCN_@{land}_t,
EXVOL_@{land}_t,
EXVAL_@{land}_t,
IMVOL_@{land}_t,
IMVAL_@{land}_t,
We_@{land}_t, 
@#for state in g
Weu@{state}_@{land}_t,
@#endfor     
Wuu_@{land}_t,
kappaBL_@{land}_t,       
@#for state in g
kappaBS@{state}_@{land}_t,
@#endfor 
@#for state in j
share@{state}_@{land}_t,
@#endfor 
@#for state in m
Rest@{state}_@{land}_t,
@#endfor 

Pi_@{land}_t,
k_@{land}_t, 
I_@{land}_t,
iH_@{land}_t,
iF_@{land}_t,

CPI_@{land}_t,
cH_@{land}_t, 
cF_@{land}_t,
NFA_@{land}_t,
CA_@{land}_t,
tau_@{land}_t,
TQ_@{land}_t,     
@#endfor

pH_t, 
pF_t,
rer_t,
rel_pT_t,
rer_cpi_t,

EX_a_t,
IM_a_t,
NX_a_t

;         

// Exogenous variables
var  

@#for land in country  
TS_@{land}_t, 
DG_@{land}_t
@#endfor
;

      
varexo 
@#for land in country 
epsiA_@{land}, 
epsiG_@{land},    
@#endfor
HH4,
sep_timing_a,
sep_timing_b;

parameters 
Check1,
Check2,
Check3,
Check4,
recruiting_cost_form,
psi_nfa,
nfa_anchor_a,
chiV,
sub_e,
betta_a,
betta_b,
sigmac,
R_w_ts,
size_a,
alpha_a_t,
alpha_b_t,
eta_c,
phi_t,
omega_ba,
omega_bb,
EX_a_ts,
IM_a_ts,
NX_a_ts,
EX_b_ts,
IM_b_ts,
NX_b_ts,
MPL_a_ts,  % eq
MPL_b_ts, % eq
MPK_a_ts,  % eq
MPK_b_ts, % eq
TPI_a_ts,  % eq
TPI_b_ts, % eq
GNP_a_ts,  % eq
GNP_b_ts, % eq
cT_a_ts, % eq
cN_a_ts, % eq
cT_b_ts, % eq
cN_b_ts,% eq
@#for land in country 
kappaw_@{land},
gammaw_@{land},
alpha_I_@{land},
chi_sector_T_@{land},
chi_sector_N_@{land},
alpha_G_T_@{land},
sT_@{land}_ts,
FCT_@{land},
FCN_@{land},
TQ_@{land}_ts,
qY_@{land}_ts,
qI_@{land}_ts,
qT_@{land}_ts,
qN_@{land}_ts,
PY_@{land}_ts,
pN_@{land}_ts,
iT_@{land}_ts,
iN_@{land}_ts,
IPI_@{land}_ts,
dissavings_@{land}_ts,
iac_@{land},  
trdb_vs_nontrdb_@{land}_ts,
CPI_@{land}_ts,
hb1_@{land},
FC_@{land},
alphaa_@{land},        
B0_@{land},            
gamman_@{land},        
kappae_@{land},    
kappav_@{land},    
kappavT_@{land},
kappavN_@{land},
N_@{land}_ts,
NT_@{land}_ts,
NN_@{land}_ts,
u_@{land}_ts,                    
p_@{land}_ts,            
q_@{land}_ts,            
rhoA_@{land},      
rhoG_@{land},      
rhoto_@{land},         
rrs_@{land},
rrl_@{land},            
s_@{land},             
xi_b_@{land},
xoui_@{land},
tau_@{land}_ts,  
ae_@{land}_ts,         
b_@{land}_ts,
C_@{land}_ts,   
Welf_@{land}_ts,              
Ce_@{land}_ts,
Welfe_@{land}_ts,              
@#for state in g
Ceu@{state}_@{land}_ts,
@#endfor         
Cuu_@{land}_ts,       
DRe_@{land}_ts,
lambdae_@{land}_ts, 
@#for state in g
lambdaeu@{state}_@{land}_ts,
Welfeu@{state}_@{land}_ts,
@#endfor    
Welfuu_@{land}_ts,
lambdauu_@{land}_ts,
M_@{land}_ts,              
mue_@{land}_ts,
@#for state in g
mueu@{state}_@{land}_ts,
@#endfor         
muuu_@{land}_ts,       
PSI_@{land}_ts,
CV_@{land}_ts,
Sf_@{land}_ts,
She_@{land}_ts,         
tauw_@{land}_ts,           
Ue_@{land}_ts, 
@#for state in g
Ueu@{state}_@{land}_ts, 
@#endfor            
Uuu_@{land}_ts,
V_@{land}_ts,              
VT_@{land}_ts,
VN_@{land}_ts,
w_@{land}_ts,         
Y_@{land}_ts,
YT_@{land}_ts,
YN_@{land}_ts,
KTuse_@{land}_ts,
KNuse_@{land}_ts,
MPLT_@{land}_ts,
MPLN_@{land}_ts,
MPKT_@{land}_ts,
MPKN_@{land}_ts,
RK_@{land}_ts,
SfT_@{land}_ts,
SfN_@{land}_ts,
RCT_@{land}_ts,
RCN_@{land}_ts,
EXVOL_@{land}_ts,
EXVAL_@{land}_ts,
IMVOL_@{land}_ts,
IMVAL_@{land}_ts,
We_@{land}_ts, 
@#for state in g
Weu@{state}_@{land}_ts,
@#endfor         
Wuu_@{land}_ts,
TS_@{land}_ts, 
DG_@{land}_ts,
@#for state in j
share@{state}_@{land}_ts,
@#endfor   
@#for state in m
Rest@{state}_@{land}_ts,
@#endfor 

k_@{land}_ts, 
I_@{land}_ts,
delta_@{land},
cp_@{land},
tax_f_@{land},
tax_f2_@{land},
Ce_@{land}_ts,
cH_@{land}_ts, 
cF_@{land}_ts,
iH_@{land}_ts,
iF_@{land}_ts,
NFA_@{land}_ts,
CA_@{land}_ts,
kappaBL_@{land}_t2,
rrs2_@{land},
rrs3_@{land},
kappaBS2_@{land}_t2,
kappaBS3_@{land}_t2, 
kappaBS4_@{land}_t2, 

kappaBL_@{land}_ts,       
@#for state in g
kappaBS@{state}_@{land}_ts,
@#endfor 

@#endfor
Rest7_a_cut,
Rest6_a_cut,
lambdaeu6_a_ts2,
lambdaeu7_a_ts2,
lambdaeu8_a_ts2,
share7_a_cut,
share8_a_cut,
H4_shock
;
