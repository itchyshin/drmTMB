# Review-Lane Staging Manifest

Generated during the May 24, 2026 overnight follow-through after the requested
Slices 556-605 validation block.

This manifest turns the dirty-tree split audit into a more actionable staging
guide. It does not stage files. It names candidate review lanes and the files
or directory roots that should be considered together if a later agent or human
creates commits.

## Ground Rules

- Rerun `git status --short --branch`, `git diff --stat`, and
  `git diff --check` before staging any lane.
- Do not stage from broad globs without reviewing `git diff` for each file.
- Do not stage generated or ignored result directories unless the lane
  deliberately treats them as dev-log evidence.
- Keep the NB2 q1 formal route at `hold_smoke_only` unless the full
  500-replicate formal grid is run and reviewed.
- Do not open NB2 `sigma` phylogeny, zero-inflated NB2 phylogeny, q4 count
  covariance, or new formula grammar during staging.

## Lane A: pkgdown Home Logo And Rendered-Site Evidence

Committed locally as `fe204dd7` (`Scale pkgdown homepage logo`) during the
May 25 staging split. The shared `docs/dev-log/check-log.md` entries remain in
the dirty tree for a later patch-staging pass because that file contains many
other lane entries.

Candidate files:

```text
pkgdown/extra.css
docs/dev-log/figure-audits/2026-05-24-home-logo/
docs/dev-log/after-task/2026-05-24-pkgdown-home-logo-scale.md
docs/dev-log/after-task/2026-05-24-pkgdown-rendered-site-revalidation.md
```

Validation already recorded:

```text
pkgdown::check_pkgdown(): no problems
pkgdown::build_site(): completed
rendered stale-promotion scan: no hits
```

If staged alone, rerun `pkgdown::build_site()` only if the CSS or rendered
evidence changes again.

## Lane B: Phylogenetic Direct-SD And Corpair Combination

Candidate files:

```text
R/methods.R
R/random-effect-scale-formulas.R
tests/testthat/test-phylo-gaussian.R
tests/testthat/test-profile-targets.R
docs/design/16-phylo-spatial-common-math.md
docs/design/18-random-effect-scale-models.md
docs/design/20-coscale-correlation-pairs.md
docs/design/45-cross-dpar-correlation-gate.md
docs/dev-log/after-task/2026-05-24-phylo-direct-sd-corpair-combination.md
man/fixef.Rd
man/random_effect_scale_formulas.Rd
vignettes/phylogenetic-models.Rmd
vignettes/phylogenetic-spatial.Rmd
vignettes/which-scale.Rmd
```

Validation to rerun before staging:

```sh
Rscript -e "devtools::test(filter = 'phylo-gaussian|profile-targets', reporter = 'summary')"
git diff --check
```

## Lane C: NB2 Log-Sigma Random-Intercept Evidence

Candidate files:

```text
R/drmTMB.R
R/parse-formula.R
R/check.R
src/drmTMB.cpp
tests/testthat/test-phase18-nbinom2-sigma-random-effect.R
tests/testthat/test-nbinom2-location-scale.R
tests/testthat/test-check-drm.R
tests/testthat/test-control.R
inst/sim/dgp/sim_dgp_nbinom2_sigma_random_effect.R
inst/sim/fit/sim_summarise_nbinom2_sigma_random_effect.R
inst/sim/run/sim_run_nbinom2_sigma_random_effect_smoke.R
inst/sim/run/sim_summary_nbinom2_sigma_random_effect_smoke.R
inst/sim/run/sim_write_nbinom2_sigma_random_effect_grid.R
docs/design/73-phase-18-nbinom2-sigma-random-intercept-ademp.md
docs/dev-log/after-task/2026-05-24-nb2-log-sigma-smoke-grid-slices-511-525.md
docs/dev-log/after-task/2026-05-24-nb2-sigma-random-intercept.md
man/check_drm.Rd
man/drmTMB.Rd
man/nbinom2.Rd
```

Validation to rerun before staging:

```sh
Rscript -e "devtools::test(filter = 'phase18-nbinom2-sigma-random-effect|nbinom2-location-scale|nongaussian-scale-boundary|check-drm', reporter = 'summary')"
git diff --check
```

Some implementation files overlap with Lane D. If staging C and D separately,
use `git add -p` or split the changes carefully.

## Lane D: NB2 Phylogenetic q1 Mu Evidence

Candidate files:

