#!/usr/bin/env Rscript
# mc-0718 Totoro smoke: one job (toy / reject / one of 27 fits).
# Brief: docs/dev-log/research/2026-08-16-mc0718-totoro-smoke-brief.md
# Do not expand beyond the predeclared 27 recovery fits.

Sys.setenv(R_PROFILE_USER = "/dev/null")
options(warn = 1)

args <- commandArgs(trailingOnly = TRUE)
`%||%` <- function(a, b) if (is.null(a) || !nzchar(a)) b else a

parse_args <- function(args) {
  out <- list(
    mode = "fit",
    seed = NA_integer_,
    n_each = NA_integer_,
    method = NA_character_,
    repo = Sys.getenv("DRMTMB_REPO", unset = ""),
    lib = Sys.getenv("DRMTMB_LIB", unset = ""),
    out = "",
    git_sha = Sys.getenv("DRMTMB_GIT_SHA", unset = "")
  )
  i <- 1L
  while (i <= length(args)) {
    key <- sub("^--", "", args[[i]])
    if (i == length(args) || startsWith(args[[i + 1L]], "--")) {
      stop("Missing value for --", key, call. = FALSE)
    }
    out[[key]] <- args[[i + 1L]]
    i <- i + 2L
  }
  out$seed <- as.integer(out$seed)
  out$n_each <- as.integer(out$n_each)
  out
}

opt <- parse_args(args)
if (!nzchar(opt$repo)) stop("Need --repo", call. = FALSE)
if (!nzchar(opt$lib)) stop("Need --lib", call. = FALSE)
if (!nzchar(opt$out)) stop("Need --out", call. = FALSE)

.libPaths(c(opt$lib, .libPaths()))

poisson_q2_data <- function(
  n_group = 56L,
  n_each = 14L,
  sd_intercept = 0.65,
  sd_slope = 0.42,
  rho = 0.45,
  seed = 20260816L
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_group), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z_intercept <- stats::rnorm(n_group)
  z_slope <- stats::rnorm(n_group)
  u_intercept <- sd_intercept * z_intercept
  u_slope <- sd_slope * (rho * z_intercept + sqrt(1 - rho^2) * z_slope)
  eta <- -0.25 + 0.70 * x + u_intercept[id] + u_slope[id] * x
  list(
    data = data.frame(
      count = stats::rpois(n, lambda = exp(eta)),
      x = x,
      id = id
    ),
    truth = c(sd0 = sd_intercept, sd1 = sd_slope, rho = rho)
  )
}

classify_exception <- function(err) {
  msg <- conditionMessage(err)
  if (grepl("gradient|grad", msg, ignore.case = TRUE)) return("gradient")
  if (grepl("optim|nlminb|convergence", msg, ignore.case = TRUE)) return("optimizer")
  if (grepl("Hess|pdHess|singular", msg, ignore.case = TRUE)) return("hessian")
  if (grepl("extract|sdpars|corpars|VarCorr", msg, ignore.case = TRUE)) return("extractor")
  "other"
}

empty_row <- function(seed, n_each, method, git_sha, exception_class = "none") {
  data.frame(
    seed = as.integer(seed),
    n_each = as.integer(n_each),
    method = as.character(method),
    convergence = NA_integer_,
    pdHess = NA,
    sd0 = NA_real_,
    sd1 = NA_real_,
    rho_re = NA_real_,
    abs_err_sd0 = NA_real_,
    abs_err_sd1 = NA_real_,
    abs_err_rho = NA_real_,
    exception_class = exception_class,
    git_sha = as.character(git_sha),
    wall_sec = NA_real_,
    sd_names = NA_character_,
    cor_names = NA_character_,
    message = NA_character_,
    stringsAsFactors = FALSE
  )
}

extract_drmtmb_corr <- function(fit) {
  sd0 <- unname(fit$sdpars$mu[["(1 + x | id):(Intercept)"]])
  sd1 <- unname(fit$sdpars$mu[["(1 + x | id):x"]])
  rho_re <- unname(fit$corpars$mu[["cor((Intercept),x | id)"]])
  if (length(sd0) != 1L || length(sd1) != 1L || length(rho_re) != 1L) {
    stop("extractor names drifted from the design-17 table", call. = FALSE)
  }
  list(
    sd0 = as.numeric(sd0),
    sd1 = as.numeric(sd1),
    rho_re = as.numeric(rho_re),
    sd_names = paste(names(fit$sdpars$mu), collapse = "|"),
    cor_names = paste(names(fit$corpars$mu), collapse = "|")
  )
}

