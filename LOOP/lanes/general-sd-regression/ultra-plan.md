# Approved general SD-regression programme

Approval: Shinichi, 2026-10-17, explicit request to implement the full plan.
Platform: Codex. The planning-only restriction ended with approval.

## Destination and scope

Implement predictor-dependent latent random-effect SDs for the union of supported
families, endpoint types and random-effect primitives in pinned drmTMB and DRM.jl
sources, on both native TMB and Julia. Include missing base random-effect plumbing
needed for the agreed combinations. Include ordinary intercepts/slopes, correlated
and labelled cross-parameter blocks, phylogenetic, animal, relmat, spatial and
phylogenetic-interaction providers, supported univariate/bivariate layouts and
existing crossed/nested/simultaneous-provider layouts. Temporal mechanisms enter
only when fitted support is established. Each required combination has a row;
unimplemented rows remain outstanding and exclusions require mathematical review.

Exclude new response distributions, more than two responses, random SD-formula
RHS effects, new correlation-regression families and arbitrary new combinations
of dependence structures. Examples and data are synthetic, independent of any
collaborator study. Do not send the drafted email.

## Contract

log(tau[g,a]) = W[g,] alpha[a]. Ordinary covariance is D[g] R[g] D[g].
Structured covariance is tau[g,a] tau[h,c] K[g,h] R[a,c]. Preserve K scaling and
existing correlation maps. For non-unit K diagonal, tau is a multiplier and
marginal SD is tau sqrt(K[g,g]); projected fields use their projected diagonal.

Simple sd(group) resolves only a unique latent target. Activate existing reserved
dpar/coef/block/level selectors for ambiguity. Keep sd1/sd2 and aliases. Use R
fixed-effect coding, interactions and supported transformations without hidden
scaling. SD covariates must be constant at the latent target level after existing
missing-data handling; never average inconsistent rows. Within-group covariates
belong in the random-regression design. Constant SD recovers the prior model.
Bernoulli has no free residual sigma. Target identity survives fit/simulate/
predict/extract/save/reload/profile/bootstrap across both engines.

## Phases and staffing

| Phase | Deliverable | Role/model/effort | Engineering estimate | Depends on |
|---|---|---|---|---|
| P0 | Pinned universe, prior-work reconciliation, ownership | Shannon/Jason, Luna medium | 1-2 weeks | approval |
| P1a (complete) | Curated NotebookLM methods synthesis | Ranga, Luna medium | completed 2026-10-20 | P0 starts |
| P1b | Symbolic/API/kernel/validation contract | Gauss, Sol high, Boole/Noether lenses | 1-2 weeks | P0 and research |
| P2 | Target descriptors, SD designs/maps/engine contract | Sol high core; Luna medium adapters | 2-4 weeks | contract |
| P3 | Bernoulli both-engine implementation, light correctness/recovery checks, public outputs and docs | Luna medium builds/tests; Sol high review | 1-2 weeks (provisional) | P2 minimum |
| P4 | Core ordinary families: Gaussian, Binomial, Poisson, NB2, and Gamma; then Beta and beta-binomial | Luna medium; Sol high coupled core | Re-estimate after route map | P3 |
| P5 | Extend core families across independent slopes, correlated/labelled blocks, and cross-parameter effects | Sol high core; Luna medium adapters | Re-estimate after route map | P4 |
| P6 | Extend core and remaining families across structured providers, crossed/nested layouts, and sparse scaling | Sol high design; Luna medium builds | Re-estimate after route map | P4-P5 |
| P7 | Remaining supported families, endpoints, bivariate routes, and special-family gaps | Luna medium; Sol high inference | Re-estimate after route map | relevant predecessors |
| P8 | Deferred coverage and uncertainty-calibration follow-up | Curie Luna medium; Fisher Sol high | Re-estimate after implementation breadth | separate follow-up; not a blocker to current implementation closeout |
| P9 | Docs/examples and full implementation checks; state interval limits plainly | writer/Pat/Grace Luna medium | 2-4 weeks | rolls with implementation |
| P10 | Independent implementation review and reconciliation | 2 Luna medium + 1 Sol high; Melissa | 1-2 weeks | implementation and regression gates pass |

### Implementation-first sequence (updated 24 October 2026)

Deliver Bernoulli fitting and
public outputs on both engines with targeted numerical/equivalence checks and a
small, fixed-seed recovery smoke before starting coverage campaigns. The smoke
can catch coding, indexing, sign, and gross-recovery errors; it does not validate
95% interval coverage. Continue the same implementation and light-check pattern
through the required family/effect/provider/backend rows. Profile and bootstrap
intervals may be exercised for workflow integrity, but documentation must say
their coverage is not validated and must not present them as calibrated
inference. The coverage campaign formerly specified in P8 is deferred until
after this implementation goal's breadth gate; track it as a separate follow-up
and do not make it a blocker to implementation closeout. This changes sequencing
and current acceptance, not the required family/effect/provider/backend scope.
The Bernoulli calibration gate is active in
`.unlazy/general-sd-regression/GATES.md`; the archived
`docs/dev-log/general-sd-regression/deferred/native-calibration-GATES.md` is
historical evidence only.

