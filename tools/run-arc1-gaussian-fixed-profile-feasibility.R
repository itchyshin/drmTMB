#!/usr/bin/env Rscript

# Current-source Arc 1 screen for the two ordinary Gaussian ML fixed-effect
# cells.  Receipts remain target-specific even though the targets share one DGP.

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^--", name, "="), "", hit[[1L]])
}
if (length(args) && any(!grepl("^--(seed|n|out)=", args))) {
  stop("Only --seed=, --n=, and --out= are accepted.", call. = FALSE)
}
seed <- as.integer(arg_value("seed", "2026080221"))
n <- as.integer(arg_value("n", "240"))
if (is.na(seed) || is.na(n) || n < 80L) stop("seed must be finite and n must be at least 80.", call. = FALSE)

script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]]))
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
source_sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
runner_sha256 <- sub(" .*", "", system2("shasum", c("-a", "256", script), stdout = TRUE))
file_sha256 <- function(path) sub(" .*", "", system2("shasum", c("-a", "256", path), stdout = TRUE))
out <- arg_value(
  "out",
  file.path(root, "docs/dev-log/interval-feasibility/results", source_sha,
            "arc1-gaussian-fixed-profile-feasibility")
)
dir.create(out, recursive = TRUE, showWarnings = FALSE)

set.seed(seed)
x <- stats::rnorm(n)
truth_mu_x <- .55
truth_sigma_x <- .18
log_sigma <- -.45 + truth_sigma_x * x
dat <- data.frame(y = .25 + truth_mu_x * x + stats::rnorm(n, sd = exp(log_sigma)), x = x)
fixture_path <- file.path(out, sprintf("fixture-n%d-seed%d.tsv", n, seed))
utils::write.table(dat, fixture_path, sep = "\t", quote = FALSE, row.names = FALSE)
fixture_sha256 <- file_sha256(fixture_path)
fit <- drmTMB::drmTMB(
  drmTMB::bf(y ~ x, sigma ~ x), family = stats::gaussian(), data = dat, REML = FALSE
)

contracts <- data.frame(
  cell_id = c("mc-0260", "mc-0262"),
  dpar = c("mu", "sigma"),
  target = c("fixef:mu:x", "fixef:sigma:x"),
  truth = c(truth_mu_x, truth_sigma_x),
  stringsAsFactors = FALSE
)

