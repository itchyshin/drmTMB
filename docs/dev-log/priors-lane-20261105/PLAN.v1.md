# DRM priors: mathematical, API and validation proposal

🎯 GOAL

Solo platform: Codex. Deliverable: a reviewed design for explicit regularization in drmTMB and DRModels.jl.
HEADLINE: normal priors on selected fixed effects, with explicit distributional parameter and intercept selection.
IN PARALLEL: read-only sibling-source reconnaissance, completed by a bounded Luna medium scout.
DEFER: general SD priors until fixed effects pass; tmbstan until SD semantics are settled; all release and publication work.
DISCIPLINE: independent objective and derivative oracles; local algebra, Totoro fitting; design review before API implementation.

Status: PROPOSED, 5 November 2026. No prior implementation, fits, sampling, calibration, parity admission, push or merge has occurred in this lane.
Reader: Shinichi and the R/TMB and Julia implementation reviewers.

## Outcome and outside judge

Users should be able to stabilize separation and weakly estimated coefficients while seeing exactly which coefficients receive a penalty. The expert check starts from the data likelihood and final design matrices, not optimizer convergence alone. Exact Gaussian ridge solutions, direct binomial likelihood calculations, finite-difference derivatives and matched glmmTMB examples provide external numerical checks. R and Julia agreeing with each other is an additional check, never the only oracle.

## Ownership and source receipt

The original drmTMB checkout is on `cursor/sweep-blocked-20261004`, with 178 status entries at inspection. It is not this lane's workspace. Its stash and all other worktrees remain untouched. Preflight reported 32 active lanes and duplicate design IDs. This proposal uses a date and subject rather than allocating another numbered design document.

The isolated managed checkout is `/Users/z3437171/.codex/worktrees/drm-priors-design-20261105/drmTMB`, initially clean and detached at `9fea3036791e9bd836e080d9297cd04b1b29c2f8`. Its only claimed path is `docs/dev-log/priors-lane-20261105/`. Implementation leases must be checked and narrowed again after design approval. The Julia checkout is dirty and has not been edited or claimed.

PR #1651 was inspected at `1bf51e2d61bd1ce0a2fb3fad914a9888544af491`. It owns changes including `R/drmTMB.R`, `NEWS.md`, the main check log and parity receipts. No changes to those files are authorized by this design-only lease. Future implementation needs a fresh overlap check and an isolated Julia worktree; an isolated checkout alone does not resolve shared-file ownership.

Sweep receipts:

