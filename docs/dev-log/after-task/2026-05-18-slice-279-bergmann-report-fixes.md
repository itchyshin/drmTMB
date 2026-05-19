# After Task: Slice 279 Bergmann Report Fixes

## Goal

Close the Bergmann-report follow-up items without widening the modelling scope:
invalid fixed-effect Wald variances should not masquerade as valid intervals,
univariate `sigma ~ phylo(...)` should tell users what is unsupported, labelled
q4 syntax that really decomposes into two q2 blocks should stay tested, and the
convergence guide should tell readers how to triage long iteration histories.

## Standing Perspectives

- Ada kept the work scoped to post-fit safety, boundary text, one existing
  covariance-block path, and convergence prose.
- Fisher checked that invalid Wald standard errors produce unavailable interval
  rows instead of finite-looking inference.
- Curie kept the tests deterministic and tied to the affected behaviours.
- Pat checked that the unsupported `sigma ~ phylo(...)` message gives an
  applied user a next model to try.
- Grace checked vignette rendering, pkgdown, and whitespace hygiene.
- Rose checked the status inventory for stale claims about fitted univariate
  phylogenetic scale models or q4 interval support.

No spawned subagents were used.

## Implemented

`drm_wald_confint()` now converts non-finite or materially negative fixed-effect
variances to `NA` standard errors and marks those rows with
`conf.status = "wald_unavailable"`. The structured-effect rejection path now
adds a `sigma ~ phylo(...)`-specific note for univariate Gaussian scale
formulas. A bivariate Gaussian test confirms that matching `mu1`/`mu2` terms
with one label and matching `sigma1`/`sigma2` terms with another label fit as
two q2 covariance blocks, not as one q4 block. The convergence vignette now
guides users to compare optimizer-budget reruns and simplify boundary-heavy
random-effect or correlation structures.

## Mathematical Contract

No likelihood parameterization changed. The Wald change is an interval-table
guard: a variance that cannot support a real standard error no longer receives
finite-looking normal endpoints. The bivariate block-diagonal test preserves the
existing labelled-block interpretation: one label shared by `mu1` and `mu2`
estimates a mean-mean correlation, and a different label shared by `sigma1` and
`sigma2` estimates a scale-scale correlation.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `R/drmTMB.R`
- `R/profile.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-203121-codex-checkpoint.md`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-phylo-gaussian.R`
- `tests/testthat/test-profile-targets.R`
- `vignettes/convergence.Rmd`

## Checks Run

- `air format NEWS.md ROADMAP.md R/profile.R R/drmTMB.R tests/testthat/test-profile-targets.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-biv-gaussian.R vignettes/convergence.Rmd`
- `Rscript -e "devtools::test(filter = 'profile-targets|phylo-gaussian|biv-gaussian', reporter = 'summary')"`
- `Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/convergence.Rmd", output_dir = tempfile("convergence-render-"), quiet = FALSE)'`
- `rg -n 'Slice 279|Bergmann|wald_unavailable|sigma ~ phylo|q4 block-diagonal|long iteration|n_qgt2_blocks|largest fixed-effect Wald|block-diagonal q2' NEWS.md ROADMAP.md R/profile.R R/drmTMB.R tests/testthat/test-profile-targets.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-biv-gaussian.R vignettes/convergence.Rmd`
- `rg -n 'sigma ~ phylo.*fitted|univariate `?sigma`?.*phylo.*fitted|block-diagonal.*q4.*unsupported|boundary-NaN|NaN.*conf\\.status = "wald"|long iteration.*ignore|long iteration.*stronger evidence' README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat --glob '!docs/dev-log/**'`
- `rg -n 'meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]' README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat --glob '!docs/dev-log/**'`
- `rg -n 'sigma.*phylo|phylo.*sigma|q4.*block|block-diagonal|long iteration|wald_unavailable' README.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript tools/codex-checkpoint.R --goal "Slice 279 Bergmann report fixes" --next "stage, commit, push, and open draft PR"`

The focused tests passed. The convergence vignette rendered after loading the
package namespace, `pkgdown::check_pkgdown()` reported no problems, and
`git diff --check` reported no whitespace errors.

## Tests Of The Tests

The Wald-SE test mutates the fitted covariance matrix to contain a negative
variance and an infinite variance, then confirms both requested fixed-effect
rows are returned with `NA` endpoints and `wald_unavailable` status. The
phylogenetic-scale test reads the actual error object and checks both the
general structured-effect boundary and the targeted `sigma ~ phylo` text. The
block-diagonal bivariate test checks convergence, `n_qgt2_blocks = 0`, two
`corpairs()` rows, separate `mu` and `sigma` correlation blocks, no
location-scale rows, and no q4 `re_cov` profile targets.

## Consistency Audit

The status inventory already recorded univariate phylogenetic `sigma` terms as
planned while keeping the labelled bivariate q4 phylogenetic block as the fitted
four-endpoint route. The stale-claim scans found only intended negative wording,
the new targeted unsupported message, existing historical design boundaries, or
the expected `meta_known_V()` compatibility references. No current source claim
was found that univariate `sigma ~ phylo(...)` is fitted or that q4 derived
intervals are generally implemented.

## What Did Not Go Smoothly

This slice resumed after context compaction, so the first step was to trust the
repository state and rerun focused tests before adding the closure notes. The
new q2 fallback test was slow because it lives in the bivariate Gaussian file,
but it passed without needing a seed or expectation change.

## Team Learning

Rose should keep treating "known issue" slices as small verification bundles:
one guard for inference, one boundary message for unsupported syntax, one
neighbouring fitted-path test, and one reader-facing next step. Pat's useful
check here was whether the error message says what to try next, not only what
failed.

## Known Limitations

Univariate `sigma ~ phylo(...)` remains planned. The q4 block-diagonal test does
not add derived q4 interval support, a new covariance parameterization, or a
predictor-dependent phylogenetic correlation path. Wald intervals still depend
on the fitted covariance matrix when it is finite and non-negative enough to
support a real standard error.

## Next Actions

Stage, commit, push, and open the Slice 279 draft PR against Slice 278, then
move to Slice 280 for `meta_V(V = V)` hardening unless the 5 AM report cutoff
arrives first.
