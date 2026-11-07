# Current profile-retry source check

Checked 2026-10-26 against `DRModels.jl` `origin/main` at
`64ccb2d8d87b329e5a43b2358fd5cb4a36cd9716`. In
`src/inference.jl`, `_profile_optimize_result()` continues a finite
non-converged result only when a stored gradient is present. The finite-
difference path falls back to Nelder–Mead only after an exception; it does not
retry a finite `:not_converged` candidate. The probit phylogenetic SD profile
case therefore remains a production gap on current main.

The general-SD candidate is `70dbf564eb670144c63c08f61ea099084d95add2` and
contains the leased regression test `test/test_binomial_phylo_sd_regression.jl`.
The test-only overlay in this evidence directory passed both live R-to-Julia
bridge cases with a bounded BackTracking continuation. It does not modify
production code. A claim for `src/inference.jl` was refused because
`codex:docs-audit-julia-20261025` still holds that path. No production source
was changed during this check.

A 44-line source patch candidate was generated from the general-SD source. `git apply --check` passed against both the general-SD Julia candidate and the active docs-audit worktree; the patch has not been applied. Patch: `profile-retry-candidate.patch`.

## Ownership and exact-head CI refresh, 2026-10-26 07:00 MDT

The docs-audit lane still holds `src/inference.jl` under its live lease. Its
exact-head GitHub Actions run `40314962162` at `3c0d3794c7e6e4610048635f47cb4bac7c4e67d5`
has Julia shards 2/4, 3/4, and 4/4 successful; shard 1/4 remains in progress.
The profile patch remains unapplied pending the owner's release. The current
general-SD drmTMB lease covers only its listed bridge test and evidence paths;
it does not include or claim the Julia inference source.

## Direct Julia regression rerun, 2026-10-26 07:17 MDT

The focused file `test/test_binomial_phylo_sd_regression.jl` ran on Julia 1.10.0
in 68.25 seconds with one Julia and BLAS thread. The joint ordinary-plus-
phylogenetic test passed 27/27, and the phylogenetic intercept test passed
23/23. The probit phylogenetic SD-slope profile test failed 2/5: its upper
profile endpoint returned `:not_converged` from finite-difference LBFGS, so
`profile.failed == 1` and the upper bound was not finite. The lower endpoint
was accepted. The fit also warned that the finite-difference Hessian was not
positive definite and withheld Wald standard errors; this is not a Wald-SE
result or a coverage check.

SHA-256 was unchanged before and after the run for `src/inference.jl`
(`58113c64…`), `src/sparse_laplace_glmm.jl` (`ee3b7618…`),
`src/binomial_sd_regression.jl` (`aa25e817…`), and the test
(`a94debee…`). The exact transcript is
`direct-phylo-sd-test-20261026-0715.log`. This reproduces the production profile
failure without the test-only overlay. The proposed patch is still unapplied
because the docs-audit lane continues to own `src/inference.jl`.


## Isolated production-patch probe, 2026-10-26 07:42 MDT

The candidate patch was applied only in `/tmp/codex-sd-probit-profile-probe-20261026`, a copy of the current `general-sd-julia` worktree with `.git` and `.julia` excluded. The focused command was `env OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. test/test_binomial_phylo_sd_regression.jl`. It exited 0. The joint ordinary-plus-phylogenetic fit/oracle passed 27/27, the phylogenetic intercept passed 23/23, and the probit phylogenetic SD-slope profile test passed 5/5. This directly exercises the proposed production retry rather than the earlier in-memory overlay.

The fit still reported a non-positive-definite finite-difference Hessian and withheld Wald SEs. This is workflow evidence for finite profile endpoints, not calibrated uncertainty or a Wald result. The isolated patched `src/inference.jl` SHA-256 is `bc9592479f22a50a2c46efcb7bac09c120d1b0c64eda8254aa04a64026419c0d`; the unchanged test SHA-256 is `a94debee744dba611daa1c88ad64fa529af3b7a93753f8cc31dae8d326276e72`; the patch SHA-256 is `144e2fac52a95c2614b74d9beef9e7c970c0ad56469b26301f8d4796ce9df58a`. Raw output: `profile-retry-isolated-probe-20261026.log`. The authoritative `DRModels.jl` worktree remains unchanged by this probe. Its `src/inference.jl` path is still held by the active docs-audit lease, and the lane lease tool refused the profile-repair claim.


## Docs-audit PR status, 2026-10-26 07:55 MDT

PR #1210 is open at head `38c3a13b48108a9daf5784e3b75a2c68d45facef`. Its changes, docs build, and docs preview have passed; all four Julia test shards remain in progress. The docs-audit owner has found additional wording gaps and a table claim that conflicts with Gamma/Beta offset refusal rules, and is recording the needed corrections before merge. The `DRM.jl/src/inference.jl` lease remains active. The profile-retry candidate is therefore still tested only in the isolated copy and remains unapplied to the authoritative candidate.
