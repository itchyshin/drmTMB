# Binomial fixed-effect interval coverage (Wald + profile), rendered with the
# maintainer-requested Confidence Eye grammar (vertical lens = Monte-Carlo
# compatibility interval for the coverage estimate; hollow circle = intercept,
# triangle = slope). Built from the already-verified 500-replicate artifacts (no
# refit). Global numeric x with facet_grid(scales="free_x") so each panel clips to
# its own cells. Run from the package root.
root <- "."
source(file.path(root, "docs/dev-log/figure-audits/_coverage-eye-helper.R"))

wald_path <- file.path(root,
  "docs/dev-log/simulation-artifacts/2026-06-17-binomial-fe-interval-calibration",
  "tables/binomial-fe-wald-coverage.csv")
prof_path <- file.path(root,
  "docs/dev-log/simulation-artifacts/2026-06-20-binomial-fe-profile-calibration",
  "tables/profile-coverage-summary.csv")
out_dir <- file.path(root, "docs/dev-log/figure-audits/2026-06-20-binomial-coverage")

tidy_param <- function(x) ifelse(grepl("Intercept", x), "Intercept", "Slope (x)")
enc <- function(x) ifelse(x == "cbind", "cbind()", "0/1 binary")

w <- utils::read.csv(wald_path, stringsAsFactors = FALSE)
wald <- data.frame(
  method = "Wald", encoding = enc(w$encoding),
  xbase = as.integer(sub("binomial_fixed_effect_0*", "", w$cell_id)),  # 1..6
  xlab = paste0("cell ", as.integer(sub("binomial_fixed_effect_0*", "", w$cell_id))),
  parameter = tidy_param(w$parameter), cov = w$coverage, mcse = w$coverage_mcse,
  stringsAsFactors = FALSE)

p <- utils::read.csv(prof_path, stringsAsFactors = FALSE)
prof <- data.frame(
  method = "Profile", encoding = enc(p$encoding),
  xbase = ifelse(p$n == 240, 8L, 9L),   # offset past the 6 Wald cells
  xlab = paste0("n = ", p$n),
  parameter = tidy_param(p$target), cov = p$coverage, mcse = p$mcse,
  stringsAsFactors = FALSE)

d <- rbind(wald, prof)
d$method <- factor(d$method, levels = c("Wald", "Profile"))
d$encoding <- factor(d$encoding, levels = c("0/1 binary", "cbind()"))
d$xnum <- d$xbase + ifelse(d$parameter == "Intercept", -0.18, 0.18)
d$gid <- paste(d$method, d$encoding, d$xbase, d$parameter)

pal <- c("Intercept" = "#2c7fb8", "Slope (x)" = "#d95f0e")
shp <- c("Intercept" = 21, "Slope (x)" = 24)
polys <- coverage_eye_polys(d, facets = c("method", "encoding"), width = 0.16)
polys$method <- factor(polys$method, levels = c("Wald", "Profile"))
polys$encoding <- factor(polys$encoding, levels = c("0/1 binary", "cbind()"))

xb <- sort(unique(d$xbase)); xl <- d$xlab[match(xb, d$xbase)]

g <- ggplot() +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0.93, ymax = 0.97,
    fill = "grey80", alpha = 0.45) +
  geom_hline(yintercept = 0.95, linewidth = 0.5, color = "grey30") +
  geom_polygon(data = polys,
    aes(x = px, y = py, group = gid, fill = parameter, color = parameter),
    alpha = 0.32, linewidth = 0.4, show.legend = FALSE) +
  geom_point(data = d, aes(x = xnum, y = cov, shape = parameter, color = parameter),
    fill = "white", size = 2.5, stroke = 0.95) +
  facet_grid(encoding ~ method, scales = "free_x", space = "free_x") +
  scale_fill_manual(values = pal) + scale_color_manual(values = pal) +
  scale_shape_manual(values = shp) +
  scale_x_continuous(breaks = xb, labels = xl) +
  coord_cartesian(ylim = c(0.90, 1.0)) +
  labs(
    title = "Binomial fixed-effect interval coverage clusters around the nominal 0.95",
    subtitle = "500 replicates per cell; engine = TMB (native). Confidence Eye spans +/- 1.96 cell MCSE.",
    x = NULL, y = "Empirical coverage of 95% intervals",
    color = "Coefficient", fill = "Coefficient", shape = "Coefficient",
    caption = paste(
      "Solid line: nominal 0.95. Pale band: 0.93-0.97 reference region (not a pass/fail threshold).",
      "Eye half-width follows the quadratic log-likelihood profile (MC uncertainty on coverage, not model uncertainty).",
      "Rows: response encoding. Columns: interval method. Wald cells span encoding x n {240,480} x trials-per-obs (cbind: 8,20); profile cells span n {240,480}.",
      "The two method columns use related but distinct design grids and are not point-for-point comparable.",
      "Source: 2026-06-17 Wald + 2026-06-20 profile calibration artifacts (no refit).",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top", panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(), strip.text = element_text(face = "bold"),
    axis.text.x = element_text(size = 8.5),
    plot.caption = element_text(hjust = 0, color = "grey40", size = 8))

out_png <- file.path(out_dir, "binomial-coverage-eye-v5.png")
ggsave(out_png, g, width = 9.2, height = 5.8, dpi = 144)
cat("wrote", out_png, " rows:", nrow(d), " polys:", nrow(polys), "\nDONE\n")
