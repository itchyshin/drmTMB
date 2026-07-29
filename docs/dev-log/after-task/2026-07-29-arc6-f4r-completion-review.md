# After-task: Arc 6 F4R completion review

## Task goal

Close the authorized F4R private validation campaign by checking every retained
receipt and deciding the predeclared high-information alpha interval screen.

## Files changed

- `docs/dev-log/2026-07-29-arc6-f4r-completion-review.md`
- `docs/dev-log/2026-07-27-arc6-f5-public-s3-design.md`
- `docs/dev-log/check-log.md`

## Checks and outcome

- Read-only Rorqual ControlMaster inspection found 16 `RUN-COMPLETE.txt` and 16
  `all-attempts.tsv` files under the authorized durable results root.
- The completion review records 16,000 retained attempts, 15,978 alpha point /
  Godambe / interval-available attempts, and 22 retained boundary-unresolved
  attempts.
- All 16 frozen F4R cells pass the alpha bias, availability, SE/SD, and coverage
  gates. The result is a narrow private PASS.
- `git diff --check` passed for the closeout documentation.

## Consistency audit

The new review explicitly distinguishes F4R from the failed lower-information
F4 campaign and from future F5 public API work. No package source, formula
grammar, capability ledger, user-facing vignette, or pkgdown artifact changed.

## Tests of the tests

No package test was added. This task audits retained simulation output rather
than introducing a new implementation. The all-attempt denominator and the
explicit unavailable records are recorded to prevent a success-only summary.

## What did not go smoothly

F4R alpha records can retain ancillary `eta_delta_unavailable` metadata. The
review uses alpha availability fields, as preregistered, rather than treating
that ancillary eta status as an alpha inference failure.

## Team learning and process improvements

Future completion packets should retain a machine-readable summary,
post-processing/bootstrap seed, and source/library-build manifest alongside
per-shard receipts.

## Design and documentation updates

The review links the F4R design and preserves the F5 boundary. The F5 design
now correctly names the completed 16-cell F4R screen rather than the failed
24-cell F4 campaign. No public docs are changed because none may imply public
association inference yet.

## GitHub issue maintenance

No issue was opened or closed: F4R is a completed private evidence screen, while
F5 is still an unapproved separate product decision.

## Known limitations and next action

F4R covers only the frozen high-information intercept grid. A separately
approved F5 may define and test an alpha-only public surface; broader family,
design, and eta inference questions remain separate arcs.
