# After Task: Experimental Binomial-Logit MSPL Phase 3

## 1. Goal

Implement and locally verify an opt-in maximum softly-penalized likelihood
(MSPL) estimator for the bounded Bernoulli/grouped-binomial logit mixed-model
surface with one ordinary q=1 or q=2 grouping block. Stop before remote compute,
a pull request, push, or merge.

## 2. Implemented

`drmTMB(..., estimator = "mspl")` now applies the clean-room criterion frozen
in design note 250: a fixed-effect Jeffreys term and a negative-Huber penalty on
derived covariance-Cholesky coordinates, both scaled by
`c_n = 2 * sqrt(p / n_eff)`. The q=2 engine uses `rho = tanh(eta)` and a stable
`log(sech(eta))` transform. The fit stores the penalized and separately
evaluated unpenalized Laplace objectives, penalty components, scaling,
fixed-design separation screen, gradient, outer Hessian, and boundary facts in
`fit$mspl`.

The default and explicit `estimator = "ml"` paths remain identical on the
declared fixtures. MSPL point prediction, simulation, extraction, printing,
and diagnostics are wired. Likelihood inference, Wald uncertainty, profiles,
and intervals fail loudly. One complete-data unlabelled binomial q=2
intercept-slope block is admitted for native-TMB ML and MSPL; REML,
missing-response integration, labels, q>=3, multiple groups, and structured
effects are rejected.

## 3a. Decisions and Rejected Alternatives

- The implementation was written from the published equations of Sterzinger
  and Kosmidis (2023), DOI `10.1007/s11222-023-10217-3`. No v8 source,
  supplementary implementation, comments, functions, or tests were copied.
- The covariance penalty acts on `(log L11, log L22, L21)` for q=2, not on the
  native marginal log-SDs and correlation predictor.
- Grouped and expanded Bernoulli likelihoods were not described as numerically
  identical: grouped rows differ by the known data-only binomial combinatorial
  constant, while estimates, gradients, Hessians, and penalties agree.
- Exact Gauss-Hermite quadrature was re-optimized independently rather than
  treating evaluation at the Laplace solution as estimator validation.
- A broad recovery/calibration campaign was rejected for this phase. It needs
  separate Totoro authorization; local deterministic implementation evidence
  cannot establish bias, RMSE, interval coverage, or a universal boundary fix.

## 4. Files Touched

Implementation and generated interface:
`DESCRIPTION`, `NAMESPACE`, `R/check.R`, `R/drmTMB.R`, `R/methods.R`,
`R/profile.R`, `R/mspl.R`, `R/mspl-estimator.R`, `src/drmTMB.cpp`,
`man/drmTMB.Rd`, `man/anova.drmTMB.Rd`, and `_pkgdown.yml`.

Tests:
`tests/testthat/test-mspl-kernels.R`,
`tests/testthat/test-mspl-estimator.R`,
`tests/testthat/test-binomial-correlated-re-mspl-prereq.R`,
`tests/testthat/test-arc2a-mu-random-intercept.R`,
`tests/testthat/test-arc2b-mu-random-slope.R`,
`tests/testthat/test-guard-branch-continuity.R`,
`tests/testthat/test-phylo-utils.R`, and
`tests/testthat/test-reml-bivariate-relmat-q2.R`.

Equations, evidence, and synchronized status surfaces:
`docs/design/250-mspl-binomial-logit-alignment.md`,
`scratchpad/mspl-binomial-quadrature-spike.R`,
`scratchpad/mspl-binomial-quadrature-results.tsv`, `README.md`, `NEWS.md`,
`docs/design/01-formula-grammar.md`, `docs/design/02-family-registry.md`,
`docs/design/33-phase-6c-core-random-effects.md`,
`docs/design/37-worked-example-inventory.md`,
`docs/design/41-phase-18-simulation-programme.md`,
`docs/design/46-pre-simulation-readiness-matrix.md`,
`docs/design/59-structural-slope-and-non-gaussian-map.md`,
`docs/design/79-supported-nongaussian-evidence-goal.md`,
`docs/design/151-phase6c-random-slope-tutorial-ledger.md`,
`docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`,
`vignettes/formula-grammar.Rmd`, `vignettes/implementation-map.Rmd`,
`vignettes/model-map.Rmd`, `vignettes/proportion-beta-binomial.Rmd`,
`docs/dev-log/check-log.md`, this report, and
`docs/dev-log/plan-actual/2026-08-08-mspl-binomial-glmm-experimental.md`.

