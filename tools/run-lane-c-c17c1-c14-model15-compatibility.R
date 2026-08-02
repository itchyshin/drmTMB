#!/usr/bin/env Rscript

write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE)
}

utc_now <- function() format(Sys.time(), tz = "UTC", usetz = TRUE)
git_output <- function(args) trimws(system2("git", args, stdout = TRUE, stderr = TRUE))
git_blob <- function(path) {
  value <- git_output(c("hash-object", path))
  if (length(value) != 1L || !nzchar(value)) stop("Could not hash ", path)
  value
}
sha256_file <- function(path) {
  value <- trimws(system2("shasum", c("-a", "256", path), stdout = TRUE))
  strsplit(value, "[[:space:]]+")[[1L]][[1L]]
}

standard_x <- function(id) {
  x <- stats::rnorm(length(id))
  x <- x - ave(x, id, FUN = mean)
  x / stats::sd(x)
}

simulate_sigma_intercept <- function(seed, tau = 0.45) {
  set.seed(seed)
  id <- factor(rep(paste0("g", seq_len(32L)), each = 30L))
  x <- standard_x(id)
  b <- stats::rnorm(32L, sd = tau); names(b) <- levels(id)
  mu <- stats::plogis(-0.15 + 0.35 * x)
  sigma <- exp(log(0.45) + b[as.character(id)])
  boundary <- stats::rbinom(length(id), 1L, 0.14)
  y <- ifelse(
    boundary == 1L,
    stats::rbinom(length(id), 1L, 0.40),
    stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
  )
  list(data = data.frame(y, x, id), b = b)
}

simulate_zoi_intercept <- function(seed, tau = 0.45) {
  set.seed(seed)
  id <- factor(rep(paste0("g", seq_len(32L)), each = 50L))
  for (dgp_draw in seq_len(1000L)) {
    x <- standard_x(id)
    b <- stats::rnorm(32L, sd = tau); names(b) <- levels(id)
    mu <- stats::plogis(-0.15 + 0.35 * x)
    sigma <- exp(-1.0)
    zoi <- stats::plogis(-1.15 + b[as.character(id)])
    boundary <- stats::rbinom(length(id), 1L, zoi)
    y <- ifelse(
      boundary == 1L,
      stats::rbinom(length(id), 1L, stats::plogis(0.1)),
      stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
    )
    n_zero <- tabulate(as.integer(id[y == 0]), nbins = 32L)
    n_one <- tabulate(as.integer(id[y == 1]), nbins = 32L)
    if (all(n_zero >= 2L) && all(n_one >= 2L)) {
      return(list(
        data = data.frame(y, x, id), b = b, dgp_draw = dgp_draw,
        min_group_zero = min(n_zero), min_group_one = min(n_one)
      ))
    }
  }
  stop("Could not reproduce the frozen zoi support contract")
}

simulate_sigma_slope <- function(seed, tau = 0.45) {
  set.seed(seed)
  id <- factor(rep(paste0("g", seq_len(32L)), each = 50L))
  x <- standard_x(id)
  b <- stats::rnorm(32L, sd = tau); names(b) <- levels(id)
  mu <- stats::plogis(-0.15 + 0.35 * x)
  sigma <- exp(-1 + b[as.character(id)] * x)
  zoi <- stats::plogis(-0.7)
  boundary <- stats::rbinom(length(id), 1L, zoi)
  y <- stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
  y[boundary == 1L] <- stats::rbinom(
    sum(boundary), 1L, stats::plogis(0.1)
  )
  list(
    data = data.frame(y, x, id), b = b,
    min_group_boundary = min(tapply(y %in% c(0, 1), id, sum)),
    min_group_interior = min(tapply(y > 0 & y < 1, id, sum))
  )
}

route_spec <- list(
  `mc-0568` = list(
    seeds = 2026073401:2026073404,
    simulate = simulate_sigma_intercept,
    formula = function() drmTMB::bf(
      y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1
    ),
    dpar = "sigma", label = "(1 | id)"
  ),
  `mc-0569` = list(
    seeds = 2026073501:2026073504,
    simulate = simulate_zoi_intercept,
    formula = function() drmTMB::bf(
      y ~ x, sigma ~ 1, zoi ~ 1 + (1 | id), coi ~ 1
    ),
    dpar = "zoi", label = "(1 | id)"
  ),
  `mc-0576` = list(
    seeds = 2026073701:2026073704,
    simulate = simulate_sigma_slope,
    formula = function() drmTMB::bf(
      y ~ x, sigma ~ x + (0 + x | id), zoi ~ 1, coi ~ 1
    ),
    dpar = "sigma", label = "(0 + x | id)"
  )
)

