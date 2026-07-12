# DO-T1 adequacy plots for the distributional output & adequacy layer
# (issue #747). Consumes R/adequacy.R's randomized quantile residuals; see
# that file for the fixed-effect-only honesty note. ggplot2 is Suggests-only
# (matching R/plot-corpairs.R and R/profile.R's plot.profile.drmTMB()); both
# functions here guard with requireNamespace().
#
# Confidence-Eye figure contract, applied to the multi-realization envelope:
# pale ribbon region + darker outline + hollow points (shape 21, white fill);
# no filled points, no horizontal CI bars. The zero/diagonal reference line
# is a reference, not an uncertainty interval.

#' Worm plot of randomized quantile residuals
#'
#' `worm_plot()` draws a detrended QQ plot (van Buuren & Fredriks-style worm
#' plot) of [drm_quantile_residuals()] against their N(0,1) order-statistic
#' theoretical quantiles: `deviation = sorted residual - theoretical
#' quantile`. A flat scatter around the dotted zero reference line is no
#' detectable departure from N(0,1); a systematic bend flags a
#' mis-specification of the fitted distributional form (see the
#' GAMLSS-Primer Fig-4c contrast: a location-only fit to heteroscedastic data
#' bends, the matching location-scale fit is flat).
#'
#' When `nsim > 1`, a pale grey envelope (with a darker outline) overplots the
#' per-rank range across the `nsim` Dunn-Smyth realizations, so a single
#' randomized draw is not over-read; the first realization's points and
#' fitted trend are drawn on top.
#'
#' This is fixed-effect adequacy only -- see [drm_quantile_residuals()]. A
#' flat worm plot is "no detectable departure" evidence about the fixed-effect
#' distributional form, never a general validity or calibration claim.
#'
#' **What this detects -- and does not.** A worm plot bends when the
#' underlying quantile residuals depart from N(0,1); see
#' `residuals.drmTMB()`'s Details for the full gated-campaign breakdown (400
#' seeds x 18 families, tweedie: 99 of 400 seeds locally, full run deferred
#' to Totoro;
#' `docs/dev-log/simulation-artifacts/2026-07-12-dg3-power-arm-gated/`). In
#' short: it flags shape/atom mis-specification a family cannot reabsorb
#' through its own free parameters (heavy tails, ignored overdispersion or
#' zero-inflation in a no-free-dispersion family, ignored truncation, a
#' missing zero/one atom -- gated power >= 0.8), but it stays flat -- a
#' genuine structural blind spot, not evidence of adequacy -- when a free
#' nuisance/dispersion/inflation parameter absorbs the mis-specification
#' (e.g. heteroscedasticity absorbed by Student-t `nu`, missing
#' zero-inflation absorbed by `nbinom2` `sigma`, or a constant-vs-covariate
#' zero-inflation/hurdle mechanism mis-set for `hurdle_nbinom2`/
#' `zero_one_beta`). For `zi_poisson`/`zi_nbinom2`, the same
#' constant-vs-covariate mechanism mis-spec is NOT flat -- power rises with
#' n -- but stays far below 0.8 even at n = 3000, so it is
#' sample-size-limited in principle but impractical to detect at realistic
#' sample sizes. A mean-structure diagnostic, not this one, is what catches
#' an absorbed mis-specification.
#'
#' @param object A `drmTMB` fit.
#' @param seed Optional single integer seed, passed to
#'   [drm_quantile_residuals()].
#' @param nsim Number of Dunn-Smyth realizations to overplot as an envelope;
#'   passed to [drm_quantile_residuals()].
#' @param response For a bivariate `biv_gaussian` fit, `1` or `2`, selecting
#'   which response's marginal residuals to plot; see
#'   [fitted_distribution()]. Must be `NULL` (the default) for univariate
#'   model types.
#' @param ... Reserved for future options.
#'
#' @return A `ggplot` object.
#' @examples
#' set.seed(20260712)
#' n <- 60
#' x <- stats::rnorm(n)
#' dat <- data.frame(y = 0.5 + 0.8 * x + stats::rnorm(n), x = x)
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   worm_plot(fit)
#' }
#' @export
worm_plot <- function(object, seed = NULL, nsim = 1L, response = NULL, ...) {
  drm_adequacy_plot_dots(list(...))
  drm_adequacy_require_ggplot2()
  data <- drm_quantile_residual_qq_data(object, seed = seed, nsim = nsim, response = response)
  primary <- data[data$sim == 1L, , drop = FALSE]

  out <- ggplot2::ggplot(
    primary,
    ggplot2::aes(x = .data$theoretical, y = .data$deviation)
  )
  if (nsim > 1L) {
    out <- out +
      drm_adequacy_envelope_layers(drm_adequacy_envelope(data, "deviation"))
  }
  out +
    ggplot2::geom_hline(
      yintercept = 0,
      linetype = "dotted",
      colour = "grey55",
      linewidth = 0.35
    ) +
    ggplot2::geom_point(
      shape = 21,
      fill = "white",
      colour = "#0072B2",
      size = 1.8,
      stroke = 0.6,
      na.rm = TRUE
    ) +
    ggplot2::geom_smooth(
      method = "lm",
      formula = y ~ poly(x, 3),
      se = FALSE,
      colour = "#D55E00",
      linewidth = 0.6,
      na.rm = TRUE
    ) +
    ggplot2::labs(
      x = "Theoretical N(0,1) quantile",
      y = "Deviation (ordered residual − theoretical quantile)",
      title = "Worm plot of randomized quantile residuals",
      subtitle = paste(
        "Fixed-effect adequacy: flat = no detectable departure from N(0,1);",
        "a bend flags mis-specification. Not a validity or calibration claim."
      )
    )
}

