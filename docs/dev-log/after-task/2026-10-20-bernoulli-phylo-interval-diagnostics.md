# After Task: Bernoulli phylogenetic SD interval diagnostics

## 1. Goal

Check how profile and parametric-bootstrap intervals behave for a predictor-dependent phylogenetic SD in two independent synthetic designs, and retain the numerical diagnostics needed to interpret the intervals.

## 2. Implemented

Ran the existing 16-tip smoke probe and a larger 48-tip by 24-observation-per-tip diagnostic. No package source or test files were edited. The larger design was run once with a corrected temporary script after the first temporary variant stopped at a stale assertion.

## 3a. Decisions and Rejected Alternatives

Treat these runs as workflow and identifiability diagnostics only. They do not estimate coverage. The 50-refit bootstrap endpoints are based on one simulated dataset and remain too noisy for a coverage claim; the non-positive-definite Hessian also prevents treating the finite profile endpoints as validated inference.

## 4. Files Touched

- Added this after-task report, its assessment record, and the matching check-log entry.
- Temporary run scripts were written under `/tmp` and are not package files.
- No model, test, API, or user documentation source was changed.

## 5. Checks Run

- `Rscript tools/general-sd-regression/probes/bernoulli-phylo-interval-smoke.R`: the 16-tip by 12-observation-per-tip fit returned `clamp_limited` profile status with missing endpoints. Its `R = 2` bootstrap smoke returned finite endpoints from 2/2 successful refits. This only checks dispatch and refitting.
- High-information diagnostic, seed `20261021`, 48 tips by 24 observations per tip: the fitted SD-slope estimate was `0.1244` and the profile interval was `[-0.1301, 0.4572]`, status `profile`, boundary false.
- The same fit had optimizer convergence code 0, maximum absolute gradient `7.61e-11`, and `pd_hess = FALSE`.
- Parametric bootstrap with `R = 50` completed 50/50 refits and returned `[-1.8251, 2.9297]`. This is a single-dataset diagnostic, not calibrated uncertainty.
- Numerical thread counts were pinned to one. The successful high-information run took about one minute. An initial temporary variant completed its refits but stopped at an assertion still expecting two draws; the corrected rerun asserted 50.

## 6. Tests of the Tests

The 16-tip probe checks that the intended profile target resolves, that the weak-information profile reports a clamp boundary rather than fabricating finite bounds, and that bootstrap refits return finite bounds. The larger diagnostic records convergence, gradient, Hessian status, profile status, and bootstrap success count. It does not include an independent likelihood oracle or repeated-sample calibration.

## 7a. Issue Ledger

No issue was changed. The results identify an inference-validation gap for the Bernoulli phylogenetic SD target; they do not change the advertised support boundary.

## 8. Consistency Audit

The low-information and higher-information examples differ in both group count and within-group replication. The profile endpoint status changed from clamp-limited to finite, but the higher-information fit still had a non-positive-definite Hessian. Its bootstrap interval was much wider than its profile interval. These results are consistent with unstable inference in this one simulated realization, not evidence of a universal threshold or a method defect by themselves.

## 9. What Did Not Go Smoothly

The first 48-by-24 temporary run changed `R` from 2 to 50 but retained the probe's `bootstrap.n == 2` assertion. It exited after the refits without printing the interval. A corrected temporary script changed the assertion to 50 and printed fit diagnostics. Future parameterized probes should derive expected counts from the requested `R` value.

## 10. Known Residuals

No repeated-sample profile or bootstrap coverage was measured. Fifty bootstrap draws are inadequate for stable tail quantiles. The finite profile interval from a fit with `pd_hess = FALSE` is not validated. The current evidence also does not establish Julia interval parity, the ordinary Bernoulli SD target's calibrated uncertainty, or inference across other random-effect types and families.

## 11. Team Learning

For model-based interval diagnostics, print optimizer status, gradient, Hessian status, interval status, and successful-refit counts before interpreting endpoint values. Keep exploratory inner-bootstrap runs separate from coverage studies.

## 12. Cross-Product Coverage

This checkpoint covers two native TMB Bernoulli phylogenetic SD interval workflows on synthetic data. It does not cover Julia inference, a calibrated coverage domain, Totoro or DRAC production recovery, or the full supported family-by-effect inventory. The general SD-regression goal remains active.