fit_one <- function(seed, cell_id, source_sha, runner_sha256) {
  spec <- route_spec[[cell_id]]
  sim <- spec$simulate(seed)
  fit <- tryCatch(
    drmTMB::drmTMB(
      spec$formula(), family = drmTMB::zero_one_beta(), data = sim$data,
      control = drmTMB::drm_control(
        se = TRUE, optimizer = list(eval.max = 3000L, iter.max = 3000L)
      )
    ),
    error = identity
  )
  if (inherits(fit, "error")) {
    return(data.frame(
      cell_id, seed, source_sha, runner_sha256, status = "fit_error",
      convergence = NA_integer_, pdHess = NA, max_gradient = NA_real_,
      tau_truth = 0.45, tau_hat = NA_real_, mode_correlation = NA_real_,
      boundary_hit = NA, support_gate = NA, n_coi_re_terms = NA_integer_,
      error = conditionMessage(fit)
    ))
  }
  tau_hat <- unname(fit$sdpars[[spec$dpar]][[spec$label]])
  modes <- ranef(fit, spec$dpar)$terms[[spec$label]]
  support_gate <- if (identical(cell_id, "mc-0569")) {
    sim$min_group_zero >= 2L && sim$min_group_one >= 2L
  } else if (identical(cell_id, "mc-0576")) {
    sim$min_group_boundary > 0L && sim$min_group_interior > 0L
  } else {
    TRUE
  }
  data.frame(
    cell_id, seed, source_sha, runner_sha256, status = "fit_ok",
    convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess),
    max_gradient = max(abs(fit$obj$gr(fit$opt$par))),
    tau_truth = 0.45, tau_hat = tau_hat,
    mode_correlation = suppressWarnings(stats::cor(modes[names(sim$b)], sim$b)),
    boundary_hit = !is.finite(tau_hat) || tau_hat <= 0.05 || tau_hat >= 2.5,
    support_gate = support_gate,
    n_coi_re_terms = fit$model$tmb_data$n_coi_re_terms,
    error = "none"
  )
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
run_id <- Sys.getenv(
  "C17_COMPAT_RUN_ID",
  "2026-08-01-lane-c-c17c1-c14-model15-compatibility-run-1"
)
out <- file.path(root, "docs/dev-log/implementation-recovery", run_id)
dir.create(out, recursive = TRUE, showWarnings = FALSE)

source_sha <- git_output(c("rev-parse", "HEAD"))
runner_sha256 <- sha256_file(script)
source_files <- c(
  "R/drmTMB.R", "R/methods.R", "src/drmTMB.cpp",
  "tests/testthat/test-zero-one-beta.R",
  "tools/run-lane-c-c17c1-c14-model15-compatibility.R"
)
source_blobs <- vapply(source_files, git_blob, character(1L))
dirty_state <- git_output(c("status", "--porcelain=v1", "--untracked-files=all"))
if (length(dirty_state) == 0L || identical(dirty_state, "")) dirty_state <- "<clean>"
writeLines(dirty_state, file.path(out, "dirty-state.txt"))

started_utc <- utc_now()
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
provenance <- data.frame(
  key = c(
    "run_status", "source_sha", "runner_sha256",
    paste0("git_blob:", source_files), "loaded_namespace_path",
    "utc_start", "utc_finish", "exact_command", "dirty_state_path"
  ),
  value = c(
    "RUNNING", source_sha, runner_sha256, unname(source_blobs),
    normalizePath(getNamespaceInfo(asNamespace("drmTMB"), "path"), mustWork = FALSE),
    started_utc, "",
    paste(
      "R_PROFILE_USER=/dev/null Rscript --no-init-file",
      "tools/run-lane-c-c17c1-c14-model15-compatibility.R"
    ),
    "dirty-state.txt"
  )
)
write_tsv(provenance, file.path(out, "provenance.tsv"))

attempts <- do.call(rbind, lapply(names(route_spec), function(cell_id) {
  do.call(rbind, lapply(
    route_spec[[cell_id]]$seeds, fit_one,
    cell_id = cell_id, source_sha = source_sha,
    runner_sha256 = runner_sha256
  ))
}))
write_tsv(attempts, file.path(out, "raw-attempts.tsv"))

summary_rows <- do.call(rbind, lapply(split(attempts, attempts$cell_id), function(x) {
  pass <- with(
    x,
    status == "fit_ok" & convergence == 0L & pdHess &
      max_gradient <= 0.01 & !boundary_hit & support_gate &
      mode_correlation > 0.45 & n_coi_re_terms == 0L
  )
  mean_relative_error <- mean(abs(x$tau_hat / 0.45 - 1))
  data.frame(
    cell_id = x$cell_id[[1L]], attempts = nrow(x), passed = sum(pass),
    mean_tau_relative_error = mean_relative_error,
    decision = if (
      all(pass) && is.finite(mean_relative_error) && mean_relative_error <= 0.40
    ) "PASS_CURRENT_SOURCE_COMPATIBILITY" else "BLOCKED_CURRENT_SOURCE_COMPATIBILITY"
  )
}))
write_tsv(summary_rows, file.path(out, "summary.tsv"))

provenance$value[provenance$key == "run_status"] <- "COMPLETE"
provenance$value[provenance$key == "utc_finish"] <- utc_now()
write_tsv(provenance, file.path(out, "provenance.tsv"))
