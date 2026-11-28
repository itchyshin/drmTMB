# After-task: generalized prior table, native R slice

## Delivered in the isolated drmTMB worktree

- Generalized table parsing and exact target resolution for Normal, Student-t, ridge, natural-SD Gamma, and LKJ correlation rows.
- Native normalized Student-t, residual/random SD Gamma, and LKJ objective terms, with no Jacobian on the natural SD/correlation density.
- Separate fit metadata for prior targets and penalty components; `logLik()` remains the unpenalized data likelihood.
- `update()` replay, inference refusals, no-prior identity, and pointwise objective accounting checks.
- Explicit Julia bridge refusal for Student-t, residual-SD, and LKJ table rows until its bridge contract supports them.

## Validation

The dedicated native test passes 84 assertions. It compares dense Gaussian objective values, scores, and Hessians at five interior points for mixed priors, Gaussian q=2 random-slope LKJ, and bivariate residual `rho12` LKJ. The regression filter passes 1,667 assertions, with four expected opt-in live-Julia skips. Separate independent Student-t, dense Gaussian, LKJ, and q=2 oracle programs pass their frozen checks and mutation controls. `git diff --check`, R parsing, and both owned Rd parses pass.

## Remaining gates

- The full drmTMB suite and live R-to-Julia suite remain outstanding on this exact Git source.
- AIC/BIC refuse active prior fits, but the message in `R/methods.R` is stale. That path is actively overlapped by open PRs including #1781 and was left unchanged.
- Three collateral roxygen-generated man-page diffs remain visible but unleased; they are preserved and must be excluded from a scoped commit.
- Independent final review and cross-package reconciliation are still required. No merge, release, or PR #1651 change occurred.

Source pin: branch `codex/drmtmb-generalized-prior-table-20261121`, base/worktree HEAD `5b7ead9b576599a671dadeb59a821dd2bc809f4d`. Test file SHA-256: `870eab3b70a4520a03f617daacc8737e2bb5ba72cd8264d112a317a33642c059`. No commit was created.
