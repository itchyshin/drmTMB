# AI-REML Transfer Gate from HSquared

This note records what `drmTMB` and `DRM.jl` can learn from the
`hsquared` / `HSquared.jl` AI-REML work, and what must not be imported into the
bivariate q4 phylogenetic lane. The reader is the next engine contributor
working on sparse Gaussian restricted likelihoods, q4 inference diagnostics, or
the Ayumi-scale blockers.

The short version is deliberately strict: **borrow the sparse Gaussian mixed
model machinery and validation discipline; do not borrow the AI-REML label for
Laplace, non-Gaussian, or q4 distributional models until a separate derivation
and validation programme exists.**

## Source Map

The scout pass inspected the local sibling checkouts:

- `../HSquared.jl/src/likelihood.jl`
- `../HSquared.jl/src/takahashi_selinv.jl`
- `../HSquared.jl/src/validation_status.jl`
- `../HSquared.jl/docs/design/03-engine-contract.md`
- `../HSquared.jl/docs/design/validation-debt-register.md`
- `../hsquared/R/hs_control.R`
- `../hsquared/R/julia-bridge.R`
- `../hsquared/R/validation-status.R`
- `../hsquared/README.md`
- `../hsquared/vignettes/hsquared.Rmd`

The core implementation in `HSquared.jl` is `fit_ai_reml()`. Each iteration:

1. builds the sparse Henderson mixed-model-equation system for a Gaussian animal
   model;
2. solves for fixed effects and breeding values;
3. computes the variance-component score using a Takahashi selected-inverse
   trace term;
4. forms the average-information matrix by two working-variate re-solves that
   reuse the same Cholesky factor;
5. takes an AI/Newton step with step-halving to keep variance components
   positive.

The uncertainty helpers in `HSquared.jl` invert the REML AI matrix for
asymptotic variance-component standard errors and derive a heritability interval.
Those interval rows stay explicitly experimental or partial unless profile,
coverage, and comparator evidence support more.

The R package `hsquared` adds a second transferable pattern: the ordinary user
path can call the validated estimator, while an advanced path exposes explicit
engine targets and provenance. `validation_status()` is a status table, not a
test runner, and only covered rows may be advertised as working.

## What Transfers

The transferable mathematical object is the exact Gaussian linear mixed model
with known sparse precision for a random-effect block:

```text
y = X beta + Z u + e
u ~ N(0, sigma_u^2 K)
e ~ N(0, sigma_e^2 I)
```

or the equivalent precision form with `Q = K^{-1}`. For `drmTMB` / `DRM.jl`,
this maps to exact Gaussian cells such as univariate Gaussian `phylo()` or
`relmat()` models where the restricted likelihood is a Gaussian restricted
likelihood over fixed effects and variance components.

The useful pieces are:

- sparse MME assembly and solve;
- Henderson determinant identities for the supplied-variance REML objective;
- Takahashi selected-inverse diagonals and in-pattern trace terms;
- parity gates against dense inverses on tiny fixtures;
- AI matrix checks against finite-difference observed information;
- boundary tests that accept a clean boundary/error state but reject NaN
  garbage;
- provenance fields such as `target`, `variance_components_source`,
  `trace_mode`, `converged`, and `boundary_status`;
- row-level validation statuses with `planned`, `partial`, and `covered`
  semantics.

This is enough to justify a future exact-Gaussian sparse-MME pilot. It is not
enough to justify q4 AI-REML language.

## DRM.jl Pilot Candidate

The clean implementation surface is the DRM.jl worktree at:

```text
/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot
```

The parked checkout at `../DRM.jl` remains on `shannon/ayumi-integration` with
uncommitted Ayumi reply/audit drafts and must stay untouched.

The first sparse-MME/AI-REML pilot should start from the exact Gaussian
location-only phylogenetic cell in DRM.jl, not from q4:

```text
y_i = X_i beta + u_{s(i)} + epsilon_i
u ~ N(0, sigma_phy^2 Sigma_phy)
epsilon ~ N(0, sigma^2 I)
```

The local source anchors are:

- `DRM.jl/src/location_only.jl`: defines `LocOnlyProblem`, the Woodbury
  marginal likelihood, the profiled-beta sparse L-BFGS route, and exact
  Takahashi traces `Tr(Q_cond M^{-1})` and `Tr(S M^{-1} S')`.
- `DRM.jl/src/gaussian_core.jl`: exposes this Gaussian phylogenetic mean cell
  through the public `algorithm = :auto` sparse route when the residual scale is
  constant.
- `DRM.jl/src/gaussian_structured.jl`: provides the larger two-structured
  Gaussian sparse path and its selected-inverse trace pattern. This is the
  second candidate after the single-structured pilot is stable.
