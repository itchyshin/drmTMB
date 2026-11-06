# After Task: Bernoulli Correlated q2 Review Repairs

## 1. Goal

Repair the independent review findings for Bernoulli correlated intercept-slope SD regression in native TMB and DRM.jl, and record the remaining numerical and documentation boundaries.

## 2. Implemented

Julia now evaluates the correlated slope innovation as a stable sech of the Fisher-z correlation parameter in both the likelihood and marginal simulator. Tests cover a high-correlation objective and gradient, a simulator call where `tanh(20)` rounds to one, and a slope-only bootstrap refit. Native tests now fit both intercept-only and slope-only targets in the correlated TMB block and check covariance reconstruction. The bounded mathematical contract is recorded in `docs/dev-log/general-sd-regression/bernoulli-correlated-q2-contract.md`.

A live R-to-Julia fit exposed a missing `recov` label for one ordinary
Bernoulli/binomial correlated q2 block. The bridge now supplies its exact
`group:atanh_rho` label. The live test verifies fitting, both selected SD
coefficient blocks, group-level predictions, and exact coefficient/prediction
preservation after RDS reload on one synthetic dataset. The fit emitted a
singular-Hessian warning, so its standard errors are not reliable.

## 3a. Decisions and Rejected Alternatives

Keep the existing two-coefficient block and its shared constant correlation. The stable innovation uses `exp(log(2) - abs(eta) - log1p(exp(-2 * abs(eta)))` rather than subtracting `tanh(eta)^2` from one. The objective test uses eta 10 because the quadrature objective is not finite at eta 20; the simulator separately checks eta 20. Assumptions: response rows are complete, the block is one ordinary `(1 + x | id)` term, and each SD predictor is fixed and constant within group. If broader cases are intended, they need separate capability rows and validation.

## 4. Files Touched

