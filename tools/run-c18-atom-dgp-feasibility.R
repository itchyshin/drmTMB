#!/usr/bin/env Rscript
#
# C18: atom (zoi/coi) structured-field DGP feasibility sweep.
#
# Question: is a group-level latent SD on zoi or coi identifiable, when the
# group structure is generated from a phylogenetic field but FIT with the
# already-working ordinary `(1 | species)` route? This measures whether
# group-level atom information suffices at all, ahead of writing any new
# structured-random-effect code for zoi/coi.
#
# Modes (set via C18_MODE env var): "smoke" (default), "time", "shard",
# "assemble". Streaming discipline: every fit's row is appended to its output
# file and flushed immediately; nothing is batch-written after a loop.

write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE)
}

append_row <- function(row, path) {
  first <- !file.exists(path)
  utils::write.table(
    row, path, sep = "\t", quote = FALSE, row.names = FALSE,
    col.names = first, append = !first
  )
}

utc_now <- function() format(Sys.time(), tz = "UTC", usetz = TRUE)

git_output <- function(args) {
  trimws(system2("git", args, stdout = TRUE, stderr = TRUE))
}

git_blob <- function(path) {
  value <- git_output(c("hash-object", path))
  if (length(value) != 1L || !nzchar(value)) return(NA_character_)
  value
}

sha256_file <- function(path) {
  value <- trimws(system2("shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE))
  if (length(value) != 1L || !nzchar(value)) return(NA_character_)
  strsplit(value, "[[:space:]]+")[[1L]][[1L]]
}

# ---- DGP -------------------------------------------------------------------

simulate_atom_field <- function(
  seed, atom, zoi, coi, n_each, tau, n_tip,
  mu0 = -0.15, mu1 = 0.35, log_sigma = -1
) {
  set.seed(seed)
  tree <- ape::stree(n_tip, type = "balanced")
  tree$edge.length <- rep(1, nrow(tree$edge))
  tree$tip.label <- paste0("sp", seq_len(n_tip))
  V <- drmTMB:::drm_phylo_tip_covariance(tree)
  field <- as.numeric(t(chol(V)) %*% rnorm(n_tip, sd = tau))
  names(field) <- tree$tip.label

  species <- factor(rep(tree$tip.label, each = n_each), levels = tree$tip.label)
  x <- rnorm(length(species))
  mu <- plogis(mu0 + mu1 * x)
  sigma <- exp(log_sigma)

  if (atom == "zoi") {
    zoi_full <- plogis(qlogis(zoi) + field[as.character(species)])
    coi_full <- rep(coi, length(species))
  } else {
    zoi_full <- rep(zoi, length(species))
    coi_full <- plogis(qlogis(coi) + field[as.character(species)])
  }

  boundary <- rbinom(length(species), 1L, zoi_full)
  y <- rbeta(length(species), mu / sigma^2, (1 - mu) / sigma^2)
  n_bd <- sum(boundary)
  if (n_bd > 0L) y[boundary == 1L] <- rbinom(n_bd, 1L, coi_full[boundary == 1L])

  list(
    data = data.frame(y = y, x = x, species = species),
    tree = tree, field = field, boundary = boundary
  )
}

group_diagnostics <- function(y, species, n_tip) {
  n_zero <- tabulate(as.integer(species[y == 0]), nbins = n_tip)
  n_one <- tabulate(as.integer(species[y == 1]), nbins = n_tip)
  n_boundary <- n_zero + n_one
  list(
    mean_boundary_group = mean(n_boundary),
    min_boundary_group = min(n_boundary),
    n_separated_groups = sum(n_zero == 0L | n_one == 0L)
  )
}

# ---- fit one cell -----------------------------------------------------------

run_cell <- function(zoi, n_each, coi, tau, n_tip, atom, seed, source_sha, runner_sha256, row_id = NA_integer_) {
  sim <- simulate_atom_field(seed, atom, zoi, coi, n_each, tau, n_tip)
  gd <- group_diagnostics(sim$data$y, sim$data$species, n_tip)

  formula <- if (atom == "zoi") {
    drmTMB::bf(y ~ x, sigma ~ 1, zoi ~ 1 + (1 | species), coi ~ 1)
  } else {
    drmTMB::bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + (1 | species))
  }

  started <- proc.time()[[3L]]
  fit <- tryCatch(
    drmTMB::drmTMB(
      formula, family = drmTMB::zero_one_beta(), data = sim$data,
      control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 3000L, iter.max = 3000L))
    ),
    error = identity
  )
  elapsed <- proc.time()[[3L]] - started

  base <- data.frame(
    row_id = row_id, atom = atom, zoi = zoi, n_each = n_each, coi = coi, tau = tau,
    n_tip = n_tip, seed = seed, source_sha = source_sha, runner_sha256 = runner_sha256,
    mean_boundary_group = gd$mean_boundary_group, min_boundary_group = gd$min_boundary_group,
    n_separated_groups = gd$n_separated_groups, elapsed_sec = elapsed,
    stringsAsFactors = FALSE
  )

  if (inherits(fit, "error")) {
    row <- cbind(base, data.frame(
      status = "fit_error", convergence = NA_integer_, pdHess = NA, max_gradient = NA_real_,
      tau_hat = NA_real_, tau_relative_error = NA_real_, mode_correlation = NA_real_,
      boundary_hit = NA, error = conditionMessage(fit), stringsAsFactors = FALSE
    ))
    return(list(row = row, fit = fit, sim = sim))
  }

  tau_hat <- unname(fit$sdpars[[atom]][["(1 | species)"]])
  u_hat <- ranef(fit, atom)$terms[["(1 | species)"]]
  mode_cor <- suppressWarnings(stats::cor(u_hat[names(sim$field)], sim$field))
  gradient <- max(abs(fit$obj$gr(fit$opt$par)))
  row <- cbind(base, data.frame(
    status = "fit_ok", convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess),
    max_gradient = gradient, tau_hat = tau_hat, tau_relative_error = abs(tau_hat / tau - 1),
    mode_correlation = mode_cor,
    boundary_hit = !is.finite(tau_hat) || tau_hat <= 0.05 || tau_hat >= 2.5,
    error = "none", stringsAsFactors = FALSE
  ))
  list(row = row, fit = fit, sim = sim)
}

