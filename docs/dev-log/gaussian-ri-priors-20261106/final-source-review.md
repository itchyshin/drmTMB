> Qualification update: the earlier review below missed derived variance-ratio interval accessors. Its inference-fence signoff is superseded by derived-ratio-guard-review.md. The numerical results remain evidence for their recorded sources; repaired-source qualification is pending.

# Final source review: Gaussian random-intercept fixed-effect priors

Reviewer: Noether. Date: 2026-11-06. Scope: independent read-only review of the approved one-iid-mean-random-intercept extension, including its bridge and inference guards. No engine, oracle, test, protected cleanup or PR #1651 files were edited. No package fits or full suites were rerun for this review; other processes were validating the pinned trees.

Source pins verified directly:

- R worktree `/Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB`: HEAD `251d103b310cde7df68d0db439888f8c16177fbb`, reviewed against `34c907e1`.
- Julia worktree `/Users/z3437171/.codex/worktrees/drmodels-fixed-priors-20261105/DRM.jl`: HEAD `f60eb88eebdaebc3b1ac1babb81aeb942f7dc8e8`, reviewed against `86ee1c2`.

## Verdict

Bounded source-review pass. No blocking mathematical inconsistency was found in the reviewed changes or their objective/reporting dependencies. The assessment covers the admitted route. It does not replace the running pinned validation, qualify intervals, establish recovery or coverage, or approve a merge, push or release. The earlier standalone-oracle review remains separate in `math-review.md`.

## Objective, scale and reporting

The approved model integrates the iid mean intercept out of `y = X beta + Z b + epsilon`, with `b ~ N(0,tau² I)` and residual SD `exp(W gamma)`. Both engines must therefore score the exact marginal Gaussian covariance `V = tau² ZZ' + diag(exp(2 W gamma))`, plus the selected coefficient terms. A normal prior includes its full negative log-density constant; ridge is exactly `lambda theta²/2`. Neither term acts on tau.

R changes route admission rather than introducing a second prior calculation. The existing selector maps only `mu` and `sigma` design columns to the TMB data arrays, with explicit zero-based column conversion and normalized-normal flags (`R/fixed-effect-priors.R:92-133`). TMB adds the selected prior sum once at the end of its joint objective (`src/drmTMB.cpp:7206-7218`). It depends only on beta_mu/beta_sigma, so the latent mode and latent Hessian are unchanged: integrating a beta/gamma-only multiplier preserves that prior once. The Gaussian iid mean-intercept integral is exact under Laplace. No new C++ code or latent-SD prior was introduced in the reviewed diff.

R removes the prior contribution when storing data logLik (`R/drmTMB.R:953-985`) and separates prior and likelihood gradients (`R/drmTMB.R:964-974`). The prior-gradient coordinates use each resolved distributional block and its matrix-column index. This remains correct when the optimizer vector also contains the log group SD.

Julia's existing Woodbury kernel uses `sigma_i² = exp(2 W gamma)` and `tau² = exp(2 log_tau)` (`src/gaussian_ranef.jl:632-656`). The added wrapper scores the data-only ML objective plus `_fixed_prior_value` once (`src/gaussian_ranef.jl:698`). Prior row offsets cover only the mean and residual-scale coefficient blocks (`src/fixed_priors.jl:42-67`); the final log group-SD coordinate is excluded. The constructors retain the full normal constant and zero ridge constant (`src/fixed_priors.jl:26-36`). No Jacobian is added for an optimizer coordinate, which is correct because the priors are on beta/gamma coefficients directly.

Julia stores data-only logLik, keeps the penalized objective available for derivatives, and records the data-only objective separately (`src/gaussian_ranef.jl:829-837`; `src/gaussian_core.jl:457-469`). Bridge flattening exports the same decomposition and gradients (`src/bridge.jl:1903-1912`). The numerical result is a marginal penalized mode, rather than a joint latent/fixed-effect mode.

## Admission, bridge coordinates and unsupported routes

R permits exactly one Gaussian mean intercept bar term, rejects covariance labels and additional bars, and retains exclusions for slopes, scale random effects, structured effects, missing-predictor models and SD formulas (`R/fixed-priors-workflow.R:24-81`). ML-only, unit-weight and dense-design conditions remain. Actual evaluated weights are checked before fitting (`R/drmTMB.R:438-446`), and the built design is checked again before prior application (`R/drmTMB.R:772-778`). Active priors disable the residual log-SD clamp, while zero ridge keeps the ordinary ML control path (`R/drmTMB.R:422`; `R/fixed-priors-workflow.R:9-12,72-78`).

Julia retains ML/default-route restrictions, rejects incomplete responses before ordinary mixed-model response-row dropping, requires complete predictors and unit weights, and checks both fixed designs for full rank (`src/gaussian_core.jl:1033-1048,1066-1071,1107-1117`). Only one mean intercept is routed to the new prior wrapper. The existing wrapper also refuses offsets combined with mean random effects (`src/gaussian_core.jl:962-977`); this review found no silently dropped offset admission. `resolve_priors` mirrors the structural restrictions and validates the grouping column (`src/fixed_priors.jl:88-117`).

