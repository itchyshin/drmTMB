# After Task: Gamma animal SD bridge parity

## Goal

Make the R-to-Julia bridge preserve the fitted SD target for one Gamma animal
intercept and compare the same synthetic model with native TMB.

## Implemented

The bridge now maps a matching structured SD target to Julia's fitted `sd`
block. It suppresses the synthetic `resd` label only when provider, group,
parameter, and a unique coefficient match. The test also checks that an
unselected two-coefficient animal term retains `resd` rather than being
mislabelled as a direct SD target.

One live synthetic comparison passed for a q1 Gamma animal intercept with a
unit-diagonal supplied covariance. It compares SD coefficients and
group-level SD predictions between native TMB and the paired Julia candidate.

## Mathematical Contract

The test uses `Cov(b) = D A D` with a unit-diagonal `A`. Julia normalizes the
structured matrix to unit diagonal, while native TMB retains the supplied
scale, so this fixture compares like-for-like marginal SDs. It does not test
non-unit covariance scaling.

## Files Changed

- `R/julia-bridge.R`
- `tests/testthat/test-julia-gamma-sd.R`
- `NEWS.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/check-log.md` and `docs/dev-log/check-log.d/2026-10-22-julia-gamma-animal-sd-bridge-parity.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md` and `arcs.md`

## Checks Run

- `Rscript -e 'invisible(parse("R/julia-bridge.R")); devtools::test(filter = "julia-gamma-sd", reporter = "summary")'`: passed the local bridge-label tests; four live tests skipped because no Julia path was configured.
- With `DRM_JL_PATH` set to the paired candidate, Julia 1.10.0, four Julia threads, and one BLAS thread, `devtools::test(filter = "julia-gamma-sd", reporter = "summary")` completed without failures and ran four live bridge tests.
- The same environment with `filter = "julia-structured"` completed without failures and ran one live test.
- `git diff --check`: passed in the independent review.
- GitHub issue lookup was attempted with `gh issue list -R itchyshin/drmTMB --state open --search 'Gamma animal SD' --limit 20`; the GitHub API connection failed.
- No site build or package-wide check was run; the documentation changes are status notes and NEWS text, not a new example or navigation item.

## Tests Of The Tests

Before the bridge fix, the new q1 target-label test failed because the payload
contained `resd`. After the fix, the q1 test passes and the q2 ambiguity
control confirms that a multi-coefficient term does not suppress `resd`. The
live test checks fitted coefficients, named SD predictions, row predictions,
and stored target labels.

## Consistency Audit

Updated the Gamma inventory, design note, limitation note, and NEWS wording to
record one candidate-only point-parity fixture. Exact stale-claim search:

```sh
rg -n -i "Gamma animal.*(Julia parity|no Julia parity)|Julia parity.*Gamma animal|non-unit covariance scaling" README.md docs/dev-log/internal-roadmap.md NEWS.md docs vignettes R tests
```

The 19,118-row required universe and all programme gate statuses are unchanged.
The active finish line continues to defer interval-coverage calibration.

## GitHub Issue Maintenance

No issue was changed because the issue-list request could not reach
`api.github.com`. Retry the lookup when the API is available; do not infer that
no matching issue exists.

## What Did Not Go Smoothly

The first live run exposed two bridge assumptions: a structured target was
labelled as `sd_phylo`, then the synthetic `resd` label was still added. An
independent review also found that the first suppression predicate did not
check coefficient uniqueness. The final predicate and q2 negative control
address that gap. An over-specific parser error matcher was removed in favour
of the observable ambiguity control.

## Team Learning

For bridge labels, match the target metadata to the fitted block before
dropping a synthetic variance label. When the formula omits a coefficient
selector, require the candidate structured term to contain one coefficient.

## Known Limitations

This is one Gamma q1 animal-intercept comparison on one synthetic dataset and
one unit-diagonal covariance. It does not establish parity for pedigree or
precision inputs, non-unit matrix scaling, animal slopes, other distributions,
general structured targets, interval calibration, or shared/released DRM.jl.
The direct SD interval methods remain uncalibrated.

## Next Actions

Continue the required-row audit and implementation across remaining family,
effect, endpoint, provider, and engine combinations. Keep this row partial in
the capability ledger; coverage calibration remains a later phase.