- `src/binomial_sd_regression.jl`
- `src/inference.jl`
- `test/test_binomial_sd_regression.jl`
- `tests/testthat/test-binomial-correlated-sd.R`
- `R/julia-bridge.R`
- `tests/testthat/test-julia-binomial-sd.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/18-random-effect-scale-models.md`
- `NEWS.md`
- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/general-sd-regression/bernoulli-correlated-q2-contract.md`
- `docs/dev-log/check-log.d/2026-10-18-bernoulli-correlated-q2-review-repair.md`
- This report

Native and Julia bases were `425bee81572c625a634b2b083050c5c57c1dc1f1` and `70dbf564eb670144c63c08f61ea099084d95add2`. Current source hashes: native TMB `1d172f604473d96a611a339a56c691a572b1acdaf508cf93103fc20ed61a0bb1`; native test `a27f06ef36a833d9cab8292939096613f373aa4963fd0e67fa6eef58ea443034`; Julia fitter `498704bbc8027581079212c14f831d29d1ccfa645297f4081a0e290ff53825f8`; Julia simulator `1f09f0c3605f55f93286477e414fb8dcbd6887180a7f51c95cebe88a35f98e09`; Julia test `0ba3407b132c349ca84e0e9863389c82820bbc556de4f42bb7569dbceb1c4013`.

## 5. Checks Run

- `JULIA_DEPOT_PATH="/private/tmp/drmTMB-julia-depot:/Users/z3437171/.julia" OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 julia --project=. --compiled-modules=no -e 'include("test/test_binomial_sd_regression.jl")'`: passed 105 assertions across the focused file.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-binomial-correlated-sd.R", reporter = "summary")'`: passed; testthat completed the focused file without failures.
- `DRMTMB_JULIA_TESTS=true DRM_JL_PATH=<Julia worktree> DRMODELS_JL_PATH=<Julia worktree> JULIA_DEPOT_PATH=/private/tmp/drmTMB-julia-depot:/Users/z3437171/.julia OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-julia-binomial-sd.R", reporter = "summary")'`: four live Julia bridge tests passed, including the new correlated q2 extraction, prediction, and save/reload test. Julia reported a numerically singular Hessian; no standard-error claim follows.
- `Rscript -e 'rmarkdown::render("vignettes/formula-grammar.Rmd", output_file = "/private/tmp/formula-grammar.html", quiet = TRUE)'`: rendered successfully, with one Pandoc MathJax deprecation warning.
- `python3 /Users/z3437171/shinichi-brain/tools/slop_check.py ...`: the edited design docs, vignette, NEWS, and contract note returned `FINDINGS: 0`.
- `git diff --check`: passed in both worktrees after the implementation edits.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R <this report>`: report structure passed; the command then exited 1 because nine programme acceptance ledgers remain unmet. This correctly keeps the full goal open.
- No Totoro or DRAC campaign was run.

## 6. Tests of the Tests

The Julia suite compares the two-target fixed-parameter likelihood against independent two-dimensional normal quadrature and includes wrong-innovation and independence negative controls. The new boundary checks require a finite objective and gradient at eta 10 and a positive stable innovation plus finite simulator output at eta 20. Native tests combine actual TMB fits for each partial-target branch with covariance checks, while the existing both-target fit has an independent quadrature oracle. The initial eta-20 objective assertion failed and was narrowed to eta 10 after confirming the objective remains unresolved at the more extreme numerical boundary.

## 7a. Issue Ledger

No GitHub issue was changed in this review-repair slice. The family-by-effect-by-engine programme ledger remains open; issue reconciliation is still required before any public completion claim.

## 8. Consistency Audit

The equation, R selectors, Julia selectors, TMB covariance factor, and Julia likelihood/simulator use the same marginal-SD and constant-correlation contract. The bridge-label unit test fails before the fix and passes after it; negative controls restrict the label to one unlabelled ordinary binomial q2 block. The live R-to-Julia test then exercises the payload, fit, public extraction, prediction, and save/reload together. The canonical formula, likelihood, and random-effect-scale design docs, NEWS, and formula vignette now record the new narrow bridge evidence and its warning, parity, and calibration limits. They do not claim broader family or provider support.

## 9. What Did Not Go Smoothly

At eta 20 the corrected Julia quadrature objective still returned a non-finite value. This showed that a stable Cholesky innovation alone does not make the extreme-correlation quadrature objective numerically resolvable. The likelihood/gradient check now uses eta 10, and the eta-20 case is retained as an explicit limitation. The closeout template helper resolved its repository root to the Shinichi brain repository and could not write into the package worktree, so this report uses the package's exact required section structure directly.

## 10. Known Residuals

The Julia likelihood at eta 20 remains unresolved. The live R-to-Julia smoke covers one synthetic design only and the fit emitted a singular-Hessian warning; same-data numerical parity and calibrated profile, Wald, or bootstrap intervals remain unverified. Other response families, structured providers, labels, multiple blocks, and higher-dimensional covariance remain outside this slice. Broad family inventory reconciliation and Totoro/DRAC recovery and calibration remain open.

## 11. Team Learning

Use a stable log-sech/sech expression in both likelihood and simulation code. Add a numerical-boundary test to each transform consumer so a likelihood fix cannot leave its bootstrap simulator unstable.

Memory receipt: queried the `shinichi-brain` vault and read `drmTMB future sd()-submodel random-effect hierarchy`; its fixed-predictor and no-random-effects-inside-SD rule shaped the scope. The repository `route.py` call did not find a manifest for the absolute checkout path, so local design docs and the package worktree supplied technical context. Golden Set: not run; this numerical transform was not a known Golden Set case in the current worktree.

## 12. Cross-Product Coverage

Covers: native TMB correlated q2 partial-target fitting and covariance reconstruction; Julia correlated q2 likelihood, simulator, and bootstrap-refit checks; and one live R-to-Julia q2 fit with target extraction, group-SD prediction, and save/reload preservation.

Does NOT cover: same-data numerical parity between engines, reliable standard errors for the singular-Hessian fit, calibrated uncertainty, the eta-20 Julia likelihood, other families, structured or crossed providers, additional correlation models, or the complete programme capability universe.
