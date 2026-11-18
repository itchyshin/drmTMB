# Derived variance-ratio interval guard review

Independent reviewer: Noether, 2026-11-06. Read-only review of the minimum R/Julia repairs; no fits, numerical-grid runs, suite reruns or repository edits. The original immutable validation copies were left untouched. The guards were uncommitted changes when reviewed; HEAD alone does not identify this snapshot.

## Original coverage gap and blocking verdict

My earlier source review checked generic coefficient intervals, profile/bootstrap entry points and profile-target inventories. It missed the derived variance-ratio accessors. Its inference coverage was incomplete, and its no-blocking-mismatch conclusion did not cover this reachable path.

On the earlier candidate, R's shared `drm_variance_ratio` calculated delta SEs and ordinary Wald limits without an active fixed-prior check (`R/heritability.R`, original lines 281-390, especially 363-388). The new one-intercept Gaussian route could reach that function through all three public accessors, `heritability`, `icc` and `repeatability`.

Julia's shared `_emit_ratio` permitted the profile branch. `_ratio_profile` used `fit.nll` and an ordinary chi-square threshold (`src/heritability.jl`, original lines 199-203 and 257), while `_ratio_status` only warned after calculation and returned a penalized-MAP status (original lines 613-620). The delta path already refused active fixed priors through `bias_correct` (`src/bias_correct.jl:97-98`).

These were blocking violations of the explicit active-fixed-prior interval fence. The fact that tau is unpenalized does not make its ratio intervals ordinary likelihood inference: priors on beta/gamma change the joint estimator, curvature and constrained profile objective. Inverse penalized curvature is not automatically the sampling covariance of that estimator, and an ordinary chi-square threshold is not automatically calibrated for a penalized profile. Neither path had established a Bayesian credible interval. The numerical likelihood/oracle agreement did not resolve this inference gap.

## Minimum repair reviewed

R now invokes `drm_abort_fixed_prior_inference` at the shared `drm_variance_ratio` entry, before the profile/default-delta branches (`R/heritability.R:284-294`). The existing helper checks active resolved fixed-prior precision; a generic MAP label alone does not activate it (`R/fixed-priors-workflow.R:123-135`). This covers all three public interval accessors while preserving zero ridge, no prior and unrelated MAP penalties. The R API has no point-only method on these accessors, so refusing the interval-returning call is appropriate. Point-only `summary()$derived` is unchanged. The roxygen text and generated Rd state this distinction.

Julia now checks `_is_fixed_prior_fit(fit) && fit.estim_method === :MAP` at the start of `_emit_ratio`, before either interval method (`src/heritability.jl:593-596`). All three public accessors reach that dispatch. The predicate identifies the fixed-prior metadata specifically; it leaves the existing generic MAP warning/status behavior intact. Zero ridge remains ML and passes the guard. No point-only ratio mode existed in this dispatch, and the repair adds none. Existing summary, random-effect and data-likelihood accessors remain available; their code was not changed. The docstring at lines 349-350 states that both interval methods refuse active fixed-prior fits.

Bounded source verdict: the minimum guards close the identified public-accessor gap without changing the likelihood, priors, oracle, thresholds, point-only summaries or generic other-MAP policy. Source signoff is conditional on successful receipts for the expanded focused tests and the required final-source regression checks. It does not qualify interval coverage or complete the overall task.

## Tests and source identity

R's new `tests/testthat/test-fixed-priors-variance-ratio-guards.R:12-30` checks all three accessors with delta/profile, verifies the fixed-prior-specific refusal, retains plain/zero-ridge delta results and the existing unsupported-profile error, checks finite point-only summary estimates, and confirms a generic MAP label alone does not trigger this guard. The coordinator reports a red run with six failures, then 24 guarded passes plus 62 existing heritability checks; a separate actual phylogenetic-SD-penalty MAP delta call also remained available after correcting an invalid non-ultrametric test setup. I did not rerun or independently inspect those runtime receipts in this source review.

Julia's new `test/test_fixed_priors_variance_ratios.jl:12-28` checks all three public delta/profile refusals with the exact reason, plain/zero-ridge estimates, a plain/zero-ridge profile comparison, and continued random-effect/logLik/summary access. Lines 31-41 use an actual phylogenetic-penalty MAP fit to check that the generic penalized-MAP ratio status remains. The coordinator reports three profile failures in the red run and an initial 18-pass guarded run. The later summary assertion, actual-other-MAP additions and existing heritability regression run need their final receipts. Those outcomes are not assumed here.

Snapshot identifiers:

- R HEAD at final inspection: `0abc7a5d83f29d4d2491563b60ff355df634c603`. Guarded `R/heritability.R` SHA-256 `5f38afba7528cd3f7ddef67356f63f9f20179dcc37464bff2ef85e629f7129a5`; Rd `fdb85dd62d7f5b45e8fdce27929df2c4ef9bf091f75b138ce656492812502765`; new test `0cd1680caf23f31469d42ecb1c365f600fbe1a0bb15ab0108997766e3e231992`.
- Julia HEAD: `ae521414b514d34d816912d9120bf735ac52c921`. Guarded `src/heritability.jl` SHA-256 `be2834a87f3d4fc0be2fd06f17d3bd5d9a05b68ae5a4010979575dd4841e3c82`; new test `c20472f2071adcc03658f08f60db06e53caa46a9d0fc4114f25f9f066f842378`.

The earlier R251d103b/Juliaf60eb88e numerical qualification remains evidence for those exact objective implementations. It must not be relabeled as full-suite qualification of these later guarded sources. Record fresh final commits and the necessary affected/full-suite receipts, preserving the still-running original suites and every earlier failed attempt. G5/G6 cannot close on the earlier claim audit alone.

Naturalness self-review: technical correction review, entire draft, perceived AI-like style 2/10 with moderate confidence. “Its inference coverage was incomplete” states the earlier omission; the shared-entry predicates identify the repair precisely. Science gate: pass for the inference distinction and reviewed control flow. Facts gate: source and test contents checked; runtime counts are explicitly coordinator-reported and latest outcomes remain pending. References gate: local owning source only. Exact-draft prose-validator assessment: NOTASSESSED. Mechanical slop-check output is retained in the tool receipt.
