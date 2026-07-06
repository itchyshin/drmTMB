# Closes Noether's note: does non-count structured one-slope recover under a
# NON-identity relatedness matrix (AR(1)) for gamma x relmat and beta x animal?
suppressMessages(devtools::load_all(".", quiet = TRUE))
suppressMessages(library(parallel))

ar1 <- function(n, rho = 0.5) outer(seq_len(n), seq_len(n), function(i, j) rho^abs(i - j))

extract <- function(fit, prov) {
  if (inherits(fit, "error")) return(list(conv = NA_integer_, pdHess = NA_integer_, sd_int = NA_real_, sd_slp = NA_real_, err = conditionMessage(fit)))
  conv <- tryCatch(as.integer(fit$opt$convergence), error = function(e) NA_integer_)
  pdh  <- tryCatch(as.integer(isTRUE(fit$sdr$pdHess)), error = function(e) NA_integer_)
  sdmu <- tryCatch(fit$sdpars$mu, error = function(e) NULL)
  gi <- paste0(prov, "(1 | id)"); gs <- paste0(prov, "(0 + x | id)")
  si <- if (!is.null(sdmu) && gi %in% names(sdmu)) unname(sdmu[[gi]]) else NA_real_
  ss <- if (!is.null(sdmu) && gs %in% names(sdmu)) unname(sdmu[[gs]]) else NA_real_
  list(conv = conv, pdHess = pdh, sd_int = si, sd_slp = ss, err = "")
}

run_gamma_R <- function(nlev, seed) {
  set.seed(seed * 2003L + nlev)
  b0 <- 0.4; b1 <- 0.25; sdi <- 0.5; sds <- 0.35
  lv <- paste0("g", seq_len(nlev)); id <- factor(rep(lv, each = 25L), levels = lv)
  x <- stats::rnorm(length(id))
  R <- ar1(nlev, 0.5); dimnames(R) <- list(lv, lv); L <- t(chol(R))
  ui <- as.vector(L %*% stats::rnorm(nlev, sd = sdi)); us <- as.vector(L %*% stats::rnorm(nlev, sd = sds))
  names(ui) <- lv; names(us) <- lv
  mu <- exp(b0 + b1 * x + ui[as.character(id)] + us[as.character(id)] * x)
  dat <- data.frame(y = stats::rgamma(length(id), shape = 25, scale = mu / 25), x = x, id = id)
  fit <- tryCatch(drmTMB(bf(y ~ x + relmat(1 + x | id, K = R), sigma ~ 1),
                         family = stats::Gamma(link = "log"), data = dat), error = function(e) e)
  c(list(family = "gamma_relmat_AR1", nlev = nlev, seed = seed, true_int = sdi, true_slp = sds), extract(fit, "relmat"))
}

run_beta_R <- function(nlev, seed) {
  set.seed(seed * 2011L + nlev)
  b0 <- -0.2; b1 <- 0.4; sdi <- 0.4; sds <- 0.30; phi <- 8
  lv <- paste0("b", seq_len(nlev)); id <- factor(rep(lv, each = 25L), levels = lv)
  x <- stats::rnorm(length(id))
  R <- ar1(nlev, 0.5); dimnames(R) <- list(lv, lv); L <- t(chol(R))
  ui <- as.vector(L %*% stats::rnorm(nlev, sd = sdi)); us <- as.vector(L %*% stats::rnorm(nlev, sd = sds))
  names(ui) <- lv; names(us) <- lv
  eta <- b0 + b1 * x + ui[as.character(id)] + us[as.character(id)] * x
  mu <- stats::plogis(eta); y <- stats::rbeta(length(id), shape1 = mu * phi, shape2 = (1 - mu) * phi)
  y <- pmin(pmax(y, 1e-4), 1 - 1e-4)
  dat <- data.frame(y = y, x = x, id = id)
  fit <- tryCatch(drmTMB(bf(y ~ x + animal(1 + x | id, A = R), sigma ~ 1),
                         family = beta(), data = dat), error = function(e) e)
  c(list(family = "beta_animal_AR1", nlev = nlev, seed = seed, true_int = sdi, true_slp = sds), extract(fit, "animal"))
}

SEEDS <- 1:20; NLEV <- 30L
runs <- c(
  parallel::mclapply(SEEDS, function(s) tryCatch(run_gamma_R(NLEV, s), error = function(e) NULL), mc.cores = 8L),
  parallel::mclapply(SEEDS, function(s) tryCatch(run_beta_R(NLEV, s), error = function(e) NULL), mc.cores = 8L)
)
runs <- Filter(Negate(is.null), runs)
# surface any first error
errs <- unique(Filter(nzchar, vapply(runs, function(r) as.character(r$err), character(1))))
if (length(errs)) cat("ERRORS:\n", paste(errs, collapse = "\n"), "\n\n")
dat <- do.call(rbind, lapply(runs, function(r) as.data.frame(r[setdiff(names(r), "err")], stringsAsFactors = FALSE)))
summ <- do.call(rbind, lapply(split(dat, dat$family), function(d) {
  ok <- d[!is.na(d$conv) & d$conv == 0L, , drop = FALSE]
  data.frame(family = d$family[1], nlev = NLEV, n = nrow(d),
             conv_rate = round(mean(d$conv == 0L, na.rm = TRUE), 3),
             pdHess_rate = round(mean(d$pdHess == 1L, na.rm = TRUE), 3),
             mean_sd_int = round(mean(ok$sd_int, na.rm = TRUE), 3),
             rmse_sd_int = round(sqrt(mean((ok$sd_int - ok$true_int)^2, na.rm = TRUE)), 3),
             mean_sd_slp = round(mean(ok$sd_slp, na.rm = TRUE), 3),
             rmse_sd_slp = round(sqrt(mean((ok$sd_slp - ok$true_slp)^2, na.rm = TRUE)), 3))
}))
print(summ, row.names = FALSE)
outdir <- "docs/dev-log/simulation-artifacts/2026-07-06-m5-row87-recovery"
utils::write.table(summ, file.path(outdir, "recovery-summary-noniden.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nNON-IDENTITY CHECK DONE\n")
