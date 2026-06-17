#!/usr/bin/env Rscript

options(warn = 1)

output_dir <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(output_dir) || !nzchar(output_dir)) {
  output_dir <- "docs/dev-log/simulation-artifacts/2026-06-17-logsigma-clamp-sensitivity-pilot"
}
tables_dir <- file.path(output_dir, "tables")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

quiet_system <- function(...) {
  out <- tryCatch(system2(..., stdout = TRUE, stderr = TRUE), error = function(e) NA_character_)
  paste(out, collapse = "\n")
}

source_sha <- quiet_system("git", c("rev-parse", "HEAD"))
source_branch <- quiet_system("git", c("branch", "--show-current"))
dirty_state <- quiet_system("git", c("status", "--short"))
if (!nzchar(dirty_state)) {
  dirty_state <- "clean"
}

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

master_seed <- 20260617L
n_rep <- 25L
n <- 180L

conditions <- data.frame(
  condition_id = c(
    "ordinary_scale",
    "near_default_upper_band",
    "above_default_upper_band",
    "below_default_lower_band"
  ),
  description = c(
    "ordinary standardized scale; expected clamp inactive",
    "large but still inside default identity band",
    "legitimate huge unstandardized scale above default band",
    "legitimate tiny unstandardized scale below default band"
  ),
  beta_mu_intercept = c(0.2, 0.2, 0.2, 0.2),
  beta_mu_x = c(0.5, 0.5, 0.5, 0.5),
  beta_sigma_intercept = c(-0.2, 11.0, 16.0, -16.0),
  beta_sigma_x = c(0.3, 0.25, 0.25, 0.25),
  stringsAsFactors = FALSE
)

configs <- data.frame(
  config_id = c("off", "default", "wide"),
  logsigma_clamp_lo = c(NA_real_, -12, -25),
  logsigma_clamp_hi = c(NA_real_, 12, 25),
  logsigma_clamp_margin = c(NA_real_, 3, 3),
  interpretation = c(
    "unclamped reference",
    "default drmTMB overflow guard",
    "widened guard for huge unstandardized scales"
  ),
  stringsAsFactors = FALSE
)

set.seed(master_seed)
replicate_seeds <- sample.int(.Machine$integer.max, nrow(conditions) * n_rep)
seed_index <- 0L

make_data <- function(condition, seed) {
  set.seed(seed)
  x <- stats::runif(n, -1, 1)
  mu <- condition$beta_mu_intercept + condition$beta_mu_x * x
  log_sigma <- condition$beta_sigma_intercept + condition$beta_sigma_x * x
  y <- stats::rnorm(n, mu, exp(log_sigma))
  data.frame(y = y, x = x, truth_mu = mu, truth_log_sigma = log_sigma)
}

