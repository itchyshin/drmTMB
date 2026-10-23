# Independent re-review of PR #1367 after P1 fixes

Reviewer: Cursor reviewer subagent, not the builder.
PR: https://github.com/itchyshin/drmTMB/pull/1367
Builder fix comment: https://github.com/itchyshin/drmTMB/pull/1367#issuecomment-5690092722
Branch reviewed: `cursor/dinnage-arc3-a3-misc-20260915` at
`ab78327b8e49e9b75356da7101b292ac416500db` (NEWS credits addendum;
code/C17 head was `1f8f0801e3612ad46d0292d7d6c94b94f56a4f8f`)
Review branch: `claude/pr1367-a3-rereview-20260915`
Date: 2026-09-15 (NEWS P2 re-check: 2026-09-15; #1344 help cross-PR: 2026-09-15)

## Verdict

ACCEPT pending CI.

The three prior P1 findings are fixed at the PR head. The C17/C14
source-compatibility guard passes locally, Curie's Md-H test now reaches both
the main beta-binomial objective and the `drm_response_log_density()` case-14
`mi()` leaf, and the eight named A3 follow-up issues now have implementation,
regression-test, and `NEWS.md` credit coverage on PR #1367. The last tracked
P2 for this issue set was #1344's `?phylo` branch-length convention sentence;
that help wording is now on A1 PR #1368 in commit `c86e86d88` (verified on
`cursor/dinnage-arc3-a1-docs-20260915`, not in the #1367 diff).

I do not see a remaining P0/P1/P2 blocker tied to the #1367 issue set. Do not
merge on this audit alone: wait for GitHub CI on #1367 to settle green. When
closing #1344, treat A1 #1368 as a cross-PR dependency: land or merge the A1
#1344 help with or before treating #1344 fully closed (A3 owns the runtime
pruning note on #1367).

## Findings

### P2 (NEWS): A3 release-note credits — ACCEPT at `ab78327b8`

Status: resolved on PR head `ab78327b8e49e9b75356da7101b292ac416500db`
(`docs(NEWS): credit Russell Dinnage for arc3 Wave A3 (#1324–#1358)`).

Independent re-check (NEWS only, not a full PR re-audit): the wave-3
independent-evaluation section now adds eight bullets, each crediting Russell
Dinnage and naming the finding plus issue number: Md-G (#1324), Md-H (#1325),
Md-I (#1326), Mi-6 (#1344, pruning note only), Mi-10 (#1348), Mi-12 (#1350),
UX-2 (#1357), UX-3 (#1358). The commit message correctly scopes #1344 to the
runtime pruning note and leaves `?phylo` wording on A1. This satisfies the
prior NEWS P2 from ACCEPT-WITH-CHANGES.

### P2: #1344 `?phylo` branch-length help — resolved on A1 #1368 (`c86e86d88`)

Status: cleared for the #1367 issue-set audit (cross-PR).

On #1367, `R/phylo-utils.R` emits a pruning note when the tree has tips absent
from the observed species, and `tests/testthat/test-dinnage-audit-a3-misc.R`
covers that note. The `?phylo` branch-length convention sentence is not in the
#1367 diff; it landed on A1 PR #1368 in commit `c86e86d886d16669286546d80bd4c33e913e2416`,
which updates `man/phylo.Rd` to state that `phylo()` uses the supplied
ultrametric branch-length scale and does not silently rescale the tree to unit
height. Issue closers should still coordinate merge order: #1344 is fully
addressed only after both #1367 (runtime note) and #1368 (help wording) are
accounted for.

## Prior P1 Re-check

### C17/C14 ledger, mc-0568

Status: fixed locally.

The PR now refreshes the C17/C14 receipt rows to
`docs/dev-log/implementation-recovery/2026-09-15-a3-misc-c17c2-c14-final-source-compatibility/`
and points `mc-0568`, `mc-0569`, and `mc-0576` at `current_source_sha`
`5ccc53815e9b91104b1f11a0a1f8ae12dbb84487`. I reran the same local gate that
previously failed:

```sh
git diff --check origin/main...HEAD
python3 tools/capability_ledger.py --check
python3 -m unittest tools/tests/test_capability_ledger.py
```

Result: pass. The unit suite ran 80 tests and printed
`C17 current-source compatibility PASS`.

### Curie case-14 coverage

Status: fixed locally.

`tests/testthat/test-dinnage-audit-a3-curie.R` now contains two beta-binomial
Md-H tests. The first forces the main objective to `eta_mu = 700` and compares
against an R reference. The second fits `bf(cbind(successes, failures) ~ mi(x),
sigma ~ 1)` with `missing = miss_control(predictor = "model")`, verifies
`has_mi == 1` and `mi_family == 1`, then forces `beta_mu = c(700, 0)` and
checks that `fit$obj$fn(par)` is finite. That reaches the
`drm_response_log_density()` case-14 leaf that was untested in the first
review.

### Remaining A3 issues

Status: implementation/test coverage present, with docs caveats above.

- #1324 Md-G: `tests/testthat/test-numeric-kernel-oracle.R` now counts
  non-finite kept grid points and sets `max_nonfinite = 0L` for the
  beta-binomial oracle.
- #1325 Md-H: `src/drmTMB.cpp` and `src/drm_response_kernels.h` now apply the
  beta-binomial mean nudge and shape floor in both the main objective and the
  response-kernel copy.
- #1326 Md-I: `drmTMB` fit objects and summaries now carry
  `estimator_exact`, and printed REML summaries distinguish exact restricted
  likelihood from the Laplace/Cox-Reid adjusted profile.
- #1344 Mi-6: runtime pruning note and test on #1367; `?phylo` branch-length
  help on A1 #1368 (`c86e86d88`).
- #1348 Mi-10: `simulate.drm_pair_association()` now saves and restores the
  caller's `.Random.seed` when `seed` is supplied.
- #1350 Mi-12: both O3 `optim()` call sites share `drm_o3_optim_control()` and
  pass through `drm_o3_check_optim()`.
- #1357 UX-2: `summary.drmTMB()` now returns `nobs = stats::nobs(object)`.
- #1358 UX-3: empty derived summaries caused by a non-constant sigma predictor
  now point users to `$sdpars`.

## Local Evidence

All commands below were run from an isolated worktree at
`1f8f0801e3612ad46d0292d7d6c94b94f56a4f8f`.

```sh
Rscript -e 'pkgload::load_all(); testthat::test_file("tests/testthat/test-dinnage-audit-a3-curie.R"); testthat::test_file("tests/testthat/test-dinnage-audit-a3-misc.R"); testthat::test_file("tests/testthat/test-numeric-kernel-oracle.R")'
```

Result: pass. Counts were Curie A3 5 pass, A3 misc 13 pass, numeric kernel
oracle 392 pass. The TMB template recompiled locally under Apple clang with
pre-existing warnings.

```sh
git diff --check origin/main...HEAD
python3 tools/capability_ledger.py --check
python3 -m unittest tools/tests/test_capability_ledger.py
```

Result: pass. The generated ledger check reported 31 generated outputs, the
unit suite ran 80 tests, and the C17/C14 guard printed current-source
compatibility PASS.

`gh pr checks 1367 --watch=false` at review time showed `os-matrix` passing,
with the Ubuntu release shards and source-tree blind-spot job still pending.

## Scope and API Checks

Package scope remains intact: the code stays within existing univariate and
bivariate distributional-regression routes and does not add a new family or a
higher-dimensional model surface.

Likelihood changes are mathematically coherent for the repaired beta-binomial
path. Both copies now use the same parameterization:
`mu = eps + (1 - 2 * eps) * inv_logit(eta_mu)`, `phi = exp(-2 * log_sigma)`,
`alpha = max(mu * phi, 1e-8)`, `beta_shape = max((1 - mu) * phi, 1e-8)`, and
the beta-binomial normalizer uses `alpha + beta_shape` after flooring. This is
consistent between the main objective and the response-kernel `mi()` leaf.

The user-facing API additions are small and consistent with existing objects:
`summary(fit)$nobs` mirrors `nobs(fit)`, and `estimator_exact` is an additional
fit/summary field rather than a renamed estimator. The changed `summary()`
print text makes the REML distinction visible without changing the public
`estimator` value.