extract_drmtmb_iid <- function(fit) {
  sd0 <- unname(fit$sdpars$mu[["(1 | id)"]])
  sd1 <- unname(fit$sdpars$mu[["(0 + x | id)"]])
  if (length(sd0) != 1L || length(sd1) != 1L) {
    stop(
      "iid extractor names unexpected: ",
      paste(names(fit$sdpars$mu), collapse = " | "),
      call. = FALSE
    )
  }
  list(
    sd0 = as.numeric(sd0),
    sd1 = as.numeric(sd1),
    rho_re = NA_real_,
    sd_names = paste(names(fit$sdpars$mu), collapse = "|"),
    cor_names = paste(names(fit$corpars$mu), collapse = "|")
  )
}

extract_glmmtmb_corr <- function(fit) {
  vc <- glmmTMB::VarCorr(fit)$cond$id
  sds <- attr(vc, "stddev")
  cors <- attr(vc, "correlation")
  if (length(sds) < 2L || is.null(cors)) {
    stop("glmmTMB VarCorr missing unstructured id SDs/correlation", call. = FALSE)
  }
  list(
    sd0 = as.numeric(sds[[1L]]),
    sd1 = as.numeric(sds[[2L]]),
    rho_re = as.numeric(cors[1L, 2L]),
    sd_names = paste(names(sds), collapse = "|"),
    cor_names = "VarCorr(cond$id)"
  )
}

fit_one <- function(dat, method) {
  if (identical(method, "drmtmb_corr")) {
    fit <- drmTMB::drmTMB(
      drmTMB::bf(count ~ x + (1 + x | id)),
      family = stats::poisson(link = "log"),
      data = dat
    )
    conv <- as.integer(fit$opt$convergence)
    pd <- tryCatch(isTRUE(fit$sdr$pdHess), error = function(e) NA)
    ext <- extract_drmtmb_corr(fit)
    return(list(convergence = conv, pdHess = pd, ext = ext))
  }
  if (identical(method, "drmtmb_iid")) {
    fit <- drmTMB::drmTMB(
      drmTMB::bf(count ~ x + (1 | id) + (0 + x | id)),
      family = stats::poisson(link = "log"),
      data = dat
    )
    conv <- as.integer(fit$opt$convergence)
    pd <- tryCatch(isTRUE(fit$sdr$pdHess), error = function(e) NA)
    ext <- extract_drmtmb_iid(fit)
    return(list(convergence = conv, pdHess = pd, ext = ext))
  }
  if (identical(method, "glmmtmb_corr")) {
    if (!requireNamespace("glmmTMB", quietly = TRUE)) {
      stop("glmmTMB is missing; do not silently switch to glmer", call. = FALSE)
    }
    fit <- glmmTMB::glmmTMB(
      count ~ x + (1 + x | id),
      family = stats::poisson(),
      data = dat
    )
    conv <- as.integer(fit$fit$convergence)
    sdr <- tryCatch(fit$sdr, error = function(e) NULL)
    pd <- if (!is.null(sdr) && !is.null(sdr$pdHess)) isTRUE(sdr$pdHess) else NA
    ext <- extract_glmmtmb_corr(fit)
    return(list(convergence = conv, pdHess = pd, ext = ext))
  }
  stop("Unknown method: ", method, call. = FALSE)
}

write_row <- function(row, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(
    row,
    file = path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    col.names = TRUE
  )
}

run_fit <- function(opt) {
  truth_sd0 <- 0.65
  truth_sd1 <- 0.42
  truth_rho <- 0.45
  row <- empty_row(opt$seed, opt$n_each, opt$method, opt$git_sha)
  t0 <- proc.time()[["elapsed"]]
  sim <- tryCatch(
    poisson_q2_data(n_group = 56L, n_each = opt$n_each, seed = opt$seed),
    error = function(e) e
  )
  if (inherits(sim, "error")) {
    row$exception_class <- classify_exception(sim)
    row$message <- conditionMessage(sim)
    row$wall_sec <- proc.time()[["elapsed"]] - t0
    write_row(row, opt$out)
    return(invisible(row))
  }
  res <- tryCatch(fit_one(sim$data, opt$method), error = function(e) e)
  row$wall_sec <- proc.time()[["elapsed"]] - t0
  if (inherits(res, "error")) {
    row$exception_class <- classify_exception(res)
    row$message <- conditionMessage(res)
    write_row(row, opt$out)
    return(invisible(row))
  }
  row$convergence <- res$convergence
  row$pdHess <- res$pdHess
  row$sd0 <- res$ext$sd0
  row$sd1 <- res$ext$sd1
  row$rho_re <- res$ext$rho_re
  row$abs_err_sd0 <- abs(row$sd0 - truth_sd0)
  row$abs_err_sd1 <- abs(row$sd1 - truth_sd1)
  row$abs_err_rho <- if (is.na(row$rho_re)) NA_real_ else abs(row$rho_re - truth_rho)
  row$sd_names <- res$ext$sd_names
  row$cor_names <- res$ext$cor_names
  row$exception_class <- "none"
  write_row(row, opt$out)
  invisible(row)
}

