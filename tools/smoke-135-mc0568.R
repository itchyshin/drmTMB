#!/usr/bin/env Rscript
# Smoke: mc-0568 × 1 seed — required before the 135-trace grid.
# Authority: docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/PREREGISTRATION.md

`%||%` <- function(a, b) {
  if (is.null(a) || length(a) == 0L || (length(a) == 1L && is.na(a))) b else a
}

repo <- Sys.getenv("DRMTMB_REPO", unset = normalizePath("."))
outdir <- file.path(
  repo,
  "docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/smoke-mc-0568"
)
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

cell_id <- "mc-0568"
# cell_index=1, seed_index=1
seed <- as.integer(20260805 + 1000000 * 1 + 1)
true_value <- 0.45
target <- "sd:sigma:(1 | id)"

message("SMOKE start cell=", cell_id, " seed=", seed)
message("loading package...")
devtools::load_all(repo, quiet = TRUE, export_all = FALSE)

standard_x <- function(id) {
  x <- stats::rnorm(length(id))
  x <- x - ave(x, id, FUN = mean)
  x / stats::sd(x)
}
simulate_sigma_intercept <- function(seed, tau = 0.45) {
  set.seed(seed)
  id <- factor(rep(paste0("g", seq_len(32L)), each = 30L))
  x <- standard_x(id)
  b <- stats::rnorm(32L, sd = tau)
  names(b) <- levels(id)
  mu <- stats::plogis(-0.15 + 0.35 * x)
  sigma <- exp(log(0.45) + b[as.character(id)])
  boundary <- stats::rbinom(length(id), 1L, 0.14)
  y <- ifelse(
    boundary == 1L,
    stats::rbinom(length(id), 1L, 0.40),
    stats::rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
  )
  data.frame(y, x, id)
}

dat <- simulate_sigma_intercept(seed, tau = true_value)
fit <- drmTMB::drmTMB(
  formula = drmTMB::bf(y ~ x, sigma ~ 1 + (1 | id), zoi ~ 1, coi ~ 1),
  data = dat,
  family = drmTMB::zero_one_beta(),
  control = drmTMB::drm_control(
    se = TRUE,
    optimizer = list(eval.max = 3000L, iter.max = 3000L)
  )
)

pt <- drmTMB::profile_targets(fit)
utils::write.csv(pt, file.path(outdir, "profile_targets.csv"), row.names = FALSE)
row <- pt[pt$parm == target, , drop = FALSE]
if (!nrow(row)) stop("target not found: ", target, call. = FALSE)
message("profile_ready=", row$profile_ready[[1]], " note=", row$note[[1]])

estimate <- as.numeric(row$estimate[[1]] %||% row$value[[1]] %||% NA_real_)
rel_err <- if (is.finite(estimate)) abs(estimate - true_value) / true_value else NA_real_
message("point estimate=", estimate, " rel_err=", rel_err)

convergence <- tryCatch(as.integer(fit$opt$convergence), error = function(e) NA_integer_)
pdHess <- tryCatch(isTRUE(fit$sdr$pdHess), error = function(e) NA)

ci <- tryCatch(
  stats::confint(fit, method = "profile", parm = target),
  error = function(e) e
)
if (inherits(ci, "error")) {
  writeLines(conditionMessage(ci), file.path(outdir, "SMOKE_FAIL.txt"))
  stop("confint failed: ", conditionMessage(ci), call. = FALSE)
}
ci_df <- as.data.frame(ci)
utils::write.csv(ci_df, file.path(outdir, "confint.csv"), row.names = FALSE)
message("confint columns: ", paste(names(ci_df), collapse = ", "))

scalar <- function(x) {
  x <- as.numeric(x)
  if (!length(x)) return(NA_real_)
  x[[1L]]
}
lower <- scalar(ci_df$lower)
upper <- scalar(ci_df$upper)
conf_status <- as.character(ci_df$conf.status[[1]] %||% "profile")
profile_boundary <- isTRUE(as.logical(ci_df$profile.boundary[[1]] %||% FALSE))
message_txt <- as.character(ci_df$profile.message[[1]] %||% ci_df$message[[1]] %||% "ok")
profile_engine <- as.character(ci_df$profile.engine[[1]] %||% "unknown")

brackets_truth <- is.finite(lower) && is.finite(upper) &&
  lower < true_value && true_value < upper
clamp_limited <- grepl("clamp", message_txt, ignore.case = TRUE) ||
  identical(conf_status, "clamp_limited")

receipt <- data.frame(
  cell_id = cell_id,
  seed = seed,
  target = target,
  true_value = true_value,
  estimate = estimate,
  lower = lower,
  upper = upper,
  rel_err = rel_err,
  convergence = convergence,
  pdHess = isTRUE(pdHess),
  conf_status = conf_status,
  profile_boundary = profile_boundary,
  clamp_limited = clamp_limited,
  message = message_txt,
  brackets_truth = brackets_truth,
  profile_engine = profile_engine,
  stringsAsFactors = FALSE
)
utils::write.csv(receipt, file.path(outdir, "receipt.csv"), row.names = FALSE)
saveRDS(
  list(fit = fit, ci = ci, receipt = receipt, profile_targets = pt),
  file.path(outdir, "smoke.rds")
)

pass <- isTRUE(brackets_truth) &&
  isTRUE(!profile_boundary) &&
  isTRUE(!clamp_limited) &&
  isTRUE(pdHess) &&
  isTRUE(!is.na(convergence) && convergence == 0L) &&
  is.finite(lower) && is.finite(upper) &&
  is.finite(estimate) && lower < estimate && estimate < upper &&
  is.finite(rel_err) && rel_err <= 0.35

line <- sprintf(
  "SMOKE_%s cell=%s seed=%s brackets=%s rel_err=%.4f CI=[%.4f, %.4f] clamp=%s boundary=%s engine=%s status=%s",
  if (pass) "PASS" else "FAIL",
  cell_id, seed, brackets_truth, rel_err, lower, upper,
  clamp_limited, profile_boundary, profile_engine, conf_status
)
writeLines(line, file.path(outdir, if (pass) "SMOKE_PASS.txt" else "SMOKE_FAIL.txt"))
message(line)
if (!pass) quit(status = 2)
