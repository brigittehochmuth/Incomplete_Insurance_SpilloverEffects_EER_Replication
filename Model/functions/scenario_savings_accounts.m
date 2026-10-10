function accounts = scenario_savings_accounts( ...
        run_dir,sim,names,param_values,param_names,land)
%SCENARIO_SAVINGS_ACCOUNTS Select the household accounting for a run.

if isfile(fullfile(run_dir,'complete_insurance_backend.json'))
    accounts = representative_agent_savings_accounts( ...
        sim,names,param_values,param_names,land);
else
    accounts = savings_accounts(sim,names,param_values,param_names,land);
end
end
