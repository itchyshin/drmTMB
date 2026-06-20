# Predictor-dependent residual correlation rho12 ~ x: fixed-effect Wald coverage,
# rendered with the maintainer-requested Confidence Eye grammar (vertical lens =
# Monte-Carlo compatibility interval for the coverage estimate; hollow point =
# coverage estimate; circle = intercept, triangle = slope). Built from the
# already-verified 500-replicate recovery artifact (no refit). Run from root.
root <- "."
source(file.path(root, "docs/dev-log/figure-audits/_coverage-eye-helper.R"))

src <- file.path(root,
  "docs/dev-log/simulation-artifacts/2026-06-20-rho12-predictor-recovery",
  "tables/rho12-recovery-summary.csv")
out_dir <- file.path(root, "docs/dev-log/figure-audits/2026-06-20-rho12-recovery")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

d <- utils::read.csv(src, stringsAsFactors = FALSE)
d$parameter <- ifelse(grepl("Intercept", d$target), "rho12 intercept", "rho12 slope (x)")
d$cov <- d$wald_coverage
d$base <- match(d$n, sort(unique(d$n)))             # n=300 -> 1, n=600 -> 2
d$xnum <- d$base + ifelse(d$parameter == "rho12 intercept", -0.2, 0.2)
d$gid <- paste(d$n, d$parameter)

pal <- c("rho12 intercept" = "#2c7fb8", "rho12 slope (x)" = "#d95f0e")
shp <- c("rho12 intercept" = 21, "rho12 slope (x)" = 24)
polys <- coverage_eye_polys(d, width = 0.13)

g <- coverage_eye_plot(
  d, polys, pal = pal, shapes = shp, ylim = c(0.88, 1.0),
  xbreaks = sort(unique(d$base)), xlabels = paste0("n = ", sort(unique(d$n)))
) +
  labs(
    title = "Residual correlation rho12 ~ x: fixed-effect Wald coverage",
    subtitle = "500 replicates per cell; engine = TMB (native). Confidence Eye spans +/- 1.96 cell MCSE.",
    x = NULL, y = "Empirical coverage of 95% Wald intervals",
    color = "Coefficient", fill = "Coefficient", shape = "Coefficient",
    caption = paste(
      "Solid line: nominal 0.95. Pale band: 0.93-0.97 reference region (not a pass/fail threshold).",
      "Eye half-width follows the quadratic log-likelihood profile; it spans +/- 1.96 cell MCSE (the eye is MC uncertainty on coverage, not model uncertainty).",
      "Bivariate Gaussian, fixed-effect residual rho12 ~ x; truth b0 = 0.4, b1 = 0.5; near-unbiased (max |bias| 0.0113).",
      "The rho12 slope at n=300 sits at the lower band edge (0.920) and recovers to 0.956 at n=600.",
      "Source: 2026-06-20-rho12-predictor-recovery artifact (no refit).",
      sep = "\n"
    )
  )

out_png <- file.path(out_dir, "rho12-recovery-coverage-eye-v5.png")
ggsave(out_png, g, width = 8.0, height = 4.8, dpi = 144)
cat("wrote", out_png, " rows:", nrow(d), " polys:", nrow(polys), "\nDONE\n")
