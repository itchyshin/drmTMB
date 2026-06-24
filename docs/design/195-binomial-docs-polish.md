# Binomial Docs Polish

Slice S042 tightens user-facing binomial wording after the bridge map. The
reader is an applied ecology or environmental-science user choosing between an
ordinary event-probability model and an overdispersed success-count model.

The polished wording names:

- native TMB `stats::binomial(link = "logit")` as a fixed-effect first slice;
- 0/1 and `cbind(successes, failures)` as the supported response encodings;
- `beta_binomial()` as the next option when known-trial data need
  extra-binomial variation through `sigma`;
- unsupported neighbours: non-logit links, `sigma` formulas, binomial random or
  structured effects, bivariate or mixed responses, and non-phylogenetic
  `engine = "julia"` binomial fits.

This is prose alignment only. It does not widen native TMB or bridge support.
