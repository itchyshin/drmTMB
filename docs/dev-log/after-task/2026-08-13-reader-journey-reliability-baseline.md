# After Task: Reader-journey reliability baseline

## Goal

Turn the existing ten native reader-workflow smoke into regression coverage and
repair the public-status and generated-surface defects it exposed.

## Implemented

The audit now has a deterministic test, an explicit temporary output path, and
an honest generic-post-fit label that records `check_drm()` warnings or errors
as failed diagnostics. The ordinal missing-response fixture freezes
both public cutpoint and internal-coordinate truths. Modelled aggregate
`corpairs()` rows now fail closed as derived intervals rather than asking for
`newdata` that cannot make the aggregate estimand profileable. Missing-response
vignette examples use public `nobs()`, `fitted()`, and `residuals()` outputs.

## Mathematical Contract

The second internal ordinal coordinate is a log-gap, whereas the public
cutpoint is the cumulative threshold. Both therefore require their own frozen
truth. A `corpairs()` row that summarizes a varying correlation surface is not
a one-parameter estimand; only a supplied row passed to `confint()` identifies
one.

## Files Changed

Reader audit tool and receipt; missing-response simulation fixture and tests;
correlation status implementation and test; five reader-facing vignettes; the
known-limitations and check-log records.

## Checks Run

- Ten-journey reader integration test: pass.
- Specialist public-output assertions: ordinal probability/cutpoint targets,
  missing-response row accounting, bivariate response-scale `rho12`,
  phylogenetic deviation/target schemas, meta-analysis `sigma`, and the
  lognormal `predict()` versus `fitted()` distinction: pass.
- Direct ordinal manifest smoke: public cutpoint truths present and correct.
- Direct modelled-`rho12` status smoke and `test-corpairs.R`: pass.
- `test-profile-targets.R`: completed without a reported failure.
- `pkgdown::check_pkgdown()`: no problems.
- `missing-data.Rmd`: rendered successfully to a temporary directory.

## Tests Of The Tests

The first render attempted to index bivariate residuals by response-variable
name and failed because the public matrix labels are `y1`/`y2`. The repaired
example uses response order and rendered successfully. The new ordinal test
also initially used an obsolete `prediction_grid()` calling convention; the
failure was corrected to the documented `focal`/`at` API before it passed.

## Consistency Audit

Searched the audited reader surfaces for the stale “cutpoint profiles are not
public” claim, the old “report-ready coefficient table” label, and the
unactionable active `corpairs()` `newdata_required` wording. The generated
audit receipt was regenerated. Historical notes were left intact.

## GitHub Issue Maintenance

No duplicate issue opened. The status repair corresponds to #802; Student-nu
profile overflow (#1010), ledger prose rot (#1011), and deferred missing-data
campaign issues remain outside this baseline slice.

## What Did Not Go Smoothly

The full G4/G5 foundation test launches real profiles across every route and
was not suitable as a quick focused check; redundant local runs were stopped.
The direct manifest smoke isolates the changed contract without launching a
campaign.

## Team Learning

An audit that only confirms fit plus `summary()` must be labelled as such.
Specialist output paths need their own executable assertions, and a status
message is a user contract: it must recommend an action that can succeed.

## Known Limitations

This is native-only. It does not add methods, calibration evidence, a new
interval engine, Julia support, CRAN certification, or a missing-response G4/G5
campaign. The generic journey smoke covers continuous location-scale, count,
both proportion workflows, and spatial fits; it is deliberately not a claim
that each has received an estimator-specific inference campaign. Full package
and `--as-cran` validation remain required before merge.

## Next Actions

Let the pull-request CI establish the package-wide cross-platform gate. Inspect
any failure narrowly; then seek merge approval without widening into Julia,
calibration, CRAN re-freeze, MSPL, or simulation work.
