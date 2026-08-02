#!/usr/bin/env Rscript

# Arc 1 target-specific feasibility receipt for mc-0438.  This is deliberately
# a STOP-capable probe: it records every attempted profile and never edits the
# capability ledger or changes the public profile-ready surface.

args <- commandArgs(trailingOnly = TRUE)
value <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^--", name, "="), "", hit[[1L]])
}
n_tip <- as.integer(value("n-tip", "8"))
n_each <- as.integer(value("n-each", "8"))
seed <- as.integer(value("seed", "2026080201"))
if (length(args) && any(!grepl("^--(n-tip|n-each|seed)=", args))) {
  stop("Only --n-tip=, --n-each=, and --seed= are accepted.", call. = FALSE)
}
if (is.na(n_tip) || n_tip < 2L || is.na(n_each) || n_each < 1L || is.na(seed)) {
  stop("n-tip, n-each, and seed must be finite positive integers.", call. = FALSE)
}

script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]]))
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
source("tools/b1-breadth-contract.R")
source("tools/b1-breadth-adapters.R")
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
runner_sha256 <- sub(" .*", "", system2("shasum", c("-a", "256", script), stdout = TRUE))
file_sha256 <- function(path) sub(" .*", "", system2("shasum", c("-a", "256", path), stdout = TRUE))
out <- file.path(root, "docs/dev-log/interval-feasibility/results", sha, "arc1-mc0438-profile-feasibility", "mc-0438")
dir.create(out, recursive = TRUE, showWarnings = FALSE)

