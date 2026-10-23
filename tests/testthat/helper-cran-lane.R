# Tests retained in the installed-package CRAN check lane. The complete suite
# runs in repository CI with NOT_CRAN=true.
drm_cran_test_contexts <- function() {
  c(
    # Release identity and runner safeguards.
    "cran-lane-filter",
    "release-identity",
    "package-skeleton",
    # Formula parsing and ordinary family contracts.
    "formula-double-bar",
    "formula-grouping-guard",
    "formula-smooth-terms",
    "gaussian-location-scale",
    "poisson-mean",
    "binomial-response",
    "binomial-links",
    "beta-binomial",
    "cumulative-logit",
    "gamma-location-scale",
    "lognormal-location-scale",
    "skew-normal-location-scale",
    "student-location-scale",
    "family-link-contract",
    "family-dpq",
    "zi-poisson",
    "zi-nbinom2",
    "hurdle-nbinom2",
    "biv-lognormal",
    "biv-student",
    # One representative route for each major package surface.
    "meta-known-v",
    "missing-response-continuous",
    "missing-predictor-gaussian",
    "missing-predictor-binary",
    "missing-predictor-zero-one-beta",
    "structured-effects",
    "corpairs",
    "check-drm",
    "summary",
    "predict-parameters",
    "prediction-grid",
    "optimizer-contract",
    "control",
    # Experimental MSPL and current release additions.
    "mspl-estimator",
    "mspl-kernels",
    "mspl-link-dispatch",
    "mspl-link-general",
    "mspl-nonlogit-links",
    "offset-families",
    # Reader-facing and S3 compatibility smokes.
    "reader-journeys",
    "reader-public-schema",
    "reader-oldfit-compat",
    "boundary-surfacing",
    "foreign-s3-dispatch",
    "profile-shape-boundary"
  )
}

drm_cran_test_filter <- function() {
  paste0(
    "(^|/test-)(",
    paste(drm_cran_test_contexts(), collapse = "|"),
    ")$"
  )
}
