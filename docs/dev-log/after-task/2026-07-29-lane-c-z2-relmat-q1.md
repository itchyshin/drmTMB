# Lane C Z2-relmat — zero-one-beta relmat q1 point-fit recovery

## 1. Goal

Recover only `mc-0585`: ordinary univariate `zero_one_beta()` mean-side
`relmat(1 | species, K = K)` with an unlabelled intercept-only q1 latent
effect. The ceiling is technical point-fit recovery.

## 2. Implemented

The existing generic structured-mean carrier now supports the exact K-only
relmat route. Tests independently reconstruct `K -> Q`, determinant
normalization, deliberately reversed matrix/observation ordering, and the
objective/AD-gradient contract.

## 3a. Decisions and Rejected Alternatives

The target is `u ~ N(0, tau^2 K)`, equivalently `Q = K^-1` and
`tau = exp(log_sd_phylo)`. The direct SD target is visible but unavailable to
profile dispatch. Supplied `Q`, pedigree inputs, slopes, q2+, other dpars, and
other providers remain outside this route.

## 4. Files Touched

`R/drmTMB.R`, `R/profile.R`, `man/profile_targets.Rd`,
`tests/testthat/test-zero-one-beta.R`, the relmat fixture runner, the canonical
ledger, and its generated outputs changed. No foreign forensic material was
staged.

## 5. Checks Run

Focused `zero-one-beta` tests passed. The independent objective matched TMB,
AD gradients agreed with central finite differences, and
`capability_ledger.py --write` plus `--check` passed.

## 6. Tests of the Tests

The oracle independently reconstructs `K -> Q`, determinant normalization, and
reversed labels. The profile endpoint test mocks the dispatcher and proves no
profile refit begins.

## 7a. Issue Ledger

The final retained receipt is
`implementation-recovery/2026-07-29-lane-c-zob-relmat-q1-local-run-3/`:
four of four fixed local attempts converged with `pdHess = TRUE`, finite
interior reported estimates, and gradients at most 0.01; the fitted IID control
also passed. Mean latent-SD recovery was 0.5523 for truth 0.55.

## 8. Consistency Audit

Noether: GO after checking the K-to-Q penalty, log determinant, and label
mapping. Fisher: GO after the repaired receipt enforced gradients and
boundaries. Rose: GO after direct `profile()` and endpoint-dispatch fences and
the regenerated profile-target reference were added.

## 9. What Did Not Go Smoothly

The retained `...local-run-1/` is non-promotional: it named the DGP latent draw
in observation order despite deliberately reversed K labels. The repair names
draws with `rownames(K)`; the final run also enforces gradient and full
reporting-scale boundary gates.

## 10. Known Residuals

`mc-0585` is `implemented / verified / point_fit_recovery` only. There is no
profile feasibility, interval feasibility, calibration, coverage, or
inference-ready evidence.

## 11. Team Learning

Labelled covariance simulations must name latent draws in the primitive
matrix's row order. Recovery pass rules must enforce recorded gradients and all
reporting-scale boundaries, not merely record them.

## 12. Cross-Product Coverage

The change covers only ordinary zero_one_beta mean-side relmat K q1 and does NOT cover the other 30 remaining cells, any scale/profile/interval surface, or any Lane A/B target.

## 13. Next Step

The generated model census is 316 implemented, 330 rejected by design, and 31
not implemented. Continue only with a separately verified provider route; the
next candidate is `mc-0586` spatial q1.
