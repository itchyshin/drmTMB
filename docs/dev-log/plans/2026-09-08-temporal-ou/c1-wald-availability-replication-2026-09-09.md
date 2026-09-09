# C1 AR1 Wald-availability replication

The first retained five-seed AR1 pilot showed four available fixed-effect Wald
intervals in primary cell C1 and one unavailable interval at seed `2026091002`.
The independent dense marginal profile for that seed established an active or
practically flat residual-variance boundary, rather than a latent-state
optimizer artifact.

This bounded current-source replication used five new fixed seeds
`2026091101`--`2026091105` with the same C1 data-generating process and the
production two-start free-sigma fit. It is not a replacement for the declared
1,000-replicate calibration campaign and does not make a coverage claim.

Four of the five selected fits reported a positive-definite full Hessian,
finite `vcov()` result, and three finite Wald intervals. The remaining fit,
seed `2026091101`, estimated residual SD `0.000338`, reported a non-positive-
definite Hessian, and correctly left covariance and intervals unavailable.
All five fits and all ten signed-persistence starts were retained.

Together with the original pilot, C1 has 8 available current-route interval
sets among 10 bounded datasets. This does not estimate a campaign rate with
useful precision, but it shows that the original failure is not an isolated
optimizer accident. It is already incompatible with the predeclared primary
availability requirement of at least 0.99, so a campaign under the present
free-sigma full-Hessian Wald contract cannot qualify that interval method.

The retained files are under
`docs/dev-log/simulation-artifacts/2026-09-09-temporal-ar1-c1-wald-replication/`.
They record selected fits, every start, source fingerprint, seeds, and session
information. No conditional covariance, residual-scale constraint, profile
interval, or campaign was substituted for the unavailable result.
