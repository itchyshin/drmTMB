# After Task: Q8 Staged-Start Mapper

## Goal

Add the private q > 2 staged-start mapper that can prepare q4-to-q8 diagnostic
starts without opening a public start API or claiming q8 recovery evidence.

## Implemented

Added `drm_qgt2_staged_start_override()` and supporting private helpers. The
mapper takes a fitted q > 2 source object and a target q > 2 bivariate Gaussian
specification, then returns a named internal start `override` plus diagnostic
`provenance`.

The mapper copies fixed effects by distributional parameter and model-matrix
column name. It copies q > 2 endpoint standard deviations by covariance-member
key. It optionally copies `theta_re_cov` starts by pair key, with shrinkage,
boundary guarding, positive-definite regularization, and an unpacking check
against `tmb_unstructured_corr_matrix()`.

## Mathematical Contract

The q8 target is still the ordinary bivariate Gaussian all-endpoint block:
`mu1`, `mu2`, `sigma1`, and `sigma2` each carry the matching group-level
endpoint structure, while residual `rho12` remains the row-level residual
coscale. The mapper may initialize fixed effects, endpoint standard deviations,
and explicitly requested group-level correlations; it does not change the
likelihood, parameterization, optimizer, fitted degrees of freedom, or
inference labels.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-optimizer-contract.R`
- `docs/design/35-optimizer-start-map-multistart.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-17-q8-staged-start-mapper.md`

## Checks Run

```sh
air format R/drmTMB.R tests/testthat/test-optimizer-contract.R
Rscript --vanilla -e 'devtools::test(filter = "optimizer-contract", reporter = "summary")'
Rscript --vanilla -e 'devtools::test(filter = "optimizer-contract|phase18-biv-gaussian-q8-endpoint", reporter = "summary")'
Rscript --vanilla -e 'devtools::document()'
Rscript --vanilla -e 'pkgdown::check_pkgdown()'
Rscript --vanilla -e 'devtools::check(error_on = "never")'
git diff --check
conflict-marker scan over touched files
forbidden-framing scan over touched prose and code
```

Results: focused optimizer-contract tests passed before and after formatting.
The combined optimizer-contract plus q8 endpoint/recovery phase18 subset passed.
`devtools::document()` completed; unrelated generated Rd/RoxygenNote drift was
removed from the PR. `pkgdown::check_pkgdown()` failed on the pre-existing
`drm_phylo_penalty` topic missing from `_pkgdown.yml`, which belongs to the
Claude penalty/Ayumi lane and was not changed here. `devtools::check(error_on =
"never")` passed with 0 errors, 0 warnings, and 0 notes in 10m 42.4s. Static
diff, conflict-marker, and forbidden-framing scans passed.

## Tests Of The Tests

The new source tests build real q4 and q8 bivariate Gaussian specifications,
then use a controlled fake fitted q4 source so expected copied starts are
known exactly. They verify fixed-effect column matching, endpoint-SD member-key
matching, neutral default `theta_re_cov`, optional pair-key theta copying,
theta shrink validation, and the correlation-matrix-to-TMB-theta inverse.

The first run failed when the stricter #597 start-override hook met duplicated
internal `log_sd_re_cov` names. The alignment helper now permits duplicated
target names only when the override has the identical name sequence; otherwise
named overrides still fail before TMB.

## Consistency Audit

The optimizer start/map design note now distinguishes three levels:
private start-override plumbing, private q8 staged-start mapper construction,
and future public user starts. No README, NEWS, pkgdown navigation, formula
grammar, likelihood, dashboard, or known-limitations entry changed because this
is internal diagnostic machinery only.

## GitHub Issue Maintenance

Issue `drmTMB#5` should be updated when the PR opens. The issue already carries
the q8 staged-start thread; this slice makes the mapper source-tested on
current `origin/main`.

## What Did Not Go Smoothly

The old local mapper could not be copied blindly because current `origin/main`
has a newer fit path and a stricter start-override contract. This PR ports the
mapper construction and source tests only. The prepared-spec fit tail and paired
cold-versus-staged diagnostic runner remain separate.

## Team Learning

Gauss: q > 2 correlation starts need pair-key reconstruction and an unpacking
check, never raw packed-vector copying. Rose: duplicated internal start-vector
names are real in `log_sd_re_cov`, so exact-sequence matching is safer than
assuming parameter names are unique.

## Known Limitations

No public `start`, `start_from`, `warm_start`, or `map` API was added. No
prepared-spec fit tail was added. No paired cold-versus-staged q8 diagnostic
was run. No q8 coverage, power, interval, speed, or release-support claim is
made.

## Next Actions

Add a current-fit-tail-safe prepared-spec helper or diagnostic runner, then run
paired cold-versus-staged q8 diagnostics before any larger q8 simulation lane.
