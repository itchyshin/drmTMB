# After Task: Structured RE Executable Evidence

## Goal

Do the next implementation batch after the SC201-SC400 conversion ledger:
package the already validated mission-control state, then add executable q1,
q2, q4 contract guards and an ADEMP scaffold for structured random-effect
coverage accounting.

## Implemented

The current mission-control contract state was committed first as
`18ee5191` (`Bank structured RE mission-control contracts`). This follow-up
adds runnable evidence on top of that contract state:

- `test-structured-re-conversion-contracts.R` verifies the q1 payload,
  reconstruction, and parity ledgers; q2 target/native/bridge boundary
  ledgers; q4 target/extractor/bridge boundary ledgers; and the ADEMP design
  ledger.
- `sim_structured_re_ademp.R` defines structured random-effect q1/q2/q4 ADEMP
  conditions, a Phase 18 registry wrapper, MCSE policy helpers, an accounting
  template, and denominator summaries that keep failed fits and unavailable
  intervals in the denominator.
- `sim_write_structured_re_ademp_scaffold.R` writes resumable scaffold
  artifacts for cells, seeds, MCSE policy, and accounting templates.
- `structured-re-executable-evidence.tsv` and dashboard build `r13` make those
  executable guards visible and validator-owned.

## Mathematical Contract

The implemented claim is narrow: q1/q2/q4 structured random-effect contract
ledgers are now executable status guards, and the ADEMP scaffold can stage
replicate-level accounting for later calibrated simulations. The work does not
change likelihoods, formula grammar, bridge execution, REML derivations,
profile calculations, or interval construction.

REML wording stays exact-Gaussian and route-specific. Q2 remains separate from
q2-plus-q2 and q4. Q4 direct structured SD targets remain separate from derived
cross-axis correlations. Coverage remains unclaimed until a calibrated grid
reports finite interval accounting and MCSE.

## Files Changed

- `inst/sim/R/sim_structured_re_ademp.R`
- `inst/sim/run/sim_write_structured_re_ademp_scaffold.R`
- `inst/sim/README.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tests/testthat/test-structured-re-ademp-scaffold.R`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format inst/sim/R/sim_structured_re_ademp.R \
  inst/sim/run/sim_write_structured_re_ademp_scaffold.R \
  tests/testthat/test-structured-re-conversion-contracts.R \
  tests/testthat/test-structured-re-ademp-scaffold.R
Rscript --vanilla -e "devtools::load_all(quiet = TRUE); res <- testthat::test_file('tests/testthat/test-structured-re-conversion-contracts.R'); stopifnot(all(vapply(res, function(x) is.null(x[['failure']]) && is.null(x[['error']]), logical(1))))"
Rscript --vanilla -e "devtools::load_all(quiet = TRUE); res <- testthat::test_file('tests/testthat/test-structured-re-ademp-scaffold.R'); stopifnot(all(vapply(res, function(x) is.null(x[['failure']]) && is.null(x[['error']]), logical(1))))"
Rscript --vanilla -e "devtools::test(filter = 'structured-re')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
git diff --check
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 \
  sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/status.json >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-executable-evidence.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-q1-bridge-payload-contract.tsv >/dev/null
```

Outcomes:

- Contract test file: 65 pass, 0 failure, 0 warning, 0 skip.
- ADEMP scaffold test file: 34 pass, 0 failure, 0 warning, 0 skip.
- `devtools::test(filter = 'structured-re')`: 99 pass, 0 failure, 0 warning,
  0 skip.
- Mission-control validator passed and reported 6 executable-evidence rows.
- Dashboard fetch checks passed on the live local server.

## Tests Of The Tests

The new contract tests check negative evidence and boundaries, not only row
presence: q1 bridge rows remain planned, q1 `corpairs()` stays not applicable,
q2 REML stays unsupported, q2-plus-q2 stays separate from q4, q4 smoke stays
smoke, and q4 interval status stays unavailable or not evaluated. The ADEMP
scaffold tests include malformed dimension/status cases and a denominator
summary where errors, nonconvergence, nonfinite intervals, and unavailable
intervals all remain in the denominator.

## Consistency Audit

The package simulation README now points to the scaffold and states that it is
not a calibrated grid, bridge promotion, or coverage claim. The dashboard
README and validator both know the new executable-evidence ledger. No README,
NEWS, formula grammar, roxygen, pkgdown navigation, likelihood, or public API
change was needed.

## GitHub Issue Maintenance

No GitHub issue was opened, closed, or commented on. The Ayumi issue remains
parked until current issue text and the exact final reply are reviewed and
approved.

## What Did Not Go Smoothly

The first draft of the contract test had `test_that()` close-brace typos and
over-specific wording checks. The first ADEMP MCSE helper also hit the usual
floating-point edge where the 0.95 coverage MCSE formula evaluated slightly
above 475. The tests caught both; the final helper subtracts a small numerical
tolerance before `ceiling()`, and the contract tests now assert row-specific
boundaries rather than identical prose.

## Team Learning

Contract rows become much more useful once they have executable negative
evidence. The next batch should keep this pattern: every promotion candidate
gets a row-specific test before any dashboard status or public wording moves.

## Known Limitations

This task does not implement deterministic native R/TMB versus direct DRM.jl
versus R-via-Julia parity fixtures. It does not add q2 or q4 REML derivations,
q4 interval coverage, non-Gaussian REML, public optimizer controls, or an Ayumi
reply.

## Next Actions

Start the next implementation batch with q1 parity fixtures: native R/TMB,
direct DRM.jl, and R-via-Julia on the same deterministic target, with matrix
digest and provenance retained. Then extend that same pattern to q2 and q4
before any bridge wording changes.
