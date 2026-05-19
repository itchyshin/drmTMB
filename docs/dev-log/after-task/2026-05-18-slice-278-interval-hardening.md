# Slice 278 interval hardening

Date: 2026-05-18

Goal: close the pre-simulation interval-hardening checkpoint by making the
current fitted-model and Phase 18 interval routes explicit, without changing
likelihood code or adding a broad interval engine.

## Standing perspectives

- Ada kept the slice narrow: tests and documentation, not new profile logic.
- Fisher checked the inference boundary between Wald, profile, Fisher-z, and
  bootstrap intervals.
- Curie focused the tests on contract coverage that should remain fast enough
  for ordinary package validation.
- Pat checked that applied users can tell fixed-effect link-scale intervals from
  response-scale profile intervals.
- Grace checked pkgdown and vignette rendering.
- Rose checked that no public claim says Fisher-z Wald intervals are the fitted
  `confint()` default or that derived variance/covariance intervals are done.

No spawned subagents were used.

## Files changed

- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/design/43-phase-18-interval-producer-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-201509-codex-checkpoint.md`
- `tests/testthat/test-phase18-sim-uncertainty.R`
- `tests/testthat/test-profile-targets.R`
- `vignettes/model-workflow.Rmd`

## What changed

- Added a Student-t interval-inventory test confirming that fitted `nu ~ x`
  contributes direct fixed-effect `fixef:nu:*` targets, that those targets stay
  on the link scale, and that `confint(..., parm = "nu:x")` returns a Wald row.
- Extended the Phase 18 correlation interval-helper test to cover supplied
  Fisher-z-scale standard errors, custom endpoint column names, bounded
  back-transformed endpoints, and recorded `std.error.scale`.
- Updated the workflow vignette, README, profile-CI design note, and Phase 18
  interval producer contract to separate fitted-model Wald/profile intervals
  from Fisher-z simulation-table producers.
- Marked Slice 278 done in the roadmap and added a NEWS bullet for the
  user-facing interval-status clarification.

## Checks run

- `air format NEWS.md README.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/design/43-phase-18-interval-producer-contract.md tests/testthat/test-phase18-sim-uncertainty.R tests/testthat/test-profile-targets.R vignettes/model-workflow.Rmd`
- `Rscript -e "devtools::test(filter = 'profile-targets|phase18-sim-uncertainty', reporter = 'summary')"`
- `Rscript -e 'devtools::load_all(quiet = TRUE); rmarkdown::render("vignettes/model-workflow.Rmd", output_dir = tempfile("model-workflow-render-"), quiet = FALSE)'`
- `rg -n 'Slice 278|Student-t `nu`|fixef:nu:x|Fisher-z|fisher_z_backtransformed|phase18_add_correlation_fisher_z_intervals|derived_interval_unavailable|bootstrap intervals|Interval hardening' NEWS.md README.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/design/43-phase-18-interval-producer-contract.md tests/testthat/test-phase18-sim-uncertainty.R tests/testthat/test-profile-targets.R vignettes/model-workflow.Rmd`
- `rg -n 'Fisher-z.*confint\(\).*default|Fisher-z.*fitted-model|bootstrap intervals are implemented|derived.*interval.*implemented|response-scale `nu`.*profile-ready|`nu`.*response-scale.*confint|variance.*profile.*implemented for all|q4.*profile.*implemented' README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat --glob '!docs/dev-log/**'`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript tools/codex-checkpoint.R --goal "Slice 278 interval hardening" --next "stage, commit, push, and open draft PR"`

The stale-claim scan returned only negative, planned-boundary, or historical
status wording; no current source claim says Fisher-z Wald intervals are the
public fitted-model default, bootstrap intervals are implemented, or derived
variance/covariance intervals are generally available.

A plain `rmarkdown::render("vignettes/model-workflow.Rmd")` failed because the
package namespace was not loaded in that ad hoc render process; the rerun with
`devtools::load_all()` passed.

## Known limitations

- No new public fitted-model Fisher-z interval method was added.
- No response-scale Student-t `nu` profile target was added.
- Derived variance, covariance-product, q4 correlation, repeatability, and
  phylogenetic-signal intervals remain unavailable until a validated derived
  interval method exists.
- Bootstrap intervals remain planned.

## Next safest step

Move to Slice 279 and treat the Bergmann-report items as separate fixes:
boundary-NaN SE propagation, q=4 block-diagonal fallback, univariate
`sigma ~ phylo()`, and long-iteration guidance should not be collapsed into the
interval-hardening PR.
