# Julia Binomial crossed and nested non-logit SD checks

- Totoro Julia 1.10.12, one thread: crossed independent Binomial intercept and numeric-slope SD tests passed 44/44 for probit and cloglog; 107 source hashes matched. Receipt: `docs/dev-log/evidence/general-sd-regression/julia-binomial-crossed-nonlogit-totoro-20261027/`.
- Totoro Julia 1.10.12, one thread: nested independent Binomial intercept and numeric-slope SD tests passed 44/44 for probit and cloglog; 107 source hashes matched. Receipt: `docs/dev-log/evidence/general-sd-regression/julia-binomial-nested-nonlogit-totoro-20261027/`.
- `python3 tools/general-sd-regression/universe.py` regenerated 19,230 rows; the two nested rows are admitted only for the exact probit/cloglog Julia iid additive route.
- `python3 -m unittest discover -s tools/general-sd-regression/tests -p 'test_universe.py'` passed 19 tests.
- `Rscript tools/check-after-task.R ...` passes the report structure check; acceptance-ledger state is UNKNOWN because the gate runner is unavailable.
- Prose lint found 0 issues; scoped `git diff --check` passed.

The point-recovery tests establish only these synthetic workflows. They do not establish interval coverage or native R/TMB parity.

---

# Julia Binomial non-logit animal and related-matrix SD checks

- Julia 1.10.12, one thread: `test/test_binomial_probit_animal_sd_regression.jl` passed 34/34.
- Julia 1.10.12, one thread: `test/test_binomial_nonlogit_animal_slope_sd_regression.jl` passed 40/40.
- Julia 1.10.12, one thread: `test/test_binomial_relmat_slope_sd_regression.jl` passed 23/23 across logit, probit, and cloglog.
- Julia 1.10.12, one thread: `test/test_binomial_probit_phylo_sd_regression.jl` passed 42/42, including the independent dense Laplace oracle.
- Julia 1.10.12, one thread: `test/test_binomial_cloglog_phylo_sd_regression.jl` passed 29/29, including probit/cloglog mixed phylogenetic plus IID dense-oracle comparisons.
- Julia 1.10.12, one thread: the isolated non-logit correlated q2 test block from `test/test_binomial_nonlogit_correlated_sd_regression.jl` passed 28/28 in 37.5 seconds.
- Totoro Julia 1.10.12, one thread: `test/test_binomial_nonlogit_correlated_sd_regression.jl` passed q3 logit recovery 16/16 in 1m02.9s and q2 probit/cloglog recovery 28/28 in 19.6s.
- Totoro Julia 1.10.12, one thread: `test/test_binomial_nonlogit_correlated_q3_sd_regression.jl` passed 26/26 in 1m08.4s for probit and cloglog. Exact project, source, and test hashes are recorded in `docs/dev-log/evidence/general-sd-regression/julia-binomial-correlated-q3-nonlogit-totoro-20261027/source.sha256` and both run receipts.
- `python3 tools/general-sd-regression/universe.py` regenerated 19,230 rows.
- `python3 -m unittest discover -s tools/general-sd-regression/tests -p 'test_universe.py'` passed 19 tests.
- `Rscript tools/check-after-task.R docs/dev-log/after-task/2026-10-27-julia-binomial-nonlogit-animal-sd.md` passed the report structure check. The acceptance ledger checker reports UNKNOWN because its gate runner is unavailable.
- `python3 tools/slop_check.py docs/dev-log/after-task/2026-10-27-julia-binomial-nonlogit-animal-sd.md` found 0 issues.
- Scoped `git diff --check` passed.

This is focused Julia point-recovery and workflow evidence for the exact rows named in the after-task report. It does not establish native parity, q4 or larger correlated-block support, or interval calibration.
