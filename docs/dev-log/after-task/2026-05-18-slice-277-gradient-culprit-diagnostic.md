# After Task: Slice 277 Fixed-Gradient Culprit Diagnostic

## Goal

Improve convergence triage by naming the largest fixed-gradient component in
`check_drm()` without changing optimization or Hessian logic.

## Implemented

- Updated the `fixed_gradient` diagnostic value from a bare maximum to
  `max=<value>; component=<label>`.
- Added internal duplicate-name disambiguation so repeated TMB parameter names
  become labels such as `beta_mu[2]`.
- Added a focused warning-branch test that forces the largest gradient onto the
  second `beta_mu` component and checks both value and message text.
- Updated the convergence guide, roxygen reference documentation, roadmap, and
  NEWS.

## Contract

Slice 277 improves culprit-parameter reporting for the fixed-gradient row only.
It does not add Hessian eigenvector diagnostics, automatic model simplification,
new boundary thresholds, or changes to `pdHess` status.

## Files Changed

- `NEWS.md`
- `R/check.R`
- `ROADMAP.md`
- `docs/dev-log/after-task/2026-05-18-slice-277-gradient-culprit-diagnostic.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-200027-codex-checkpoint.md`
- `man/check_drm.Rd`
- `tests/testthat/test-check-drm.R`
- `vignettes/convergence.Rmd`

## Checks Run

- `air format NEWS.md R/check.R ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-277-gradient-culprit-diagnostic.md docs/dev-log/recovery-checkpoints/2026-05-18-200027-codex-checkpoint.md man/check_drm.Rd tests/testthat/test-check-drm.R vignettes/convergence.Rmd`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/check_drm.Rd`.
- `Rscript -e "devtools::test(filter = 'check-drm', reporter = 'summary')"`:
  passed.
- `Rscript -e 'rmarkdown::render("vignettes/convergence.Rmd", output_dir = tempfile("convergence-render-"), quiet = FALSE)'`:
  passed.
- `rg -n 'Slice 277|fixed_gradient|largest fixed-gradient|largest component|component=|beta_mu\[2\]|Hessian and boundary diagnostics|gradient component label' NEWS.md ROADMAP.md R/check.R man/check_drm.Rd tests/testthat/test-check-drm.R vignettes/convergence.Rmd`:
  confirmed the diagnostic, test, reference, article, roadmap, and NEWS.
- `rg -n 'Hessian eigenvector.*implemented|culprit.*implemented|pdHess.*culprit|boundary.*culprit.*implemented|gradient component.*implemented|largest fixed-gradient.*implemented' README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat --glob '!docs/dev-log/**'`:
  returned no matches.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 277 fixed-gradient culprit diagnostic" --next "stage, commit, push, and open draft PR"`:
  wrote `docs/dev-log/recovery-checkpoints/2026-05-18-200027-codex-checkpoint.md`.

## Tests Of The Tests

The new mutated diagnostic branch would fail if `check_drm()` stopped reporting
the largest gradient component, stopped disambiguating duplicated fixed-parameter
names, or reported the component in the value but not the explanatory message.

## Consistency Audit

Ada kept the slice scoped to one diagnostic row. Fisher kept the change in the
post-fit diagnostic layer rather than treating it as a new convergence remedy.
Curie added a direct mutated-object test rather than a slow simulation. Pat
checked that the convergence guide explains why the largest component matters.
Grace checked roxygen, focused tests, vignette rendering, pkgdown, and
formatting. Rose checked that Hessian eigenvector and automatic culprit
reporting are not claimed.

## Known Limitations

- Hessian eigenvector culprit reporting remains planned.
- Boundary-specific culprit labels for random-effect SDs and correlations remain
  limited to existing row values.
- Duplicate TMB parameter names are disambiguated positionally, not mapped back
  to formula-term labels in this slice.

## Next Actions

A later diagnostics slice can map internal fixed-parameter positions to
distributional-parameter coefficient names when a stable namespace is available
for all fitted families.
