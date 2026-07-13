# TMB 1.9.21 marginal-Gauss-Kronrod mechanism probe.
# Standalone evidence only: this does not wire integration into drmTMB.
Sys.setenv(OPENBLAS_NUM_THREADS = "1")

suppressPackageStartupMessages({
  library(TMB)
  library(lme4)
})

args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)
if (length(script_arg) != 1L) stop("Run this probe with Rscript.")
script <- normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)
out_dir <- dirname(script)
cpp_source <- file.path(out_dir, "binomial_ri.cpp")

build_dir <- tempfile("drmtmb-marginal-gk-")
dir.create(build_dir)
on.exit(unlink(build_dir, recursive = TRUE, force = TRUE), add = TRUE)
cpp_build <- file.path(build_dir, basename(cpp_source))
stopifnot(file.copy(cpp_source, cpp_build))

old <- setwd(build_dir)
on.exit(setwd(old), add = TRUE)
TMB::compile(cpp_build, framework = "TMBad", flags = "-O2")
dll <- tools::file_path_sans_ext(basename(cpp_build))
dll_path <- TMB::dynlib(file.path(build_dir, dll))
dyn.load(dll_path)
on.exit(dyn.unload(dll_path), add = TRUE)

seed <- 20260801L
M <- 40L
n_each <- 2L
sd_true <- 0.8
beta_true <- c(-0.2, 0.7)

# Preserve the exact frozen fixture from the prior 80-seed study. Its
# mean-centering makes it unsuitable for population-SD evidence, but does not
# invalidate a same-data integration-mechanism comparison.
set.seed(seed)
id <- factor(rep(seq_len(M), each = n_each))
x <- stats::rnorm(length(id))
u <- stats::rnorm(M, sd = sd_true)
u <- u - mean(u)
p <- stats::plogis(beta_true[[1L]] + beta_true[[2L]] * x + u[id])
y <- stats::rbinom(length(id), 1L, p)
dat <- data.frame(y = y, x = x, id = id)

tmb_data <- list(
  y = as.numeric(y),
  x = as.numeric(x),
  group = as.integer(id) - 1L,
  n_group = M
)
parameters <- list(beta = c(0, 0), log_sd = log(0.5), u = rep(0, M))

make_laplace <- function() {
  TMB::MakeADFun(
    data = tmb_data,
    parameters = parameters,
    random = "u",
    DLL = dll,
    silent = TRUE
  )
}
make_gk <- function() {
  TMB::MakeADFun(
    data = tmb_data,
    parameters = parameters,
    random = "u",
    integrate = list(u = TMB:::GK(adaptive = TRUE)),
    DLL = dll,
    silent = TRUE
  )
}

obj_laplace <- make_laplace()
obj_gk <- make_gk()

expected_outer <- c("beta", "beta", "log_sd")
stopifnot(
  identical(names(obj_laplace$par), expected_outer),
  identical(names(obj_gk$par), expected_outer),
  length(obj_gk$env$random) == 0L,
  length(obj_gk$par) == 3L,
  all(is.finite(obj_gk$gr(obj_gk$par)))
)

starts <- rbind(
  truth = c(beta_true, log(sd_true)),
  moderate = c(0, 0, log(0.5)),
  small_sd = c(0, 0, log(0.05))
)
lower <- c(-5, -5, -12)
upper <- c(5, 5, 3)
nl_control <- list(
  eval.max = 5000L,
  iter.max = 3000L,
  rel.tol = 1e-12,
  x.tol = 1e-10
)