1. Repository: `git status --short`, `git worktree list --porcelain`, `git stash list`, all-ref branch and prior/ridge/tmbstan history searches. Existing phylogenetic penalty and MSPL are separate estimators; reuse reporting safeguards rather than overwrite either.
2. Siblings: source scout inspected gllvmTMB commit `092fcee6efac54fdc725267f01386e6ba4ca0031`; DRModels.jl `origin/main` is `24ac6ca925a5c0f870b345b18804c9e592d0d275`; GLLVModels.jl `origin/main` is `cac9657fb8b493f03e2d7dccdfc4499886725a9b`. Julia remote main refs were fetched and remained at those inspected hashes. The gllvmTMB local remote-main ref was `49a674c815df43dad51e75bf8d8e981bbca49c8e`; the detailed prior findings here refer to the requested immutable commit, not all subsequent gllvmTMB changes.
3. Brain: vault query `"priors" "drmTMB"`, then all-project query `"fixed_effect_priors" OR "tmbstan"`; results did not establish a prior approved DRM fixed-effect API. Deterministic `rg` over AGENT_LOG, DECISIONS and deep-research README for DRM priors, `092fcee6e` and tmbstan did not locate such a decision. Search absence is bounded by those queries.
4. External: [glmmTMB priors vignette](https://glmmtmb.github.io/glmmTMB/articles/priors.html) and [tmbstan source documentation](https://github.com/kaskr/tmbstan), checked 5 November 2026. These support comparator design, not a claim of drmTMB compatibility. A wider NotebookLM literature review is optional; no novelty claim is proposed.
5. Issues: open drmTMB issue searches for `prior` and `tmbstan` found missing-data prior issues but no clearly matching general coefficient-prior issue. No issues or comments were posted. Julia issue matching remains an implementation-start task.

Verdict: build the general coefficient-prior gap, reuse lessons and safeguards from existing work, preserve separate variance-penalty semantics.

## What already exists

Current drmTMB main has `penalty = drm_phylo_penalty(...)`. `R/penalty.R:1-169` specifies an exponential SD prior expressed as a log-SD density, including its Jacobian. `src/drmTMB.cpp:381-415` evaluates it. It is applied at the univariate and bivariate phylogenetic branches around lines 1576 and 6911. This is not a general fixed-effect prior. `R/drmTMB.R:383-390` explicitly refuses the penalty for the Julia engine. The fit specification builds a TMB object at lines 749-782 and separates the reported penalty from data log-likelihood at lines 925-970. MSPL is a distinct bias-reduction route and must not silently acquire normal priors.

At gllvmTMB commit `092fcee6e`, `R/fixed-effect-priors.R:1-47,114-202` defines exact coefficient selection, normal densities, and an objective adapter with matching gradient and Hessian additions. The helper requires the caller to confirm its stated predictor scaling; its link-aware defaults are not universal defaults for DRM. Its route and inference guards at lines 89-112 and 140-162 deliberately restrict availability. Its diagnostics reconstruct prior-aware objectives too. Reuse these integration lessons, not an assumption that every DRM route already works.

The source scout found no general fixed-effect normal-prior/ridge route in the inspected Julia main sources. DRModels.jl does contain `src/phylo_penalty.jl`, which concerns variance components. Its lines 87-109 document a tree-scale caveat: several Julia routes use raw branch-length covariance while R uses correlation scaling; a named Gaussian route is an exception. Identical SD hyperparameters therefore require matching covariance normalization first. Recheck each actual route, rather than treating this historical comment as proof of its present runtime scale. No blanket claim is made about every unmerged branch or dirty edit.

## 1. Fixed-effect mathematics

For each distributional parameter d, the predictor is eta_d = X_d beta_d + Z_d b_d + offset_d. Location mu describes the response centre, scale sigma its dispersion, shape parameters such as nu other distributional features, and coscale rho12 the residual correlation between two responses. A normal prior here is on a coefficient of eta_d, not on an observation's response-scale mu, sigma or rho12.

Let L(beta, psi) denote the data marginal likelihood, with random effects integrated by the route's documented method. For selected coordinates S:

    P(beta) = sum[j in S] {0.5 * ((beta_j - m_j)/s_j)^2 + log(s_j) + 0.5*log(2*pi)}
    Q(beta, psi) = -log L(beta, psi) + P(beta)
    grad P_j = (beta_j - m_j)/s_j^2
    Hess P_jj = 1/s_j^2

The normal density's reference measure is d beta. There is no additional link Jacobian for a coefficient prior. Include normalizing constants in stored density values. The ridge convention is `0.5 * lambda * sum(beta_j^2)`, so lambda = 1/s^2 and mean = 0. Zero lambda means no penalty; negative or nonfinite lambda fails. Normal SD must be finite and positive; an absent row means no prior.

For fixed effects only, P is independent of b, so it can be added outside integration without changing conditional random-effect modes at a fixed beta, psi. Implementation should add it inside the common compiled TMB objective after route-specific likelihood accumulation, exactly once, so `obj$fn`, gradients, Hessians, rebuilding and future sampling see the same function. Inventory early returns and analytical branches before choosing that insertion point. A fit-wrapper-only addition is insufficient evidence for tmbstan.

Julia implementation must use the same mathematical term in each admitted objective and its analytic derivatives. Do not copy GPL R/C++ source into the MIT Julia package. Record R-side borrowed-source provenance in `inst/COPYRIGHTS` if code is ported from gllvmTMB; mathematical reimplementation and generated parity fixtures must be distinguished from source copying.

## 2. Proposed API, subject to approval

Use a new `priors` argument, retaining existing `penalty` behaviour. Typed constructors avoid evaluating strings:

```r
p <- drm_priors(
  drm_prior_normal(dpar = "mu", coef = "x", mean = 0, sd = 2),
  drm_prior_normal(dpar = "mu", coef = "(Intercept)", mean = 0, sd = 5),
  drm_prior_normal(dpar = "sigma", coef = "all", intercept = "exclude",
                   mean = 0, sd = 1)
)
fit <- drmTMB(bf(mu = y ~ x, sigma = ~ x), data = dat, priors = p)

# Exactly the same coefficient penalty, with explicit ridge precision:
r <- drm_priors(drm_prior_ridge(dpar = "mu", coef = "all",
                                intercept = "exclude", lambda = 0.25))
```

These are proposed calls, not currently runnable examples. `dpar` is mandatory; `coef` is an exact final design-matrix column name or the reserved selector `all`. For `all`, require `intercept = "include"` or `"exclude"`; no silent intercept default. Explicit coefficient selection is literal, including `(Intercept)`. Use model-matrix assignment metadata to identify a conventional intercept, not a name substring. A no-intercept model's level columns are ordinary coefficients; do not guess their scientific roles. Error on an empty selection, unknown dpar/column, overlapping selections, invalid numbers or unsupported route. Never silently recycle means or SDs.

Provide a read-only resolver view showing dpar, coefficient, matrix column, mean, SD, precision and inclusion reason before fitting. Store that resolved table on the fit. Factors and interactions resolve after contrasts, row filtering and rank checks. Report that coefficient priors depend on coding and predictor units. Do not rescale data automatically or assert that standardized priors are scientifically equivalent across links.

The Julia frontend should expose equivalent constructor semantics and resolved tables. Resolve names locally in Julia and validate the bridge payload against both sides. Identical argument intent is a design target; numeric parity is an earned per-route result.

First admission: Gaussian mu/sigma and binomial-logit mu with fixed effects. Next: bivariate Gaussian mu1/mu2/sigma1/sigma2/rho12, then audited shape, zero-inflation and hurdle blocks. Mandatory dpar selection applies to every block. Families and mixed-effect routes remain explicit refusals until tested. Reject REML, MSPL, existing `penalty` combinations and direct SD-formula coefficients in the first slice. Later combination is a separate design, not accidental addition.

## 3. Random-effect SD stage

Separate a prior on an actual group SD from a normal prior on coefficients of an SD regression. Start with one constant independent random-intercept SD. Select by dpar, group and term; then add independent slopes and structured blocks only after their scale maps are verified. Refuse correlated-block ambiguity rather than penalize Cholesky diagonal entries as though they were marginal SDs.

Candidate: Gamma(shape a, rate r) on natural SD s > 0, with a > 1 for a penalty that discourages collapse to zero. In optimizer coordinate z = log(s), natural-SD mode penalized likelihood adds:

    P_sd(z) = r*exp(z) - (a-1)*z - a*log(r) + lgamma(a)

No Jacobian is added merely because optimization uses z. If the target is instead a density with respect to dz, subtract z. These give different MAP estimates: under flat likelihood their SD modes are (a-1)/r and a/r. The API must label the target measure, and tests must recover both distinct answers. Recommendation: natural-SD penalized likelihood for the new SD constructor, preserving the older phylogenetic interface's existing log-SD target unchanged. Require review of this distinction before implementation.

Half-normal and exponential natural-SD priors shrink toward zero and are not automatic remedies for singularity. A positive penalized SD is not evidence of a data-supported random effect. Preserve boundary and prior-sensitivity warnings. Reject SD-regression, covariance correlations and multiple SD-block combinations until separately mapped and tested.

## 4. Inference and reporting

Mark fits as penalized/MAP, store data log-likelihood, prior density contribution and total objective separately, and identify the reference measure. For mixed models, state whether data log-likelihood uses Laplace or another approximation and that it is evaluated at the penalized estimate. Report the penalized gradient and retain the likelihood-only gradient, which need not vanish at MAP.

Inverse penalized Hessian is local posterior curvature under the stated target, not automatically frequentist sampling covariance. Do not call its intervals calibrated or full-posterior intervals. Add deliberate guards for ordinary LRT, AIC/BIC comparisons, profile likelihood intervals, bootstrap interpretation and unsupported prediction/simulation routes. Rebuilding, update(), objective_at(), summaries and diagnostics must retain the resolved priors. Testing only the initial fit would miss lost-prior bugs.

## 5. Independent validation and acceptance

| Gate | Check | Required finding |
|---|---|---|
| G0 | Design and ownership review | API/SD measure agreed, file leases clear |
| G1 | Pure resolver and density tests | Exact selection; no double penalties; malformed and unsupported requests fail |
| G2 | Exact Gaussian ridge oracle with known variance | Coefficients match `(X'WX/v + D)^-1 (X'Wy/v + D*m)`; density, gradient and Hessian agree independently |
| G3 | Separation and multi-parameter fixtures | Finite properly selected binomial estimates; unselected blocks unchanged at a fixed parameter vector; every admitted block contributes once |
| G4 | Numerical checks | Density difference <= 1e-10 on modest fixtures; central-difference gradient scaled error <= 1e-6; Hessian scaled error <= 1e-5; exact Gaussian coefficient error <= 1e-7 |
| G5 | Julia and bridge | Same resolved target; independent oracle on each side, then per-cell cross-engine objective/gradient/coefficient comparisons with stated integration differences |
| G6 | Mixed-effect and SD checks | Dense exact Gaussian integration and 1-D high-accuracy quadrature; SD mode/Jacobian fixtures; compare matching glmmTMB parameterization |
| G7 | Public workflow | Clean install, document/test/check/pkgdown requirements, update/rebuild/report guards, reader example, provenance and after-task report |
| G8 | tmbstan, separately | Joint target and coordinate transformations verified before sampling; analytic posterior benchmark and sampler diagnostics |

These are proposed tolerances for new bounded tests, not changes to any existing signed parity threshold. Approve them before measurement; report failures without tuning them to pass. Mutation checks must detect a dropped sigma prior, penalized excluded intercept, wrong lambda factor, missing derivative, duplicate penalty and dropped rebuild metadata. Multi-parameter tests compare objective differences at a common parameter vector so reoptimization cannot hide incorrect block selection.

No recovery or interval-coverage campaign is authorized by this proposal. Regularization deliberately introduces bias; recovery alone is not a pass criterion. Any later simulation reports bias, RMSE, failure denominators and sensitivity with a declared scientific target.

## 6. Separate tmbstan assessment

The tmbstan documentation accepts a TMB object and defaults to joint sampling (`laplace = FALSE`), including random effects. `laplace = TRUE` integrates them approximately and does not produce their draws. Compatibility must be exercised; presence of `fit$obj` proves neither correctness nor support.

Audit proper priors for every free parameter, constraints, maps, random-effect normalization, overflow guards and objective rebuilds. A natural-SD prior requires the log-SD change-of-variable term in a sampling density, even when natural-SD MAP optimization did not use that term. The same applies to other transformed parameters. Build a clearly named sampling target rather than quietly alter the fitted MAP objective. Never add a second Jacobian to the existing phylogenetic log-density. Refuse unsupported improper targets and estimator adjustments.

First sampler test: Gaussian fixed effects with known variance and a proper normal prior, comparing posterior mean/covariance against conjugate algebra with Monte Carlo error recorded. Second: one Gaussian random intercept with a proper SD prior, comparing the joint sampler against numerical integration. Run at least four chains, record divergences, rank-normalized R-hat and bulk/tail effective sample sizes; declare thresholds before launch. Treat a short startup smoke only as compatibility evidence. No Julia posterior sampler is implied by this stage.

## Execution and compute envelope

Order: fixed effects in both packages, SD priors, tmbstan. Split into small source-pinned slices and review each before widening family coverage. First implementation action: trace callers and enumerate final dpar-to-parameter maps, including analytical and early-return routes. Refresh the graph after substantial changes.

Local work: algebra and one-cell smoke fixtures only, cap about four cores with BLAS threads set to one. Recommend Totoro for compiled package checks and bounded fitting comparisons; DRAC only if a later replicated grid justifies queued arrays. No fits ran during discovery, so runtime is not yet measured. Before any fit, state an estimate from the selected smoke workload; if no credible estimate exists, time one tiny fit first and inspect populated results. Use that timing for the next bounded batch. Do not launch an unestimated campaign. Runs above three hours require pre-run results and approval. Cap Totoro at 150 cores, retain logs/source manifests and stop overruns. Campaigns never use Actions.

After G0, proposed reversible authority: scoped source edits in isolated R and Julia worktrees after leases, failing tests, documentation, local commits and approved checks. Proposed initial checks: resolver unit tests, exact Gaussian oracle, objective/gradient checks and one separation fixture; broaden to required package checks after these pass. Remote push/PR authority: none yet. Must stop for ownership conflicts, changed scientific/API scope, >3-hour runs, merge, release, submission or public messaging. No cleanup or PR #1651 edits are included.

Review decision requested: approve the first fixed-effect slice with exact coefficient selectors and explicit intercept handling. General SD target-measure choice and sampler support remain later, separate gates. Jev is not needed for this small set of technical decisions; no paid decision-model calls were made.

## Review status

Source reconnaissance is complete at the cited refs. Mathematical and API proposals need reviewer approval. No acceptance gate G1-G8 has been exercised. Naturalness assessment and deterministic prose check are recorded beside this file; scientific validation remains open.
