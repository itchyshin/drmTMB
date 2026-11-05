# Fixed-effect normal priors and ridge penalties

Status: implementation and bounded validation complete; broad checks still running. No push, merge, release or submission.

R isolated branch: `codex/fixed-effect-priors-20261105`, base `9fea3036791e9bd836e080d9297cd04b1b29c2f8`. Aggregate SHA-256 of R/native source and the two prior test files: `c53a03570e8263f8c75e2c95929d03f069b3c97d0694fed8cab5e7113cfbc28f` (76 files, manifest in `docs/dev-log/priors-lane-20261105/evidence/`). Julia base: `24ac6ca925a5c0f870b345b18804c9e592d0d275`; final aggregate source SHA-256 `a30e347285f925af2e128ed6350fafe4d6b9035668444606bfa2fcea13e26653`. Aggregate hashes are not Git commit IDs.

The first slice admits ordinary, complete, unit-weight, fixed-effect Gaussian mu/sigma and binomial-logit mu models. Normal priors include density constants; ridge adds exactly 0.5 lambda beta squared. Selection uses dpar and final design-matrix column, with explicit intercept policy for whole-block selectors. Zero ridge retains ML and ordinary likelihood controls. Active fits expose local penalized-Hessian curvature; interval and likelihood-comparison methods refuse. SD priors and sampling remain outside this slice.

On Totoro, final optimized R source passed both new prior test files and the 10-file affected regression set (9.099 seconds; two existing live-Julia comparison skips). Julia final source passed its 82-check focused suite and 14 affected test files. Five live R-to-Julia fixtures passed, including same-name mu/sigma predictors, binomial partial priors, zero ridge, factor interaction and no-intercept factors. Maximum coefficient gap was 4.30e-11; maximum data-log-likelihood gap was 1.07e-12. This is bounded fixture agreement, not general parity or interval calibration.

The R tutorial executes on the candidate and renders to HTML. `pkgdown::check_pkgdown()` passes. The Julia prior guide executes and builds in an isolated single-page check. A full Julia site build fails on a joint-missing-data convergence assertion also reproduced on matched clean main; that example was not changed. Full package checks and suites remain pending in the current checkpoint.

Noether and the independent integration reviewer returned scoped READY after fixes. Pat returned scoped READY with a final prose/code alignment suggestion, now incorporated. See `docs/dev-log/after-task/2026-11-05-fixed-effect-priors.md` for failures, test mutations and source-specific limits. The main log contains only a pointer to this record; existing cleanup and PR #1651 receipt entries are unchanged.