fit_tmb <- function(obj, method) {
  rows <- lapply(seq_len(nrow(starts)), function(i) {
    opt <- nlminb(
      start = starts[i, ],
      objective = obj$fn,
      gradient = obj$gr,
      lower = lower,
      upper = upper,
      control = nl_control
    )
    grad <- obj$gr(opt$par)
    data.frame(
      method = method,
      start = rownames(starts)[[i]],
      beta0 = opt$par[[1L]],
      beta1 = opt$par[[2L]],
      sd = exp(opt$par[[3L]]),
      log_sd = opt$par[[3L]],
      objective = opt$objective,
      convergence = opt$convergence,
      max_abs_gradient = max(abs(grad)),
      message = if (is.null(opt$message)) "" else opt$message,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

fit_lme4 <- function(nAGQ, method) {
  rows <- lapply(seq_len(nrow(starts)), function(i) {
    control <- lme4::glmerControl(
      optimizer = "bobyqa",
      optCtrl = list(maxfun = 500000L, rhobeg = 1e-3, rhoend = 1e-10),
      calc.derivs = TRUE
    )
    fit <- suppressWarnings(lme4::glmer(
      y ~ x + (1 | id),
      data = dat,
      family = stats::binomial(),
      nAGQ = nAGQ,
      start = list(theta = exp(starts[i, 3L]), fixef = starts[i, 1:2]),
      control = control
    ))
    grad <- fit@optinfo$derivs$gradient
    if (is.null(grad)) grad <- NA_real_
    data.frame(
      method = method,
      start = rownames(starts)[[i]],
      beta0 = unname(lme4::fixef(fit)[[1L]]),
      beta1 = unname(lme4::fixef(fit)[[2L]]),
      sd = unname(lme4::getME(fit, "theta")[[1L]]),
      log_sd = if (lme4::getME(fit, "theta")[[1L]] > 0) {
        log(lme4::getME(fit, "theta")[[1L]])
      } else {
        -Inf
      },
      objective = -as.numeric(stats::logLik(fit)),
      convergence = fit@optinfo$conv$opt,
      max_abs_gradient = if (all(is.na(grad))) NA_real_ else max(abs(grad)),
      message = paste(fit@optinfo$conv$lme4$messages, collapse = "; "),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

group_rows <- split(seq_len(nrow(dat)), dat$id)
direct_nll <- function(theta, diagnostics = FALSE) {
  beta <- theta[1:2]
  sd <- exp(theta[[3L]])
  integral_errors <- numeric(length(group_rows))
  nll_errors <- numeric(length(group_rows))
  values <- vapply(seq_along(group_rows), function(g) {
    ii <- group_rows[[g]]
    integrand <- function(z) {
      vapply(z, function(zz) {
        eta <- beta[[1L]] + beta[[2L]] * dat$x[ii] + sd * zz
        exp(
          sum(stats::dbinom(
            dat$y[ii], 1L, stats::plogis(eta), log = TRUE
          )) + stats::dnorm(zz, log = TRUE)
        )
      }, numeric(1L))
    }
    ans <- stats::integrate(
      integrand,
      lower = -Inf,
      upper = Inf,
      subdivisions = 2000L,
      rel.tol = 1e-11,
      abs.tol = 1e-12,
      stop.on.error = TRUE
    )
    stopifnot(ans$value > ans$abs.error)
    integral_errors[[g]] <<- ans$abs.error
    # integrate() estimates error on the probability-integral scale. Propagate
    # its recorded lower endpoint through -log() to obtain the corresponding
    # NLL error estimate.
    nll_errors[[g]] <<- -log(ans$value - ans$abs.error) + log(ans$value)
    -log(ans$value)
  }, numeric(1L))
  value <- sum(values)
  if (diagnostics) {
    return(list(
      value = value,
      sum_integral_abs_error = sum(integral_errors),
      sum_nll_abs_error = sum(nll_errors),
      max_nll_abs_error = max(nll_errors)
    ))
  }
  value
}

numeric_gradient <- function(fn, par, step = 1e-5) {
  vapply(seq_along(par), function(j) {
    h <- step * max(1, abs(par[[j]]))
    upper_par <- lower_par <- par
    upper_par[[j]] <- upper_par[[j]] + h
    lower_par[[j]] <- lower_par[[j]] - h
    (fn(upper_par) - fn(lower_par)) / (2 * h)
  }, numeric(1L))
}

fit_direct <- do.call(rbind, lapply(seq_len(nrow(starts)), function(i) {
  opt <- nlminb(
    start = starts[i, ],
    objective = direct_nll,
    lower = lower,
    upper = upper,
    control = nl_control
  )
  grad <- numeric_gradient(direct_nll, opt$par)
  data.frame(
    method = "direct_integral",
    start = rownames(starts)[[i]],
    beta0 = opt$par[[1L]],
    beta1 = opt$par[[2L]],
    sd = exp(opt$par[[3L]]),
    log_sd = opt$par[[3L]],
    objective = opt$objective,
    convergence = opt$convergence,
    max_abs_gradient = max(abs(grad)),
    message = paste0(
      "nlminb: ", if (is.null(opt$message)) "" else opt$message,
      "; finite numerical gradient=", all(is.finite(grad))
    ),
    stringsAsFactors = FALSE
  )
}))

fits <- rbind(
  fit_tmb(obj_laplace, "TMB_Laplace"),
  fit_tmb(obj_gk, "TMB_adaptive_marginal_GK"),
  fit_lme4(1L, "glmer_nAGQ1"),
  fit_lme4(25L, "glmer_nAGQ25"),
  fit_direct
)

devfun1 <- lme4::glmer(
  y ~ x + (1 | id), data = dat, family = stats::binomial(),
  nAGQ = 1L, devFunOnly = TRUE
)
devfun25 <- lme4::glmer(
  y ~ x + (1 | id), data = dat, family = stats::binomial(),
  nAGQ = 25L, devFunOnly = TRUE
)

numeric_devfun_gradient <- function(devfun, sd, beta, step = 1e-5) {
  par <- c(sd, beta)
  ans <- numeric(length(par))
  # The RE-SD parameter is constrained to be non-negative. Use a forward
  # derivative at the boundary and a central derivative otherwise.
  h_sd <- step * max(1, sd)
  ans[[1L]] <- if (sd <= h_sd) {
    (devfun(c(sd + h_sd, beta)) - devfun(par)) / h_sd
  } else {
    (devfun(c(sd + h_sd, beta)) - devfun(c(sd - h_sd, beta))) / (2 * h_sd)
  }
  for (j in 2:3) {
    h <- step * max(1, abs(par[[j]]))
    upper_par <- lower_par <- par
    upper_par[[j]] <- upper_par[[j]] + h
    lower_par[[j]] <- lower_par[[j]] - h
    ans[[j]] <- (devfun(upper_par) - devfun(lower_par)) / (2 * h)
  }
  # devfun is deviance; convert derivatives to the NLL scale.
  0.5 * ans
}

for (i in seq_len(nrow(fits))) {
  if (fits$method[[i]] == "glmer_nAGQ1") {
    grad <- numeric_devfun_gradient(
      devfun1, fits$sd[[i]], c(fits$beta0[[i]], fits$beta1[[i]])
    )
    fits$max_abs_gradient[[i]] <- max(abs(grad))
  }
  if (fits$method[[i]] == "glmer_nAGQ25") {
    grad <- numeric_devfun_gradient(
      devfun25, fits$sd[[i]], c(fits$beta0[[i]], fits$beta1[[i]])
    )
    fits$max_abs_gradient[[i]] <- max(abs(grad))
  }
}

best <- do.call(rbind, lapply(split(fits, fits$method), function(z) {
  z[which.min(z$objective), , drop = FALSE]
}))
row.names(best) <- NULL

point_rows <- rbind(
  data.frame(point = "truth", beta0 = beta_true[[1L]], beta1 = beta_true[[2L]], sd = sd_true),
  transform(best[, c("method", "beta0", "beta1", "sd")], point = method)[, c("point", "beta0", "beta1", "sd")]
)
point_rows$sd_eval <- pmax(point_rows$sd, exp(lower[[3L]]))

evaluate_point <- function(row) {
  theta <- c(row$beta0, row$beta1, log(row$sd_eval))
  direct <- direct_nll(theta, diagnostics = TRUE)
  glmer_arg <- c(row$sd_eval, row$beta0, row$beta1)
  gl1a <- 0.5 * devfun1(glmer_arg)
  gl1b <- 0.5 * devfun1(glmer_arg)
  gl25a <- 0.5 * devfun25(glmer_arg)
  gl25b <- 0.5 * devfun25(glmer_arg)
  data.frame(
    point = row$point,
    beta0 = row$beta0,
    beta1 = row$beta1,
    sd = row$sd,
    sd_eval = row$sd_eval,
    direct_nll = direct$value,
    direct_sum_integral_abs_error = direct$sum_integral_abs_error,
    direct_sum_nll_abs_error = direct$sum_nll_abs_error,
    direct_max_nll_abs_error = direct$max_nll_abs_error,
    tmb_laplace_nll = obj_laplace$fn(theta),
    tmb_gk_nll = obj_gk$fn(theta),
    glmer1_nll = gl1b,
    glmer25_nll = gl25b,
    glmer1_repeat_delta = gl1b - gl1a,
    glmer25_repeat_delta = gl25b - gl25a,
    stringsAsFactors = FALSE
  )
}

objective_grid <- do.call(rbind, lapply(
  split(point_rows, seq_len(nrow(point_rows))), evaluate_point
))
row.names(objective_grid) <- NULL

reference <- objective_grid[objective_grid$point == "truth", ][1L, ]
for (method in c("direct_nll", "tmb_laplace_nll", "tmb_gk_nll", "glmer1_nll", "glmer25_nll")) {
  objective_grid[[paste0(method, "_normalized")]] <-
    objective_grid[[method]] - reference[[method]]
}
objective_grid$tmb_gk_minus_direct_normalized <-
  objective_grid$tmb_gk_nll_normalized - objective_grid$direct_nll_normalized
objective_grid$glmer25_minus_direct_normalized <-
  objective_grid$glmer25_nll_normalized - objective_grid$direct_nll_normalized
objective_grid$tmb_laplace_minus_glmer1_normalized <-
  objective_grid$tmb_laplace_nll_normalized - objective_grid$glmer1_nll_normalized
objective_grid$tmb_gk_minus_direct_raw <-
  objective_grid$tmb_gk_nll - objective_grid$direct_nll
objective_grid$glmer25_minus_direct_raw <-
  objective_grid$glmer25_nll - objective_grid$direct_nll
objective_grid$direct_normalized_nll_error_estimate <-
  objective_grid$direct_sum_nll_abs_error + reference$direct_sum_nll_abs_error

metadata <- data.frame(
  key = c(
    "generated_at_utc", "R_version", "TMB_version", "lme4_version",
    "seed", "M", "n_each", "sd_true", "beta0_true", "beta1_true",
    "u_centered", "TMB_framework", "TMB_GK_method", "TMB_GK_adaptive",
    "TMB_GK_tolerance_control", "gk_outer_names", "gk_random_length",
    "cpp_md5", "runner_md5"
  ),
  value = c(
    format(Sys.time(), tz = "UTC", usetz = TRUE), R.version.string,
    as.character(utils::packageVersion("TMB")),
    as.character(utils::packageVersion("lme4")), seed, M, n_each, sd_true,
    beta_true[[1L]], beta_true[[2L]], TRUE, "TMBad",
    "adaptive marginal Gauss-Kronrod", TRUE,
    "TMB 1.9.21 exposes adaptive/debug only; internal defaults retained",
    paste(names(obj_gk$par), collapse = ";"), length(obj_gk$env$random),
    unname(tools::md5sum(cpp_source)), unname(tools::md5sum(script))
  ),
  stringsAsFactors = FALSE
)

setwd(old)
write.table(dat, file.path(out_dir, "fixture.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
write.table(fits, file.path(out_dir, "fit-results.tsv"), sep = "\t", row.names = FALSE, quote = FALSE, na = "NA")
write.table(best, file.path(out_dir, "best-fits.tsv"), sep = "\t", row.names = FALSE, quote = FALSE, na = "NA")
write.table(objective_grid, file.path(out_dir, "objective-grid.tsv"), sep = "\t", row.names = FALSE, quote = FALSE, na = "NA")
write.table(metadata, file.path(out_dir, "manifest.tsv"), sep = "\t", row.names = FALSE, quote = TRUE)

cat("\nBEST FITS\n")
print(best, row.names = FALSE)
cat("\nCOMMON-VECTOR OBJECTIVES\n")
print(objective_grid, row.names = FALSE)
cat("\nTASK B PROBE DONE\n")
