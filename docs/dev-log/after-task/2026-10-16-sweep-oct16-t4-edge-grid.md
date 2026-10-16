# 2026-10-16: sweep-oct16 lane t4, edge-case grid (drmTMB ca3ddef vs DRModels.jl f71b292)

**Readers:** the maintainer triaging the sweep, and the next agent who changes the convergence flag, separation, boundary or clamp diagnostics in either twin.

## What was done

- 15 edge-case cells × 50 simulated datasets were fitted in both twins from byte-identical CSVs.
- Every fit was classified against an engine-independent reference likelihood and an analytic check of whether the MLE exists.
- No package code changed. The receipt, scripts, data manifest, results and repros are in `sweep-oct16/t4/`; start with `RECEIPT_t4.md`.

## What it found

**drmTMB `is_converged()` is TRUE with no warning when the MLE does not exist.**
- **Complete binomial separation:** 50/50. Commented on #1270.
- **Poisson, low-mean n = 8:** 13 of the 14 datasets with no Poisson MLE (all-zero y, or every positive count at the extreme x). New issue #1553.
- **Common cause:** the inflated-SE screen's `min(SE)` fallback (`R/check.R:1343-1344`) cannot see SEs that inflate uniformly, and `poisson_start()` / `binomial_start()` suppress glm.fit's warnings.

**DRModels.jl has no existence screen on the Poisson route.**
- On all-zero data it returns the start value `log(eps())` after 0 iterations as a converged fit. New issue DRModels.jl#1109.
- An aliased fixed-effect design reports converged, with finite pseudo-inverse SEs and a warning that names the wrong cause. New issue DRModels.jl#1110.

**The twins' `is_converged()` flags disagree on 236 of 700 fits (cells 1–14).**
- 182 of those are at the same optimum: the twins differ only in what the flag means.
- The owner decision requested in new issue #1554 is which meaning both twins share. #1554 also notes that each twin's documentation describes the other twin's semantics.

**Evidence comments on known issues:**
- #1548: Beta false convergence at φ ≥ 1e4. CppAD tape optimisation amplifies the lgamma noise roughly 30-fold; draft #1547 fixes it.
- #1462: Student logLik above the Gaussian supremum, up to +1.02e40; 4 of these fits report converged silently.
- #1469: tiny n. The causes are no finite MLE, the default log-sigma clamp, and genuine bimodality.
- #1470: status update at this pin.
- DRModels.jl #1050 and #969: the RE boundary flag and the near-zero pseudo-inverse SE.
- DRModels.jl #994: multi-start would find the higher of two maxima.
- DRModels.jl #1059: cross-link to #1554.

## Checks

- **Determinism.** The pipeline was re-run from scratch. Every fit in cells 1–14 was identical in both engines, apart from timings.
- **Verification.** Each finding was reproduced at both pins by an adversarial verifier. Each new issue was also checked by an independent skeptic, whose corrections were applied before filing.
- **Toolchain.** R 4.3.3 and TMB 1.9.10 (Ubuntu archive), Julia 1.12.7 (conda-forge). The box toolchain could not be installed because CRAN and julialang.org are blocked in this environment.

## Next steps for maintainers

1. Decide #1554. This decides what #1442, #1509, DRModels.jl#1044 and DRModels.jl#1107 should each do to the flag.
2. Land #1442 (binomial separation) and #1547 (stable kernels). Extend the existence screen to log-link count families (#1553, DRModels.jl#1109).
