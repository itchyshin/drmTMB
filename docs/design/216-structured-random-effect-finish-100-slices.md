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

- SR001-SR100: 92 banked rows and 8 blocked rows after the q1 mean-phylo
  Route A parity blocker moved to banked experimental evidence.
- SR064-SR066 are banked only as pilot-accounting rows, not as interval
  reliability.
- SR073 is now banked for one deterministic q1 mean-phylo ML parity fixture.
  SR074-SR075 remain blocked because their bridge smoke is not row-complete
  parity.
- Within the SR101-SR200 tranche, SR111 banks the q1 mean-phylo Route A ML
  parity fixture, SR112 now banks q1 sigma-only phylo ML parity plus separate
  bridge-only REML admission, and SR113 banks q1 matched `mu` plus `sigma`
  phylo ML parity for one repeated-species native R/TMB, direct DRM.jl, and
  R-via-Julia fixture. SR114 now banks q1 Gaussian `relmat()` mean-side ML
  parity for one K-matrix fixture across the same three evidence routes.
  SR115 now banks q1 Gaussian `animal()` mean-side ML parity for one A-matrix
  fixture across those routes. SR116 now banks q1 Gaussian `spatial()`
  mean-side ML parity for one coordinate fixture by converting coords to the
  same fixed-range K target that native drmTMB uses before calling DRM.jl.
  SR117 now banks one q1 Poisson `phylo()` mean-side ML/Laplace bridge parity
  fixture with approximate native dense-TMB and R-via-Julia tolerances. SR118
  now banks q1 unsupported-route preflight errors for structured sigma
  predictors, precision slots, and malformed covariance matrices. SR119 now
  banks q1 coefficient-scale maps for fixed link-scale coefficients,
  response-scale structured SDs, and coupled phylo Cholesky reconstruction.
  SR120 banks the q1 acceptance gate tying fixtures, tolerances, scale maps,
  and negative preflight evidence together before q2 work begins.
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

## Current Disposition

The opening SR101-SR200 ledger banked the first governance wave. The current
execution has also banked the q1 mean-phylo, q1 sigma-only, q1 matched `mu`
plus `sigma`, q1 `spatial()` mean-side, q1 `relmat()` mean-side, q1
`animal()` mean-side ML parity evidence, and one q1 Poisson `phylo()`
mean-side ML/Laplace bridge parity fixture. It also banks the q1 unsupported
structured-route preflight errors as negative evidence and the q1
coefficient-scale reconstruction map as contract evidence. SR120 banks the q1
acceptance gate as a transition gate, not as broad bridge support. SR121 banks
the q2 payload-boundary contract and coefficient-ordering fixture while keeping
R-via-Julia q2 parity unavailable. SR122 banks coordinate-spatial q2 native ML
point evidence while keeping bridge support planned. SR123 and SR124 bank animal
and `relmat()` q2 native ML point evidence with the same bridge boundary. SR125
banks q2-plus-q2 target separation as boundary evidence, not as full q4 or
bridge support. SR126 now records that scale-only q2 `sigma1`/`sigma2` blocks
for fixed `spatial()`, `animal()`, and `relmat()` matrices have native-TMB
point-fit/extractor evidence only; bridge, interval, coverage, denominator, and
support claims remain unpromoted. SR127 banks
the q2 coefficient-ordering map as fixture-level contract evidence only. SR128
banks the direct DRM.jl q2 export/status contract for `phylo()`, `spatial()`,
`animal()`, and `relmat()` as narrow direct fixture evidence: phylo same-target
ML, animal/relmat known-covariance, and spatial fixed-covariance only. SR129
banks q2 payload provenance for source repositories, branches, heads, payload
version, estimator, endpoint, matrix ID, matrix digest, matrix levels, version
fields, and dirty-state policy. SR130 banks the q2 parity acceptance gate for
one complete-response exact-Gaussian ML native/direct/R-via-Julia fixture per
structured type: phylo, animal, `relmat()`, and fixed-covariance coordinate
`spatial()`. Aggregate q2 support remains fixture-scoped only; range-estimating
spatial, q2 REML, q4, broad bridge support, and interval coverage are not
accepted. SR131, SR133, and SR140 now bank calibrated q4 point evidence: the
same-fixture native R/TMB, direct DRM.jl, and R-via-Julia point comparison,
`corpairs()` point parity, and the q4 point-parity acceptance gate are banked
for log likelihood, fixed coefficients, direct SD targets, and derived
correlations. SR132 banks the q4 phylogenetic covariance target map for four
direct SD targets and six derived correlations, and SR134 banks the q4
profile-target bridge map for the four direct SD axes. These q4 rows are point
and extractor evidence only: q4 interval reliability, q4 interval coverage, q4
REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, non-Gaussian AI-REML,
and broad bridge support remain unpromoted. SR136 banks the q4 scale-axis
interval-failure ledger for `sd_sigma1` and `sd_sigma2`, keeping native refit
failures and direct DRM.jl undercoverage visible as blockers. SR137 banks
direct DRM.jl q4 point SD export rows for `sd_mu1`, `sd_mu2`, `sd_sigma1`, and
`sd_sigma2`. SR138 banks the deterministic balanced8 q4 fixture data and known
`Sigma_a` metadata, and SR139 predeclares q4 point-parity tolerances for log
likelihood, fixed coefficients, direct SDs, and derived correlations. The
remaining rows are queued or blocked because their evidence has not been
produced yet.

The next implementation target moves out of point parity and into the guarded
q4 inference boundary: SR135 remains blocked until requested/effective q4 REML
wording can be audited without treating Patterson-Thompson REML as HSquared
AI-REML, and SR150 remains blocked until calibrated finite-interval denominator
and MCSE evidence exists. SR136 does not change interval wording; it records
why q4 scale-axis interval wording remains blocked. SR137 does not change
bridge wording; it records direct-Julia point targets. SR138 is fixture data,
SR139 is tolerance policy, and SR140 is point-parity acceptance only, not an
interval, coverage, REML, AI-REML, or support transition.
SR141 banks the q1, q2, and q4 ADEMP coverage-design rows as design-only
evidence: data-generating mechanisms, estimands, methods, performance
measures, MCSE targets, failed-fit denominators, and interval policies are
written before any calibrated grid is run. It is not a coverage result.
SR142-SR149 bank coverage-calibration infrastructure only: q1/q2/q4 scaffold
rows, interval-method separation, bootstrap accounting fields, MCSE targets,
failure taxonomy, and a report template. SR150 remains blocked until real
replicate outputs replace mock rows and finite-interval accounting plus MCSE
support a calibrated claim. SR151-SR159 bank native REML scope status:
source-map rows, q1 mean-side allowed wording, sigma/q2/q4 rejection or
feasibility rows, Patterson-Thompson wording, requested/effective estimator
diagnostic fields, public optimizer gating, and non-Gaussian wording scans.
Unsupported cells remain unsupported. SR160 records the blocked REML acceptance
gate, and SR161-SR170 bank structured-type gap scope rows for mesh/SPDE,
sparse animal pedigree helpers, `relmat()` precision `Q`, q1-only
`phylo_interaction()`, direct-SD grammar, structured slopes, structured
`rho12`, non-Gaussian q2/q4 structured covariance, and the type-gap acceptance
gate. The q2 rows must reuse the q1 evidence ladder without borrowing q4,
REML, interval, or current bridge-support wording.

## Claim Boundary

This plan does not add public bridge support, native q4 REML, HSquared
AI-REML, non-Gaussian REML, public optimizer controls, interval coverage
reliability, an Ayumi reply, or a commit. It is a machine-validated plan for
the next implementation tranche.
