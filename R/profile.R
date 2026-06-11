#' Confidence intervals for fitted model parameters
#'
#' `confint()` returns confidence intervals for a fitted `drmTMB` model. Wald
#' intervals are fast and are returned for fixed-effect coefficients and direct
#' response-scale parameter targets by default. Direct Wald targets include
#' constant residual-scale, random-effect standard-deviation, random-effect
#' correlation, and constant residual-correlation rows when the fitted TMB
#' parameter and `TMB::sdreport()` covariance are available.
#' Correlation Wald intervals are computed on the fitted TMB correlation-link
#' scale, equivalent to a guarded Fisher z/atanh transform, and then returned on
#' the correlation scale.
#' Bootstrap intervals simulate and refit direct targets. For positive scale and
#' SD targets, percentile endpoints are taken on the fitted log scale before
#' back-transforming to the response scale.
#' Profile-likelihood intervals are slower because nuisance parameters are
#' re-optimized; this first public profile path supports explicit fixed-effect,
#' constant distributional-scale, random-effect standard-deviation,
#' random-effect correlation, bivariate phylogenetic q=2 mean-mean
#' correlation, block-diagonal bivariate phylogenetic `mu1`/`mu2` and
#' `sigma1`/`sigma2` correlations, and constant residual-correlation targets.
#' For predictor-dependent scale, residual-correlation, or currently supported
#' `corpair()` formulae, supply `newdata` with `parm = "sigma"`,
#' `parm = "rho12"`, or the fitted `corpair(...)` dpar to profile the fitted
#' response-scale value for each supplied row.
#'
#' Target names follow the profile target namespace. For fixed effects, use
#' names such as `"fixef:mu:x"`, `"fixef:sigma:(Intercept)"`, or
#' `"fixef:rho12:w"`. Compact coefficient labels from `summary(fit)`, such as
#' `"mu:x"`, are also accepted. Random-effect SD intervals are reported on the
#' SD scale, and random-effect correlation intervals are reported on the
#' correlation scale. For bivariate Gaussian fits with constant residual
#' correlation, `parm = "rho12"` profiles the residual correlation and reports
#' the interval on the response correlation scale. For fits with constant
#' `sigma`, `sigma1`, or `sigma2`, `parm = "sigma"` and friends report
#' response-scale intervals.
#'
#' The fastest routine route is `confint(fit)`, which uses Wald intervals for
#' fixed effects and direct response-scale targets. For long phylogenetic,
#' spatial, animal-model, or relatedness fits, profile only the needed
#' variance-component or correlation rows with the default
#' `profile_engine = "auto"` first; direct scalar scale, SD, and correlation
#' targets use the endpoint engine when no full-profile controls are supplied.
#' Use `profile_engine = "tmbprofile"` or `profile_precision = "fast"` when you
#' want the previous full-curve `TMB::tmbprofile()` route for comparison,
#' diagnostics, or control tuning.
#'
#' @param object A `drmTMB` fit.
#' @param parm Optional character or integer vector selecting interval targets.
#'   `NULL` selects all direct Wald-ready targets for Wald intervals. Profile
#'   intervals require explicit target names or target-set shortcuts. Supported
#'   shortcuts are `"fixed_effects"`, `"random_effects"`,
#'   `"variance_components"`, and `"correlations"`.
#' @param level Confidence level.
#' @param method Interval method: `"wald"`, `"profile"`, or `"bootstrap"`. If
#'   `newdata` is supplied and `method` is omitted, `method = "profile"` is
#'   used.
#' @param newdata Optional data frame for response-scale profile intervals for
#'   predictor-dependent `sigma`, `sigma1`, `sigma2`, `rho12`, or fitted
#'   `corpair()` values. Each row is profiled separately by profiling its
#'   fixed-effect linear predictor and then transforming the interval to the
#'   response scale.
#' @param trace Logical; passed to [TMB::tmbprofile()] when the `tmbprofile`
#'   profile engine is used.
#' @param profile_precision Profile-control shortcut. `"default"` leaves
#'   [TMB::tmbprofile()] controls unchanged. `"fast"` supplies
#'   `ystep = 0.5` and `ytol = 2` unless the caller supplies those controls in
#'   `...`, giving a quicker first-pass profile for long variance-component or
#'   correlation targets.
#' @param profile_maxit Optional positive whole number passed to
#'   [TMB::tmbprofile()] as `maxit` when `method = "profile"`. Use this as a
#'   per-target adaptive-step budget for long or exploratory profile runs.
#' @param profile_engine Profile engine for direct fitted-object targets.
#'   `"auto"` uses a scalar endpoint solver for direct scale, SD, and
#'   correlation targets when no [TMB::tmbprofile()] controls are supplied, and
#'   otherwise uses [TMB::tmbprofile()]. `"endpoint"` requires the scalar
#'   endpoint solver, while `"tmbprofile"` preserves the previous full-profile
#'   route for comparison and debugging.
#' @param R Number of parametric-bootstrap refits when
#'   `method = "bootstrap"`.
#' @param seed Optional seed for bootstrap simulation.
#' @param parallel Profile or bootstrap backend: `"none"` or Unix
#'   `"multicore"`. For profile intervals, targets or `newdata` rows are split
#'   across workers. For bootstrap intervals, refits are split across workers.
#' @param workers Requested profile or bootstrap workers. If `NULL` and
#'   `parallel = "multicore"`, `drmTMB` uses about half the detected CPU cores.
#'   Multicore execution is capped at the number of jobs and at 10 workers.
#' @param refit_control Optional [drm_control()] object used for bootstrap
#'   refits. The default skips `TMB::sdreport()` and drops the TMB object because
#'   bootstrap intervals use refit point estimates.
#' @param ... Additional arguments passed to [TMB::tmbprofile()] when
#'   `method = "profile"` and the `tmbprofile` profile engine is used.
#'   `drmTMB` supplies the profiled `obj`, `name`, `lincomb`, and `trace`
#'   arguments internally; set the profile target with `parm`.
#'
#' @return A data frame with columns `parm`, `level`, `lower`, `upper`,
#'   `scale`, `transformation`, `tmb_parameter`, `index`, `method`, and
#'   `profile.engine`, `conf.status`, `profile.boundary`, and
#'   `profile.message`. Successful rows currently use
#'   `conf.status = "wald"`, `"profile"`, or `"bootstrap"`; profile rows mark
#'   intervals that land near a lower SD boundary or correlation boundary.
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
#' confint(fit)
#' confint(fit, parm = "variance_components")
#' confint(fit, parm = "sigma", method = "profile")
#' # Use the full-profile engine when you need the older tmbprofile route:
#' # confint(fit, parm = "sigma", method = "profile",
#' #   profile_engine = "tmbprofile", profile_precision = "fast")
#' # Direct-target parametric bootstrap is available when refit cost is worth it:
#' # confint(fit, parm = "sigma", method = "bootstrap", R = 99)
#' # Bootstrap intervals for positive scale and SD targets use link-scale
#' # percentiles before back-transforming to the response scale.
#' @export
confint.drmTMB <- function(
  object,
  parm = NULL,
  level = 0.95,
  method = c("wald", "profile", "bootstrap"),
  newdata = NULL,
  trace = FALSE,
  profile_precision = c("default", "fast"),
  profile_maxit = NULL,
  profile_engine = c("auto", "endpoint", "tmbprofile"),
  R = 199L,
  seed = NULL,
  parallel = c("none", "multicore"),
  workers = NULL,
  refit_control = NULL,
  ...
) {
  profile_precision_missing <- missing(profile_precision)
  parallel_missing <- missing(parallel)
  method_missing <- missing(method)
  profile_engine <- match.arg(profile_engine)
  method <- validate_interval_method(
    method,
    c("wald", "profile", "bootstrap"),
    "confint()"
  )
  if (!is.null(newdata) && method_missing) {
    method <- "profile"
  }
  validate_profile_level(level)
  profile_precision <- resolve_profile_precision(
    profile_precision,
    missing_arg = profile_precision_missing
  )
  profile_maxit <- validate_profile_maxit(profile_maxit)
  parallel <- resolve_bootstrap_parallel(
    parallel,
    missing_arg = parallel_missing
  )
  profile_dots <- list(...)

  if (identical(method, "wald")) {
    if (!is.null(newdata)) {
      cli::cli_abort(
        "{.arg newdata} is only used when {.code method = \"profile\"}."
      )
    }
    if (length(profile_dots) > 0L) {
      cli::cli_abort(
        "Additional arguments in {.arg ...} are only used when {.code method = \"profile\"}."
      )
    }
    return(drm_wald_confint(object, parm = parm, level = level))
  }

  if (identical(method, "bootstrap")) {
    bootstrap_parallel <- parallel
    if (!is.null(newdata)) {
      cli::cli_abort(
        "{.arg newdata} is not used when {.code method = \"bootstrap\"}."
      )
    }
    if (length(profile_dots) > 0L) {
      cli::cli_abort(
        "Additional arguments in {.arg ...} are only used when {.code method = \"profile\"}."
      )
    }
    all_targets <- drm_profile_targets(object)
    targets <- profile_match_bootstrap_targets(all_targets, parm)
    return(drm_bootstrap_confint(
      object,
      targets = targets,
      level = level,
      R = R,
      seed = seed,
      parallel = bootstrap_parallel,
      workers = workers,
      refit_control = refit_control
    ))
  }

  if (!is.null(newdata)) {
    if (identical(profile_engine, "endpoint")) {
      cli::cli_abort(c(
        "{.code profile_engine = \"endpoint\"} is only available for direct fitted-object scalar targets.",
        i = "Use {.code profile_engine = \"tmbprofile\"} or {.code profile_engine = \"auto\"} for row-specific {.arg newdata} profiles."
      ))
    }
    profile_args <- profile_precision_args(
      profile_precision,
      profile_dots,
      profile_maxit = profile_maxit
    )
    return(do.call(
      drm_profile_response_newdata_confint,
      c(
        list(
          object = object,
          parm = parm,
          newdata = newdata,
          level = level,
          trace = trace,
          parallel = parallel,
          workers = workers
        ),
        profile_args
      )
    ))
  }

  if (is.null(parm)) {
    cli::cli_abort(c(
      "Profile confidence intervals currently require explicit target names.",
      i = "Use names such as {.val fixef:mu:x} or compact labels such as {.val mu:x}."
    ))
  }

  targets <- profile_match_confint_targets(
    drm_profile_targets(object),
    parm,
    fixed_only = FALSE
  )
  tmbprofile_controls <- profile_tmbprofile_controls_requested(
    profile_precision_missing = profile_precision_missing,
    profile_maxit = profile_maxit,
    dots = profile_dots
  )
  if (identical(profile_engine, "endpoint") && tmbprofile_controls) {
    cli::cli_abort(c(
      "{.code profile_engine = \"endpoint\"} does not use {.fun TMB::tmbprofile} controls.",
      i = "Remove {.arg profile_precision}, {.arg profile_maxit}, and {.arg ...}, or use {.code profile_engine = \"tmbprofile\"}."
    ))
  }
  if (identical(profile_engine, "auto") && tmbprofile_controls) {
    profile_engine <- "tmbprofile"
  }
  profile_args <- profile_precision_args(
    profile_precision,
    profile_dots,
    profile_maxit = profile_maxit
  )
  do.call(
    drm_profile_confint,
    c(
      list(
        object = object,
        parm = targets$parm,
        level = level,
        trace = trace,
        parallel = parallel,
        workers = workers,
        profile_engine = profile_engine
      ),
      profile_args
    )
  )
}

