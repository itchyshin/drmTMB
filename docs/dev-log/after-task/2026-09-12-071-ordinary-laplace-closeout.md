# After Task: 0.7.1 ordinary-Laplace R--Julia parity closeout

## Goal

Close the bounded 0.7.1 ordinary-random-intercept parity arc: make the scalar
`marginal = "Laplace"` capability and coupled-NB2 route visible in the
machine-readable bridge registry, retain the four-fixture evidence boundary,
and prove that the campaign source subsets correspond to the declared source
commits.

## Implemented

The registry now emits `ordinary_ri_scalar_laplace` and
`ordinary_nb2_coupled_laplace`, and the generated installed/dashboard TSVs,
scoreboard, and canonical parity matrix cite the retained evidence.  The
claim is deliberately narrow: the 500 paired seeds per frozen fixture estimate
profile-interval coverage with every attempted engine-target cell retained in
the unconditional denominator.  It does not claim general calibration or
cross-engine coverage equality.  The scalar row also states that `:Laplace`
is distinct from the legacy GHQ-32 `:LA` route.

The S7 reconciliation guard now verifies declared campaign source subsets
against their committed Git objects, including portability between wrapped and
wrapper-free archives.  It rejects unsafe archive members, missing required
roots, files absent from the declared commit, altered bytes, and foreign
bundles.

## Mathematical Contract

The newly ledgered bridge surface is the scalar ordinary random-intercept
Laplace objective for Binomial, Poisson, and NB2, plus the coupled NB2
location--scale ordinary-RI route.  The evidence classification concerns
declared outer parameters and profile endpoints; inner modes are not targets.
`fit_failed`, `profile_failed`, `nonfinite_endpoint`, and `truth_outside`
remain distinct retained outcomes.

## Files Changed

- `R/julia-bridge.R` is the registry source for the two capability rows.
- `inst/extdata/julia-capabilities.tsv` and
  `docs/dev-log/dashboard/julia-capabilities.tsv` are regenerated and
  byte-identical outputs.
- `docs/design/parity-scoreboard.md` and
  `docs/design/parity-matrix.md` are regenerated at DRM.jl
  `b2caf00f23f080fe89028966a4bfb098ef095510`.
- The S7 verifier, reconciliation script, coverage writer, and negative
  controls live under `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/`.
- `tests/testthat/test-071-four-fixture-summary.R` checks the emitted registry
  rows and the frozen-scenario claim fence.

## Checks Run

- `Rscript -e 'devtools::test(reporter = "summary")'` completed with exit 0.
  Its recorded summary contains only existing/environment-gated skips and
  expected warning controls.
- `DRM_JL_PATH=/private/tmp/drmjl-071-pinned-b2 Rscript -e
  'devtools::test(filter = "parity-matrix", reporter = "summary")'` passed
  against the pinned Julia checkout.  The only skip is the pre-existing
  `zero_one_beta` route awaiting its separate ledger PR #1184.
- `bash .../test-source-commit-proof.sh` passed its full/subset,
  wrapped/wrapper-free, tamper, missing-root, and foreign-bundle controls.
- `bash -n` passed for the source verifier and reconciliation payload.
- `git diff --check` passed; the two generated capability TSVs are identical.

The retained Nibi receipt
`receipts/s7-source-commit-proof-21753825.tsv` records source-subset PASS for
drmTMB `453cff782900aa55211d3f5971c229fc485d291e` and DRM.jl
`b2caf00f23f080fe89028966a4bfb098ef095510`.

## Tests Of The Tests

The new registry test was red before the ordinary-Laplace rows existed.  The
source verifier has explicit altered-byte, missing-required-root, and
foreign-bundle negative controls.  The source-pinned matrix test first exposed
stale generated line references after the TSV row insertion; regenerating
`parity-matrix.md` with its canonical writer made it byte-identical again.

## Consistency Audit

The audited claim language appears in the generated registry, scoreboard, and
matrix and consistently names a frozen-scenario evidence exception.  Searches
covered `README.md`, `NEWS.md`, `docs/dev-log/internal-roadmap.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
`vignettes/formula-grammar.Rmd`, `_pkgdown.yml`, `docs`, `R`, and `tests` for
ordinary-Laplace syntax, the `:LA`/GHQ-32 distinction, and general-coverage
overclaims.  No user-facing grammar or navigation change is required: the
bridge remains optional and the source-pinned evidence is represented in the
capability tables.

## GitHub Issue Maintenance

`drmTMB#544`, cited by both ledger rows, was inspected and is closed.  No issue
was opened, closed, or commented on here: this closeout records an existing
bounded parity programme and does not widen its public scope.  The separate
open zero-one-beta ledger item remains deliberately outside this arc.

## What Did Not Go Smoothly

The initial local reconciliation compared a retained archive to a live working
tree, which is not a valid retained-evidence proof.  Also, the full test suite
does not run the source-pinned matrix check unless `DRM_JL_PATH` is set, and the
first explicit pinned run exposed a stale generated matrix.  Both were repaired
without changing source pins, fixtures, targets, profile caps, campaign results,
or denominators.

## Team Learning

Generated parity artefacts need their own canonical writers invoked after a
ledger-row insertion: superficially similar scoreboard and matrix writers
serve different documents.  Retained source archives should be proven against
the commit object and a declared required-root subset, never against whichever
checkout happens to be available later.

## Known Limitations

This is not a general coverage, calibration, performance, GPU, release, or
CRAN result.  The retained campaign was not rerun.  The live Julia engine was
not exercised by the local package suite; its source-pinned campaign evidence
and source-subset receipt remain the claim-bearing proof.

## Next Actions

Open this scoped change as a draft PR, retain the S7 receipts, and leave
release/merge decisions to a separate review.  Any future coverage campaign
must receive a new source pin, manifest, runtime receipt, and denominator.
