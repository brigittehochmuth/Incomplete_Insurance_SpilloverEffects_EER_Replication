function moments = recruiting_transition_moments(sim, names)
%RECRUITING_TRANSITION_MOMENTS Manuscript-consistent sector employment moments.
% The maintained empirical mapping uses percentage deviations from the
% pre-reform level over transition quarters 1--40 (matrix columns 2:41).

names = strtrim(cellstr(names));
v = @(name) sim(find(strcmp(names,name),1),:);
assert(~isempty(find(strcmp(names,'NT_a_t'),1)) && ...
    ~isempty(find(strcmp(names,'NN_a_t'),1)), ...
    'RecruitingCosts:MissingSectorEmployment','NT_a_t and NN_a_t are required.');
assert(size(sim,2) >= 42,'RecruitingCosts:ShortTransition', ...
    ['The simulation must contain an initial column, quarters 1--40, ' ...
     'and a terminal column.']);
q = 2:41;
nt_level = v('NT_a_t');
nn_level = v('NN_a_t');
nt = 100*(nt_level./nt_level(1)-1);
nn = 100*(nn_level./nn_level(1)-1);
moments = struct();
moments.definition = 'mean 100*(N_t^j/N_0^j-1), t=1,...,40';
moments.tradable_q1_40_avg_pct = mean(nt(q));
moments.nontradable_q1_40_avg_pct = mean(nn(q));
moments.relative_q1_40_avg_pct = moments.tradable_q1_40_avg_pct ...
    -moments.nontradable_q1_40_avg_pct;
moments.relative_identity_error = moments.relative_q1_40_avg_pct ...
    -(mean(nt(q))-mean(nn(q)));
moments.tradable_impact_pct = nt(2);
moments.nontradable_impact_pct = nn(2);
[moments.tradable_peak_pct,moments.tradable_peak_quarter] = max(nt(q));
[moments.nontradable_peak_pct,moments.nontradable_peak_quarter] = max(nn(q));
[moments.tradable_trough_pct,moments.tradable_trough_quarter] = min(nt(q));
[moments.nontradable_trough_pct,moments.nontradable_trough_quarter] = min(nn(q));
moments.tradable_peak_quarter = moments.tradable_peak_quarter;
moments.nontradable_peak_quarter = moments.nontradable_peak_quarter;
moments.tradable_trough_quarter = moments.tradable_trough_quarter;
moments.nontradable_trough_quarter = moments.nontradable_trough_quarter;
assert(abs(moments.relative_identity_error) <= 1e-12, ...
    'RecruitingCosts:RelativeMomentIdentity', ...
    'Reported relative employment moment is not T minus N.');
end
