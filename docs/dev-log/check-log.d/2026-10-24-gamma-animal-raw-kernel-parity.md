## 2026-10-24 Gamma animal raw-`A` parity

- Decision: use raw supplied `A` in Julia Gamma animal fitting and marginal simulation, matching native TMB; the user explicitly selected this after the normalization-vs-raw scaling conflict was surfaced.
- Julia focused tests: `test_gamma_animal_sd_regression.jl`, `test_gamma_animal_slope_sd_regression.jl`, and `test_gamma_animal_intercept_slope_sd.jl`; 66 assertions passed.
- R bridge filter: `gamma-animal-q2-nonunit-kernel-(simulation|parity)`; both live Julia tests passed. The simulation test checks the raw-`A` seeded draw; the parity test checks coefficient, log likelihood, and named group-SD agreement with non-unit-diagonal `A`.
- Julia and R diffs passed scoped `git diff --check` before doc updates. Documentation edits were then checked for stale claims and whitespace.
- This is one Gamma animal point-parity fixture and selected simulation checks. It does not establish broad engine parity, interval coverage, or programme completion.
