#!/usr/bin/env Rscript

# Current-source Arc 1 profile receipt for mc-0266, the exact Gaussian
# residual-scale random-intercept SD target.

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^--", name, "="), "", hit[[1L]])
}
if (length(args) && any(!grepl("^--(seed|groups|each|out)=", args))) {
  stop("Only --seed=, --groups=, --each=, and --out= are accepted.", call. = FALSE)
}
seed <- as.integer(arg_value("seed", "2026080241"))
groups <- as.integer(arg_value("groups", "48"))
each <- as.integer(arg_value("each", "20"))
if (anyNA(c(seed, groups, each)) || groups < 16L || each < 4L) {
  stop("seed must be finite, groups >= 16, and each >= 4.", call. = FALSE)
}

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
            "arc1-gaussian-sigma-re-profile-feasibility")
)
dir.create(out, recursive = TRUE, showWarnings = FALSE)

set.seed(seed)
id <- factor(rep(seq_len(groups), each = each))
x <- stats::rnorm(length(id))
truth_sd <- .35
u_sigma <- stats::rnorm(groups, sd = truth_sd)
sigma <- exp(-.45 + u_sigma[id])
dat <- data.frame(y = .20 + .50 * x + stats::rnorm(length(id), sd = sigma), x = x, id = id)
fixture_path <- file.path(out, sprintf("fixture-g%d-each%d-seed%d.tsv", groups, each, seed))
utils::write.table(dat, fixture_path, sep = "\t", quote = FALSE, row.names = FALSE)
fixture_sha256 <- file_sha256(fixture_path)
fit <- drmTMB::drmTMB(
  drmTMB::bf(y ~ x, sigma ~ 1 + (1 | id)),
  family = stats::gaussian(), data = dat, REML = FALSE
)
target_name <- "sd:sigma:(1 | id)"
target <- subset(drmTMB::profile_targets(fit), parm == target_name)
if (nrow(target) != 1L || !isTRUE(target$profile_ready) || !identical(target$target_type, "direct")) {
  stop("mc-0266 residual-scale SD is not an exact ready direct target.", call. = FALSE)
}
prof <- tryCatch(stats::profile(fit, parm = target_name, trace = FALSE), error = identity)
stem <- sprintf("mc-0266-g%d-each%d-seed%d", groups, each, seed)
trace_path <- file.path(out, paste0(stem, "-trace.tsv"))
interval_path <- file.path(out, paste0(stem, "-interval.tsv"))
if (!inherits(prof, "error")) {
  prof$cell_id <- "mc-0266"
  prof$target_id <- "mc-0266::sd:sigma:(1 | id)"
  prof$seed <- seed
  prof$information_rung <- sprintf("g%d_each%d", groups, each)
  utils::write.table(prof, trace_path, sep = "\t", quote = FALSE, row.names = FALSE)
  profile_field <- function(name) {
    value <- unique(prof[[name]])
    if (length(value) != 1L) stop("Profile field is not constant: ", name, call. = FALSE)
    value[[1L]]
  }
  interval <- data.frame(
    parm = target_name, level = profile_field("level"),
    lower = profile_field("conf.low"), upper = profile_field("conf.high"),
    scale = profile_field("scale"), transformation = profile_field("transformation"),
    tmb_parameter = profile_field("tmb_parameter"), index = profile_field("index"),
    method = "profile", profile.engine = "tmbprofile",
    conf.status = profile_field("conf.status"),
    profile.boundary = !all(is.finite(c(profile_field("conf.low"), target$estimate[[1L]], profile_field("conf.high")))) ||
      profile_field("conf.low") >= target$estimate[[1L]] || profile_field("conf.high") <= target$estimate[[1L]] ||
      !identical(profile_field("profile.message"), "ok"),
    profile.message = profile_field("profile.message"),
    cell_id = "mc-0266", target_id = "mc-0266::sd:sigma:(1 | id)",
    seed = seed, information_rung = sprintf("g%d_each%d", groups, each),
    stringsAsFactors = FALSE
  )
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
  cell_id = "mc-0266", target_id = "mc-0266::sd:sigma:(1 | id)",
  cohort_id = "arc1-gaussian-sigma-re-profile-feasibility", family = "gaussian", provider = "ordinary_re",
  dgp_id = "arc1_gaussian_sigma_random_intercept",
  dgp_version = sprintf("g%d_each%d_seed%d_current_source_v1", groups, each, seed),
  formula = "bf(y ~ x, sigma ~ 1 + (1 | id)); gaussian(identity/log)",
  true_parameter_scale = "0.35 on the residual log-SD random-intercept SD scale",
  profile_parameter = target_name, seed = seed,
  execution_information_rung = sprintf("g%d_each%d", groups, each),
  binding_source = "tools/run-arc1-gaussian-sigma-re-profile-feasibility.R",
  source_sha = source_sha, runner_sha256 = runner_sha256, profile_engine = "tmbprofile",
  estimator = "ML", target_type = "direct",
  fixture_path = fixture_path, fixture_sha256 = fixture_sha256,
  promotion_eligible = clean, receipt_scope = "targetwise_interval_feasibility_only_no_coverage",
  conf_status = conf_status, estimate = estimate, lower = lower, upper = upper,
  convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess),
  profile_boundary = boundary, clamp_limited = FALSE, trace_complete = !inherits(prof, "error"),
  failure_reason = if (inherits(prof, "error")) conditionMessage(prof) else if (clean) "" else interval$profile.message[[1L]],
  trace_path = if (file.exists(trace_path)) trace_path else "",
  trace_sha256 = if (file.exists(trace_path)) file_sha256(trace_path) else "",
  interval_path = if (file.exists(interval_path)) interval_path else "",
  interval_sha256 = if (file.exists(interval_path)) file_sha256(interval_path) else "",
  stringsAsFactors = FALSE
)
utils::write.table(receipt, file.path(out, paste0(stem, "-receipt.tsv")), sep = "\t", quote = FALSE, row.names = FALSE)
print(receipt[c("cell_id", "target_id", "conf_status", "lower", "upper", "convergence", "pdHess", "profile_boundary", "promotion_eligible")])
if (!clean) quit(status = 2L)
