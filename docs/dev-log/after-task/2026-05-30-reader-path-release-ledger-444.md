# After Task: Reader Path and Release Ledger for #444

## Goal

Implement a small #444 documentation slice from Kuhn's scout recommendation:
make the README reader path point to the model/status maps, add one factual
release-ledger bullet for #439, and reinforce the location-scale tutorial's
reaction-norm reporting row without changing likelihood, formula grammar,
simulation, design, or check-log files.

## Implemented

- `README.md` now includes a "Start here" status-map pointer to the public
  model map and implementation map.
- `NEWS.md` now records the #439 documentation status for ordinary Gaussian
  `mu` q > 2 blocks and independent Gaussian `sigma` random slopes, while
  keeping q > 2 direct correlation profiling and correlated residual-scale
  slope covariance unavailable or planned.
- `vignettes/location-scale.Rmd` now adds a narrow hierarchical reporting row
  for `(1 + temperature | population)`, tying the random-slope SD and fitted
  intercept-slope correlation to `check_drm()`, `profile_targets()`, and
  `corpairs(fit, class = "mean-slope")`.

## Mathematical Contract

This was documentation-only. It did not edit `inst/sim/`, `docs/design/`,
likelihood code, formula parsing, tests, or generated roxygen files.

## Files Changed

- `README.md`
- `NEWS.md`
- `vignettes/location-scale.Rmd`

## Checks Run

Focused source scans found the new README status-map pointer, NEWS #439
release-ledger bullet, and location-scale reaction-norm reporting row.
`pkgdown::check_pkgdown()` reported no problems. Full `pkgdown::build_site()`
was attempted but stopped with exit code `-1` after partial progress and no
R/pkgdown error text in `/tmp/drmtmb-pkgdown-build.log`. Targeted
`pkgdown::build_home()`, `pkgdown::build_news()`,
`pkgdown::build_article("location-scale")`, and `pkgdown:::build_search()`
completed, and rendered scans found the new wording in `index.html`,
`news/index.html`, `articles/location-scale.html`, and `search.json`.
`git diff --check` passed.

## Tests Of The Tests

No R tests were run because this slice changed only reader-facing prose and did
not touch package behavior.

## Consistency Audit

The prose points readers to the model/status maps before they choose syntax,
keeps q > 2 Gaussian `mu` correlations unavailable for direct profile
intervals, and keeps correlated residual-scale slope covariance planned.

## GitHub Issue Maintenance

This slice advances #444 and should be linked from the Phase 6c sprint issue
and PR after the commit is pushed.

## What Did Not Go Smoothly

The full pkgdown build did not finish in this Codex session even after output
was redirected to a temp log. Targeted touched-page renders and search-index
builds were used as the completion evidence for this prose slice.

## Team Learning

When full pkgdown is unstable or too heavy, render the touched pages and search
index directly, then record the full-build limitation instead of hiding it.

## Known Limitations

This slice does not add a new random-slope tutorial, new examples, or new
simulation evidence. It only improves the reader path and release ledger.

## Next Actions

Use #444 for the larger tutorial and release-ledger closeout after the
remaining random-slope support cells are settled.
