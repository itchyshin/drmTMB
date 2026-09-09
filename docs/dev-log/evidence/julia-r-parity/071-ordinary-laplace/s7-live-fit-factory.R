#!/usr/bin/env Rscript
# The only live-fit entry point for S7.  It is deliberately small so the
# integrator selection is auditable: native TMB takes its own Laplace route;
# scalar Julia must receive the explicit requested marginal = "Laplace".

r071_s7_engine_fit <- function(spec, fixture, drm_fit = drmTMB) {
  if (!is.data.frame(spec) || nrow(spec) != 1L || !"engine" %in% names(spec) ||
      !spec$engine[[1L]] %in% c("tmb", "julia")) {
    stop("S7 live fit factory needs one tmb or julia task specification", call. = FALSE)
  }
  if (!is.list(fixture) || !all(c("formula", "family", "data") %in% names(fixture))) {
    stop("S7 live fit factory needs a complete frozen fixture", call. = FALSE)
  }
  args <- list(
    formula = fixture$formula, family = fixture$family, data = fixture$data,
    engine = spec$engine[[1L]]
  )
  if (identical(spec$engine[[1L]], "julia")) {
    if (!identical(fixture$marginal, "Laplace")) {
      stop("S7 scalar Julia fixture must explicitly request marginal = Laplace", call. = FALSE)
    }
    args$marginal <- "Laplace"
  }
  do.call(drm_fit, args)
}
