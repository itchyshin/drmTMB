#!/usr/bin/env Rscript
# Pure S7 manifest builder.  It never loads drmTMB, invokes Julia, or calls
# Slurm.  The later approved worker consumes this exact fixture-by-seed grid.

r071_s7_fixture_table <- function() {
  data.frame(
    fixture = c("binomial_ri", "poisson_ri", "nb2_ri", "nb2_coupled"),
    fixture_index = 1:4,
    seed_base = c(71011000L, 71012000L, 71013000L, 71014000L),
    profile_attempt_count = c(6L, 6L, 8L, 14L),
    stringsAsFactors = FALSE
  )
}

r071_s7_validate_manifest <- function(manifest) {
  required <- c("array_index", "logical_task_id", "fixture", "fixture_index", "seed_index", "dgp_seed", "profile_attempt_count")
  if (!identical(names(manifest), required) || nrow(manifest) != 2000L) {
    stop("S7 manifest schema or denominator drift", call. = FALSE)
  }
  if (!identical(manifest$array_index, seq_len(2000L)) ||
      !identical(manifest$logical_task_id, seq_len(2000L)) ||
      anyDuplicated(manifest[c("fixture", "seed_index")]) ||
      anyDuplicated(manifest$dgp_seed) ||
      any(manifest$seed_index < 1L | manifest$seed_index > 500L)) {
    stop("S7 manifest bijection drift", call. = FALSE)
  }
  fixtures <- r071_s7_fixture_table()
  if (any(!manifest$fixture %in% fixtures$fixture) ||
      !identical(as.integer(table(factor(manifest$fixture, levels = fixtures$fixture))), rep.int(500L, 4L))) {
    stop("S7 manifest must retain 500 seeds for each frozen fixture", call. = FALSE)
  }
  expected_profiles <- fixtures$profile_attempt_count[match(manifest$fixture, fixtures$fixture)]
  if (!identical(manifest$profile_attempt_count, as.integer(expected_profiles))) {
    stop("S7 manifest profile-attempt count drift", call. = FALSE)
  }
  invisible(manifest)
}

r071_s7_fixture_targets <- function(fixture) {
  common <- data.frame(
    parm = c("fixef:mu:(Intercept)", "fixef:mu:x"),
    target_class = c("fixed-effect", "fixed-effect"),
    truth = c(-0.1, 0.55), stringsAsFactors = FALSE
  )
  if (identical(fixture, "binomial_ri")) {
    return(rbind(common, data.frame(
      parm = "sd:mu:(1 | group)", target_class = "random-effect-sd", truth = 0.45,
      stringsAsFactors = FALSE
    )))
  }
  if (identical(fixture, "poisson_ri")) {
    common$truth <- c(0.2, 0.35)
    return(rbind(common, data.frame(
      parm = "sd:mu:(1 | group)", target_class = "random-effect-sd", truth = 0.45,
      stringsAsFactors = FALSE
    )))
  }
  if (identical(fixture, "nb2_ri")) {
    common$truth <- c(0.2, 0.35)
    return(rbind(common, data.frame(
      parm = c("fixef:sigma:(Intercept)", "sd:mu:(1 | group)"),
      target_class = c("fixed-effect", "random-effect-sd"), truth = c(0.125, 0.45),
      stringsAsFactors = FALSE
    )))
  }
  if (identical(fixture, "nb2_coupled")) {
    return(data.frame(
      parm = c("fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)",
               "fixef:sigma:z", "cholesky:recov:L11", "cholesky:recov:L22",
               "cholesky:recov:L21"),
      target_class = c("fixed-effect", "fixed-effect", "fixed-effect", "fixed-effect",
                       "covariance-coordinate", "covariance-coordinate", "covariance-coordinate"),
      truth = c(0.2, 0.35, 0.15, -0.1, log(0.45), log(0.125), -0.10125),
      stringsAsFactors = FALSE
    ))
  }
  stop("unknown frozen S7 fixture: ", fixture, call. = FALSE)
}

r071_s7_validate_profile_plan <- function(plan) {
  required <- c("fixture", "engine", "parm", "target_class", "truth")
  if (!identical(names(plan), required) || nrow(plan) != 34L ||
      anyDuplicated(plan[c("fixture", "engine", "parm")]) ||
      any(!plan$engine %in% c("tmb", "julia")) || any(!is.finite(plan$truth))) {
    stop("S7 profile-plan schema or denominator drift", call. = FALSE)
  }
  expected <- r071_s7_fixture_table()
  counts <- as.integer(table(factor(plan$fixture, levels = expected$fixture)))
  if (!identical(counts, expected$profile_attempt_count) || any(!plan$fixture %in% expected$fixture)) {
    stop("S7 profile-plan fixture denominator drift", call. = FALSE)
  }
  invisible(plan)
}

r071_s7_profile_plan <- function() {
  fixtures <- r071_s7_fixture_table()$fixture
  rows <- lapply(fixtures, function(fixture) {
    targets <- r071_s7_fixture_targets(fixture)
    do.call(rbind, lapply(c("tmb", "julia"), function(engine) {
      data.frame(fixture = fixture, engine = engine, targets, stringsAsFactors = FALSE)
    }))
  })
  plan <- do.call(rbind, rows)
  row.names(plan) <- NULL
  r071_s7_validate_profile_plan(plan)
}

r071_s7_manifest <- function() {
  fixtures <- r071_s7_fixture_table()
  rows <- lapply(seq_len(nrow(fixtures)), function(i) {
    seed_index <- seq_len(500L)
    data.frame(
      fixture = fixtures$fixture[[i]],
      fixture_index = fixtures$fixture_index[[i]],
      seed_index = seed_index,
      dgp_seed = fixtures$seed_base[[i]] + seed_index,
      profile_attempt_count = fixtures$profile_attempt_count[[i]],
      stringsAsFactors = FALSE
    )
  })
  manifest <- do.call(rbind, rows)
  manifest$array_index <- seq_len(nrow(manifest))
  manifest$logical_task_id <- manifest$array_index
  manifest <- manifest[c("array_index", "logical_task_id", "fixture", "fixture_index", "seed_index", "dgp_seed", "profile_attempt_count")]
  row.names(manifest) <- NULL
  r071_s7_validate_manifest(manifest)
}

r071_s7_task <- function(manifest, array_index) {
  r071_s7_validate_manifest(manifest)
  if (length(array_index) != 1L || is.na(array_index) || array_index != as.integer(array_index) ||
      array_index < 1L || array_index > 2000L) {
    stop("array index is outside the frozen 1..2000 array", call. = FALSE)
  }
  manifest[manifest$array_index == as.integer(array_index), , drop = FALSE]
}

r071_s7_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (length(args) != 1L || !grepl("^--write=.+", args[[1L]])) {
    stop("usage: Rscript prepare-s7-campaign-manifest.R --write=PATH", call. = FALSE)
  }
  path <- sub("^--write=", "", args[[1L]])
  utils::write.table(r071_s7_manifest(), path, sep = "\t", quote = FALSE, row.names = FALSE)
}

if (sys.nframe() == 0L) r071_s7_main()
