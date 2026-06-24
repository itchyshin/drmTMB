# After Task: Matched Mu Sigma One-Slope Readiness Gate

## Goal

Record the matched Gaussian structured `mu+sigma` one-slope cell as a readiness
gate, not as runtime support. The exact future member set is:

```text
mu:(Intercept)
mu:x
sigma:(Intercept)
sigma:x
```

This protects the q-series map from treating separate `mu` and `sigma`
one-slope successes, or a two-member q2-shaped block, as sufficient evidence for
the matched model.

## Implemented

- Added endpoint-member identity columns to `structured_effects()`:
  `endpoint_member_set`, `endpoint_member_count`, and `endpoint_members`.
- Extended `tests/testthat/test-structured-effects.R` so matched intercept
  rows expose `mu:(Intercept)+sigma:(Intercept)` and the matched one-slope
  attempt remains blocked by the location-scale intercept-only guard.
- Added
  `docs/dev-log/dashboard/structured-re-mu-sigma-slope-readiness.tsv` with one
  row each for `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`,
  and K-matrix `relmat()`.
- Linked the planned matched slope rows in
  `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv` to the new
  readiness sidecar.
- Wired the readiness sidecar into
  `tests/testthat/test-structured-re-conversion-contracts.R`,
  `tools/validate-mission-control.py`, `docs/dev-log/dashboard/README.md`, and
  `docs/design/218-structured-q-series-completion-map.md`.

## Mathematical Contract

The matched one-slope model is a four-member endpoint/coefficient allocation,
not a two-member `mu+sigma` intercept block and not two independent one-slope
cells glued together after the fact. Runtime support should only open once the
structured design can allocate separate intercept and slope members for both
`mu` and `sigma`.

## Files Changed

- `R/methods.R`
- `man/structured_effects.Rd`
- `tests/testthat/test-structured-effects.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-mu-sigma-slope-readiness.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format R/methods.R tests/testthat/test-structured-effects.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "devtools::test(filter = 'structured-effects')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
```

Results:

- `structured-effects` passed with 333 assertions.
- `structured-re-conversion-contracts` passed with 1531 assertions.
- `python3 tools/validate-mission-control.py` passed and reported 4 structured
  RE `mu+sigma` slope-readiness rows.

## Tests Of The Tests

The extractor test constructs lightweight fitted objects through the same
structured-term parser/build helpers used by the runtime setup. It checks the
positive matched-intercept identity and the negative matched-slope guard. The
conversion-contract test checks the sidecar schema, provider set, planned
statuses, linked q-series cells, and the exact four-member target string.

## Consistency Audit

The readiness sidecar, q-series support cells, dashboard README, design map,
conversion-contract test, and mission-control validator now use the same
boundary: matched `mu+sigma` one-slope support remains planned until the
four-member runtime mapping exists.

## What Did Not Go Smoothly

The first test run caught a vocabulary mismatch: the sidecar said "four
endpoint-member" while the contract test expected "four-member". The sidecar
and validator now use the same "four-member runtime mapping" wording as the
q-series support cells.

## Known Limitations

- No matched `mu+sigma` structured one-slope runtime support.
- No broad bridge support.
- No relmat Q bridge marshalling.
- No labelled structured slope covariance.
- No interval reliability or coverage.
- No REML, AI-REML, DRAC execution, SR150 evidence, PR undrafting or merging, or
  Ayumi-facing reply.

## Next Actions

1. Implement the four-member runtime mapping for matched `mu+sigma` slopes in a
   small provider-first slice.
2. Add diagnostics only after the runtime object exposes all four endpoint
   members distinctly.
3. Keep bridge parity, intervals, coverage, and REML language behind their own
   evidence rows.

## Supersession Note

Later on 2026-06-24, the four-member native runtime point-fit/extractor mapping
landed for `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K/Q
`relmat()` matched `mu+sigma` one-slope cells. This readiness note remains the
control-plane gate that made the endpoint-member contract explicit; the later
runtime note records the fitted cells and keeps bridge, interval, coverage,
REML, and AI-REML claims planned.
