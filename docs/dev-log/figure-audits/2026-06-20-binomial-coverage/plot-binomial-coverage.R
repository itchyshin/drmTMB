# Binomial fixed-effect interval-coverage figure (Wald + profile).
# Honest coverage display: hollow point = coverage rate per audited cell, error
# bar = +/- 1.96 * Monte-Carlo SE (sampling uncertainty on the coverage estimate),
# solid line = nominal 0.95, pale band = 0.93-0.97 reference region. Reads the
# banked 500-replicate artifacts; no refit. Run from the drmTMB package root.
suppressMessages(library(ggplot2))

root <- "."
wald_path <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-17-binomial-fe-interval-calibration",
  "tables/binomial-fe-wald-coverage.csv"
)
prof_path <- file.path(
  root,
  "docs/dev-log/simulation-artifacts/2026-06-20-binomial-fe-profile-calibration",
  "tables/profile-coverage-summary.csv"
)
out_dir <- file.path(root, "docs/dev-log/figure-audits/2026-06-20-binomial-coverage")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

tidy_param <- function(x) {
  ifelse(grepl("Intercept", x), "Intercept", "Slope (x)")
}

w <- utils::read.csv(wald_path, stringsAsFactors = FALSE)
wald <- data.frame(
  method = "Wald",
  encoding = ifelse(w$encoding == "cbind", "cbind()", "0/1 binary"),
  label = paste0("cell ", sub("binomial_fixed_effect_0*", "", w$cell_id)),
  parameter = tidy_param(w$parameter),
  coverage = w$coverage,
  mcse = w$coverage_mcse,
  stringsAsFactors = FALSE
)

p <- utils::read.csv(prof_path, stringsAsFactors = FALSE)
prof <- data.frame(
  method = "Profile",
  encoding = ifelse(p$encoding == "cbind", "cbind()", "0/1 binary"),
  label = paste0("n = ", p$n),
  parameter = tidy_param(p$target),
  coverage = p$coverage,
  mcse = p$mcse,
  stringsAsFactors = FALSE
)

dat <- rbind(wald, prof)
dat$method <- factor(dat$method, levels = c("Wald", "Profile"))
dat$encoding <- factor(dat$encoding, levels = c("0/1 binary", "cbind()"))
dat$cell <- dat$label

gg <- ggplot(dat, aes(x = cell, y = coverage, color = parameter, shape = parameter)) +
  annotate("rect",
    xmin = -Inf, xmax = Inf, ymin = 0.93, ymax = 0.97,
    fill = "grey80", alpha = 0.45
  ) +
  geom_hline(yintercept = 0.95, linewidth = 0.5, color = "grey30") +
  geom_errorbar(
    aes(ymin = coverage - 1.96 * mcse, ymax = coverage + 1.96 * mcse),
    width = 0.25, linewidth = 0.6,
    position = position_dodge(width = 0.5)
  ) +
  geom_point(
    fill = "white", size = 2.8, stroke = 1.0,
    position = position_dodge(width = 0.5)
  ) +
  facet_grid(encoding ~ method, scales = "free_x", space = "free_x") +
  scale_color_manual(values = c("Intercept" = "#2c7fb8", "Slope (x)" = "#d95f0e")) +
  scale_shape_manual(values = c("Intercept" = 21, "Slope (x)" = 24)) +
  coord_cartesian(ylim = c(0.90, 1.0)) +
  labs(
    title = "Binomial fixed-effect interval coverage clusters around the nominal 0.95",
    subtitle = "500 replicates per cell; engine = TMB (native). Point = coverage rate, bar = +/- 1.96 cell-specific MCSE.",
    x = NULL,
    y = "Empirical coverage of 95% intervals",
    color = "Coefficient",
    shape = "Coefficient",
    caption = paste(
      "Solid line: nominal 0.95. Pale band: 0.93-0.97 reference region (not a pass/fail threshold).",
      "Rows: response encoding. Columns: interval method. Wald cells span the design grid",
      "encoding x n in {240, 480} x trials-per-obs (cbind: 8, 20); profile cells span n in {240, 480}.",
      "The two method columns use related but distinct design grids and are not point-for-point comparable.",
      "Source: 2026-06-17 Wald + 2026-06-20 profile calibration artifacts (no refit).",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(size = 9),
    strip.text = element_text(face = "bold"),
    plot.caption = element_text(hjust = 0, color = "grey40", size = 8)
  )

out_png <- file.path(out_dir, "binomial-coverage-wald-profile-v3.png")
ggsave(out_png, gg, width = 8.5, height = 5.6, dpi = 144)
cat("wrote", out_png, "\n")
cat("rows:", nrow(dat), " wald:", sum(dat$method == "Wald"),
    " profile:", sum(dat$method == "Profile"), "\n")
cat("coverage range:", format(range(dat$coverage)), "\n")
cat("DONE\n")
