## 1. Goal

Run the corrected fixed-design binomial S0-A2 evidence slice only. The authorized scope excluded hurdle models, GLMM theory, package integration, pull requests, pushes, and merges.

## 2. Implemented

This additive evidence slice preserved the original S0 STOP artifacts and implemented the reviewed cone-based correction contract in scratchpad/separation-s0a2-cone-spike.R. For each full-rank binomial fixture it formed the signed design matrix B = diag(2y - 1)X, tested existence of a normalized nonzero improving direction, tested a strict-margin formulation, and checked coefficient-sign feasibility without assuming a unique separating ray.

The harness also compared detectseparation 0.4.0 classifications, exact-source drmTMB objective values, ordinary glm fits, and brglm2 comparators. It evaluated the unpenalized drmTMB objective along predeclared rays using both the compiled objective and a direct binomial log-likelihood calculation.

The run retained a STOP. The overlap fixture's normalized cone should be infeasible, but ROI.plugin.lpsolve returned solver status 0 with the zero vector even though the reported constraint residual was 1. The harness rejected that nominal success, classified the result as unresolved, and failed four rows: the overlap cone check, the overlap strict-class check, the aggregate core verdict, and the aggregate S0-A2 verdict.

Across the separated fixtures, the cone signs, maintained detector indicators, and compiled/direct objective rays were mutually consistent. All 121 objective-ray gate rows passed. That is partial evidence only: it does not establish the required global overlap certificate and therefore does not license an S0-A2 PASS.

Exact-row controls were recorded as not_run_after_core_failure. Hurdle and S1 stages were not run.

## 3a. Decisions and Rejected Alternatives

- Preserved the reviewed mathematical contract and the failed rows. The solver contradiction was not hidden by changing fixtures, tolerances, or expected outcomes after the run.
- Required explicit constraint-residual validation in addition to a solver status code. Status 0 with residual 1 is not a feasible LP certificate.
- Did not use the strict-margin optimum of zero as a proof of overlap because the normalized nonzero-cone infeasibility remained unresolved.
- Did not treat finite optimizer coefficients, convergence codes, pdHess, or bias-reduced estimates as evidence of finite unpenalized maximum-likelihood estimates.
- Kept ten brglm2 direct-call errors as RETAINED_FAILURE rows. The installed brglm2 1.1.0 rejected the requested type = AS_mean argument; these comparator rows were non-gating and provide no valid brglm2 evidence.
- Did not proceed to exact-row controls after the core failure and did not run hurdle or GLMM work.
- Rejected any edit to R, src, tests, DESCRIPTION, NAMESPACE, public documentation, release surfaces, or other lanes.

## 4. Files Touched

- scratchpad/separation-s0a2-cone-spike.R
- scratchpad/separation-s0a2-cone-results.tsv
- docs/dev-log/after-task/2026-08-08-separation-s0a2-cone-experiment.md
- docs/dev-log/plan-actual/2026-08-08-separation-s0a2.md

The prior contract and original STOP artifacts were read but not modified.

## 5. Checks Run

- session_ownership.sh and tools/lane_preflight.sh: Codex continued the isolated Lane S worktree; no foreign Claude lane was detected, subject to the script's weak-evidence caveat.
- Process inspection: no live process was using the recycled worktree.
- Runtime inventory: R 4.6.0; drmTMB 0.6.0; detectseparation 0.4.0; ROI 1.0.2; ROI.plugin.lpsolve 1.0.2; lpSolveAPI 5.5.2.0.17.15; brglm2 1.1.0; TMB 1.9.21.
- Main command used R_PROFILE_USER=/dev/null and Rscript --no-init-file with the isolated drmTMB and separation libraries. It exited 1 with: S0-A2 rows=283 pass=231 fail=4 recorded=38.
- Result-table audit: 283 data rows; 28 columns on every line; 231 PASS; 4 FAIL; 38 RECORDED; 10 RETAINED_FAILURE; 0 UNRESOLVED status labels. The four FAIL rows are s0a2-0010, s0a2-0011, s0a2-0281, and s0a2-0283.
- Objective audit: 121 objective-ray rows, all PASS.
- Scope audit: no hurdle or S1 stage rows; exact-row controls state not_run_after_core_failure.
- SHA-256: spike 4ae2569477fb12457ebc46fea02b0b5a520d4e6dfbe4f3d4dbdfc16ed881b173; TSV 3400afa169c9cb321c40184fd5f2daeaf0952dbff57468c28de93ca1e2ce5308.
- The first read-only Luna verifier correctly declined to certify a rerun because its sandbox could not create temporary files. A second Luna verifier with workspace-write authority reran only the deterministic harness in a temporary output location, reproduced exit 1, and produced a byte-identical TSV with the same SHA-256. Verdict: MECHANICAL_STOP_EVIDENCE_VALID.
- The D-43 completion panel ran once with Noether, Fisher, and Rose. All three returned NOT-DONE, so the milestone claim is withheld.
- The ultra-plan routing audit found five retained receipts for this date: two Luna, two Terra, and one Sol. Its enforced date-wide verdict failed because all Codex sessions on 2026-08-08, including unrelated tasks, were Sol-heavy and several sessions exceeded the one-compaction ceiling. This is retained as orchestration debt and does not alter the independently reproduced scientific STOP.

