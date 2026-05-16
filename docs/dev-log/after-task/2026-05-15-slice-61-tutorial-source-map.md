# Slice 61 Tutorial Source Map

## Goal

Open Phase 6b with a source-map artifact that makes the tutorial upgrade
biological and mathematical, not just navigational. The immediate requirement
was to record how later tutorial slices should interpret different kinds of
slopes, variance components, `sd(group)`, residual `rho12`, and group-level
`corpairs()` rows.

## Implemented

- Added `docs/design/32-phase-6b-tutorial-source-map.md`.
- Linked that source map from `docs/design/21-tutorial-style.md`.
- Marked Slice 61 done in `ROADMAP.md`.
- Kept the existing Phase 6b tracking issue #31 as the issue anchor.

The new source map separates fixed mean slopes, residual-scale fixed slopes,
mean random-slope SDs, residual-scale random-slope SDs, random-effect scale
models, residual `rho12` slopes, group-level `corpairs()` rows, and structured
variance components. It also maps each major tutorial to the later Phase 6b
slice that should polish it.

## Mathematical Contract

Slice 61 does not change fitted-model behavior. It records the interpretation
contract later tutorials should use:

```text
mean slope:             mu_i = beta_0 + beta_1 x_i
residual-scale slope:   log(sigma_i) = gamma_0 + gamma_1 z_i
mean random slope:      mu_ij = beta_0 + beta_1 x_ij + b_0j + b_1j x_ij
random-effect scale:    log(sd_mu_group,j) = alpha_0 + alpha_1 h_j
residual correlation:   rho12_i = tanh(delta_0 + delta_1 x_i)
```

Tutorials should report `exp(gamma_1)` or `exp(alpha_1)` as SD ratios and
`exp(2 gamma_1)` or `exp(2 alpha_1)` as variance ratios when the biological
target is variance. They should keep residual `rho12` separate from
group-level correlations and should keep phylogenetic or spatial slopes planned
unless a later implementation slice adds code and recovery tests.

For q=4 location-scale covariance examples, the source map explicitly preserves
all four mean-scale pairs: `mu1`-`sigma1`, `mu1`-`sigma2`,
`mu2`-`sigma1`, and `mu2`-`sigma2`.

## Files Changed

- `ROADMAP.md`
- `docs/design/21-tutorial-style.md`
- `docs/design/32-phase-6b-tutorial-source-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-15-slice-61-tutorial-source-map.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format ROADMAP.md docs/design/21-tutorial-style.md docs/design/32-phase-6b-tutorial-source-map.md`:
  passed.
- `git diff --check`: passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`:
  passed and rendered the updated `ROADMAP.html`.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `rg -n "32-phase-6b|slopes, variance components|biological and mathematical interpretation|Slice 61|profile\\.boundary|profile\\.message" ROADMAP.md pkgdown-site/ROADMAP.html docs/design/21-tutorial-style.md docs/design/32-phase-6b-tutorial-source-map.md --glob '!pkgdown-site/search.json'`:
  confirmed the source-map link, roadmap status, and rendered roadmap wording.
- `rg -n "phylogenetic slopes.*implemented|spatial slopes.*implemented|q=4.*profile intervals|direct profile intervals for derived|rho ~|meta_gaussian\\(|tau ~" docs/design/32-phase-6b-tutorial-source-map.md ROADMAP.md docs/design/21-tutorial-style.md`:
  found no unsupported syntax or stale implementation claim. The hits were
  explicit planned-status guardrails.

## Tests Of The Tests

No package tests were run because this slice changed documentation and roadmap
source only. The relevant checks were markdown formatting, pkgdown rendering,
pkgdown metadata checks, and stale-claim scans.

## Consistency Audit

The source map keeps the AGENTS.md scope boundary: one-response and two-response
models only, `rho12` as the residual bivariate correlation, and higher
multivariate work outside `drmTMB`. It also preserves the Phase 6 profile
boundary by treating q=4 correlations and variance-ratio summaries as derived
targets unless a direct profile method exists.

## Team Learning

- Ada: Slice 61 should anchor the tutorial programme before individual article
  edits start.
- Jason: source mapping is useful only when it names the biological question,
  not just the file path.
- Pat and Darwin: later tutorials should show the reader how to read slopes and
  variance components as biological claims.
- Noether: every slope interpretation needs the equation, R syntax, and output
  scale to agree.
- Rose: keep planned structured slopes and derived intervals visibly planned.

## Known Limitations

This slice does not rewrite the tutorials themselves. It also does not add new
random-slope, phylogenetic-slope, spatial-slope, or profile-likelihood
machinery.

## Next Actions

1. Slice 62 should improve the tutorial landing path so readers can move from a
   scientific question to the right guide or worked tutorial.
2. Slice 63 should use this source map to polish the Gaussian location-scale
   tutorial and the scale-vocabulary guide.
3. Slice 67 should return to random-effect scale and covariance interpretation
   with runnable output and invalid-formulation guardrails.
