devtools::load_all(quiet = TRUE)

set.seed(20261021)
n_tip <- 60L
n_each <- 100L
tree_full <- ape::rcoal(n_tip)
tree_full$tip.label <- paste0("sp", seq_len(n_tip))
A_full <- drmTMB:::drm_phylo_tip_covariance(tree_full)
z0 <- as.numeric(scale(stats::rnorm(n_tip)))
names(z0) <- tree_full$tip.label
alpha <- c(log(0.35), 0.45)
tau <- exp(alpha[[1L]] + alpha[[2L]] * z0)
u <- as.vector(t(chol(A_full)) %*% stats::rnorm(n_tip))
index <- rep(seq_len(n_tip), each = n_each)
dat_full <- data.frame(
  y = stats::rbinom(length(index), 1L, stats::plogis(0.2 + tau[index] * u[index])),
  species = factor(tree_full$tip.label[index], levels = tree_full$tip.label),
  z = unname(z0[index])
)

low_labels <- tree_full$tip.label[seq_len(16L)]
tree_low <- ape::keep.tip(tree_full, low_labels)
A_low <- drmTMB:::drm_phylo_tip_covariance(tree_low)
covariance_delta <- max(abs(A_low - A_full[low_labels, low_labels]))
stopifnot(covariance_delta < 1e-8)
dat_low <- droplevels(dat_full[dat_full$species %in% low_labels, , drop = FALSE])

fit_sd_profile <- function(data, tree) {
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

low <- fit_sd_profile(dat_low, tree_low)
full <- fit_sd_profile(dat_full, tree_full)

cat("Seed:", 20261021L, "observations per retained tip:", n_each, "\n")
cat("Truth:", alpha, "\n")
cat("Pruned tree covariance max delta:", covariance_delta, "\n")
cat("16 tips:\n")
print(coef(low$fit, "sd_phylo(species)"))
print(low$interval)
cat("60 tips:\n")
print(coef(full$fit, "sd_phylo(species)"))
print(full$interval)
