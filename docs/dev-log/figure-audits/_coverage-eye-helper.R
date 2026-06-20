# Shared Confidence Eye helper for simulation coverage figures.
#
# The repo's default coverage grammar (docs/design/39-visualization-grammar.md)
# is dots + MCSE bars + a target line; Confidence Eyes are the default for
# coefficient/SD/correlation rows, and are allowed on coverage plots only "for a
# specific reason". The maintainer requested the eye grammar here, so these
# coverage figures render each cell's empirical coverage estimate as a VERTICAL
# Confidence Eye: a pale compatibility lens whose half-width follows the quadratic
# log-likelihood profile (widest at the coverage estimate, tapering to zero at the
# +/- z * MCSE endpoints, exactly as plot_corpairs() does on the Fisher-z scale),
# plus a hollow point-estimate marker. The eye represents the Monte-Carlo
# compatibility interval for the coverage estimate -- NOT model uncertainty.
suppressMessages(library(ggplot2))

# Build vertical-eye polygon vertices for each row of `d`.
# `d` needs: xnum (numeric x centre incl. dodge), cov (coverage), mcse, gid
# (unique per cell-series), parameter, plus any facet columns in `facets`.
coverage_eye_polys <- function(d, facets = character(0), width = 0.13,
                               n = 90L, level = 0.95) {
  cutoff <- 0.5 * stats::qchisq(level, df = 1)
  zc <- stats::qnorm(1 - (1 - level) / 2)
  do.call(rbind, lapply(seq_len(nrow(d)), function(i) {
    r <- d[i, , drop = FALSE]
    se <- max(r$mcse, .Machine$double.eps)
    yy <- seq(r$cov - zc * se, r$cov + zc * se, length.out = n)
    hw <- width * pmax(cutoff - 0.5 * ((yy - r$cov) / se)^2, 0) / cutoff
    out <- data.frame(
      px = c(r$xnum - hw, rev(r$xnum + hw)),
      py = c(yy, rev(yy)),
      gid = r$gid,
      parameter = r$parameter,
      stringsAsFactors = FALSE
    )
    for (f in facets) out[[f]] <- r[[f]]
    out
  }))
}

# Assemble the coverage-eye ggplot. `d` needs: xnum, cov, mcse, gid, parameter,
# xbreaks/xlabels attributes for the x scale, plus facet columns.
coverage_eye_plot <- function(d, polys, pal, shapes, facet = NULL,
                              xbreaks, xlabels, band = c(0.93, 0.97),
                              ylim = c(0.90, 1.0), nominal = 0.95) {
  g <- ggplot() +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = band[1], ymax = band[2],
      fill = "grey80", alpha = 0.45) +
    geom_hline(yintercept = nominal, linewidth = 0.5, color = "grey30") +
    geom_polygon(
      data = polys,
      aes(x = px, y = py, group = gid, fill = parameter, color = parameter),
      alpha = 0.32, linewidth = 0.4, show.legend = FALSE
    ) +
    geom_point(
      data = d,
      aes(x = xnum, y = cov, shape = parameter, color = parameter),
      fill = "white", size = 2.7, stroke = 1.0
    ) +
    scale_fill_manual(values = pal) +
    scale_color_manual(values = pal) +
    scale_shape_manual(values = shapes) +
    scale_x_continuous(breaks = xbreaks, labels = xlabels) +
    coord_cartesian(ylim = ylim) +
    theme_minimal(base_size = 11) +
    theme(
      legend.position = "top",
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      strip.text = element_text(face = "bold"),
      plot.caption = element_text(hjust = 0, color = "grey40", size = 8)
    )
  if (!is.null(facet)) g <- g + facet_wrap(stats::as.formula(paste("~", facet)), nrow = 2)
  g
}
