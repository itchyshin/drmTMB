#!/usr/bin/env Rscript
# t9 R harness — Gaussian location-scale (1|g) CI coverage
# Pin: drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a
# Expected runtime: over 3 h for the full lane (both engines).

args <- commandArgs(trailingOnly = TRUE)
parse_args <- function(args) {
  out <- list(
    G = NA_integer_, sd_g = NA_real_, n_rep = 300L, n_boot_rep = 100L,
    n_g = 10L, B = 199L, cell_index = 1L, out = NA_character_
  )
  i <- 1L
  while (i <= length(args)) {
    key <- sub("^--", "", args[[i]])
    val <- args[[i + 1L]]
    if (key == "G") out$G <- as.integer(val)
    else if (key == "sd_g") out$sd_g <- as.numeric(val)
    else if (key == "n_rep") out$n_rep <- as.integer(val)
    else if (key == "n_boot_rep") out$n_boot_rep <- as.integer(val)
    else if (key == "n_g") out$n_g <- as.integer(val)
    else if (key == "B") out$B <- as.integer(val)
    else if (key == "cell_index") out$cell_index <- as.integer(val)
    else if (key == "out") out$out <- val
    i <- i + 2L
  }
  out
}

opt <- parse_args(args)
stopifnot(!is.na(opt$G), !is.na(opt$sd_g), !is.na(opt$out))

Sys.setenv(
  OMP_NUM_THREADS = "1",
  OPENBLAS_NUM_THREADS = "1",
  MKL_NUM_THREADS = "1",
  TMB_NUM_THREADS = "1"
)
options(warn = 1)

suppressPackageStartupMessages(library(drmTMB))

SEED_BASE <- 20261016900
PARMS <- c("fixef:sigma:(Intercept)", "fixef:sigma:x", "sd:mu:(1 | g)")
TRUTH <- c(
  "fixef:sigma:(Intercept)" = 0,
  "fixef:sigma:x" = 0.3,
  "sd:mu:(1 | g)" = opt$sd_g
)

r_seed_from_spec <- function(spec) {
  as.integer(spec %% 2147483647)
}

simulate_dat <- function(G, n_g, sd_g, spec_seed) {
  set.seed(r_seed_from_spec(spec_seed))
  g <- factor(rep(seq_len(G), each = n_g))
  x <- rep(seq(-1, 1, length.out = n_g), times = G)
  u <- rnorm(G, 0, sd_g)
  sigma <- exp(0 + 0.3 * x)
  y <- 0 + 0.5 * x + u[as.integer(g)] + rnorm(length(x), 0, sigma)
  data.frame(y = y, x = x, g = g)
}

run_with_timeout <- function(expr, seconds, label) {
  warns <- character()
  t0 <- proc.time()[[3]]
  val <- tryCatch(
    {
      setTimeLimit(elapsed = seconds, transient = TRUE)
      on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE), add = TRUE)
      withCallingHandlers(
        force(expr),
        warning = function(w) {
          warns <<- c(warns, conditionMessage(w))
          invokeRestart("muffleWarning")
        }
      )
    },
    error = function(e) e
  )
  elapsed <- proc.time()[[3]] - t0
  if (inherits(val, "error")) {
    msg <- conditionMessage(val)
    timed_out <- grepl("reached elapsed time limit|time limit", msg, ignore.case = TRUE)
    return(list(
      ok = FALSE, value = NULL, elapsed = elapsed,
      error = if (timed_out) paste0("TIMEOUT_", label, ": ", msg) else paste0("ERROR_", label, ": ", msg),
      timed_out = timed_out, warns = warns
    ))
  }
  list(ok = TRUE, value = val, elapsed = elapsed, error = NA_character_, timed_out = FALSE, warns = warns)
}

