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
| P1a | Curated NotebookLM methods synthesis | Ranga, Luna medium | 3-5 days | P0 starts |
| P1b | Symbolic/API/kernel/validation contract | Gauss, Sol high, Boole/Noether lenses | 1-2 weeks | P0 and research |
| P2 | Target descriptors, SD designs/maps/engine contract | Sol high core; Luna medium adapters | 2-4 weeks | contract |
| P3 | Bernoulli both-engine slice and calibrated intervals | Luna medium builds/tests; Sol high review | 2-4 weeks | P2 minimum |
| P4 | Other ordinary families/intercepts/slopes | Luna medium; Sol high coupled core | 3-6 weeks | P3 gate |
| P5 | Correlated/labelled/cross-parameter blocks | Sol high core; Luna medium adapters | 4-8 weeks | P4 |
| P6 | All structured providers and sparse scaling | Sol high design; Luna medium builds | 8-16 weeks | P5 |
| P7 | Bivariate and special-family gaps | Luna medium; Sol high inference | 4-8 weeks | relevant predecessors |
| P8 | Recovery/calibration of advertised domains | Curie Luna medium; Fisher Sol high | 6-12 weeks | rolls with builds |
| P9 | Docs/examples/full checks | writer/Pat/Grace Luna medium | 2-4 weeks | rolls with builds |
| P10 | Independent review and reconciliation | 2 Luna medium + 1 Sol high; Melissa | 1-2 weeks | gates pass |

Full planning range: 40-80 engineer-weeks, about 5-10 elapsed months with 2-3
sustained contributors; first calibrated Bernoulli milestone 3-6 elapsed weeks.
These are forecasts, not measured throughput. Re-estimate after inventory and
pilots. Compute and queue time are separate. At most four live agents including
Ada. Reuse children; at most six new children and one ceiling child per production
checkpoint. Native shared R/TMB files have one writer. Julia has separate
ownership/worktree. Reviewers do not approve their own implementation.

## Evidence and compute

Research: curate 12-20 primary/official sources on identifiability, covariance
scaling, integration and uncertainty. Verify load-bearing claims independently.
No private material. NotebookLM signed-out state is an explicit dependency;
source curation and reversible work may continue, but do not claim synthesis done.

Every row needs deterministic target/coding/simulation/extraction checks,
constant-SD regression, save/reload/refit integrity and independent-DGP recovery.
Calibration is either direct or explicitly reviewed shared-mechanism evidence
with held-out checks and labelled inference domains. Oracles include exact
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
G2 Bernoulli both-engine numerical/recovery/inference. G3 every breadth row
implemented or reviewed structural exclusion. G4 output/refit semantics.
G5 calibrated advertised uncertainty. G6 runnable rendered docs/examples.
G7 full R/Julia/bridge/platform regression. G8 independent review, reverified
evidence and Melissa plan-versus-actual reconciliation.

Unlazy checks precede corresponding work. Keep exact source hashes, seeds,
environments, all-attempt summaries, check logs, after-task reports and recovery
checkpoints. Deliver docs per wave. Audit neighbouring stale support claims.
Ordinary scoped edits/checks/checkpoints/local commits are preauthorised. No
merge/release/publication/security changes/destructive external work, or new
large campaign, beyond the stated gates. No required unimplemented cell is done.
