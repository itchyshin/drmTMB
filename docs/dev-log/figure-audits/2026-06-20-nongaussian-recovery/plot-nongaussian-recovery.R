# Non-Gaussian fixed-effect mu recovery: Wald coverage across six one-response
# families, rendered with the maintainer-requested Confidence Eye grammar
# (vertical lens = Monte-Carlo compatibility interval for the coverage estimate;
# hollow circle = mu intercept, triangle = mu slope). Built from the already-
# verified 500-replicate recovery artifact (no refit). Run from the package root.
root <- "."
source(file.path(root, "docs/dev-log/figure-audits/_coverage-eye-helper.R"))

src <- file.path(root,
  "docs/dev-log/simulation-artifacts/2026-06-20-nongaussian-fe-recovery-calibration",
  "tables/nongaussian-fe-coverage-summary.csv")
out_dir <- file.path(root, "docs/dev-log/figure-audits/2026-06-20-nongaussian-recovery")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

d <- utils::read.csv(src, stringsAsFactors = FALSE)
d$parameter <- ifelse(grepl("Intercept", d$target), "mu intercept", "mu slope (x)")
d$cov <- d$wald_coverage
fam_levels <- c("poisson", "nbinom2", "Gamma", "lognormal", "beta", "student")
d$family <- factor(d$family, levels = fam_levels)
d$base <- match(d$n, sort(unique(d$n)))
d$xnum <- d$base + ifelse(d$parameter == "mu intercept", -0.2, 0.2)
d$gid <- paste(d$family, d$n, d$parameter)

pal <- c("mu intercept" = "#2c7fb8", "mu slope (x)" = "#d95f0e")
shp <- c("mu intercept" = 21, "mu slope (x)" = 24)
polys <- coverage_eye_polys(d, facets = "family", width = 0.13)
polys$family <- factor(polys$family, levels = fam_levels)

g <- coverage_eye_plot(
  d, polys, pal = pal, shapes = shp, facet = "family",
  xbreaks = sort(unique(d$base)), xlabels = paste0("n = ", sort(unique(d$n)))
) +
  labs(
    title = "Non-Gaussian fixed-effect mu recovery: Wald coverage clusters around 0.95",
    subtitle = "500 replicates per cell; engine = TMB (native); six families. Confidence Eye spans +/- 1.96 cell MCSE.",
    x = NULL, y = "Empirical coverage of 95% Wald intervals",
    color = "Coefficient", fill = "Coefficient", shape = "Coefficient",
    caption = paste(
      "Solid line: nominal 0.95. Pale band: 0.93-0.97 reference region (not a pass/fail threshold).",
      "Eye half-width follows the quadratic log-likelihood profile (MC uncertainty on coverage, not model uncertainty).",
      "Near-unbiased recovery across all six families (max |bias| 0.0052; pdHess >= 0.996).",
      "The student n=300 mu:x cell (0.926) sits just below the band and recovers to 0.952 at n=600.",
      "Source: 2026-06-20-nongaussian-fe-recovery-calibration artifact (no refit).",
      sep = "\n"
    )
  )

out_png <- file.path(out_dir, "nongaussian-recovery-coverage-eye-v3.png")
ggsave(out_png, g, width = 9.2, height = 5.8, dpi = 144)
cat("wrote", out_png, " rows:", nrow(d), " polys:", nrow(polys), "\nDONE\n")
