#!/usr/bin/env Rscript

# Lane C C1 only: local retained point-recovery receipt for labelled NB2
# phylogenetic intercept--slope covariance. This is not a coverage, interval,
# profile, bootstrap, capability-ledger, or dashboard workflow.

write_tsv <- function(x, path) {
  utils::write.table(
    x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA"
  )
}

clean_text <- function(x) {
  x <- paste(as.character(x), collapse = "; ")
  x <- gsub("[\r\n\t]+", " ", x)
  trimws(gsub(" +", " ", x))
}

balanced_tree <- function(n_tip = 64L) {
  stopifnot(n_tip > 1L, n_tip == 2L^round(log2(n_tip)))
  edges <- matrix(integer(), ncol = 2L)
  lengths <- numeric()
  next_node <- n_tip + 1L
  build <- function(tips) {
    if (length(tips) == 1L) return(tips)
    node <- next_node
    next_node <<- next_node + 1L
    half <- length(tips) / 2L
    left <- build(tips[seq_len(half)])
    right <- build(tips[seq.int(half + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    lengths <<- c(lengths, 1, 1)
    node
  }
  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = lengths,
      tip.label = paste0("species_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

new_c1_data <- function(seed, n_tip = 64L, n_each = 8L) {
  set.seed(seed)
  tree <- balanced_tree(n_tip)
  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  x <- x - ave(x, species, FUN = mean)
  x <- x / stats::sd(x)
  beta <- c(`(Intercept)` = 1.00, x = 0.35)
  tau <- c(intercept = 0.60, slope = 0.50)
  rho <- 0.50
  sigma <- 0.50
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  K <- K[tree$tip.label, tree$tip.label]
  Sigma <- diag(tau) %*% matrix(c(1, rho, rho, 1), 2L) %*% diag(tau)
  field <- t(chol(K + diag(1e-10, n_tip))) %*%
    matrix(stats::rnorm(2L * n_tip), nrow = n_tip) %*% chol(Sigma)
  rownames(field) <- tree$tip.label
  eta <- beta[[1L]] + beta[[2L]] * x +
    field[species, 1L] + x * field[species, 2L]
  list(
    data = data.frame(
      count = stats::rnbinom(length(species), size = 1 / sigma^2, mu = exp(eta)),
      x = x,
      species = factor(species, levels = tree$tip.label)
    ),
    tree = tree,
    beta = beta,
    tau = tau,
    rho = rho,
    sigma = sigma
  )
}

result_template <- function(source_sha, attempt_id, seed) {
  data.frame(
    fixture_id = "lane_c_c1_nb2_phylo_q2_local",
    source_sha = source_sha,
    attempt_id = attempt_id,
    seed = seed,
    n_tip = 64L,
    n_each = 8L,
    n_obs = 512L,
    tree_type = "balanced_ultrametric_unit_branch",
    formula = "count ~ x + phylo(1 + x | p | species, tree = tree); sigma ~ 1",
    beta0_truth = 1.00,
    beta1_truth = 0.35,
    tau0_truth = 0.60,
    tau1_truth = 0.50,
    rho_truth = 0.50,
    sigma_truth = 0.50,
    fit_status = NA_character_,
    error_stage = NA_character_,
    warning = NA_character_,
    convergence = NA_integer_,
    pdHess = NA,
    objective = NA_real_,
    max_gradient = NA_real_,
    boundary_hit = NA,
    beta0_hat = NA_real_,
    beta1_hat = NA_real_,
    tau0_hat = NA_real_,
    tau1_hat = NA_real_,
    rho_hat = NA_real_,
    sigma_hat = NA_real_,
    elapsed_sec = NA_real_,
    stringsAsFactors = FALSE
  )
}

run_one <- function(source_sha, attempt_id, seed) {
  out <- result_template(source_sha, attempt_id, seed)
  warnings <- character()
  sim <- tryCatch(new_c1_data(seed), error = identity)
  if (inherits(sim, "error")) {
    out$fit_status <- "fit_error"
    out$error_stage <- "dgp"
    out$warning <- clean_text(conditionMessage(sim))
    return(out)
  }
  tree <- sim$tree
  elapsed <- system.time({
    fit <- tryCatch(
      withCallingHandlers(
        drmTMB::drmTMB(
          drmTMB::bf(
            count ~ x + phylo(1 + x | p | species, tree = tree),
            sigma ~ 1
          ),
          family = drmTMB::nbinom2(),
          data = sim$data,
          control = list(eval.max = 800, iter.max = 800)
        ),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = identity
    )
  })
  out$elapsed_sec <- unname(elapsed[["elapsed"]])
  if (inherits(fit, "error")) {
    out$fit_status <- "fit_error"
    out$error_stage <- "fit"
    out$warning <- clean_text(c(warnings, conditionMessage(fit)))
    return(out)
  }
  sd_mu <- fit$sdpars$mu
  cor_mu <- fit$corpars$phylo
  rho_name <- "cor(mu:(Intercept),mu:x | p | species)"
  gradient <- tryCatch(fit$obj$gr(fit$opt$par), error = function(e) NA_real_)
  out$fit_status <- "fit_ok"
  out$error_stage <- "none"
  out$warning <- clean_text(warnings)
  out$convergence <- fit$opt$convergence
  out$pdHess <- isTRUE(fit$sdr$pdHess)
  out$objective <- unname(fit$opt$objective)
  out$max_gradient <- if (all(is.finite(gradient))) max(abs(gradient)) else NA_real_
  out$beta0_hat <- unname(fit$coefficients$mu[["(Intercept)"]])
  out$beta1_hat <- unname(fit$coefficients$mu[["x"]])
  out$tau0_hat <- unname(sd_mu[["phylo(1 | p | species)"]])
  out$tau1_hat <- unname(sd_mu[["phylo(0 + x | p | species)"]])
  out$rho_hat <- unname(cor_mu[[rho_name]])
  out$sigma_hat <- unname(stats::sigma(fit)[[1L]])
  finite <- all(is.finite(unlist(out[c(
    "beta0_hat", "beta1_hat", "tau0_hat", "tau1_hat", "rho_hat", "sigma_hat"
  )])))
  out$boundary_hit <- !finite || abs(out$rho_hat) >= 0.95 ||
    any(unlist(out[c("tau0_hat", "tau1_hat", "sigma_hat")]) <= 0.05)
  out
}

summarise_attempts <- function(attempts) {
  valid <- attempts$fit_status == "fit_ok" & attempts$convergence == 0L &
    attempts$pdHess & !attempts$boundary_hit &
    stats::complete.cases(attempts[, c(
      "beta0_hat", "beta1_hat", "tau0_hat", "tau1_hat", "rho_hat", "sigma_hat"
    )])
  means <- colMeans(attempts[valid, c(
    "beta0_hat", "beta1_hat", "tau0_hat", "tau1_hat", "rho_hat", "sigma_hat"
  ), drop = FALSE])
  pass <- length(valid) == 3L && all(valid) &&
    abs(means[["beta0_hat"]] - 1.00) <= 0.20 &&
    abs(means[["beta1_hat"]] - 0.35) <= 0.20 &&
    abs(means[["sigma_hat"]] / 0.50 - 1) <= 0.40 &&
    abs(means[["tau0_hat"]] / 0.60 - 1) <= 0.40 &&
    abs(means[["tau1_hat"]] / 0.50 - 1) <= 0.40 &&
    abs(means[["rho_hat"]] - 0.50) <= 0.25
  data.frame(
    fixture_id = "lane_c_c1_nb2_phylo_q2_local",
    planned_attempts = 3L,
    attempted_attempts = nrow(attempts),
    fit_ok = sum(attempts$fit_status == "fit_ok"),
    fit_error = sum(attempts$fit_status == "fit_error"),
    nonconverged = sum(attempts$fit_status == "fit_ok" & attempts$convergence != 0L),
    pdhess_false = sum(attempts$fit_status == "fit_ok" & !attempts$pdHess),
    boundary_hits = sum(attempts$fit_status == "fit_ok" & attempts$boundary_hit),
    mean_beta0_hat = means[["beta0_hat"]],
    mean_beta1_hat = means[["beta1_hat"]],
    mean_tau0_hat = means[["tau0_hat"]],
    mean_tau1_hat = means[["tau1_hat"]],
    mean_rho_hat = means[["rho_hat"]],
    mean_sigma_hat = means[["sigma_hat"]],
    decision = if (pass) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE",
    stringsAsFactors = FALSE
  )
}

script <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script <- sub("^--file=", "", script[[1L]])
repo_root <- normalizePath(file.path(dirname(script), ".."))
setwd(repo_root)
pkgload::load_all(repo_root, quiet = TRUE, export_all = FALSE)
artifact_dir <- file.path(
  repo_root, "docs", "dev-log", "implementation-recovery",
  "2026-07-28-lane-c-c1-nb2-phylo-q2-local"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
source_head <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
dirty <- length(system2("git", c("status", "--porcelain"), stdout = TRUE)) > 0L
source_sha <- paste0(source_head, if (dirty) "-dirty" else "")
attempt_path <- file.path(artifact_dir, "raw-attempts.tsv")
summary_path <- file.path(artifact_dir, "summary.tsv")
seeds <- 2026072801:2026072803
attempts <- vector("list", length(seeds))
for (i in seq_along(seeds)) {
  attempts[[i]] <- run_one(source_sha, i, seeds[[i]])
  write_tsv(do.call(rbind, attempts[seq_len(i)]), attempt_path)
}
attempts <- do.call(rbind, attempts)
write_tsv(attempts, attempt_path)
write_tsv(summarise_attempts(attempts), summary_path)
message("Wrote retained local C1 receipt: ", artifact_dir)
