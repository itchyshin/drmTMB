#!/usr/bin/env Rscript

# Arc 3 point-fit gate + local profile smoke for mc-0321 (gaussian) and
# mc-0409 (nbinom2), both targeting `sd:mu:phylo_interaction(1 |
# plant:pollinator)`. See tools/arc3-phylo-interaction-fixtures.R's header
# for why this ladder exists (mc-0438's Poisson STOP at the same target).
#
# Streams one row per (family, rung, seed) fit to stdout AND to a TSV,
# flushing after every row, so a stop mid-run still leaves usable evidence.

args <- commandArgs(trailingOnly = TRUE)
script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[[1L]]))
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root)
pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
source("tools/arc3-phylo-interaction-fixtures.R")

out_dir <- "/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/4775443f-332b-48b0-aa32-ec256d627713/scratchpad"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_path <- file.path(out_dir, "arc3-phylo-interaction-gate.tsv")
log_path <- file.path(out_dir, "arc3-phylo-interaction-gate.log")
con <- file(out_path, open = "a")
logcon <- file(log_path, open = "a")

target <- "sd:mu:phylo_interaction(1 | plant:pollinator)"
sd_name <- "phylo_interaction(1 | plant:pollinator)"

rungs <- list(
  list(rung = "star_np8_npo8_each8",  n_plant = 8L, n_pollinator = 8L, n_each = 8L,  tree_type = "star"),
  list(rung = "star_np8_npo8_each20", n_plant = 8L, n_pollinator = 8L, n_each = 20L, tree_type = "star"),
  list(rung = "star_np8_npo8_each40", n_plant = 8L, n_pollinator = 8L, n_each = 40L, tree_type = "star"),
  list(rung = "bal_np4_npo4_each20",  n_plant = 4L, n_pollinator = 4L, n_each = 20L, tree_type = "balanced")
)
seeds <- c(101L, 202L, 303L)
sd_pair <- 0.6

run_one <- function(family_name, rung_spec, seed) {
  writeLines(sprintf(
    "[%s] %s rung=%s seed=%d starting", format(Sys.time()), family_name, rung_spec$rung, seed
  ), logcon); flush(logcon)

  t0 <- Sys.time()
  row <- tryCatch({
    if (identical(family_name, "gaussian")) {
      fx <- arc3_phylo_interaction_gaussian_fixture(
        n_plant = rung_spec$n_plant, n_pollinator = rung_spec$n_pollinator,
        n_each = rung_spec$n_each, sd_pair = sd_pair, tree_type = rung_spec$tree_type, seed = seed
      )
      plant_tree <- fx$plant_tree; pollinator_tree <- fx$pollinator_tree
      fit <- drmTMB::drmTMB(
        drmTMB::bf(
          y ~ x + drmTMB::phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree),
          sigma ~ 1
        ),
        family = stats::gaussian(), data = fx$data
      )
    } else {
      fx <- arc3_phylo_interaction_nbinom2_fixture(
        n_plant = rung_spec$n_plant, n_pollinator = rung_spec$n_pollinator,
        n_each = rung_spec$n_each, sd_pair = sd_pair, tree_type = rung_spec$tree_type, seed = seed
      )
      plant_tree <- fx$plant_tree; pollinator_tree <- fx$pollinator_tree
      fit <- drmTMB::drmTMB(
        drmTMB::bf(
          nb2 ~ x + drmTMB::phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree),
          sigma ~ 1
        ),
        family = drmTMB::nbinom2(), data = fx$data
      )
    }
    fit_time <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    est <- unname(fit$sdpars$mu[[sd_name]])
    rel_err <- abs(est - sd_pair) / sd_pair
    targets <- drmTMB::profile_targets(fit)
    tr <- subset(targets, parm == target)
    profile_ready <- nrow(tr) == 1L && isTRUE(tr$profile_ready) && identical(tr$target_type, "direct")

    conf_status <- NA_character_; lower <- NA_real_; upper <- NA_real_
    profile_time <- NA_real_; profile_error <- ""
    if (profile_ready) {
      t1 <- Sys.time()
      prof <- tryCatch(stats::profile(fit, parm = target, trace = FALSE), error = identity)
      profile_time <- as.numeric(difftime(Sys.time(), t1, units = "secs"))
      if (inherits(prof, "error")) {
        profile_error <- conditionMessage(prof)
      } else {
        conf_status <- unique(prof$conf.status)[[1L]]
        lower <- unique(prof$conf.low)[[1L]]
        upper <- unique(prof$conf.high)[[1L]]
        profile_error <- unique(prof$profile.message)[[1L]]
      }
    }
    finite_ordered <- profile_ready && all(is.finite(c(lower, est, upper))) && lower < est && est < upper
    data.frame(
      family = family_name, rung = rung_spec$rung, tree_type = rung_spec$tree_type,
      n_plant = rung_spec$n_plant, n_pollinator = rung_spec$n_pollinator, n_each = rung_spec$n_each,
      n_pair = fx$n_pair, n_obs = nrow(fx$data), seed = seed, sd_true = sd_pair,
      sd_est = est, rel_err = rel_err, convergence = fit$opt$convergence,
      pdHess = isTRUE(fit$sdr$pdHess), fit_time_s = round(fit_time, 3),
      profile_ready = profile_ready, conf_status = conf_status,
      lower = lower, upper = upper, finite_ordered = finite_ordered,
      profile_time_s = round(profile_time, 3), profile_message = profile_error,
      error = "", stringsAsFactors = FALSE
    )
  }, error = function(e) {
    data.frame(
      family = family_name, rung = rung_spec$rung, tree_type = rung_spec$tree_type,
      n_plant = rung_spec$n_plant, n_pollinator = rung_spec$n_pollinator, n_each = rung_spec$n_each,
      n_pair = NA_integer_, n_obs = NA_integer_, seed = seed, sd_true = sd_pair,
      sd_est = NA_real_, rel_err = NA_real_, convergence = NA_integer_,
      pdHess = NA, fit_time_s = as.numeric(difftime(Sys.time(), t0, units = "secs")),
      profile_ready = NA, conf_status = NA_character_,
      lower = NA_real_, upper = NA_real_, finite_ordered = NA,
      profile_time_s = NA_real_, profile_message = "",
      error = conditionMessage(e), stringsAsFactors = FALSE
    )
  })
  row
}

header_written <- FALSE
for (rung_spec in rungs) {
  for (family_name in c("gaussian", "nbinom2")) {
    for (seed in seeds) {
      row <- run_one(family_name, rung_spec, seed)
      utils::write.table(
        row, con, sep = "\t", quote = FALSE, row.names = FALSE,
        col.names = !header_written
      )
      flush(con)
      header_written <- TRUE
      print(row[c(
        "family", "rung", "seed", "sd_est", "rel_err", "convergence", "pdHess",
        "profile_ready", "conf_status", "lower", "upper", "finite_ordered", "error"
      )])
      flush(stdout())
      writeLines(sprintf(
        "[%s] %s rung=%s seed=%d done: sd_est=%.3f rel_err=%.3f conf_status=%s finite_ordered=%s",
        format(Sys.time()), family_name, rung_spec$rung, seed,
        ifelse(is.na(row$sd_est), NA, row$sd_est), ifelse(is.na(row$rel_err), NA, row$rel_err),
        ifelse(is.na(row$conf_status), "NA", row$conf_status), as.character(row$finite_ordered)
      ), logcon); flush(logcon)
    }
  }
}
close(con); close(logcon)
message("Done. Results at: ", out_path)