```text
.github/workflows/phase18-simulation-grid.yaml
R/drmTMB.R
R/parse-formula.R
R/check.R
src/drmTMB.cpp
tests/testthat/test-phase18-nbinom2-phylo-q1.R
tests/testthat/test-nbinom2-location-scale.R
tests/testthat/test-check-drm.R
tests/testthat/test-control.R
inst/sim/README.md
inst/sim/run/sim_run_actions_cell.R
inst/sim/dgp/sim_dgp_nbinom2_phylo_q1.R
inst/sim/fit/sim_summarise_nbinom2_phylo_q1.R
inst/sim/run/sim_run_nbinom2_phylo_q1_smoke.R
inst/sim/run/sim_summary_nbinom2_phylo_q1_smoke.R
inst/sim/run/sim_write_nbinom2_phylo_q1_grid.R
docs/design/34-validation-debt-register.md
docs/design/41-phase-18-simulation-programme.md
docs/design/46-pre-simulation-readiness-matrix.md
docs/design/59-structural-slope-and-non-gaussian-map.md
docs/design/63-implementation-map-slices-311-325.md
docs/design/64-implementation-map-slices-326-340.md
docs/design/65-implementation-map-slices-341-355.md
docs/design/67-sdstar-p8-poisson-q1.md
docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md
docs/design/75-phase-18-nbinom2-phylo-q1-formal-audit.md
docs/dev-log/after-task/2026-05-24-nb2-phylo-q1-formal-slices-526-540.md
docs/dev-log/after-task/2026-05-24-nb2-phylo-q1-formal-audit-slices-541-555.md
vignettes/implementation-map.Rmd
vignettes/source-map.Rmd
```

Validation to rerun before staging:

```sh
Rscript -e "devtools::test(filter = 'phase18-nbinom2-phylo-q1|nbinom2-location-scale|nongaussian-structured-boundary', reporter = 'summary')"
rg -n 'NB2.*q1.*formal recovery.*(now|passed|complete|closed)|NB2.*q1.*coverage.*(now|passed|complete|closed)|nbinom2_phylo_q1.*promote_narrowly|broad NB2 structured.*(ready|now)|NB2 sigma phylogeny.*now|zero-inflated NB2 phylogeny.*now|count covariance.*now' NEWS.md ROADMAP.md README.md inst/sim/README.md docs/design vignettes tests -g '!*.html'
git diff --check
```

## Lane E: Ayumi/Santi Developer Handoff

Committed locally as `ca2650e9`
(`Add Ayumi Santi simulated handoff artifacts`) during the May 25 staging
split. The lane includes the full simulated-only `docs/dev-log/ayumi-santi/`
evidence bundle named below.

Candidate files and directory roots:

```text
tools/ayumi-santi-q2-objective1-runner.R
tools/ayumi-santi-q2-positive-control.R
tools/ayumi-santi-finish-sim-slices.R
docs/design/76-ayumi-santi-phylo-model-improvement-path.md
docs/design/77-ayumi-santi-protocol-formula-gallery.md
docs/design/78-ayumi-santi-q2-objective1-positive-control.md
docs/design/79-ayumi-santi-no-real-data-sim-slices.md
docs/dev-log/after-task/2026-05-24-ayumi-santi-phylo-improvement-path.md
docs/dev-log/after-task/2026-05-24-ayumi-santi-protocol-formula-gallery.md
docs/dev-log/after-task/2026-05-24-ayumi-santi-q2-objective1-runner.md
docs/dev-log/after-task/2026-05-24-ayumi-santi-q2-positive-control.md
docs/dev-log/after-task/2026-05-24-ayumi-santi-no-real-data-sim-slices.md
docs/dev-log/ayumi-santi/
```

Validation to rerun before staging:

```sh
Rscript --vanilla -e 'invisible(parse(file = "tools/ayumi-santi-q2-objective1-runner.R")); invisible(parse(file = "tools/ayumi-santi-q2-positive-control.R")); invisible(parse(file = "tools/ayumi-santi-finish-sim-slices.R")); cat("parse ok\n")'
Rscript -e "devtools::test(filter = 'phylo-gaussian', reporter = 'summary')"
git diff --check
```

This lane is simulated-only and developer-only. Do not make biological claims
from it.

## Lane F: Overnight Validation, Recovery, And Process Notes

Candidate files:

```text
docs/design/80-phase-18-shared-runner-migration-audit.md
docs/design/81-phase-18-validation-slices-579-605.md
docs/dev-log/audits/2026-05-24-overnight-dirty-tree-split-audit.md
docs/dev-log/audits/2026-05-24-review-lane-staging-manifest.md
docs/dev-log/after-task/2026-05-24-phase18-shared-runner-migration-slices-556-578.md
docs/dev-log/after-task/2026-05-24-phase18-validation-slices-579-605.md
docs/dev-log/after-task/2026-05-24-dirty-tree-split-audit.md
docs/dev-log/after-task/2026-05-24-overnight-process-guardrails.md
docs/dev-log/check-log.md
docs/dev-log/team-improvements.md
```

