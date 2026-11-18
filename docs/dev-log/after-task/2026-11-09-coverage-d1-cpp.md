# After task: coverage D1, drmTMB C++ branches

Reader: the next person adding a coverage batch, and a reviewer checking that
the new tests do not pin a bug.

## Task goal

Raise line coverage of `src/drmTMB.cpp` by executing the opt-in
`se_group_sd` ADREPORT bodies, the Tweedie constant phylogenetic SD, the
binomial two-provider group SD, and the bivariate phylogenetic PC prior.
Tests only, in new `tests/testthat/test-coverage-d1-*.R` files.

## Files created

- `tests/testthat/test-coverage-d1-a-group-sd.R`
- `tests/testthat/test-coverage-d1-b-group-sd.R`
- `tests/testthat/test-coverage-d1-c-structured.R`
- `tests/testthat/test-coverage-d1-d-structured.R`
- `docs/dev-log/check-log.d/2026-11-09-coverage-d1-cpp.md`
- this note

No file under `R/`, `src/`, or `.github/` changed.

## Checks

`testthat::test_file()` on each new file: FAIL 0, WARN 0, SKIP 0.
Pass counts were 14, 70, 50, and 18. Uninstrumented file times were 0.49s,
1.78s, 0.86s, and 0.35s, on shards 1 to 4.

`covr::package_coverage(type = "none")` on the four files, including the
`-O0` rebuild, finished in 150.9s with the tests passing. Union with the
merged cobertura from run 42646500498:

- `src/drmTMB.cpp` before: 5159 / 5344 = 96.54%
- `src/drmTMB.cpp` after: 5206 / 5344 = 97.42%
- 47 missed lines newly hit
- no other `src/` file gained a hit

The CI shards already rebuild with coverage flags. The added cost on a shard
is the test time, not that rebuild. Recent green shard times on the 180-minute
job were about 142, 90, 68, and 141 minutes. The new file on the slowest
shard (shard 1) is the 0.49s student and Poisson fit.

## What the tests check

For a group SD, the reported value equals

`drm_exp_sd_logscale_guarded(drm_softclamp_log_sd(log_eta, tmb_data))`

and the sdreport ADREPORT equals the same transform of the sdreport log
predictor. Where the helper applies, `log_eta` equals the SD design matrix
times `beta_sd_mu` or `beta_sd_sigma`. The Tweedie model with `phylo()` and
no `sd()` formula checks `sd_phylo == exp(log_sd_phylo)`. The bivariate PC
prior checks

`sum(rate * sd - log(sd) - log(rate))`

with `rate = -log(0.05) / 1`, and `estimator == "MAP"`. Every retained fit
has `opt$convergence == 0`. Standard errors are not asserted.

## Consistency

This batch does not change a family, the formula grammar, or a likelihood.
`README.md`, `NEWS.md`, `docs/dev-log/internal-roadmap.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
`vignettes/formula-grammar.Rmd`, and `_pkgdown.yml` were left as they are.

Searches on the new test and note files:

```sh
rg "meta_gaussian|tau ~|rho ~|meta_known_V" tests/testthat/test-coverage-d1-*.R docs/dev-log/check-log.d/2026-11-09-coverage-d1-cpp.md docs/dev-log/after-task/2026-11-09-coverage-d1-cpp.md
rg "nocov|skip_on_covr|skip_if" tests/testthat/test-coverage-d1-*.R
```

The four test files and the check-log shard have no matches. The tests say
`sigma`, `sd()`, `phylo()`, `rho12`, and `mu`.

## Tests of the tests

A student fit was printed before the tests were written. `report()` matched
the R transform with a maximum absolute difference of 0, and the sdreport
vector matched the transform of the sdreport log predictor with difference 0.
The same identity is what `test_file()` now checks for each family. A
bivariate penalty fit matched the hand sum to the printed digits (`3.40134998`
on both sides). Fits that warned about singular or false convergence were
replaced with data that converges, not with a weaker expectation.

## What did not go smoothly

`phylo(tree = built$tree)` is rejected. The formula needs a bare name, `tree`.

`se_group_sd` on a random 4-tip coalescent tree made the Tweedie phylogenetic
fit either non-convergent in a fraction of a second or still running after
15 seconds. One seed-1 draw converges both the constant SD and the `sd()`
formula in about 0.2s. That tree and those counts are written out in the test,
so a different `ape` version cannot redraw the tree.

The missed lines 3354-3355 are the lognormal mu group-SD ADREPORT. The
skew-normal ADREPORT at 3250-3251 is not gated on `report_group_sd` and was
already covered. The first skew fit did not move 3354.

`sd_phylo_group_log_values()` does not index the bivariate `sd1()` / `sd2()`
coefficient vector. Using it as the expected log predictor would have asserted
`NA` against a finite template value. The test does not do that.

## Team learning

An ADREPORT body that is already behind a hit `if` still needs one fit with
the flag on. Compare each reported vector with the transform of its own log
predictor. Do not require `sdreport()$value` to equal `obj$report()`.

For a coverage shard that is already near 180 minutes, keep the new file to
fits that return in well under a second, and do not retry a non-converging
Tweedie phylogenetic fit with a larger `eval.max`.

## Design docs, pkgdown, issues

No design-doc or pkgdown edit. The likelihood and the formula grammar are
unchanged.

No GitHub issue was opened or commented on. The uncovered lines are flags in
the pull request. Opening an issue for each defensive `error()` body would
duplicate the flag list, and the dead branches are not a user-facing bug on
their own. Open pull requests that edit `src/drmTMB.cpp` (#1689, #1529,
#1514, #1524, #1443, #1438, #1033) were not modified and these tests do not
call the SD-prior API from #1689.

## Limitations

`src/drmTMB.cpp` is at 97.42%, not the plan's 99% target. Reaching 99% needs
5291 covered lines. About 111 of the remaining 138 zeros cannot be hit from
the public R API without editing `R/` or `src/`. The flags in the pull request
name those lines. The next coverage batch should not spend fits on them.
