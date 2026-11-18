devtools::load_all(quiet = TRUE)

set.seed(20261021)
n_tip <- 60L
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
dat <- data.frame(
  y = stats::rbinom(length(index), 1L, stats::plogis(0.2 + tau[index] * u[index])),
  species = factor(tree$tip.label[index], levels = tree$tip.label),
  z = unname(z0[index])
)

fit <- drmTMB(
  bf(
    y ~ phylo(1 | species, tree = tree),
    sd(species, level = "phylogenetic") ~ z
  ),
  family = stats::binomial(),
  data = dat,
  control = drm_control(se = FALSE)
)
targets <- profile_targets(fit)
target <- targets$parm[
  grepl("sd_phylo", targets$parm) & grepl("z", targets$parm)
]
stopifnot(length(target) == 1L)

profile_interval <- confint(
  fit,
  parm = target,
  method = "profile",
  profile_precision = "fast"
)

cat("tips:", n_tip, "observations per tip:", n_each, "\n")
cat("true coefficients:", alpha, "\n")
cat("estimated coefficients:\n")
print(coef(fit, "sd_phylo(species)"))
cat("log-SD clamp band:\n")
print(drmTMB:::drm_profile_direct_sd_clamp_band(fit))
cat("profile interval:\n")
print(profile_interval)
