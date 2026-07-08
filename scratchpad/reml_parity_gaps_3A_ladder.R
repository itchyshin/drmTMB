# Validation for two REML parity gaps (ML supports both; REML gates reject):
#   (3) biv mu-sigma q2 block: (1|p|id) spanning mu1 and sigma1
#   (A) q>2 labelled block: mu-side q3 (1 + x1 + x2 | id)
# Question: does REML recover (and debias vs ML) with replication?
suppressPackageStartupMessages({devtools::load_all(".", quiet = TRUE); library(parallel)})
assignInNamespace("drm_validate_reml_spec", function(spec) invisible(TRUE), ns = "drmTMB")
assignInNamespace("drm_validate_reml_spec_biv", function(spec) invisible(TRUE), ns = "drmTMB")
Sys.setenv(OPENBLAS_NUM_THREADS = "1")

## ---- (3) biv mu-sigma q2: (a_mu1, a_sig1) correlated ------------------------
S3 <- chol(matrix(c(.6^2, .3 * .6 * .4, .3 * .6 * .4, .4^2), 2, 2))
truth3 <- c(sd_mu1 = .6, sd_sig1 = .4, cor = .3)
sim3 <- function(n_each, seed) {
  n_id <- 60L; set.seed(seed * 31337L + n_each)
  a <- matrix(rnorm(n_id * 2), n_id, 2) %*% S3
  id <- rep(seq_len(n_id), each = n_each); n <- n_id * n_each; x <- rnorm(n)
  d <- data.frame(id = factor(id), x = x,
    y1 = .3 + .5 * x + a[id, 1] + rnorm(n, 0, exp(log(.5) + a[id, 2])),
    y2 = .6 + .2 * x + rnorm(n, 0, .6))
  form <- bf(mu1 = y1 ~ x + (1 | p | id), mu2 = y2 ~ x,
             sigma1 = ~ 1 + (1 | p | id), sigma2 = ~ 1, rho12 = ~ 1)
  o <- list()
  for (est in c("ML", "REML")) {
    f <- tryCatch(suppressWarnings(drmTMB(form, biv_gaussian(), d, REML = (est == "REML"),
           control = drm_control(optimizer_preset = "robust"))), error = function(e) NULL)
    if (is.null(f)) return(NULL)
    pr <- summary(f)$parameters; g <- function(rx) unname(pr$estimate[grep(rx, pr$parm)][1])
    o[[est]] <- c(sd_mu1 = g("^sd:mu"), sd_sig1 = g("^sd:sigma"), cor = g("^cor.*id"))
  }
  data.frame(shape = "3_biv_musigma", n_each = n_each, seed = seed, par = names(truth3),
             truth = truth3, ml = o$ML[names(truth3)], reml = o$REML[names(truth3)], row.names = NULL)
}

## ---- (A) mu-side q3 block (1 + x1 + x2 | id) --------------------------------
R3 <- matrix(c(1, .3, .2, .3, 1, .25, .2, .25, 1), 3, 3)
SA <- chol(diag(c(.6, .4, .3)) %*% R3 %*% diag(c(.6, .4, .3)))
truthA <- c(sd_int = .6, sd_x1 = .4, sd_x2 = .3)
simA <- function(n_each, seed) {
  n_id <- 60L; set.seed(seed * 71993L + n_each)
  a <- matrix(rnorm(n_id * 3), n_id, 3) %*% SA
  id <- rep(seq_len(n_id), each = n_each); n <- n_id * n_each
  x1 <- rnorm(n); x2 <- rnorm(n)
  y <- .3 + .5 * x1 - .2 * x2 + a[id, 1] + a[id, 2] * x1 + a[id, 3] * x2 + rnorm(n, 0, .5)
  d <- data.frame(id = factor(id), x1 = x1, x2 = x2, y = y)
  form <- bf(y ~ x1 + x2 + (1 + x1 + x2 | id), sigma ~ 1)
  o <- list()
  for (est in c("ML", "REML")) {
    f <- tryCatch(suppressWarnings(drmTMB(form, gaussian(), d, REML = (est == "REML"),
           control = drm_control(optimizer_preset = "robust"))), error = function(e) NULL)
    if (is.null(f)) return(NULL)
    pr <- summary(f)$parameters; sds <- pr$estimate[grep("^sd:mu", pr$parm)]
    if (length(sds) < 3L) return(NULL)
    o[[est]] <- sds[1:3]
  }
  data.frame(shape = "A_q3block", n_each = n_each, seed = seed, par = names(truthA),
             truth = truthA, ml = o$ML, reml = o$REML, row.names = NULL)
}

g <- expand.grid(seed = 1:10, n_each = c(5L, 10L))
r3 <- do.call(rbind, mcmapply(sim3, g$n_each, g$seed, SIMPLIFY = FALSE, mc.cores = 8))
rA <- do.call(rbind, mcmapply(simA, g$n_each, g$seed, SIMPLIFY = FALSE, mc.cores = 8))
show <- function(r, lbl) {
  cat(sprintf("\n=== %s (n_id=60, 10 seeds) ===\n", lbl))
  for (p in unique(r$par)) for (k in sort(unique(r$n_each))) {
    s <- r[r$par == p & r$n_each == k, ]; tr <- s$truth[1]
    bml <- mean(s$ml, na.rm = TRUE) - tr; brl <- mean(s$reml, na.rm = TRUE) - tr
    cat(sprintf("  %-8s n_each=%-2d truth %+.2f : biasML %+.3f biasREML %+.3f  %s\n",
        p, k, tr, bml, brl, if (abs(brl) <= abs(bml) + 1e-9) "REML>=ML" else "ML better"))
  }
}
show(r3, "(3) biv mu-sigma q2 block"); show(rA, "(A) mu-side q3 labelled block")
cat("\nPARITY 3+A LADDER DONE\n")
