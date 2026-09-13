# OU v1 frozen capability manifest

This document freezes the OU v1 target at the BM phylogenetic configurations
listed in `264-ou-v1-capability-manifest.csv`. Every row must finish as
`SUPPORTED`, `FIT_ONLY`, or `REFUSED`; no row can silently disappear.

The census is a snapshot at commit `501fb3ae4`. A BM phylogenetic configuration
added after this manifest is an OU v2 candidate, not an unplanned addition to
this programme.

The snapshot has **29 rows**, including G16: BM's univariate Gaussian
missing-response phylogenetic route. That row needs its own OU likelihood and
recovery evidence; it cannot borrow complete-response evidence.

## Correlated OU correction

For diagonal decay matrix \(A=\operatorname{diag}(\alpha_\mu,\alpha_\sigma)\),
the multivariate stationary covariance \(S\) is valid only when
\(AS+SA^\top\) is positive semidefinite. Therefore OU v1 will parameterize a
bounded diffusion correlation \(r_D=c\tanh(\eta)\), with a documented
constant \(0<c<1\), and report the stationary correlation

\[
r_S=\frac{2\sqrt{\alpha_\mu\alpha_\sigma}}
          {\alpha_\mu+\alpha_\sigma}r_D.
\]

This keeps every root and edge covariance valid when rates differ. Simply
unmapping BM's `eta_cor_phylo` is invalid: the current OU likelihood does not
use that parameter.

## Scope boundary

The manifest includes complete univariate, bivariate, and missing-response
targets because OU v1 is a full BM-grammar programme. It explicitly excludes
phylogenetic-temporal combinations, new post-census BM configurations,
forecasting/newdata work, and any universal OU-preference claim.
