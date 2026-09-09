phylo_temporal_ou_oracle_fixture <- function(seed = 202609092L) {
  set.seed(seed)
  tree <- ape::rcoal(12L)
  tree$tip.label <- sprintf("sp_%02d", seq_len(ape::Ntip(tree)))
  schedules <- lapply(seq_along(tree$tip.label), function(i) {
    if (i %% 2L) c(0, 0.5, 2, 5, 9) else c(0, 1, 3, 6)
  })
  data <- do.call(rbind, Map(function(species, elapsed) {
    data.frame(species = species, elapsed = elapsed)
  }, tree$tip.label, schedules))
  data$x <- stats::rnorm(nrow(data))
  beta <- c(0.25, 0.45)
  sd_phylo <- 0.60
  sd_temporal <- 0.75
  sigma <- 0.40
  decay <- 0.45
  A <- ape::vcv(tree, corr = TRUE)[tree$tip.label, tree$tip.label, drop = FALSE]
  stable <- as.vector(t(chol(A)) %*% stats::rnorm(nrow(A))) * sd_phylo
  names(stable) <- tree$tip.label
  data$y <- NA_real_
  for (species in tree$tip.label) {
    rows <- which(data$species == species)
    time <- data$elapsed[rows]
    R <- exp(-decay * abs(outer(time, time, "-")))
    temporal <- as.vector(t(chol(R)) %*% stats::rnorm(length(rows))) * sd_temporal
    data$y[rows] <- beta[[1L]] + beta[[2L]] * data$x[rows] + stable[[species]] +
      temporal + stats::rnorm(length(rows), sd = sigma)
  }
  list(tree = tree, data = data[sample.int(nrow(data)), , drop = FALSE])
}

phylo_temporal_ou_dense_covariance <- function(
  species, elapsed, A, sd_phylo, sd_temporal, sigma, decay
) {
  stable <- sd_phylo^2 * A[species, species, drop = FALSE]
  same_species <- outer(species, species, `==`)
  temporal <- sd_temporal^2 * same_species * exp(-decay * abs(outer(elapsed, elapsed, "-")))
  stable + temporal + diag(sigma^2, length(species))
}

phylo_temporal_ou_dense_nll_at <- function(fit, par, tree) {
  names_par <- names(par)
  beta <- unname(par[names_par == "beta_mu"])
  sigma <- exp(unname(par[match("beta_sigma", names_par)]))
  sd_temporal <- exp(unname(par[match("log_sd_temporal", names_par)]))
  decay <- exp(unname(par[match("theta_temporal", names_par)]))
  sd_phylo <- exp(unname(par[match("log_sd_phylo", names_par)]))
  data <- fit$data
  phylo <- fit$model$structured$phylo_mu
  A <- ape::vcv(tree, corr = TRUE)
  species <- as.character(data[[phylo$group]])
  elapsed <- as.numeric(data[[fit$model$structured$temporal_mu$time]])
  V <- phylo_temporal_ou_dense_covariance(
    species, elapsed, A, sd_phylo, sd_temporal, sigma, decay
  )
  root <- chol(V)
  residual <- fit$model$y - as.vector(as.matrix(fit$model$X$mu) %*% beta)
  0.5 * (length(residual) * log(2 * pi) +
    2 * sum(log(diag(root))) + sum(forwardsolve(t(root), residual)^2))
}

phylo_temporal_ou_separable_covariance <- function(
  species, elapsed, A, sd_phylo, sd_temporal, sigma, decay
) {
  stable <- sd_phylo^2 * A[species, species, drop = FALSE]
  field <- sd_temporal^2 * A[species, species, drop = FALSE] *
    exp(-decay * abs(outer(elapsed, elapsed, "-")))
  stable + field + diag(sigma^2, length(species))
}
