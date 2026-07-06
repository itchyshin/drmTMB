# S3 recovery ladders for the 3 non-count structured mu one-slope cells.
# Usage: Rscript s3_recovery.R <mode>   where mode = "pilot" or "full"
suppressMessages(devtools::load_all(".", quiet = TRUE))
suppressMessages(library(parallel))

mode <- (function() {
  a <- commandArgs(trailingOnly = TRUE)
  if (length(a) >= 1L) a[[1]] else "pilot"
})()

N_PER <- 25L
if (identical(mode, "full")) {
  LEVELS <- c(10L, 20L, 30L)
  SEEDS <- 1:30
  CORES <- max(1L, parallel::detectCores() - 2L)
} else if (identical(mode, "control")) {
  LEVELS <- 30L
  SEEDS <- 1:30
  CORES <- max(1L, parallel::detectCores() - 2L)
} else {
  LEVELS <- c(10L, 20L)
  SEEDS <- 1:6
  CORES <- 6L
}
CONTROL <- identical(mode, "control")

extract <- function(fit, prov) {
  if (inherits(fit, "error")) {
    return(list(conv = NA_integer_, pdHess = NA_integer_, sd_int = NA_real_, sd_slp = NA_real_))
  }
  conv <- tryCatch(as.integer(fit$opt$convergence), error = function(e) NA_integer_)
  pdh  <- tryCatch(as.integer(isTRUE(fit$sdr$pdHess)), error = function(e) NA_integer_)
  sdmu <- tryCatch(fit$sdpars$mu, error = function(e) NULL)
  gi <- paste0(prov, "(1 | id)")
  gs <- paste0(prov, "(0 + x | id)")
  si <- if (!is.null(sdmu) && gi %in% names(sdmu)) unname(sdmu[[gi]]) else NA_real_
  ss <- if (!is.null(sdmu) && gs %in% names(sdmu)) unname(sdmu[[gs]]) else NA_real_
  list(conv = conv, pdHess = pdh, sd_int = si, sd_slp = ss)
}

# --- family generators (return one-row result) ---
run_gamma <- function(nlev, seed, true_slp = 0.35) {
  set.seed(seed * 1009L + nlev + 1L)
  b0 <- 0.4; b1 <- 0.25; sdi <- 0.5
  lv <- paste0("g", seq_len(nlev)); id <- factor(rep(lv, each = N_PER), levels = lv)
  x <- stats::rnorm(length(id))
  ui <- stats::rnorm(nlev, sd = sdi); us <- stats::rnorm(nlev, sd = true_slp)
  names(ui) <- lv; names(us) <- lv
  mu <- exp(b0 + b1 * x + ui[as.character(id)] + us[as.character(id)] * x)
  dat <- data.frame(y = stats::rgamma(length(id), shape = 25, scale = mu / 25), x = x, id = id)
  K <- diag(nlev); dimnames(K) <- list(lv, lv)
  fit <- tryCatch(drmTMB(bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1),
                         family = stats::Gamma(link = "log"), data = dat),
                  error = function(e) e)
  c(list(family = "gamma_relmat", nlev = nlev, seed = seed,
         true_int = sdi, true_slp = true_slp), extract(fit, "relmat"))
}

run_student <- function(nlev, seed, true_slp = 0.35) {
  set.seed(seed * 1013L + nlev + 3L)
  b0 <- 0.2; b1 <- 0.5; sdi <- 0.5
  lv <- paste0("s", seq_len(nlev)); id <- factor(rep(lv, each = N_PER), levels = lv)
  x <- stats::rnorm(length(id))
  theta <- seq(0, 1.9 * pi, length.out = nlev)
  coords <- data.frame(x = cos(theta), y = sin(theta), row.names = lv)
  prec <- drmTMB:::drm_spatial_coords_precision(coords, site = lv, group = "id")
  covm <- solve(as.matrix(prec$precision))
  L <- t(chol(covm))
  ui <- as.vector(L %*% stats::rnorm(nlev, sd = sdi)); names(ui) <- lv
  us <- as.vector(L %*% stats::rnorm(nlev, sd = true_slp)); names(us) <- lv
  mu <- b0 + b1 * x + ui[as.character(id)] + us[as.character(id)] * x
  dat <- data.frame(y = mu + 0.25 * stats::rt(length(id), df = 12), x = x, id = id)
  fit <- tryCatch(drmTMB(bf(y ~ x + spatial(1 + x | id, coords = coords), sigma ~ 1),
                         family = student(), data = dat),
                  error = function(e) e)
  c(list(family = "student_spatial", nlev = nlev, seed = seed,
         true_int = sdi, true_slp = true_slp), extract(fit, "spatial"))
}

