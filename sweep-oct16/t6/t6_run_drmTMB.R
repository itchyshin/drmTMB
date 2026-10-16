# Run predict/simulate checks for one drmTMB cell (hard timeout via the caller).
# Usage: Rscript t6_run_drmTMB.R <root> <family> <fe|re>
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) >= 3L)
root <- args[[1L]]
family <- args[[2L]]
re_lab <- args[[3L]]
re <- identical(re_lab, "re")
source(file.path(root, "t6_config.R"))

suppressPackageStartupMessages(library(drmTMB))

cell <- t6_cell(family, re)
datadir <- file.path(root, "data")
resdir <- file.path(root, "results")
dir.create(resdir, recursive = TRUE, showWarnings = FALSE)
log_path <- file.path(resdir, paste0("cells_", cell, ".csv"))

append_row <- function(...) {
  rec <- data.frame(..., stringsAsFactors = FALSE, check.names = FALSE)
  hdr <- !file.exists(log_path)
  utils::write.table(
    rec, log_path, sep = ",", row.names = FALSE, col.names = hdr,
    append = !hdr, qmethod = "double"
  )
  print(rec)
  invisible(rec)
}

safe_msg <- function(e) {
  paste(collapse = " ", gsub("[\r\n]+", " ", conditionMessage(e)))
}

read_dat <- function() {
  d <- utils::read.csv(file.path(datadir, paste0(cell, ".csv")),
                       stringsAsFactors = FALSE)
  d$f <- factor(d$f, levels = c("a", "b", "c"))
  d$g <- factor(d$g)
  d
}

family_obj <- function() {
  switch(family,
    gaussian = stats::gaussian(),
    student = student(),
    lognormal = lognormal(),
    gamma = stats::Gamma(link = "log"),
    poisson = stats::poisson(),
    nbinom2 = nbinom2(),
    binomial = stats::binomial(),
    beta = beta_family(),
    tweedie = tweedie(),
    skew_normal = skew_normal(),
    beta_binomial = beta_binomial(),
    zero_one_beta = zero_one_beta(),
    stop(family)
  )
}

build_formula <- function() {
  mu_rhs <- if (re) "y ~ x + f + (1 | g)" else "y ~ x + f"
  if (family == "beta_binomial") {
    mu_rhs <- if (re) {
      "cbind(y, trials - y) ~ x + f + (1 | g)"
    } else {
      "cbind(y, trials - y) ~ x + f"
    }
  }
  extras <- list()
  dpars <- t6_dpars(family)
  if ("sigma" %in% dpars) extras$sigma <- ~ 1
  if ("nu" %in% dpars) extras$nu <- ~ 1
  if ("zoi" %in% dpars) extras$zoi <- ~ 1
  if ("coi" %in% dpars) extras$coi <- ~ 1
  do.call(bf, c(list(stats::as.formula(mu_rhs)), extras))
}

fitted_moments_cond <- function(fit) {
  mt <- fit$model$model_type
  mu <- as.numeric(predict(fit, dpar = "mu"))
  sigma <- if ("sigma" %in% names(fit$coefficients)) {
    as.numeric(predict(fit, dpar = "sigma"))
  } else {
    NA_real_
  }
  nu <- if ("nu" %in% names(fit$coefficients)) {
    as.numeric(predict(fit, dpar = "nu"))
  } else {
    NA_real_
  }
  if (identical(mt, "gaussian") || identical(mt, "skew_normal")) {
    list(mean = mu, var = sigma^2)
  } else if (identical(mt, "student")) {
    list(mean = mu, var = sigma^2 * nu / (nu - 2))
  } else if (identical(mt, "lognormal")) {
    list(mean = exp(mu + sigma^2 / 2),
         var = exp(2 * mu + sigma^2) * (exp(sigma^2) - 1))
  } else if (identical(mt, "gamma")) {
    list(mean = mu, var = (mu * sigma)^2)
  } else if (identical(mt, "poisson")) {
    list(mean = mu, var = mu)
  } else if (identical(mt, "nbinom2")) {
    list(mean = mu, var = mu + sigma^2 * mu^2)
  } else if (identical(mt, "binomial")) {
    trials <- fit$model$trials
    list(mean = mu * trials, var = trials * mu * (1 - mu))
  } else if (identical(mt, "beta")) {
    phi <- 1 / sigma^2
    list(mean = mu, var = mu * (1 - mu) / (1 + phi))
  } else if (identical(mt, "tweedie")) {
    list(mean = mu, var = sigma^2 * mu^nu)
  } else if (identical(mt, "beta_binomial")) {
    trials <- fit$model$trials
    phi <- 1 / sigma^2
    pvar <- mu * (1 - mu) * (1 + (trials - 1) / (1 + phi))
    list(mean = mu * trials, var = trials * pvar)
  } else if (identical(mt, "zero_one_beta")) {
    zoi <- as.numeric(predict(fit, dpar = "zoi"))
    coi <- as.numeric(predict(fit, dpar = "coi"))
    list(mean = (1 - zoi) * mu + zoi * coi, var = NA_real_)
  } else {
    list(mean = mu, var = NA_real_)
  }
}

