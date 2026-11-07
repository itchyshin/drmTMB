# After Task: Julia Binomial Non-logit Animal and Related-matrix SD

## 1. Goal

Verify Julia Binomial predictor-dependent SD fits for animal and related-matrix intercepts and numeric slopes, tree-backed phylogenetic intercepts, one mixed phylogenetic/IID route, ordinary correlated q2 and q3 blocks, crossed independent intercept/slope terms, and nested independent intercept/slope terms under probit and complementary log-log links. Update only matching capability rows.

## 2. Implemented

Added row-scoped admissions for animal intercepts and slopes with `A_covariance` or `Ainv_precision`, and related-matrix intercepts and slopes with `K_covariance`. The exception applies only to Julia Binomial probit and cloglog rows. Pedigree, `Q_precision`, correlated blocks, simultaneous providers, and other non-logit rows remain blocked.

The tested tree-backed phylogenetic intercept, the tested tree plus IID provider pair, and ordinary correlated q2 and q3 blocks are also admitted for both links. The correlated-block exceptions are restricted to the tested block rules, coefficient sets, and target members.

The crossed-effects fitter now uses link-aware Binomial likelihood derivatives and starts for probit and complementary log-log. Independent crossed intercept and numeric-slope terms pass a focused synthetic test for both links. These admissions are limited to the tested additive iid crossed and nested routes.

## 3a. Decisions and Rejected Alternatives

Promote only rows directly exercised by focused tests. Do not treat probit/cloglog support in the base Binomial likelihood as evidence that every structured or crossed random-effect route is ready. Preserve `pedigree` and `Q_precision` as blocked until their exact routes are tested.

## 3. Mathematical Contract

The predictor-dependent scale multiplies the supplied covariance or precision route under the existing Julia parameterization. Tests compare `A` with its inverse-precision representation, and compare animal covariance with the matching `K` covariance for intercept fits. SD predictors are constant within each latent group. No new covariance normalization or correlation model was introduced.

## 4. Files Touched

- `../general-sd-julia/test/test_binomial_probit_animal_sd_regression.jl` (verification only)
- `../general-sd-julia/test/test_binomial_nonlogit_animal_slope_sd_regression.jl` (verification only)
- `../general-sd-julia/test/test_binomial_relmat_slope_sd_regression.jl` (verification only)
- `../general-sd-julia/test/test_binomial_probit_phylo_sd_regression.jl` (verification only)
- `../general-sd-julia/test/test_binomial_cloglog_phylo_sd_regression.jl` (verification only)
- `../general-sd-julia/test/test_binomial_nonlogit_correlated_sd_regression.jl` (verification only; the q2 test block was run in an isolated temporary script)
- `../general-sd-julia/test/test_binomial_nonlogit_correlated_q3_sd_regression.jl` (new independent synthetic recovery test)
- `../general-sd-julia/test/test_binomial_nonlogit_crossed_sd_regression.jl` (new independent synthetic recovery test)
- `../general-sd-julia/test/test_binomial_nonlogit_nested_sd_regression.jl` (new independent synthetic recovery test)
- `../general-sd-julia/src/binomial_sd_regression.jl` (link-aware crossed Binomial likelihood, derivatives, and starting value)
- `tools/general-sd-regression/universe.py`
- `tools/general-sd-regression/tests/test_universe.py`
- `docs/dev-log/check-log.d/2026-10-27-julia-binomial-nonlogit-animal-sd.md`
- `docs/dev-log/evidence/general-sd-regression/julia-binomial-correlated-q3-nonlogit-totoro-20261027/source.sha256`
- `docs/dev-log/evidence/general-sd-regression/julia-binomial-correlated-q3-nonlogit-totoro-20261027/run.txt`
- `docs/dev-log/evidence/general-sd-regression/julia-binomial-correlated-q3-nonlogit-totoro-20261027/combined-run.txt`
- `docs/dev-log/general-sd-regression/required-rows.tsv`
- `docs/dev-log/general-sd-regression/required-universe.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/after-task/2026-10-27-julia-binomial-nonlogit-animal-sd.md`

## 5. Checks Run

