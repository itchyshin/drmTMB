# Structured Q-Series Completion Map

## Purpose

The structured random-effect q-series needs a single unit of truth. Earlier
work advanced through high-value cells: Ayumi q4 phylo point fits, q2 bridge
fixtures, q8 ordinary diagnostics, q1 bridge parity, and the first count q1
routes. That produced useful evidence, but the evidence landed in different
places: formula grammar, helper tables, dashboard sidecars, design notes, PR
text, and bridge tests.

The completion rule from this point is:

1. add or update the support-cell row first;
2. code only the exact formula/provider/endpoint/route described by that row;
3. test the row at the matching evidence tier;
4. update dashboard, docs, and PR wording against the same row;
5. promote public wording only when the row reaches `supported`.

The validator-owned source table is:

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`

This table complements, but does not replace,
`docs/dev-log/dashboard/structured-re-balance-matrix.tsv`. The older matrix is
the coarse structured random-effect status board. The q-series table is the
finer completion map that names exact formula cells, endpoint sets, slope
classes, routes, estimator labels, interval status, coverage status, and claim
boundaries.

## Support-Cell Schema

Every row must include these fields:

- `cell_id`
- `formula_cell`
- `family_class`
- `family`
- `structure_provider`
- `dimension_pattern`
- `endpoint_set`
- `slope_class`
- `covariance_layout`
- `route`
- `estimator_requested`
- `estimator_effective`
- `fit_status`
- `extractor_status`
- `bridge_status`
- `interval_status`
- `coverage_status`
- `authority_status`
- `evidence_url`
- `claim_boundary`
- `denominator_policy`
- `next_gate`

The extra `next_gate` field is not a capability claim. It is the work queue for
the next evidence transition. It exists so a row does not hide why it is still
planned, diagnostic-only, or blocked.

Allowed evidence tiers are:

`planned/unsupported` -> `parser-ready` -> `point-fit` ->
`extractor-ready` -> `fixture-parity` -> `interval-feasible` ->
`inference-ready` -> `supported`

The TSV uses underscore spellings for machine checks:

`planned`, `unsupported`, `parser_ready`, `point_fit`, `extractor_ready`,
`fixture_parity`, `interval_feasible`, `inference_ready`, `supported`.

Two local guard statuses are also allowed:

- `diagnostic_only`: the route can be inspected but does not support interval
  reliability, coverage, or power wording.
- `blocked`: the row has a named blocker and must not be promoted by adjacent
  evidence.

## Current Evidence Boundary

The current table records these broad facts without promoting beyond them:

- Gaussian structured intercept support is present across `phylo()`,
  `spatial()`, `animal()`, and `relmat()` for univariate `mu`, univariate
  `sigma`, matched `mu+sigma`, bivariate `mu1+mu2`, and constant all-four q4
  point/status cells.
- One independent Gaussian structured `mu` slope has point-fit evidence across
  `phylo()`, `spatial()`, `animal()`, and `relmat()`.
- Structured residual-scale one-slope cells remain planned. A working `mu`
  slope does not imply the matching `sigma` slope.
- Q2 bridge fixture evidence is banked only for complete-response
  exact-Gaussian ML fixtures: phylo, fixed-covariance spatial, animal A-matrix,
  and relmat K-matrix.
- Phylo q4 point parity and extractor evidence exist, but q4 interval
  reliability, q4 interval coverage, q4 REML, native-TMB q4 REML, q4 AI-REML,
  HSquared AI-REML, and non-Gaussian AI-REML remain outside support.
- Ordinary q6/q8 diagnostic routes do not imply structured q6/q8 support.
- Poisson and NB2 q1 structured `mu` intercept rows are first non-Gaussian
  point-fit slices. They do not imply non-Gaussian structured slopes, q2/q4,
  REML, or interval support.
- Direct SD target visibility does not create derived-correlation interval
  support. Direct SD profile feasibility and derived correlation interval
  reliability are separate cells.

## Why the Older Work Drifted

The first q-series waves were productive because they chose valuable cells
instead of waiting for a perfect architecture. The drift came from not treating
the cell as the shared evidence unit. A q-dimension, endpoint set, provider,
estimator, bridge route, extractor status, interval status, coverage status,
and public claim could be updated in different places at different times.

That made q-neighbour inference tempting:

- q4 worked, so q2 or q1 might be assumed;
- q1 `mu` plus q1 `sigma` might be treated like labelled q2;
- an ordinary q8 diagnostic route might be read as structured q8 planning;
- a direct SD profile row might be read as derived correlation interval
  support.

Ayumi exposed the same issue from another direction: a univariate phylo
location-scale model with random effects in both `mu` and `sigma` can work
while the half-cell without a scale random effect can still fail or be
unproven. Balanced or larger cells therefore never license unsupported
half-cells.

## Authority Rule

Dashboard sidecars are the source of truth for structured random-effect status.
README, NEWS, design notes, check-log entries, PR text, and narrative
summaries are derived. If narrative text disagrees with a validator-owned
dashboard sidecar, use the stricter and newer dashboard row until the prose is
reconciled.

For this q-series map, `structured-re-q-series-support-cells.tsv` is the
first row-level authority for completion planning. A public support statement
must name the exact row components: formula cell, provider, endpoint set,
route, estimator, interval status, and coverage status.

`structured-re-mu-slope-fixture-audit.tsv` records the current one-slope
Gaussian structured `mu` artifact evidence for `phylo()`, `spatial()`,
`animal()`, and `relmat()`. These rows bank source-tested DGP, smoke-summary,
and grid-writer evidence plus extractor identity. They do not promote bridge
fixture parity, residual-scale slopes, labelled structured slope covariance,
interval reliability, or coverage.

`structured-re-mu-slope-parity-fixture.tsv` records the next gate for those
one-slope Gaussian structured `mu` cells. It banks deterministic same-target
native/direct/R-via-Julia fixture contracts for `phylo()`, fixed-covariance
`spatial()`, and A-matrix `animal()` cells. The `relmat()` row remains planned
until the K-versus-Q fixture source is reconciled. The sidecar is fixture
evidence only: it does not promote broad bridge support, residual-scale slopes,
labelled structured slope covariance, interval reliability, or coverage.

## Implementation Order

The efficient completion order is:

1. Keep this support-cell table and validator contract green.
2. Banked in this slice: add neutral structured metadata wrappers and
   endpoint/member/coefficient identity in `structured_effects()` before adding
   new runtime model cells. The extractor now records provider, matrix
   slot/source/role, compact precision fingerprint, endpoint set, coefficient
   set, covariance layout, member levels, endpoint blocks, and endpoint
   covariance labels for `phylo()`, `spatial()`, `animal()`, `relmat()`, and
   `phylo_interaction()` rows.
3. Banked in this slice: add provider contract tests for `phylo()`,
   `spatial()`, `animal()`, `relmat()`, and `phylo_interaction()`: matrix
   digest, level alignment, input scale, precision/covariance source,
   missing-level policy, and provenance.
4. Banked in this slice at extractor and artifact level: verify Gaussian one
   independent structured `mu` slope identity and source-tested DGP,
   smoke-summary, and grid-writer artifacts across `phylo()`, `spatial()`,
   `animal()`, and `relmat()`. Runtime status stays at the exact point-fit
   cells already recorded in the support-cell table; bridge fixture parity,
   intervals, and coverage remain separate gates.
5. Banked in this slice for `phylo()`, fixed-covariance `spatial()`, and
   A-matrix `animal()`: add same-target native/direct/R-via-Julia bridge
   fixtures for one independent structured `mu` slope. `relmat()` remains a
   planned parity row until the K-versus-Q fixture source is reconciled.
6. Add or verify `sigma` one independent slope cells.
7. Add matched `mu+sigma` slope diagnostics.
8. Add bivariate structured slope covariance.
9. Add structured q4 slope blocks.
10. Leave two-slope structured q6/q8 cells planned until the one-slope cells,
   metadata wrappers, provider contracts, bridge parity, interval diagnostics,
   and coverage denominators are stable.

Bridge parity, REML language, intervals, coverage, and public support move only
after the exact cell passes the evidence ladder. No row in this note promotes
DRAC execution, broad R bridge support, public optimizer controls, q4 interval
coverage, q4 REML, HSquared AI-REML, or non-Gaussian AI-REML.

## Future Lesson

For every future structured random-effect feature, write the support-cell row
first. Then code, tests, dashboard, docs, check-log entries, after-task notes,
and PR wording all update against that row. That keeps useful evidence from
accumulating faster than the public truth can track it.