adapter <- b1_phylo_interaction_poisson(seed, "high")
# The B1 adapter's high rung fixes 8 groups/clade and 8 observations/pair.
# Rebuild its exact family/DGP with the explicit pair-level denominator here.
set.seed(seed)
tree1 <- b1_star_tree(paste0("plant", seq_len(n_tip)))
tree2 <- b1_star_tree(paste0("poll", seq_len(n_tip)))
grid <- expand.grid(plant = tree1$tip.label, pollinator = tree2$tip.label, stringsAsFactors = FALSE)
pair <- paste(grid$plant, grid$pollinator, sep = ":")
field <- stats::rnorm(length(pair), sd = .45)
names(field) <- pair
row <- rep(seq_len(nrow(grid)), each = n_each)
dat <- grid[row, , drop = FALSE]
dat$x <- stats::rnorm(nrow(dat))
dat$count <- stats::rpois(nrow(dat), lambda = exp(.45 - .20 * dat$x + field[paste(dat$plant, dat$pollinator, sep = ":")]))
fixture_path <- file.path(out, sprintf("fixture-npair%d-each%d-seed%d.tsv", nrow(grid), n_each, seed))
utils::write.table(dat, fixture_path, sep = "\t", quote = FALSE, row.names = FALSE)
fixture_sha256 <- file_sha256(fixture_path)
target <- "sd:mu:phylo_interaction(1 | plant:pollinator)"
formula_text <- "bf(count ~ x + phylo_interaction(1 | plant:pollinator, tree1 = tree1, tree2 = tree2)); poisson(log)"
fit <- drmTMB::drmTMB(
  drmTMB::bf(count ~ x + drmTMB::phylo_interaction(1 | plant:pollinator, tree1 = tree1, tree2 = tree2)),
  family = stats::poisson(link = "log"), data = dat, REML = FALSE,
  control = drmTMB::drm_control(se = FALSE)
)
profile_target <- subset(drmTMB::profile_targets(fit), parm == target)
if (nrow(profile_target) != 1L || !isTRUE(profile_target$profile_ready) ||
    !identical(profile_target$target_type, "direct")) {
  stop("mc-0438 direct target is not profile-ready.", call. = FALSE)
}
profile_fit <- tryCatch(stats::profile(fit, parm = target, trace = FALSE, ystep = .25, ytol = .05, maxit = 100), error = identity)
trace_path <- file.path(out, sprintf("mc-0438-npair%d-each%d-seed%d-trace.tsv", nrow(grid), n_each, seed))
interval_path <- file.path(out, sprintf("mc-0438-npair%d-each%d-seed%d-interval.tsv", nrow(grid), n_each, seed))
if (!inherits(profile_fit, "error")) {
  profile_fit$cell_id <- "mc-0438"
  profile_fit$target_id <- paste0("mc-0438::", target)
  profile_fit$seed <- seed
  profile_fit$information_rung <- sprintf("pair_groups_%d_each_%d", nrow(grid), n_each)
  utils::write.table(profile_fit, trace_path, sep = "\t", quote = FALSE, row.names = FALSE)
  profile_field <- function(name) {
    answer <- unique(profile_fit[[name]])
    if (length(answer) != 1L) stop("Profile field is not constant: ", name, call. = FALSE)
    answer[[1L]]
  }
  interval <- data.frame(
    parm = target, level = profile_field("level"),
    lower = profile_field("conf.low"), upper = profile_field("conf.high"),
    method = "profile", profile.engine = "tmbprofile",
    conf.status = profile_field("conf.status"),
    profile.boundary = !all(is.finite(c(profile_field("conf.low"), profile_target$estimate[[1L]], profile_field("conf.high")))) ||
      profile_field("conf.low") >= profile_target$estimate[[1L]] || profile_field("conf.high") <= profile_target$estimate[[1L]] ||
      !identical(profile_field("profile.message"), "ok"),
    profile.message = profile_field("profile.message"),
    cell_id = "mc-0438", target_id = paste0("mc-0438::", target), seed = seed,
    information_rung = sprintf("pair_groups_%d_each_%d", nrow(grid), n_each),
    stringsAsFactors = FALSE
  )
  utils::write.table(interval, interval_path, sep = "\t", quote = FALSE, row.names = FALSE)
}
conf_status <- if (inherits(profile_fit, "error")) "profile_error" else interval$conf.status[[1L]]
profile_boundary <- if (inherits(profile_fit, "error")) NA else interval$profile.boundary[[1L]]
lower <- if (inherits(profile_fit, "error")) NA_real_ else interval$lower[[1L]]
upper <- if (inherits(profile_fit, "error")) NA_real_ else interval$upper[[1L]]
receipt <- data.frame(
  cell_id = "mc-0438", target_id = paste0("mc-0438::", target), cohort_id = "arc1-mc0438-profile-feasibility",
  family = "poisson", provider = "phylo_interaction", dgp_id = "b1_phylo_interaction_poisson_pair_level",
  dgp_version = sprintf("pair_groups_%d_each_%d_seed_%d", nrow(grid), n_each, seed), formula = formula_text,
  true_parameter_scale = "0.45 on the Poisson log-mu pair-level phylogenetic-interaction SD scale",
  profile_parameter = target, seed = seed, execution_information_rung = sprintf("pair_groups_%d_each_%d", nrow(grid), n_each),
  denominator_rule = "n_pair_groups = n_plant * n_pollinator; retain every attempted pair-level profile",
  source_sha = sha, runner_sha256 = runner_sha256, estimator = "ML", target_type = "direct",
  fixture_path = fixture_path, fixture_sha256 = fixture_sha256,
  profile_engine = "tmbprofile", promotion_eligible = FALSE, receipt_scope = "feasibility_stop_not_ledger_promotion",
  conf_status = conf_status, estimate = profile_target$estimate[[1L]], lower = lower, upper = upper,
  convergence = fit$opt$convergence, hessian_requested = FALSE, pdHess = NA, profile_boundary = profile_boundary,
  clamp_limited = FALSE, trace_complete = !inherits(profile_fit, "error"),
  failure_reason = if (inherits(profile_fit, "error")) {
    conditionMessage(profile_fit)
  } else if (any(!is.finite(c(lower, upper)))) {
    "nonfinite_interval"
  } else {
    interval$profile.message[[1L]]
  },
  trace_path = if (file.exists(trace_path)) trace_path else "",
  trace_sha256 = if (file.exists(trace_path)) file_sha256(trace_path) else "",
  interval_path = if (file.exists(interval_path)) interval_path else "",
  interval_sha256 = if (file.exists(interval_path)) file_sha256(interval_path) else "",
  stringsAsFactors = FALSE
)
utils::write.table(receipt, file.path(out, sprintf("mc-0438-npair%d-each%d-seed%d-receipt.tsv", nrow(grid), n_each, seed)), sep = "\t", quote = FALSE, row.names = FALSE)
print(receipt)
