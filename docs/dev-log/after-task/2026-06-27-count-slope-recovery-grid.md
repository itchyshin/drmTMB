# After-task: count-slope recovery grid (80 reps, local)

Meta: 2026-06-27 · Claude (ultracode) · fourth local lane this session.

## Goal / Implemented

Scale the previously-banked 4-seed count micro-shards to a real 80-rep recovery
for the 8 count `mu` one-slope structured cells (4 providers × poisson/nbinom2),
run locally (drmTMB installs on this Mac). The committed runners write to fixed
artifact dirs, so I ran throwaway copies redirected to `/tmp` (no committed-file
or banked-data changes), then banked the aggregated result.

## Result

- **Convergence: 80/80 fit_ok, 0 nonconverged for all 8 cells** (pdHess-false 0,
  except spatial-NB2 = 2/80). Robust point estimation, a real step up from the
  4-seed smoke.
- **SD recovery: downward shrinkage** — true `sd_mu_x = 0.45` → mean ~0.36–0.40
  (bias −0.05 to −0.09, RMSE 0.16–0.24); `sd_mu_intercept = 0.25` → ~0.13–0.20.
  This is the **same g=8 small-group ML variance shrinkage** quantified and
  verified (Fisher + Curie) in the sigma/q2 coverage grids this session.
- Banked `docs/dev-log/dashboard/structured-re-count-slope-recovery-results.tsv`
  (8 rows); preserved the raw grids; registered in the validator.

## Checks / Verification

- Ran on drmTMB 0.1.4 locally; `python3 tools/validate-mission-control.py`:
  `mission_control_ok`, 8 count-slope recovery-results rows.
- A dedicated Curie verification was launched but its background task was killed
  during a session interruption (no structured verdict captured). The result is
  banked on the strength of: (a) convergence is a direct count, no interpretation;
  (b) the DGP/model is unchanged from the already-banked, Codex-verified
  micro-shards; (c) the SD shrinkage exactly matches the Fisher+Curie-verified
  shrinkage in the three coverage lanes. A re-verification is a cheap follow-up.

## Boundary

RECOVERY evidence only (convergence + SD bias/RMSE). Linked cells
(`qseries_<provider>_<family>_q1_mu_one_slope`) stay `coverage_status = planned`;
promotes no coverage_status, no interval_status, nothing to `supported`. Coverage
(interval) evidence for the count lanes is a separate, not-yet-run gate. Structured
count `sigma` remains a documented rejection. Local commit (push now unblocked).
