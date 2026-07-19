# After Task: Arc 4c PR-A coverage infrastructure

## 1. Goal

Freeze and test the infrastructure for an evidence-first coverage campaign of the three remaining ordinary `mu` random-slope cells: skew-normal `mc-0464`, Tweedie `mc-0539`, and zero-one Beta `mc-0575`. This phase ends before compute. It does **NOT cover** any model fit, coverage result, ledger promotion, O3/AGHQ expansion, Cox-Reid expansion, or `supported` claim.

## 2. Implemented

- Added one sourceable Arc 4c contract, one retained-attempt runner, and one independent summarizer.
- Froze the three DGPs, natural-scale SD target 0.50, M grid, seed mapping, ten-replicate shards, all-attempt coverage denominator, exact-binomial gate, and contiguous-suffix floor rule.
- Added strict raw schemas, atomic TSV plus checksum publication, corrupt-checkpoint quarantine, deterministic resume, and manifest-authoritative aggregation.
- Added Fir preflight, smoke, array, and `afterok` aggregation scripts with one-thread pins, build/source provenance, deterministic partitioning, and a global 96-task ceiling.
- Added source-checkout contract tests and source-tarball skips for intentionally excluded top-level tools.
- Qualified inherited O3 calls as `stats::dnorm()` and `stats::plogis()` to remove an R-code-check NOTE found while walking around the change.
- Quoted paths in five inherited SHA-256 helpers so tests work from the repository's real path containing `Github Local`.

## 3a. Decisions and Rejected Alternatives

- Kept `estimator = ML` and used the ordinary drmTMB profile route. O3 and Cox-Reid remain responses to later negative evidence, not part of this certification.
- Kept M=8 exploratory. A failure there excludes only that rung; any M=16/32/64 smoke failure halts that family.
- Scored noncomputable intervals as noncoverage in the primary denominator. Conditional coverage is diagnostic and cannot rescue availability failure.
- Rejected GitHub Actions for simulation and artifact storage under D-50. Fir is the frozen execution host after approval.
- Rejected any fit-based local smoke during PR A because even a one-replicate model fit crosses the explicit Gate A boundary.

## 4. Files Touched

- Contract and analysis: `tools/arc4c-mu-slope-coverage-contract.R`, `tools/run-arc4c-mu-slope-coverage.R`, `tools/summarize-arc4c-mu-slope-coverage.R`.
- Dispatch: `tools/prepare-arc4c-drac-dispatch.R` and the three `tools/slurm/arc4c-*.sbatch` workers.
- Tests: `tests/testthat/test-arc4c-mu-slope-coverage-runner.R`, `tests/testthat/test-arc4c-drac-dispatch.R`.
- Design receipts: the S0, ultra-plan, and Fisher/Rose plan-review documents dated 2026-07-19.
- Adjacent portability: five development runners now quote SHA helper paths; `R/aghq-coxreid.R` qualifies two `stats` functions.

## 5. Checks Run

- Arc 4c runner contract: 86 expectations, zero failures.
- Arc 4c dispatch contract: 156 expectations, zero failures.
- All three Slurm scripts: `bash -n` passed.
- Capability ledger generation check, 37 ledger unit tests, and Mission Control validation passed without ledger mutation.
- `devtools::document()` produced no generated changes.
- Full `devtools::test()` reached the complete suite; its first pass exposed only inherited unquoted-path failures, which were repaired and rechecked in the affected runner files.
- The first `devtools::check()` correctly failed because the new development tests sourced `tools/` from a source tarball. The repaired tests now skip only in that tarball and still execute fully in a source checkout. The final full-check result is recorded in `docs/dev-log/check-log.md`.

## 6. Tests of the Tests

Synthetic fixtures exercise finite hits and misses, fit errors, bad Hessians, nonfinite profiles, primary versus conditional coverage, M=8-only exclusion, every non-exploratory smoke failure, corrupt and partial shards, wrong logical IDs, duplicate or missing rows, deterministic retry, partitioning, and CLI rejection. A 3,600-row executable synthetic aggregation rebuilt the three-family decision tables and then failed closed after deliberate manifest and shard corruption.

## 7a. Issue Ledger

No exact Arc 4c GitHub issue existed at S0. Related open issues `#687`, `#680`, `#496`, and `#33` were read-only context and were neither closed nor edited. Capability cells `mc-0464`, `mc-0539`, and `mc-0575` remain `point_fit_recovery`; PR A makes no ledger claim.

## 8. Consistency Audit

The runner, summarizer, smoke selector, and dispatch manifest share the same cell order, M grid, seed rule, and shard mapping. Full aggregation is manifest-authoritative and refuses extra as well as missing logical tasks. Worker scripts use the verified clone, call `pkgload::load_all(..., recompile = FALSE)` after the sole preflight build, retain failure outputs, and pin OMP, OpenBLAS, FlexiBLAS, BLIS, MKL, and TMB threads to one. The root worktree remained untouched.

## 9. What Did Not Go Smoothly

The first broad test run exposed path quoting defects in older SHA helpers because this checkout contains a space. The first source-tarball check then exposed that both new development tests assumed excluded top-level tools were present. Both failures were useful: the neighbouring helpers now work in the real workspace path, and the new tests follow the repository's established source-checkout/tarball boundary.

## 10. Known Residuals

No actual skew-normal, Tweedie, or zero-one Beta Arc 4c fit has run. Runtime, RSS, module resolution, package compilation, profile finiteness, and scheduler layout remain unverified until a fresh post-merge Fir preflight and the twelve approved N=1 smokes. The fixed DGP and gate may reveal a family-specific failure; that is an intended evidence outcome, not an infrastructure failure.

## 11. Team Learning

Fisher's denominator and contiguous-suffix corrections and Rose's manifest/provenance corrections were incorporated before code. Keeping runner and dispatch ownership separate made their seam testable: the physical array is derived from the smoke-selected logical manifest rather than from handwritten Slurm ranges. The Golden Set principle is preserved by explicit wrong-cell, missing-shard, and source-tarball cases rather than relying only on happy-path output.

## 12. Cross-Product Coverage

This work affects drmTMB only. It does NOT cover DRM.jl parity, gllvmTMB latent-variable integration, CRAN submission, capability-surface estimator redesign, other families or estimands, correlated slopes, random intercepts, scale-side effects, or `supported`-tier calibration. The durable next boundary is PR-A merge verification, followed by a separate maintainer compute approval.
