# After Task: structured SD clamp report consistency

## 1. Goal

Keep the structured phylogenetic random-effect SD report consistent with the
effective SD used by the likelihood and public prediction when the numerical
log-SD clamp is active.

## 2. Implemented

Four structured TMB branches now store the soft-clamped group log SD before
exponentiating it: Gaussian, Gamma, Beta, and the shared bivariate
Gaussian/lognormal/Student branch. Runtime checks now cover univariate
Gaussian, Gamma, Beta, and bivariate Gaussian. This aligns
`log_sd_phylo_group`, `sd_phylo_group`, and link-scale prediction.

## 3a. Decisions and Rejected Alternatives

The clamp is applied once and the stored effective log SD is exponentiated.
This keeps the report aligned with the value used in the likelihood. I did not
change the random-effect covariance, kernel scaling, or public formula syntax.

## 4. Files Touched

- `src/drmTMB.cpp`
- `tests/testthat/test-structured-sd-clamp-report.R`
- `tests/testthat/test-gamma-phylo-sd-regression.R`
- `docs/dev-log/check-log.md`
- This report

## 5. Checks Run

- `Rscript -e 'pkgload::load_all(".", recompile = TRUE, quiet = FALSE)'` rebuilt
  the current package successfully. The compiler emitted 15 warnings, including
  existing unused variables in the likelihood and Eigen header warnings.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "gamma-phylo-sd-regression", reporter = "summary")'`
  passed all 15 expectations.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "(gamma-phylo-sd-regression|structured-sd-clamp-report)", reporter = "summary")'`
  passed all 30 expectations across Gamma, Gaussian, Beta, and bivariate
  Gaussian routes.
- `rg -n '= eta_sd;' src/drmTMB.cpp` returned no raw group-SD report assignments.
- `gh issue list --state open --search 'phylogenetic SD clamp report in:title,body' --limit 10`
  returned no matching open issue.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R <report>`
  passed the report-structure check and then reported open programme gates.
  This is expected because the overall SD-regression goal remains active.
- Status inventory search: `rg -n 'log_sd_phylo_group|sd_phylo_group|logsigma_clamp' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd`. Only historical clamp entries in `NEWS.md` matched; the formula and capability inventory did not change.

## 6. Tests of the Tests

The family tests perturb fitted SD coefficients beyond the clamp, then check
the exact smooth-clamp result, `log(sd_phylo_group)`, and public link-scale
predictions. To verify that the tests detect the original bug, I temporarily
restored raw `eta_sd` reporting in the four changed branches, rebuilt, and ran
the tests. They produced at least 10 expected failures: TMB reported raw 4.00
while the likelihood and public prediction used the effective 3.75. I restored
the implementation, rebuilt, and reran the suite successfully. An earlier
exploratory assertion incorrectly assumed the output must be below the upper
identity band; the smooth clamp saturates over its configured margin. The final
tests use the exact transformation.

## 7a. Issue Ledger

No matching open issue was found. No issue was opened or changed.

## 8. Consistency Audit

The formula grammar, covariance definition, and kernel normalization are
unchanged. The source audit found seven structured group-SD branches; all store
the clamped value before exponentiation. Runtime tests cover the Gaussian,
Gamma, Beta, and bivariate Gaussian branches, comparing TMB reports with public
predictions. The bivariate lognormal and Student variants and the separate
beta-binomial, binomial, and Poisson branches received source-level comparison
only in this slice.

## 9. What Did Not Go Smoothly

The first clamp assertion confused the exact identity band with the clamp's
outer saturation range. Reading the C++ helper resolved the discrepancy, and
the final test checks the configured transformation directly.

## 10. Known Residuals

This slice does not establish runtime consistency for bivariate lognormal or
Student models, beta-binomial, binomial, or Poisson structured branches, Julia
parity, full family/effect breadth, or interval-coverage calibration. Coverage
calibration remains outside the active implementation goal.

## 11. Team Learning

For a smooth clamp, test the configured transformation including its margin;
do not assume the result stays inside the identity band.

## 12. Cross-Product Coverage

This slice covers native q1 structured phylogenetic SD reports for Gaussian,
Gamma, Beta, and bivariate Gaussian. It does NOT cover bivariate lognormal or
Student runtime paths, other structured providers, or Julia execution. The
active programme ledger retains those cells as open.
