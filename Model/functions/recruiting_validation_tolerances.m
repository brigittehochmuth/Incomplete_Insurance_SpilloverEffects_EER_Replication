function tolerances = recruiting_validation_tolerances()
%RECRUITING_VALIDATION_TOLERANCES Central numerical gates for recruiting costs.

tolerances.derivative_relative = 1e-6;
tolerances.identity = 1e-10;
tolerances.job_value = 1e-10;
tolerances.vacancy_foc = 1e-10;
tolerances.resource = 1e-10;
tolerances.employment_flow = 1e-10;
tolerances.normalized_intensity = 1e-12;
tolerances.target_pp = 0.01;
tolerances.current_regression_scaled = 1e-10;
end
