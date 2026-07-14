# Ayumi Inference Gap Ledger

## Purpose

This note banks A071-A080 for the Ayumi phylogenetic balance arc. It separates
fit support from inferential support for location, scale, and bivariate q4
phylogenetic models so the next Ayumi-facing answer can be useful without
claiming interval coverage that has not been evaluated.

## Status Summary

Native TMB ML can fit balanced univariate Gaussian `phylo()` cells for location
(`mu`), scale (`sigma`), and matched `mu+sigma` formulas. Some of those rows
expose direct profile targets. That is target availability, not calibrated
coverage.

Native TMB q4 ML is a diagnostic route. The q4 SD targets can be direct profile
targets, but the current bootstrap evidence is split: a 30-tip B=2 smoke
returned successful refits, while 100-tip careful and robust smokes returned
`bootstrap_unavailable`. The 250-tip endpoint-profile budget returned a
`profile_failed` status row from a nonconverged, `pdHess = FALSE` fit. These
rows are evidence that status accounting works; they are not practical Ayumi
intervals.

Native TMB q4 REML now has tested block-diagonal and dense recovery evidence.
The q1 sigma, matched univariate q2, and bivariate mean-side q2 routes also have
point-fit/recovery evidence. None of these rows has calibrated interval or
coverage evidence, and q4 Patterson-Thompson REML is not HSquared AI-REML.

Direct DRM.jl has q4 profile/bootstrap machinery in the active implementation
worktree. A lightweight source check confirmed that `profile_sigma_a`,
`bootstrap_sigma_a`, `fit_q4_sparse_tmb`, `confint`, and `drm` are defined when
DRM.jl is loaded from
`/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`. That is direct
Julia evidence only. It does not promote R-via-Julia bridge support.

The direct DRM.jl bootstrap evidence also contains an important caveat:
`docs/dev-log/after-task/2026-06-13-bivariate-bootstrap-sigma-a.md` in the
active DRM.jl worktree records severe scale-axis SD undercoverage for the
parametric bootstrap at nominal 90% coverage. This is a good reason to keep
profile/bootstrap status row-specific and to avoid any broad interval claim.

## Dashboard Ledgers

`docs/dev-log/dashboard/ayumi-inference-coverage-ledger.tsv` records Wald,
profile, bootstrap, and coverage status for the main Ayumi balance cells. Most
rows remain `not_evaluated`, `unsupported`, or `undercoverage_known`.

`docs/dev-log/dashboard/ayumi-boundary-status-ledger.tsv` records the boundary
and fit-status rows that matter for applied interpretation. It keeps
`pdHess = FALSE`, log-`sigma` clamps, near-boundary residual `rho12`, q4
covariance warnings, profile failures, and direct Julia collapsed-axis behavior
visible as separate facts.

The q4 target inventory also has a direct-DRM.jl row:
`direct_drmjl_q4_profile_bootstrap`. Its bridge status is `unsupported` because
direct Julia availability is not an R bridge route.

## Promotion Contract

A row may be considered for Ayumi-facing interval language only after all of
the following are true for the same model cell:

1. The point fit returns with an interpretable convergence and Hessian status,
   or the row explicitly states why Hessian-based inference is not used.
2. Native R, direct DRM.jl, and R-via-Julia target identities agree when the
   bridge is involved.
3. Profile or bootstrap status is target-specific, including failures and
   boundary messages.
4. Replicated known-truth evidence evaluates coverage or explicitly labels
   coverage as not evaluated.
5. The row does not borrow REML, AI-REML, or HSquared language from another
   estimator family.

## Decision

A071-A080 close the inference-status gap, not the inference problem. The honest
current answer is:

> Native ML gives usable point/status evidence for selected balanced Gaussian
> phylogenetic cells. Native q4 ML and scale-side real-data rows still need
> boundary-aware inference work; native q4 REML recovery does not close that
> interval gap. Direct DRM.jl has useful q4 profile/bootstrap
> machinery, but the R bridge is not promoted and scale-axis bootstrap
> undercoverage is already known.

This is enough to prepare an Ayumi reply outline later, but not enough to post
or claim 10,440-tip sigma-phylo intervals.