run_target <- function(contract) {
  target <- subset(drmTMB::profile_targets(fit), parm == contract$target)
  if (nrow(target) != 1L || !isTRUE(target$profile_ready) || !identical(target$target_type, "direct")) {
    stop("Exact direct profile target is not ready: ", contract$target, call. = FALSE)
  }
  prof <- tryCatch(stats::profile(fit, parm = contract$target, trace = FALSE), error = identity)
  stem <- sprintf("%s-n%d-seed%d", contract$cell_id, n, seed)
  trace_path <- file.path(out, paste0(stem, "-trace.tsv"))
  interval_path <- file.path(out, paste0(stem, "-interval.tsv"))
  if (!inherits(prof, "error")) {
    trace <- as.data.frame(prof)
    trace$cell_id <- contract$cell_id
    trace$target_id <- paste0(contract$cell_id, "::", contract$target)
    trace$seed <- seed
    trace$information_rung <- paste0("n", n)
    utils::write.table(trace, trace_path, sep = "\t", quote = FALSE, row.names = FALSE)
  }
  if (!inherits(prof, "error")) {
    profile_field <- function(name) {
      value <- unique(prof[[name]])
      if (length(value) != 1L) stop("Profile field is not constant: ", name, call. = FALSE)
      value[[1L]]
    }
    interval <- data.frame(
      parm = contract$target, level = profile_field("level"),
      lower = profile_field("conf.low"), upper = profile_field("conf.high"),
      scale = profile_field("scale"), transformation = profile_field("transformation"),
      tmb_parameter = profile_field("tmb_parameter"), index = profile_field("index"),
      method = "profile", profile.engine = "tmbprofile",
      conf.status = profile_field("conf.status"),
      profile.boundary = !all(is.finite(c(profile_field("conf.low"), target$estimate[[1L]], profile_field("conf.high")))) ||
        profile_field("conf.low") >= target$estimate[[1L]] || profile_field("conf.high") <= target$estimate[[1L]] ||
        !identical(profile_field("profile.message"), "ok"),
      profile.message = profile_field("profile.message"), stringsAsFactors = FALSE
    )
    interval$cell_id <- contract$cell_id
    interval$target_id <- paste0(contract$cell_id, "::", contract$target)
    interval$seed <- seed
    interval$information_rung <- paste0("n", n)
    utils::write.table(interval, interval_path, sep = "\t", quote = FALSE, row.names = FALSE)
  }
  conf_status <- if (inherits(prof, "error")) "profile_error" else interval$conf.status[[1L]]
  lower <- if (inherits(prof, "error")) NA_real_ else interval$lower[[1L]]
  upper <- if (inherits(prof, "error")) NA_real_ else interval$upper[[1L]]
  boundary <- if (inherits(prof, "error")) NA else interval$profile.boundary[[1L]]
  estimate <- target$estimate[[1L]]
  clean <- identical(conf_status, "profile") && all(is.finite(c(lower, estimate, upper))) &&
    lower < estimate && estimate < upper &&
    !isTRUE(boundary) && identical(fit$opt$convergence, 0L) && isTRUE(fit$sdr$pdHess)
  receipt <- data.frame(
    cell_id = contract$cell_id,
    target_id = paste0(contract$cell_id, "::", contract$target),
    cohort_id = "arc1-gaussian-fixed-profile-feasibility",
    family = "gaussian", provider = "none",
    dgp_id = "arc1_gaussian_fixed_location_scale",
    dgp_version = sprintf("n%d_seed%d_current_source_v1", n, seed),
    formula = "bf(y ~ x, sigma ~ x); gaussian(identity/log)",
    true_parameter_scale = sprintf("%g on the %s linear-predictor scale", contract$truth, contract$dpar),
    profile_parameter = contract$target, seed = seed,
    execution_information_rung = paste0("n", n),
    binding_source = "tools/run-arc1-gaussian-fixed-profile-feasibility.R",
    source_sha = source_sha, runner_sha256 = runner_sha256,
    estimator = "ML", target_type = "direct",
    fixture_path = fixture_path, fixture_sha256 = fixture_sha256,
    profile_engine = "tmbprofile", promotion_eligible = clean,
    receipt_scope = "targetwise_interval_feasibility_only_no_coverage",
    conf_status = conf_status, estimate = estimate, lower = lower, upper = upper,
    convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess),
    profile_boundary = boundary, clamp_limited = FALSE,
    trace_complete = !inherits(prof, "error"),
    failure_reason = if (inherits(prof, "error")) conditionMessage(prof) else if (clean) "" else interval$profile.message[[1L]],
    trace_path = if (file.exists(trace_path)) trace_path else "",
    trace_sha256 = if (file.exists(trace_path)) file_sha256(trace_path) else "",
    interval_path = if (file.exists(interval_path)) interval_path else "",
    interval_sha256 = if (file.exists(interval_path)) file_sha256(interval_path) else "",
    stringsAsFactors = FALSE
  )
  receipt_path <- file.path(out, paste0(stem, "-receipt.tsv"))
  utils::write.table(receipt, receipt_path, sep = "\t", quote = FALSE, row.names = FALSE)
  receipt
}

receipts <- do.call(rbind, lapply(seq_len(nrow(contracts)), function(i) run_target(contracts[i, , drop = FALSE])))
print(receipts[c("cell_id", "target_id", "conf_status", "lower", "upper", "convergence", "pdHess", "profile_boundary", "promotion_eligible")])
if (!all(receipts$promotion_eligible)) quit(status = 2L)