Recovery checkpoints under `docs/dev-log/recovery-checkpoints/` are local
handoff aids and should remain untracked unless the maintainer explicitly wants
one included.

Validation already recorded:

```text
devtools::test(): passed
pkgdown::check_pkgdown(): no problems
pkgdown::build_site(): completed
devtools::check(error_on = "never"): 0 errors, 0 warnings, 0 notes
git diff --check: clean
```

## May 25 Resume Addendum

The May 25 resume pass found the checkout still on
`codex/nb2-poisson-structured-gates-actions`, with the local branch behind its
upstream by 13 commits and the dirty tree extended beyond the original May 24
manifest. Do not pull, merge, rebase, or push from this state until the dirty
work is either committed into review lanes or intentionally stashed by the
project owner.

The newest completed local task is the fixed-effect ordinal artifact lane.
That after-task report names the current next action: split or stage the dirty
Phase 18 tree into reviewable PR lanes before adding more likelihood surfaces.

## Lane G: First-Wave Summary And Runner Infrastructure

Candidate files:

```text
inst/sim/run/sim_run_first_wave_summary_smoke.R
tests/testthat/test-phase18-first-wave-summary-smoke-runner.R
docs/design/82-phase-18-validation-slices-606-628.md
docs/design/83-phase-18-closure-aware-summary-factory-slices-629-638.md
docs/design/84-phase-18-post-closure-validation-slices-639-655.md
docs/design/85-phase-18-post-closure-validation-slices-656-668.md
docs/design/86-phase-18-bounded-runner-roadmap-sync-slices-669-678.md
docs/design/87-phase-18-wrapper-forwarding-slices-679-688.md
docs/design/88-phase-18-nested-parallel-guard-slices-689-698.md
docs/design/89-phase-18-meta-v-grid-output-slices-699-708.md
docs/design/90-phase-18-count-mu-re-grid-output-slices-709-718.md
docs/design/91-phase-18-simple-random-slope-grid-output-slices-719-728.md
docs/design/92-phase-18-grid-artifact-manifest-slices-729-738.md
docs/design/93-phase-18-artifact-status-summary-slices-739-748.md
docs/design/94-phase-18-first-wave-artifact-status-writer-slices-749-758.md
docs/design/95-phase-18-first-wave-status-report-slices-759-768.md
docs/design/96-phase-18-first-wave-table-bundle-slices-769-778.md
docs/design/97-phase-18-first-wave-summary-report-slices-779-788.md
docs/design/98-phase-18-first-wave-summary-render-helper-slices-789-798.md
docs/design/99-phase-18-first-wave-summary-smoke-slices-809-818.md
docs/design/100-phase-18-first-wave-summary-polished-smoke-slices-819-828.md
docs/design/101-phase-18-first-wave-summary-count-smoke-slices-829-838.md
docs/design/102-phase-18-first-wave-summary-table-polish-slices-839-848.md
docs/design/103-phase-18-first-wave-summary-warning-smoke-slices-849-858.md
docs/design/104-phase-18-first-wave-summary-bias-overview-slices-859-868.md
docs/design/105-phase-18-first-wave-summary-interval-coverage-slices-869-878.md
docs/design/106-phase-18-first-wave-summary-manifest-smoke-slices-879-888.md
docs/design/107-phase-18-first-wave-summary-nrep2-revalidation-slices-889-898.md
docs/design/108-phase-18-first-wave-summary-runner-revalidation-slices-899-908.md
docs/dev-log/after-task/2026-05-24-phase18-validation-slices-606-628.md
docs/dev-log/after-task/2026-05-24-phase18-closure-aware-summary-factory-slices-629-638.md
docs/dev-log/after-task/2026-05-24-phase18-post-closure-validation-slices-639-655.md
docs/dev-log/after-task/2026-05-24-phase18-post-closure-validation-slices-656-668.md
docs/dev-log/after-task/2026-05-24-phase18-bounded-runner-roadmap-sync-slices-669-678.md
docs/dev-log/after-task/2026-05-24-phase18-wrapper-forwarding-slices-679-688.md
docs/dev-log/after-task/2026-05-24-phase18-nested-parallel-guard-slices-689-698.md
docs/dev-log/after-task/2026-05-24-phase18-meta-v-grid-output-slices-699-708.md
docs/dev-log/after-task/2026-05-24-phase18-count-mu-re-grid-output-slices-709-718.md
docs/dev-log/after-task/2026-05-24-phase18-simple-random-slope-grid-output-slices-719-728.md
docs/dev-log/after-task/2026-05-24-phase18-grid-artifact-manifest-slices-729-738.md
docs/dev-log/after-task/2026-05-24-phase18-artifact-status-summary-slices-739-748.md
docs/dev-log/after-task/2026-05-24-phase18-first-wave-artifact-status-writer-slices-749-758.md
docs/dev-log/after-task/2026-05-24-phase18-first-wave-status-report-slices-759-768.md
docs/dev-log/after-task/2026-05-24-phase18-first-wave-table-bundle-slices-769-778.md
docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-report-slices-779-788.md
docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-render-helper-slices-789-798.md
docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-smoke-slices-809-818.md
docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-polished-smoke-slices-819-828.md
docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-count-smoke-slices-829-838.md
docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-table-polish-slices-839-848.md
docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-warning-smoke-slices-849-858.md
docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-bias-overview-slices-859-868.md
docs/dev-log/after-task/2026-05-24-phase18-first-wave-summary-interval-coverage-slices-869-878.md
docs/dev-log/after-task/2026-05-25-phase18-first-wave-summary-manifest-smoke-slices-879-888.md
docs/dev-log/after-task/2026-05-25-phase18-first-wave-summary-nrep2-revalidation-slices-889-898.md
docs/dev-log/after-task/2026-05-25-phase18-first-wave-summary-runner-revalidation-slices-899-908.md
```

