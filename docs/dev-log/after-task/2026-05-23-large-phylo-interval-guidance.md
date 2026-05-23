# After Task: Large-Phylo Interval Guidance

## Goal

Make the post-merge interval story usable for Ayumi-style large phylogenetic
fits: Wald first, endpoint profile for direct scalar likelihood checks,
`TMB::tmbprofile()` only when the full-profile route is wanted, and bootstrap as
a slower simulation-refit audit.

## Implemented

- Updated `confint()` documentation so the default
  `profile_engine = "auto"` route is the first profile example, and the old
  `TMB::tmbprofile()` route is shown only as an explicit comparison/debugging
  choice.
- Added a large-data vignette section that separates Wald, endpoint profile,
  full-profile comparison, multicore profile, and bootstrap calls for
  `sigma` and `sd:mu:phylo(1 | species)`.
- Added a Unix-focused bootstrap multicore smoke test for
  `confint(method = "bootstrap", parallel = "multicore", workers = 2)`.
- Updated the known-limitations ledger so it no longer says public
  `confint()` bootstrap intervals are unimplemented.

## Files Changed

- `R/profile.R`
- `man/confint.drmTMB.Rd`
- `tests/testthat/test-profile-targets.R`
- `vignettes/large-data.Rmd`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-23-large-phylo-interval-guidance.md`

## Checks Run

```sh
air format R/profile.R tests/testthat/test-profile-targets.R vignettes/large-data.Rmd
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'profile-targets', reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
rg -n "profile_precision = \"fast\" before|start with.*profile_precision|bootstrap intervals are not implemented|method = \"bootstrap\".*not implemented|parallel/workers currently routes to the bootstrap path|manual mclapply" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat man -g '!*.html'
gh issue list --search "confint bootstrap profile multicore phylogenetic" --limit 20
git diff --check
```

- `devtools::document()` passed and regenerated `man/confint.drmTMB.Rd`.
- `devtools::test(filter = 'profile-targets')` passed.
- `pkgdown::check_pkgdown()` reported no problems.
- The stale-wording scan found one outdated bootstrap limitation; this task
  updated it. The final scan only found an intentional audit-command pattern in
  `docs/design/69-comprehensive-function-page-figure-audit.md`.
- The issue search returned no overlapping open issues.
- `git diff --check` was clean.

## Tests Of The Tests

The new bootstrap test checks a neighbouring route that was not covered by the
previous profile multicore tests: it uses a real `confint()` bootstrap call,
asks for two Unix forked workers, and asserts the returned
`bootstrap.parallel`, `bootstrap.workers`, successful refit count, and failure
count columns.

## Consistency Audit

The public guidance now matches the merged implementation:

- Wald intervals are the routine first route for direct response-scale targets
  when `TMB::sdreport()` succeeds.
- Direct scalar profiles use the endpoint engine through
  `profile_engine = "auto"` unless the user supplies full-profile controls.
- `profile_engine = "tmbprofile"` remains the exact full-profile comparison
  and debugging route.
- Bootstrap intervals are available through `confint()` for direct fitted
  targets with stored model data, but remain unsupported for `summary()`,
  `corpairs()`, `newdata`, and derived targets.

## GitHub Issue Maintenance

`gh issue list --search "confint bootstrap profile multicore phylogenetic"
--limit 20` returned no issue rows. No issue was opened because this slice
clarified merged behaviour and added a focused regression test rather than
introducing a new planned feature.

## What Did Not Go Smoothly

The stale-wording scan caught an old known-limitations paragraph that still
said public `confint()` bootstrap intervals were not implemented. Updating that
ledger was necessary so the documentation does not contradict the merged
`confint(method = "bootstrap")` route.

## Team Learning

Rose should keep searching durable limitation ledgers after fast implementation
work. The code, NEWS, and reference page can be correct while a dev-log
limitation still tells the previous story.

## Known Limitations

This task did not run Ayumi's 10,438-species model and did not add new
benchmark timings. It also did not change bootstrap scope: direct fitted
targets are supported, but `newdata`, `summary()`, `corpairs()`, and derived
bootstrap intervals remain unsupported.

## Next Actions

Ask Ayumi to reinstall from GitHub, confirm the `RemoteSha`, then rerun the
real-data timing table for Wald, endpoint profile, profile multicore, and a
small direct-target bootstrap smoke.