The conditional R-to-Julia bridge now requests coefficient-label metadata when priors are present, requires both prior specifications and expected coordinates, prepares those priors before fitting, and flattens with the same labels (`R/julia-bridge.R:7069-7089,7144`). Without priors, it retains the previous branch. On the Julia side, prior preparation strips random-effect terms before constructing the fixed-column schema (`src/bridge.jl:750-760`), resolves literal public names to raw names, and checks the complete ordered resolved coordinate list against `prior_expected` (`src/bridge.jl:762-790`). R checks the returned contract and MAP/ML designation before attaching prior reporting (`R/julia-bridge.R:839-902`). These paths prevent a coefficient prior from being assigned to the group-SD coordinate or silently omitted by the conditional bridge.

The production raw-factor bridge refusal remains in place (`R/julia-bridge.R:3183-3198`). The validation adapter's precomputed indicator representation checks response/group identity and both the original and transported fixed matrices before mapping priors by their frozen column indices (`tools/gaussian-ri-prior-adapters/r-bridge.R:16-38`). It also requires the raw-factor formula to remain refused (`r-bridge.R:41-48`). As adjudicated earlier, this validates the frozen numerical design representation and does not establish raw-factor frontend parity.

## Boundary treatment, inference and regression risks

The log group-SD coordinate represents the tau-zero model only as a limit. The new code neither redefines that limit nor turns its singular log-coordinate curvature into regular interior inference. Julia retains the original Hessian/iteration/convergence checks and boundary advisory path (`src/gaussian_ranef.jl:760-780,829-837`; `src/gaussian_core.jl:950-954`). The earlier independent ri_02/ri_03 checks established negligible covariance perturbations, positive one-sided variance scores and matching boundary objective values, while their reported convergence flags remained true. That evidence is recorded in `math-review.md`; no convergence exception was introduced.

R profile target listings and direct summary targets now mark active-prior intervals unavailable (`R/profile.R:825-829`; `R/methods.R:5491-5495`). Their guard uses positive resolved prior precision (`R/fixed-priors-workflow.R:123-135`), so zero ridge retains ML inference behavior. Julia profile readiness now agrees with its existing interval/profile/bootstrap refusals for active fixed-prior MAP fits (`src/introspection.jl:38-46`; `src/inference.jl:226,332,2244`). Refits retain the fixed-prior specifications (`src/inference.jl:2273-2276`). Local penalized curvature remains distinct from a calibrated confidence interval.

The no-prior Julia objective expression is unchanged when `prior_rows === nothing`; the new branch is reached only with an explicit prior request. Empty Julia prior collections and zero ridge produce zero added objective and an ML designation (`src/fixed_priors.jl:40,66-67`; `src/gaussian_core.jl:459-469`). R zero ridge produces no active TMB prior rows (`R/fixed-effect-priors.R:126-132`). The added tests target objective/gradient/Hessian addition, data-only logLik, selector coordinates, no-prior/zero-ridge behavior, update, unsupported-route refusals and bridge mismatch controls (`test/test_fixed_priors_gaussian_ranef.jl:3-95`; R `tests/testthat/test-fixed-priors-gaussian-ranef.R:1-146`). Their presence is source evidence; this report makes no new assertion that those tests passed.

Remaining qualification work belongs to the running exact-source validation receipts. Retain every failed attempt, the boundary/singular-Hessian warnings, and the numeric-design limitation in the final result. Any later source change requires checking the changed spans and their affected evidence again.

## Review-method note

Graft was queried before source inspection. The review used the exact changed-file diffs and targeted owning-source spans. No subagents were spawned. The source checks covered the admitted coefficient-prior route and its nearby guards; they were not an exhaustive audit of unrelated families or bridge routes.

Naturalness self-review, 2026-11-06: technical review, entire draft, perceived AI-like style 2/10 with moderate confidence. The located examples “adds the selected prior sum once” and “requires the raw-factor formula to remain refused” state mechanisms and evidence conditions directly; no wording repair was needed. Science gate: pass within the stated model, from the equations and owning source. Facts gate: pass for source pins, changes and cited spans inspected here; running test outcomes remain unclaimed. References gate: local-source support checked; no external references used. The style assessment records the reviewer's editorial judgment; it cannot establish authorship. Exact-draft prose-validator assessment: NOTASSESSED. Mechanical slop check initially exited 0 with two low-density “This is” flags; both were removed before the final check.

Final mechanical check: `python3 /Users/z3437171/shinichi-brain/tools/slop_check.py final-source-review.md` exited 0 with zero hits and `FINDINGS: 0`. Both reviewed HEAD pins remained unchanged at the end of inspection; tracked production source had no uncommitted changes. Existing settings/hook edits and the coordinator's STATE.md update were left untouched.
