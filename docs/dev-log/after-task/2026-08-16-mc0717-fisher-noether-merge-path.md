# After Task: Fisher / Noether merge-path for PR #1059

**Reader:** Shinichi and the next compute owner.  
**Lane:** `cursor/ng-correlated-slope-impl` (worktree `.worktrees/ng-corr-w1`).  
**Quiesce:** merge still blocked. This task did not request merge and did not launch Totoro.

## Goal

Read Design 257's alignment table against one fitted binomial `(1 + x | g)` object, decide whether the evidence supports `point_fit_recovery` only, and park a Totoro smoke runbook.

## Verdict

**PASS** for alignment and claim ceiling. **Merge blocked by quiesce.**

Noether: `sd0` / `sd1` / `rho_re` extractors, `tanh(eta_cor_mu)`, and the log-sech Cholesky match Design 257 on seed `20260811` (`n_group = 56`, `n_each = 14`). Absolute errors 0.051 / 0.005 / 0.141 all sit inside the 0.30 gates. Fisher: `estimator = ML`, `REML = FALSE`, `REML = TRUE` still aborts, and the generic `profile_ready = TRUE` surface is not a Wave 1 interval claim. Wald already emits Hessian NaNs.

Confirmed residuals, not alignment failures: constant-within-group `x` still fits (`sd1 ≈ 0`, `pdHess = FALSE`); parser `i` hint still says `experimental q = 2`.

## Files Changed

- `docs/dev-log/research/2026-08-16-mc0717-totoro-smoke-brief.md` — predeclared 27-fit Totoro smoke; not launched.
- `docs/dev-log/check-log.md` — this review.
- this after-task.

Local probe only (not committed): `scratchpad/2026-08-16-mc0717-fisher-noether-fit.R` and `.json`.

## Checks Run

| Check | Result |
| --- | --- |
| Fitted object, seed `20260811` | `conv = 0`, `pdHess = TRUE`, `estimator = ML` |
| Alignment gates 0.30 | PASS on `sd0` / `sd1` / `rho_re` |
| `rho_re == tanh(eta_cor_mu)` | TRUE |
| `REML = TRUE` | aborted |
| Totoro `ssh -o BatchMode=yes` | succeeded; no checkout at `~/drmTMB` |
| Totoro launch | **not run** |

## Next Actions

1. Keep draft PR #1059 unmerged.
2. Add the constant-within-group `x` rejection test when someone next touches the prereq file.
3. Launch the 27-fit Totoro smoke only after Shinichi names this brief.
4. Stay off #1033, MSPL, and Ligges.
