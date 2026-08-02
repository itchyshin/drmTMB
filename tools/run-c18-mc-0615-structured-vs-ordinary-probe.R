suppressMessages(devtools::load_all(quiet = TRUE))

# Same DGP as tools/run-lane-c-c18-zob-relmat-coi-q1-local-recovery.R
new_data <- function(seed, n_group = 32L, n_each = 50L, tau = .55,
                     zoi_truth = .5, coi_truth = .5,
                     mu0 = -.15, mu1 = .35, log_sigma = -1) {
  set.seed(seed)
  labels <- paste0("sp", seq_len(n_group))
  Q <- diag(2, n_group)
  Q[cbind(seq_len(n_group - 1L), 2:n_group)] <- -.5
  Q[cbind(2:n_group, seq_len(n_group - 1L))] <- -.5
  rownames(Q) <- colnames(Q) <- rev(labels)
  K <- solve(Q)
  field <- as.numeric(t(chol(K)) %*% rnorm(n_group, sd = tau))
  names(field) <- rownames(K)
  species <- factor(rep(labels, each = n_each), levels = labels)
  x <- rnorm(n_group * n_each)
  mu <- plogis(mu0 + mu1 * x); sigma <- exp(log_sigma)
  coi_full <- plogis(qlogis(coi_truth) + field[as.character(species)])
  boundary <- rbinom(length(species), 1L, zoi_truth)
  y <- rbeta(length(species), mu / sigma^2, (1 - mu) / sigma^2)
  y[boundary == 1L] <- rbinom(sum(boundary), 1L, coi_full[boundary == 1L])
  list(data = data.frame(y, x, species), K = K, field = field, tau = tau)
}

fit_one <- function(sim, structured) {
  K <- sim$K
  f <- if (structured) {
    bf(y ~ x, sigma ~ 1, coi ~ drmTMB::relmat(1 | species, K = K), zoi ~ 1)
  } else {
    bf(y ~ x, sigma ~ 1, coi ~ 1 + (1 | species), zoi ~ 1)
  }
  fit <- tryCatch(
    drmTMB(f, family = zero_one_beta(), data = sim$data,
           control = drm_control(se = FALSE)),
    error = identity
  )
  if (inherits(fit, "error")) return(list(ok = FALSE, tau_hat = NA_real_, err = conditionMessage(fit)))
  tau_hat <- tryCatch(unname(unlist(fit$sdpars$coi))[1], error = function(e) NA_real_)
  list(ok = TRUE, conv = fit$opt$convergence, tau_hat = tau_hat, err = "")
}

seeds <- 2026080621:2026080640
cat(sprintf("%-12s %-22s %-22s %s\n", "seed", "STRUCTURED relmat", "ORDINARY (1|species)", "note"))
res <- list()
for (s in seeds) {
  sim <- new_data(s)
  a <- fit_one(sim, TRUE)
  b <- fit_one(sim, FALSE)
  coll_a <- isTRUE(a$ok) && !is.na(a$tau_hat) && a$tau_hat < .05
  coll_b <- isTRUE(b$ok) && !is.na(b$tau_hat) && b$tau_hat < .05
  note <- if (coll_a && !coll_b) "STRUCTURED-ONLY COLLAPSE" else if (coll_a && coll_b) "both collapsed" else if (!coll_a && coll_b) "ordinary-only collapse" else ""
  cat(sprintf("%-12s %-22s %-22s %s\n", s,
              sprintf("tau=%.5f%s", a$tau_hat, if (coll_a) " *" else ""),
              sprintf("tau=%.5f%s", b$tau_hat, if (coll_b) " *" else ""), note))
  res[[length(res) + 1]] <- data.frame(seed = s, tau_struct = a$tau_hat, tau_ord = b$tau_hat,
                                       coll_struct = coll_a, coll_ord = coll_b)
}
r <- do.call(rbind, res)
cat("\n=== SUMMARY over", nrow(r), "seeds (truth tau = 0.55, collapse = tau_hat < 0.05) ===\n")
cat(sprintf("  structured relmat collapses : %d / %d\n", sum(r$coll_struct), nrow(r)))
cat(sprintf("  ordinary (1|species) collapses: %d / %d\n", sum(r$coll_ord), nrow(r)))
cat(sprintf("  structured-ONLY collapses     : %d  <- nonzero implies a structured-path problem\n",
            sum(r$coll_struct & !r$coll_ord)))
cat(sprintf("  median tau_hat structured=%.4f  ordinary=%.4f\n",
            median(r$tau_struct, na.rm = TRUE), median(r$tau_ord, na.rm = TRUE)))
saveRDS(r, "/tmp/f5/relmat_probe.rds")