Validation to rerun before staging:

```sh
Rscript -e "devtools::test(filter = '^phase18-(first-wave-summary-report|first-wave-summary-render-helper|first-wave-summary-smoke-runner)$', reporter = 'summary')"
git diff --check
```

This lane is reporting and runner infrastructure. Do not turn one- or
two-replicate smoke artifacts into final operating-characteristic claims.

## Lane H: Current-State Revalidation And Core-Family Completion Map

Candidate files:

```text
docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md
docs/dev-log/after-task/2026-05-25-phase18-core-family-completion-map-slices-1279-1288.md
docs/dev-log/after-task/2026-05-25-phase18-current-state-revalidation-slices-909-1008.md
docs/design/41-phase-18-simulation-programme.md
docs/dev-log/check-log.md
```

Validation already recorded:

```text
Rscript -e "devtools::test(filter = '^phase18-', reporter = 'summary')": passed
```

If staged alone, rerun the focused `^phase18-` suite and keep the status answer
explicit: non-Gaussian support is partial, with ordinary Poisson/NB2 mixed
effects and q=1 phylogenetic `mu` intercept gates separate from broader
structured non-Gaussian random-effect covariance.

## Lane I: Core Fixed-Effect Family Artifacts

Candidate files:

```text
.github/workflows/phase18-simulation-grid.yaml
inst/sim/README.md
inst/sim/run/sim_run_actions_cell.R
inst/sim/run/sim_run_first_wave_summary_smoke.R
inst/sim/dgp/sim_dgp_proportion_fixed_effect.R
inst/sim/dgp/sim_dgp_positive_continuous_fixed_effect.R
inst/sim/dgp/sim_dgp_ordinal_fixed_effect.R
inst/sim/fit/sim_summarise_proportion_fixed_effect.R
inst/sim/fit/sim_summarise_positive_continuous_fixed_effect.R
inst/sim/fit/sim_summarise_ordinal_fixed_effect.R
inst/sim/run/sim_run_proportion_fixed_effect_smoke.R
inst/sim/run/sim_run_positive_continuous_fixed_effect_smoke.R
inst/sim/run/sim_run_ordinal_fixed_effect_smoke.R
inst/sim/run/sim_summary_proportion_fixed_effect_smoke.R
inst/sim/run/sim_summary_positive_continuous_fixed_effect_smoke.R
inst/sim/run/sim_summary_ordinal_fixed_effect_smoke.R
inst/sim/run/sim_write_proportion_fixed_effect_grid.R
inst/sim/run/sim_write_positive_continuous_fixed_effect_grid.R
inst/sim/run/sim_write_ordinal_fixed_effect_grid.R
tests/testthat/test-phase18-proportion-fixed-effect.R
tests/testthat/test-phase18-positive-continuous-fixed-effect.R
tests/testthat/test-phase18-ordinal-fixed-effect.R
tests/testthat/test-phase18-actions-runner.R
tests/testthat/test-phase18-first-wave-summary-smoke-runner.R
docs/design/110-phase-18-proportion-fixed-effect-artifacts-slices-1289-1298.md
docs/design/111-phase-18-positive-continuous-fixed-effect-artifacts-slices-1299-1308.md
docs/design/112-phase-18-ordinal-fixed-effect-artifacts-slices-1309-1318.md
docs/design/51-phase-18-ordinal-fixed-effect-ademp.md
docs/design/46-pre-simulation-readiness-matrix.md
docs/design/34-validation-debt-register.md
docs/dev-log/after-task/2026-05-25-phase18-proportion-fixed-effect-artifacts-slices-1289-1298.md
docs/dev-log/after-task/2026-05-25-phase18-positive-continuous-fixed-effect-artifacts-slices-1299-1308.md
docs/dev-log/after-task/2026-05-25-phase18-ordinal-fixed-effect-artifacts-slices-1309-1318.md
NEWS.md
ROADMAP.md
```

