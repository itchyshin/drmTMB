.onLoad <- function(libname, pkgname) {
  if (requireNamespace("emmeans", quietly = TRUE)) {
    emmeans::.emm_register("drmTMB", pkgname)
  }
}

# Re-export `nlme`'s shared mixed-model extractors so attach order with
# `glmmTMB`/`lme4` does not replace them with drmTMB-only generics.
# drmTMB methods register through `NAMESPACE` `S3method()` directives.
#' @importFrom nlme fixef ranef
#' @export
fixef
#' @export
ranef
NULL
