# After-task: promote 4 g=32-certified cells to interval_feasible

Meta: 2026-06-27 · Claude (ultracode) · the first machine status promotion of the
structured q-series interval rung. Six sign-offs obtained before any edit.

## Decision and authority

Promote exactly four cells from `interval_status = planned` to `interval_feasible`:
`qseries_phylo_q1_sigma_one_slope`, `qseries_phylo_q2_mu1_mu2_one_slope`,
`qseries_relmat_q1_sigma_one_slope`, `qseries_relmat_q2_mu1_mu2_one_slope`.
`coverage_status` stays `planned` on all cells; nothing reaches `inference_ready`
or `supported`. spatial + animal stay `planned` (no g=32 run / interval rung).

Sign-offs (the HOLD-panel gate): Fisher/Rose/Emmy (interval_feasible is the honest
tier, earlier panel); Pat/`user_tester` + Darwin/`audience_reviewer` =
SIGN_OFF_WITH_CHANGES; maintainer = approved.

## What changed (one coordinated commit)

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`: 4 rows'
  `interval_status` -> `interval_feasible`; `claim_boundary` rewritten per the
  reviewers (q2 leads with the g=8 ~0.91-0.92 number + Wald-t ~0.93; sigma notes
  ~23% g=8 profile non-convergence for sigma:x and that the Wald-t opt-in
  over-inflates sigma SDs; both name `confint(method = "profile")` and state REML
  is not the fix; substrings `same-target fixture` / `slope-only` /
  `interval reliability` / relmat `Q bridge` preserved for the content guards).
- `tools/validate-mission-control.py`: three cell-id-keyed helpers
  (`_qseries_interval_status_within_planned_or_certified`,
  `_planned_field_violation`, `_expected_value_violation`) + a
  `CERTIFIED_INTERVAL_FEASIBLE_CELLS` set. The 96 anti-over-promotion guards
  (direct, `{field}`-loop, and `{field: expected_value}`-dict forms across ~24
  sidecar families) now admit `interval_feasible` for exactly these four cells and
  still pin every other cell to `planned` and every `coverage_status` to `planned`.
- `tests/testthat/test-structured-re-conversion-contracts.R`: 37 hardcoded
  `interval_status == "planned"` assertions on q-series subsets rewritten to the
  order-robust `ifelse(<sub>$cell_id %in% <certified>, "interval_feasible",
  "planned")` form. q4 / coverage_status / non-qseries (sidecar-own) assertions
  untouched.

## Verification

- `mission_control_ok` green with the four cells promoted.
- ROSE-PRINCIPLE GUARD CHECK: flipping a *non*-certified cell
  (`qseries_spatial_q1_sigma_one_slope`) to `interval_feasible` still raises 16
  validation errors -> the relaxation is scoped to the four cells, not global.
- `devtools::test(filter="conversion")`: FAIL 4 / PASS 6205. The 4 are the
  pre-existing artifact-path failures (`file.path(artifact_parts, ...)` building a
  vector), present identically on clean `main`; unrelated to this change.
- `devtools::test(filter="bridge-fixtures")`: FAIL 0 / PASS 739. No other test
  references the four cell_ids' interval_status.

## Boundary (what this is NOT)

interval_feasible is one rung; it is **not** `inference_ready` or `supported`.
`coverage_status` is unchanged (`planned`) everywhere. At the deployment default
g=8 the q2 cells under-cover (~0.91-0.93); the certification is g>=32 profile.
The honest public recommendation remains: profile channel + g>=32. `supported`
needs deployment-g nominal coverage, which is not reachable this cycle (scale-side
REML is a separate, partly-upstream research arc; see
`2026-06-27-reml-unblock-scoping.md`).
