suppressMessages(devtools::load_all("/Users/z3437171/local-scratch/parity-joint/wt-uncited-reml", quiet = TRUE))
suppressMessages(library(ape))
options(digits = 15)
flat <- function(x) { if (is.list(x)) x <- unlist(x); x }
nm <- function(x) gsub("[.:]", "_", x)

## SEs, from summary()$coefficients when it carries std_error, else sqrt(diag(vcov)).
## Both spellings of the separator are normalised, because engine = "tmb" labels
## coefficients `mu:(Intercept)` in summary()/vcov() and `mu.(Intercept)` in coef().
se_of <- function(fit) {
  s <- try(summary(fit)$coefficients, silent = TRUE)
  if (!inherits(s, "try-error") && !is.null(s) && "std_error" %in% colnames(s)) {
    return(stats::setNames(as.numeric(s[, "std_error"]), nm(rownames(s))))
  }
  v <- try(stats::vcov(fit), silent = TRUE)
  if (inherits(v, "try-error") || is.null(v)) return(NULL)
  v <- as.matrix(v)
  stats::setNames(sqrt(diag(v)), nm(rownames(v)))
}

## ---- SE diagnosis + comparison, cells 1 and 2 ----
set.seed(1)
n <- 60; x <- rnorm(n); z <- rnorm(n)
y <- 0.5 + 0.8 * x + rnorm(n, sd = exp(-0.3 + 0.25 * z))
d1 <- data.frame(y = y, x = x, z = z)
f1 <- bf(y ~ x, sigma ~ z)
set.seed(11)
ng <- 15; nper <- 10; n2 <- ng * nper
gg <- factor(rep(seq_len(ng), each = nper)); u <- rnorm(ng, sd = 0.7); x2 <- rnorm(n2)
y2 <- 0.4 + 0.9 * x2 + u[as.integer(gg)] + rnorm(n2, sd = 0.5)
d2 <- data.frame(y = y2, x = x2, g = gg)
f2 <- bf(y ~ x + (1 | g), sigma ~ 1)

se_block <- function(tag, ft, fj) {
  st <- se_of(ft); sj <- se_of(fj)
  cat("\n##### SE ", tag, " #####\n", sep = "")
  cat("tmb   SE names: ", paste(names(st), collapse = ", "), "\n", sep = "")
  cat("julia SE names: ", paste(names(sj), collapse = ", "), "\n", sep = "")
  k <- intersect(names(st), names(sj)); k <- k[is.finite(st[k]) & is.finite(sj[k])]
  if (!length(k)) { cat("NO COMMON FINITE SE\n"); return(invisible(NULL)) }
  for (i in k) cat(sprintf("  SE %-22s tmb=%.12f julia=%.12f abs=%.6e rel=%.6e\n",
                           i, st[[i]], sj[[i]], abs(st[[i]] - sj[[i]]), abs(st[[i]] - sj[[i]])/abs(st[[i]])))
  cat(sprintf("MAX_ABS_SE_DIFF=%.12e MAX_REL_SE_DIFF=%.12e n_SE=%d\n",
              max(abs(st[k]-sj[k])), max(abs(st[k]-sj[k])/abs(st[k])), length(k)))
  sp <- sj; sp[k[1]] <- sp[k[1]] * 1.10
  m <- max(abs(st[k]-sp[k])/abs(st[k]))
  cat(sprintf("RED CONTROL se_julia[%s]*1.10 -> MAX_REL_SE_DIFF=%.12e : %s at rtol 1e-3\n",
              k[1], m, if (m > 1e-3) "FAILS (as it must)" else "STILL PASSES -- VACUOUS"))
  invisible(NULL)
}
se_block("CELL 1 REML", drmTMB(f1, gaussian(), data = d1, REML = TRUE, engine = "tmb"),
                        drmTMB(f1, gaussian(), data = d1, REML = TRUE, engine = "julia"))
se_block("CELL 2 REML", drmTMB(f2, gaussian(), data = d2, REML = TRUE, engine = "tmb"),
                        drmTMB(f2, gaussian(), data = d2, REML = TRUE, engine = "julia"))