- Julia 1.10.12, one thread: animal intercept test passed 34/34.
- Julia 1.10.12, one thread: animal numeric-slope test passed 40/40, including an `Ainv_precision` bootstrap refit and serialization.
- Julia 1.10.12, one thread: related-matrix slope test passed 23/23 across logit, probit, and cloglog.
- Julia 1.10.12, one thread: probit phylogenetic test passed 42/42, including latent derivative checks and an independent dense Laplace oracle.
- Julia 1.10.12, one thread: cloglog phylogenetic and mixed phylogenetic/IID test passed 29/29, including independent dense Laplace oracles for both links.
- Julia 1.10.12, one thread: isolated non-logit correlated q2 test block passed 28/28 in 37.5 seconds for probit and cloglog.
- Totoro Julia 1.10.12, one thread: the complete existing correlated test file passed q3 logit recovery (16/16 in 1m02.9s) and q2 probit/cloglog recovery (28/28 in 19.6s).
- Totoro Julia 1.10.12, one thread: the new non-logit correlated q3 recovery test passed 26/26 in 1m08.4s for probit and cloglog. All 109 project, source, and test hashes matched the tested snapshot.
- Totoro Julia 1.10.12, one thread: `test/test_binomial_nonlogit_crossed_sd_regression.jl` passed 44/44 for probit and cloglog, covering crossed independent intercept and numeric-slope SD terms. All 107 project, source, and test hashes matched the tested snapshot.
- Totoro Julia 1.10.12, one thread: `test/test_binomial_nonlogit_nested_sd_regression.jl` passed 44/44 for probit and cloglog, covering nested independent intercept and numeric-slope SD terms. All 107 project, source, and test hashes matched the tested snapshot.
- The two earlier local attempts were interrupted at their runtime estimates before reaching a verdict; the later full Totoro run completed successfully.
- `python3 tools/general-sd-regression/universe.py` regenerated 19,230 rows.
- `python3 -m unittest discover -s tools/general-sd-regression/tests -p 'test_universe.py'` passed 19 tests.

## 6. Tests of the Tests

Independent synthetic data use link-matched Bernoulli probabilities. The checks cover convergence, broad signed SD-slope recovery, matrix-order handling, covariance and precision equivalence, predictions, simulation, one bootstrap refit, and serialization. These checks establish point-recovery and workflow behavior for the tested cases; they do not assess interval coverage.

## 7a. Issue Ledger

No issue was opened, changed, or closed.

## 8. Consistency Audit

The generated universe marks 30 additional Julia non-logit rows required: animal intercept and slope for `A_covariance` and `Ainv_precision`; related-matrix intercept and slope for `K_covariance`; tree-backed phylogenetic intercepts; the tested tree plus IID pair; ordinary correlated q2 and q3 blocks; crossed and nested independent iid terms, all under probit and cloglog. The family-level link registry remains blocked; only these exact tested rows carry `specialized_engine_admitted_route`. The denominator remains 19,230.

## 9. What Did Not Go Smoothly

The lane-preflight helper was first invoked with Python, although it is a shell script. Rerunning it with Bash produced the expected exact-path report. The first nested remote command also used `julia` from PATH, which is not set on Totoro; rerunning through the documented `~/hsq_work/julia-1.10.0/bin/julia` completed. The selected source/test paths had no conflicting missing refs; the shared lane census still reports many active lanes, so no unrelated implementation files were touched.

## 10. Known Residuals

The Julia tests are direct-engine tests and do not establish native TMB parity for these exact rows. Pedigree, `Q_precision`, correlated blocks above the tested q3 anchor, other simultaneous providers, interval calibration, and remaining distributions and mechanisms remain open. The full capability ledger is not a completion percentage.

## 11. Team Learning

Keep broad link support blocked at the family level when only selected mechanisms have been exercised. Add explicit row-level tests and admission predicates for each provider/input combination rather than promoting every structured row for a newly implemented link.

## 12. Cross-Product Coverage

- Covers direct Julia Binomial animal and related-matrix SD intercepts and numeric slopes, tree-backed phylogenetic intercepts, one phylogenetic plus IID combination, correlated q2/q3 blocks, crossed and nested independent intercept/slope terms for probit and cloglog.
- Does not cover native parity, all structured inputs, uncertainty calibration, or the full predictor-dependent random-effect SD goal.

## Next Actions

Continue with the next unresolved Bernoulli mechanism after checking exact source support and lane ownership. Keep the programme active and interval coverage deferred.
