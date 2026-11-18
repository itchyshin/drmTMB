# Synthetic campaign-level operating-characteristic stress test

This simulation records operating-characteristic checks for the staged Bernoulli rule under explicit attempt-level distributions. The retained runs below evaluated earlier gate versions. Following review, approximate t intervals for bias became diagnostics and left the current decision rule. The simulator does not fit models or establish profile-interval calibration.

The simulator creates truths -0.5, 0, and 0.5, with 1,000 attempts per truth at look one and 3,000 additional attempts per truth only when the first-look decision is `look2_required`. It calls `native_sd_staged_decision()`. The current rule evaluates fixed coverage and planned false-positive bands, the validity floor, planned denominators, and the global stopping rule. Bias summaries are descriptive only. Retained outputs from earlier rule versions must be read as historical evidence for those versions.

For each synthetic attempt, a normally distributed estimation error sets the point estimate. A fixed interval width in standard-error units creates lower and upper bounds. Interval validity can depend on that same estimation error. Failed fits are recorded as terminal errors with missing estimates and intervals. At truth zero, every attempt is exactly one of: valid interval covering zero, valid interval excluding zero, or invalid. These categories sum to all planned attempts and preserve the identity that planned coverage plus planned false positives equals the valid fraction. Truth strata are generated independently, representing separate datasets without a shared cross-truth shock; within an attempt, estimate error, interval validity, coverage, false positives, and bias remain dependent through the shared error.

The 11 fixed scenarios represent:

- `nominal`: 99% interval validity and 95% conditional coverage, giving expected planned coverage 0.9405 and planned false-positive rate 0.0495 at the zero truth.
- `undercoverage`, `overcoverage`, `low_validity`, and `log_sd_bias`: isolated departures from the ordinary reference.
- `informative_invalidity`: interval validity correlated with estimation error.
- `joint_lower_boundary`: expected planned coverage 0.925, planned false-positive rate 0.025, and validity 0.95, jointly at their lower bands.
- `joint_upper_boundary`: expected planned coverage 0.975, planned false-positive rate 0.025, and validity 1, jointly at the upper coverage and lower false-positive bands.
- `log_bias_boundary` and `relative_bias_boundary`: stress the descriptive bias summaries while keeping nominal expected coverage. They no longer test acceptance gates. For normal log-scale error with SD 0.12, mean log bias 0.10 implies expected relative `exp(a)` bias above 0.10. The relative-bias boundary instead uses mean log bias `log(1.10) - 0.5 * 0.12^2`, which gives expected relative bias 0.10.
- `fit_failures`: 8% terminal fit errors, reducing the valid-fraction denominator as the real gate does.

Each output row reports early accept, early fail, look-two continuation, look-two outcome counts, and final outcome counts. Look-two acceptance, failure, and inconclusive results have both unconditional campaign probabilities (including the chance of reaching look two) and conditional probabilities among campaigns that reached look two. Exact 95% binomial intervals use the matching denominator; conditional values are unavailable if no simulated campaign reaches look two. The output also includes exact 95% Monte Carlo intervals for each unconditional campaign event and a 95% t interval for expected attempts. These intervals quantify Monte Carlo uncertainty in this synthetic OC experiment; they do not alter the calibration gate's 97.5% Monte Carlo intervals.

Run from the repository root with:

```sh
Rscript tools/general-sd-regression/campaign-oc.R 100 20261020
Rscript tools/general-sd-regression/campaign-oc.R 1000 20261021
```

The arguments are the number of independent campaigns per scenario and the seed. The retained 100-campaign smoke pilot took 15.024 seconds across 11 scenarios. The first 1,000-campaign run is preserved as superseded because its bias-boundary intervals did not preserve nominal coverage. The corrected 1,000-campaign run took 160.852 seconds and is retained with source hashes and environment receipt under `evidence/campaign-oc-joint-corrected-20261019/`.

These scenarios are stylized distributions for checking the decision rule, not estimates of fitted Bernoulli behavior. Their rates and dependence parameters are design inputs. The results can describe how the frozen rule behaves under these assumptions, but cannot select or justify thresholds, count toward fit-based calibration denominators, establish model identifiability, or support a feature-level calibration claim. The original independent-model recovery and uncertainty campaign remains required.

## Corrected campaign-level pilot

The corrected 1,000-campaign run applied the then-current helper gates and global stopping rule to every synthetic campaign. In the nominal scenario, 855 of 1,000 campaigns ended in acceptance (95% exact Monte Carlo interval 0.832 to 0.876), 145 were inconclusive (0.124 to 0.168), and none failed. The second look was required in 973 campaigns (0.961 to 0.982). Mean workload was 11,757 attempted fits per campaign, with a 95% t interval of 11,666 to 11,848. These outcomes reflect the chosen synthetic parameters, including 99% conditional interval validity and the bias gates used at that time; they are historical and do not characterize the current rule or fitted-model performance.

At the joint lower boundary, 116 campaigns failed and 884 were inconclusive; at the joint upper boundary, 61 failed and 939 were inconclusive. The bias-edge scenarios retained nominal coverage and false-positive rates by construction. The log-bias boundary failed the relative-bias gate because its expected relative bias is about 0.113. The relative-bias boundary ended in 57 failures and 943 inconclusive results, with no acceptances. These boundary results describe the earlier sequential rule, which often remained inconclusive when true values sat on a gate boundary. All scenario counts and Monte Carlo intervals are in the retained output file; exact source, helper, seed, and environment hashes are in its receipt.

The script uses fixed seeds and stylized attempt records. It verifies the implementation's joint accounting and characterizes behavior under these chosen scenarios. Independent inference review remains required before inferential use. The bias intervals remain uncalibrated diagnostics. The report contains no fitted interval, parameter-recovery result, threshold, or feature-level calibration claim.

## Current-source inference-review rerun

After review identified that the earlier retained receipt named a different `campaign-oc.R` hash, the then-current script was rerun for 1,000 campaigns per scenario with seed `20261020`. The receipt and full output are in `evidence/campaign-oc-inference-review-20261019/`. The nominal scenario ended with 850 acceptances and 150 inconclusive campaigns; none of the boundary or alternative scenarios accepted. This binds that synthetic result to the script and helper hashes used then. It does not address the rare-tail counterexample for the relative-bias t interval, informative missingness among finite estimates, profile-interval coverage, or fitted Bernoulli behavior. The current contract removes bias intervals from acceptance because those intervals lack validated coverage; retained OC receipts do not validate the revised rule.

## Current rule after the bias decision

The revised rule was run for 1,000 campaigns per scenario with seed `20261022`; output, timing, and source hashes are retained in `evidence/campaign-oc-bias-diagnostics-20261019/`. The nominal scenario ended with 855 acceptances and 145 inconclusive outcomes. The `log_bias_boundary` and `relative_bias_boundary` scenarios had 852 and 847 acceptances because bias diagnostics no longer affect the decision. The `log_sd_bias` scenario failed in all 1,000 campaigns because its interval behavior fell outside the predeclared criteria. Runtime was 157.18 seconds on local R 4.6.0. These results describe only the staged rule under the chosen synthetic distributions; they do not validate fitted Bernoulli intervals or point-estimator recovery.