#' List confidence-interval targets for a fitted model
#'
#' `profile_targets()` shows the names that can be supplied to
#' [confint.drmTMB()]. The table also records whether each row is currently
#' ready for direct profile-likelihood intervals. This helps users inspect the
#' fitted object before starting an expensive profile. Full q4 unstructured
#' correlation summaries are derived targets; block-diagonal phylogenetic q4
#' fallback correlations are direct targets, but a direct target can still fail
#' on a weak, boundary-limited, or one-sided profile.
#'
#' Use `ready_only = TRUE` for the fastest inspection path before calling
#' `confint(..., method = "profile")`. Use the `target_class` column to filter
#' fixed effects, random-effect SDs, residual correlations, and other
#' variance-component rows before a long profile run.
#'
#' @param object A `drmTMB` fit.
#' @param ready_only Logical; if `TRUE`, return only targets whose
#'   `profile_ready` column is `TRUE`.
#'
#' @return A data frame with columns `parm`, `target_class`, `dpar`, `term`,
#'   `tmb_parameter`, `index`, `estimate`, `link_estimate`, `scale`,
#'   `transformation`, `target_type`, `profile_ready`, and `profile_note`.
#'   `target_type` is either `"direct"` for a target that maps to a single
#'   fitted TMB parameter or `"derived"` for a target that is reported from a
#'   transformed or multi-parameter quantity. `profile_ready = TRUE` means the
#'   target is direct and the fitted object retained the TMB object needed for
#'   [confint.drmTMB()] with `method = "profile"`. Common `profile_note`
#'   values are `"ready"`, `"tmb_object_required"`, `"missing_tmb_parameter"`,
#'   `"derived_target"`, and `"derived_unstructured_correlation"`.
#'   Derived variance-ratio summaries such as repeatability and phylogenetic
#'   signal are listed as point-estimate targets with
#'   `profile_ready = FALSE`.
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
#' profile_targets(fit)
#' profile_targets(fit, ready_only = TRUE)
#' @export
profile_targets <- function(object, ready_only = FALSE) {
  if (!inherits(object, "drmTMB") && !inherits(object, "drmTMB_julia")) {
    cli::cli_abort("{.arg object} must be a {.cls drmTMB} fit.")
  }
  if (
    !is.logical(ready_only) ||
      length(ready_only) != 1L ||
      is.na(ready_only)
  ) {
    cli::cli_abort(
      "{.arg ready_only} must be a single {.code TRUE} or {.code FALSE}."
    )
  }

  targets <- drm_profile_targets(object)
  if (ready_only) {
    targets <- targets[targets$profile_ready, , drop = FALSE]
  }
  row.names(targets) <- NULL
  targets
}

#' Compute profile-likelihood curves for fitted model targets
#'
#' `profile()` computes and returns the full likelihood-profile curve for one
#' or more direct [profile_targets()]. It is a diagnostic companion to
#' [confint.drmTMB()]. Use [confint.drmTMB()] for interval tables, especially
#' with the fast endpoint engine; use `profile()` followed by `plot()` when you
#' need to see whether a target has a peaked, flat, one-sided, or boundary-like
#' likelihood shape.
#'
#' The returned x-axis values are transformed to the same scale shown by
#' [profile_targets()]. For example, SD and scale targets are shown on their
#' public positive scale, and correlation targets are shown on the correlation
#' scale. The y-axis diagnostic is likelihood-ratio distance,
#' `2 * (profile_nll - min(profile_nll))`, so a flatter curve indicates weaker
#' likelihood support around the fitted value.
#'
#' @param fitted A `drmTMB` fit.
#' @param parm Character or integer vector selecting direct profile targets.
#'   Use [profile_targets()] to inspect available names. Unlike
#'   [confint.drmTMB()], this helper always uses the full
#'   [TMB::tmbprofile()] curve because the curve itself is the diagnostic.
#' @param level Confidence level used for the likelihood-ratio cutoff and
#'   interval endpoint annotations.
#' @param trace Logical; passed to [TMB::tmbprofile()].
#' @param profile_precision Profile-control shortcut. `"default"` leaves
#'   [TMB::tmbprofile()] controls unchanged. `"fast"` supplies
#'   `ystep = 0.5` and `ytol = 2` unless the caller supplies those controls in
#'   `...`.
#' @param profile_maxit Optional positive whole number passed to
#'   [TMB::tmbprofile()] as `maxit`.
#' @param compare Logical; if `TRUE`, run a coarse first-pass profile and then
#'   the requested profile controls so the returned object can compare curve
#'   shape and elapsed time.
#' @param first_pass_ystep,first_pass_ytol Coarse [TMB::tmbprofile()] controls
#'   used only when `compare = TRUE`. The dense pass uses `profile_precision`,
#'   `profile_maxit`, and `...`.
#' @param ... Additional arguments passed to [TMB::tmbprofile()]. `drmTMB`
#'   supplies the profiled `obj`, `name`, `lincomb`, and `trace` arguments
#'   internally; set the profile target with `parm`.
#'
#' @return A data frame with class `"profile.drmTMB"`. The main columns are
#'   `parm`, `profile_value`, `profile_value_link`, `objective`,
#'   `delta_objective`, `delta_deviance`, `estimate`, `profile_pass`,
#'   `elapsed`, `profile_source`, `conf.low`, `conf.high`, `conf.status`, and
#'   `profile.message`.
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
#' prof <- profile(fit, parm = "sigma", profile_precision = "fast")
#' head(prof)
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   plot(prof)
#' }
#' @export
profile.drmTMB <- function(
  fitted,
  parm,
  level = 0.95,
  trace = FALSE,
  profile_precision = c("default", "fast"),
  profile_maxit = NULL,
  compare = FALSE,
  first_pass_ystep = 0.5,
  first_pass_ytol = 2,
  ...
) {
  if (!inherits(fitted, "drmTMB")) {
    cli::cli_abort("{.arg fitted} must be a {.cls drmTMB} fit.")
  }
  if (missing(parm) || is.null(parm)) {
    cli::cli_abort(c(
      "{.arg parm} is required for profile-likelihood curves.",
      i = "Use {.fn profile_targets} to inspect available direct target names."
    ))
  }
  if (is.null(fitted$obj)) {
    cli::cli_abort(c(
      "Profile-likelihood curves require the TMB object retained in {.code fit$obj}.",
      i = "Refit with {.code drm_control(keep_tmb_object = TRUE)} before using {.fn profile}."
    ))
  }
  validate_profile_level(level)
  profile_precision <- resolve_profile_precision(
    profile_precision,
    missing_arg = missing(profile_precision)
  )
  profile_maxit <- validate_profile_maxit(profile_maxit)
  profile_args <- profile_precision_args(
    profile_precision,
    list(...),
    profile_maxit = profile_maxit
  )
  profile_check_tmbprofile_dots_list(profile_args)
  compare <- validate_profile_plot_flag(compare, "compare")
  first_pass_args <- profile_first_pass_args(
    profile_args,
    ystep = first_pass_ystep,
    ytol = first_pass_ytol
  )

  targets <- profile_match_targets(drm_profile_targets(fitted), parm)
  rows <- lapply(seq_len(nrow(targets)), function(i) {
    target <- targets[i, , drop = FALSE]
    if (isTRUE(compare)) {
      return(rbind(
        do.call(
          drm_profile_curve,
          c(
            list(
              object = fitted,
              target = target,
              level = level,
              trace = trace,
              profile_pass = "coarse",
              profile_controls = profile_controls_label(first_pass_args)
            ),
            first_pass_args
          )
        ),
        do.call(
          drm_profile_curve,
          c(
            list(
              object = fitted,
              target = target,
              level = level,
              trace = trace,
              profile_pass = "dense",
              profile_controls = profile_controls_label(profile_args)
            ),
            profile_args
          )
        )
      ))
    }
    do.call(
      drm_profile_curve,
      c(
        list(
          object = fitted,
          target = target,
          level = level,
          trace = trace,
          profile_pass = "profile",
          profile_controls = profile_controls_label(profile_args)
        ),
        profile_args
      )
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  attr(out, "level") <- level
  class(out) <- c("profile.drmTMB", class(out))
  out
}

#' Plot profile-likelihood curves
#'
#' `plot()` for `"profile.drmTMB"` objects draws the likelihood-ratio curve
#' returned by [profile.drmTMB()]. The dotted horizontal line is the
#' likelihood-ratio cutoff for the stored confidence level, the solid vertical
#' line marks the fitted estimate, and dashed vertical lines mark profile
#' interval endpoints when they were extracted successfully. When the profile
#' object contains coarse and dense passes, colour and line type separate the
#' passes and the caption reports elapsed time for each.
#'
#' @param x A `"profile.drmTMB"` object returned by [profile.drmTMB()].
#' @param interval Logical; draw profile interval endpoint lines when finite
#'   `conf.low` and `conf.high` columns are available.
#' @param ... Reserved for future options.
#'
#' @return A `ggplot` object.
#' @export
plot.profile.drmTMB <- function(x, interval = TRUE, ...) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved for future options.")
  }
  plot_profile_require_ggplot2()
  validate_profile_plot_data(x)
  interval <- validate_profile_plot_flag(interval, "interval")

  level <- unique(x$level)
  if (length(level) != 1L || !is.finite(level)) {
    cli::cli_abort(
      "{.arg x} must contain one finite confidence level in column {.val level}."
    )
  }
  cutoff <- stats::qchisq(level, df = 1)
  estimates <- unique(x[c("parm", "estimate")])
  intervals <- unique(x[c("parm", "conf.low", "conf.high", "conf.status")])
  intervals <- intervals[
    is.finite(intervals$conf.low) &
      is.finite(intervals$conf.high) &
      intervals$conf.status == "profile",
    ,
    drop = FALSE
  ]

  data <- x
  data$.drmTMB_profile_parm <- data$parm
  estimates$.drmTMB_profile_parm <- estimates$parm
  intervals$.drmTMB_profile_parm <- intervals$parm
  has_pass_comparison <- length(unique(data$profile_pass)) > 1L

  mapping <- if (has_pass_comparison) {
    ggplot2::aes(
      x = .data[["profile_value"]],
      y = .data[["delta_deviance"]],
      colour = .data[["profile_pass"]],
      linetype = .data[["profile_pass"]]
    )
  } else {
    ggplot2::aes(
      x = .data[["profile_value"]],
      y = .data[["delta_deviance"]]
    )
  }

  out <- ggplot2::ggplot(data, mapping) +
    ggplot2::geom_hline(
      yintercept = cutoff,
      linetype = "dotted",
      colour = "grey55",
      linewidth = 0.35
    ) +
    ggplot2::geom_vline(
      data = estimates,
      mapping = ggplot2::aes(xintercept = .data[["estimate"]]),
      inherit.aes = FALSE,
      linewidth = 0.35,
      colour = "grey30"
    )
  if (isTRUE(interval) && nrow(intervals) > 0L) {
    out <- out +
      ggplot2::geom_vline(
        data = intervals,
        mapping = ggplot2::aes(xintercept = .data[["conf.low"]]),
        inherit.aes = FALSE,
        linetype = "dashed",
        linewidth = 0.3,
        colour = "grey45"
      ) +
      ggplot2::geom_vline(
        data = intervals,
        mapping = ggplot2::aes(xintercept = .data[["conf.high"]]),
        inherit.aes = FALSE,
        linetype = "dashed",
        linewidth = 0.3,
        colour = "grey45"
      )
  }
  line_args <- list(linewidth = 0.8, na.rm = TRUE)
  point_args <- list(
    size = 1.8,
    shape = 21,
    fill = "white",
    stroke = 0.6,
    na.rm = TRUE
  )
  if (!has_pass_comparison) {
    line_args$colour <- "#0072B2"
    point_args$colour <- "#0072B2"
  }
  out <- out +
    do.call(ggplot2::geom_line, line_args) +
    do.call(ggplot2::geom_point, point_args)
  if (has_pass_comparison) {
    out <- out +
      ggplot2::scale_colour_manual(
        values = c(coarse = "grey45", dense = "#0072B2", profile = "#0072B2"),
        breaks = unique(data$profile_pass)
      ) +
      ggplot2::scale_linetype_manual(
        values = c(coarse = "dashed", dense = "solid", profile = "solid"),
        breaks = unique(data$profile_pass)
      )
  }
  if (length(unique(data$parm)) > 1L) {
    out <- out +
      ggplot2::facet_wrap(~.drmTMB_profile_parm, scales = "free_x")
  }
  labels <- list(
    x = "Profiled target value",
    y = "Likelihood-ratio distance",
    caption = profile_plot_caption(data)
  )
  if (has_pass_comparison) {
    labels$colour <- "Profile pass"
    labels$linetype <- "Profile pass"
  }
  out + do.call(ggplot2::labs, labels)
}

utils::globalVariables(".data")

drm_profile_curve <- function(
  object,
  target,
  level,
  trace,
  profile_pass,
  profile_controls,
  ...
) {
  implemented_classes <- c(
    "fixed-effect",
    "distributional-scale",
    "random-effect-sd",
    "random-effect-correlation",
    "residual-correlation"
  )
  if (!isTRUE(target$profile_ready)) {
    cli::cli_abort(c(
      "Profile target {.val {target$parm}} is not ready for direct profiling.",
      i = "Inventory note: {.val {target$profile_note}}."
    ))
  }
  if (!target$target_class %in% implemented_classes) {
    cli::cli_abort(c(
      "Profile-likelihood curves are implemented for direct fixed-effect, constant distributional-scale, random-effect SD, random-effect correlation, and constant residual-correlation targets.",
      i = "Requested {.val {target$parm}} has target class {.val {target$target_class}}."
    ))
  }

  lincomb <- profile_lincomb(object, target)
  elapsed <- system.time({
    prof <- drm_tmbprofile(
      object = object,
      target_name = target$parm,
      lincomb = lincomb,
      trace = trace,
      ...
    )
  })[["elapsed"]]
  profile_data <- as.data.frame(prof)
  value_column <- setdiff(names(profile_data), "value")
  if (length(value_column) != 1L) {
    cli::cli_abort(
      "Internal error: profile curve must contain one profiled-value column."
    )
  }
  profile_value_link <- profile_data[[value_column]]
  objective <- profile_data$value
  delta_objective <- objective - min(objective, na.rm = TRUE)
  ci <- tryCatch(
    drm_tmbprofile_confint(prof, target_name = target$parm, level = level),
    error = function(err) err
  )
  interval <- c(NA_real_, NA_real_)
  conf_status <- "profile_interval_unavailable"
  profile_message <- "interval_unavailable"
  if (!inherits(ci, "error")) {
    interval <- profile_transform_interval(
      c(unname(ci[1L, "lower"]), unname(ci[1L, "upper"])),
      target
    )
    conf_status <- "profile"
    profile_message <- "ok"
  } else {
    profile_message <- conditionMessage(ci)
  }

  data.frame(
    parm = target$parm,
    target_class = target$target_class,
    dpar = target$dpar,
    term = target$term,
    level = level,
    profile_value = profile_transform_values(profile_value_link, target),
    profile_value_link = profile_value_link,
    objective = objective,
    delta_objective = delta_objective,
    delta_deviance = 2 * delta_objective,
    estimate = target$estimate,
    link_estimate = target$link_estimate,
    profile_pass = profile_pass,
    elapsed = unname(elapsed),
    profile_controls = profile_controls,
    profile_source = "TMB::tmbprofile via stats::profile.drmTMB",
    conf.low = interval[[1L]],
    conf.high = interval[[2L]],
    conf.status = conf_status,
    profile.message = profile_message,
    scale = target$scale,
    transformation = target$transformation,
    tmb_parameter = target$tmb_parameter,
    index = target$index,
    stringsAsFactors = FALSE
  )
}

profile_first_pass_args <- function(profile_args, ystep, ytol) {
  if (
    !is.numeric(ystep) ||
      length(ystep) != 1L ||
      !is.finite(ystep) ||
      ystep <= 0
  ) {
    cli::cli_abort("{.arg first_pass_ystep} must be one positive number.")
  }
  if (
    !is.numeric(ytol) ||
      length(ytol) != 1L ||
      !is.finite(ytol) ||
      ytol <= 0
  ) {
    cli::cli_abort("{.arg first_pass_ytol} must be one positive number.")
  }
  out <- profile_args
  out$ystep <- ystep
  out$ytol <- ytol
  out$maxit <- NULL
  out
}

profile_controls_label <- function(args) {
  if (length(args) == 0L) {
    return("TMB defaults")
  }
  paste(
    vapply(
      names(args),
      function(name) {
        value <- args[[name]]
        if (length(value) > 4L) {
          value <- c(value[seq_len(4L)], "...")
        }
        paste0(name, "=", paste(value, collapse = "/"))
      },
      character(1)
    ),
    collapse = ", "
  )
}

profile_transform_values <- function(values, target) {
  switch(
    target$transformation,
    linear_predictor = values,
    ordered_cutpoint = values,
    exp = exp(values),
    tanh = 0.999999 * tanh(values),
    rho12_tanh = rho_response(values),
    values
  )
}

profile_plot_caption <- function(data) {
  source <- unique(data$profile_source)
  if (length(source) != 1L) {
    source <- "TMB::tmbprofile"
  }
  elapsed <- unique(data[c("profile_pass", "elapsed", "profile_controls")])
  elapsed <- elapsed[
    order(match(
      elapsed$profile_pass,
      c("coarse", "dense", "profile")
    )),
  ]
  elapsed_text <- paste(
    sprintf(
      "%s %.2fs (%s)",
      elapsed$profile_pass,
      elapsed$elapsed,
      elapsed$profile_controls
    ),
    collapse = "; "
  )
  paste0("Source: ", source, ". Elapsed: ", elapsed_text, ".")
}

plot_profile_require_ggplot2 <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.fn plot.profile.drmTMB} requires the {.pkg ggplot2} package.",
      i = "Install it with {.code install.packages(\"ggplot2\")}."
    ))
  }
  invisible(TRUE)
}