mc_pass <- function(obs, truth, mcse) {
  ok <- is.finite(obs) & is.finite(truth) & is.finite(mcse) & mcse > 0
  if (!any(ok)) return(list(pass = FALSE, max_z = NA_real_, n_ok = 0L, n = length(obs)))
  z <- abs(obs[ok] - truth[ok]) / mcse[ok]
  list(pass = max(z) <= T6_PASS_MCSE, max_z = max(z), n_ok = sum(ok), n = length(obs))
}

capture_fit <- function() {
  setTimeLimit(elapsed = T6_FIT_TIMEOUT_S, transient = TRUE)
  on.exit(setTimeLimit(elapsed = Inf, transient = TRUE), add = TRUE)
  dat <- read_dat()
  fam <- family_obj()
  form <- build_formula()
  warns <- character()
  withCallingHandlers(
    {
      fit <- drmTMB(form, family = fam, data = dat)
    },
    warning = function(w) {
      warns <<- c(warns, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(fit = fit, dat = dat, warns = warns)
}

seed <- t6_seed_r(family, re)
nom <- t6_seed_nominal(family, re)
t0 <- proc.time()[["elapsed"]]
got <- tryCatch(capture_fit(), error = function(e) e)
elapsed <- proc.time()[["elapsed"]] - t0

if (inherits(got, "error")) {
  append_row(
    engine = "drmTMB", cell = cell, family = family, re = re,
    check = "fit", status = "error", pass = FALSE,
    detail = safe_msg(got), time_s = elapsed, seed = nom, seed_r = seed
  )
  quit(save = "no", status = 0)
}

fit <- got$fit
dat <- got$dat
append_row(
  engine = "drmTMB", cell = cell, family = family, re = re,
  check = "fit", status = "ok",
  pass = isTRUE(tryCatch(is_converged(fit), error = function(e) FALSE)),
  detail = paste0(
    "converged=", tryCatch(is_converged(fit), error = function(e) NA),
    " status=", tryCatch(convergence_status(fit), error = function(e) NA),
    " warns=", paste(got$warns, collapse = " | ")
  ),
  time_s = elapsed, seed = nom, seed_r = seed
)

# --- predict types: link, response, each dpar ---
for (dpar in t6_dpars(family)) {
  for (typ in c("response", "link")) {
    chk <- paste0("predict_", typ, "_", dpar)
    t1 <- proc.time()[["elapsed"]]
    val <- tryCatch(predict(fit, dpar = dpar, type = typ), error = function(e) e)
    el <- proc.time()[["elapsed"]] - t1
    if (inherits(val, "error")) {
      append_row(engine = "drmTMB", cell = cell, family = family, re = re,
                 check = chk, status = "error", pass = FALSE,
                 detail = safe_msg(val), time_s = el, seed = nom, seed_r = seed)
    } else {
      ok <- is.numeric(val) && length(val) == nrow(dat) && all(is.finite(val))
      append_row(engine = "drmTMB", cell = cell, family = family, re = re,
                 check = chk, status = "ok", pass = ok,
                 detail = sprintf("n=%d finite=%d range=[%g,%g]",
                                  length(val), sum(is.finite(val)),
                                  min(val), max(val)),
                 time_s = el, seed = nom, seed_r = seed)
    }
  }
}

# Save FE/population predictions on a shared newdata grid for Julia compare.
nd <- data.frame(
  x = c(-0.5, 0, 0.5),
  f = factor(c("a", "b", "c"), levels = levels(dat$f)),
  g = factor(rep(levels(dat$g)[1], 3), levels = levels(dat$g)),
  trials = 12L
)
pred_path <- file.path(resdir, paste0("predict_R_", cell, ".csv"))
pred_tab <- list(row = seq_len(nrow(nd)))
for (dpar in t6_dpars(family)) {
  for (typ in c("response", "link")) {
    val <- tryCatch(
      as.numeric(predict(fit, newdata = nd, dpar = dpar, type = typ)),
      error = function(e) rep(NA_real_, nrow(nd))
    )
    pred_tab[[paste(dpar, typ, sep = "_")]] <- val
  }
}
utils::write.csv(as.data.frame(pred_tab), pred_path, row.names = FALSE)

# --- newdata with unseen levels ---
nd_bad <- data.frame(x = 0, f = factor("z", levels = c("a", "b", "c", "z")),
                     g = dat$g[1], trials = 12L)
t1 <- proc.time()[["elapsed"]]
unseen <- tryCatch(
  predict(fit, newdata = nd_bad, dpar = "mu"),
  error = function(e) e
)
el <- proc.time()[["elapsed"]] - t1
if (inherits(unseen, "error")) {
  msg <- safe_msg(unseen)
  named <- grepl("unknown factor level|new level|not used|unseen", msg, ignore.case = TRUE)
  append_row(engine = "drmTMB", cell = cell, family = family, re = re,
             check = "newdata_unseen_level", status = "error_ok",
             pass = named, detail = msg, time_s = el, seed = nom, seed_r = seed)
} else {
  append_row(engine = "drmTMB", cell = cell, family = family, re = re,
             check = "newdata_unseen_level", status = "silent",
             pass = FALSE,
             detail = "predict() returned a number for an unseen factor level",
             time_s = el, seed = nom, seed_r = seed)
}

# --- character vs factor predictors ---
t1 <- proc.time()[["elapsed"]]
nd_fac <- data.frame(x = c(-0.5, 0.5), f = factor(c("a", "c"), levels = levels(dat$f)),
                     g = factor(rep(levels(dat$g)[1], 2), levels = levels(dat$g)),
                     trials = 12L)
nd_chr <- data.frame(x = nd_fac$x, f = as.character(nd_fac$f),
                     g = as.character(nd_fac$g), trials = 12L,
                     stringsAsFactors = FALSE)
p_fac <- tryCatch(as.numeric(predict(fit, newdata = nd_fac, dpar = "mu")),
                  error = function(e) e)
p_chr <- tryCatch(as.numeric(predict(fit, newdata = nd_chr, dpar = "mu")),
                  error = function(e) e)
el <- proc.time()[["elapsed"]] - t1
if (inherits(p_fac, "error") || inherits(p_chr, "error")) {
  detail <- paste(
    "fac:", if (inherits(p_fac, "error")) safe_msg(p_fac) else "ok",
    "chr:", if (inherits(p_chr, "error")) safe_msg(p_chr) else "ok"
  )
  append_row(engine = "drmTMB", cell = cell, family = family, re = re,
             check = "char_vs_factor", status = "error", pass = FALSE,
             detail = detail, time_s = el, seed = nom, seed_r = seed)
} else {
  mx <- max(abs(p_fac - p_chr))
  append_row(engine = "drmTMB", cell = cell, family = family, re = re,
             check = "char_vs_factor", status = "ok",
             pass = is.finite(mx) && mx <= 1e-10,
             detail = sprintf("max_abs_diff=%g", mx),
             time_s = el, seed = nom, seed_r = seed)
}

# --- se.fit where offered ---
t1 <- proc.time()[["elapsed"]]
se_pred <- tryCatch(predict(fit, newdata = nd, dpar = "mu", se.fit = TRUE),
                    error = function(e) e)
el <- proc.time()[["elapsed"]] - t1
if (inherits(se_pred, "error")) {
  append_row(engine = "drmTMB", cell = cell, family = family, re = re,
             check = "se.fit_predict", status = "error", pass = TRUE,
             detail = paste("predict(se.fit=TRUE) errored:", safe_msg(se_pred)),
             time_s = el, seed = nom, seed_r = seed)
} else if (is.list(se_pred) && !is.null(se_pred$se.fit)) {
  append_row(engine = "drmTMB", cell = cell, family = family, re = re,
             check = "se.fit_predict", status = "ok", pass = TRUE,
             detail = "predict() returned se.fit",
             time_s = el, seed = nom, seed_r = seed)
} else {
  # Silently ignored (known #1536). Record as fail of the offered-API bar.
  append_row(engine = "drmTMB", cell = cell, family = family, re = re,
             check = "se.fit_predict", status = "ignored", pass = FALSE,
             detail = "predict(se.fit=TRUE) ignored se.fit and returned a numeric vector",
             time_s = el, seed = nom, seed_r = seed)
}

t1 <- proc.time()[["elapsed"]]
pp <- tryCatch(
  predict_parameters(fit, newdata = nd, dpar = "mu", conf.int = TRUE),
  error = function(e) e
)
el <- proc.time()[["elapsed"]] - t1
if (inherits(pp, "error")) {
  append_row(engine = "drmTMB", cell = cell, family = family, re = re,
             check = "se.fit_predict_parameters", status = "error", pass = FALSE,
             detail = safe_msg(pp), time_s = el, seed = nom, seed_r = seed)
} else {
  has_se <- "std.error" %in% names(pp) && all(is.finite(pp$std.error))
  append_row(engine = "drmTMB", cell = cell, family = family, re = re,
             check = "se.fit_predict_parameters", status = "ok", pass = isTRUE(has_se),
             detail = sprintf("cols=%s", paste(names(pp), collapse = "/")),
             time_s = el, seed = nom, seed_r = seed)
}

# --- simulate nsim=1000 vs fitted moments (conditional; re.form = NULL) ---
t1 <- proc.time()[["elapsed"]]
sims <- tryCatch(
  simulate(fit, nsim = T6_NSIM, seed = seed, re.form = NULL),
  error = function(e) e
)
el <- proc.time()[["elapsed"]] - t1
if (inherits(sims, "error")) {
  append_row(engine = "drmTMB", cell = cell, family = family, re = re,
             check = "simulate_conditional", status = "error", pass = FALSE,
             detail = safe_msg(sims), time_s = el, seed = nom, seed_r = seed)
} else {
  sim_mat <- as.matrix(sims)
  storage.mode(sim_mat) <- "double"
  sim_mean <- rowMeans(sim_mat)
  sim_var <- apply(sim_mat, 1L, stats::var)
  mom <- fitted_moments_cond(fit)
  mcse_mean <- sqrt(pmax(mom$var, 0) / T6_NSIM)
  # Fallback empirical MC SE when family var is missing.
  if (any(!is.finite(mcse_mean))) {
    mcse_mean <- apply(sim_mat, 1L, stats::sd) / sqrt(T6_NSIM)
  }
  mean_chk <- mc_pass(sim_mean, mom$mean, mcse_mean)
  append_row(engine = "drmTMB", cell = cell, family = family, re = re,
             check = "simulate_mean_vs_fitted",
             status = if (mean_chk$pass) "ok" else "fail",
             pass = mean_chk$pass,
             detail = sprintf("max_z=%.3f n_ok=%d/%d", mean_chk$max_z,
                              mean_chk$n_ok, mean_chk$n),
             time_s = el, seed = nom, seed_r = seed)
  if (all(is.finite(mom$var))) {
    mcse_var <- mom$var * sqrt(2 / (T6_NSIM - 1))
    var_chk <- mc_pass(sim_var, mom$var, mcse_var)
    append_row(engine = "drmTMB", cell = cell, family = family, re = re,
               check = "simulate_var_vs_fitted",
               status = if (var_chk$pass) "ok" else "fail",
               pass = var_chk$pass,
               detail = sprintf("max_z=%.3f n_ok=%d/%d", var_chk$max_z,
                                var_chk$n_ok, var_chk$n),
               time_s = 0, seed = nom, seed_r = seed)
  } else {
    append_row(engine = "drmTMB", cell = cell, family = family, re = re,
               check = "simulate_var_vs_fitted", status = "skip",
               pass = NA, detail = "no closed-form fitted variance",
               time_s = 0, seed = nom, seed_r = seed)
  }
}

# --- simulate(newdata =) known gap #1536 ---
nd2 <- nd[1:2, , drop = FALSE]
t1 <- proc.time()[["elapsed"]]
sim_nd <- tryCatch(
  simulate(fit, nsim = 1, seed = 1, newdata = nd2),
  error = function(e) e
)
el <- proc.time()[["elapsed"]] - t1
if (inherits(sim_nd, "error")) {
  append_row(engine = "drmTMB", cell = cell, family = family, re = re,
             check = "simulate_newdata", status = "error", pass = TRUE,
             detail = safe_msg(sim_nd), time_s = el, seed = nom, seed_r = seed)
} else {
  n_row <- NROW(sim_nd)
  append_row(engine = "drmTMB", cell = cell, family = family, re = re,
             check = "simulate_newdata", status = "ignored",
             pass = n_row == nrow(nd2),
             detail = sprintf("nrow(sim)=%d nrow(newdata)=%d nrow(train)=%d",
                              n_row, nrow(nd2), nrow(dat)),
             time_s = el, seed = nom, seed_r = seed)
}

# Save a tiny RDS of the fit metadata (not the whole TMB object).
meta <- list(
  cell = cell, family = family, re = re,
  seed = nom, seed_r = seed,
  n = nrow(dat),
  dpars = t6_dpars(family),
  coef = tryCatch(fit$opt$par, error = function(e) NULL)
)
saveRDS(meta, file.path(resdir, paste0("meta_R_", cell, ".rds")))