run_beta <- function(nlev, seed, true_slp = 0.30) {
  set.seed(seed * 1019L + nlev + 5L)
  b0 <- -0.2; b1 <- 0.4; sdi <- 0.4; phi <- 8
  lv <- paste0("b", seq_len(nlev)); id <- factor(rep(lv, each = N_PER), levels = lv)
  x <- stats::rnorm(length(id))
  ui <- stats::rnorm(nlev, sd = sdi); us <- stats::rnorm(nlev, sd = true_slp)
  names(ui) <- lv; names(us) <- lv
  eta <- b0 + b1 * x + ui[as.character(id)] + us[as.character(id)] * x
  mu <- stats::plogis(eta)
  y <- stats::rbeta(length(id), shape1 = mu * phi, shape2 = (1 - mu) * phi)
  y <- pmin(pmax(y, 1e-4), 1 - 1e-4)
  dat <- data.frame(y = y, x = x, id = id)
  ped <- data.frame(id = lv, dam = NA_character_, sire = NA_character_)
  fit <- tryCatch(drmTMB(bf(y ~ x + animal(1 + x | id, pedigree = ped), sigma ~ 1),
                         family = beta(), data = dat),
                  error = function(e) e)
  c(list(family = "beta_animal", nlev = nlev, seed = seed,
         true_int = sdi, true_slp = true_slp), extract(fit, "animal"))
}

grid <- expand.grid(nlev = LEVELS, seed = SEEDS, KEEP.OUT.ATTRS = FALSE)
runners <- list(gamma = run_gamma, student = run_student, beta = run_beta)

all_rows <- list()
for (fam in names(runners)) {
  fn <- runners[[fam]]
  res <- parallel::mclapply(seq_len(nrow(grid)), function(i)
    tryCatch(if (CONTROL) fn(grid$nlev[i], grid$seed[i], true_slp = 0) else fn(grid$nlev[i], grid$seed[i]), error = function(e)
      list(family = fam, nlev = grid$nlev[i], seed = grid$seed[i],
           true_int = NA, true_slp = NA, conv = NA, pdHess = NA, sd_int = NA, sd_slp = NA)),
    mc.cores = CORES)
  all_rows[[fam]] <- do.call(rbind, lapply(res, function(r) as.data.frame(r, stringsAsFactors = FALSE)))
}
dat <- do.call(rbind, all_rows)

summ <- do.call(rbind, lapply(split(dat, list(dat$family, dat$nlev), drop = TRUE), function(d) {
  ok <- d[!is.na(d$conv) & d$conv == 0L, , drop = FALSE]
  data.frame(
    family = d$family[1], nlev = d$nlev[1], n = nrow(d),
    conv_rate = mean(d$conv == 0L, na.rm = TRUE),
    pdHess_rate = mean(d$pdHess == 1L, na.rm = TRUE),
    mean_sd_int = round(mean(ok$sd_int, na.rm = TRUE), 3),
    rmse_sd_int = round(sqrt(mean((ok$sd_int - ok$true_int)^2, na.rm = TRUE)), 3),
    mean_sd_slp = round(mean(ok$sd_slp, na.rm = TRUE), 3),
    rmse_sd_slp = round(sqrt(mean((ok$sd_slp - ok$true_slp)^2, na.rm = TRUE)), 3)
  )
}))
summ <- summ[order(summ$family, summ$nlev), ]
cat(sprintf("MODE=%s  N_PER=%d  LEVELS=%s  SEEDS=%d  CORES=%d\n\n",
            mode, N_PER, paste(LEVELS, collapse = "/"), length(SEEDS), CORES))
print(summ, row.names = FALSE)

if (identical(mode, "full") || CONTROL) {
  outdir <- "docs/dev-log/simulation-artifacts/2026-07-06-m5-row87-recovery"
  dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  sfx <- if (CONTROL) "-control" else ""
  utils::write.table(dat, file.path(outdir, paste0("recovery-raw", sfx, ".tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
  utils::write.table(summ, file.path(outdir, paste0("recovery-summary", sfx, ".tsv")), sep = "\t", row.names = FALSE, quote = FALSE)
  cat("\nWROTE artifacts to", outdir, "\n")
}
cat("\nRECOVERY DONE\n")
