R_w_t      = R_w_ts; 
pH_t       = 1; 
pF_t       = 1;
rer_t      = 1;
rel_pT_t   = 1;
rer_cpi_t  = 1;
TPI_a_t = TPI_a_ts;  % eq
TPI_b_t= TPI_b_ts;
cT_a_t =cT_a_ts;
cN_a_t =cN_a_ts;
cT_b_t =cT_b_ts;
cN_b_t =cN_b_ts;

EX_a_t      = EX_a_ts;
IM_a_t      = IM_a_ts;
NX_a_t      = NX_a_ts;
EX_b_t      = EX_b_ts;
IM_b_t      = IM_b_ts;
NX_b_t      = NX_b_ts;


@#for land in country 
MPL_@{land}_t     = MPL_@{land}_ts;         
MPK_@{land}_t     = MPK_@{land}_ts;         
ae_@{land}_t     = ae_@{land}_ts;         
b_@{land}_t      = b_@{land}_ts;
C_@{land}_t      = C_@{land}_ts;              
Ce_@{land}_t     = Ce_@{land}_ts;
Welfe@{state}_@{land}_t    = Welfe@{state}_@{land}_ts;
@#for state in g
Welfeu@{state}_@{land}_t    = Welfeu@{state}_@{land}_ts;
Ceu@{state}_@{land}_t    = Ceu@{state}_@{land}_ts;
@#endfor
Cuu_@{land}_t    = Cuu_@{land}_ts;       
Welfuu_@{land}_t    = Welfuu_@{land}_ts;       
DRe_@{land}_t    = DRe_@{land}_ts;
@#for state in g
kappaBS@{state}_@{land}_t = kappaBS@{state}_@{land}_ts;
@#endfor
kappaBL_@{land}_t = kappaBL_@{land}_ts; 
lambdae_@{land}_t = lambdae_@{land}_ts; 
@#for state in g
lambdaeu@{state}_@{land}_t = lambdaeu@{state}_@{land}_ts;
@#endfor
lambdauu_@{land}_t = lambdauu_@{land}_ts;
M_@{land}_t      = M_@{land}_ts;              
mue_@{land}_t    = mue_@{land}_ts; 
@#for state in g
mueu@{state}_@{land}_t   = mueu@{state}_@{land}_ts;
@#endfor
muuu_@{land}_t   = muuu_@{land}_ts;       
qY_@{land}_t     = qY_@{land}_ts;
qI_@{land}_t     = qI_@{land}_ts;
qT_@{land}_t     = qT_@{land}_ts;
qN_@{land}_t     = qN_@{land}_ts;
PY_@{land}_t     = PY_@{land}_ts;
iT_@{land}_t     = iT_@{land}_ts;
iN_@{land}_t     = iN_@{land}_ts;
IPI_@{land}_t    = IPI_@{land}_ts;
N_@{land}_t      = N_@{land}_ts;                    
NT_@{land}_t     = NT_@{land}_ts;
NN_@{land}_t     = NN_@{land}_ts;
PSI_@{land}_t    = PSI_@{land}_ts;
CV_@{land}_t     = CV_@{land}_ts;
J_@{land}_t      = J_@{land}_ts;
p_@{land}_t      = p_@{land}_ts;              
q_@{land}_t      = q_@{land}_ts;              
Sf_@{land}_t     = Sf_@{land}_ts;
SfT_@{land}_t    = SfT_@{land}_ts;
SfN_@{land}_t    = SfN_@{land}_ts;
She_@{land}_t    = She_@{land}_ts;         
wnash_@{land}_t  = w_@{land}_ts;
tauw_@{land}_t   = tauw_@{land}_ts;           
Ue_@{land}_t     = Ue_@{land}_ts;
@#for state in g
Ueu@{state}_@{land}_t    = Ueu@{state}_@{land}_ts;
@#endfor
Uuu_@{land}_t    = Uuu_@{land}_ts;
V_@{land}_t      = V_@{land}_ts;              
VT_@{land}_t     = VT_@{land}_ts;
VN_@{land}_t     = VN_@{land}_ts;
w_@{land}_t      = w_@{land}_ts;         
Y_@{land}_t      = Y_@{land}_ts;  
YT_@{land}_t     = YT_@{land}_ts;
YN_@{land}_t     = YN_@{land}_ts;
KTuse_@{land}_t  = KTuse_@{land}_ts;
KNuse_@{land}_t  = KNuse_@{land}_ts;
MPLT_@{land}_t   = MPLT_@{land}_ts;
MPLN_@{land}_t   = MPLN_@{land}_ts;
MPKT_@{land}_t   = MPKT_@{land}_ts;
MPKN_@{land}_t   = MPKN_@{land}_ts;
RK_@{land}_t     = RK_@{land}_ts;
RCT_@{land}_t    = RCT_@{land}_ts;
RCN_@{land}_t    = RCN_@{land}_ts;
EXVOL_@{land}_t  = EXVOL_@{land}_ts;
EXVAL_@{land}_t  = EXVAL_@{land}_ts;
IMVOL_@{land}_t  = IMVOL_@{land}_ts;
IMVAL_@{land}_t  = IMVAL_@{land}_ts;
We_@{land}_t     = We_@{land}_ts; 
@#for state in g
Weu@{state}_@{land}_t    = Weu@{state}_@{land}_ts;
@#endfor

Wuu_@{land}_t    = Wuu_@{land}_ts;
TS_@{land}_t     = TS_@{land}_ts; 
DG_@{land}_t     = DG_@{land}_ts;
@#for state in j
share@{state}_@{land}_t= share@{state}_@{land}_ts;
@#endfor
@#for state in m
Rest@{state}_@{land}_t = Rest@{state}_@{land}_ts;
@#endfor 

k_@{land}_t       = k_@{land}_ts; 
I_@{land}_t       = I_@{land}_ts;
CPI_@{land}_t      = 1;

Pi_@{land}_t     = 1;

pN_@{land}_t = pN_@{land}_ts;

cH_@{land}_t     = cH_@{land}_ts; 
cF_@{land}_t     = cF_@{land}_ts;

iH_@{land}_t     = iH_@{land}_ts; 
iF_@{land}_t     = iF_@{land}_ts;
NFA_@{land}_t    = NFA_@{land}_ts;
tau_@{land}_t    = tau_@{land}_ts;
TQ_@{land}_t    = TQ_@{land}_ts;     
     
@#endfor

Rf_a_t = Rf_a_ts;
nfa_spread_a_t = nfa_spread_a_ts;
nfa_spread_b_t = nfa_spread_b_ts;
