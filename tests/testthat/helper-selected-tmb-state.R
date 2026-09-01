selected_tmb_par_list <- function(fit) {
  stopifnot(
    inherits(fit, "drmTMB"),
    is.list(fit$tmb_state),
    !is.null(fit$tmb_state$last.par.best)
  )
  fit$obj$env$parList(
    fit$opt$par,
    par = fit$tmb_state$last.par.best
  )
}
