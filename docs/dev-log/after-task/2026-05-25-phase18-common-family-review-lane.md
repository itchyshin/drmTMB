# After Task: Phase 18 Common-Family Review Lane

## Goal

Split the fixed-effect proportion, positive-continuous, and ordinal Phase 18
artifact work into a reviewable stacked branch on top of PR #324 without
including unrelated NB2 formal-audit, Ayumi/Santi, pkgdown-logo, or
phylogenetic direct-SD dirty-tree lanes.

## Implemented

Created branch `codex/phase18-common-family-artifacts` in
`/private/tmp/drmTMB-common-family-artifacts`. The branch adds DGP, summariser,
smoke, summary, grid-writer, first-wave summary, manual Actions dispatch,
focused tests, design notes, NEWS, ROADMAP, simulation README, check-log, and
after-task evidence for three fixed-effect lanes:

- `beta()` and `beta_binomial()` proportions;
- `lognormal()` and `Gamma(link = "log")` positive-continuous responses;
- `cumulative_logit()` ordinal responses.

## Mathematical Contract

No likelihood parameterization changed. The branch adds simulation artifacts for
already fitted fixed-effect families. Proportion models use `logit(mu)` and
`log(sigma)` coefficients; lognormal uses `mu` as log-response location; Gamma
uses `mu` as response mean and `sigma` as coefficient of variation; ordinal
uses ordered cutpoints and an identifiable no-intercept latent `mu` slope.

## Files Changed

The lane changes the Phase 18 runner/workflow files, three focused test files,
three DGP files, three fit-summariser files, nine run/summary/grid files, four
design notes, simulation README, NEWS, ROADMAP, check-log, and the prior
per-lane after-task reports.

## Checks Run

```sh
air format .github/workflows/phase18-simulation-grid.yaml NEWS.md ROADMAP.md docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/51-phase-18-ordinal-fixed-effect-ademp.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/110-phase-18-proportion-fixed-effect-artifacts-slices-1289-1298.md docs/design/111-phase-18-positive-continuous-fixed-effect-artifacts-slices-1299-1308.md docs/design/112-phase-18-ordinal-fixed-effect-artifacts-slices-1309-1318.md docs/dev-log/after-task/2026-05-25-phase18-core-family-completion-map-slices-1279-1288.md docs/dev-log/after-task/2026-05-25-phase18-proportion-fixed-effect-artifacts-slices-1289-1298.md docs/dev-log/after-task/2026-05-25-phase18-positive-continuous-fixed-effect-artifacts-slices-1299-1308.md docs/dev-log/after-task/2026-05-25-phase18-ordinal-fixed-effect-artifacts-slices-1309-1318.md inst/sim/README.md inst/sim/dgp/sim_dgp_proportion_fixed_effect.R inst/sim/dgp/sim_dgp_positive_continuous_fixed_effect.R inst/sim/dgp/sim_dgp_ordinal_fixed_effect.R inst/sim/fit/sim_summarise_proportion_fixed_effect.R inst/sim/fit/sim_summarise_positive_continuous_fixed_effect.R inst/sim/fit/sim_summarise_ordinal_fixed_effect.R inst/sim/run/sim_run_proportion_fixed_effect_smoke.R inst/sim/run/sim_run_positive_continuous_fixed_effect_smoke.R inst/sim/run/sim_run_ordinal_fixed_effect_smoke.R inst/sim/run/sim_summary_proportion_fixed_effect_smoke.R inst/sim/run/sim_summary_positive_continuous_fixed_effect_smoke.R inst/sim/run/sim_summary_ordinal_fixed_effect_smoke.R inst/sim/run/sim_write_proportion_fixed_effect_grid.R inst/sim/run/sim_write_positive_continuous_fixed_effect_grid.R inst/sim/run/sim_write_ordinal_fixed_effect_grid.R inst/sim/run/sim_run_first_wave_summary_smoke.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-proportion-fixed-effect.R tests/testthat/test-phase18-positive-continuous-fixed-effect.R tests/testthat/test-phase18-ordinal-fixed-effect.R tests/testthat/test-phase18-first-wave-summary-smoke-runner.R tests/testthat/test-phase18-actions-runner.R
Rscript -e "devtools::test(filter = '^phase18-(proportion-fixed-effect|positive-continuous-fixed-effect|ordinal-fixed-effect|first-wave-summary-smoke-runner|actions-runner)$', reporter = 'summary')"
ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f); puts "ok #{f}" }' .github/workflows/phase18-simulation-grid.yaml
Rscript -e "files <- c('inst/sim/dgp/sim_dgp_proportion_fixed_effect.R','inst/sim/dgp/sim_dgp_positive_continuous_fixed_effect.R','inst/sim/dgp/sim_dgp_ordinal_fixed_effect.R','inst/sim/fit/sim_summarise_proportion_fixed_effect.R','inst/sim/fit/sim_summarise_positive_continuous_fixed_effect.R','inst/sim/fit/sim_summarise_ordinal_fixed_effect.R','inst/sim/run/sim_run_proportion_fixed_effect_smoke.R','inst/sim/run/sim_run_positive_continuous_fixed_effect_smoke.R','inst/sim/run/sim_run_ordinal_fixed_effect_smoke.R','inst/sim/run/sim_summary_proportion_fixed_effect_smoke.R','inst/sim/run/sim_summary_positive_continuous_fixed_effect_smoke.R','inst/sim/run/sim_summary_ordinal_fixed_effect_smoke.R','inst/sim/run/sim_write_proportion_fixed_effect_grid.R','inst/sim/run/sim_write_positive_continuous_fixed_effect_grid.R','inst/sim/run/sim_write_ordinal_fixed_effect_grid.R','inst/sim/run/sim_run_first_wave_summary_smoke.R','inst/sim/run/sim_run_actions_cell.R','tests/testthat/test-phase18-proportion-fixed-effect.R','tests/testthat/test-phase18-positive-continuous-fixed-effect.R','tests/testthat/test-phase18-ordinal-fixed-effect.R','tests/testthat/test-phase18-first-wave-summary-smoke-runner.R','tests/testthat/test-phase18-actions-runner.R'); invisible(lapply(files, parse)); cat('ok parse\n')"
rg -n 'proportion.*(still need|needs).*DGP|beta.*still need.*DGP|beta_binomial.*still need.*DGP|positive-continuous.*(still need|needs).*DGP|lognormal.*still need.*DGP|Gamma.*still need.*DGP|ordinal.*(still need|needs).*DGP|cumulative_logit.*still need.*DGP|fixed-effect ordinal.*(still need|needs).*grid|Promote fixed-effect ordinal artifacts|next.*ordinal artifacts|Make proportions the next implementation lane|add positive-continuous lognormal/Gamma artifacts' README.md ROADMAP.md NEWS.md docs/design inst/sim tests/testthat -g '!*.html'
git diff --check
```

