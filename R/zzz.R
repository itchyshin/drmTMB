.onLoad <- function(libname, pkgname) {
  if (requireNamespace("emmeans", quietly = TRUE)) {
    emmeans::.emm_register("drmTMB", pkgname)
  }
  register_foreign_s3_methods()
}

# `fixef()` and `ranef()` are drmTMB's own generics (see `R/methods.R`), but they
# are not drmTMB's alone: `nlme` defines generics of the same name, and `lme4` and
# `glmmTMB` both re-export `nlme`'s rather than defining their own -- verified by
# `identical(lme4::ranef, nlme::ranef)` and the same for `glmmTMB` and for `fixef`.
#
# So attach order decides which generic a bare `ranef(fit)` reaches. A reader who
# writes `library(drmTMB); library(glmmTMB)` gets `nlme`'s generic, which had no
# method for a `drmTMB` object, and the call failed outright with
# "no applicable method for 'ranef' applied to an object of class \"drmTMB\"".
# Nothing about the fit was wrong; only the search path.
#
# Registering drmTMB's methods on `nlme`'s generics makes dispatch work whichever
# generic wins, which is the convention `lme4` and `glmmTMB` already follow. This
# is dynamic registration rather than a NAMESPACE `S3method()` directive because
# `nlme` is optional here: it is a recommended package, so it is present in
# practice, but drmTMB does not import it and must load without it.
#
# `sigma()` needs none of this: it is already registered against the `stats`
# generic (`importFrom(stats, sigma)`), which is the shared one.
register_foreign_s3_methods <- function() {
  if (!requireNamespace("nlme", quietly = TRUE)) {
    return(invisible(FALSE))
  }
  nlme_ns <- asNamespace("nlme")
  for (generic in c("fixef", "ranef")) {
    method <- get(paste0(generic, ".drmTMB"), envir = asNamespace("drmTMB"))
    registerS3method(generic, "drmTMB", method, envir = nlme_ns)
  }
  invisible(TRUE)
}