estimate_from_fit <- function(fit, parm) {
  cf <- tryCatch(coef(fit), error = function(e) NULL)
  if (identical(parm, "fixef:sigma:(Intercept)") && !is.null(cf$sigma)) {
    return(unname(cf$sigma[["(Intercept)"]]))
  }
  if (identical(parm, "fixef:sigma:x") && !is.null(cf$sigma)) {
    return(unname(cf$sigma[["x"]]))
  }
  if (identical(parm, "sd:mu:(1 | g)")) {
    par <- tryCatch(fit$obj$env$last.par.best, error = function(e) NULL)
    if (!is.null(par)) {
      hit <- grep("log_sd_mu", names(par), value = TRUE)
      if (length(hit) >= 1L) return(exp(unname(par[[hit[[1L]]]])))
    }
  }
  NA_real_
}

empty_row <- function(spec_seed, r_seed, rep_i, method, parm, do_boot) {
  data.frame(
    engine = "drmTMB",
    cell_index = opt$cell_index,
    G = opt$G,
    sd_g = opt$sd_g,
    n_g = opt$n_g,
    n = opt$G * opt$n_g,
    rep = rep_i,
    spec_seed = spec_seed,
    r_seed = r_seed,
    method = method,
    parm = parm,
    truth = unname(TRUTH[[parm]]),
    estimate = NA_real_,
    lower = NA_real_,
    upper = NA_real_,
    scale = NA_character_,
    conf_status = NA_character_,
    profile_engine = NA_character_,
    profile_boundary = NA,
    profile_message = NA_character_,
    bootstrap_n = NA_integer_,
    bootstrap_failed = NA_integer_,
    covered = NA,
    finite_interval = FALSE,
    silent_nan = FALSE,
    fit_ok = FALSE,
    timed_out = FALSE,
    error = NA_character_,
    warnings = NA_character_,
    elapsed_fit = NA_real_,
    elapsed_method = NA_real_,
    do_bootstrap = do_boot,
    stringsAsFactors = FALSE
  )
}

sanitize_tsv <- function(rows) {
  for (nm in names(rows)) {
    if (is.character(rows[[nm]])) {
      rows[[nm]] <- gsub("[\\r\\n\\t]+", " ", rows[[nm]], perl = TRUE)
    }
  }
  rows
}

append_rows <- function(path, rows) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  rows <- sanitize_tsv(rows)
  header <- !file.exists(path) || file.info(path)$size == 0
  utils::write.table(
    rows, file = path, sep = "\t", row.names = FALSE,
    col.names = header, quote = FALSE, append = !header
  )
}

done_reps <- integer()
if (file.exists(opt$out) && file.info(opt$out)$size > 0) {
  prev <- try(utils::read.delim(opt$out, stringsAsFactors = FALSE), silent = TRUE)
  if (!inherits(prev, "try-error") && nrow(prev) > 0) {
    done_reps <- unique(prev$rep)
  }
}

