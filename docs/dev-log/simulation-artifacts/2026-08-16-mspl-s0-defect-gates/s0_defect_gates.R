# S0 defect gates for the MSPL boundary programme. See PREREGISTRATION.md (committed first).
#   Rscript --no-init-file s0_defect_gates.R --exp=A --nrep=200 --cores=40 --outdir=OUT
#   Rscript --no-init-file s0_defect_gates.R --exp=B --nrep=300 --cores=40 --outdir=OUT

args <- commandArgs(trailingOnly = TRUE)
arg_of <- function(k, d = NA_character_) {
  h <- grep(sprintf("^--%s=", k), args, value = TRUE)
  if (!length(h)) return(d)
  sub(sprintf("^--%s=", k), "", h[[1L]])
}
EXP     <- arg_of("exp")
n_rep   <- as.integer(arg_of("nrep", "200"))
n_cores <- as.integer(arg_of("cores", "1"))
out_dir <- arg_of("outdir", "results")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
library(drmTMB)

## ---- the SHIPPED forms, transcribed ---------------------------------------
## D = negative Huber (src/drmTMB.cpp:77-85): D(t) = -t^2/2 (|t|<=1), -|t|+1/2 (|t|>1)
neg_huber <- function(t) ifelse(abs(t) <= 1, -t^2 / 2, -abs(t) + 0.5)
## c_n = 2*sqrt(p/n_eff) (R/mspl.R:112-128); for the Gaussian port p = # fixed-effect
## columns of the mu design (intercept + x = 2), n_eff = n rows.
c_n_of <- function(p, n_eff) 2 * sqrt(p / n_eff)

TARGET <- "sd:mu:(1 | g)"

## Locate the log-SD coordinate in the TMB parameter vector by name.
log_sd_index <- function(obj) {
  nm <- names(obj$par)
  i <- which(nm == "log_sd_mu")
  if (length(i) != 1L) stop("log_sd_mu index not unique: ", paste(i, collapse = ","))
  i
}

fit_pen_sd <- function(dat) {
  fit <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = dat)
  obj <- fit$obj
  if (is.null(obj)) stop("fit$obj is NULL — TMB object not retained")
  i <- log_sd_index(obj)
  cn <- c_n_of(p = 2, n_eff = nrow(dat))
  fn_pen <- function(par) as.numeric(obj$fn(par)) - cn * neg_huber(par[i])
  gr_pen <- function(par) {
    g <- as.numeric(obj$gr(par))
    t <- par[i]
    dD <- if (abs(t) <= 1) -t else -sign(t)   # D'(t)
    g[i] <- g[i] - cn * dD
    g
  }
  o <- nlminb(obj$env$last.par.best[-obj$env$random], fn_pen, gr_pen)
  ml_sd  <- exp(fit$opt$par[[i]])
  pen_sd <- exp(o$par[[i]])
  c(ml = ml_sd, pen = pen_sd, conv = o$convergence)
}

if (identical(EXP, "A")) {
  one <- function(r) {
    seed <- 20260816L + r
    set.seed(seed)
    g <- factor(rep(1:10, each = 10)); x <- rnorm(100)
    u <- rnorm(10, 0, 0.5)
    y <- 1 + 0.5 * x + u[as.integer(g)] + rnorm(100, 0, 0.7)
    d1 <- data.frame(y = y, x = x, g = g)
    d2 <- transform(d1, y = 100 * y)
    a <- tryCatch(fit_pen_sd(d1), error = function(e) c(ml = NA, pen = NA, conv = 99))
    b <- tryCatch(fit_pen_sd(d2), error = function(e) c(ml = NA, pen = NA, conv = 99))
    data.frame(seed = seed,
               ml_1 = a[["ml"]],  ml_100_backscaled  = b[["ml"]]  / 100,
               pen_1 = a[["pen"]], pen_100_backscaled = b[["pen"]] / 100,
               ml_disc  = abs(a[["ml"]]  - b[["ml"]]  / 100),
               pen_disc = abs(a[["pen"]] - b[["pen"]] / 100),
               conv = a[["conv"]] + b[["conv"]])
  }
  res <- if (n_cores > 1) parallel::mclapply(1:n_rep, one, mc.cores = n_cores) else lapply(1:n_rep, one)
  out <- do.call(rbind, res)
  write.csv(out, file.path(out_dir, "expA_equivariance.csv"), row.names = FALSE)
  ok <- is.finite(out$pen_disc)
  cat(sprintf("EXP A n=%d ok=%d | ML control: mean disc %.2e max %.2e | PENALIZED: mean disc %.4f max %.4f\n",
              nrow(out), sum(ok),
              mean(out$ml_disc, na.rm = TRUE), max(out$ml_disc, na.rm = TRUE),
              mean(out$pen_disc, na.rm = TRUE), max(out$pen_disc, na.rm = TRUE)))
}

if (identical(EXP, "B")) {
  CELLS <- c(0.25, 0.5, 1, 2, 4)
  one <- function(k) {
    ci <- (k - 1L) %/% n_rep + 1L; r <- (k - 1L) %% n_rep + 1L
    sd_u <- CELLS[ci]
    seed <- 20260816L + 1000L * ci + r
    set.seed(seed)
    g <- factor(rep(1:10, each = 20)); x <- rnorm(200)
    u <- rnorm(10, 0, sd_u)
    eta <- 0.5 * x + u[as.integer(g)]
    y <- rbinom(200, 1, plogis(eta))
    d <- data.frame(y = y, x = x, g = g)
    sd_of <- function(est) tryCatch({
      f <- drmTMB(bf(y ~ x + (1 | g)), family = binomial(), data = d, estimator = est)
      p <- summary(f)$parameters
      v <- p$estimate[p$parm == TARGET]
      if (length(v) == 1) v else NA_real_
    }, error = function(e) NA_real_)
    data.frame(cell = ci, sd_true = sd_u, seed = seed,
               sd_ml = sd_of("ml"), sd_mspl = sd_of("mspl"))
  }
  K <- length(CELLS) * n_rep
  res <- if (n_cores > 1) parallel::mclapply(1:K, one, mc.cores = n_cores) else lapply(1:K, one)
  out <- do.call(rbind, res)
  write.csv(out, file.path(out_dir, "expB_anchor_ladder.csv"), row.names = FALSE)
  agg <- aggregate(cbind(sd_ml, sd_mspl) ~ sd_true, out, function(z) mean(z, na.rm = TRUE))
  agg$bias_ml   <- 100 * (agg$sd_ml   / agg$sd_true - 1)
  agg$bias_mspl <- 100 * (agg$sd_mspl / agg$sd_true - 1)
  print(agg, digits = 4)
  cat("EXP B done, rows", nrow(out), "\n")
}
