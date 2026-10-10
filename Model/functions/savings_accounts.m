function accounts = savings_accounts(sim, names, param_values, param_names, land)
%SAVINGS_ACCOUNTS Reconcile corrected household and aggregate saving objects.
% The corrected cash measure strips firm investment financing from PSI.
% Direct household claims plus the retained-equity accrual must equal that
% cash measure. The legacy PSI-based measure is retained for disclosure.

if nargin < 5 || isempty(land)
    land = 'a';
end
names = strtrim(cellstr(names));
param_names = strtrim(cellstr(param_names));
v = @(name) sim(require_name(names, name), 1:size(sim,2)-1);
p = @(name) param_values(require_name(param_names, name));

suffix = ['_' land '_t'];
T = size(sim, 2)-1;
N = v(['N' suffix]);
Ce = v(['Ce' suffix]);
ae = v(['ae' suffix]);
tau = v(['tau' suffix]);
tauw = v(['tauw' suffix]);
w = v(['w' suffix]);
PSI = v(['PSI' suffix]);
qI = v(['qI' suffix]);
I = v(['I' suffix]);
k = v(['k' suffix]);
R = v('R_w_t');
pfind = v(['p' suffix]);
mue = v(['mue' suffix]);
mueu1 = v(['mueu1' suffix]);

% The transition may change separation after the pre-reform initial column.
% Recover the period-specific rate from the model's cohort law instead of
% applying the post-reform parameter to q0 as well:
%   mueu1_t = s_t*(1-p_t)*mue_{t-1}.
lagged_mue = lag_vector(mue, 1);
separation_denominator = (1-pfind).*lagged_mue;
assert(all(isfinite(separation_denominator)) ...
        && all(separation_denominator > 0), ...
    'BaselineModel:SavingsSeparationDenominator', ...
    'The separation-rate cohort identity has a nonpositive denominator.');
effective_separation = mueu1./separation_denominator;
assert(all(isfinite(effective_separation)) ...
        && all(effective_separation >= -1e-10) ...
        && all(effective_separation <= 1+1e-10), ...
    'BaselineModel:SavingsSeparationRate', ...
    'The separation rate implied by the cohort identity is outside [0,1].');
effective_separation = min(max(effective_separation,0),1);

gross_return = zeros(1, T);
principal_return = zeros(1, T);
for t = 1:T
    emp_weight = (1-effective_separation(t)*(1-p(['tax_f_' land])) ...
        *(1-pfind(t)))*lagged(mue, t, 1);
    emp_principal = emp_weight*lagged(ae, t, 1);
    principal_return(t) = emp_principal;
    gross_return(t) = emp_principal*lagged(R, t, 1);
    for state = 1:7
        mueu = v(sprintf('mueu%d_%s_t', state, land));
        Rest = v(sprintf('Rest%d_%s_t', state, land));
        weight = pfind(t)*lagged(mueu, t, 1)*Rest(t) ...
            *(1-p(['tax_f_' land])-p(['tax_f2_' land]));
        principal = weight*lagged(ae, t, state+1);
        principal_return(t) = principal_return(t)+principal;
        gross_return(t) = gross_return(t) ...
            +principal*lagged(R, t, state+1);
    end
end
net_interest = gross_return-principal_return;

capital_financing = qI.*I-k+R.*lag_vector(k, 1);
psi_distributed = PSI+capital_financing;
labor_income = (1-tauw).*w.*N;
net_taxes = N.*tau;
consumption_employed = N.*Ce;

disposable_cash_income = labor_income+psi_distributed+net_interest-net_taxes;
household_cash_saving = disposable_cash_income-consumption_employed;
legacy_disposable_income = labor_income+PSI+net_interest-net_taxes;
legacy_household_saving = legacy_disposable_income-consumption_employed;

direct_net_claims = N.*ae-principal_return;
net_financial_saving = direct_net_claims+capital_financing;
reconciliation = household_cash_saving-net_financial_saving;

CA = v(['CA' suffix]);
investment_expenditure = qI.*I;
national_saving = investment_expenditure+CA;
national_identity_residual = national_saving-investment_expenditure-CA;
GNP = v(['GNP' suffix]);

denom = disposable_cash_income;
accounts = struct();
accounts.period = 0:T-1;
accounts.total_household_wealth = N.*ae;
accounts.psi_distributed = psi_distributed;
accounts.net_interest = net_interest;
accounts.disposable_cash_income = disposable_cash_income;
accounts.household_cash_saving = household_cash_saving;
accounts.household_cash_rate = household_cash_saving./denom;
accounts.direct_net_claims = direct_net_claims;
accounts.net_financial_saving = net_financial_saving;
accounts.net_financial_rate = net_financial_saving./denom;
accounts.corporate_saving = capital_financing;
accounts.corporate_saving_rate = capital_financing./denom;
accounts.legacy_household_saving = legacy_household_saving;
accounts.legacy_household_rate = legacy_household_saving./legacy_disposable_income;
accounts.consolidated_private_saving = net_financial_saving;
accounts.consolidated_private_rate = net_financial_saving./denom;
accounts.national_saving = national_saving;
accounts.national_saving_rate = national_saving./GNP;
accounts.investment_expenditure = investment_expenditure;
accounts.CA = CA;
accounts.reconciliation = reconciliation;
accounts.national_identity_residual = national_identity_residual;
accounts.max_reconciliation_relative = max(abs(reconciliation)./(1+abs(denom)));
accounts.max_national_identity_relative = ...
    max(abs(national_identity_residual)./(1+abs(national_saving)));
assert(accounts.max_reconciliation_relative <= 1e-8, ...
    'BaselineModel:SavingsReconciliation', ...
    'Savings reconciliation %.12g exceeds 1e-8.', ...
    accounts.max_reconciliation_relative);
assert(accounts.max_national_identity_relative <= 1e-8, ...
    'BaselineModel:NationalSavingIdentity', ...
    'National saving identity residual %.12g exceeds 1e-8.', ...
    accounts.max_national_identity_relative);
accounts.summary = summary_table(accounts);
end

function T = summary_table(a)
names = {'Household Cash Saving';'Household Net Financial Saving'; ...
    'Corporate Saving';'Consolidated Private Saving';'National Saving'; ...
    'Legacy, Contaminated by Investment Financing'};
rates = {a.household_cash_rate; a.net_financial_rate; ...
    a.corporate_saving_rate; a.consolidated_private_rate; ...
    a.national_saving_rate; a.legacy_household_rate};
steady = NaN(numel(rates),1); impact = steady; first40 = steady; late = steady;
for i = 1:numel(rates)
    x = rates{i};
    steady(i) = 100*x(1);
    impact(i) = 100*(x(2)-x(1));
    first40(i) = mean(100*(x(2:41)-x(1)));
    late(i) = mean(100*(x(38:41)-x(1)));
end
T = table(names, steady, impact, first40, late, 'VariableNames', ...
    {'Measure','SteadyStateRatePct','ImpactChangePP', ...
    'Q1_40AverageChangePP','Q37_40AverageChangePP'});
end

function x = lagged(series, t, lag)
x = series(max(1, t-lag));
end

function lagged_series = lag_vector(series, lag)
lagged_series = [repmat(series(1), 1, lag), series(1:end-lag)];
end

function index = require_name(names, name)
index = find(strcmp(names, name), 1);
if isempty(index)
    error('BaselineModel:MissingName', 'Required model name not found: %s', name);
end
end