# ---- grid -------------------------------------------------------------------

build_grid <- function() {
  zoi_vals <- c(0.10, 0.12, 0.15, 0.25, 0.35, 0.50)
  n_each_vals <- c(30L, 50L, 100L, 200L)
  coi_vals <- c(0.1, 0.3, 0.5, 0.7, 0.9)
  tau_vals <- c(0.3, 0.55, 0.8)
  n_tip_vals <- c(32L, 64L)
  atoms <- c("zoi", "coi")
  seed_idx <- 1:20
  seed_base <- 2026080200L

  grid <- expand.grid(
    zoi = zoi_vals, n_each = n_each_vals, coi = coi_vals, tau = tau_vals,
    n_tip = n_tip_vals, atom = atoms, seed_idx = seed_idx,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  grid$seed <- seed_base + grid$seed_idx
  grid$row_id <- seq_len(nrow(grid))
  grid
}

# ---- entry point --------------------------------------------------------

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)

use_installed <- identical(Sys.getenv("C18_USE_INSTALLED", "0"), "1")
if (use_installed) {
  rlib <- Sys.getenv("C18_RLIB", "")
  if (nzchar(rlib)) .libPaths(c(rlib, .libPaths()))
  library(drmTMB)
} else {
  pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
}

mode <- Sys.getenv("C18_MODE", "smoke")
out_dir <- Sys.getenv(
  "C18_OUT",
  file.path(root, "docs/dev-log/implementation-recovery/2026-08-02-c18-atom-dgp-feasibility")
)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

source_sha <- git_output(c("rev-parse", "HEAD"))
runner_sha256 <- sha256_file(script)