- `DRM.jl/test/test_two_structured_gaussian_sparse.jl`: already supplies dense
  versus sparse log-likelihood/point-estimate anchors for the two-structured
  Gaussian path and finite-difference gradient checks at the sparse optimum.

The exclusion anchors are just as important:

- `DRM.jl/src/gaussian_locscale_phylo.jl` records that the textbook
  average-information data quadratic was invalid for the sigma-phylo
  location-scale route; that route currently uses clean-gradient or
  observed-information REML language.
- `DRM.jl/src/reml_q4.jl` implements a Patterson-Thompson correction for the
  q4 augmented-state likelihood. It is not HSquared-style two-component
  Gaussian AI-REML.

So the next implementation slice is narrow: isolate or add a supplied-variance
restricted likelihood for the location-only Gaussian phylogenetic mean cell,
then prove it against the existing marginal objective and dense tiny fixtures.
Only after that should an AI matrix or bridge provenance field be added.

Status update from the clean DRM.jl worktree: the supplied-variance restricted
objective, Takahashi trace diagnostic, AI-vs-observed information diagnostic,
boundary fixtures, dense restricted-score diagnostic, sparse-Woodbury
restricted-score diagnostic, sparse average-information diagnostic, and
matching developer optimizer diagnostics, including a guarded
average-information update experiment, tiny recovery-grid diagnostics, a
weak-signal boundary probe, machine-readable simulation-status rows, and a
larger interior stress row are now implemented internally for the
location-only Gaussian phylogenetic mean cell on
`codex/ai-reml-gaussian-mme-pilot`. The focused dense-oracle test is
`DRM.jl/test/test_location_only_reml_mme.jl`.

## Bridge Provenance Sketch

If an exact-Gaussian sparse-MME route is ever surfaced through the R bridge, the
R object should carry estimator provenance explicitly rather than inheriting a
generic `engine = "julia"` label. The minimum fields are:

- `target = "gaussian_loconly_phylo_reml"` for the exact Gaussian location-only
  phylogenetic mean cell;
- `estimator = "supplied_variance_reml"` for the current internal helper, and a
  different value such as `"ai_reml_optimizer"` only after an optimizer is
  implemented and validated;
- `effective_REML = TRUE` for the exact Gaussian restricted objective;
- `variance_components_source = "supplied"` until the variance components are
  estimated by a validated optimizer;
- `trace_mode = "takahashi_selinv"` when trace terms come from the selected
  inverse;
- `information_mode = "ai_vs_observed_diagnostic"` for the current developer
  comparison;
- `boundary_status` with values such as `interior`, `near_zero_variance`,
  `singular_fixed_effect_information`, or `nonfinite_objective`;
- `claim_status = "internal_diagnostic"` until bridge parity, comparator, and
  simulation gates land.

This sketch is deliberately not a bridge promotion. It says how to avoid hiding
the estimator identity if the exact-Gaussian route is later wired through R.

## Explicit q4 Exclusion Row

The q4 bivariate phylogenetic location-scale route remains outside the
HSquared-derived AI-REML claim. Its current honest labels are:

```text
target: bivariate_q4_phylo_location_scale
estimator: ML/Laplace or Patterson-Thompson q4 REML, as actually requested
information: observed-information/profile/bootstrap diagnostics, not AI-REML
status: blocked for 10k-scale sigma-phylo intervals until drmTMB#570 and DRM.jl#293 clear
```

Do not use the exact-Gaussian pilot as evidence for q4 scale-axis inference,
q4 non-Gaussian extensions, full-data Ayumi intervals, or any 10k-scale
sigma-phylo interval claim.

## What Does Not Transfer

The bivariate q4 phylogenetic location-scale model is not the same object as
the HSquared Gaussian animal model. In the Ayumi path, the model has four
phylogenetic axes (`mu1`, `mu2`, `sigma1`, `sigma2`), nonlinear scale
parameters, residual correlation, and an augmented-state likelihood. For that
cell, any REML or interval method has to be derived for the actual objective.

Do not write any of the following without new derivation and evidence:

- "AI-REML solves q4";
- "AI-REML validates bivariate q4 sigma-phylo intervals";
- "HSquared proves q4 REML scalability";
- "non-Gaussian REML" when the implemented method is ML/Laplace, profile,
  bootstrap, observed-information Newton, or another method.

For q4 and non-Gaussian/Laplace routes, use the actual method name and report
the diagnostic state: objective, optimizer, Hessian status, profile/bootstrap
status, boundary flags, and any first non-finite component.

## Evidence Ladder Before Any AI-REML Claim

A future `drmTMB` / `DRM.jl` AI-REML claim must clear these gates for the named
cell:

1. **Derivation gate.** State the exact objective, parameterization, fixed-effect
   restriction, variance components, and random-effect precision. Name whether
   the target is Gaussian REML, ML/Laplace, observed-information Newton, or
   something else.
