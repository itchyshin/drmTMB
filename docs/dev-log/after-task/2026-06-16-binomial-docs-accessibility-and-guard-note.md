# After Task: Binomial Docs Accessibility And Numerical Guard Note

## Goal

Make the bounded-response documentation reflect the merged plain
Bernoulli/binomial first slice, and record Hao Qin's numerical-guard concern as
a simulation-audit commitment.

## Implemented

The `Proportions and success rates` tutorial now routes applied readers through
four bounded-response choices:

```text
0/1 event or ordinary successes out of known trials -> stats::binomial()
overdispersed successes out of known trials -> beta_binomial()
continuous proportions strictly inside (0, 1) -> beta()
continuous proportions on [0, 1] with structural exact boundaries -> zero_one_beta()
```

The tutorial adds a small fixed-effect ordinary binomial event-probability
example using `stats::binomial(link = "logit")`, and it tells users to use
`cbind(successes, failures)` rather than `weights = trials`,
`successes / trials`, or `cbind(successes, trials)`.

The design and evidence maps now list `stats::binomial(link = "logit")` as a
fitted fixed-effect route with no public `sigma`, no random effects, no
structured effects, and no Julia bridge claim.

The numerical-guard note classifies constants and floors as domain transforms,
model-defining restrictions, starting-value safeguards, density-domain floors,
tail log floors, or likelihood-altering guards. It sets the future simulation
rule: a likelihood-altering guard can be useful as a diagnostic safeguard, but
it cannot upgrade a guarded fit into an inference claim.

## Mathematical Contract

The plain binomial tutorial states the fitted model as:

```text
Y_i | n_i, mu_i ~ Binomial(n_i, mu_i)
logit(mu_i) = beta_0 + beta_1 canopy_i + beta_2 NDVI_i
E[Y_i / n_i] = mu_i
Var(Y_i / n_i) = mu_i * (1 - mu_i) / n_i
```

For 0/1 data, `n_i = 1`. For success counts, `n_i = successes_i + failures_i`.
This route has ordinary binomial sampling variation only. Extra-binomial
variation belongs to `beta_binomial()` through its public `sigma`.

## Files Changed

- `vignettes/proportion-beta-binomial.Rmd`
- `vignettes/distribution-families.Rmd`
- `vignettes/model-map.Rmd`
- `docs/design/03-likelihoods.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/design/79-supported-nongaussian-evidence-goal.md`
- `docs/design/116-nongaussian-tutorial-gate-slices-1349-1358.md`
- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/dev-log/team-improvements.md`

## Checks Run

```sh
air format vignettes/proportion-beta-binomial.Rmd vignettes/distribution-families.Rmd vignettes/model-map.Rmd
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); out <- tempfile("proportion-binomial-", fileext = ".html"); rmarkdown::render("vignettes/proportion-beta-binomial.Rmd", output_file = out, quiet = TRUE); cat(out, "\n")'
Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-binomial-response.R", reporter = "summary")'
Rscript --vanilla -e 'pkgdown::check_pkgdown()'
Rscript --vanilla -e 'devtools::test()'
Rscript --vanilla -e 'devtools::check(error_on = "never", document = FALSE)'
git diff --check
rg -n '^(<<<<<<<|=======|>>>>>>>)' . --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**'
rg hard-framing terms over the touched current docs and vignette files
rg -n '^successes out of known trials -> beta_binomial\(\)|Counted successes out of trials \|.*`beta_binomial\(\)`' vignettes/proportion-beta-binomial.Rmd vignettes/distribution-families.Rmd vignettes/model-map.Rmd docs/design/37-worked-example-inventory.md docs/design/116-nongaussian-tutorial-gate-slices-1349-1358.md docs/design/79-supported-nongaussian-evidence-goal.md
rg -n 'Numerical Guard Simulation Audit|Hao Qin|likelihood-altering|logsigma_clamp|guard_sensitivity' docs/design/176-numerical-guard-simulation-audit.md docs/dev-log/team-improvements.md
```

Results:

- The updated proportion tutorial rendered to a temporary HTML file.
- Focused `test-binomial-response.R` passed.
- Full `devtools::test()` passed with 0 failures, 8 known log-sigma-clamp
  warnings, 5 existing Julia bridge/sigma-phylo skips, and 11174 passes.
- `devtools::check(error_on = "never", document = FALSE)` finished with
  0 errors, 0 warnings, and 0 notes. The package check was already running when
  the numerical-guard Markdown note was added; subsequent Markdown, whitespace,
  conflict, and grep scans covered that note.
- `pkgdown::check_pkgdown()` remains blocked by the pre-existing
  Claude-owned penalty/MAP docs seam: `_pkgdown.yml` is missing
  `drm_phylo_penalty`.
- The touched-file hard-framing scan returned no hits.
- The stale unconditional route
  `successes out of known trials -> beta_binomial()` returned no hits in the
  current tutorial/design routes.

## Tests Of The Tests

The focused binomial test file already checks the fitted fixed-effect
binomial likelihood, method surface, malformed neighbours, and `stats::glm()`
parity. The rendered tutorial exercises the new reader-facing example with the
current package source loaded. The numerical-guard note is a planning artifact;
its tests belong to a later simulation lane, not to this documentation slice.

## Consistency Audit

The tutorial, family guide, model map, worked-example inventory, likelihood
design note, and supported-non-Gaussian evidence map now agree that ordinary
binomial event probabilities use `stats::binomial(link = "logit")`, while
overdispersed success counts use `beta_binomial()`.

No `src/drmTMB.cpp`, `R/drmTMB.R`, Gaussian clamp, penalty/MAP, Ayumi, or
DRM.jl code path was changed.

## GitHub Issue Maintenance

- `#569`: posted the docs/accessibility PR link and restated the fixed-effect
  native TMB boundary:
  https://github.com/itchyshin/drmTMB/issues/569#issuecomment-4723968820
- `#60`: posted the comparator/evidence breadcrumb, keeping `stats::glm()`
  parity as the first comparator evidence and leaving interval-calibration
  claims to the simulation programme:
  https://github.com/itchyshin/drmTMB/issues/60#issuecomment-4723968828
- `#59`: posted the numerical-guard simulation-audit breadcrumb:
  https://github.com/itchyshin/drmTMB/issues/59#issuecomment-4723968812

## What Did Not Go Smoothly

`pkgdown::check_pkgdown()` is still blocked by a neighbouring `_pkgdown.yml`
index entry for `drm_phylo_penalty`. This slice did not touch that Claude-owned
penalty/MAP seam.

The full package test and check runs were long because they exercised the
Phase 18 and Julia-bridge guard suites, but they finished cleanly.

## Team Learning

Hao Qin's critique improves the release standard: constants in the C++ AD path
must not be treated as harmless by default. They need classification, tests, and
simulation sensitivity checks. The new design note makes that a future
simulation deliverable.

## Known Limitations

Plain binomial support remains fixed-effect native TMB only. Random effects,
structured effects, bivariate/mixed responses, interval-calibration claims,
speed claims, and the Julia bridge remain unsupported or planned.

The numerical-guard note does not prove that guards have negligible impact. It
only records the audit contract for the larger simulation programme.

## Next Actions

- Open the documentation PR and link it to `#569` and the comparator/evidence
  queue.
- Add a numerical-guard sensitivity lane to the big simulation programme before
  guard-dependent routes are used for promotion claims.
- Leave the `drm_phylo_penalty` pkgdown seam to the Claude-owned penalty/MAP
  slice.