Validation to rerun before staging:

```sh
Rscript -e "devtools::test(filter = '^phase18-(proportion-fixed-effect|positive-continuous-fixed-effect|ordinal-fixed-effect|first-wave-summary-smoke-runner|actions-runner)$', reporter = 'summary')"
ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f); puts "ok #{f}" }' .github/workflows/phase18-simulation-grid.yaml
rg -n 'proportion.*(still need|needs).*DGP|positive-continuous.*(still need|needs).*DGP|ordinal.*(still need|needs).*DGP|cumulative_logit.*still need.*DGP|fixed-effect ordinal.*(still need|needs).*grid' README.md ROADMAP.md NEWS.md docs/design inst/sim tests/testthat -g '!*.html'
git diff --check
```

This can be split into three commits if needed: proportion, positive
continuous, and ordinal. If split that finely, `inst/sim/run/sim_run_actions_cell.R`,
`inst/sim/run/sim_run_first_wave_summary_smoke.R`,
`.github/workflows/phase18-simulation-grid.yaml`, `NEWS.md`, `ROADMAP.md`, and
`docs/dev-log/check-log.md` need patch staging.

## Lane J: Phylogenetic Direct-SD Public Syntax Cleanup

Candidate files:

```text
README.md
vignettes/drmTMB.Rmd
vignettes/implementation-map.Rmd
vignettes/model-map.Rmd
vignettes/phylogenetic-models.Rmd
vignettes/phylogenetic-spatial.Rmd
vignettes/structural-dependence.Rmd
vignettes/which-scale.Rmd
docs/design/34-validation-debt-register.md
docs/design/46-pre-simulation-readiness-matrix.md
docs/design/51-phase-18-ordinal-fixed-effect-ademp.md
docs/dev-log/after-task/2026-05-25-phylogenetic-direct-sd-public-syntax-cleanup.md
```

Validation to rerun before staging:

```sh
rg -n 'sd_phylo\(|sd_phylo1\(|sd_phylo2\(|sd_phylo\*' README.md vignettes docs/design docs/dev-log/check-log.md NEWS.md
Rscript -e "pkgdown::build_article('phylogenetic-models', new_process = FALSE)"
rg -n 'sd\(species, level = "phylogenetic"\)|sd1\(species, level = "phylogenetic"\)|sd2\(species, level = "phylogenetic"\)' pkgdown-site/articles/phylogenetic-models.html
git diff --check
```

Keep historical `sd_phylo*()` mentions only where they explicitly describe
compatibility, deprecated aliases, or old after-task evidence.

## Shared Files To Handle Carefully

These files carry changes from more than one lane and should not be blindly
staged with a single lane:

```text
NEWS.md
ROADMAP.md
README.md
docs/dev-log/check-log.md
docs/dev-log/team-improvements.md
R/drmTMB.R
R/parse-formula.R
R/check.R
src/drmTMB.cpp
.github/workflows/phase18-simulation-grid.yaml
tests/testthat/test-check-drm.R
tests/testthat/test-control.R
tests/testthat/test-phase18-actions-runner.R
tests/testthat/test-phase18-first-wave-summary-smoke-runner.R
tests/testthat/test-nbinom2-location-scale.R
inst/sim/README.md
inst/sim/run/sim_run_actions_cell.R
inst/sim/run/sim_run_first_wave_summary_smoke.R
vignettes/source-map.Rmd
vignettes/implementation-map.Rmd
```

Use patch staging for these files if the branch is split into multiple commits.
