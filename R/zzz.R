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
#
# One entry per generic/class pair that NAMESPACE registers an S3 method for
# (see the `S3method(<generic>, <class>)` lines there). `fixef` has three
# implementations -- native `drmTMB` fits and the two Julia-bridge result
# classes -- so all three need registering on nlme's table, not just the
# native one, or `fixef()` on a Julia-bridge fit errors with "no applicable
# method" whenever nlme is attached after drmTMB (nlme's exported `fixef`
# then masks drmTMB's re-export in the search path).
.drmtmb_foreign_s3_methods <- list(
  fixef = c("drmTMB", "drmTMB_julia", "drmTMB_julia_xfam"),
  ranef = "drmTMB"
)

register_foreign_s3_methods <- function() {
  if (!requireNamespace("nlme", quietly = TRUE)) {
    return(invisible(FALSE))
  }
  nlme_ns <- asNamespace("nlme")
  drmtmb_ns <- asNamespace("drmTMB")
  for (generic in names(.drmtmb_foreign_s3_methods)) {
    for (class in .drmtmb_foreign_s3_methods[[generic]]) {
      method <- get(paste0(generic, ".", class), envir = drmtmb_ns)
      registerS3method(generic, class, method, envir = nlme_ns)
    }
  }
  invisible(TRUE)
}