validate_profile_plot_data <- function(data) {
  if (!inherits(data, "profile.drmTMB") || !is.data.frame(data)) {
    cli::cli_abort(
      "{.arg x} must be a {.cls profile.drmTMB} object returned by {.fn profile}."
    )
  }
  required <- c(
    "parm",
    "level",
    "profile_value",
    "delta_deviance",
    "estimate",
    "conf.low",
    "conf.high",
    "conf.status"
  )
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    cli::cli_abort(
      "{.arg x} is missing profile column{?s}: {.val {missing}}."
    )
  }
  numeric_columns <- c(
    "level",
    "profile_value",
    "delta_deviance",
    "estimate",
    "conf.low",
    "conf.high"
  )
  bad_numeric <- numeric_columns[
    !vapply(
      data[numeric_columns],
      is.numeric,
      logical(1)
    )
  ]
  if (length(bad_numeric) > 0L) {
    cli::cli_abort(
      "{.arg x} profile column{?s} must be numeric: {.val {bad_numeric}}."
    )
  }
  invisible(data)
}

validate_profile_plot_flag <- function(x, argument) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort(
      "{.arg {argument}} must be a single {.code TRUE} or {.code FALSE}."
    )
  }
  x
}

validate_interval_method <- function(method, choices, caller) {
  if (
    !is.character(method) ||
      length(method) < 1L ||
      anyNA(method) ||
      !all(nzchar(method))
  ) {
    cli::cli_abort("{.arg method} must be a non-missing character value.")
  }
  if (length(method) > 1L) {
    if (all(method %in% choices)) {
      return(choices[[1L]])
    }
    cli::cli_abort("{.arg method} must be a single character value.")
  }

  if (
    method %in% c("bootstrap", "parametric_bootstrap") && !method %in% choices
  ) {
    cli::cli_abort(c(
      "{.arg method} = {.val {method}} is not implemented for {.fn {caller}} intervals yet.",
      i = "Current interval methods are {.val {choices}}.",
      i = "Use {.code method = \"profile\"} for direct profile-ready targets, or keep bootstrap intervals as a separate simulation/audit step."
    ))
  }

  matched <- pmatch(method, choices, duplicates.ok = FALSE)
  if (is.na(matched)) {
    cli::cli_abort(
      "{.arg method} must be one of {.val {choices}}."
    )
  }
  choices[[matched]]
}

resolve_profile_precision <- function(profile_precision, missing_arg = FALSE) {
  if (isTRUE(missing_arg)) {
    return("default")
  }
  match.arg(profile_precision, c("default", "fast"))
}

resolve_bootstrap_parallel <- function(parallel, missing_arg = FALSE) {
  if (isTRUE(missing_arg)) {
    return("none")
  }
  match.arg(parallel, c("none", "multicore"))
}

validate_profile_maxit <- function(profile_maxit) {
  if (is.null(profile_maxit)) {
    return(NULL)
  }
  if (
    !is.numeric(profile_maxit) ||
      length(profile_maxit) != 1L ||
      is.na(profile_maxit) ||
      !is.finite(profile_maxit) ||
      profile_maxit < 1L ||
      profile_maxit != as.integer(profile_maxit)
  ) {
    cli::cli_abort(
      "{.arg profile_maxit} must be {.code NULL} or a positive whole number."
    )
  }
  as.integer(profile_maxit)
}

profile_tmbprofile_controls_requested <- function(
  profile_precision_missing,
  profile_maxit,
  dots
) {
  !isTRUE(profile_precision_missing) ||
    !is.null(profile_maxit) ||
    length(dots) > 0L
}

profile_precision_args <- function(
  profile_precision = "default",
  dots,
  profile_maxit = NULL
) {
  profile_precision <- match.arg(profile_precision, c("default", "fast"))
  profile_check_tmbprofile_dots_list(dots)
  if (!is.null(profile_maxit)) {
    if ("maxit" %in% names(dots)) {
      cli::cli_abort(c(
        "Profile step budget was supplied twice.",
        x = "Use either {.arg profile_maxit} or {.arg maxit} in {.arg ...}, not both."
      ))
    }
    dots$maxit <- profile_maxit
  }
  if (identical(profile_precision, "default")) {
    return(dots)
  }
  if (!"ystep" %in% names(dots)) {
    dots$ystep <- 0.5
  }
  if (!"ytol" %in% names(dots)) {
    dots$ytol <- 2
  }
  dots
}

interval_status_levels <- function() {
  c(
    "wald",
    "profile",
    "bootstrap",
    "profile_ready",
    "newdata_required",
    "derived_interval_unavailable",
    "wald_unavailable",
    "bootstrap_unavailable",
    "target_unavailable",
    "profile_unavailable",
    "not_requested"
  )
}

interval_source_levels <- function() {
  c("wald", "profile", "bootstrap", "not_available")
}