All checks passed. The focused test bundle completed with no failures, YAML and
R parses succeeded, the stale-wording scan returned no hits, and `git diff
--check` was clean.

## Tests Of The Tests

The focused tests cover DGP reproducibility, response support, live smoke fits,
artifact row counts, Wald rows, first-wave summary inclusion, manual Actions
dry-run routing, malformed inputs, and overwrite guards.

## Consistency Audit

The branch keeps the implemented claim fixed-effect only. It does not add
bounded-response random effects, positive-response random effects, ordinal
mixed models, structured non-Gaussian effects, mixed-response families,
skew-normal, Tweedie, or generalized Gamma support.

## GitHub Issue Maintenance

No issue mutation was done from this stacked branch. The prior per-lane issue
searches for proportion, positive-continuous, and ordinal Phase 18 artifacts
returned no direct open issues.

## What Did Not Go Smoothly

The first split attempt showed that the old staging manifest did not yet include
the common-family lane. Ada built the review branch in a separate worktree so
the original dirty checkout remains recoverable and the unrelated lanes stay
out of the commit.

## Team Learning

Ada should turn split audits into stacked branches when an open PR is already
conflicting with `main`. Grace should check workflow and runner task surfaces
before package tests. Rose should scan not only source docs, but also old
planning notes that can still say an artifact is missing after the follow-up
slice lands. These were role perspectives in this thread; no spawned subagents
were running.

## Known Limitations

This branch is stacked on PR #324. It should be reviewed against
`codex/nb2-poisson-structured-gates-actions`, and it will remain blocked for
mainline merge until the base PR conflict is resolved.

## Next Actions

Push the stacked branch and open a draft PR against
`codex/nb2-poisson-structured-gates-actions`. Then handle the separate
phylogenetic direct-SD/pkgdown webpage lane so the public site can deploy the
newer `sd(..., level = "phylogenetic")` wording.