2. **Dense oracle gate.** On tiny fixtures, match a dense restricted likelihood,
   dense inverse trace, and direct optimizer.
3. **Sparse parity gate.** Match sparse MME log likelihood, scores, traces, and
   fitted point estimates against the dense oracle.
4. **Information gate.** Compare the proposed AI/Newton matrix with an
   independent finite-difference observed Hessian of the same objective.
5. **Boundary gate.** Exercise zero variance, weak signal, near-singular
   precision, high correlation, and failed-profile cases. Return finite
   diagnostics or explicit errors, never silent NaNs.
6. **Simulation gate.** Report bias with Monte Carlo standard error, convergence
   rate, Hessian rate, and interval coverage only if intervals are being claimed.
7. **Comparator gate.** Compare against a same-estimand external Gaussian REML
   comparator where one exists. Bayesian or different-estimand probes are
   agreement evidence only.
8. **Bridge gate.** If surfaced through `engine = "julia"`, record the estimator
   actually fitted and propagate target/status/provenance fields to the R object.
9. **Documentation gate.** Update the capability matrix, validation debt, check
   log, after-task report, and public docs with the same claim boundary.

## Next Ten Slices

These slices should be executed in order. They deliberately separate exact
Gaussian work from q4/non-Gaussian work.

1. **Transfer note.** Bank this design note and make the finish matrix point to
   it. Status: done in `codex/ai-reml-transfer-slices`.
2. **Clean DRM.jl worktree.** Create or use a separate clean DRM.jl worktree for
   engine experiments. Do not use the dirty `shannon/ayumi-integration` checkout
   that holds parked Ayumi drafts. Status: done at
   `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`.
3. **Gaussian sparse-MME source map.** In DRM.jl, identify one exact Gaussian
   sparse-precision cell whose current dense or TMB comparator can serve as the
   oracle. Status: done; first target is the location-only Gaussian phylogenetic
   mean cell in `DRM.jl/src/location_only.jl`, with the two-structured Gaussian
   path as the second candidate.
4. **Supplied-variance REML objective.** Implement or isolate a supplied-variance
   sparse REML objective for that Gaussian cell, with dense parity tests.
   Status: done in the clean DRM.jl worktree for the location-only Gaussian
   phylogenetic mean cell.
5. **Takahashi trace diagnostic.** Add a trace helper or diagnostic that matches
   the dense inverse on tiny fixtures and reports the trace mode. Status: done
   in the same DRM.jl worktree with `trace_mode = :takahashi_selinv`.
6. **AI-information diagnostic.** Add a developer diagnostic comparing the
   Gaussian AI matrix with a finite-difference observed Hessian. Status: done
   as an internal diagnostic comparison, not as an identity claim.
7. **Boundary fixtures.** Add weak-signal, zero-variance, and near-singular
   precision tests that distinguish honest boundary states from numerical
   garbage. Status: done for the location-only Gaussian helper, including a
   degenerate fixed-effect information case.
8. **Bridge provenance sketch.** Draft the R bridge fields needed to carry
   `target`, `estimator`, `effective_REML`, `trace_mode`, and boundary status.
   Status: done in this note; no bridge row is promoted.
9. **q4 exclusion note.** Add an explicit q4/non-Gaussian exclusion row: use
   observed-information/profile/bootstrap language until a q4 derivation lands.
   Status: done in this note.
10. **Issue and dashboard synchronization.** Tie the above to the open engine
    issues (`drmTMB#570`, `DRM.jl#293`, `drmTMB#555`, `DRM.jl#291`) without
    changing Ayumi-facing drafts. Status: done locally in the mission-control
    dashboard and check-log; no GitHub issue comment was posted.

## Next Ten Slices After This Gate

The next batch starts after this exact-Gaussian transfer gate. These remain
claim-bounded implementation or evidence tasks:

1. Add a tiny optimizer experiment that uses the supplied-variance restricted
   objective and records why it is or is not ready to be called AI-REML.
   Status: done as a finite-difference LBFGS diagnostic in the clean DRM.jl
   worktree; it records `ai_reml_ready = false`.
2. Add a same-estimand external Gaussian comparator check for the location-only
   phylogenetic mean cell. Status: partial; the focused test has an independent
   dense GLS same-estimand oracle, but no external package dependency has been
   added.
3. Add a selected-inverse diagonal/PEV diagnostic fixture before any uncertainty
   extractor is considered. Status: done with a Takahashi selected-inverse
   posterior-variance diagnostic checked against a dense inverse.
4. Add a validation-status row in DRM.jl with `planned` / `partial` / `covered`
   semantics for this exact Gaussian cell. Status: done locally in
   `DRM.jl/docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv`.
