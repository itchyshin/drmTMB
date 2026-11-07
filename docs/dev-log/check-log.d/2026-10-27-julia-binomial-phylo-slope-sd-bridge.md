## 2026-10-27: Julia Binomial phylogenetic slope SD bridge closeout

- Live R-to-Julia test, with paired local DRM.jl and Julia 1.10.0:
  `PATH="/Users/z3437171/.juliaup/bin:$PATH" DRMODELS_JL_PATH="$PWD/../general-sd-julia" DRM_JL_PATH="$PWD/../general-sd-julia" DRMTMB_JULIA_TESTS=true NOT_CRAN=true JULIA_HOME="/Users/z3437171/.juliaup/bin" OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "julia-binomial-phylo-slope-sd", reporter = "summary", stop_on_failure = TRUE)'`
  passed with exit 0: 30 expectations and one live Julia bridge test. It checked logit, probit, and cloglog fits against native TMB, tip-level SD predictions, plus logit save/reload and marginal simulation.
- `python3 tools/general-sd-regression/universe.py` regenerated 19,118 rows. The exact Julia probit/cloglog phylogenetic numeric-slope tree rows are admitted; other non-logit Julia Binomial rows remain blocked.
- `python3 -m unittest discover -s tools/general-sd-regression/tests`: 33 passed in 39.622 seconds.
- An independent review confirmed the exception is limited to the exact two rows and prompted an exact link-set assertion (`probit`, `cloglog`). The ledger wording describes other rows as blocked; it does not assert those Julia routes are absent.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: PASS, 19,118 candidate rows, 75 linked, 19,043 unlinked, 95 evidence records.
- `Rscript -e 'pkgdown::check_pkgdown()'`: exit 0, no problems found; existing Pandoc `--mathml` deprecation warnings.
- Combined pkgdown site build did not complete after more than seven minutes idle and was stopped. No full site-render claim.
- Scoped `git diff --check`: PASS. No full R suite, `R CMD check`, or interval calibration run.
- Evidence receipt: `docs/dev-log/general-sd-regression/evidence/julia-binomial-phylo-slope-sd-bridge-20261027/receipt.json`. No capability row promoted.
