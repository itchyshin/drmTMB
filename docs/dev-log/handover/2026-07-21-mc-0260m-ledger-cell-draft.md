# DRAFT ledger cell `mc-0260m` — meta_V route — FOR SHINICHI'S APPROVAL

Approved to draft (Shinichi, 2026-07-21). **Not landed.** The `claim_boundary` is the
load-bearing field; approve or amend that text and I will insert the row and regenerate.

## Why a new row rather than promoting `mc-0260`

`mc-0260` is `gaussian / mu / fixed / none / ML`, tier `point_fit_recovery`, and its own
boundary says verbatim that `meta_V` is *"outside this census's effect_type/provider axes."*
One row carries one tier, and that row also covers ordinary Gaussian OLS fixed effects. So a
meta_V campaign could not promote `mc-0260` without silently promoting the OLS arm too, and
OLS evidence cannot stand in for meta_V. A separate row is the only honest structure.

The discriminator is column 8, `route_modifier` — which already exists in the schema, so this
is a row insert, not a schema migration.

## Proposed row

| # | column | value |
|---:|---|---|
| 1 | cell_id | `mc-0260m` |
| 2 | source_order | `677` |
| 3 | axis | `model_surface` |
| 4 | family_route | `gaussian` |
| 5 | family_type | `gaussian` |
| 6 | model_type | `1` |
| 7 | route_variant | `base` |
| 8 | **route_modifier** | **`meta_V`** |
| 9 | dpar | `mu` |
| 10 | effect_type | `fixed` |
| 11 | structure_provider | `none` |
| 12 | dimension | `univariate` |
| 13 | q_gate | `na` |
| 14 | estimator | `ML` |
| 15 | capability_status | `implemented` |
| 16 | work_status | `verified` |
| 17 | **evidence_tier** | **`point_fit_recovery`** |
| 18 | test_gate | `na` |
| 19 | tranche_id | `meta-v` |
| 21 | blocking_reviewers | `Rose; Fisher` |
| 22 | primary_evidence_id | `ev-mc-0260m-meta-v` |

## `claim_boundary` — THE FIELD TO APPROVE

> Gaussian meta-analysis with additive known sampling covariance supplied by `meta_V(V = V)` in
> the `mu` formula, fitted by ML with a fitted residual heterogeneity `sigma`. Point-fit recovery
> only: drmTMB agrees with `metafor::rma.uni(method = "ML")` and `rma.mv()` on fixed effects,
> `tau^2` and log-likelihood in the existing comparator smoke tests
> (`tests/testthat/test-comparators.R`). This row carries **no interval and no coverage evidence**
> for either the pooled effect or the between-study SD. A measured degeneracy is recorded rather
> than hidden: at K=12 with true `tau = 0.10` the fitted `tau` pins at approximately 1e-6 and
> `confint()` returns the heterogeneity interval as `[0, Inf]` (reproduced, seeds 4 and 10), so the
> heterogeneity interval must not be reported as usable at small K. Does not admit meta-analytic
> random effects beyond the residual `sigma`, multivariate or bivariate meta-analysis,
> proportional sampling-variance models, latent relatedness, or the deprecated `meta_known_V()`
> alias as a separate claim.

## `next_gate`

> A separately approved, pre-registered coverage campaign is required before any interval or
> inference promotion. `docs/design/48-phase-18-meta-v-ademp.md` must be **amended first**: it uses
> 500 replicates (below this project's own decision-noise floor), names `sigma(fit)` — a point
> extractor — rather than `confint()` as the interval producer, and samples `n_study` at 36 and 72
> only, missing the small-K regime where the `[0, Inf]` degeneracy occurs.

## What this row does NOT do

- It does not promote anything. It creates a place to record meta_V evidence at the tier that
  evidence already supports, which is point-fit recovery.
- It does not resolve Rose's separate `mc-0262` objection (the M=64 threshold contradiction).
  That is still open and is not cleared by creating this row.
- It does not touch `mc-0260`, whose boundary text should eventually gain a pointer here — but
  that edit is claim-surface and I have left it alone.

## Landing checklist (after approval)

1. Insert the row in `docs/dev-log/dashboard/capability-ledger/cells.tsv`.
2. `python3 tools/capability_ledger.py --write` to regenerate derived includes — **never hand-edit
   them**.
3. `python3 -m unittest tools/tests/test_capability_ledger.py` and
   `python3 tools/capability_ledger.py --check`.
4. Note: regenerating touches `vignettes/includes/*`, which is inside the **pkgdown owner's lane**.
   Coordinate before step 2, or hand them the row to land.