fit_one <- function(dat, condition, config, replicate, seed) {
  control <- if (identical(config$config_id, "off")) {
    drm_control(logsigma_clamp = NULL)
  } else {
    drm_control(
      logsigma_clamp = c(config$logsigma_clamp_lo, config$logsigma_clamp_hi),
      logsigma_clamp_margin = config$logsigma_clamp_margin
    )
  }
  warnings <- character()
  elapsed <- system.time({
    fit <- tryCatch(
      withCallingHandlers(
        drmTMB(
          bf(y ~ x, sigma ~ x),
          data = dat,
          control = control
        ),
        warning = function(w) {
          warnings <<- c(warnings, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(e) e
    )
  })

  base <- data.frame(
    condition_id = condition$condition_id,
    replicate = replicate,
    seed = seed,
    config_id = config$config_id,
    n = nrow(dat),
    elapsed_sec = unname(elapsed[["elapsed"]]),
    warning_count = length(warnings),
    warnings = paste(unique(warnings), collapse = " | "),
    stringsAsFactors = FALSE
  )

  if (inherits(fit, "error")) {
    return(cbind(
      base,
      data.frame(
        status = "error",
        error = conditionMessage(fit),
        convergence = NA_integer_,
        pdHess = NA,
        objective = NA_real_,
        logLik = NA_real_,
        AIC = NA_real_,
        BIC = NA_real_,
        beta_mu_intercept = NA_real_,
        beta_mu_x = NA_real_,
        beta_sigma_intercept = NA_real_,
        beta_sigma_x = NA_real_,
        se_mu_intercept = NA_real_,
        se_mu_x = NA_real_,
        se_sigma_intercept = NA_real_,
        se_sigma_x = NA_real_,
        raw_logsigma_min = NA_real_,
        raw_logsigma_max = NA_real_,
        reported_logsigma_min = NA_real_,
        reported_logsigma_max = NA_real_,
        max_abs_clamp_delta = NA_real_,
        clamp_active = NA,
        stringsAsFactors = FALSE
      )
    ))
  }

  coef_fit <- coef(fit)
  vc <- tryCatch(stats::vcov(fit), error = function(e) NULL)
  se <- setNames(rep(NA_real_, 4L), c(
    "mu:(Intercept)", "mu:x", "sigma:(Intercept)", "sigma:x"
  ))
  if (is.matrix(vc)) {
    diag_vc <- diag(vc)
    se[names(diag_vc)] <- sqrt(pmax(diag_vc, 0))
  }
  X_sigma <- stats::model.matrix(~x, dat)
  raw_logsigma <- drop(X_sigma %*% coef_fit$sigma)
  reported_logsigma <- fit$obj$report()$log_sigma
  max_abs_delta <- max(abs(raw_logsigma - reported_logsigma), na.rm = TRUE)
  cbind(
    base,
    data.frame(
      status = "ok",
      error = "",
      convergence = fit$opt$convergence,
      pdHess = isTRUE(fit$sdr$pdHess),
      objective = fit$opt$objective,
      logLik = as.numeric(stats::logLik(fit)),
      AIC = stats::AIC(fit),
      BIC = stats::BIC(fit),
      beta_mu_intercept = unname(coef_fit$mu["(Intercept)"]),
      beta_mu_x = unname(coef_fit$mu["x"]),
      beta_sigma_intercept = unname(coef_fit$sigma["(Intercept)"]),
      beta_sigma_x = unname(coef_fit$sigma["x"]),
      se_mu_intercept = unname(se["mu:(Intercept)"]),
      se_mu_x = unname(se["mu:x"]),
      se_sigma_intercept = unname(se["sigma:(Intercept)"]),
      se_sigma_x = unname(se["sigma:x"]),
      raw_logsigma_min = min(raw_logsigma),
      raw_logsigma_max = max(raw_logsigma),
      reported_logsigma_min = min(reported_logsigma),
      reported_logsigma_max = max(reported_logsigma),
      max_abs_clamp_delta = max_abs_delta,
      clamp_active = max_abs_delta > 1e-3,
      stringsAsFactors = FALSE
    )
  )
}

fit_rows <- list()
row_index <- 0L
for (condition_row in seq_len(nrow(conditions))) {
  condition <- conditions[condition_row, , drop = FALSE]
  for (replicate in seq_len(n_rep)) {
    seed_index <- seed_index + 1L
    seed <- replicate_seeds[[seed_index]]
    dat <- make_data(condition, seed)
    for (config_row in seq_len(nrow(configs))) {
      row_index <- row_index + 1L
      fit_rows[[row_index]] <- fit_one(
        dat = dat,
        condition = condition,
        config = configs[config_row, , drop = FALSE],
        replicate = replicate,
        seed = seed
      )
    }
  }
}

fits <- do.call(rbind, fit_rows)

truth <- conditions[, c(
  "condition_id",
  "beta_mu_intercept",
  "beta_mu_x",
  "beta_sigma_intercept",
  "beta_sigma_x"
)]
names(truth) <- c(
  "condition_id",
  "truth_mu_intercept",
  "truth_mu_x",
  "truth_sigma_intercept",
  "truth_sigma_x"
)
fits <- merge(fits, truth, by = "condition_id", all.x = TRUE, sort = FALSE)
fits$bias_mu_intercept <- fits$beta_mu_intercept - fits$truth_mu_intercept
fits$bias_mu_x <- fits$beta_mu_x - fits$truth_mu_x
fits$bias_sigma_intercept <- fits$beta_sigma_intercept - fits$truth_sigma_intercept
fits$bias_sigma_x <- fits$beta_sigma_x - fits$truth_sigma_x

ref <- fits[fits$config_id == "off" & fits$status == "ok", ]
ref <- ref[, c(
  "condition_id", "replicate",
  "beta_mu_intercept", "beta_mu_x",
  "beta_sigma_intercept", "beta_sigma_x",
  "se_mu_intercept", "se_mu_x",
  "se_sigma_intercept", "se_sigma_x",
  "logLik", "objective", "AIC", "BIC"
)]
names(ref)[-(1:2)] <- paste0(names(ref)[-(1:2)], "_off")
comparisons <- merge(fits, ref, by = c("condition_id", "replicate"), all.x = TRUE, sort = FALSE)
for (field in c(
  "beta_mu_intercept", "beta_mu_x", "beta_sigma_intercept", "beta_sigma_x",
  "se_mu_intercept", "se_mu_x", "se_sigma_intercept", "se_sigma_x",
  "logLik", "objective", "AIC", "BIC"
)) {
  comparisons[[paste0(field, "_diff_vs_off")]] <-
    comparisons[[field]] - comparisons[[paste0(field, "_off")]]
}

ok_rate <- function(x) mean(x, na.rm = TRUE)
mean_abs <- function(x) mean(abs(x), na.rm = TRUE)
max_abs <- function(x) max(abs(x), na.rm = TRUE)
mcse_mean <- function(x) stats::sd(x, na.rm = TRUE) / sqrt(sum(is.finite(x)))

split_key <- interaction(comparisons$condition_id, comparisons$config_id, drop = TRUE)
aggregate_rows <- lapply(split(comparisons, split_key), function(x) {
  data.frame(
    condition_id = x$condition_id[[1]],
    config_id = x$config_id[[1]],
    n_attempted = nrow(x),
    n_ok = sum(x$status == "ok"),
    n_error = sum(x$status == "error"),
    convergence_rate = ok_rate(x$convergence == 0),
    pdHess_rate = ok_rate(x$pdHess),
    warning_rate = ok_rate(x$warning_count > 0),
    clamp_active_rate = ok_rate(x$clamp_active),
    max_abs_clamp_delta = max(x$max_abs_clamp_delta, na.rm = TRUE),
    mean_abs_beta_sigma_intercept_diff_vs_off =
      mean_abs(x$beta_sigma_intercept_diff_vs_off),
    max_abs_beta_sigma_intercept_diff_vs_off =
      max_abs(x$beta_sigma_intercept_diff_vs_off),
    mean_abs_beta_sigma_x_diff_vs_off = mean_abs(x$beta_sigma_x_diff_vs_off),
    max_abs_beta_sigma_x_diff_vs_off = max_abs(x$beta_sigma_x_diff_vs_off),
    mean_abs_logLik_diff_vs_off = mean_abs(x$logLik_diff_vs_off),
    max_abs_logLik_diff_vs_off = max_abs(x$logLik_diff_vs_off),
    mean_abs_AIC_diff_vs_off = mean_abs(x$AIC_diff_vs_off),
    max_abs_AIC_diff_vs_off = max_abs(x$AIC_diff_vs_off),
    mean_elapsed_sec = mean(x$elapsed_sec, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
})
aggregate <- do.call(rbind, aggregate_rows)

condition_rows <- lapply(split(comparisons, comparisons$condition_id), function(x) {
  default <- x[x$config_id == "default", ]
  wide <- x[x$config_id == "wide", ]
  data.frame(
    condition_id = x$condition_id[[1]],
    n_rep = length(unique(x$replicate)),
    default_clamp_active_rate = ok_rate(default$clamp_active),
    default_convergence_rate = ok_rate(default$convergence == 0),
    default_pdHess_rate = ok_rate(default$pdHess),
    default_max_abs_sigma_intercept_diff_vs_off =
      max_abs(default$beta_sigma_intercept_diff_vs_off),
    default_max_abs_logLik_diff_vs_off = max_abs(default$logLik_diff_vs_off),
    wide_clamp_active_rate = ok_rate(wide$clamp_active),
    wide_max_abs_sigma_intercept_diff_vs_off =
      max_abs(wide$beta_sigma_intercept_diff_vs_off),
    wide_max_abs_logLik_diff_vs_off = max_abs(wide$logLik_diff_vs_off),
    stringsAsFactors = FALSE
  )
})
condition_summary <- do.call(rbind, condition_rows)

headline <- data.frame(
  source_sha = source_sha,
  source_branch = source_branch,
  master_seed = master_seed,
  n_conditions = nrow(conditions),
  n_replicates_per_condition = n_rep,
  n_fit_attempts = nrow(fits),
  n_ok = sum(fits$status == "ok"),
  n_errors = sum(fits$status == "error"),
  max_default_abs_logLik_diff_when_inactive =
    max(abs(comparisons$logLik_diff_vs_off[
      comparisons$config_id == "default" &
        comparisons$condition_id %in% c("ordinary_scale", "near_default_upper_band")
    ]), na.rm = TRUE),
  max_default_abs_sigma_intercept_diff_when_inactive =
    max(abs(comparisons$beta_sigma_intercept_diff_vs_off[
      comparisons$config_id == "default" &
        comparisons$condition_id %in% c("ordinary_scale", "near_default_upper_band")
    ]), na.rm = TRUE),
  max_wide_abs_logLik_diff_all_conditions =
    max(abs(comparisons$logLik_diff_vs_off[comparisons$config_id == "wide"]), na.rm = TRUE),
  max_wide_abs_sigma_intercept_diff_all_conditions =
    max(abs(comparisons$beta_sigma_intercept_diff_vs_off[
      comparisons$config_id == "wide"
    ]), na.rm = TRUE),
  max_default_abs_logLik_diff_when_binding =
    max(abs(comparisons$logLik_diff_vs_off[
      comparisons$config_id == "default" &
        comparisons$condition_id %in% c("above_default_upper_band", "below_default_lower_band")
    ]), na.rm = TRUE),
  max_default_abs_sigma_intercept_diff_when_binding =
    max(abs(comparisons$beta_sigma_intercept_diff_vs_off[
      comparisons$config_id == "default" &
        comparisons$condition_id %in% c("above_default_upper_band", "below_default_lower_band")
    ]), na.rm = TRUE),
  dirty_state = dirty_state,
  stringsAsFactors = FALSE
)

utils::write.csv(conditions, file.path(tables_dir, "logsigma-clamp-conditions.csv"), row.names = FALSE)
utils::write.csv(configs, file.path(tables_dir, "logsigma-clamp-configs.csv"), row.names = FALSE)
utils::write.csv(fits, file.path(tables_dir, "logsigma-clamp-fits.csv"), row.names = FALSE)
utils::write.csv(comparisons, file.path(tables_dir, "logsigma-clamp-comparisons.csv"), row.names = FALSE)
utils::write.csv(aggregate, file.path(tables_dir, "logsigma-clamp-aggregate.csv"), row.names = FALSE)
utils::write.csv(condition_summary, file.path(tables_dir, "logsigma-clamp-condition-summary.csv"), row.names = FALSE)
utils::write.csv(headline, file.path(output_dir, "logsigma-clamp-sensitivity-run-summary.csv"), row.names = FALSE)
capture.output(utils::sessionInfo(), file = file.path(output_dir, "session-info.txt"))

figures_dir <- file.path(output_dir, "figures")
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)
plot_rows <- aggregate[aggregate$config_id %in% c("default", "wide"), ]
condition_order <- conditions$condition_id
config_order <- c("default", "wide")
plot_matrix <- function(metric) {
  out <- matrix(
    0,
    nrow = length(config_order),
    ncol = length(condition_order),
    dimnames = list(config_order, condition_order)
  )
  for (i in seq_len(nrow(plot_rows))) {
    out[plot_rows$config_id[[i]], plot_rows$condition_id[[i]]] <- plot_rows[[metric]][[i]]
  }
  out
}
png(
  file.path(figures_dir, "logsigma-clamp-sensitivity.png"),
  width = 1400,
  height = 700,
  res = 140
)
op <- par(mfrow = c(1, 2), mar = c(8, 5, 3, 1), las = 2, xpd = NA)
on.exit(par(op), add = TRUE)
cols <- c(default = "#2f6f95", wide = "#b75d69")
barplot(
  log10(plot_matrix("max_abs_logLik_diff_vs_off") + 1e-12),
  beside = TRUE,
  col = cols,
  ylab = "log10(max |logLik diff vs off| + 1e-12)",
  main = "Likelihood sensitivity",
  names.arg = condition_order,
  cex.names = 0.72,
  ylim = c(-12, 3)
)
legend("topleft", legend = config_order, fill = cols, bty = "n", cex = 0.8)
barplot(
  log10(plot_matrix("max_abs_beta_sigma_intercept_diff_vs_off") + 1e-12),
  beside = TRUE,
  col = cols,
  ylab = "log10(max |sigma-intercept diff vs off| + 1e-12)",
  main = "Scale-coefficient sensitivity",
  names.arg = condition_order,
  cex.names = 0.72,
  ylim = c(-12, 2)
)
legend("topleft", legend = config_order, fill = cols, bty = "n", cex = 0.8)
dev.off()

print(headline)