5. Add an R bridge registry draft row that keeps `r_bridge_status = "planned"`
   and `claim_status = "internal_diagnostic"`. Status: done as an internal
   bridge payload schema tuple in DRM.jl and mirrored here as a design
   boundary; no R object field is promoted.
6. Add a micro scaling smoke for the supplied-variance helper on balanced trees,
   reporting time only as developer evidence. Status: done for 8, 16, and 32
   leaves in the focused DRM.jl test; no speed claim is made.
7. Add an issue comment draft locally for `DRM.jl#291` / `drmTMB#555`, but do
   not post it without maintainer approval. Status: done at
   `docs/dev-log/issue-drafts/2026-06-21-drmjl291-drmtmb555-ai-reml-postgate.md`;
   nothing was posted.
8. Add a q4-specific diagnostic note explaining why the q4 Patterson-Thompson
   correction is not HSquared AI-REML. Status: done in
   `docs/design/179-q4-patterson-thompson-is-not-hsquared-ai-reml.md`.
9. Add a bridge payload schema test once a real R field is wired. Status:
   partial; the DRM.jl internal schema tuple is tested, but no R bridge field is
   wired yet.
10. Re-run dashboard validation and start the live local dashboard copy. Status:
    done locally; the dashboard remains `partial` for this lane.

## Next Twenty Slices After The Post-Gate Batch

This third local batch hardened the exact-Gaussian diagnostic surface. It still
does not promote an average-information optimizer or R bridge row.

1. **Dense REML components.** Add a dense same-estimand REML component helper
   for tiny developer fixtures. Status: done in the clean DRM.jl worktree.
2. **Sparse-vs-dense comparator diagnostic.** Compare sparse and dense `nll`,
   `beta`, and fixed-effect information. Status: done and tested.
3. **Boundary classifier.** Return explicit `interior`, `near_zero_variance`,
   `singular_fixed_effect_information`, or `nonfinite_objective` labels.
   Status: done and tested.
4. **Rank-deficient fixed-effect gate.** Classify singular designs by checking
   fixed-effect design rank before the profile solve can obscure the cause.
   Status: done after the first focused-test failure exposed the gap.
5. **Optimizer dense-comparator gate.** Attach dense-comparator evidence to the
   finite-difference optimizer diagnostic. Status: done and tested.
6. **Optimizer observed-Hessian gate.** Attach finite-difference observed
   Hessian, eigenvalues, and positive-definite status. Status: done and tested
   on the deterministic interior fixture.
7. **Optimizer boundary label.** Attach boundary status to the optimizer
   diagnostic. Status: done and tested.
8. **Combined diagnostic payload.** Bundle boundary, comparator, trace, PEV,
   information, validation-status, and bridge-schema fields for a supplied
   point. Status: done and tested.
9. **Dense comparator in tests.** Check the dense helper against the hand-written
   dense GLS oracle already in the focused test. Status: done.
10. **Boundary invalid-input test.** Check non-finite supplied parameters return
    `nonfinite_objective`. Status: done.
11. **Near-zero variance boundary test.** Check tiny phylogenetic variance
    reports `near_zero_variance`. Status: done.
12. **Singular fixed-effect boundary test.** Check rank-deficient `X` reports
    `singular_fixed_effect_information`. Status: done.
13. **PEV shrinkage sanity.** Check duplicated observations shrink or preserve
    leaf posterior variances. Status: done.
14. **Validation-status refresh.** Update the local DRM.jl validation-status TSV
    to mention comparator, boundary, payload, and optimizer diagnostics. Status:
    done.
15. **DRM.jl check-log entry.** Add a post-gate comparator/boundary check-log
    entry. Status: done.
16. **DRM.jl after-task report.** Add a comparator/boundary after-task report.
    Status: done.
17. **drmTMB after-task report.** Add this 20-slice report on the mission-control
    side. Status: done.
18. **Capability matrix sync.** Refresh the AI-REML-inspired row without
    changing `unsupported` bridge status. Status: done.
19. **Dashboard sync.** Refresh mission-control active text and HSquared blocker
    text. Status: done locally.
20. **Claim-boundary scan.** Re-scan for forbidden q4/non-Gaussian/Ayumi/10k
    phrases and confirm hits are quoted prohibitions or historical guardrails.
    Status: done locally.

## Next Twenty Slices During The Away Run

This fourth local batch keeps hardening the finite-difference diagnostic
scaffold. It remains a diagnostic scaffold, not an analytic restricted score or
AI update.

1. **FD gradient stability helper.** Compare finite-difference gradients across
   multiple step sizes. Status: done and tested.
2. **FD Hessian stability helper.** Compare finite-difference Hessians across
   multiple step sizes. Status: done and tested.
