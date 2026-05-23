# After Task: Fast Scalar Profile Endpoints

## Goal

Add a faster endpoint-only profile-likelihood route for direct scalar targets
without weakening the existing general `TMB::tmbprofile()` path. The user-facing
question was practical: how much faster can direct phylogenetic SD intervals get,
especially around 1,000 to 5,000 species?

## What Changed

- `confint.drmTMB()` now accepts
  `profile_engine = c("auto", "endpoint", "tmbprofile")`.
- `profile_engine = "auto"` uses the endpoint engine for direct scalar
  distributional scale, random-effect SD, random-effect correlation, and
  constant residual `rho12` targets when no `TMB::tmbprofile()` controls are
  supplied.
- `profile_engine = "tmbprofile"` preserves the previous full-profile route for
  fixed effects, `newdata` rows, linear combinations, derived targets, and
  debugging.
- Output now includes `profile.engine`, so benchmark rows and user output can
  show which engine actually ran.
- The endpoint engine fixes one internal scalar parameter, optimizes the
  remaining parameters with `nlminb()`, warm-starts across endpoint evaluations,
  and solves the two likelihood-ratio crossings with `uniroot()`.
- `bench/profile-scalar-endpoint.R` records timing, interval bounds,
  convergence/failure state, endpoint root errors, endpoint-versus-`tmbprofile`
  differences, Git state, and R/TMB versions.

## Benchmark Evidence

The benchmark artifact is
`docs/dev-log/benchmarks/profile-scalar-endpoint.csv`. These rows were run on
the local checkout with `git_dirty = TRUE` because the benchmark was run before
the implementation commit existed.

| Rows | Species | Target | `tmbprofile` sec | Endpoint sec | Speedup | Endpoint - `tmbprofile` lower | Endpoint - `tmbprofile` upper | Endpoint root errors |
| ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | --- |
| 10,000 | 1,000 | `sd:mu:phylo(1 \| species)` | 21.750 | 16.241 | 1.339x | 6.87e-06 | -4.34e-06 | 0.00103, 0.000862 |
| 100,000 | 1,000 | `sd:mu:phylo(1 \| species)` | 234.136 | 123.110 | 1.902x | -1.06e-05 | 3.53e-07 | 0.00180, 0.000054 |
| 100,000 | 5,000 | `sd:mu:phylo(1 \| species)` | 251.120 | 152.011 | 1.652x | -3.68e-06 | 1.24e-05 | 0.00119, 0.00378 |
| 10,000 | 1,000 | `sigma` | 33.008 | 31.387 | 1.052x | 1.54e-06 | -9.37e-07 | 0.00106, 0.000681 |

All final benchmark rows converged for both engines. Endpoint root errors are
absolute errors in
`profile_nll(theta) - nll_hat - qchisq(level, 1) / 2`; the stated tolerance is
0.005. The 100,000 row / 10,000 species stretch case was not run, so the speed
claim is limited to the measured 1,000- and 5,000-species scenarios.

## Correctness And Scope

The endpoint engine is not a universal replacement for profiles. It is only for
direct scalar internal parameters that map cleanly to response-scale scale, SD,
or correlation targets. Fixed effects, `newdata` rows, arbitrary linear
combinations, repeatability, phylogenetic signal, and derived q4 correlations
stay on the current `TMB::tmbprofile()` or status-only routes.

`nlminb()` can report false convergence on constrained endpoints even when the
objective value is finite and the endpoint root satisfies the likelihood-ratio
equation. The implementation accepts `nlminb()` convergence code 1 only through
the final endpoint equation guard; endpoints that miss the 0.005 root tolerance
fail with guidance to use `profile_engine = "tmbprofile"`.

## Tests And Checks

- `Rscript -e "devtools::load_all(quiet = TRUE)"`: passed.
- `Rscript -e "devtools::test(filter = 'profile-targets', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'profile-targets|corpairs|summary', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(reporter = 'summary')"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `Rscript -e "devtools::check(error_on = 'never', args = '--no-manual')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `Rscript -e "pkgdown::build_site()"`: completed and rebuilt the local
  pkgdown site.
- `git diff --check`: clean.

## Consistency Audit

The profile-engine scan checked source docs and rendered pages for
`profile_engine`, `profile.engine`, endpoint wording, and `tmbprofile` wording.
It found the new API in `R/profile.R`, `man/confint.drmTMB.Rd`,
`docs/design/12-profile-likelihood-cis.md`, `bench/README.md`, `NEWS.md`,
`pkgdown-site/reference/confint.drmTMB.html`, and `pkgdown-site/news/index.html`.

The stale-claim scan checked for unsupported broad claims such as "all profiles
are faster" and for endpoint wording attached to derived or `newdata` targets.
It found no unsupported general speed claim. The remaining matches were the
intentional boundary statements that derived q4 correlations and row-specific
`newdata` profiles are not endpoint-engine targets, plus older large-data
planning text about possible 10,000-species benchmarks.

## GitHub Issue Maintenance

`gh issue list --search "profile endpoint confint phylogenetic SD" --limit 20`
returned no open issue rows needing update. I did not open a duplicate issue
because the implementation, benchmark evidence, and remaining 10,000-species
stretch boundary are recorded in this after-task note and the check log.

## Role Review

Ada integrated the API, benchmark, documentation, and validation record. Fisher
checked the likelihood-ratio endpoint equation, response-scale interval
differences, and claim boundary. Gauss checked the constrained optimization
contract and false-convergence handling. Emmy checked the S3 output shape and
internal helper routing. Grace checked test, pkgdown, and package-check
evidence. Rose checked that the report does not claim faster profiles generally.
These were role perspectives, not spawned agents.

## Remaining Boundaries

The benchmark evidence supports a narrow claim: direct scalar endpoint profiles
for the measured phylogenetic SD target were faster than the current
`TMB::tmbprofile()` path on this machine. It does not yet support a general
"all profiles are faster" claim, nor does it cover derived quantities,
row-specific prediction intervals, q4 derived correlations, or 10,000-species
trees.
