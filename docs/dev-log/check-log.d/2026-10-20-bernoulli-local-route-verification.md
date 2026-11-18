# Check log: Bernoulli local route verification, 2026-10-20

All commands ran in the `codex/general-sd-regression` worktree with `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`, and `JULIA_NUM_THREADS=1`.

- `Rscript -e 'devtools::test(filter = "binomial-ordinary-phylo-sd")'`: PASS, 18 assertions, 35.9 seconds. Fits ordinary and phylogenetic random intercepts with and without SD formulas; checks SD coefficient recovery, predictions, simulation, save/reload, and constant-SD likelihood equivalence.
- `Rscript -e 'devtools::test(filter = "binomial-sd-simulation")'`: PASS, 15 assertions, 3.5 seconds. Checks marginal and conditional simulation, draws under predictor-dependent SDs, and the small bootstrap-refit path (`R = 2`). This is workflow smoke evidence, not bootstrap coverage evidence.
- `Rscript -e 'devtools::test(filter = "binomial-sd-integration")'`: PASS, 381 assertions across `binomial-sd-integration` and its beta-binomial neighbor, 301.7 seconds. Bernoulli checks include an independent scalar-cluster Laplace oracle, a wrong-sign control, constant-SD equivalence, q1 and random-slope recovery, prediction, profiling, and stored-fit behavior. The beta-binomial context also passed.
- `Rscript -e 'devtools::test(filter = "binomial-phylo-sd-simulation")'`: PASS, 11 assertions, 1.8 seconds. Checks phylogenetic SD simulation, covariance ordering/scaling, and save/reload.
- `DRM_JL_PATH=<paired Julia worktree> DRMTMB_JULIA_TESTS=true Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd")'`: PASS, 31 assertions, 34.9 seconds, one live Julia runtime test. JuliaCall loaded paired checkout `70dbf564e`; a raw branch-length scale notice was printed for the non-unit-height test tree.
- All five focused commands reported zero test failures and zero test warnings; the Julia command executed one live Julia test.
- `Rscript .../tools/check-after-task.R docs/dev-log/after-task/2026-10-20-bernoulli-local-route-verification.md`: structure check passed, then exit 1 because the active programme ledger still has 12 unmet gates (`native-binomial`, `native-calibration`, Julia bridge, and other family/target rows). No gate was marked abandoned; this workstream remains active.

## Evidence boundary

These results verify targeted behaviors on the current dirty worktree and one live Julia bridge route. They do not establish frequentist interval coverage, production-scale recovery, all random-effect/provider combinations, broad Julia runtime parity, or completion of the full supported-family inventory. The `R = 2` bootstrap test checks refitting only.