3. **FD stability payload.** Return step sizes, gradients, Hessians, maximum
   gradient disagreement, and maximum Hessian disagreement. Status: done.
4. **Local profile helper.** Evaluate residual and phylogenetic log-SD axes
   around a supplied point. Status: done and tested.
5. **Optimizer local-profile gate.** Attach local-profile evidence to the
   optimizer diagnostic. Status: done and tested.
6. **Optimizer FD-stability gate.** Attach FD-stability evidence to the optimizer
   diagnostic. Status: done and tested.
7. **Optimizer start count.** Record `n_starts`. Status: done and tested.
8. **Optimizer finite-record count.** Record `n_finite_records`. Status: done
   and tested.
9. **Optimizer accepted-record count.** Record `n_accepted_records`. Status:
   done and tested.
10. **Optimizer improvement.** Record best start-to-optimum improvement. Status:
    done and tested.
11. **PEV minimum.** Report posterior-variance minimum. Status: done and tested.
12. **PEV maximum.** Report posterior-variance maximum. Status: done and tested.
13. **Leaf PEV mean.** Report mean leaf posterior variance. Status: done and
    tested.
14. **Weighted leaf PEV trace.** Report `sum(STS_diag .* diag(M^{-1}))` and
    compare it with the dense trace. Status: done and tested.
15. **Payload FD stability.** Include FD-stability diagnostics in the combined
    diagnostic payload. Status: done and tested.
16. **Payload local profile.** Include local-profile diagnostics in the combined
    diagnostic payload. Status: done and tested.
17. **Statistics import repair.** Add the missing `Statistics` import after the
    first focused test exposed it. Status: done.
18. **DRM.jl validation-status refresh.** Update the local validation-status TSV
    with FD/local-profile/PEV-summary coverage. Status: done.
19. **DRM.jl check-log and after-task.** Bank the slice in DRM.jl dev-log files.
    Status: done.
20. **drmTMB dashboard/check-log sync.** Refresh the mission-control row and
    check-log without changing bridge or q4 claim status. Status: done locally.

## Dense Restricted-Score Extension During The Away Run

After the FD/local-profile batch, the clean DRM.jl worktree added a dense
analytic restricted-score diagnostic for the same exact-Gaussian target. This is
the next rung toward a sparse analytic score, not a public optimizer claim.

- `_loconly_reml_dense_score_diagnostic()` evaluates
  `0.5 * (tr(P dV) - y' P dV P y)` for the residual and phylogenetic log-SD
  parameters and compares it with finite differences of the sparse restricted
  objective.
- `_loconly_reml_dense_score_optimizer_diagnostic()` uses that dense score in a
  developer-only LBFGS experiment and keeps `ai_reml_ready = false`.
- The focused DRM.jl test now checks dense score versus finite differences and
  dense-score optimizer agreement with the finite-difference optimizer.

## Sparse Restricted-Score Extension After The Away Run

The next 20-slice batch moved the same score identity from dense `V` projection
to sparse Woodbury quantities while keeping the dense path as the oracle. This
is still exact-Gaussian developer evidence, not an average-information update
and not a bridge promotion.

1. **Sparse score helper.** Added
   `_loconly_reml_sparse_score_diagnostic()` in the clean DRM.jl worktree.
   Status: done and tested.
2. **Residual trace decomposition.** Compute the residual-axis trace from
   `tr(V^{-1})`, the Takahashi `Tr(S M^{-1} S')` term, and the fixed-effect
   correction. Status: done and tested against the dense score.
3. **Residual quadratic decomposition.** Compute the residual-axis quadratic
   from the restricted residual projection `P y`. Status: done and tested.
4. **Phylogenetic trace decomposition.** Compute the phylogenetic-axis trace
   through Woodbury `V^{-1}` solves and sparse `Q_cond` solves. Status: done
   and tested against the dense score.
5. **Phylogenetic quadratic decomposition.** Compute the phylogenetic-axis
   quadratic through `S' P y` and sparse `Q_cond` solves. Status: done and
   tested.
6. **Dense-score parity.** Require sparse-score agreement with the dense score
   to `1e-8`. Status: done and tested.
7. **Finite-difference parity.** Require sparse-score agreement with finite
   differences to `1e-6`. Status: done and tested.
8. **Trace/quadratic payload.** Return trace terms, quadratic terms, correction
   terms, dense score, finite-difference score, and maximum absolute
   disagreements. Status: done and tested.
9. **Sparse-score optimizer diagnostic.** Added
   `_loconly_reml_sparse_score_optimizer_diagnostic()` as a developer-only LBFGS
   experiment with `ai_reml_ready = false`. Status: done and tested.
10. **Optimizer dense-comparator gate.** Attach dense same-estimand comparator
    evidence to the sparse-score optimizer. Status: done and tested.
