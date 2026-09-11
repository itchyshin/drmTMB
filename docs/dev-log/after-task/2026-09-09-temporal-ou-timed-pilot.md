# After Task: temporal OU timed pilot

**Branch:** `codex/temporal-ou-v1-20260908`

**Date:** 2026-09-09

**Scope:** measure bounded local OU fitting time, memory, output completeness, and public interval availability without launching a calibration campaign.

## 1. Goal

Produce the measured evidence required before any future OU campaign plan can be considered: a fixed-seed local timing pilot with resource accounting and retained diagnostic denominators.

## 2. Implemented

`tools/run-temporal-ou-pilot.R` fits five fixed seeds for each of three irregular-time cells: combined short-series OU, combined persistent OU, and OU-only. It retains 15 selected-fit rows, 30 positive-decay starts, interval status, Hessian status, warnings, and errors. The pilot was run once with macOS `/usr/bin/time -l`; G9 now requires the resource receipt and every output field needed to interpret availability.

## 3a. Decisions and Rejected Alternatives

The pilot records the guarded Wald interface exactly as users encounter it. It does not bypass the OU guard to compute a conditional covariance merely because all 15 numerical Hessians are positive definite. That would confuse numerical regularity in this small fixture with the missing AR1 coverage qualification. The pilot does not start, estimate, or authorize a larger calibration campaign.

## 4. Files Touched

The pilot runner and G9 verifier are in `tools/`. Retained outputs are under `docs/dev-log/simulation-artifacts/2026-09-09-temporal-ou-pilot/`. The ledger and check log point to this evidence.

## 5. Checks Run

| Check | Outcome |
| --- | --- |
| `/usr/bin/time -l Rscript --vanilla tools/run-temporal-ou-pilot.R` | `TEMPORAL_OU_PILOT_PASS`; 30.33 seconds wall time; 569,245,696-byte maximum resident size. |
| `Rscript --vanilla tools/temporal-ou-gates.R G9` | `TEMPORAL_OU_G9_PASS`. |
| Output completeness | 15/15 finite selected fits and 30/30 retained starts; no pilot warnings or errors. |
| Hessian and interval status | 15/15 positive-definite Hessians; 0/15 available public Wald intervals and 15/15 explicit guard diagnostics. |

## 6. Tests of the Tests

The runner fails after retaining evidence if the declared 15 rows, 30 starts, finite selected objectives, or positive elapsed times are incomplete. G9 additionally requires the resource receipt, source commit, matching runner hash, interval/Hessian/warning/error columns, and full per-fixture starts. Removing the resource record or a diagnostic column makes G9 fail.

## 7a. Issue Ledger

No issue was opened or edited. This is an unpushed local implementation lane.

## 8. Consistency Audit

The pilot uses the same OU formula grammar and positive-decay starts as the recovery fixture. Its `interval_status` records the same public guard tested in the vignette and methods. The source commit and runner hash are retained independently of later documentation commits.

## 9. What Did Not Go Smoothly

The initial resource-accounted command completed without displaying its standard output in the tool stream, so the retained files and G9 were inspected directly afterwards. The receipt and every required output were present; no run was repeated or filtered.

## 10. Known Residuals

The pilot shows that local timing and memory are modest for these 15 data sets, but it provides no coverage result. The shared AR1 C1 residual-variance boundary remains unresolved for Wald inference. G7, G14, and G15 remain open; no remote campaign, profile inference, or forecast was launched.

## 11. Team Learning

Positive-definite Hessians on a small timing fixture do not qualify an interval interface whose calibration prerequisite is unresolved elsewhere. Timing, numerical diagnostics, public availability, and scientific coverage must remain separate reported quantities.

## 12. Cross-Product Coverage

This task covers the exact 15-fit Gaussian OU timing fixture, resource accounting, retained starts, and guarded public Wald availability. It does NOT cover mean-coefficient covariance qualification, profile or bootstrap intervals, coverage, variance-component intervals, remote campaigns, non-Gaussian families, REML, temporal slopes, forecasts, new-data prediction, ARMA/Toeplitz, random walks, seasonal states, Matérn, or gllvmTMB.
