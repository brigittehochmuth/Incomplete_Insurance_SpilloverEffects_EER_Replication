// Baseline fiscal closure: labor taxes are fixed and lump-sum taxes stabilize debt.
@#for land in country
tauw_@{land}_t = tauw_@{land}_ts;
tau_@{land}_t - steady_state(tau_@{land}_t) = rhoto_@{land}*(tau_@{land}_t(-1)-steady_state(tau_@{land}_t)) + xi_b_@{land}*(b_@{land}_t(-1)-omega_b@{land}*Y_@{land}_t(-1));
@#endfor