11. **Optimizer boundary label.** Attach boundary status to the sparse-score
    optimizer. Status: done and tested.
12. **Optimizer sparse-score payload.** Return the final sparse-score
    diagnostic at the optimizer solution. Status: done and tested.
13. **Bridge schema score mode.** Add an internal `score_mode` field to the
    schema tuple. Status: done and tested; no R bridge field is promoted.
14. **Combined payload sparse score.** Add sparse-score diagnostics to the
    combined developer payload. Status: done and tested.
15. **Near-zero variance score boundary.** Check sparse-score parity when the
    phylogenetic SD is near zero. Status: done and tested.
16. **Singular design score boundary.** Check the sparse-score diagnostic fails
    explicitly for singular fixed-effect information. Status: done and tested.
17. **DRM.jl validation-status refresh.** Update the local validation-status TSV
    with sparse-score coverage. Status: done.
18. **DRM.jl check-log and after-task.** Bank the sparse-score slice in DRM.jl
    dev-log files. Status: done.
19. **drmTMB mission-control sync.** Refresh this transfer ledger, the finish
    matrix, dashboard JSON, check-log, and after-task report. Status: done
    locally.
20. **Claim-boundary preservation.** Keep q4, Laplace, non-Gaussian,
    Ayumi-facing, R-bridge, and 10k interval claims unchanged. Status: done
    locally.

## Sparse Average-Information Extension After The Score Gate

After the sparse-score batch passed, the clean DRM.jl worktree added a sparse
average-information diagnostic for the same exact-Gaussian target. This checks
the matrix needed by a future update step, but it is still diagnostic-only.

1. **Sparse AI helper.** Added
   `_loconly_reml_sparse_ai_information_diagnostic()` in the clean DRM.jl
   worktree. Status: done and tested.
2. **Woodbury projection reuse.** Evaluate `P z` with Woodbury `V^{-1}` solves
   and the profiled fixed-effect correction. Status: done.
3. **Derivative action helpers.** Apply residual and phylogenetic `dV` actions
   without building dense `V`. Status: done.
4. **Dense-AI parity.** Require sparse average-information agreement with the
   dense diagnostic to `1e-8`. Status: done and tested.
5. **Observed-Hessian comparison.** Compare sparse average information with the
   finite-difference observed Hessian using the same tolerance gate as the dense
   diagnostic. Status: done and tested.
6. **Symmetry gate.** Check the sparse information matrix is symmetric. Status:
   done and tested.
7. **Payload inclusion.** Add `sparse_information` to the combined developer
   payload. Status: done and tested.
8. **Singular-design failure path.** Check sparse information returns an
   explicit non-finite diagnostic for singular fixed-effect information. Status:
   done and tested.
9. **DRM.jl validation-status refresh.** Update the local validation-status TSV
   with sparse average-information coverage. Status: done.
10. **DRM.jl check-log and after-task.** Bank the sparse-information slice in
    DRM.jl dev-log files. Status: done.
11. **drmTMB mission-control sync.** Refresh this transfer ledger, matrix,
    dashboard JSON, check-log, and after-task report. Status: done locally.
12. **Claim-boundary preservation.** Keep q4, Laplace, non-Gaussian,
    Ayumi-facing, R-bridge, and 10k interval claims unchanged. Status: done
    locally.

## Guarded Average-Information Update Experiment

The next 20-slice batch added the first two-parameter average-information update
experiment for the same exact-Gaussian target. It is still an internal
optimizer experiment: it has descent guards and comparator checks, but no
simulation, bridge, interval, q4, or user-facing promotion.

1. **Guarded update helper.** Added
   `_loconly_reml_ai_update_optimizer_diagnostic()` in the clean DRM.jl
   worktree. Status: done and tested.
2. **Sparse score input.** Use the sparse-Woodbury restricted score as the
   update gradient. Status: done.
3. **Sparse information input.** Use the sparse average-information diagnostic
   as the step matrix. Status: done.
4. **Finite objective gate.** Reject nonfinite starting or intermediate
   restricted objectives. Status: done.
5. **Score finite gate.** Reject nonfinite sparse scores before taking a step.
   Status: done.
6. **Information finite gate.** Reject nonfinite sparse information matrices.
   Status: done.
7. **Conditioning gate.** Record information eigenvalues and condition number;
   reject ill-conditioned matrices. Status: done.
8. **Ridge guard.** Add a small ridge when the information matrix is not safely
   positive. Status: done.
9. **Step-halving guard.** Halve the update step until the objective decreases
   or the halving budget is exhausted. Status: done.
10. **No-descent status.** Return explicit `no_descent` rather than silently
    accepting a bad update. Status: done.
11. **Iteration trace.** Record objective before/after, score norm, step norm,
    step factor, halving count, information diagnostics, and status. Status:
    done and tested.
