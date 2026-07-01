# Claude handover — 2026-06-27 (#3): the bias-correction breakthrough

Branch: `claude/local-coverage-grids-sigma-q2` (== `main`, fast-forwarded).
**Nothing pushed to the remote** — `main` is local, ahead of `origin` by this
whole session. The user decides when to push.

Run R as `R_PROFILE_USER=/dev/null Rscript --no-init-file` (the `.Rprofile`'s
R-4.5 lib segfaults R 4.6). Validator: `python3 tools/validate-mission-control.py`
→ `mission_control_ok` (green). Conversion test: FAIL 0 / PASS 6209.

## The headline: `supported` is now in reach, engine-validated

The q2 mu-slope SD cells under-covered at the deployment default g=8 (~0.88
Wald-z). The wall was the **centre** (ML variance-component shrinkage), not the
width — all four interval methods (Wald, Wald-t, profile, percentile-bootstrap)
are centred on the biased estimate. The fix is a closed-form, truth-free **bias
correction**: `sigma_corrected = sigma_ML * g/(g-1)` (shift log-SD by
`+log(g/(g-1))`) combined with the t(df=g-1) width.

- **Engine-validated** (fresh SR475 fits through `confint`, NOT post-hoc):
  pooled **bc+t = 0.954 (MCSE 0.0048) at g=8**, per-cell 0.943–0.964, vs wald_z
  0.884. Artifact: `docs/dev-log/simulation-artifacts/2026-06-27-bias-corrected-engine-coverage-g8/`.
- Cross-g (post-hoc): g=8 0.955, g=16 0.949, g=32 0.963 — nominal everywhere, no
  over-correction at large g. `.../2026-06-27-oracle-bias-correction/`.
- **Key insight:** `g/(g-1)` *is* REML's leading-order variance debiasing in
  closed form (Searle/Casella/McCulloch 1992; Patterson-Thompson 1971). So the
  correction makes REML *less urgent* for these cells (it borrows REML's insight
  without the restricted likelihood, which is underived on the scale axis), but
  not less important in general (it's leading-order/calibrated; REML is exact).
  Fully documented: design doc 219 + `confint.drmTMB` `@references` + 12 verified
  BibTeX entries in `REFERENCES.bib`.

## What shipped (engine features, committed on main)

- `confint(..., method="wald", small_sample_df="group")` — t(g-1) width (commit
  `34cece73`). Helper `wald_target_df`.
- `confint(..., method="wald", bias_correct="group")` — `+log(g/(g-1))` centre
  shift (commit `466d5e2d`). Helper `wald_target_log_bias`. Composes
  independently with `small_sample_df`. Both default `"none"` = byte-identical.
  Both **OPT-IN and SCOPED to location (mu) variance components** — sigma/
  dispersion SDs already over-cover, so the correction is NOT applied to them.
- Group count `g` resolves from `object$model$structured$phylo_mu$group_levels`
  (NOT the empty covariance_blocks registry, NOT the augmented `n_re`).

## THE LIVE ARC — pick this up first

A six-reviewer `supported`/`inference_ready` sign-off panel was **in flight when
this session stopped** (the user asked to stop). Re-run it:
`Workflow({scriptPath: ".../workflows/scripts/supported-promotion-signoff-wf_20ab847f-1a1.js"})`
or author a fresh one. It must decide:

1. **Tier earned** — `inference_ready` vs `supported`, given engine-validated
   nominal-at-g=8 + the full ladder (point-fit + fixture + interval-feasible +
   g=8 coverage). Fisher's prior "supported-for-g≥N is design-inappropriate"
   ruling is plausibly RESOLVED because coverage is now nominal AT the deployment
   default g=8 — but confirm.
2. **THE OPEN TENSION (decisive):** the correction is **opt-in**. The DEFAULT
   `confint(method="wald")` still under-covers (~0.88) at g=8; nominal needs the
   explicit `small_sample_df="group", bias_correct="group"` call. Does a cell
   count as `supported` when nominal coverage requires a non-default call? Or
   should the correction become the **DEFAULT** for structured-RE SD targets
   (a policy decision — would break the parity fixtures, needs fixture regen)?
   This is the maintainer's call (Pat + Darwin will weigh communicability).
3. **coverage_status** — currently `planned` on all cells; should it promote off
   `planned` for these 4 (we now have engine-validated coverage)?
4. The exact `claim_boundary` wording and remaining gates.

## If the panel clears → the coordinated promotion (same pattern as before)

The `interval_feasible` promotion (commit `5c1008ec`) is the template. To move
the 4 q2 cells (`qseries_{phylo,relmat}_q2_mu1_mu2_one_slope`, TSV rows 17 & 59)
to `inference_ready`/`supported`:

- `tools/validate-mission-control.py` has 3 cell-id-keyed helpers
  (`_qseries_interval_status_within_planned_or_certified`,
  `_planned_field_violation`, `_expected_value_violation`) + the
  `CERTIFIED_INTERVAL_FEASIBLE_CELLS` set that relax the ~96 anti-over-promotion
  guards for exactly the certified cells. A higher-tier promotion needs the
  helpers extended to admit the new `interval_status` value (and, if
  coverage_status moves, the coverage_status guards relaxed the same cell-id-keyed
  way). EMPIRICAL METHOD: flip the rows on a scratch copy, run the validator,
  fix what fires, iterate (that's how the 96 were found).
- `tests/testthat/test-structured-re-conversion-contracts.R`: the q2
  interval_status assertions are already order-robust
  (`ifelse(cell_id %in% c(<4 certified>), "interval_feasible", "planned")`) — a
  new tier needs those updated. coverage_status assertions are still `rep("planned")`.
- ROSE-PRINCIPLE CHECK: after promoting, flip a NON-certified cell on a scratch
  copy and confirm the validator STILL rejects it (guards scoped, not weakened).
- `claim_boundary` must carry the opt-in caveat (name the exact `confint` call;
  state the default under-covers) + the boundary caveat (Self-Liang).

## Earlier-session context (all committed, on main)

See `docs/dev-log/2026-06-27-session-review-note.md` for the fuller record:
- [gllvmTMB#565](https://github.com/itchyshin/gllvmTMB/issues/565) advisory ("t
  is not always better") posted.
- 42 superseded drmTMB PRs closed.
- 4 cells promoted to `interval_feasible` (six sign-offs; commit `5c1008ec`).
- 4 pre-existing artifact-path test failures fixed (commit `c5d1716c`).
- REML ruled out as the g=8 fix (adversarial scoping; commit `148329d1`,
  after-task `2026-06-27-reml-unblock-scoping.md`).

## Commit chain (newest first, all on local `main`)

`e89eb02f` engine-validate + citations + doc 219 · `466d5e2d` bias_correct
feature · `ca3f7aed` closed-form breakthrough · `c2594490` bootstrap negative ·
`4cdb18f0` oracle bias-correction · `d326f7a8` all-4-methods-centred · `c5d1716c`
test fix · `5c1008ec` interval_feasible promotion · (earlier) `34cece73` t-Wald,
`148329d1` REML scoping.

## Open / deferred

- Push to remote (user's call).
- Validate the engine at g=16/g=32 (currently only post-hoc there).
- Extend the bias correction to sigma/q4 cells only after per-class simulation
  validation (it's calibrated; do not assume it generalizes).
- The default-vs-opt-in policy decision (maintainer).