### Core-family priority and estimate reset (20 October 2026)

Prioritize Gaussian, Binomial (including Bernoulli), Poisson, NB2, and Gamma
because they are common mixed-model families in lme4/glmmTMB. Add Beta and
beta-binomial next as high-value proportion and overdispersed-binomial routes
for ecological applications. This is sequencing only: every other supported
family, endpoint, random-effect type/provider/layout, and both engines remain
in the finish line wherever identifiable. Family availability in lme4 or
glmmTMB does not imply predictor-dependent random-effect SD support there or
in drmTMB/DRM.jl.

Withdraw the earlier 4-8 elapsed-month estimate. The 19,118-row ledger is a
generated candidate superset with thousands of unresolved or blocked rows, not
19,118 independent implementation tasks. Re-estimate only after a dependency-
clustered audit separates shared machinery, base random-effect prerequisites,
family adapters, engine bridges, and already verified slices. The first core
wave uses targeted numerical/equivalence checks and small fixed-seed recovery
smokes; interval coverage is deferred to a separately tracked follow-up after
implementation breadth.
Compute and queue time are separate. At most four live agents including Ada. Reuse
children; at most six new children and one ceiling child per production
checkpoint. Native shared R/TMB files have one writer. Julia has separate
ownership/worktree. Reviewers do not approve their own implementation.

## Evidence and compute

Research: the bounded NotebookLM synthesis of primary/official sources on
identifiability, covariance scaling, integration and uncertainty is complete.
Its cited synthesis is in
`docs/dev-log/general-sd-regression/notebooklm-methods-review-20261020.md`.
Verify load-bearing claims independently and use no private material.

Every implementation row needs targeted deterministic target/coding/simulation/
extraction checks, constant-SD regression, relevant save/reload/refit checks,
and a small independent-DGP recovery smoke. Keep every failed attempt visible.
These checks establish implementation behavior, not interval calibration.
Calibration is a later gate and is either direct or explicitly reviewed
shared-mechanism evidence with held-out checks and labelled inference domains.
Oracles include exact
Gaussian covariance, scalar-cluster quadrature, sparse/dense and reorder/PD
checks, matched external estimators and method-aware cross-engine comparisons.

Freeze separate pilot/production seeds, null/positive/negative SD slopes,
categorical/continuous/interaction designs, unequal sizes, group/repeat ladders,
correlation and structured cases, rare events/boundaries/confounding, and broken
index/sign/mean-only negative controls. Start high-information then descend.

Inference targets: log-SD coefficients, predefined SD-ratio contrasts and
representative latent/marginal SDs. Profile is the coefficient reference and
joint parametric bootstrap the derived-target reference. Wald requires evidence.
Retain interval/refit failures, boundary and clamp flags; report all-attempt and
conditional coverage. Start 1000 reps/domain; prespecified second stage up to
4000 if inconclusive. Nominal .95 coverage acceptance: exact-binomial interval
inside [.925,.975]; .05 false-positive interval inside [.025,.075]. Freeze
domain-specific recovery/bias tolerances before production and do not adjust
conditions to conceal an ordinary-condition failure.

Mac: small tests/renders, about four cores. Totoro: timed pilots/debug/recovery,
initially 16 workers, maximum 150. DRAC: per-seed arrays for larger/structured/
bootstrap jobs, initially maximum 128 tasks. Verify existing sockets/toolchains;
no Duo or login-node compute. Time/memory/correct-answer pilot precedes any run;
projected >3h requires results plus approval. No campaigns on GitHub Actions.

## Gates and closure

G0 baseline/pinned complete universe. G1 reviewed research/alignment contract.
G2 Bernoulli both-engine implementation, light numerical/recovery checks and
documented interval limitations. G3 every breadth row implemented or reviewed
structural exclusion. G4 output/refit semantics. G5 is calibrated coverage and
uncertainty for every advertised domain; it is explicitly deferred and tracked
as a separate follow-up, not a blocker to implementation closeout.
G6 runnable rendered docs/examples. G7 full R/Julia/bridge/platform regression.
G8 independent implementation review, reverified evidence and Melissa
plan-versus-actual reconciliation. Do not claim calibrated intervals until G5
passes; do not launch a campaign until the current source, runtime estimate,
first-look decision, qualification and required source-bound records are ready.

Unlazy checks precede corresponding work. Keep exact source hashes, seeds,
environments, all-attempt summaries, check logs, after-task reports and recovery
checkpoints. Deliver docs per wave. Audit neighbouring stale support claims.
Ordinary scoped edits/checks/checkpoints/local commits are preauthorised. No
merge/release/publication/security changes/destructive external work, or new
large campaign, beyond the stated gates. No required unimplemented cell is done.