12. **Multi-start support.** Reuse the same conservative start ladder as the
    other developer optimizers. Status: done.
13. **FD optimizer comparison.** Require the guarded-update endpoint to agree
    with the finite-difference optimizer diagnostic. Status: done and tested.
14. **Dense-score optimizer comparison.** Require endpoint agreement with the
    dense-score optimizer diagnostic. Status: done and tested.
15. **Sparse-score optimizer comparison.** Require endpoint agreement with the
    sparse-score optimizer diagnostic. Status: done and tested.
16. **Final comparator.** Attach the dense same-estimand comparator at the final
    point. Status: done and tested.
17. **Final boundary label.** Attach boundary status at the final point. Status:
    done and tested.
18. **Singular-design failure path.** Check rank-deficient fixed-effect
    information returns a clean failed diagnostic. Status: done and tested.
19. **DRM.jl local evidence.** Bank validation-status, check-log, and after-task
    files in the clean DRM.jl worktree. Status: done.
20. **drmTMB mission-control sync.** Refresh this ledger, matrix, dashboard,
    check-log, and after-task report without changing q4, bridge, Ayumi, or 10k
    claim status. Status: done locally.

## Tiny Recovery Grid And Condition Rows

The next recovery batch added the first deterministic simulation diagnostics
for the exact-Gaussian location-only cell. These are point-recovery diagnostics
for the guarded update experiment; they are not interval coverage evidence.

1. **ADEMP-shaped recovery helper.** Added
   `_loconly_reml_recovery_grid_diagnostic()` with explicit aim, DGP,
   estimands, method, and performance fields. Status: done and tested.
2. **Truth-known DGP.** Simulate
   `y = X beta + u_species + epsilon` with
   `u ~ N(0, sigma_phy^2 Sigma_phy)` and
   `epsilon ~ N(0, sigma^2 I)`. Status: done.
3. **Guarded update fitting.** Fit each replicate with the guarded
   average-information update experiment. Status: done.
4. **Convergence summary.** Report accepted fit count and convergence rate.
   Status: done and tested.
5. **Point recovery summary.** Report mean estimates, bias, RMSE, and MCSE for
   bias for `sigma` and `sigma_phy`. Status: done and tested.
6. **Boundary accounting.** Report boundary-status counts per grid. Status:
   done and tested.
7. **Coverage exclusion.** Return `coverage_status = :not_evaluated`. Status:
   done and tested.
8. **Stable interior test cell.** Use 10 species and 3 observations per species
   in the routine test cell after a sparser draft correctly exposed boundary
   instability. Status: done.
9. **Condition-grid wrapper.** Added
   `_loconly_reml_recovery_condition_grid_diagnostic()` to keep multiple
   simulation cells row-separated. Status: done and tested.
10. **Default condition rows.** Use two stable interior rows: baseline
    phylogenetic SD and higher phylogenetic SD. Status: done and tested.
11. **Condition-level nested diagnostics.** Preserve the full single-cell
    diagnostic inside each condition row. Status: done and tested.
12. **No weak-boundary promotion.** Leave weak-signal boundary rows for a later
    diagnostic that is allowed to report low convergence or boundary states.
    Status: done.
13. **DRM.jl validation-status refresh.** Update the local validation-status TSV
    with recovery-grid coverage. Status: done.
14. **DRM.jl check-log and after-task.** Bank recovery-grid and condition-grid
    reports in DRM.jl dev-log files. Status: done.
15. **drmTMB matrix sync.** Refresh the AI-REML-inspired matrix row without
    changing bridge status. Status: done locally.
16. **drmTMB dashboard sync.** Refresh dashboard JSON and live copy. Status:
    done locally.
17. **drmTMB check-log and after-task.** Bank this recovery batch in
    mission-control evidence files. Status: done locally.
18. **Focused test expansion.** Focused DRM.jl test now includes the single-cell
    and two-cell recovery diagnostics. Status: done.
19. **Claim-boundary scan.** Re-scan forbidden q4/non-Gaussian/Ayumi/10k
    wording. Status: done locally.
20. **Next boundary-grid gate.** The next slice is an explicitly labelled
    weak-signal/boundary condition grid, not a public promotion. Status:
    done as a weak-signal recovery probe.

## Weak-Signal Boundary Recovery Probe

The final slice in this run added an explicitly labelled weak-signal recovery
probe. It is designed to report boundary-prone behavior honestly; it does not
ask the weak-signal cell to pass the stable recovery criteria.

1. **Weak-signal probe helper.** Added
   `_loconly_reml_weak_signal_recovery_probe()` in the clean DRM.jl worktree.
   Status: done and tested.
2. **Boundary-allowed semantics.** Return
   `expected_behavior = :boundary_states_allowed`. Status: done and tested.
