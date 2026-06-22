# Structured Random-Effect Finish: SR101-SR200

## Purpose

This note opens the next 100 slices after the structured random-effect balance
ledger. The previous tranche corrected the support map across `phylo()`,
`spatial()`, `animal()`, `relmat()`, and q1-only `phylo_interaction()`. This
tranche is narrower: close the remaining bridge, inference, REML-scope, docs,
Julia-twin, and Ayumi closeout gaps without promoting unsupported capability.

The validator-owned source table is:

- `docs/dev-log/dashboard/structured-re-finish-100-slices.tsv`

## Carryover State

The handoff into SR101-SR200 is:

- SR001-SR100: 91 banked rows and 9 blocked rows.
- SR064-SR066 are banked only as pilot-accounting rows, not as interval
  reliability.
- SR073-SR075 remain blocked because bridge smoke is not row-complete parity.
- SR091, SR093, SR095-SR097, and SR099 remain blocked by live issue access,
  reply drafting/approval, public posting, posted-URL recording, or commit
  approval.

The next 100 slices should not erase those blockers. They should turn each
blocker into a smaller piece of evidence that can be tested, documented, and
banked.

## Evidence Ladder

Bridge support must use three separate evidence columns before a support row is
banked:

1. native R/TMB evidence for the same row and target;
2. direct DRM.jl evidence for the same row and target;
3. R-via-Julia bridge evidence for the same row and target.

A live bridge smoke can show that a route is reachable and finite. It is not
parity unless the target values, estimator labels, tolerance policy, payload
provenance, and failure behavior all agree for the row.

Coverage support must follow the ADEMP structure from Morris, White, and
Crowther (2019) and the transparent-reporting discipline of Williams et al.
(2024): aims, data-generating mechanisms, estimands, methods, performance
measures, failure accounting, and Monte Carlo standard errors are all part of
the result. The pilot rows from SR064-SR066 are an accounting seed, not a
coverage claim.

## Waves

`SR101`-`SR200` are arranged as 10 waves:

1. Finish Rehydrate: bank the carryover scope, evidence ladder, and validator
   ownership for the new ledger.
2. Bridge q1 parity: turn q1 bridge smoke and rejection rows into row-specific
   native/direct/bridge fixtures.
3. Bridge q2 parity: do the same for bivariate q2 location and q2-plus-q2
   scale-block rows.
4. Bridge q4 parity: build all-four q4 target, `corpairs()`, provenance, and
   tolerance fixtures without claiming q4 REML or AI-REML.
5. Coverage calibration: scale the q1/q2/q4 pilot accounting into calibrated
   known-truth grids before any interval reliability wording.
6. Native REML scope: keep native REML exact-Gaussian, route-specific, and
   separate from bridge smoke and HSquared AI-REML language.
7. Structured type gaps: keep mesh/SPDE, sparse pedigrees, precision-matrix
   bridge forms, direct-SD grammar, structured slopes, structured `rho12`, and
   non-Gaussian q2/q4 covariance out of support claims until designed.
8. R API docs: synchronize formula grammar, limitations, README, pkgdown,
   examples, errors, dashboard, and status wording only after evidence rows
   bank.
9. Julia twin sync: refresh direct DRM.jl status, target schema, provenance,
   gate-vs-engine CI guard, and twin check logs before bridge promotion.
10. Ayumi closeout: refresh the live issue or current transcript, draft only
    with approval, scan exact text, post only after approval, and record the
    public URL.

## Opening Disposition

The opening SR101-SR200 ledger intentionally banks only the first governance
wave. The remaining rows are queued or blocked because their evidence has not
been produced yet.

The first implementation target should be SR111-SR120: a q1 bridge parity
fixture that can compare native R/TMB, direct DRM.jl, and R-via-Julia on one
deterministic target scale. Once that pattern is stable, extend it to q2 and
q4 rather than writing bespoke parity checks for each route.

## Claim Boundary

This plan does not add public bridge support, native q4 REML, HSquared
AI-REML, non-Gaussian REML, public optimizer controls, interval coverage
reliability, an Ayumi reply, or a commit. It is a machine-validated plan for
the next implementation tranche.
