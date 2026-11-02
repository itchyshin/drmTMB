# Triage pilot close verdicts

Checked against `origin/main` at `75845a3d0f7a8031013875b35dea03160a2663a2` (2026-10-07). These are recommendations only; this pilot did not close or comment on the issues.

#1323 | close-fixed | https://github.com/itchyshin/drmTMB/pull/1368 (`0d07d18d74ec92e8890b240a59f373172b5e1c39`) | The capability vignette and `tests/testthat/test-dinnage-audit-wave1.R` now list lognormal, Gamma, Student-t, and beta-binomial as one-binary `mi()` routes, so the Md-F table no longer claims those families reject `mi()`.

#1250 | keep-open | https://github.com/itchyshin/drmTMB/issues/1232 | No `src/Makevars*`, `drmTMB::openmp()`, or `drm_control(parallel=)` exist on current `main`; the product tracker is still open at #1232 and this engineering checklist is not implemented.

#1469 | keep-open | https://github.com/itchyshin/drmTMB/issues/1452 | The n = 8 scale-test mismatch with `is_converged() = TRUE` is still a live numerical defect; #1452 and DRModels.jl#944 are related convergence-flag issues, not the same scale-invariance claim.

#1470 | keep-open | https://github.com/itchyshin/drmTMB/issues/1470 | Current `main` still has no rank-deficiency or aliasing step for a collinear scale design, so a fit can report `converged = TRUE` while `vcov()` fails.

#1462 | keep-open | https://github.com/itchyshin/drmTMB/blob/75845a3d0f7a8031013875b35dea03160a2663a2/src/drm_response_kernels.h#L11-L22 | `drm_student_log_density()` still uses the unstable `lgamma` difference and `log(1 + z^2/nu)` form, so the large-`nu` logLik excess is not fixed.

#1015 | close-stale | https://github.com/itchyshin/drmTMB/issues/1015 | The issue is an explicitly parked planning item that forbids code, docs, or new issues until a later approval; Transfer B already landed and the remaining transfers are out of this ticket's boundaries.
