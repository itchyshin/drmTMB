# Phylo Extractor Status Fields

This note supports S029 of the 100-slice finish run. It records the status
fields that make phylogenetic q2 and q4 extractors honest before any uncertainty
or bridge promotion.

The machine-readable source is
`docs/dev-log/dashboard/phylo-extractor-status.tsv`.

## Contract

`corpairs()`, `summary(fit)$covariance`, and `profile_targets()` serve different
questions:

- `corpairs(conf.int = FALSE)` is a point-estimate extractor and should say
  `conf.status = "not_requested"` with `interval_source = "not_available"`.
- `corpairs(conf.int = TRUE)` can expose target-specific interval status, such
  as `newdata_required` for covariate-dependent q2 rows or
  `derived_interval_unavailable` for full q4 unstructured correlations.
- `summary(fit)$covariance` records covariance interval status separately as
  `covariance_conf.status`.
- `profile_targets()` records target readiness through `profile_ready` and
  `profile_note`.

None of these fields is a Wald-interval promotion for q4 correlations. A row
can advance only with target-specific interval evidence.

## Next Action

S030 should refresh the served dashboard after the native R Gaussian phylo wave
so the live copy exposes the q4 target inventory, phylo balance inventory,
scale diagnostics, profile/logLik table, bootstrap accounting, q2/q4 target map,
and extractor status table together.
