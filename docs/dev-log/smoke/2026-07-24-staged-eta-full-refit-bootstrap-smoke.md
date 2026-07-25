# Staged-eta full-refit bootstrap local smoke receipt

**Status:** PASS for executable output and retained diagnostics only. This is
not recovery, calibration, interval, coverage, or a public-inference claim.

## Approved scope

The owner approved one tiny local smoke. The runner used slope cell
`staged_eta_17` (`n = 240`, Bernoulli intercept `-0.2`, NB2 `sigma = 0.25`,
and truth `alpha = (-0.15, 0.65)`), two outer attempts, and five full-refit
bootstrap attempts per outer fit. The smoke-specific availability threshold was
3/5 solely to exercise the ledger path; it does not alter the full campaign's
399 attempted / 380 resolved contract.

## Environment and provenance

An isolated local library was built from this worktree at
`/private/tmp/drmtmb-staged-eta-smoke.cMKMkR`. The smoke wrote its local,
untracked outputs under `output/` there. The source driver SHA-256 was
`8767881d479af064c3e92fb56f31228c4e7ff030ce5e8650c9b8c2694327dc6d`.

The first invocation omitted `R_PROFILE_USER=/dev/null` and returned without
writing a ledger. That failed attempt is retained as an environment diagnostic,
not interpreted as a fit result. The valid rerun used both the isolated library
and `R_PROFILE_USER=/dev/null`.

## Result

- Outer ledger: 2/2 rows, both `interior`.
- Bootstrap ledger: 10/10 rows, every Bernoulli margin, NB2 margin, and
  association fit `ok`/`interior`; no messages.
- Both smoke intervals met the smoke-only 3/5 availability threshold.
- The diagnostic RDS has 2 outer bundles × 5 bootstrap diagnostics and retains
  association score, curvature, and optimization-domain data for every refit.
- Output files are non-empty: `staged-eta-outer-attempts.csv`,
  `staged-eta-bootstrap-attempts.csv`, `staged-eta-bootstrap-diagnostics.rds`,
  and `staged-eta-summary.csv`.

## Boundary and next gate

This receipt proves only that the installed source, simulator, full margin
refits, association refits, and retention schema work together for one regular
cell. It does not support the observed smoke coverage fractions (two outer
attempts and five bootstrap draws are intentionally non-inferential).

Before any campaign, request a separate owner approval for DRAC. The campaign
must use the immutable 24-cell grid, 200 all-attempt outer datasets per cell,
399 full-refit bootstrap attempts per outer fit, and the 380-resolved
availability threshold; it must retain all failures and receive Fisher,
Noether, and Rose review before a public claim.