## 6. Tests of the Tests

- Shifted and mirrored complete-separation fixtures checked both coefficient tails without asserting an invariant intercept direction.
- A centered complete fixture checked the admissible zero-intercept ray.
- A quasi-complete fixture checked equality rows and the affected coefficient direction.
- Intercept-only all-success and all-failure fixtures checked positive and negative infinite intercepts.
- Grouped cbind and Bernoulli-expanded forms checked equivalent signed-design geometry.
- A rank-deficient non-separated fixture was classified before the LP so singularity could not masquerade as separation.
- The overlap fixture tested the negative control. Its solver status/residual contradiction triggered the intended fail-closed path.
- Compiled drmTMB and direct binomial objective changes were compared at every declared ray point; all 121 comparisons and qualitative gates passed.
- The rerun wrote to a temporary result path and was compared byte-for-byte with the retained TSV.

## 7a. Issue Ledger

- S0A2-001 — ROI.plugin.lpsolve reports status 0 for the overlap normalized-cone LP while returning the zero vector with maximum constraint residual 1. Open and blocking. A future correction must obtain a valid infeasibility certificate or use an independently justified formulation/backend.
- S0A2-002 — direct brglm2 1.1.0 calls reject type = AS_mean as an unused argument. Open but non-gating for the cone estimand; no brglm2 comparator claim is licensed.
- No detector or drmTMB defect is established by either issue.

## 8. Consistency Audit

The script, TSV, this report, and the plan-versus-actual receipt all state the same verdict: S0-A2 is NOT-DONE because overlap infeasibility was not validly certified. The reports distinguish solver failure from scientific disagreement and distinguish partial separated-fixture consistency from a completed exact detector contract.

The file fence excludes package implementation and public surfaces. Searches over README.md, ROADMAP.md, NEWS.md, docs/dev-log/known-limitations.md, docs/design/01-formula-grammar.md, vignettes/formula-grammar.Rmd, and _pkgdown.yml found no new S0-A2 capability claim requiring synchronization.

Memory receipt: the reviewed S0-A2 contract and retained original S0 receipt were used as local provenance; no brain-memory write was made.

Golden Set: the immutable original STOP artifacts and the reviewed S0-A2 contract hashes were preserved. The new deterministic TSV was independently reproduced byte-for-byte.

## 9. What Did Not Go Smoothly

The LP backend's nominal success code was internally inconsistent with its returned solution. Checking only solver status would have produced a false PASS; explicit constraint-residual validation exposed the problem.

The first independent verifier had a read-only sandbox and therefore could not perform the required temporary rerun. Its verdict was retained as MECHANICAL_EVIDENCE_INVALID. The rerun was then assigned to a fresh verifier with narrowly scoped workspace-write permission, which reproduced the retained STOP.

The brglm2 comparator call used an interface not accepted by installed brglm2 1.1.0. The errors remain in the result table and were not repaired after seeing the run.

During the slice origin/main advanced, leaving the branch six commits behind. The evidence branch was not rebased because the user authorized only S0-A2 and prohibited integration work.

The routing auditor cannot isolate native session history to this one lane. Its retained-receipt summary confirms the intended S0-A2 tiers, but its date-wide composition and compaction gates failed on the combined day's sessions.

## 10. Known Residuals

- No valid overlap infeasibility certificate has been obtained.
- The exact-row zero-weight, offset, and response-mask controls were not run because the core gate failed.
- The brglm2 mean-bias-reduction comparator is unresolved.
- Hurdle separation and all S1 GLMM theory/numerics remain unstarted.
- The maximum licensed claim is partial consistency on the declared separated fixed-design fixtures, including objective-ray direction. It is not an exact fixed-design detector PASS and not package capability.

## 11. Team Learning

For LP-based separation evidence, a solver return code is not a certificate. The harness must validate primal feasibility and, for negative controls, require an independently trustworthy infeasibility result. A zero strict-margin optimum cannot substitute for the normalized-cone result when the latter is numerically contradictory.

Comparators should be called through version-verified interfaces before they enter a frozen evidence run. Their failures can remain non-gating, but they cannot be described as evidence.

## 12. Cross-Product Coverage

This slice covers only the private drmTMB fixed-design binomial experiment. It does NOT cover drmTMB package code or API, gllvmTMB, DRM.jl, GLLVM.jl, hurdle models, GLMM theory, REML, penalties, missing-data behavior, aggregation beyond the declared grouped-binomial fixture, release work, CI, pkgdown, issues, pull requests, pushes, or merges.