## 5. Checks Run

- `devtools::document()`: PASS and idempotent; the NAMESPACE/man diff SHA-256
  remained `0763af0cb7a2dd58707013e46f819d390b1d5bb716126a0c0896e490a84911d3`.
- Focused MSPL/q2/legacy-neighbour matrix: PASS after review repairs.
- Independent q1/q2 penalty value and numerical-gradient comparison against
  penalized-minus-unpenalized TMB: PASS at fixed perturbed vectors.
- Exact quadrature script: PASS. The q1 41-to-81-node increment was `0`; the q2
  31-to-41-node increment was `2.56e-13`. Exact-criterion BFGS converged for q1
  and q2 with maximum numerical gradients `2.01e-06` and `1.27e-05`.
- The exact-vs-Laplace parameter infinity-norm differences were `0.0153` (q1)
  and `0.0414` (q2); exact-criterion gains over the Laplace solutions were
  `9.26e-05` and `9.96e-04`. These are measured approximation differences, not
  equality claims.
- Quadrature SHA-256: script
  `22386a957dd2747a7d9d2a92cc54c0312fa9f90da7884bb5d772116517380027`;
  TSV `4be95fe8b5cfc8fd10964741188b26c335a06cc7c463368c3b41bd3bfe8e3ece`.
- First broad `devtools::check(args = "--no-manual", error_on = "never")`
  before review repairs: 0 errors, 0 warnings, 0 reported notes; 22m13s.
- One broad `devtools::test()` run exercised the complete suite but retained a
  single detector-injection failure because the package namespace had loaded
  before that repair was written. The repaired focused matrix passed; the final
  package check reloaded and exercised the repaired snapshot.
- Final frozen-snapshot `devtools::check(args = "--as-cran",
  error_on = "warning")`: completed in 21m58s with 0 errors and 0 warnings.
  The raw checker reported one NOTE because `testthat.R` took about 18 minutes;
  devtools summarized 0 notes. This timing NOTE is retained, not treated as an
  MSPL failure.
- Fresh completion-audit focused matrix: PASS on the final source state.
- Fresh independent quadrature regeneration: PASS with byte-identical script
  and TSV hashes. The first write attempt was blocked by the managed sandbox
  after all numerical gates had passed; the approved local worktree-write
  rerun produced the exact recorded TSV.
- Full `pkgdown::build_site(preview = FALSE, new_process = FALSE)` followed by
  `pkgdown::check_pkgdown()`: PASS; every article was rebuilt and the final
  checker reported no problems. Rendered read-back confirmed the point-only
  MSPL and exact q=2 binomial boundaries.
- Final post-audit `devtools::check(args = "--as-cran",
  error_on = "warning")`: completed in 22m07.7s with 0 errors and 0 warnings.
  Raw `R CMD check` retained the single long-test timing NOTE (`testthat.R`
  about 18 minutes); devtools summarized 0 notes.
- The first `pkgdown::check_pkgdown()` failed because the new
  `anova.drmTMB` inference-fence topic was absent from the reference index.
  `_pkgdown.yml` was repaired and the rerun reported no problems.
- Final `lane_preflight.sh` found no Claude lane in the last 12 hours, with its
  required warning that silence is weak evidence. The experiment's HEAD and
  merge-base remain `efb5af4f`; the local `origin/main` ref advanced during
  closeout by two commits to `31da19f2`. No rebase or merge was performed.