drm_profile_targets <- function(object) {
  if (inherits(object, "drmTMB_julia")) {
    return(drm_julia_profile_targets(object))
  }

  rows <- list()
  counters <- new.env(parent = emptyenv())

  add_rows <- function(new_rows) {
    if (!length(new_rows)) {
      return(invisible(NULL))
    }
    rows <<- c(rows, new_rows)
    invisible(NULL)
  }

  next_indices <- function(internal, n) {
    if (is.na(internal) || n == 0L) {
      return(rep(NA_integer_, n))
    }
    current <- if (exists(internal, envir = counters, inherits = FALSE)) {
      get(internal, envir = counters, inherits = FALSE)
    } else {
      0L
    }
    out <- current + seq_len(n)
    assign(internal, current + n, envir = counters)
    out
  }

  for (dpar in names(object$coefficients)) {
    beta <- object$coefficients[[dpar]]
    internal <- profile_fixef_internal(dpar)
    indices <- next_indices(internal, length(beta))
    add_rows(lapply(seq_along(beta), function(i) {
      status <- profile_direct_target_status(
        object,
        internal,
        indices[[i]]
      )
      new_profile_target_row(
        parm = paste0("fixef:", dpar, ":", names(beta)[[i]]),
        target_class = "fixed-effect",
        dpar = dpar,
        term = names(beta)[[i]],
        tmb_parameter = internal,
        index = indices[[i]],
        estimate = unname(beta[[i]]),
        link_estimate = unname(beta[[i]]),
        scale = "link",
        transformation = "linear_predictor",
        target_type = "direct",
        profile_ready = status$profile_ready,
        profile_note = status$profile_note
      )
    }))
  }

  scale_dpars <- intersect(
    names(object$coefficients),
    c("sigma", "sigma1", "sigma2")
  )
  for (dpar in scale_dpars) {
    beta <- object$coefficients[[dpar]]
    if (
      length(beta) == 1L &&
        identical(names(beta), "(Intercept)") &&
        identical(drm_dpar_link(object, dpar), "log")
    ) {
      internal <- profile_fixef_internal(dpar)
      status <- profile_direct_target_status(object, internal, 1L)
      add_rows(list(new_profile_target_row(
        parm = dpar,
        target_class = "distributional-scale",
        dpar = dpar,
        term = "(constant)",
        tmb_parameter = internal,
        index = 1L,
        estimate = exp(unname(beta[[1L]])),
        link_estimate = unname(beta[[1L]]),
        scale = "response",
        transformation = "exp",
        target_type = "direct",
        profile_ready = status$profile_ready,
        profile_note = status$profile_note
      )))
    }
  }

  if ("rho12" %in% names(object$coefficients)) {
    beta <- object$coefficients$rho12
    if (length(beta) == 1L && identical(names(beta), "(Intercept)")) {
      status <- profile_direct_target_status(object, "beta_rho12", 1L)
      add_rows(list(new_profile_target_row(
        parm = "rho12",
        target_class = "residual-correlation",
        dpar = "rho12",
        term = "(constant)",
        tmb_parameter = "beta_rho12",
        index = 1L,
        estimate = rho_response(unname(beta[[1L]])),
        link_estimate = unname(beta[[1L]]),
        scale = "response",
        transformation = "rho12_tanh",
        target_type = "direct",
        profile_ready = status$profile_ready,
        profile_note = status$profile_note
      )))
    }
  }

  for (dpar in names(object$sdpars)) {
    values <- object$sdpars[[dpar]]
    for (i in seq_along(values)) {
      term <- names(values)[[i]]
      internal <- profile_sd_internal(object, dpar, term)
      is_direct <- !is.na(internal)
      index <- if (is_direct) {
        next_indices(internal, 1L)
      } else {
        NA_integer_
      }
      status <- if (is_direct) {
        profile_direct_target_status(object, internal, index)
      } else {
        list(profile_ready = FALSE, profile_note = "derived_target")
      }
      add_rows(list(new_profile_target_row(
        parm = paste0("sd:", dpar, ":", term),
        target_class = "random-effect-sd",
        dpar = dpar,
        term = term,
        tmb_parameter = internal,
        index = index,
        estimate = unname(values[[i]]),
        link_estimate = log(unname(values[[i]])),
        scale = "response",
        transformation = if (is_direct) "exp" else "derived_group_scale",
        target_type = if (is_direct) "direct" else "derived",
        profile_ready = status$profile_ready,
        profile_note = status$profile_note
      )))
    }
  }

  registry_cor_rows <- profile_registry_cor_targets(object)
  add_rows(registry_cor_rows)
  add_rows(profile_derived_summary_targets(object))
  registry_cor_keys <- covariance_block_corpars_keys(
    object$model$random$covariance_blocks
  )
  for (dpar in names(object$corpars)) {
    values <- object$corpars[[dpar]]
    internal <- profile_cor_internal(dpar)
    is_structured_qgt2 <- dpar %in%
      c("phylo", "spatial", "animal", "relmat") &&
      isTRUE(object$model$structured$phylo_mu$has) &&
      identical(
        dpar,
        structured_mu_correlation_key(
          object$model$structured$phylo_mu
        )
      ) &&
      isTRUE(object$model$structured$phylo_mu$q > 2L) &&
      !phylo_mu_is_block_diagonal(object$model$structured$phylo_mu)
    for (i in seq_along(values)) {
      if (paste(dpar, i, sep = ":") %in% registry_cor_keys) {
        next
      }
      if (random_effect_correlation_is_modelled(object, dpar, i)) {
        next
      }
      index <- i
      if (
        dpar %in%
          c("phylo", "spatial", "animal", "relmat") &&
          isTRUE(object$model$structured$phylo_mu$has) &&
          identical(
            dpar,
            structured_mu_correlation_key(
              object$model$structured$phylo_mu
            )
          ) &&
          isTRUE(object$model$structured$phylo_mu$q > 2L)
      ) {
        internal <- "theta_phylo"
      }
      if (is_structured_qgt2) {
        status <- list(
          profile_ready = FALSE,
          profile_note = "derived_unstructured_correlation"
        )
      } else {
        status <- profile_direct_target_status(
          object,
          internal,
          index
        )
      }
      add_rows(list(new_profile_target_row(
        parm = paste0("cor:", dpar, ":", names(values)[[i]]),
        target_class = "random-effect-correlation",
        dpar = dpar,
        term = names(values)[[i]],
        tmb_parameter = internal,
        index = index,
        estimate = unname(values[[i]]),
        link_estimate = if (is_structured_qgt2) {
          NA_real_
        } else {
          guarded_correlation_link(
            unname(values[[i]]),
            guard = 0.999999
          )
        },
        scale = "response",
        transformation = if (is_structured_qgt2) {
          "unstructured_corr"
        } else {
          "tanh"
        },
        target_type = if (is_structured_qgt2) "derived" else "direct",
        profile_ready = status$profile_ready,
        profile_note = status$profile_note
      )))
    }
  }

  if (!is.null(object$ordinal)) {
    theta <- object$ordinal$theta_raw
    internal <- "theta_ord"
    indices <- next_indices(internal, length(theta))
    add_rows(lapply(seq_along(theta), function(i) {
      status <- profile_direct_target_status(
        object,
        internal,
        indices[[i]]
      )
      new_profile_target_row(
        parm = paste0("ordinal:theta_ord:", names(theta)[[i]]),
        target_class = "ordinal-cutpoint-internal",
        dpar = "ordinal",
        term = names(theta)[[i]],
        tmb_parameter = internal,
        index = indices[[i]],
        estimate = unname(theta[[i]]),
        link_estimate = unname(theta[[i]]),
        scale = "internal",
        transformation = "ordered_cutpoint",
        target_type = "direct",
        profile_ready = status$profile_ready,
        profile_note = status$profile_note
      )
    }))
  }

  out <- if (length(rows)) {
    do.call(rbind, rows)
  } else {
    empty_profile_targets()
  }
  row.names(out) <- NULL
  validate_profile_targets(out)
}

