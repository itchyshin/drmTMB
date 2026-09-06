suppressMessages(devtools::load_all("/Users/z3437171/local-scratch/parity-joint/wt-uncited-reml", quiet = TRUE))
suppressMessages(library(ape)); options(digits = 15)
nm <- function(x) gsub("[.:]", "_", x)
flat <- function(x) { if (is.list(x)) x <- unlist(x); x }
se_of <- function(fit) {
  s <- try(summary(fit)$coefficients, silent = TRUE)
  if (!inherits(s, "try-error") && !is.null(s) && "std_error" %in% colnames(s))
    return(stats::setNames(as.numeric(s[, "std_error"]), nm(rownames(s))))
  NULL
}
set.seed(3L)
n_tip <- 100L; n_each <- 5L; nn <- n_tip * n_each
tree <- ape::rcoal(n_tip); tree$tip.label <- paste0("sp_", seq_len(n_tip))
A <- ape::vcv(tree, corr = TRUE); L <- t(chol(A))
Gl <- chol(matrix(c(.6^2,.4*.6*.5,.4*.6*.5,.5^2),2,2)); Gs <- chol(matrix(c(.4^2,.3*.4*.3,.3*.4*.3,.3^2),2,2))
Am <- L %*% matrix(rnorm(n_tip*2), n_tip, 2) %*% Gl
As <- L %*% matrix(rnorm(n_tip*2), n_tip, 2) %*% Gs
tip <- rep(seq_len(n_tip), each = n_each)
d3 <- data.frame(sp = factor(tree$tip.label[tip], levels = tree$tip.label),
                 y1 = 0.3 + Am[tip,1] + rnorm(nn, 0, exp(log(.5)+As[tip,1])),
                 y2 = 0.7 + Am[tip,2] + rnorm(nn, 0, exp(log(.6)+As[tip,2])))
dense <- bf(mu1 = y1 ~ 1 + phylo(1 | p | sp, tree = tree),
            mu2 = y2 ~ 1 + phylo(1 | p | sp, tree = tree),
            sigma1 = ~ 1 + phylo(1 | p | sp, tree = tree),
            sigma2 = ~ 1 + phylo(1 | p | sp, tree = tree), rho12 = ~ 1)
t3  <- suppressWarnings(drmTMB(dense, biv_gaussian(), data = d3, REML = TRUE,  engine = "tmb",
                               control = drm_control(optimizer_preset = "robust")))
j3  <- drmTMB(dense, biv_gaussian(), data = d3, REML = TRUE,  engine = "julia")
t3m <- suppressWarnings(drmTMB(dense, biv_gaussian(), data = d3, REML = FALSE, engine = "tmb",
                               control = drm_control(optimizer_preset = "robust")))
j3m <- drmTMB(dense, biv_gaussian(), data = d3, REML = FALSE, engine = "julia")
cat("\n## CELL 3 DENSE q4 all axes, 100 tips x 5 = 500, seed 3\n")
cat(sprintf("tmb  REML convergence=%s estimator=%s df=%s\n", t3$opt$convergence, t3$estimator, attr(logLik(t3),"df")))
cat(sprintf("julia REML estimator=%s engine_estim_method=%s effective_REML=%s df=%s\n",
            j3$estimator, as.character(j3$bridge$estim_method)[1], isTRUE(j3$effective_REML), attr(logLik(j3),"df")))
ct <- flat(coef(t3)); cj <- flat(coef(j3)); names(ct) <- nm(names(ct)); names(cj) <- nm(names(cj))
k <- intersect(names(ct), names(cj))
for (i in k) cat(sprintf("  coef %-22s tmb=%.12f julia=%.12f d=%.6e\n", i, ct[[i]], cj[[i]], abs(ct[[i]]-cj[[i]])))
cat(sprintf("MAX_ABS_COEF_DIFF=%.12e  names_identical=%s  n=%d\n", max(abs(ct[k]-cj[k])),
            identical(sort(names(ct)), sort(names(cj))), length(k)))
cat(sprintf("logLik REML tmb=%.12f julia=%.12f ABS_DIFF=%.12e\n",
            as.numeric(logLik(t3)), as.numeric(logLik(j3)), abs(as.numeric(logLik(t3))-as.numeric(logLik(j3)))))
cat(sprintf("logLik ML   tmb=%.12f julia=%.12f ABS_DIFF=%.12e  (tmb ML convergence=%s)\n",
            as.numeric(logLik(t3m)), as.numeric(logLik(j3m)), abs(as.numeric(logLik(t3m))-as.numeric(logLik(j3m))), t3m$opt$convergence))
cat(sprintf("ML_REML_GAP tmb=%.12f julia=%.12f\n",
            as.numeric(logLik(t3m))-as.numeric(logLik(t3)), as.numeric(logLik(j3m))-as.numeric(logLik(j3))))
sj <- se_of(j3); st <- se_of(t3)
cat("julia SE: ", paste(sprintf("%s=%s", names(sj), sj), collapse=", "), "\n", sep="")
cat("tmb   SE: ", paste(sprintf("%s=%.6f", names(st), st), collapse=", "), "\n", sep="")
cat("n non-finite julia SE = ", sum(!is.finite(sj)), " / ", length(sj), "\n", sep="")
cat("\nDONE\n")