## ---- CELL 3 on the committed block-diagonal q4 fixture (test-reml-bivariate.R S3) ----
set.seed(3L)
n_tip <- 100L; n_each <- 5L; nn <- n_tip * n_each
tree <- ape::rcoal(n_tip); tree$tip.label <- paste0("sp_", seq_len(n_tip))
A <- ape::vcv(tree, corr = TRUE); L <- t(chol(A))
Gl <- chol(matrix(c(.6^2, .4*.6*.5, .4*.6*.5, .5^2), 2, 2))
Gs <- chol(matrix(c(.4^2, .3*.4*.3, .3*.4*.3, .3^2), 2, 2))
Am <- L %*% matrix(rnorm(n_tip*2), n_tip, 2) %*% Gl
As <- L %*% matrix(rnorm(n_tip*2), n_tip, 2) %*% Gs
tip <- rep(seq_len(n_tip), each = n_each)
s1 <- exp(log(.5) + As[tip,1]); s2 <- exp(log(.6) + As[tip,2])
d3 <- data.frame(sp = factor(tree$tip.label[tip], levels = tree$tip.label),
                 y1 = 0.3 + Am[tip,1] + rnorm(nn, 0, s1),
                 y2 = 0.7 + Am[tip,2] + rnorm(nn, 0, s2))
f3 <- bf(mu1 = y1 ~ 1 + phylo(1 | p | sp, tree = tree),
         mu2 = y2 ~ 1 + phylo(1 | p | sp, tree = tree),
         sigma1 = ~ 1 + phylo(1 | ps | sp, tree = tree),
         sigma2 = ~ 1 + phylo(1 | ps | sp, tree = tree),
         rho12 = ~ 1)
cat("\n##### CELL 3 block-diagonal q4, 100 tips x 5 = 500, seed 3 #####\n")
cat("drm_julia_biv_phylo_dimension = ", drmTMB:::drm_julia_biv_phylo_dimension(f3), "\n", sep = "")
t0 <- Sys.time()
t3 <- suppressWarnings(drmTMB(f3, biv_gaussian(), data = d3, REML = TRUE, engine = "tmb",
                              control = drm_control(optimizer_preset = "robust")))
cat(sprintf("tmb  (%.1fs) convergence=%s estimator=%s logLik=%.12f\n",
            as.numeric(difftime(Sys.time(), t0, units="secs")), t3$opt$convergence, t3$estimator,
            as.numeric(logLik(t3))))
t0 <- Sys.time()
j3 <- tryCatch(drmTMB(f3, biv_gaussian(), data = d3, REML = TRUE, engine = "julia"),
               error = function(e) {cat("julia REFUSES/ERRORS: ", conditionMessage(e), "\n"); NULL})
if (!is.null(j3)) {
  cat(sprintf("julia(%.1fs) estimator=%s engine_estim_method=%s effective_REML=%s logLik=%.12f\n",
              as.numeric(difftime(Sys.time(), t0, units="secs")), j3$estimator,
              as.character(j3$bridge$estim_method)[1], isTRUE(j3$effective_REML), as.numeric(logLik(j3))))
  ct <- flat(coef(t3)); cj <- flat(coef(j3)); names(ct) <- nm(names(ct)); names(cj) <- nm(names(cj))
  k <- intersect(names(ct), names(cj))
  for (i in k) cat(sprintf("  coef %-22s tmb=%.12f julia=%.12f d=%.6e\n", i, ct[[i]], cj[[i]], abs(ct[[i]]-cj[[i]])))
  cat(sprintf("MAX_ABS_COEF_DIFF=%.12e names_identical=%s\n", max(abs(ct[k]-cj[k])),
              identical(sort(names(ct)), sort(names(cj)))))
  cat(sprintf("logLik REML tmb=%.12f julia=%.12f ABS_DIFF=%.12e\n",
              as.numeric(logLik(t3)), as.numeric(logLik(j3)), abs(as.numeric(logLik(t3))-as.numeric(logLik(j3)))))
  t3m <- suppressWarnings(drmTMB(f3, biv_gaussian(), data = d3, REML = FALSE, engine = "tmb",
                                 control = drm_control(optimizer_preset = "robust")))
  j3m <- drmTMB(f3, biv_gaussian(), data = d3, REML = FALSE, engine = "julia")
  cat(sprintf("logLik ML   tmb=%.12f julia=%.12f ABS_DIFF=%.12e\n",
              as.numeric(logLik(t3m)), as.numeric(logLik(j3m)), abs(as.numeric(logLik(t3m))-as.numeric(logLik(j3m)))))
  cat(sprintf("ML_REML_GAP tmb=%.12f julia=%.12f ; tmb ML convergence=%s\n",
              as.numeric(logLik(t3m))-as.numeric(logLik(t3)), as.numeric(logLik(j3m))-as.numeric(logLik(j3)),
              t3m$opt$convergence))
  se_block("CELL 3 REML", t3, j3)
}
cat("\nDONE\n")
