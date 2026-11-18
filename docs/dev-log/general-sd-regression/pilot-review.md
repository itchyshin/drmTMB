# Bernoulli SD pilot review

Read-only review of `bernoulli-pilot-design.md` and `run-bernoulli-pilot.R`.

## Findings

The generator matches the stated target: Bernoulli observations use the logistic mean `-0.3 + 0.6 x + exp(log(0.8) + a w) u`, with one standard-normal intercept per group. The fit uses the corresponding `sd(id) ~ w` formula. The current extraction of profile endpoints as `ci$lower` and `ci$upper` agrees with the native profile test; `conf.low`/`conf.high` are not the right fields here. The six pilot attempts are retained as rows, including fit/profile errors, so the all-attempt denominator can be reconstructed. The design also correctly says that six pilot fits do not establish coverage and reserves calibration for the larger campaign.

Before using the pilot as a workload or readiness gate, make these bounded changes:

1. **Bind the run to the profile implementation and installed binary.** The manifest hashes the principal R/C++ sources and helper/runner, but omits `R/profile.R`, the design file, and the compiled library actually loaded from the temporary library. Record those hashes plus `packageVersion("drmTMB")`, the loaded DLL path, and its digest. This matters because the run's target is a profile interval and source hashes alone do not identify the executable likelihood.
2. **Freeze the interval request and define validity.** Pass `level = 0.95` explicitly. Record `profile.boundary` and `profile.message` (and any profile method/status field available), then define a valid interval as finite, ordered endpoints with the intended successful status and no boundary/clamp limitation. Keep invalid intervals in the attempt table and count them as misses for any all-attempt coverage calculation.
3. **Add a compact denominator receipt.** Summarize attempted fits, fit successes, converged positive-Hessian fits, valid intervals, profile failures, and boundary/clamp-limited intervals by condition, while preserving the row-level CSV. Do not silently drop errors or calculate coverage only among valid intervals.
4. **Make the objective check a gate with a precise claim.** `binomial_sd_laplace_oracle()` is an independent implementation of the scalar Laplace objective, not an exact marginal-likelihood oracle. Label the field accordingly, set a predeclared discrepancy tolerance, and fail the pilot gate when exceeded. Do not infer that Laplace approximation error is negligible from agreement between two Laplace calculations; higher-order integration sensitivity remains separate.

The design's current **2–5 minute** estimate addresses the earlier two-minute concern, but remains provisional: the roughly 30-second profile timing came from a smaller, lower-level interval test than this pilot. Retain the five-minute stop-and-report bound, measure the six-fit local pilot before dispatch, and use the measured time for any Totoro estimate. No simulation was run for this review.

## Review status

CI field mapping and generator/target alignment: checked. Attempt rows preserve ordinary fit/profile failures; explicit denominator summary and interval-validity rule: still needed. Objective check is independent at the implementation level but not an exact-likelihood oracle. Coverage/calibration claims: appropriately deferred by the design. This review does not certify a run or the broader family-by-random-effect programme.
