devtools::load_all(quiet = TRUE)

set.seed(20261022)
n_tip <- 16L
n_each <- 100L
tree <- ape::rcoal(n_tip)
tree$tip.label <- paste0("sp", seq_len(n_tip))
A <- drmTMB:::drm_phylo_tip_covariance(tree)
z0 <- as.numeric(scale(stats::rnorm(n_tip)))
names(z0) <- tree$tip.label
alpha <- c(log(0.35), 0.45)
tau <- exp(alpha[[1L]] + alpha[[2L]] * z0)
u <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip))
index <- rep(seq_len(n_tip), each = n_each)
dat_full <- data.frame(
  y = stats::rbinom(length(index), 1L, stats::plogis(0.2 + tau[index] * u[index])),
  species = factor(tree$tip.label[index], levels = tree$tip.label),
  z = unname(z0[index])
)
low_rows <- unlist(lapply(seq_len(n_tip), function(i) {
  (i - 1L) * n_each + seq_len(12L)
}), use.names = FALSE)
dat_low <- dat_full[low_rows, , drop = FALSE]

fit_sd_profile <- function(data) {
  fit <- drmTMB(
    bf(
      y ~ phylo(1 | species, tree = tree),
      sd(species, level = "phylogenetic") ~ z
    ),
    family = stats::binomial(),
    data = data,
    control = drm_control(se = FALSE)
  )
  targets <- profile_targets(fit)
  target <- targets$parm[
    grepl("sd_phylo", targets$parm) & grepl("z", targets$parm)
  ]
  stopifnot(length(target) == 1L)
  interval <- confint(
    fit,
    parm = target,
    method = "profile",
    profile_precision = "fast"
  )
  list(fit = fit, interval = interval)
}

low <- fit_sd_profile(dat_low)
high <- fit_sd_profile(dat_full)

cat("Seed:", 20261022L, "tips:", n_tip, "\n")
cat("True SD coefficients:", alpha, "\n")
cat("12 observations per tip:\n")
print(coef(low$fit, "sd_phylo(species)"))
print(low$interval)
cat("100 observations per tip:\n")
print(coef(high$fit, "sd_phylo(species)"))
print(high$interval)