if (mode == "smoke") {
  cat("C18 smoke: one representative cell, both atoms (zoi RE path, coi RE path)\n")
  cell <- list(zoi = 0.15, n_each = 50L, coi = 0.5, tau = 0.55, n_tip = 32L, seed = 2026080201L)
  for (atom in c("zoi", "coi")) {
    cat("--- atom =", atom, "---\n")
    result <- run_cell(
      cell$zoi, cell$n_each, cell$coi, cell$tau, cell$n_tip, atom, cell$seed,
      source_sha, runner_sha256
    )
    append_row(result$row, file.path(out_dir, "smoke-attempt.tsv"))
    print(result$row)
    if (inherits(result$fit, "error")) {
      cat("FIT ERROR:", conditionMessage(result$fit), "\n")
    } else {
      cat("str(fit$opt):\n"); str(result$fit$opt)
      cat("fit$sdr$pdHess:", isTRUE(result$fit$sdr$pdHess), "\n")
      cat("summary sdpars[[atom]]:\n"); print(result$fit$sdpars[[atom]])
      cat("head(ranef):\n"); print(head(ranef(result$fit, atom)$terms[["(1 | species)"]]))
    }
  }
} else if (mode == "time") {
  n_time <- as.integer(Sys.getenv("C18_TIME_N", "20"))
  cat("C18 time: sampling", n_time, "fits spanning small/large grid corners\n")
  small <- list(zoi = 0.15, n_each = 30L, coi = 0.5, tau = 0.55, n_tip = 32L)
  large <- list(zoi = 0.15, n_each = 200L, coi = 0.5, tau = 0.55, n_tip = 64L)
  half <- n_time %/% 2L
  seeds <- 2026080201:(2026080200L + n_time)
  rows <- vector("list", n_time)
  i <- 1L
  for (corner in list(small = small, large = large)) {
    n_this <- if (i == 1L) half else n_time - half
    for (j in seq_len(n_this)) {
      atom <- if (j %% 2L == 0L) "coi" else "zoi"
      result <- run_cell(
        corner$zoi, corner$n_each, corner$coi, corner$tau, corner$n_tip, atom,
        seeds[[(i - 1L) * half + j]], source_sha, runner_sha256
      )
      append_row(result$row, file.path(out_dir, "timing-sample.tsv"))
      rows[[(i - 1L) * half + j]] <- result$row
      cat(sprintf(
        "corner=%s atom=%s n=%d elapsed=%.2fs status=%s\n",
        names(list(small = small, large = large))[i], atom,
        corner$n_each * corner$n_tip, result$row$elapsed_sec, result$row$status
      ))
    }
    i <- i + 1L
  }
  rows <- do.call(rbind, rows)
  cat(sprintf(
    "\nmean elapsed=%.2fs min=%.2fs max=%.2fs (n=%d)\n",
    mean(rows$elapsed_sec), min(rows$elapsed_sec), max(rows$elapsed_sec), nrow(rows)
  ))
  full_grid_n <- 6L * 4L * 5L * 3L * 2L * 2L * 20L
  cat(sprintf(
    "projected SERIAL wall time for full grid (%d fits): %.1f min\n",
    full_grid_n, mean(rows$elapsed_sec) * full_grid_n / 60
  ))
} else if (mode == "shard") {
  shard <- as.integer(Sys.getenv("C18_SHARD", "1"))
  nshard <- as.integer(Sys.getenv("C18_NSHARD", "1"))
  grid <- build_grid()
  my_rows <- which(((grid$row_id - 1L) %% nshard) == (shard - 1L))
  shard_dir <- file.path(out_dir, "shards")
  dir.create(shard_dir, recursive = TRUE, showWarnings = FALSE)
  shard_file <- file.path(shard_dir, sprintf("shard-%03d.tsv", shard))
  log_file <- file.path(shard_dir, sprintf("shard-%03d.log", shard))
  log_con <- file(log_file, open = "at")
  on.exit(close(log_con), add = TRUE)
  writeLines(paste(utc_now(), "START", shard, "of", nshard, "n_rows", length(my_rows)), log_con)
  flush(log_con)
  for (i in my_rows) {
    result <- tryCatch(
      run_cell(
        grid$zoi[[i]], grid$n_each[[i]], grid$coi[[i]], grid$tau[[i]], grid$n_tip[[i]],
        grid$atom[[i]], grid$seed[[i]], source_sha, runner_sha256, row_id = grid$row_id[[i]]
      ),
      error = identity
    )
    if (inherits(result, "error")) {
      row <- data.frame(
        row_id = grid$row_id[[i]], atom = grid$atom[[i]], zoi = grid$zoi[[i]],
        n_each = grid$n_each[[i]], coi = grid$coi[[i]], tau = grid$tau[[i]],
        n_tip = grid$n_tip[[i]], seed = grid$seed[[i]], source_sha = source_sha,
        runner_sha256 = runner_sha256, mean_boundary_group = NA_real_,
        min_boundary_group = NA_real_, n_separated_groups = NA_integer_,
        elapsed_sec = NA_real_, status = "sim_error", convergence = NA_integer_,
        pdHess = NA, max_gradient = NA_real_, tau_hat = NA_real_,
        tau_relative_error = NA_real_, mode_correlation = NA_real_, boundary_hit = NA,
        error = conditionMessage(result), stringsAsFactors = FALSE
      )
    } else {
      row <- result$row
    }
    append_row(row, shard_file)
    writeLines(paste(utc_now(), "FIT", grid$row_id[[i]], grid$atom[[i]], row$status), log_con)
    flush(log_con)
  }
  writeLines(paste(utc_now(), "DONE", shard, "of", nshard), log_con)
  flush(log_con)
} else if (mode == "assemble") {
  shard_dir <- file.path(out_dir, "shards")
  shard_files <- list.files(shard_dir, pattern = "^shard-.*\\.tsv$", full.names = TRUE)
  if (length(shard_files) == 0L) stop("No shard files found under ", shard_dir)
  attempts <- do.call(rbind, lapply(shard_files, function(f) {
    utils::read.delim(f, stringsAsFactors = FALSE)
  }))
  attempts <- attempts[order(attempts$row_id), ]
  write_tsv(attempts, file.path(out_dir, "raw-attempts.tsv"))

  cells <- unique(attempts[c("atom", "zoi", "n_each", "coi", "tau", "n_tip")])
  summary_rows <- do.call(rbind, lapply(seq_len(nrow(cells)), function(k) {
    cl <- cells[k, ]
    x <- attempts[
      attempts$atom == cl$atom & attempts$zoi == cl$zoi & attempts$n_each == cl$n_each &
        attempts$coi == cl$coi & attempts$tau == cl$tau & attempts$n_tip == cl$n_tip,
    ]
    pass <- with(
      x,
      status == "fit_ok" & convergence == 0L & !is.na(pdHess) & pdHess &
        !is.na(max_gradient) & max_gradient <= 0.01 & !is.na(boundary_hit) & !boundary_hit &
        !is.na(mode_correlation) & mode_correlation > 0.45
    )
    pass_rate <- mean(pass)
    decision <- if (pass_rate >= 0.9) {
      "RECOVERABLE"
    } else if (pass_rate >= 0.5) {
      "MARGINAL"
    } else {
      "NOT_RECOVERABLE"
    }
    data.frame(
      atom = cl$atom, zoi = cl$zoi, n_each = cl$n_each, coi = cl$coi, tau = cl$tau,
      n_tip = cl$n_tip, n_attempts = nrow(x), n_fit_ok = sum(x$status == "fit_ok"),
      n_pass = sum(pass), pass_rate = pass_rate,
      mean_tau_relative_error_pass = if (any(pass)) mean(x$tau_relative_error[pass]) else NA_real_,
      mean_mode_correlation = mean(x$mode_correlation, na.rm = TRUE),
      mean_min_boundary_group = mean(x$min_boundary_group, na.rm = TRUE),
      mean_mean_boundary_group = mean(x$mean_boundary_group, na.rm = TRUE),
      mean_n_separated_groups = mean(x$n_separated_groups, na.rm = TRUE),
      frac_separated_groups = mean(x$n_separated_groups, na.rm = TRUE) / cl$n_tip,
      decision = decision, stringsAsFactors = FALSE
    )
  }))
  write_tsv(summary_rows, file.path(out_dir, "summary.tsv"))

  namespace_path <- normalizePath(
    getNamespaceInfo(asNamespace("drmTMB"), "path"), mustWork = FALSE
  )
  source_files <- c("R/drmTMB.R", "src/drmTMB.cpp", "R/phylo-utils.R", "tools/run-c18-atom-dgp-feasibility.R")
  source_blobs <- vapply(source_files, git_blob, character(1L))
  dirty_state <- git_output(c("status", "--porcelain=v1", "--untracked-files=all"))
  if (length(dirty_state) == 0L || identical(dirty_state, "")) dirty_state <- "<clean>"
  writeLines(dirty_state, file.path(out_dir, "dirty-state.txt"))
  provenance <- data.frame(
    key = c(
      "run_status", "source_sha", "runner_sha256", paste0("git_blob:", source_files),
      "loaded_namespace_path", "n_shard_files", "n_attempts_total", "utc_finish",
      "exact_command", "dirty_state_path"
    ),
    value = c(
      "COMPLETE", source_sha, runner_sha256, unname(source_blobs), namespace_path,
      length(shard_files), nrow(attempts), utc_now(),
      "R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-c18-atom-dgp-feasibility.R (C18_MODE=assemble)",
      "dirty-state.txt"
    )
  )
  write_tsv(provenance, file.path(out_dir, "provenance.tsv"))
  cat("Assembled", nrow(attempts), "attempts from", length(shard_files), "shard files.\n")
} else {
  stop("Unknown C18_MODE: ", mode)
}
