# After Task: Implementation Map Slices 341-355

## Goal

Turn Slices 341-355 into implementation-ready issue templates and acceptance
gates, while preserving the public boundary that generic direct-SD syntax,
p8/q8 slope covariance, spatial q4 parity, and Poisson/NB2 structured count
dependence remain planned until implementation evidence exists.

## Implemented

- Added `docs/design/65-implementation-map-slices-341-355.md`.
- Added 341-355 roadmap rows to the implementation-map article.
- Updated `ROADMAP.md`, `NEWS.md`, and `docs/dev-log/check-log.md`.
- Kept the changes documentation-only. No likelihood, parser, extractor, or
  test surface was opened by this task.

## Mathematical Contract

No mathematical model changed. The contract recorded here is a future evidence
contract:

- generic direct-SD syntax must identify its structured level and remain
  distinct from ordinary `sd(group)`;
- p8/q8 work must name endpoint class, covariance parameterization, and
  interval policy before fitting;
- spatial q4 must match the same four location-scale endpoints across parser,
  likelihood, extractors, diagnostics, and docs;
- Poisson and NB2 structured q1 candidates are limited to one `mu` structured
  intercept until recovery and diagnostic evidence exists.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `vignettes/implementation-map.Rmd`
- `docs/design/65-implementation-map-slices-341-355.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-21-implementation-map-slices-341-355.md`

## Checks Run

```sh
air format NEWS.md ROADMAP.md vignettes/implementation-map.Rmd docs/design/65-implementation-map-slices-341-355.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-implementation-map-slices-341-355.md
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
rg -n "341-343|344-345|346-347|348-351|352-355|implementation-ready issue|acceptance checklist|Poisson q1|NB2 q1" pkgdown-site/articles/implementation-map.html pkgdown-site/ROADMAP.html
rg -n 'generic sd\*.*(is implemented|now works|now accepts)|p8/q8.*(is fitted|are fitted|now fit)|spatial q4.*(is fitted|now fits)|Poisson.*structured.*now fits|NB2.*structured.*now fits|non-Gaussian structured.*now fits' README.md ROADMAP.md NEWS.md docs/design vignettes R tests/testthat -g '!*.html'
git diff --check
```

Results:

- `air format` completed without output.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_site()` completed and wrote the updated implementation-map
  and ROADMAP pages.
- The rendered-page scan found the 341-343, 344-345, 346-347, 348-351, and
  352-355 rows, plus Poisson/NB2 q1 wording and acceptance-checklist wording.
- The stale-support scan found no false fitted claims for generic `sd*()`,
  p8/q8, spatial q4, Poisson/NB2 structured-count routes, or non-Gaussian
  structured dependence.
- `git diff --check` was clean.

## Tests Of The Tests

This was a documentation and roadmap slice, so no new unit tests were added.
The targeted stale-support scan is the test of the planning boundary: it should
fail loudly if these planning rows accidentally claim fitted generic `sd*()`,
p8/q8, spatial q4, or non-Gaussian structured-count support.

## Consistency Audit

Ada kept the slice set narrow and synchronized. Boole and Pat focused on
whether future issue templates explain syntax and user routes clearly. Fisher,
Gauss, and Noether kept this as an evidence contract rather than a likelihood
claim. Grace tracked pkgdown and rendered-page checks. Rose checked stale-claim
risk and asked whether each issue template helps the next contributor and the
applied user.

## GitHub Issue Maintenance

No GitHub issue was opened in this slice. The output is the reusable issue
template material that should be copied or adapted when the next implementation
issue starts.

## What Did Not Go Smoothly

The roadmap is now long enough that future slice entries are easier to add than
to navigate. The implementation map helps, but the next real code issue should
avoid adding another broad planning block unless it unlocks a concrete fitted
surface.

## Team Learning

Issue templates need the same fitted-versus-planned discipline as public docs.
Rose's closeout question for the next slice is: does the template make it
harder for us to overclaim and easier for a user to find a model they can run
today?

## Known Limitations

- Generic direct-SD syntax remains planned.
- p8/q8 location-scale slope covariance remains planned.
- Spatial q4 location-scale covariance remains planned.
- Poisson and NB2 structured q1 count dependence remain planned.
- Random effects in `zi`, `hu`, future `zoi`, and future `coi` remain out of
  scope for now.

## Next Actions

Start one implementation issue from the new templates. The most direct code
candidate is spatial q4 parity if the next goal is structured Gaussian parity,
or Poisson q1 structured `mu` intercept if the next goal is first
non-Gaussian structured-dependence evidence.
