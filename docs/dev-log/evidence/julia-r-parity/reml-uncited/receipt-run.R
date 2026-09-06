## SAME-TARGET RECEIPT: the three UNCITED REML capabilities.
## leaf uncited-reml, 2026-09-05.
suppressMessages(devtools::load_all("/Users/z3437171/local-scratch/parity-joint/wt-uncited-reml", quiet = TRUE))
suppressMessages(library(ape))
options(digits = 15)

flat <- function(x) { if (is.list(x)) x <- unlist(x); x }
nm_norm <- function(x) gsub("[.]", "_", x)

ses <- function(fit) {
  v <- try(stats::vcov(fit), silent = TRUE)
  if (inherits(v, "try-error") || is.null(v)) return(NULL)
  s <- sqrt(diag(as.matrix(v)))
  stats::setNames(s, nm_norm(names(s)))
}

compare <- function(tag, ft, fj, ft_ml, fj_ml) {
  ct <- flat(stats::coef(ft)); cj <- flat(stats::coef(fj))
  names(ct) <- nm_norm(names(ct)); names(cj) <- nm_norm(names(cj))
  common <- intersect(names(ct), names(cj))
  cat("\n########## ", tag, " ##########\n", sep = "")
  cat("coef names tmb   : ", paste(sort(names(ct)), collapse = ", "), "\n", sep = "")
  cat("coef names julia : ", paste(sort(names(cj)), collapse = ", "), "\n", sep = "")
  cat("names identical  : ", identical(sort(names(ct)), sort(names(cj))), "  n_common=", length(common), "\n", sep = "")
  dc <- abs(ct[common] - cj[common])
  for (k in common) cat(sprintf("  coef %-22s tmb=%.12f julia=%.12f d=%.6e\n", k, ct[[k]], cj[[k]], abs(ct[[k]] - cj[[k]])))
  cat(sprintf("MAX_ABS_COEF_DIFF = %.12e\n", max(dc)))
  lt <- as.numeric(stats::logLik(ft)); lj <- as.numeric(stats::logLik(fj))
  cat(sprintf("logLik REML tmb=%.12f julia=%.12f  ABS_DIFF=%.12e\n", lt, lj, abs(lt - lj)))
  lmt <- as.numeric(stats::logLik(ft_ml)); lmj <- as.numeric(stats::logLik(fj_ml))
  cat(sprintf("logLik ML   tmb=%.12f julia=%.12f  ABS_DIFF=%.12e\n", lmt, lmj, abs(lmt - lmj)))
  cat(sprintf("ML_REML_GAP tmb=%.12f julia=%.12f\n", lmt - lt, lmj - lj))
  cat(sprintf("nobs tmb=%d julia=%d ; df tmb=%s julia=%s\n", stats::nobs(ft), stats::nobs(fj),
              attr(stats::logLik(ft), "df"), attr(stats::logLik(fj), "df")))
  cat("ESTIMATOR HONESTY: tmb$estimator=", ft$estimator,
      " julia$estimator=", fj$estimator,
      " julia$effective_REML=", isTRUE(fj$effective_REML),
      " engine estim_method=", as.character(fj$bridge$estim_method)[1], "\n", sep = "")
  cat("  ML controls: tmb$estimator=", ft_ml$estimator, " julia$estimator=", fj_ml$estimator,
      " engine estim_method=", as.character(fj_ml$bridge$estim_method)[1], "\n", sep = "")
  st <- ses(ft); sj <- ses(fj)
  if (is.null(st) || is.null(sj)) { cat("SE: unavailable on at least one engine\n") } else {
    kc <- intersect(names(st), names(sj))
    kc <- kc[is.finite(st[kc]) & is.finite(sj[kc])]
    nan_j <- sum(!is.finite(sj))
    cat("SE finite: tmb=", sum(is.finite(st)), "/", length(st),
        " julia=", sum(is.finite(sj)), "/", length(sj), " (non-finite julia: ", nan_j, ")\n", sep = "")
    if (length(kc)) {
      for (k in kc) cat(sprintf("  SE %-22s tmb=%.12f julia=%.12f abs=%.6e rel=%.6e\n",
                                k, st[[k]], sj[[k]], abs(st[[k]] - sj[[k]]), abs(st[[k]] - sj[[k]]) / abs(st[[k]])))
      cat(sprintf("MAX_ABS_SE_DIFF = %.12e ; MAX_REL_SE_DIFF = %.12e ; n_SE=%d\n",
                  max(abs(st[kc] - sj[kc])), max(abs(st[kc] - sj[kc]) / abs(st[kc])), length(kc)))
      ## RED CONTROL on the SE check itself: perturb one Julia SE by 10 %.
      sp <- sj; sp[kc[1]] <- sp[kc[1]] * 1.10
      cat(sprintf("RED CONTROL (se_julia[1] * 1.10): MAX_REL_SE_DIFF = %.12e -> %s at rtol 1e-3\n",
                  max(abs(st[kc] - sp[kc]) / abs(st[kc])),
                  if (max(abs(st[kc] - sp[kc]) / abs(st[kc])) > 1e-3) "FAILS (as it must)" else "STILL PASSES -- CHECK IS VACUOUS"))
    } else cat("SE: no commonly-finite entries\n")
  }
  invisible(NULL)
}