- `git diff --check`: PASS.
- Independent review: the first architecture, inference, and mechanical
  verdicts were NOT-DONE and retained. After repair, Emmy returned DONE and
  Fisher returned DONE. Grace's second NOT-DONE identified the literal design,
  rejection-matrix, deterministic-fallback, and receipt gaps; all were repaired
  before Grace's local mechanical re-review returned DONE. Grace's final
  post-gate audit also returned DONE after verifying the intended
  22-tracked/11-untracked file fence, unchanged oracle hashes, parsed R/Rd and
  DESCRIPTION surfaces, broad-check receipt, pkgdown repair, and base drift.
  The subsequent fresh completion audit deliberately added ten tracked current
  design/vignette neighbour repairs; the final reconciled fence is therefore
  32 tracked modifications plus the same 11 untracked additions.

Runtime: R 4.6.0, TMB 1.9.21, Matrix 1.7.5, detectseparation 0.4.0,
brglm2 1.1.0, statmod 1.5.2, and numDeriv 2016.8.1.1.

## 6. Tests of the Tests

The clean-room penalty test independently reconstructs the Jeffreys information
matrix, stable q=2 Cholesky coordinates, negative-Huber term, and scale. It
checks both values and finite-difference gradients against the difference
between the penalized and unpenalized TMB objectives for q1 and q2.

Other independent checks cover grouped-versus-expanded data after subtracting
the exact combinatorial constant, exact quadrature re-optimization, conditional
link/response prediction identities, and fresh q=2 simulation draws reproduced
from the native correlation predictor and stable `sech` transform. Negative
tests cover engine, family/link, REML, existing penalty, fixed-design rank,
frequency weights, grouping structure, q>=3, and missing-response cross-products.

## 7a. Issue Ledger

- Fixed: the initial implementation stored an unpenalized diagnostic in
  `fit$logLik`; it now lives only under `fit$mspl`, and ordinary likelihood
  methods remain fenced.
- Fixed: q=2 binomial REML and missing-response routes were accidentally
  admitted by the global parser prerequisite; post-spec context gates now
  reject them.
- Fixed: `check_drm()` and `is_converged(include_hessian = TRUE)` initially
  ignored the stored MSPL outer Hessian.
- Fixed: the first quadrature receipt evaluated only at the Laplace solution;
  the final receipt independently re-optimizes the exact q1/q2 criteria.
- Fixed: the first exact q2 `nlminb()` ended with singular-convergence code 1;
  deterministic BFGS reached code 0 and a `1.27e-05` numerical gradient.
- Fixed: stale README, family-registry, formula-grammar, vignette, roadmap,
  limitations, and NEWS wording said all correlated binomial slopes were
  unsupported.
- Fixed in the fresh completion audit: the same stale-neighbour class remained
  in the core parser error and current random-effect/model-map design and
  tutorial surfaces. They now distinguish the exact unlabelled complete-data
  binomial q=2 point-fit route from labelled, multiple, structured,
  missing-response, and REML neighbours.
- Retained approximation evidence: exact-minus-Laplace marginal log likelihood
  at the Laplace solution was `0.00344` for q1 and `0.05342` for q2.
- Existing open issue #686 overlaps soft penalties. It was inspected but left
  unchanged because this task forbids remote writes and is not a landing task.

## 8. Consistency Audit

The initial exact status scan was:

`rg -n -i "mspl|softly.penal|jeffreys|separation|estimator.*mspl|correlated.*binomial|binomial.*random.*slope" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md vignettes/formula-grammar.Rmd _pkgdown.yml R tests`

The contradiction scan was:

`rg -n "correlated or labelled binomial|correlated.*binomial.*unsupported|binomial.*correlated.*planned|correlated binomial slopes" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md vignettes/formula-grammar.Rmd`

