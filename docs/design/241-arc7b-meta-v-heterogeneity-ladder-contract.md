# 241 — Arc 7B known-`V` meta-analytic heterogeneity ladder

Status: **implementation and local validation contract**. This document extends
the constant-extra-heterogeneity B3 contract without changing it. It does not
promote a capability tier or establish interval calibration.

## Purpose

Gaussian meta-analysis in `drmTMB` combines a supplied sampling covariance with
one or more *separate* modelled sources of heterogeneity. The purpose of this
arc is to demonstrate, with a known data-generating process and an independent
Gaussian likelihood calculation, which of those sources can be fitted together.
It is not a claim that every meta-analysis can identify every layer.

For response vector \(y\), known sampling covariance \(V\), fixed-effect design
\(X\), and residual SD \(\sigma_i\), the observation model is

\[
y \sim N\{X\beta + Z_s b_s + Z_e b_e,\; V +
  \operatorname{diag}(\sigma_i^2)\},
\]

where the optional latent location effects are independent conditional on their
modelled SDs:

\[
b_s \sim N\{0, \operatorname{diag}(\tau_{s,j}^2)\},\qquad
b_e \sim N\{0, \operatorname{diag}(\tau_{e,k}^2)\}.
\]

Consequently the marginal covariance used by the direct oracle is

\[
\Sigma = V + \operatorname{diag}(\sigma_i^2) +
Z_s\operatorname{diag}(\tau_{s,j}^2)Z_s^\mathsf{T} +
Z_e\operatorname{diag}(\tau_{e,k}^2)Z_e^\mathsf{T}.
\]

All fitted scale coefficients use log-SD links. A comparator which reports a
log-variance coefficient must therefore be divided by two before comparison.

For the four additive-Gaussian ladder members, the parameter map is:

\[
\begin{aligned}
\log \sigma_i &= z_i^\mathsf{T}\gamma,\\
\log \tau_{s,j} &= z_{s,j}^\mathsf{T}\alpha_s,\\
\log \tau_{e,k} &= z_{e,k}^\mathsf{T}\alpha_e.
\end{aligned}
\]

L has no moderator-driven scale coefficient; LS estimates only \(\gamma\);
LSS adds \(\alpha_s\); and LSSS adds the nested effect-level
\(\alpha_e\). The formula grammar mirrors those equations directly: `sigma ~
z`, `sd(study) ~ z_study`, and `sd(effect) ~ z_effect`. An effect label must be
defined within its study (so labels are not shared across studies) and must have
replication.

DH has a different conditional model:

\[
\log \sigma_{ij} = z_{ij}^\mathsf{T}\gamma + u_j,
\qquad u_j \sim N(0,\omega^2).
\]

Integrating \(u_j\) creates a residual scale mixture; it does **not** add a
Gaussian covariance term of the form \(Z\operatorname{diag}(\tau^2)Z^\mathsf{T}\).
Thus DH is a separately labelled sensitivity route, not LSS under another
name and not an oracle-validated campaign target in this arc.

## The ladder

| Layer | Formula | Estimand | Required replication |
| --- | --- | --- | --- |
| L | `yi ~ x + meta_V(V = V)` | pooled location only | one effect per study is sufficient |
| LS | `..., sigma ~ z` | residual heterogeneity SD \(\sigma_i\) | moderator observed for each effect |
| LSS | `... + (1 | study), sigma ~ z, sd(study) ~ z_study` | study-level location SD \(\tau_{s,j}\) | multiple effects within study; `z_study` constant within study |
| LSSS | `... + (1 | study) + (1 | effect), sigma ~ z, sd(study) ~ z_study, sd(effect) ~ z_effect` | study and nested-effect location SDs | repeated effects nested in studies |
| DH sensitivity | `... + (1 | study), sigma ~ z + (1 | study)` | a random deviation in log residual SD | multiple effects within study |

The DH sensitivity model is not an alternative spelling of LSS: it places a
random effect in the `sigma` linear predictor, whereas LSS models the SD of a
location random effect with `sd(study) ~ ...`.

## Validation contract

1. Every layer has a deterministic known-truth DGP and retains source seed,
   known-`V` representation, nesting map, convergence state, Hessian state, and
   all requested interval states.
2. A diagonal-`V` LS fit is compared with the compatible `metafor` route after
   its log-variance to log-SD conversion.
3. Dense-`V`, LSS, and LSSS fits are compared with the marginal Gaussian
   likelihood above. A diagonal comparator cannot validate those routes. DH is
   excluded from that oracle: a random effect on log residual SD creates a
   scale mixture rather than the additive Gaussian covariance in this contract.
4. Local smoke includes a deliberately weak small-study boundary and a larger
   interior control. A clean optimizer result is not evidence of identifiability.
5. Profile-LR is the only candidate full-campaign interval procedure. Endpoint
   and `tmbprofile` are numerical cross-checks of that one procedure. A small
   bootstrap engineering check must retain its inner-refit completion rate.

## Explicit exclusions

This contract does not cover structured `phylo()`, `animal()`, `relmat()`, or
`spatial()` LSS; bivariate meta-analysis; publication-bias models; non-Gaussian
known-`V` models; arbitrary additional nesting levels; or a capability-tier
change. The existing B0 draft PR remains separate and must not be merged as a
side effect of this work.

The parameterization and comparator boundary follow Nakagawa et al. (2025,
*Global Change Biology*, 31:e70204, doi:10.1111/gcb.70204), the supplied
[location-scale meta-analysis guide](https://itchyshin.github.io/location-scale_meta-analysis/),
and the local `location-scale-scale` article. They establish terminology and
comparator scope; they are not evidence that this exact dense or layered
`meta_V()` route has calibrated intervals.
