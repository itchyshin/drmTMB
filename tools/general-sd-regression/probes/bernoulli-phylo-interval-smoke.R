devtools::load_all(quiet = TRUE)

set.seed(20261020)
n_tip <- 16L
n_each <- 12L
tree <- ape::rcoal(n_tip)
tree$tip.label <- paste0("sp", seq_len(n_tip))
A <- drmTMB:::drm_phylo_tip_covariance(tree)
z0 <- as.numeric(scale(stats::rnorm(n_tip)))
names(z0) <- tree$tip.label
tau <- exp(log(0.35) + 0.45 * z0)
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
  control = drm_control(se = FALSE, keep_data = TRUE)
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
stopifnot(
  identical(profile_interval$conf.status, "clamp_limited"),
  isTRUE(profile_interval$profile.boundary),
  all(is.na(profile_interval[c("lower", "upper")]))
)

bootstrap_interval <- confint(
  fit,
  parm = target,
  method = "bootstrap",
  R = 2L,
  seed = 20261020L,
  parallel = "none",
  refit_control = drm_control(se = FALSE)
)
stopifnot(
  bootstrap_interval$bootstrap.n == 2L,
  bootstrap_interval$bootstrap.failed == 0L,
  is.finite(bootstrap_interval$lower),
  is.finite(bootstrap_interval$upper)
)

print(profile_interval)
print(bootstrap_interval)
