# Gaussian correlated random-slope recovery: relative bias of the fixed effects,
# the random-effect SDs, and residual sigma across a group-count ladder, built from
# the already-verified 500-replicate recovery artifact (no refit). This is the
# repo's default recovery grammar (dots + Monte-Carlo error bars + a zero target
# line), NOT a Confidence Eye -- the promoted claim is POINT recovery + RE-SD
# CONSISTENCY (the SD bias shrinks toward zero as groups grow), not interval
# coverage. Run from the package root.
suppressMessages(library(ggplot2))
root <- "."
src <- file.path(root,
  "docs/dev-log/simulation-artifacts/2026-06-20-gaussian-random-slope-recovery",
  "tables/random-slope-recovery-summary.csv")
out_dir <- file.path(root, "docs/dev-log/figure-audits/2026-06-20-random-slope-recovery")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

d <- utils::read.csv(src, stringsAsFactors = FALSE)
# Monte-Carlo uncertainty on the mean estimate (rmse ~ sd for small bias), on the
# relative-bias scale: 1.96 * (rmse / sqrt(n_used)) / |truth|.
d$relbias_pct <- 100 * d$rel_bias
d$mc_pct <- 100 * 1.96 * (d$rmse / sqrt(d$n_used)) / abs(d$truth)

lab <- c(
  "fixef:mu:(Intercept)" = "mu intercept",
  "fixef:mu:x" = "mu slope (x)",
  "sd_int" = "SD(intercept)",
  "sd_slope" = "SD(slope)",
  "sigma" = "residual sigma"
)
d$parameter <- factor(lab[d$target], levels = unname(lab))
d$kind <- ifelse(grepl("^fixef", d$target), "fixed effect",
          ifelse(d$target == "sigma", "residual SD", "random-effect SD"))
d$group <- factor(paste0("n_group = ", d$n_group),
                  levels = c("n_group = 40", "n_group = 80"))

pal <- c("n_group = 40" = "#d95f0e", "n_group = 80" = "#2c7fb8")
pd <- position_dodge(width = 0.55)

g <- ggplot(d, aes(x = parameter, y = relbias_pct, color = group, group = group)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = -5, ymax = 5,
           fill = "grey85", alpha = 0.5) +
  geom_hline(yintercept = 0, linewidth = 0.5) +
  geom_errorbar(aes(ymin = relbias_pct - mc_pct, ymax = relbias_pct + mc_pct),
                width = 0.18, position = pd, linewidth = 0.5) +
  geom_point(size = 2.8, position = pd) +
  scale_color_manual(values = pal) +
  scale_y_continuous(breaks = seq(-7.5, 5, 2.5)) +
  labs(
    title = "Gaussian correlated random-slope recovery: fixed effects unbiased; RE SDs consistent",
    subtitle = "bf(y ~ x + (1 + x | id), sigma ~ 1); 500 replicates/cell; engine = TMB (native); 0 errors, pdHess 1.000.",
    x = NULL, y = "Relative bias (%)", color = NULL,
    caption = paste(
      "Dots: mean relative bias; bars: +/- 1.96 Monte-Carlo SE on the mean (not model uncertainty).",
      "Grey band: +/- 5% reference (not a pass/fail threshold). Zero line = unbiased.",
      "Fixed effects near-unbiased at both group counts; the random-effect SDs carry the expected ML",
      "small-sample downward bias that SHRINKS with groups (SD(slope) -6.7% at 40 -> -1.1% at 80).",
      "POINT recovery only: rho not validated; RE-SD interval calibration not claimed; Wald stays",
      "partial (n_group=40 slope coverage 0.922). Source: 2026-06-20-gaussian-random-slope-recovery (no refit).",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.caption = element_text(hjust = 0, size = 8),
        panel.grid.major.x = element_blank())

out_png <- file.path(out_dir, "random-slope-recovery-bias-v1.png")
ggsave(out_png, g, width = 9.2, height = 5.6, dpi = 144)
cat("wrote", out_png, " rows:", nrow(d), "\nDONE\n")
