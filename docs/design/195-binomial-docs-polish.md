# Binomial Docs Polish

> **Superseded boundary (2026-07-13):** this historical fixed-effect-first
> polish preceded Arc 2a/2b. Plain binomial now also fits ordinary `mu` random
> intercepts and independent numeric slopes; only the exact `mc-0061` slope
> domain is inference-ready with caveats. The notes below retain their original
> slice context but must not be read as current capability truth.

Slice S042 tightens user-facing binomial wording after the bridge map. The
reader is an applied ecology or environmental-science user choosing between an
ordinary event-probability model and an overdispersed success-count model.

The polished wording names:

- native TMB `stats::binomial(link = "logit")` with fixed effects plus ordinary
  `mu` random-intercept and independent-slope first slices;
- 0/1 and `cbind(successes, failures)` as the supported response encodings;
- `beta_binomial()` as the next option when known-trial data need
  extra-binomial variation through `sigma`;
- unsupported neighbours: non-logit links, `sigma` formulas, correlated or
  labelled binomial slopes, structured effects, bivariate or mixed responses,
  and non-phylogenetic
  `engine = "julia"` binomial fits.

This is prose alignment only. It does not widen native TMB or bridge support.