## ---------------- CELL 1 ----------------
set.seed(1)
n <- 60; x <- rnorm(n); z <- rnorm(n)
y <- 0.5 + 0.8 * x + rnorm(n, sd = exp(-0.3 + 0.25 * z))
d1 <- data.frame(y = y, x = x, z = z)
f1 <- bf(y ~ x, sigma ~ z)
compare("CELL 1  REML (Gaussian fixed-effect location-scale)  bf(y ~ x, sigma ~ z), gaussian(), n=60 seed=1",
  drmTMB(f1, family = gaussian(), data = d1, REML = TRUE,  engine = "tmb"),
  drmTMB(f1, family = gaussian(), data = d1, REML = TRUE,  engine = "julia"),
  drmTMB(f1, family = gaussian(), data = d1, REML = FALSE, engine = "tmb"),
  drmTMB(f1, family = gaussian(), data = d1, REML = FALSE, engine = "julia"))

## ---------------- CELL 2 ----------------
set.seed(11)
ng <- 15; nper <- 10; n2 <- ng * nper
gg <- factor(rep(seq_len(ng), each = nper))
u <- rnorm(ng, sd = 0.7); x2 <- rnorm(n2)
y2 <- 0.4 + 0.9 * x2 + u[as.integer(gg)] + rnorm(n2, sd = 0.5)
d2 <- data.frame(y = y2, x = x2, g = gg)
f2 <- bf(y ~ x + (1 | g), sigma ~ 1)
compare("CELL 2  REML with ordinary random effects (Gaussian mean)  bf(y ~ x + (1|g), sigma ~ 1), gaussian(), n=150 15x10 seed=11",
  drmTMB(f2, family = gaussian(), data = d2, REML = TRUE,  engine = "tmb"),
  drmTMB(f2, family = gaussian(), data = d2, REML = TRUE,  engine = "julia"),
  drmTMB(f2, family = gaussian(), data = d2, REML = FALSE, engine = "tmb"),
  drmTMB(f2, family = gaussian(), data = d2, REML = FALSE, engine = "julia"))

## ---------------- CELL 3 ----------------
set.seed(202)
n_tip <- 40L; n_each <- 4L; nn <- n_tip * n_each
tree <- ape::rcoal(n_tip); tree$tip.label <- paste0("sp_", seq_len(n_tip))
A <- ape::vcv(tree, corr = TRUE); L <- t(chol(A))
sds <- c(.5, .5, .4, .4); R <- diag(4); R[1, 3] <- R[3, 1] <- 0.6
Sig <- diag(sds) %*% R %*% diag(sds)
a <- L %*% matrix(rnorm(n_tip * 4), n_tip, 4) %*% chol(Sig)
tip <- rep(seq_len(n_tip), each = n_each)
d3 <- data.frame(
  sp = factor(tree$tip.label[tip], levels = tree$tip.label),
  y1 = .3 + a[tip, 1] + rnorm(nn, 0, exp(log(.5) + a[tip, 3])),
  y2 = .6 + a[tip, 2] + rnorm(nn, 0, exp(log(.6) + a[tip, 4]))
)
f3 <- bf(
  mu1 = y1 ~ 1 + phylo(1 | p | sp, tree = tree),
  mu2 = y2 ~ 1 + phylo(1 | p | sp, tree = tree),
  sigma1 = ~ 1 + phylo(1 | p | sp, tree = tree),
  sigma2 = ~ 1 + phylo(1 | p | sp, tree = tree),
  rho12 = ~ 1
)
t3 <- suppressWarnings(drmTMB(f3, family = biv_gaussian(), data = d3, REML = TRUE, engine = "tmb",
                             control = drm_control(optimizer_preset = "robust")))
cat("\nCELL 3 native tmb convergence code: ", t3$opt$convergence, " message: ", paste(t3$opt$message, collapse=" "), "\n", sep = "")
t3m <- suppressWarnings(drmTMB(f3, family = biv_gaussian(), data = d3, REML = FALSE, engine = "tmb",
                              control = drm_control(optimizer_preset = "robust")))
j3 <- drmTMB(f3, family = biv_gaussian(), data = d3, REML = TRUE, engine = "julia")
j3m <- drmTMB(f3, family = biv_gaussian(), data = d3, REML = FALSE, engine = "julia")
compare("CELL 3  REML bivariate phylogenetic location-scale (q4, all axes)  dense q4 phylo on mu1,mu2,sigma1,sigma2; rho12 ~ 1; 40 tips x 4 = 160, seed=202",
        t3, j3, t3m, j3m)
cat("\nDONE\n")