for (rep_i in seq_len(opt$n_rep)) {
  if (rep_i %in% done_reps) next
  spec_seed <- SEED_BASE + (opt$cell_index - 1L) * opt$n_rep + (rep_i - 1L)
  r_seed <- r_seed_from_spec(spec_seed)
  do_boot <- rep_i <= opt$n_boot_rep
  dat <- simulate_dat(opt$G, opt$n_g, opt$sd_g, spec_seed)

  fit_res <- run_with_timeout(
    drmTMB(bf(y ~ x + (1 | g), sigma ~ x), family = gaussian(), data = dat),
    seconds = 30,
    label = "fit"
  )

  rows <- list()
  methods <- c("wald", "profile", if (do_boot) "bootstrap")
  if (!fit_res$ok) {
    for (method in methods) {
      for (parm in PARMS) {
        row <- empty_row(spec_seed, r_seed, rep_i, method, parm, do_boot)
        row$error <- fit_res$error
        row$timed_out <- fit_res$timed_out
        row$elapsed_fit <- fit_res$elapsed
        row$warnings <- paste(fit_res$warns, collapse = " | ")
        rows[[length(rows) + 1L]] <- row
      }
    }
    append_rows(opt$out, do.call(rbind, rows))
    cat(sprintf(
      "cell=%d G=%d sd_g=%s rep=%d FIT_FAIL %s\n",
      opt$cell_index, opt$G, opt$sd_g, rep_i, fit_res$error
    ))
    next
  }

  fit <- fit_res$value
  for (method in methods) {
    timeout_sec <- switch(method, wald = 15, profile = 90, bootstrap = 180)
    ci_res <- run_with_timeout(
      {
        if (identical(method, "bootstrap")) {
          confint(fit, parm = PARMS, method = "bootstrap", R = opt$B, seed = r_seed)
        } else {
          confint(fit, parm = PARMS, method = method)
        }
      },
      seconds = timeout_sec,
      label = method
    )
    if (!ci_res$ok) {
      for (parm in PARMS) {
        row <- empty_row(spec_seed, r_seed, rep_i, method, parm, do_boot)
        row$fit_ok <- TRUE
        row$error <- ci_res$error
        row$timed_out <- ci_res$timed_out
        row$elapsed_fit <- fit_res$elapsed
        row$elapsed_method <- ci_res$elapsed
        row$warnings <- paste(c(fit_res$warns, ci_res$warns), collapse = " | ")
        rows[[length(rows) + 1L]] <- row
      }
      next
    }
    ci <- ci_res$value
    for (parm in PARMS) {
      row <- empty_row(spec_seed, r_seed, rep_i, method, parm, do_boot)
      row$fit_ok <- TRUE
      row$elapsed_fit <- fit_res$elapsed
      row$elapsed_method <- ci_res$elapsed
      hit <- ci[ci$parm == parm, , drop = FALSE]
      if (nrow(hit) != 1L) {
        row$error <- sprintf("ERROR_%s: expected 1 row for %s, got %d", method, parm, nrow(hit))
        rows[[length(rows) + 1L]] <- row
        next
      }
      row$estimate <- estimate_from_fit(fit, parm)
      row$lower <- as.numeric(hit$lower[[1L]])
      row$upper <- as.numeric(hit$upper[[1L]])
      row$scale <- as.character(hit$scale[[1L]])
      row$conf_status <- as.character(hit$conf.status[[1L]])
      if ("profile.engine" %in% names(hit)) {
        row$profile_engine <- as.character(hit$profile.engine[[1L]])
      }
      if ("profile.boundary" %in% names(hit)) {
        row$profile_boundary <- as.logical(hit$profile.boundary[[1L]])
      }
      if ("profile.message" %in% names(hit)) {
        row$profile_message <- as.character(hit$profile.message[[1L]])
      }
      if ("bootstrap.n" %in% names(hit)) {
        row$bootstrap_n <- as.integer(hit$bootstrap.n[[1L]])
      }
      if ("bootstrap.failed" %in% names(hit)) {
        row$bootstrap_failed <- as.integer(hit$bootstrap.failed[[1L]])
      }
      finite <- is.finite(row$lower) && is.finite(row$upper)
      row$finite_interval <- finite
      status_ok <- !is.na(row$conf_status) && row$conf_status %in% c("wald", "profile", "bootstrap")
      has_nan <- (!is.finite(row$lower) || !is.finite(row$upper)) &&
        !is.na(row$lower) && !is.na(row$upper) &&
        (is.nan(row$lower) || is.nan(row$upper))
      row$silent_nan <- isTRUE(has_nan && status_ok)
      row$covered <- if (finite) (row$lower <= row$truth && row$truth <= row$upper) else NA
      row$warnings <- paste(c(fit_res$warns, ci_res$warns), collapse = " | ")
      rows[[length(rows) + 1L]] <- row
    }
  }
  out_df <- do.call(rbind, rows)
  append_rows(opt$out, out_df)
  n_fail <- sum(!is.na(out_df$error))
  n_nan <- sum(out_df$silent_nan, na.rm = TRUE)
  cat(sprintf(
    "cell=%d G=%d sd_g=%s rep=%03d fit=%.3fs n_fail=%d silent_nan=%d\n",
    opt$cell_index, opt$G, opt$sd_g, rep_i, fit_res$elapsed, n_fail, n_nan
  ))
}

cat("DONE cell", opt$cell_index, "\n")