Current wording distinguishes the one experimental unlabelled q=2 binomial
route from labelled, multiple, structured, missing-response, and REML
neighbours. `_pkgdown.yml` indexes the new `anova.drmTMB` inference-fence topic;
no article or navigation menu was added. GitHub issue maintenance was
deliberately read-only.

The fresh completion audit widened the contradiction scan across `R/`, current
design notes, current roadmaps/limitations, and vignettes. It repaired the core
error plus the live random-effect, simulation-programme, readiness, model-map,
worked-example, and proportion-tutorial surfaces. Remaining blanket statements
are confined to other families or historical plans and do not contradict the
earned binomial q=2 point-fit cell.

Memory receipt: the repository LOAD-FIRST manifest, ultra-plan,
symbolic-alignment, R-package engineering, validation-harness,
after-task-audit, and prose-style-review guidance shaped this work. The memory
registry reinforced exact-cell evidence boundaries. No matching Golden Set
mistake class required a `memory_regression.py` run, and no brain-vault write
was authorized.

## 9. What Did Not Go Smoothly

The first integration run exposed eight neighbouring test assumptions: a
CondExp census, six low-level TMB data fixtures missing inert MSPL fields, and
an estimator-message expectation. Review then found deeper problems that the
focused green tests had missed: a misleading core `logLik`, unintended q=2
cross-products, absent diagnostic routing, and an incomplete quadrature oracle.

The quadrature repair itself retained two failed runs: one selected an `NA`
increment row, and one q2 `nlminb()` stopped singularly despite a small gradient.
Both causes were corrected without changing fixtures or manufacturing a pass.
The first pkgdown validation also failed because `anova.drmTMB` was not indexed;
the topic was added and the validation rerun passed.

The fresh audit then found that the first documentation reconciliation had not
walked far enough around the q=2 prerequisite: a core error and several live
neighbour surfaces still said the route was unavailable. They were corrected
and the full site and package checks were rerun. The first quadrature
regeneration attempt also hit a managed-sandbox write denial only after its
numerical gates passed; an approved local write rerun reproduced the tracked TSV
byte-for-byte.

## 10. Known Residuals

This phase establishes an experimental local point-estimation implementation,
not recovery, bias, RMSE, interval, coverage, or release readiness. The q2
Laplace approximation differs measurably from exact quadrature on the one toy
fixture. No Linux/Windows, declared-minimum-version, sanitizer, Totoro, or DRAC
evidence exists. The optional separation detector is a conservative fixed-X
screen, not a general GLMM oracle. The implementation does not establish an
estimated-latent-variable MSPL result. The branch is two commits behind the
closeout value of `origin/main`; any later landing task must inspect that delta
afresh rather than treating the current branch as integration-ready.

## 11. Team Learning

A quadrature evaluation at a package optimum validates an integrator, not the
estimator. Re-optimizing the independently coded criterion and comparing its
stationary point is the smallest honest estimator check. Likewise, adding a
parser path requires a post-spec cross-product audit: family-level admission
alone can silently expose REML or missing-data routes.

The first review panel materially improved the code. Its initial NOT-DONE
verdicts remain part of the evidence rather than being replaced by the final
verdicts.

## 12. Cross-Product Coverage

Covered: native TMB; Bernoulli and grouped-binomial logit responses; finite
offsets; full-rank dense fixed designs; positive integer frequency weights;
one ordinary q=1 random intercept or one unlabelled q=2 intercept-slope block;
ML default equivalence; MSPL point fitting, extraction, point prediction,
simulation, separation fixtures, objective diagnostics, and local exact
quadrature comparisons.

This phase **does NOT cover** `hu`, `zi`, beta-binomial or count separation,
non-logit links, missing-data integration, REML, existing MAP penalties,
structured effects, labelled or multiple covariance blocks, q>=3, multiple
grouping factors, Julia/AGHQ fitting, likelihood inference, Wald SEs, profiles,
confidence intervals, LRTs, AIC/BIC, recovery campaigns, calibration, public
support status, release work, PRs, pushes, or merges. Totoro and DRAC were not
launched.