3. **Boundary accounting.** Report boundary replicate count and boundary rate.
   Status: done and tested.
4. **Nested diagnostic.** Preserve the full recovery-grid diagnostic underneath
   the weak-signal wrapper. Status: done.
5. **No convergence requirement.** Test that the probe reports boundary states
   without requiring universal convergence. Status: done and tested.
6. **DRM.jl evidence.** Bank validation-status, check-log, and after-task notes.
   Status: done.
7. **drmTMB mission-control sync.** Refresh this ledger, matrix, dashboard,
   check-log, and after-task report. Status: done locally.
8. **Claim boundary.** No coverage, bridge, q4, non-Gaussian, Ayumi-facing, or
   10k interval claim is changed. Status: done locally.

## Machine-Readable Simulation-Status Rows

The latest local batch turned the point-recovery diagnostics into one compact
row surface and then hardened that surface as a schema-backed, writer-backed
contract. This is still developer evidence for the exact-Gaussian
location-only cell; it does not evaluate interval coverage and does not promote
an average-information optimizer, R bridge row, q4 route, non-Gaussian route,
Ayumi-facing reply, or 10k interval claim.

1. **Status row helper.** Added `_loconly_reml_simulation_status()` in the clean
   DRM.jl worktree. Status: done and tested.
2. **Stable recovery row.** Added `stable_recovery` for the deterministic
   interior recovery grid. Status: done.
3. **Condition-grid row.** Added `condition_grid` summarizing the two stable
   condition rows without flattening their identity in the nested diagnostic.
   Status: done.
4. **Weak-signal row.** Added `weak_signal_boundary_probe` with boundary states
   allowed and no convergence-success requirement. Status: done.
5. **Larger interior stress row.** Added `larger_interior_stress` as a small
   runtime/stability smoke beyond the baseline cell. Status: done.
6. **Schema helper.** Added `_loconly_reml_simulation_status_schema()` with
   target, estimator, design, status, replicate, convergence, boundary,
   failure-count, MCSE, runtime-budget, seed-registry, evidence, and next-gate
   fields. Status: done and tested.
7. **Row validator.** Added `_loconly_reml_validate_simulation_status()` so row
   order, required fields, status values, bounded rates, seed/evidence fields,
   and diagnostic-only MCSE semantics are checked together. Status: done and
   tested.
8. **TSV writer.** Added `_loconly_reml_write_simulation_status_tsv()` and
   `tools/loconly-reml-simulation-status.jl`. Status: done and tested.
9. **Stable row order.** The focused test requires the default row order:
   `stable_recovery`, `condition_grid`, `weak_signal_boundary_probe`,
   `larger_interior_stress`. Status: done.
10. **Expected-behavior field.** Rows now distinguish stable interior recovery,
    row-separated stable recovery, boundary-allowed weak signal, and stress
    smoke behavior. Status: done.
11. **Failure-reason counts.** Rows now carry near-zero variance, nonfinite
    objective, and singular fixed-effect information counts. Status: done.
12. **Runtime/seed contract.** Rows now carry runtime budget, runtime observed
    as developer evidence, deterministic seed, and seed registry fields; no
    speed claim is made. Status: done.
13. **Optional medium stress row.** `include_medium_stress = true` adds
    `medium_interior_stress`; the optional script path wrote five rows in a
    temporary TSV. Status: done and tested.
14. **Broader recovery-grid helper.** Added
    `_loconly_reml_broader_recovery_grid_diagnostic()` with baseline, higher
    phylogenetic signal, and medium stress cells. Status: done and tested.
15. **Weak-signal condition grid.** Added
    `_loconly_reml_weak_signal_condition_grid_diagnostic()` with low and
    near-zero phylogenetic signal cells. Status: done and tested.
16. **Coverage exclusion.** Every row and helper remains
    `coverage_status = :not_evaluated` and `ai_reml_ready = false`. Status:
    done and tested.
17. **DRM.jl evidence refresh.** Updated the local validation-status TSV,
    simulation-status TSV, check-log, and after-task report. Status: done.
18. **drmTMB matrix/dashboard sync.** Mark this lane's simulation column as
    `partial`, not `covered`, and refresh dashboard prose/machine fields with
    the row-contract evidence. Status: done locally.
19. **drmTMB check-log and after-task.** Bank this full 20-slice batch in
    mission-control evidence files. Status: done locally.
20. **Claim-boundary scan.** Re-scan forbidden q4, non-Gaussian, Ayumi, and
    10k interval wording after the sync. Status: done locally.

## Ayumi Boundary

This note is engine work only. It must not be converted into a reply to Ayumi.
The Ayumi thread stays parked until the 10k-scale engine blockers are cleared
and the promised full Bayesian results arrive for cross-checking.
