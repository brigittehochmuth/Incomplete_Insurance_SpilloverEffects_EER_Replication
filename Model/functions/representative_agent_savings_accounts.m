function accounts = representative_agent_savings_accounts( ...
        sim,names,~,~,land)
%REPRESENTATIVE_AGENT_SAVINGS_ACCOUNTS Reconcile complete-insurance saving.
% The representative household owns the aggregate portfolio. Its budget is
% therefore the authoritative source for disposable income and saving.

if nargin < 5 || isempty(land)
    land = 'a';
end
names = strtrim(cellstr(names));
columns = 1:size(sim,2)-1;
v = @(name) sim(require_name(names,name),columns);
suffix = ['_' land '_t'];

consumption = v(['C' suffix]);
assets = v(['ae' suffix]);
tax = v(['tau' suffix]);
labor_tax = v(['tauw' suffix]);
wage = v(['w' suffix]);
employment = v(['N' suffix]);
profits = v(['PSI' suffix]);
gross_return = v('R_w_t');
qI = v(['qI' suffix]);
investment = v(['I' suffix]);
capital = v(['k' suffix]);
current_account = v(['CA' suffix]);
gnp = v(['GNP' suffix]);

lagged_assets = lag_vector(assets,1);
lagged_return = lag_vector(gross_return,1);
net_interest = (lagged_return-1).*lagged_assets;
labor_income = (1-labor_tax).*wage.*employment;
benefit_income = v(['muuu' suffix]).*v(['kappaBL' suffix]);
for state = 1:8
    benefit_income = benefit_income + ...
        v(sprintf('mueu%d_%s_t',state,land)) ...
        .*v(sprintf('kappaBS%d_%s_t',state,land));
end
disposable_cash_income = labor_income+profits+benefit_income+net_interest-tax;
household_cash_saving = disposable_cash_income-consumption;
asset_acquisition = assets-lagged_assets;
reconciliation = household_cash_saving-asset_acquisition;

investment_expenditure = qI.*investment;
capital_financing = investment_expenditure-capital ...
    +gross_return.*lag_vector(capital,1);
national_saving = investment_expenditure+current_account;
national_identity_residual = national_saving-investment_expenditure-current_account;

accounts = struct();
accounts.period = 0:numel(consumption)-1;
accounts.total_household_wealth = assets;
accounts.labor_income = labor_income;
accounts.profits = profits;
accounts.benefit_income = benefit_income;
accounts.net_interest = net_interest;
accounts.disposable_cash_income = disposable_cash_income;
accounts.household_cash_saving = household_cash_saving;
accounts.household_cash_rate = household_cash_saving./disposable_cash_income;
accounts.asset_acquisition = asset_acquisition;
accounts.reconciliation = reconciliation;
accounts.corporate_saving = capital_financing;
accounts.corporate_saving_rate = capital_financing./disposable_cash_income;
accounts.national_saving = national_saving;
accounts.national_saving_rate = national_saving./gnp;
accounts.investment_expenditure = investment_expenditure;
accounts.CA = current_account;
accounts.national_identity_residual = national_identity_residual;
accounts.max_reconciliation_relative = ...
    max(abs(reconciliation)./(1+abs(disposable_cash_income)));
accounts.max_national_identity_relative = ...
    max(abs(national_identity_residual)./(1+abs(national_saving)));
assert(accounts.max_reconciliation_relative <= 1e-8, ...
    'CompleteInsurance:SavingsReconciliation', ...
    'Household saving reconciliation %.12g exceeds 1e-8.', ...
    accounts.max_reconciliation_relative);
assert(accounts.max_national_identity_relative <= 1e-8, ...
    'CompleteInsurance:NationalSavingIdentity', ...
    'National saving identity residual %.12g exceeds 1e-8.', ...
    accounts.max_national_identity_relative);
accounts.accounting_convention = 'representative_household_budget_identity';
end


function values = lag_vector(values,lag)
values = [repmat(values(1),1,lag),values(1:end-lag)];
end


function index = require_name(names,name)
index = find(strcmp(names,name),1);
if isempty(index)
    error('CompleteInsurance:MissingName', ...
        'Required representative-agent variable is missing: %s.',name);
end
end
