# After-task: first q-series coverage evidence — local SR475 sigma + q2 grids

Meta: 2026-06-27 · Claude (ultracode) session · the q-series completion lane's
first executed coverage evidence. drmTMB was installed and run LOCALLY on this Mac.

## 1. Goal

Produce the decisive missing rung of the q-series ladder — coverage — for the
sigma-slope and q2-slope lanes, which had 0% coverage evidence and were assumed
cluster-gated. Test that assumption, run the grids, verify, and bank honestly.

## 2. Implemented

- **Installed drmTMB locally** (`R CMD INSTALL` into the user library, TMB model
  compiled). The "coverage needs the cluster" framing was wrong: the *agent* is
  transfer-blocked from fir, but the grid itself is ~1 s/fit, so a full grid is
  ~7–10 min on this Mac.
- **Ran the full SR475 sigma-slope grid** (7 admitted targets × 475 reps, 7 shards
  in parallel) and the **SR475 q2-slope grid** (10 targets × 475 reps). All
  475/475 converged, 0 boundary, for every target.
- **Fixed the MCSE gate** in all 3 coverage runners: floor on `planned_reps >= 475L`
  (was the grid run at scale?), then take the binomial MCSE on the actual finite
  denominator. The prior `n_wald_fin >= 475L` floor was wrong — non-finite
  intervals drop the finite count below 475 even at a full run, so it returned
  `NA` for every target. (Found only by running the grid; Fisher/Rose had approved
  the untested version.)
- **Banked** `docs/dev-log/dashboard/structured-re-slope-coverage-results.tsv`
  (17 rows: 7 sigma + 10 q2) with per-target measured coverage, corrected MCSE
  gate, channel-trust flags, and verdict; registered it in the validator;
  preserved the raw replicate+summary TSVs under
  `docs/dev-log/simulation-artifacts/2026-06-27-{sigma,q2}-slope-coverage-grid-local/`.

## 3. Results (Fisher + Curie independently verified; DGP↔model aligned)

**Sigma-slope — WALD coverage near-nominal (the trustworthy channel):**

| provider/target | Wald cov | Wald MCSE | MCSE≤0.01 | bias |
|---|---|---|---|---|
| phylo sigma:(Int) | 0.941 | 0.0109 | no (borderline) | −0.054 |
| phylo sigma:x | 0.994 | 0.0037 | yes | −0.026 |
| spatial sigma:(Int) | 0.991 | 0.0045 | yes | −0.086 |
| spatial sigma:x | 0.991 | 0.0044 | yes | −0.030 |
| animal sigma:(Int) | 0.974 | 0.0073 | yes | −0.072 |
| relmat sigma:(Int) | 0.941 | 0.0109 | no (borderline) | −0.057 |
| relmat sigma:x | 0.996 | 0.0030 | yes | −0.021 |

5/7 clear MCSE ≤ 0.01; phylo + relmat sigma:(Intercept) sit at 0.0109 (coverage
0.94 → ~560 reps to tighten). **Sigma PROFILE coverage is censoring-suspect** and
must NOT be used as a reliability channel: the non-finite profile reps are exactly
the high-shrinkage reps where the SD collapsed toward 0 — the reps Wald MISSES — so
profile coverage (0.96–0.99) is selection-inflated by ~2pp. Report Wald.

**Q2-slope — UNDER-nominal (a NEGATIVE result):** Wald 0.874–0.905, profile
0.897–0.918, all ~4–5 MCSE below 0.95, all 475/475 finite. SD-slope targets carry
~−0.08 bias (g=8 shrinkage → off-centre + slightly narrow Wald); the unbiased
correlation target still under-covers (~0.89) from a ~27% Wald SE deficit on 8
levels. **Intervals are not reliable for these targets.** More groups, REML-style
bias correction, or bootstrap-on-bias-corrected estimates would be needed.

## 4. Files Touched

- `tools/run-structured-re-sigma-slope-coverage-grid.R`,
  `…-q2-slope-…`, `…-q4-location-…` (MCSE gate floor → `planned_reps`)
