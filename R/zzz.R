.onLoad <- function(libname, pkgname) {
  if (requireNamespace("emmeans", quietly = TRUE)) {
    emmeans::.emm_register("drmTMB", pkgname)
  }
  register_foreign_s3_methods()
}

# drmTMB re-exports `nlme`'s `fixef()` and `ranef()` (see `R/drmTMB-package.R`), matching
# `lme4` and `glmmTMB`. NAMESPACE `S3method()` registers methods on the imported generic
# in drmTMB's namespace, but explicit `nlme::ranef()` and attach-order masking still need
# the methods registered on `nlme`'s namespace -- verified by `getS3method(..., envir =
# asNamespace("nlme"))` after install without this hook.
register_foreign_s3_methods <- function() {
  if (!requireNamespace("nlme", quietly = TRUE)) {
    return(invisible(FALSE))
  }
  nlme_ns <- asNamespace("nlme")
  drmtmb_ns <- asNamespace("drmTMB")
  for (generic in c("fixef", "ranef")) {
    method <- get(paste0(generic, ".drmTMB"), envir = drmtmb_ns)
    registerS3method(generic, "drmTMB", method, envir = nlme_ns)
  }
  invisible(TRUE)
}