#' Normal QQ plot of randomized quantile residuals
#'
#' `qq_plot()` draws a normal QQ plot of [drm_quantile_residuals()] against
#' their N(0,1) order-statistic theoretical quantiles, with the y = x
#' reference line dotted. Points on the reference line are no detectable
#' departure from N(0,1); systematic curvature away from it flags a
#' mis-specification of the fitted distributional form.
#'
#' When `nsim > 1`, a pale grey envelope (with a darker outline) overplots the
#' per-rank range across the `nsim` Dunn-Smyth realizations, so a single
#' randomized draw is not over-read; the first realization's points are drawn
#' on top.
#'
#' This is fixed-effect adequacy only -- see [drm_quantile_residuals()]. See
#' [worm_plot()] for the detrended variant that makes systematic bends easier
#' to read.
#'
#' **What this detects -- and does not.** Same scope as [worm_plot()] --
#' shape/atom mis-specification a family cannot reabsorb through its own
#' free parameters is detected with gated power >= 0.8 (heavy tails, ignored
#' overdispersion or zero-inflation in a no-free-dispersion family, ignored
#' truncation, a missing zero/one atom); a mis-specification a free
#' nuisance/dispersion/inflation parameter absorbs (heteroscedasticity via
#' Student-t `nu`, missing zero-inflation via `nbinom2` `sigma`, a
#' constant-vs-covariate inflation mechanism for `hurdle_nbinom2`/
#' `zero_one_beta`) is a genuine structural blind spot, not evidence of
#' adequacy; the same mechanism mis-spec for `zi_poisson`/`zi_nbinom2` is
#' sample-size-limited rather than structurally blind but stays far below
#' 0.8 even at n = 3000. See `residuals.drmTMB()`'s Details for the
#' full gated-campaign breakdown (tweedie: 99 of 400 seeds locally, full run
#' deferred to Totoro)
#' (`docs/dev-log/simulation-artifacts/2026-07-12-dg3-power-arm-gated/`).
#'
#' @param object A `drmTMB` fit.
#' @param seed Optional single integer seed, passed to
#'   [drm_quantile_residuals()].
#' @param nsim Number of Dunn-Smyth realizations to overplot as an envelope;
#'   passed to [drm_quantile_residuals()].
#' @param response For a bivariate `biv_gaussian` fit, `1` or `2`, selecting
#'   which response's marginal residuals to plot; see
#'   [fitted_distribution()]. Must be `NULL` (the default) for univariate
#'   model types.
#' @param ... Reserved for future options.
#'
#' @return A `ggplot` object.
#' @examples
#' set.seed(20260712)
#' n <- 60
#' x <- stats::rnorm(n)
#' dat <- data.frame(y = 0.5 + 0.8 * x + stats::rnorm(n), x = x)
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   qq_plot(fit)
#' }
#' @export
qq_plot <- function(object, seed = NULL, nsim = 1L, response = NULL, ...) {
  drm_adequacy_plot_dots(list(...))
  drm_adequacy_require_ggplot2()
  data <- drm_quantile_residual_qq_data(object, seed = seed, nsim = nsim, response = response)
  primary <- data[data$sim == 1L, , drop = FALSE]

  out <- ggplot2::ggplot(
    primary,
    ggplot2::aes(x = .data$theoretical, y = .data$sample)
  )
  if (nsim > 1L) {
    out <- out +
      drm_adequacy_envelope_layers(drm_adequacy_envelope(data, "sample"))
  }
  out +
    ggplot2::geom_abline(
      intercept = 0,
      slope = 1,
      linetype = "dotted",
      colour = "grey55",
      linewidth = 0.35
    ) +
    ggplot2::geom_point(
      shape = 21,
      fill = "white",
      colour = "#0072B2",
      size = 1.8,
      stroke = 0.6,
      na.rm = TRUE
    ) +
    ggplot2::labs(
      x = "Theoretical N(0,1) quantile",
      y = "Randomized quantile residual",
      title = "Normal QQ plot of randomized quantile residuals",
      subtitle = paste(
        "Fixed-effect adequacy: on the line = no detectable departure from",
        "N(0,1). Not a validity or calibration claim."
      )
    )
}

drm_adequacy_plot_dots <- function(dots) {
  if (length(dots) > 0L) {
    cli::cli_abort("{.arg ...} is reserved for future options.")
  }
  invisible(NULL)
}

drm_adequacy_require_ggplot2 <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.fn worm_plot}/{.fn qq_plot} require the {.pkg ggplot2} package.",
      i = "Install it with {.code install.packages(\"ggplot2\")}."
    ))
  }
  invisible(TRUE)
}

# Pale ribbon + darker outline (Confidence-Eye envelope styling; no fill on
# the outline itself, so it never reads as a filled point / CI bar).
drm_adequacy_envelope_layers <- function(envelope) {
  list(
    ggplot2::geom_ribbon(
      data = envelope,
      mapping = ggplot2::aes(
        x = .data$theoretical,
        ymin = .data$ymin,
        ymax = .data$ymax
      ),
      inherit.aes = FALSE,
      fill = "grey75",
      alpha = 0.35,
      colour = NA
    ),
    ggplot2::geom_line(
      data = envelope,
      mapping = ggplot2::aes(x = .data$theoretical, y = .data$ymin),
      inherit.aes = FALSE,
      colour = "grey45",
      linewidth = 0.3
    ),
    ggplot2::geom_line(
      data = envelope,
      mapping = ggplot2::aes(x = .data$theoretical, y = .data$ymax),
      inherit.aes = FALSE,
      colour = "grey45",
      linewidth = 0.3
    )
  )
}