- `docs/dev-log/dashboard/structured-re-slope-coverage-results.tsv` (new, 17 rows)
- `docs/dev-log/simulation-artifacts/2026-06-27-sigma-slope-coverage-grid-local/` (14 TSVs)
- `docs/dev-log/simulation-artifacts/2026-06-27-q2-slope-coverage-grid-local/` (20 TSVs)
- `tools/validate-mission-control.py` (register coverage-results sidecar)
- this after-task; `docs/dev-log/check-log.md`

## 5. Checks Run

- drmTMB 0.1.4 installed + loaded locally; both runners ran end-to-end.
- `Rscript --no-init-file -e 'parse(...)'` on all 3 runners: OK.
- `python3 tools/validate-mission-control.py`: `mission_control_ok`, 104 q-series
  cells, 17 slope coverage-results rows.
- **Fisher** (`inference_reviewer`) + **Curie** (`simulation_tester`) independently
  verified: DGP↔model alignment for both grids; sigma Wald trustworthy (and the
  Wald-on-sane-half-width subset matches full Wald to 3e-4, no exploded-interval
  inflation); sigma profile censoring is informative; q2 under-coverage is real
  (Curie reproduced the SD shrinkage in an independent slice); the MCSE-gate fix.
- Every reported number reproduces exactly from the raw replicate TSVs.

## 6. Tests of the Tests

- DGP draws the structured effects with the SAME package covariance functions the
  model fits against (same tree/coords/A/K), so coverage is against the true
  estimand, not a mismatched DGP.
- Reported coverage is on retained denominators (nonconverged/boundary retained
  when the interval is finite); the finite-interval fractions are recorded so
  censoring is visible (sigma profile especially).

## 7a. Issue Ledger

- Fixed: MCSE-gate floor (`n_wald_fin` → `planned_reps`) in all 3 runners.
- Surfaced (not promoted): q2-slope intervals under-cover — a real reliability
  gap, banked as a negative.
- Deferred (next gate): the formal `coverage_status` promotion off `planned`.
  It is blocked here by design — 24 validator cross-checks assert
  `coverage_status == "planned"` (the discipline guard), and promotion also
  requires interval reliability (still `planned`). This sidecar is a measurement,
  not a promotion; the cells stay `planned`.

## 8. Consistency Audit

- 17 coverage-results rows ↔ 8 linked support cells (4 sigma, 4 q2), all still
  `coverage_status = planned`; the validator enforces that linkage.
- The 2 borderline sigma targets are flagged FALSE (MCSE 0.0109), not rounded to
  pass. q2 verdict is explicitly the negative `under_nominal_intervals_unreliable`.
- Excluded holdouts (animal sigma:x, animal/relmat cor) stay unmeasured — no
  half-cell inference.

## 9. What Did Not Go Smoothly

- The reviewed-but-untested MCSE gate (`n_wald_fin >= 475`) was wrong in practice;
  only running the real grid exposed it. Lesson: a gate that can only be exercised
  by live data should not be trusted on source-review alone.
- Sigma profile intervals have a real non-finite rate (down to 71% finite) that is
  informatively censored — caught by Fisher/Curie, not by the runner's own summary.

## 10. Known Residuals

- `coverage_status` promotion (off `planned`) is the next gate — needs the 24
  cross-check update + interval reliability; it is a coordinated change, deferred.
- 2 sigma intercept targets need ~560 reps to clear MCSE ≤ 0.01 (could run locally
  or on the now-available clusters).
- q2-slope intervals are unreliable; this lane cannot progress toward `supported`
  without a fix to the interval method or design (more groups / bias correction).
- These commits are LOCAL (the `Bash(git push *)` deny rule blocks push); they
  land once the maintainer clears it.

## 11. Team Learning

The single most important move this session was **challenging an inherited
assumption**, not adding more verification: the prior handover framed coverage as
cluster-only, so the decisive rung looked unreachable. It was reachable in ~10
minutes locally. And running it for real immediately paid off twice — it exposed a
reviewed-but-untested gate bug, and it turned an unknown (q2 interval reliability)
into a definite, banked negative. Coverage that is *measured* is worth far more
than coverage that is *assumed*, in either direction.