run_toy <- function(opt) {
  # Plumbing check only. Seed 881000 is not in the 27-fit denominator.
  toy_seed <- 881000L
  toy_n <- 4L
  sim <- poisson_q2_data(n_group = 12L, n_each = toy_n, seed = toy_seed)
  fit <- drmTMB::drmTMB(
    drmTMB::bf(count ~ x + (1 + x | id)),
    family = stats::poisson(link = "log"),
    data = sim$data
  )
  ext <- extract_drmtmb_corr(fit)
  vals <- c(ext$sd0, ext$sd1, ext$rho_re)
  if (any(!is.finite(vals))) {
    stop("TOY FAIL: empty/NA extractors: ", paste(vals, collapse = ", "), call. = FALSE)
  }
  row <- empty_row(toy_seed, toy_n, "drmtmb_corr_toy", opt$git_sha)
  row$convergence <- as.integer(fit$opt$convergence)
  row$pdHess <- tryCatch(isTRUE(fit$sdr$pdHess), error = function(e) NA)
  row$sd0 <- ext$sd0
  row$sd1 <- ext$sd1
  row$rho_re <- ext$rho_re
  row$sd_names <- ext$sd_names
  row$cor_names <- ext$cor_names
  row$exception_class <- "none"
  write_row(row, opt$out)
  cat(
    sprintf(
      "TOY PASS conv=%s pdHess=%s sd0=%.4f sd1=%.4f rho=%.4f names=%s / %s\n",
      row$convergence, row$pdHess, row$sd0, row$sd1, row$rho_re,
      row$sd_names, row$cor_names
    )
  )
}

run_reject <- function(opt) {
  sim <- poisson_q2_data(n_group = 10L, n_each = 8L, seed = 881999L)
  q2 <- drmTMB::bf(count ~ x + (1 + x | id))
  probes <- list(
    reml = function() {
      drmTMB::drmTMB(
        q2,
        family = stats::poisson(link = "log"),
        data = sim$data,
        REML = TRUE
      )
    },
    missing_response = function() {
      dat <- sim$data
      dat$count[[1L]] <- NA_integer_
      drmTMB::drmTMB(
        q2,
        family = stats::poisson(link = "log"),
        data = dat,
        missing = drmTMB::miss_control(response = "include")
      )
    },
    labelled = function() {
      drmTMB::drmTMB(
        drmTMB::bf(count ~ x + (1 + x | p | id)),
        family = stats::poisson(link = "log"),
        data = sim$data
      )
    },
    mixed = function() {
      drmTMB::drmTMB(
        drmTMB::bf(count ~ x + (1 | id) + (1 + x | id)),
        family = stats::poisson(link = "log"),
        data = sim$data
      )
    },
    nbinom2 = function() {
      drmTMB::drmTMB(
        q2,
        family = drmTMB::nbinom2(),
        data = sim$data
      )
    }
  )
  rows <- lapply(names(probes), function(name) {
    err <- tryCatch({
      probes[[name]]()
      NULL
    }, error = function(e) e)
    data.frame(
      neighbour = name,
      stayed_red = inherits(err, "error"),
      message = if (inherits(err, "error")) conditionMessage(err) else "FITTED",
      git_sha = opt$git_sha,
      stringsAsFactors = FALSE
    )
  })
  tab <- do.call(rbind, rows)
  dir.create(dirname(opt$out), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(tab, opt$out, sep = "\t", quote = FALSE, row.names = FALSE)
  if (!all(tab$stayed_red)) {
    stop(
      "REJECTION MATRIX FAIL: a neighbour fitted: ",
      paste(tab$neighbour[!tab$stayed_red], collapse = ", "),
      call. = FALSE
    )
  }
  cat("REJECTION MATRIX PASS\n")
  print(tab)
}

if (!requireNamespace("drmTMB", quietly = TRUE)) {
  stop("drmTMB is not installed in ", opt$lib, call. = FALSE)
}

if (identical(opt$mode, "toy")) {
  run_toy(opt)
} else if (identical(opt$mode, "reject")) {
  run_reject(opt)
} else if (identical(opt$mode, "fit")) {
  if (is.na(opt$seed) || is.na(opt$n_each) || !nzchar(opt$method)) {
    stop("fit mode needs --seed --n_each --method", call. = FALSE)
  }
  run_fit(opt)
} else {
  stop("Unknown --mode ", opt$mode, call. = FALSE)
}
