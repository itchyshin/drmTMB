# After Task: Slices 1159-1178 Reference And Forgotten-Promises Audit

## Goal

Ada ran the first reference-discoverability and forgotten-promises audit after
the post-1138 slice ledger. The aim was to separate what is fitted, what is
documented as planned, and what remains only a design or simulation target.

## Implemented

- Added `docs/dev-log/forgotten-promises-status-2026-05-20.md`.
- Checked `_pkgdown.yml` reference grouping for formula-only and post-fit
  syntax: `sd(group)`, `animal()`, `phylo()`, `spatial()`, `relmat()`,
  `corpair()`, `rho12`, `check_drm()`, `profile_targets()`, `confint()`,
  `plot_corpairs()`, and `plot_parameter_surface()`.
- Confirmed the matching generated `.Rd` files exist for those reference
  topics.
- Turned repeated promises into a status table covering figures, simulation
  plots, inference raindrops, formula discoverability, same-response bivariate
  `mu`/`sigma`, `rho12` separation, profile intervals, bootstrap intervals,
  Ayumi convergence, starts, Student-t shape, skew families, animal/relmat,
  phylogenetic, spatial, Phase 18 simulations, and example coverage.

## Mathematical Contract

No likelihood or formula grammar changed in this audit. The main contract is
status honesty: documented planned syntax such as `animal()` or `relmat()` must
remain visibly planned until likelihood, diagnostics, profile targets, recovery
tests, and examples exist.

## Files Changed

- `docs/dev-log/forgotten-promises-status-2026-05-20.md`
- `docs/dev-log/after-task/2026-05-20-slices-1159-1178-reference-forgotten-promises-audit.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
sed -n '1,240p' _pkgdown.yml
ls man/random_effect_scale_formulas.Rd man/animal.Rd man/phylo.Rd man/spatial.Rd man/relmat.Rd man/corpair.Rd man/meta_V.Rd man/rho12.Rd man/check_drm.Rd man/profile_targets.Rd man/confint.drmTMB.Rd man/plot_corpairs.Rd man/plot_parameter_surface.Rd
rg -n 'public bootstrap|bootstrap intervals are not implemented|method = "bootstrap"|parametric-bootstrap|private parametric-bootstrap|pdHess|false convergence|Ayumi|PV2|locphylo|skew-normal|skew_t|skew-t|shape random|animal\(\)|relmat\(|profile-ready|derived_interval_unavailable' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R/profile.R R/formula-markers.R --glob '!docs/design/archive/**'
```

The broader package validation for this combined lane remains the previous
targeted tests, `devtools::document()`, `pkgdown::check_pkgdown()`, and
`git diff --check` recorded in the companion covariance-block after-task note.

## Tests Of The Tests

This was a documentation and status audit, not a new test lane. The useful
validation is that the audit table names evidence and remaining action for each
promise instead of silently converting planned syntax into fitted claims.

## Consistency Audit

The audit agrees with the current high-level status:

- Student-t `nu` is fitted as fixed-effect shape; skew-normal and skew-t remain
  fixed-effect-first future families.
- `animal()` and `relmat()` are reference-visible planned markers, not fitted
  model routes.
- Public bootstrap intervals remain planned; private Phase 18 bootstrap helpers
  are simulation infrastructure.
- Profile readiness is target-specific, and direct q2 readiness does not make
  q4 derived rows interval-ready.

## What Did Not Go Smoothly

The search output is large because many design and Phase 18 files correctly
mention the same terms. Rose's fix was to convert the results into a compact
status table rather than trying to make the search itself the deliverable.

## Team Learning

- Ada kept the audit tied to PR #263 and the post-1138 slice ledger.
- Rose separated stale promises from valid planned-feature wording.
- Pat checked whether a new user can find syntax from the reference index.
- Grace checked that reference topics are present in `_pkgdown.yml` and in
  generated `.Rd` files.
- Fisher kept inference claims separate from simulation infrastructure.

These were role perspectives, not spawned agents.

## Known Limitations

- This is a source-reference audit plus `pkgdown::check_pkgdown()`, not a full
  rendered-site user test. The next site-build pass should inspect the rendered
  reference index directly.
- No GitHub issues were opened or updated in this slice; the table is ready to
  drive that issue triage if the project owner wants issue-level tracking.

## Next Actions

1. Run a rendered reference-index audit after the next full site build.
2. Re-run the Ayumi convergence stress set with the current diagnostics.
3. Turn the status table into GitHub issues only for concrete missing pieces
   that need external tracking.
