#!/usr/bin/env Rscript

# Current-source Arc 1 profile receipt for the exact mc-0260m pooled-effect
# target. The between-study SD is deliberately outside this receipt.

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^--", name, "="), "", hit[[1L]])
}
if (length(args) && any(!grepl("^--(seed|k|out)=", args))) {
  stop("Only --seed=, --k=, and --out= are accepted.", call. = FALSE)
}
seed <- as.integer(arg_value("seed", "2026080231"))
k <- as.integer(arg_value("k", "48"))
if (is.na(seed) || is.na(k) || k < 24L) stop("seed must be finite and k must be at least 24.", call. = FALSE)

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
            "arc1-meta-v-profile-feasibility")
)
dir.create(out, recursive = TRUE, showWarnings = FALSE)

set.seed(seed)
truth_mu <- .20
truth_tau <- .25
vi <- stats::runif(k, min = .01, max = .08)
dat <- data.frame(yi = stats::rnorm(k, mean = truth_mu, sd = sqrt(vi + truth_tau^2)), vi = vi)
fixture_path <- file.path(out, sprintf("fixture-k%d-seed%d.tsv", k, seed))
utils::write.table(dat, fixture_path, sep = "\t", quote = FALSE, row.names = FALSE)
fixture_sha256 <- file_sha256(fixture_path)
fit <- drmTMB::drmTMB(
  drmTMB::bf(yi ~ 1 + drmTMB::meta_V(V = vi)),
  family = stats::gaussian(), data = dat, REML = FALSE
)
target_name <- "fixef:mu:(Intercept)"
target <- subset(drmTMB::profile_targets(fit), parm == target_name)
if (nrow(target) != 1L || !isTRUE(target$profile_ready) || !identical(target$target_type, "direct")) {
  stop("mc-0260m pooled-effect target is not an exact ready direct target.", call. = FALSE)
}
prof <- tryCatch(stats::profile(fit, parm = target_name, trace = FALSE), error = identity)
stem <- sprintf("mc-0260m-k%d-seed%d", k, seed)
trace_path <- file.path(out, paste0(stem, "-trace.tsv"))
interval_path <- file.path(out, paste0(stem, "-interval.tsv"))
if (!inherits(prof, "error")) {
  prof$cell_id <- "mc-0260m"
  prof$target_id <- "mc-0260m::fixef:mu:(Intercept)"
  prof$seed <- seed
  prof$information_rung <- paste0("K", k)
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
    cell_id = "mc-0260m", target_id = "mc-0260m::fixef:mu:(Intercept)",
    seed = seed, information_rung = paste0("K", k), stringsAsFactors = FALSE
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
  cell_id = "mc-0260m", target_id = "mc-0260m::fixef:mu:(Intercept)",
  cohort_id = "arc1-meta-v-profile-feasibility", family = "gaussian", provider = "meta_V",
  dgp_id = "arc1_meta_v_pooled_mean", dgp_version = sprintf("k%d_seed%d_current_source_v1", k, seed),
  formula = "bf(yi ~ 1 + meta_V(V = vi)); gaussian(identity)",
  true_parameter_scale = "0.20 pooled mean on the Gaussian identity scale",
  profile_parameter = target_name, seed = seed, execution_information_rung = paste0("K", k),
  binding_source = "tools/run-arc1-meta-v-profile-feasibility.R",
  source_sha = source_sha, runner_sha256 = runner_sha256, profile_engine = "tmbprofile",
  estimator = "ML", target_type = "direct",
  fixture_path = fixture_path, fixture_sha256 = fixture_sha256,
  promotion_eligible = clean, receipt_scope = "pooled_effect_only_no_tau_interval_no_coverage",
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