drm_profile_confint <- function(
  object,
  parm,
  level = 0.95,
  trace = FALSE,
  parallel = "none",
  workers = NULL,
  profile_engine = c("tmbprofile", "auto", "endpoint"),
  ...
) {
  validate_profile_level(level)
  profile_engine <- match.arg(profile_engine)
  profile_check_tmbprofile_dots(...)
  if (is.null(object$obj)) {
    cli::cli_abort(c(
      "Profile confidence intervals require the TMB object retained in {.code fit$obj}.",
      i = "Refit with {.code drm_control(keep_tmb_object = TRUE)} before using {.code method = \"profile\"}."
    ))
  }
  targets <- profile_match_targets(drm_profile_targets(object), parm)
  endpoint_plan <- profile_endpoint_parallel_plan(
    targets = targets,
    parallel = parallel,
    workers = workers,
    profile_engine = profile_engine
  )
  plan <- if (identical(endpoint_plan$backend, "none")) {
    profile_parallel_plan(
      nrow(targets),
      parallel = parallel,
      workers = workers
    )
  } else {
    profile_serial_plan()
  }

  worker <- function(i) {
    drm_profile_target_confint(
      object = object,
      target = targets[i, , drop = FALSE],
      level = level,
      trace = trace,
      profile_engine = profile_engine,
      endpoint_plan = endpoint_plan,
      ...
    )
  }
  rows <- profile_lapply(seq_len(nrow(targets)), worker, plan)
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

profile_serial_plan <- function() {
  list(backend = "none", workers = 1L)
}

profile_endpoint_parallel_plan <- function(
  targets,
  parallel,
  workers,
  profile_engine
) {
  if (
    nrow(targets) != 1L ||
      identical(profile_engine, "tmbprofile") ||
      !profile_endpoint_target_supported(targets)
  ) {
    return(profile_serial_plan())
  }
  plan <- profile_parallel_plan(2L, parallel = parallel, workers = workers)
  if (identical(plan$backend, "none") || plan$workers < 2L) {
    return(profile_serial_plan())
  }
  plan
}

profile_derived_summary_targets <- function(object) {
  rows <- drm_derived_summary_rows(object)
  if (nrow(rows) == 0L) {
    return(list())
  }
  lapply(seq_len(nrow(rows)), function(i) {
    row <- rows[i, , drop = FALSE]
    new_profile_target_row(
      parm = row$parm[[1L]],
      target_class = "derived-summary",
      dpar = row$dpar[[1L]],
      term = row$term[[1L]],
      tmb_parameter = NA_character_,
      index = NA_integer_,
      estimate = row$estimate[[1L]],
      link_estimate = NA_real_,
      scale = "response",
      transformation = "variance_ratio",
      target_type = "derived",
      profile_ready = FALSE,
      profile_note = "derived_target"
    )
  })
}

drm_profile_response_newdata_confint <- function(
  object,
  parm,
  newdata,
  level = 0.95,
  trace = FALSE,
  parallel = "none",
  workers = NULL,
  ...
) {
  validate_profile_level(level)
  profile_check_tmbprofile_dots(...)
  if (is.null(object$obj)) {
    cli::cli_abort(c(
      "Profile confidence intervals require the TMB object retained in {.code fit$obj}.",
      i = "Refit with {.code drm_control(keep_tmb_object = TRUE)} before using {.code method = \"profile\"}."
    ))
  }
  dpar <- profile_newdata_dpar(object, parm)
  if (!is.data.frame(newdata)) {
    cli::cli_abort("{.arg newdata} must be a data frame.")
  }
  if (nrow(newdata) < 1L) {
    cli::cli_abort("{.arg newdata} must contain at least one row.")
  }

  X <- drm_prediction_matrix(object, newdata, dpar)
  beta <- object$coefficients[[dpar]]
  if (!identical(colnames(X), names(beta))) {
    cli::cli_abort(c(
      "Could not align {.arg newdata} with the fitted {.val {dpar}} formula.",
      i = "Check that factor levels and predictor columns match the fitted model."
    ))
  }
  offset <- drm_prediction_offset(object, newdata, dpar)
  if (length(offset) != nrow(X)) {
    cli::cli_abort(
      "Internal error: response-scale profile offsets do not match {.arg newdata} rows."
    )
  }

  internal <- profile_fixef_internal(dpar)
  par_names <- names(object$opt$par)
  positions <- which(par_names == internal)
  if (length(positions) < ncol(X)) {
    cli::cli_abort(c(
      "Profile target {.val {dpar}} cannot be mapped to optimized parameters.",
      i = "Expected {ncol(X)} coefficient{?s} in TMB parameter {.val {internal}}."
    ))
  }

  labels <- profile_newdata_parm_labels(dpar, newdata)
  plan <- profile_parallel_plan(nrow(X), parallel = parallel, workers = workers)
  worker <- function(i) {
    lincomb <- rep(0, length(object$opt$par))
    lincomb[positions[seq_len(ncol(X))]] <- as.numeric(X[i, ])
    prof <- drm_tmbprofile(
      object = object,
      target_name = labels[[i]],
      lincomb = lincomb,
      trace = trace,
      ...
    )
    ci <- drm_tmbprofile_confint(prof, target_name = labels[[i]], level = level)
    interval <- profile_transform_newdata_interval(
      c(unname(ci[1L, "lower"]), unname(ci[1L, "upper"])),
      object = object,
      dpar = dpar,
      offset = offset[[i]]
    )

    diagnostics <- profile_interval_diagnostics(
      interval,
      transformation = profile_newdata_transformation(object, dpar)
    )

    data.frame(
      parm = labels[[i]],
      level = level,
      lower = interval[[1L]],
      upper = interval[[2L]],
      scale = "response",
      transformation = profile_newdata_transformation(object, dpar),
      tmb_parameter = internal,
      index = NA_integer_,
      method = "profile",
      profile.engine = "tmbprofile",
      conf.status = "profile",
      profile.boundary = diagnostics$boundary,
      profile.message = diagnostics$message,
      stringsAsFactors = FALSE
    )
  }
  rows <- profile_lapply(seq_len(nrow(X)), worker, plan)
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

skew_normal_slant_targets <- function(object, targets) {
  if (!identical(object$model$model_type, "skew_normal")) {
    return(character())
  }
  targets$parm[targets$dpar == "nu"]
}

warn_skew_normal_slant_wald <- function(object, targets) {
  slant <- skew_normal_slant_targets(object, targets)
  if (length(slant) == 0L) {
    return(invisible(NULL))
  }
  cli::cli_warn(c(
    "!" = "{cli::qty(slant)}Wald confidence interval{?s} for the skew-normal slant ({.val {slant}}) {?is/are} miscalibrated near {.code nu = 0}, where the Azzalini information is near-singular.",
    "i" = "{cli::qty(slant)}Use {.code method = \"profile\"} (or {.code method = \"bootstrap\"}) for the slant interval{?s} instead."
  ))
  invisible(NULL)
}

drm_wald_confint <- function(object, parm, level) {
  targets <- drm_profile_targets(object)
  targets <- targets[wald_supported_targets(targets), , drop = FALSE]
  targets <- profile_match_confint_targets(
    targets,
    parm,
    fixed_only = FALSE
  )
  if (nrow(targets) == 0L) {
    return(empty_confint_table(method = "wald"))
  }
  warn_skew_normal_slant_wald(object, targets)

  z <- stats::qnorm((1 + level) / 2)
  variances <- rep(NA_real_, nrow(targets))
  hessian_ready <- isTRUE(object$sdr$pdHess)
  if (hessian_ready) {
    cov_fixed <- drm_sdreport_cov_fixed(object)
    positions <- profile_target_opt_positions(object, targets)
    in_covariance <- !is.na(positions) & positions <= nrow(cov_fixed)
    variances[in_covariance] <- cov_fixed[
      cbind(positions[in_covariance], positions[in_covariance])
    ]
  } else if (is.null(object$sdr)) {
    drm_sdreport_cov_fixed(object)
  }
  se <- profile_wald_standard_errors(variances)
  interval_ready <- hessian_ready &
    is.finite(targets$link_estimate) &
    is.finite(se)
  lower <- rep(NA_real_, nrow(targets))
  upper <- rep(NA_real_, nrow(targets))
  if (any(interval_ready)) {
    link_lower <- targets$link_estimate[interval_ready] -
      z * se[interval_ready]
    link_upper <- targets$link_estimate[interval_ready] +
      z * se[interval_ready]
    transformed <- mapply(
      function(lo, hi, row) {
        profile_transform_interval(c(lo, hi), targets[row, , drop = FALSE])
      },
      link_lower,
      link_upper,
      which(interval_ready),
      SIMPLIFY = FALSE
    )
    lower[interval_ready] <- vapply(transformed, `[[`, numeric(1L), 1L)
    upper[interval_ready] <- vapply(transformed, `[[`, numeric(1L), 2L)
  }

  out <- data.frame(
    parm = targets$parm,
    level = level,
    lower = lower,
    upper = upper,
    scale = targets$scale,
    transformation = targets$transformation,
    tmb_parameter = targets$tmb_parameter,
    index = targets$index,
    method = "wald",
    profile.engine = NA_character_,
    conf.status = ifelse(interval_ready, "wald", "wald_unavailable"),
    profile.boundary = NA,
    profile.message = NA_character_,
    stringsAsFactors = FALSE
  )
  row.names(out) <- NULL
  out
}

drm_bootstrap_confint <- function(
  object,
  targets,
  level,
  R,
  seed,
  parallel,
  workers,
  refit_control
) {
  validate_profile_level(level)
  R <- validate_bootstrap_replicates(R)
  plan <- bootstrap_parallel_plan(R, parallel = parallel, workers = workers)
  refit_control <- bootstrap_refit_control(refit_control)
  if (nrow(targets) == 0L) {
    return(empty_confint_table(method = "bootstrap"))
  }
  if (is.null(object$data)) {
    cli::cli_abort(c(
      "Bootstrap confidence intervals require the fitted model data.",
      i = "Refit with {.code drm_control(keep_data = TRUE)} before using {.code method = \"bootstrap\"}."
    ))
  }

  simulations <- stats::simulate(object, nsim = R, seed = seed)
  target_names <- targets$parm
  worker <- function(index) {
    bootstrap_refit_one(
      object = object,
      simulations = simulations,
      index = index,
      target_names = target_names,
      refit_control = refit_control
    )
  }
  rows <- bootstrap_lapply(seq_len(R), worker, plan)
  draws <- do.call(rbind, rows)
  row.names(draws) <- NULL

  probs <- c((1 - level) / 2, (1 + level) / 2)
  intervals <- lapply(seq_len(nrow(targets)), function(i) {
    target <- targets[i, , drop = FALSE]
    target_draws <- draws[draws$parm == target$parm, , drop = FALSE]
    draw_values <- bootstrap_percentile_draws(target_draws, target)
    finite <- is.finite(draw_values) & target_draws$refit_ok
    n_ok <- sum(finite)
    failed <- nrow(target_draws) - n_ok
    if (n_ok < 2L) {
      lower <- NA_real_
      upper <- NA_real_
      status <- "bootstrap_unavailable"
      message <- "fewer than two successful bootstrap refits"
    } else {
      qs <- bootstrap_percentile_interval(
        target_draws = target_draws[finite, , drop = FALSE],
        target = target,
        probs = probs
      )
      lower <- qs[[1L]]
      upper <- qs[[2L]]
      status <- "bootstrap"
      message <- paste0(n_ok, "/", nrow(target_draws), " successful refits")
    }
    data.frame(
      parm = target$parm,
      level = level,
      lower = lower,
      upper = upper,
      scale = target$scale,
      transformation = target$transformation,
      tmb_parameter = target$tmb_parameter,
      index = target$index,
      method = "bootstrap",
      profile.engine = NA_character_,
      conf.status = status,
      profile.boundary = NA,
      profile.message = message,
      bootstrap.n = n_ok,
      bootstrap.failed = failed,
      bootstrap.parallel = plan$backend,
      bootstrap.workers = plan$workers,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, intervals)
  row.names(out) <- NULL
  out
}

validate_bootstrap_replicates <- function(R) {
  if (
    !is.numeric(R) ||
      length(R) != 1L ||
      is.na(R) ||
      !is.finite(R) ||
      R < 1L ||
      R != as.integer(R)
  ) {
    cli::cli_abort("{.arg R} must be a positive whole number.")
  }
  as.integer(R)
}

bootstrap_parallel_plan <- function(R, parallel, workers) {
  if (
    !is.character(parallel) ||
      length(parallel) != 1L ||
      is.na(parallel) ||
      !parallel %in% c("none", "multicore")
  ) {
    cli::cli_abort(
      "{.arg parallel} must be one of {.val none} or {.val multicore}."
    )
  }
  workers <- resolve_parallel_workers(workers, parallel)
  if (identical(parallel, "multicore") && .Platform$OS.type == "windows") {
    cli::cli_abort(
      "{.code parallel = \"multicore\"} is not available on Windows."
    )
  }
  actual_workers <- if (identical(parallel, "none")) {
    1L
  } else {
    min(10L, R, workers)
  }
  list(backend = parallel, workers = actual_workers)
}

resolve_parallel_workers <- function(workers, parallel) {
  if (is.null(workers)) {
    if (identical(parallel, "none")) {
      return(1L)
    }
    cores <- suppressWarnings(parallel::detectCores(logical = FALSE))
    if (!is.finite(cores) || is.na(cores) || cores < 1L) {
      cores <- suppressWarnings(parallel::detectCores(logical = TRUE))
    }
    if (!is.finite(cores) || is.na(cores) || cores < 1L) {
      cores <- 2L
    }
    return(max(1L, as.integer(floor(cores / 2))))
  }
  if (
    !is.numeric(workers) ||
      length(workers) != 1L ||
      is.na(workers) ||
      !is.finite(workers) ||
      workers < 1L ||
      workers != as.integer(workers)
  ) {
    cli::cli_abort("{.arg workers} must be a positive whole number or NULL.")
  }
  as.integer(workers)
}

profile_parallel_plan <- function(n_task, parallel, workers) {
  bootstrap_parallel_plan(n_task, parallel = parallel, workers = workers)
}

bootstrap_refit_control <- function(refit_control) {
  if (is.null(refit_control)) {
    return(drm_control(
      se = FALSE,
      keep_tmb_object = FALSE,
      optimizer_preset = "default"
    ))
  }
  drm_parse_control(refit_control)
}

profile_lapply <- function(indices, worker, plan) {
  if (identical(plan$backend, "none") || identical(plan$workers, 1L)) {
    return(lapply(indices, worker))
  }
  parallel::mclapply(indices, worker, mc.cores = plan$workers)
}

bootstrap_lapply <- function(indices, worker, plan) {
  if (identical(plan$backend, "none") || identical(plan$workers, 1L)) {
    return(lapply(indices, worker))
  }
  parallel::mclapply(indices, worker, mc.cores = plan$workers)
}

bootstrap_refit_one <- function(
  object,
  simulations,
  index,
  target_names,
  refit_control
) {
  out <- bootstrap_empty_draws(index, target_names)
  data <- bootstrap_response_data(object, simulations, index)
  refit <- tryCatch(
    {
      bootstrap_weights <- object$model$weights
      drmTMB(
        formula = object$formula,
        family = object$family,
        data = data,
        weights = bootstrap_weights,
        control = refit_control
      )
    },
    error = function(err) err
  )
  if (inherits(refit, "error")) {
    out$refit_message <- conditionMessage(refit)
    return(out)
  }
  refit_ok <- isTRUE(refit$opt$convergence == 0L)
  refit_targets <- drm_profile_targets(refit)
  matched <- match(target_names, refit_targets$parm)
  has_target <- !is.na(matched)
  out$refit_convergence <- refit$opt$convergence
  out$refit_ok <- refit_ok & has_target
  out$refit_message <- if (refit_ok) "ok" else refit$opt$message
  out$estimate[has_target] <- refit_targets$estimate[matched[has_target]]
  out$link_estimate[has_target] <-
    refit_targets$link_estimate[matched[has_target]]
  out
}

bootstrap_empty_draws <- function(index, target_names) {
  data.frame(
    bootstrap = index,
    parm = target_names,
    estimate = NA_real_,
    link_estimate = NA_real_,
    refit_ok = FALSE,
    refit_convergence = NA_integer_,
    refit_message = "not run",
    stringsAsFactors = FALSE
  )
}

bootstrap_percentile_interval <- function(target_draws, target, probs) {
  if (bootstrap_uses_link_percentiles(target)) {
    link_quantiles <- stats::quantile(
      target_draws$link_estimate,
      probs = probs,
      names = FALSE,
      type = 8
    )
    return(profile_transform_interval(link_quantiles, target))
  }
  stats::quantile(
    target_draws$estimate,
    probs = probs,
    names = FALSE,
    type = 8
  )
}

bootstrap_percentile_draws <- function(target_draws, target) {
  if (bootstrap_uses_link_percentiles(target)) {
    return(target_draws$link_estimate)
  }
  target_draws$estimate
}

bootstrap_uses_link_percentiles <- function(target) {
  identical(target$transformation[[1L]], "exp")
}

bootstrap_response_data <- function(object, simulations, index) {
  data <- object$data
  if (identical(object$model$model_type, "biv_gaussian")) {
    response_names <- bivariate_response_names(object)
    sim_y1 <- paste0("sim_", index, "_y1")
    sim_y2 <- paste0("sim_", index, "_y2")
    if (!all(c(sim_y1, sim_y2) %in% names(simulations))) {
      cli::cli_abort(
        "Internal error: bivariate bootstrap simulations are missing response columns."
      )
    }
    data[[response_names[[1L]]]] <- simulations[[sim_y1]]
    data[[response_names[[2L]]]] <- simulations[[sim_y2]]
    return(data)
  }
  response <- response_name_from_model_frame(
    object,
    "mu",
    fallback = NA_character_
  )
  if (
    !is.character(response) ||
      length(response) != 1L ||
      is.na(response) ||
      !response %in% names(data)
  ) {
    cli::cli_abort(
      "Bootstrap confidence intervals require a stored response column in the fitted data."
    )
  }
  sim_col <- paste0("sim_", index)
  if (!sim_col %in% names(simulations)) {
    cli::cli_abort(
      "Internal error: bootstrap simulations are missing response column {.val {sim_col}}."
    )
  }
  data[[response]] <- simulations[[sim_col]]
  data
}

wald_supported_targets <- function(targets) {
  targets$target_type == "direct" &
    targets$target_class %in%
      c(
        "fixed-effect",
        "distributional-scale",
        "random-effect-sd",
        "random-effect-correlation",
        "residual-correlation"
      ) &
    targets$transformation %in%
      c("linear_predictor", "exp", "tanh", "rho12_tanh")
}

bootstrap_supported_targets <- function(targets) {
  wald_supported_targets(targets)
}

profile_match_bootstrap_targets <- function(targets, parm) {
  unsupported <- profile_bootstrap_requested_unsupported_targets(targets, parm)
  if (nrow(unsupported) > 0L) {
    abort_unsupported_bootstrap_targets(unsupported)
  }
  if (is.numeric(parm)) {
    if (
      any(!is.finite(parm)) ||
        any(parm != as.integer(parm)) ||
        any(parm < 1L | parm > nrow(targets))
    ) {
      cli::cli_abort(
        "{.arg parm} numeric values must select rows from the available confidence-interval targets."
      )
    }
    return(targets[as.integer(parm), , drop = FALSE])
  }
  targets <- targets[bootstrap_supported_targets(targets), , drop = FALSE]
  profile_match_confint_targets(targets, parm, fixed_only = FALSE)
}

profile_bootstrap_requested_unsupported_targets <- function(targets, parm) {
  if (is.null(parm)) {
    return(targets[0L, , drop = FALSE])
  }
  if (is.numeric(parm)) {
    if (
      any(!is.finite(parm)) ||
        any(parm != as.integer(parm)) ||
        any(parm < 1L | parm > nrow(targets))
    ) {
      return(targets[0L, , drop = FALSE])
    }
    requested <- targets[as.integer(parm), , drop = FALSE]
    return(requested[!bootstrap_supported_targets(requested), , drop = FALSE])
  }
  if (!is.character(parm)) {
    return(targets[0L, , drop = FALSE])
  }

  aliases <- paste0(targets$dpar, ":", targets$term)
  expanded <- profile_expand_confint_target_sets(targets, parm)
  index <- match(expanded, targets$parm)
  missing_index <- is.na(index)
  if (any(missing_index)) {
    index[missing_index] <- match(expanded[missing_index], aliases)
  }
  index <- unique(index[!is.na(index)])
  if (length(index) == 0L) {
    return(targets[0L, , drop = FALSE])
  }
  requested <- targets[index, , drop = FALSE]
  requested[!bootstrap_supported_targets(requested), , drop = FALSE]
}

abort_unsupported_bootstrap_targets <- function(targets) {
  labels <- paste(targets$parm, collapse = ", ")
  target_types <- paste(unique(targets$target_type), collapse = ", ")
  notes <- paste(unique(targets$profile_note), collapse = ", ")
  cli::cli_abort(c(
    "Bootstrap confidence intervals currently support direct fitted-object targets only.",
    x = "Unsupported bootstrap target(s): {labels}.",
    i = "Requested target type(s): {target_types}; inventory note(s): {notes}.",
    i = "Use {.fn profile_targets} to inspect {.code target_type} and {.code profile_note} before choosing bootstrap targets."
  ))
}

profile_target_opt_positions <- function(object, targets) {
  opt_names <- names(object$opt$par)
  vapply(
    seq_len(nrow(targets)),
    function(i) {
      target <- targets[i, , drop = FALSE]
      internal <- target$tmb_parameter[[1L]]
      index <- target$index[[1L]]
      if (is.na(internal) || is.na(index)) {
        return(NA_integer_)
      }
      hits <- which(opt_names == internal)
      if (length(hits) < index) {
        return(NA_integer_)
      }
      hits[[index]]
    },
    integer(1L)
  )
}

profile_wald_standard_errors <- function(variances) {
  se <- rep(NA_real_, length(variances))
  ok <- is.finite(variances) & variances >= -sqrt(.Machine$double.eps)
  se[ok] <- sqrt(pmax(variances[ok], 0))
  se
}

empty_confint_table <- function(method = character()) {
  data.frame(
    parm = character(),
    level = numeric(),
    lower = numeric(),
    upper = numeric(),
    scale = character(),
    transformation = character(),
    tmb_parameter = character(),
    index = integer(),
    method = rep(method, 0L),
    profile.engine = character(),
    conf.status = character(),
    profile.boundary = logical(),
    profile.message = character(),
    stringsAsFactors = FALSE
  )
}

drm_profile_target_confint <- function(
  object,
  target,
  level,
  trace,
  profile_engine = c("tmbprofile", "auto", "endpoint"),
  endpoint_plan = profile_serial_plan(),
  ...
) {
  profile_engine <- match.arg(profile_engine)
  implemented_classes <- c(
    "fixed-effect",
    "distributional-scale",
    "random-effect-sd",
    "random-effect-correlation",
    "residual-correlation"
  )
  if (!isTRUE(target$profile_ready)) {
    cli::cli_abort(c(
      "Profile target {.val {target$parm}} is not ready for direct profiling.",
      i = "Inventory note: {.val {target$profile_note}}."
    ))
  }
  if (!target$target_class %in% implemented_classes) {
    cli::cli_abort(c(
      "Profile intervals are implemented for direct fixed-effect, constant distributional-scale, random-effect SD, random-effect correlation, and constant residual-correlation targets.",
      i = "Requested {.val {target$parm}} has target class {.val {target$target_class}}."
    ))
  }

  if (identical(profile_engine, "endpoint")) {
    return(drm_profile_target_endpoint_confint(
      object = object,
      target = target,
      level = level,
      endpoint_plan = endpoint_plan
    ))
  }

  if (
    identical(profile_engine, "auto") &&
      profile_endpoint_target_supported(target)
  ) {
    endpoint <- tryCatch(
      drm_profile_target_endpoint_confint(
        object = object,
        target = target,
        level = level,
        endpoint_plan = endpoint_plan
      ),
      error = function(err) err
    )
    if (!inherits(endpoint, "error")) {
      return(endpoint)
    }
  }

  drm_profile_target_tmbprofile_confint(
    object = object,
    target = target,
    level = level,
    trace = trace,
    ...
  )
}

drm_profile_target_tmbprofile_confint <- function(
  object,
  target,
  level,
  trace,
  ...
) {
  lincomb <- profile_lincomb(object, target)
  prof <- drm_tmbprofile(
    object = object,
    target_name = target$parm,
    lincomb = lincomb,
    trace = trace,
    ...
  )
  ci <- drm_tmbprofile_confint(prof, target_name = target$parm, level = level)
  interval <- profile_transform_interval(
    c(unname(ci[1L, "lower"]), unname(ci[1L, "upper"])),
    target
  )
  diagnostics <- profile_interval_diagnostics(
    interval,
    transformation = target$transformation
  )

  data.frame(
    parm = target$parm,
    level = level,
    lower = interval[[1L]],
    upper = interval[[2L]],
    scale = target$scale,
    transformation = target$transformation,
    tmb_parameter = target$tmb_parameter,
    index = target$index,
    method = "profile",
    profile.engine = "tmbprofile",
    conf.status = "profile",
    profile.boundary = diagnostics$boundary,
    profile.message = diagnostics$message,
    stringsAsFactors = FALSE
  )
}

drm_profile_target_endpoint_confint <- function(
  object,
  target,
  level,
  endpoint_plan = profile_serial_plan()
) {
  result <- drm_profile_endpoint_result(
    object = object,
    target = target,
    level = level,
    endpoint_plan = endpoint_plan
  )
  interval <- result$interval
  diagnostics <- profile_interval_diagnostics(
    interval,
    transformation = target$transformation
  )

  data.frame(
    parm = target$parm,
    level = level,
    lower = interval[[1L]],
    upper = interval[[2L]],
    scale = target$scale,
    transformation = target$transformation,
    tmb_parameter = target$tmb_parameter,
    index = target$index,
    method = "profile",
    profile.engine = "endpoint",
    conf.status = "profile",
    profile.boundary = diagnostics$boundary,
    profile.message = diagnostics$message,
    stringsAsFactors = FALSE
  )
}

drm_profile_endpoint_result <- function(
  object,
  target,
  level,
  root_tol = 1e-4,
  max_bracket_steps = 40L,
  endpoint_plan = profile_serial_plan()
) {
  if (!profile_endpoint_target_supported(target)) {
    cli::cli_abort(c(
      "Profile endpoint engine is only implemented for direct scalar scale, SD, and correlation targets.",
      i = "Requested {.val {target$parm}} has target class {.val {target$target_class}} and transformation {.val {target$transformation}}."
    ))
  }
  if (is.null(object$obj)) {
    cli::cli_abort(c(
      "Profile confidence intervals require the TMB object retained in {.code fit$obj}.",
      i = "Refit with {.code drm_control(keep_tmb_object = TRUE)} before using {.code method = \"profile\"}."
    ))
  }

  position <- profile_target_opt_positions(object, target)
  if (!is.finite(position) || is.na(position)) {
    cli::cli_abort(c(
      "Profile target {.val {target$parm}} cannot be mapped to an optimized scalar parameter.",
      i = "Check {.code profile_targets(fit)} before using {.code profile_engine = \"endpoint\"}."
    ))
  }
  position <- as.integer(position)

  drm_pin_tmb_object_to_optimum(object$obj, object$opt, object$tmb_state)
  theta_hat <- unname(object$opt$par[[position]])
  nll_hat <- unname(object$opt$objective)
  cutoff <- stats::qchisq(level, df = 1) / 2
  curvature_se <- profile_endpoint_curvature_se(object, position)
  control <- if (is.list(object$control) && is.list(object$control$optimizer)) {
    object$control$optimizer
  } else {
    list()
  }

  endpoint_worker <- function(direction) {
    evaluator <- profile_endpoint_evaluator(
      object = object,
      target_position = position,
      control = control
    )
    profile_endpoint_crossing(
      evaluator = evaluator,
      theta_hat = theta_hat,
      nll_hat = nll_hat,
      cutoff = cutoff,
      direction = direction,
      root_tol = root_tol,
      max_bracket_steps = max_bracket_steps,
      target_name = target$parm,
      curvature_se = curvature_se
    )
  }
  crossings <- profile_lapply(c(-1L, 1L), endpoint_worker, endpoint_plan)
  lower <- crossings[[1L]]
  upper <- crossings[[2L]]

  link_interval <- c(lower$theta, upper$theta)
  interval <- profile_transform_interval(link_interval, target)
  list(
    link_interval = link_interval,
    interval = interval,
    cutoff = cutoff,
    lower_root_error = lower$root_error,
    upper_root_error = upper$root_error,
    lower_n_eval = lower$n_eval,
    upper_n_eval = upper$n_eval,
    n_eval = lower$n_eval + upper$n_eval,
    curvature_se = curvature_se,
    lower_initial_step = lower$initial_step,
    upper_initial_step = upper$initial_step,
    lower_bracket_step = lower$bracket_step,
    upper_bracket_step = upper$bracket_step,
    lower_step_source = lower$step_source,
    upper_step_source = upper$step_source,
    endpoint_parallel = endpoint_plan$backend,
    endpoint_workers = endpoint_plan$workers,
    target_position = position
  )
}

profile_endpoint_target_supported <- function(target) {
  nrow(target) == 1L &&
    isTRUE(target$profile_ready[[1L]]) &&
    identical(target$target_type[[1L]], "direct") &&
    target$target_class[[1L]] %in%
      c(
        "distributional-scale",
        "random-effect-sd",
        "random-effect-correlation",
        "residual-correlation"
      ) &&
    target$transformation[[1L]] %in% c("exp", "tanh", "rho12_tanh")
}

profile_endpoint_curvature_se <- function(object, position) {
  if (!drm_has_sdreport_covariance(object)) {
    return(NA_real_)
  }
  cov_fixed <- object$sdr$cov.fixed
  if (position > nrow(cov_fixed)) {
    return(NA_real_)
  }
  variance <- cov_fixed[position, position]
  if (!is.finite(variance) || variance <= 0) {
    return(NA_real_)
  }
  sqrt(variance)
}

profile_endpoint_evaluator <- function(object, target_position, control) {
  par0 <- object$opt$par
  free <- seq_along(par0) != target_position
  start_free <- par0[free]

  evaluate <- function(theta, start) {
    full0 <- par0
    fn_free <- function(pfree) {
      full <- full0
      full[free] <- pfree
      full[[target_position]] <- theta
      object$obj$fn(full)
    }
    gr_free <- function(pfree) {
      full <- full0
      full[free] <- pfree
      full[[target_position]] <- theta
      object$obj$gr(full)[free]
    }
    opt <- stats::nlminb(start, fn_free, gr_free, control = control)
    opt_message <- opt$message
    if (is.null(opt_message) || length(opt_message) == 0L) {
      opt_message <- "unknown"
    }
    opt_gradient <- tryCatch(
      gr_free(opt$par),
      error = function(err) rep(NA_real_, length(opt$par))
    )
    max_abs_gradient <- suppressWarnings(max(abs(opt_gradient), na.rm = TRUE))
    if (!is.finite(max_abs_gradient)) {
      max_abs_gradient <- NA_real_
    }
    convergence_tolerated <- opt$convergence %in% c(0L, 1L)
    if (
      !is.finite(opt$objective) ||
        is.null(opt$convergence) ||
        !convergence_tolerated
    ) {
      cli::cli_abort(c(
        "Constrained endpoint optimization failed.",
        i = "Target internal value: {format(theta, digits = 6)}.",
        i = "Maximum absolute gradient: {format(max_abs_gradient, digits = 4)}.",
        x = "Optimizer message: {opt_message[[1L]]}"
      ))
    }
    list(nll = unname(opt$objective), par = opt$par)
  }

  list(evaluate = evaluate, start_free = start_free)
}

profile_endpoint_crossing <- function(
  evaluator,
  theta_hat,
  nll_hat,
  cutoff,
  direction,
  root_tol,
  max_bracket_steps,
  target_name,
  curvature_se = NA_real_
) {
  n_eval <- 0L
  last_free <- evaluator$start_free
  eval_root <- function(theta) {
    n_eval <<- n_eval + 1L
    out <- evaluator$evaluate(theta, last_free)
    last_free <<- out$par
    out$nll - nll_hat - cutoff
  }

  at_hat <- -cutoff
  if (!is.finite(at_hat) || at_hat >= 0) {
    cli::cli_abort(c(
      "Could not start endpoint profile for target {.val {target_name}}.",
      i = "The fitted optimum did not evaluate below the likelihood-ratio cutoff."
    ))
  }

  step_info <- profile_endpoint_initial_step(
    theta_hat = theta_hat,
    direction = direction,
    cutoff = cutoff,
    curvature_se = curvature_se
  )
  step <- step_info$step
  initial_step <- step
  n_bracket_step <- 0L
  outer <- theta_hat + direction * step
  outer_value <- eval_root(outer)
  for (i in seq_len(max_bracket_steps)) {
    if (is.finite(outer_value) && outer_value >= 0) {
      break
    }
    step <- step * 1.6
    n_bracket_step <- i
    outer <- theta_hat + direction * step
    outer_value <- eval_root(outer)
  }
  if (!is.finite(outer_value) || outer_value < 0) {
    cli::cli_abort(c(
      "Could not bracket profile endpoint for target {.val {target_name}}.",
      i = "This can indicate a flat, one-sided, or boundary-limited profile."
    ))
  }

  interval <- sort(c(theta_hat, outer))
  if (direction < 0) {
    f_lower <- outer_value
    f_upper <- at_hat
  } else {
    f_lower <- at_hat
    f_upper <- outer_value
  }
  root <- stats::uniroot(
    eval_root,
    interval = interval,
    f.lower = f_lower,
    f.upper = f_upper,
    tol = root_tol
  )
  root_error <- abs(root$f.root)
  if (!is.finite(root_error) || root_error > 5e-3) {
    cli::cli_abort(c(
      "Endpoint profile root for target {.val {target_name}} did not satisfy the likelihood-ratio equation closely enough.",
      i = "Absolute root error: {format(root_error, digits = 4)}.",
      i = "Try {.code profile_engine = \"tmbprofile\"} for the full profile path."
    ))
  }
  list(
    theta = root$root,
    root_error = root_error,
    n_eval = n_eval,
    initial_step = initial_step,
    bracket_step = step,
    n_bracket_step = n_bracket_step,
    step_source = step_info$source
  )
}

profile_endpoint_initial_step <- function(
  theta_hat,
  direction,
  cutoff = NA_real_,
  curvature_se = NA_real_
) {
  if (
    is.finite(cutoff) &&
      cutoff > 0 &&
      is.finite(curvature_se) &&
      curvature_se > 0
  ) {
    step <- sqrt(2 * cutoff) * curvature_se * 1.1
    if (is.finite(step) && step > sqrt(.Machine$double.eps)) {
      return(list(step = step, source = "curvature"))
    }
  }
  step <- max(0.25, abs(theta_hat) * 0.05)
  if (!is.finite(step) || step <= 0) {
    step <- 0.25
  }
  list(step = step, source = "fixed")
}

profile_check_tmbprofile_dots <- function(...) {
  profile_check_tmbprofile_dots_list(list(...))
}

profile_check_tmbprofile_dots_list <- function(dots) {
  if (!length(dots)) {
    return(invisible(NULL))
  }
  dot_names <- names(dots)
  if (is.null(dot_names)) {
    return(invisible(NULL))
  }
  controlled <- intersect(
    dot_names[nzchar(dot_names)],
    c("obj", "name", "lincomb", "trace")
  )
  if (length(controlled)) {
    cli::cli_abort(c(
      "Profile target selection is controlled by {.arg parm}.",
      x = "Do not pass {.arg {controlled}} through {.arg ...}.",
      i = "{.pkg drmTMB} profiles one target at a time by supplying {.arg obj}, {.arg name}, {.arg lincomb}, and {.arg trace} to {.fun TMB::tmbprofile} internally."
    ))
  }
  invisible(NULL)
}

drm_tmbprofile <- function(object, target_name, lincomb, trace, ...) {
  drm_pin_tmb_object_to_optimum(object$obj, object$opt, object$tmb_state)
  tryCatch(
    TMB::tmbprofile(
      obj = object$obj,
      name = target_name,
      lincomb = lincomb,
      trace = trace,
      ...
    ),
    error = function(err) {
      cli::cli_abort(
        c(
          "Profile likelihood failed while profiling target {.val {target_name}}.",
          i = "Check {.code profile_targets(fit)} to confirm the target is profile-ready.",
          i = "Try changing profile controls such as {.arg ystep}, {.arg ytol}, or {.arg parm.range}; then inspect {.code check_drm(fit)} if the profile still fails.",
          i = "This can indicate a boundary, one-sided, non-monotone, or failed-inner-optimization profile.",
          x = "Original error: {conditionMessage(err)}"
        ),
        parent = err
      )
    }
  )
}

drm_tmbprofile_confint <- function(profile, target_name, level) {
  tryCatch(
    stats::confint(profile, level = level),
    error = function(err) {
      cli::cli_abort(
        c(
          "Could not extract a profile confidence interval for target {.val {target_name}}.",
          i = "The profile may not cross the likelihood-ratio threshold on both sides.",
          i = "Try a wider {.arg parm.range}, a smaller {.arg ystep}, or inspect the profile object interactively.",
          i = "This can indicate a boundary, one-sided, non-monotone, or failed-inner-optimization profile.",
          x = "Original error: {conditionMessage(err)}"
        ),
        parent = err
      )
    }
  )
}

profile_interval_diagnostics <- function(
  interval,
  transformation,
  sd_boundary = sqrt(.Machine$double.eps),
  correlation_boundary = 0.98
) {
  interval <- as.numeric(interval)
  if (length(interval) != 2L || any(!is.finite(interval))) {
    return(list(boundary = TRUE, message = "nonfinite_interval"))
  }
  if (
    transformation %in%
      c("exp", "derived_group_scale") &&
      min(interval) <= sd_boundary
  ) {
    return(list(boundary = TRUE, message = "near_sd_boundary"))
  }
  if (
    transformation %in%
      c("tanh", "rho12_tanh", "unstructured_corr") &&
      max(abs(interval)) >= correlation_boundary
  ) {
    return(list(boundary = TRUE, message = "near_correlation_boundary"))
  }
  list(boundary = FALSE, message = "ok")
}

profile_transform_interval <- function(interval, target) {
  switch(
    target$transformation,
    linear_predictor = interval,
    exp = exp(interval),
    tanh = 0.999999 * tanh(interval),
    rho12_tanh = rho_response(interval),
    interval
  )
}

profile_transform_newdata_interval <- function(interval, object, dpar, offset) {
  eta_interval <- interval + offset
  switch(
    drm_dpar_link(object, dpar),
    log = exp(eta_interval),
    atanh_guarded = rho_response(eta_interval),
    atanh_re_guarded = rho_response(eta_interval, guard = 0.999999),
    cli::cli_abort(
      "Internal error: no response-scale profile transformation for {.val {dpar}}."
    )
  )
}

profile_newdata_transformation <- function(object, dpar) {
  switch(
    drm_dpar_link(object, dpar),
    log = "exp",
    atanh_guarded = "rho12_tanh",
    atanh_re_guarded = "random_effect_correlation_tanh",
    "unknown"
  )
}

profile_registry_cor_targets <- function(object) {
  registry <- object$model$random$covariance_blocks
  if (
    !is.list(registry) ||
      is.null(registry$pairs) ||
      nrow(registry$pairs) == 0L
  ) {
    return(list())
  }

  pairs <- registry$pairs
  pair_is_fitted <- !is.na(pairs$tmb_parameter) & !is.na(pairs$tmb_index)
  pairs <- pairs[pair_is_fitted, , drop = FALSE]
  if (nrow(pairs) == 0L) {
    return(list())
  }

  out <- lapply(seq_len(nrow(pairs)), function(i) {
    pair <- pairs[i, , drop = FALSE]
    dpar <- covariance_block_corpars_key(pair$tmb_parameter[[1L]])
    values <- object$corpars[[dpar]]
    index <- pair$tmb_index[[1L]]
    if (random_effect_correlation_is_modelled(object, dpar, index)) {
      return(NULL)
    }
    if (is.null(values) || index < 1L || index > length(values)) {
      cli::cli_abort(
        "Internal error: covariance-block registry pair has no profile target correlation."
      )
    }
    estimate <- unname(values[[index]])
    is_unstructured_corr <- identical(pair$tmb_parameter[[1L]], "theta_re_cov")
    status <- if (is_unstructured_corr) {
      list(
        profile_ready = FALSE,
        profile_note = "derived_unstructured_correlation"
      )
    } else {
      profile_direct_target_status(
        object,
        pair$tmb_parameter[[1L]],
        index
      )
    }
    new_profile_target_row(
      parm = paste0("cor:", dpar, ":", pair$parameter[[1L]]),
      target_class = "random-effect-correlation",
      dpar = dpar,
      term = pair$parameter[[1L]],
      tmb_parameter = pair$tmb_parameter[[1L]],
      index = index,
      estimate = estimate,
      link_estimate = if (is_unstructured_corr) {
        NA_real_
      } else {
        guarded_correlation_link(estimate, guard = 0.999999)
      },
      scale = "response",
      transformation = if (is_unstructured_corr) {
        "unstructured_corr"
      } else {
        "tanh"
      },
      target_type = if (is_unstructured_corr) "derived" else "direct",
      profile_ready = status$profile_ready,
      profile_note = status$profile_note
    )
  })
  out[!vapply(out, is.null, logical(1L))]
}

new_profile_target_row <- function(
  parm,
  target_class,
  dpar,
  term,
  tmb_parameter,
  index,
  estimate,
  link_estimate,
  scale,
  transformation,
  target_type,
  profile_ready,
  profile_note
) {
  data.frame(
    parm = parm,
    target_class = target_class,
    dpar = dpar,
    term = term,
    tmb_parameter = tmb_parameter,
    index = as.integer(index),
    estimate = as.numeric(estimate),
    link_estimate = as.numeric(link_estimate),
    scale = scale,
    transformation = transformation,
    target_type = target_type,
    profile_ready = as.logical(profile_ready),
    profile_note = profile_note,
    stringsAsFactors = FALSE
  )
}

empty_profile_targets <- function() {
  data.frame(
    parm = character(),
    target_class = character(),
    dpar = character(),
    term = character(),
    tmb_parameter = character(),
    index = integer(),
    estimate = numeric(),
    link_estimate = numeric(),
    scale = character(),
    transformation = character(),
    target_type = character(),
    profile_ready = logical(),
    profile_note = character(),
    stringsAsFactors = FALSE
  )
}

validate_profile_targets <- function(targets) {
  expected <- names(empty_profile_targets())
  if (!identical(names(targets), expected)) {
    cli::cli_abort("Internal error: profile target columns are inconsistent.")
  }
  if (nrow(targets) == 0L) {
    return(targets)
  }
  allowed_types <- c("direct", "derived")
  bad_type <- !targets$target_type %in% allowed_types
  if (any(bad_type)) {
    cli::cli_abort(
      "Internal error: profile target type {.val {targets$target_type[bad_type][[1L]]}} is not supported."
    )
  }
  allowed_notes <- c(
    "ready",
    "tmb_object_required",
    "julia_bridge_payload_required",
    "missing_tmb_parameter",
    "derived_target",
    "derived_unstructured_correlation"
  )
  bad_note <- !targets$profile_note %in% allowed_notes
  if (any(bad_note)) {
    cli::cli_abort(
      "Internal error: profile target note {.val {targets$profile_note[bad_note][[1L]]}} is not supported."
    )
  }
  allowed_transformations <- c(
    "linear_predictor",
    "exp",
    "rho12_tanh",
    "tanh",
    "variance_ratio",
    "derived_group_scale",
    "unstructured_corr",
    "ordered_cutpoint"
  )
  bad_transformation <- !targets$transformation %in% allowed_transformations
  if (any(bad_transformation)) {
    cli::cli_abort(
      "Internal error: profile target transformation {.val {targets$transformation[bad_transformation][[1L]]}} is not supported."
    )
  }
  if (any(targets$profile_ready & targets$target_type != "direct")) {
    cli::cli_abort("Internal error: derived profile targets cannot be ready.")
  }
  duplicate <- duplicated(targets$parm)
  if (any(duplicate)) {
    cli::cli_abort(
      "Internal error: duplicate profile target name {.val {targets$parm[duplicate][[1L]]}}."
    )
  }
  targets
}

profile_fixef_internal <- function(dpar) {
  if (
    any(startsWith(
      dpar,
      c("sd(", "sd1(", "sd2(", "sd_phylo(", "sd_phylo1(", "sd_phylo2(")
    ))
  ) {
    return("beta_sd_mu")
  }
  if (identical(dpar, "hu")) {
    return("beta_zi")
  }
  if (startsWith(dpar, "corpair(")) {
    return("beta_cor_mu")
  }
  paste0("beta_", dpar)
}

profile_sd_internal <- function(object, dpar, term) {
  registry <- object$model$random$covariance_blocks
  if (
    is.list(registry) &&
      nrow(qgt2_members <- qgt2_covariance_members(registry)) > 0L &&
      any(
        vapply(
          seq_len(nrow(qgt2_members)),
          function(i) {
            member <- qgt2_members[i, , drop = FALSE]
            identical(covariance_registry_member_sd_key(member), dpar) &&
              identical(member$label[[1L]], term)
          },
          logical(1L)
        )
      )
  ) {
    return("log_sd_re_cov")
  }
  if (
    dpar %in%
      c("mu", "sigma") &&
      grepl(
        "phylo\\(|phylo_interaction\\(|spatial\\(|animal\\(|relmat\\(",
        term
      )
  ) {
    return("log_sd_phylo")
  }
  if (dpar %in% c("mu", "sigma")) {
    return(paste0("log_sd_", dpar))
  }
  NA_character_
}

profile_cor_internal <- function(dpar) {
  if (identical(dpar, "mu")) {
    return("eta_cor_mu")
  }
  if (
    dpar %in%
      c("phylo", "phylo_interaction", "spatial", "animal", "relmat")
  ) {
    return("eta_cor_phylo")
  }
  paste0("eta_cor_", dpar)
}

profile_internal_is_active <- function(object, internal, index) {
  if (is.na(internal) || is.na(index)) {
    return(FALSE)
  }
  if (is.null(object$obj)) {
    return(FALSE)
  }
  sum(names(object$opt$par) == internal) >= index
}

profile_direct_target_status <- function(object, internal, index) {
  ready <- profile_internal_is_active(object, internal, index)
  list(
    profile_ready = ready,
    profile_note = profile_ready_note(
      ready,
      object = object,
      internal = internal,
      index = index
    )
  )
}

profile_ready_note <- function(
  profile_ready,
  object = NULL,
  internal = NA,
  index = NA
) {
  if (isTRUE(profile_ready)) {
    return("ready")
  }
  if (!is.null(object) && is.null(object$obj)) {
    return("tmb_object_required")
  }
  "missing_tmb_parameter"
}

profile_match_targets <- function(targets, parm) {
  if (missing(parm) || is.null(parm)) {
    cli::cli_abort(c(
      "Profile targets must be supplied explicitly.",
      i = "Use {.code drmTMB:::drm_profile_targets(fit)$parm} to inspect available targets."
    ))
  }
  if (is.numeric(parm)) {
    if (
      any(!is.finite(parm)) ||
        any(parm != as.integer(parm)) ||
        any(parm < 1L | parm > nrow(targets))
    ) {
      cli::cli_abort(
        "{.arg parm} numeric values must select rows from the available profile targets."
      )
    }
    return(targets[as.integer(parm), , drop = FALSE])
  }
  if (!is.character(parm)) {
    cli::cli_abort(
      "{.arg parm} must be a character or integer vector of profile targets."
    )
  }
  index <- match(parm, targets$parm)
  missing_index <- is.na(index)
  if (any(missing_index)) {
    available <- paste(utils::head(targets$parm, 10L), collapse = ", ")
    cli::cli_abort(c(
      "Unknown profile target{?s}: {.val {parm[missing_index]}}.",
      i = "First available targets: {available}."
    ))
  }
  targets[index, , drop = FALSE]
}

profile_match_confint_targets <- function(targets, parm, fixed_only) {
  if (is.null(parm)) {
    return(targets)
  }
  parm <- profile_expand_confint_target_sets(targets, parm)
  if (is.numeric(parm)) {
    if (
      any(!is.finite(parm)) ||
        any(parm != as.integer(parm)) ||
        any(parm < 1L | parm > nrow(targets))
    ) {
      cli::cli_abort(
        "{.arg parm} numeric values must select rows from the available confidence-interval targets."
      )
    }
    return(targets[as.integer(parm), , drop = FALSE])
  }
  if (!is.character(parm)) {
    cli::cli_abort(
      "{.arg parm} must be a character or integer vector of confidence-interval targets."
    )
  }

  aliases <- paste0(targets$dpar, ":", targets$term)
  index <- match(parm, targets$parm)
  missing_index <- is.na(index)
  if (any(missing_index)) {
    index[missing_index] <- match(parm[missing_index], aliases)
  }
  missing_index <- is.na(index)
  if (any(missing_index)) {
    available <- paste(utils::head(targets$parm, 10L), collapse = ", ")
    detail <- if (fixed_only) {
      "Use coefficient labels from summary(fit) or full names such as {.val fixef:mu:x}."
    } else {
      "Use full profile target names such as {.val fixef:mu:x}."
    }
    cli::cli_abort(c(
      "Unknown confidence-interval target{?s}: {.val {parm[missing_index]}}.",
      i = detail,
      i = "First available targets: {available}."
    ))
  }
  targets[index, , drop = FALSE]
}

profile_expand_confint_target_sets <- function(targets, parm) {
  if (!is.character(parm)) {
    return(parm)
  }
  alias_rows <- list(
    fixed_effects = targets$target_class == "fixed-effect",
    `fixed-effects` = targets$target_class == "fixed-effect",
    random_effects = targets$target_class %in%
      c("random-effect-sd", "random-effect-correlation"),
    `random-effects` = targets$target_class %in%
      c("random-effect-sd", "random-effect-correlation"),
    variance_components = targets$target_class %in%
      c("distributional-scale", "random-effect-sd"),
    `variance-components` = targets$target_class %in%
      c("distributional-scale", "random-effect-sd"),
    correlations = targets$target_class %in%
      c("random-effect-correlation", "residual-correlation")
  )
  expanded <- unlist(
    lapply(parm, function(one) {
      rows <- alias_rows[[one]]
      if (is.null(rows)) {
        return(one)
      }
      targets$parm[rows]
    }),
    use.names = FALSE
  )
  unique(expanded)
}

profile_newdata_dpar <- function(object, parm) {
  if (is.null(parm)) {
    cli::cli_abort(c(
      "{.arg parm} must name one distributional parameter when {.arg newdata} is supplied.",
      i = "Use {.val sigma}, {.val sigma1}, {.val sigma2}, {.val rho12}, or a fitted {.fn corpair} dpar."
    ))
  }
  if (!is.character(parm) || length(parm) != 1L || is.na(parm)) {
    cli::cli_abort(
      "{.arg parm} must be one distributional-parameter name when {.arg newdata} is supplied."
    )
  }

  scale_or_residual <- intersect(
    c("sigma", "sigma1", "sigma2", "rho12"),
    names(object$coefficients)
  )
  scale_or_residual <- scale_or_residual[vapply(
    scale_or_residual,
    function(dpar) drm_dpar_link(object, dpar) %in% c("log", "atanh_guarded"),
    logical(1)
  )]
  corpair <- names(object$coefficients)[
    startsWith(names(object$coefficients), "corpair(")
  ]
  corpair <- corpair[vapply(
    corpair,
    function(dpar) identical(drm_dpar_link(object, dpar), "atanh_re_guarded"),
    logical(1)
  )]
  supported <- c(scale_or_residual, corpair)
  if (!parm %in% supported) {
    available <- if (length(supported)) {
      paste(supported, collapse = ", ")
    } else {
      "none for this fitted model"
    }
    cli::cli_abort(c(
      "Response-scale profile intervals with {.arg newdata} are implemented for fitted scale, residual-correlation, and q2 ordinary or phylogenetic {.fn corpair} parameters.",
      i = "Requested {.val {parm}}; available for this fit: {available}."
    ))
  }
  parm
}

profile_newdata_parm_labels <- function(dpar, newdata) {
  labels <- row.names(newdata)
  default_labels <- as.character(seq_len(nrow(newdata)))
  if (
    is.null(labels) ||
      anyNA(labels) ||
      any(!nzchar(labels)) ||
      identical(labels, default_labels)
  ) {
    labels <- default_labels
  }
  paste0(dpar, "[", labels, "]")
}

profile_target_positions <- function(targets, labels) {
  aliases <- paste0(targets$dpar, ":", targets$term)
  positions <- match(aliases, labels)
  if (anyNA(positions)) {
    cli::cli_abort(
      "Internal error: confidence-interval targets do not match fitted coefficient labels."
    )
  }
  positions
}

profile_lincomb <- function(object, target) {
  par_names <- names(object$opt$par)
  positions <- which(par_names == target$tmb_parameter)
  if (length(positions) < target$index) {
    cli::cli_abort(c(
      "Profile target {.val {target$parm}} cannot be mapped to optimized parameters.",
      i = "Expected index {target$index} in TMB parameter {.val {target$tmb_parameter}}."
    ))
  }
  out <- rep(0, length(object$opt$par))
  out[positions[[target$index]]] <- 1
  out
}

validate_profile_level <- function(level) {
  if (
    !is.numeric(level) ||
      length(level) != 1L ||
      !is.finite(level) ||
      level <= 0 ||
      level >= 1
  ) {
    cli::cli_abort("{.arg level} must be one number between 0 and 1.")
  }
}
