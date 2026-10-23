suppressMessages(devtools::load_all("/Users/z3437171/local-scratch/parity-joint/wt-uncited-reml", quiet = TRUE))
suppressMessages(library(ape))
options(digits = 15)
nm <- function(x) gsub("[.:]", "_", x)
se_of <- function(fit) {
  s <- try(summary(fit)$coefficients, silent = TRUE)
  if (!inherits(s, "try-error") && !is.null(s) && "std_error" %in% colnames(s))
    return(stats::setNames(as.numeric(s[, "std_error"]), nm(rownames(s))))
  v <- try(stats::vcov(fit), silent = TRUE)
  if (inherits(v, "try-error") || is.null(v)) return(NULL)
  v <- as.matrix(v); stats::setNames(sqrt(diag(v)), nm(rownames(v)))
}

## CONTROL A: is the cell-1 mu-block SE gap driven by the sigma COVARIATE?
set.seed(1); n <- 60; x <- rnorm(n); z <- rnorm(n)
y <- 0.5 + 0.8 * x + rnorm(n, sd = exp(-0.3 + 0.25 * z))
d1 <- data.frame(y = y, x = x, z = z)
for (tag in c("sigma ~ z (the receipt cell)", "sigma ~ 1 (control)")) {
  f <- if (grepl("z", tag)) bf(y ~ x, sigma ~ z) else bf(y ~ x, sigma ~ 1)
  st <- se_of(drmTMB(f, gaussian(), data = d1, REML = TRUE, engine = "tmb"))
  sj <- se_of(drmTMB(f, gaussian(), data = d1, REML = TRUE, engine = "julia"))
  k <- intersect(names(st), names(sj))
  cat("\n## CONTROL A ", tag, "\n", sep = "")
  for (i in k) cat(sprintf("   SE %-20s tmb=%.12f julia=%.12f rel=%.6e\n", i, st[[i]], sj[[i]], abs(st[[i]]-sj[[i]])/abs(st[[i]])))
}

## CONTROL B: does the bridge fit the BLOCK-DIAGONAL q4 layout, or a DENSE one?
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
blockdiag <- bf(mu1 = y1 ~ 1 + phylo(1 | p  | sp, tree = tree),
                mu2 = y2 ~ 1 + phylo(1 | p  | sp, tree = tree),
                sigma1 = ~ 1 + phylo(1 | ps | sp, tree = tree),
                sigma2 = ~ 1 + phylo(1 | ps | sp, tree = tree), rho12 = ~ 1)
dense     <- bf(mu1 = y1 ~ 1 + phylo(1 | p | sp, tree = tree),
                mu2 = y2 ~ 1 + phylo(1 | p | sp, tree = tree),
                sigma1 = ~ 1 + phylo(1 | p | sp, tree = tree),
                sigma2 = ~ 1 + phylo(1 | p | sp, tree = tree), rho12 = ~ 1)
tb <- suppressWarnings(drmTMB(blockdiag, biv_gaussian(), data = d3, REML = TRUE, engine = "tmb",
                              control = drm_control(optimizer_preset = "robust")))
td <- suppressWarnings(drmTMB(dense, biv_gaussian(), data = d3, REML = TRUE, engine = "tmb",
                              control = drm_control(optimizer_preset = "robust")))
jb <- drmTMB(blockdiag, biv_gaussian(), data = d3, REML = TRUE, engine = "julia")
cat("\n## CONTROL B  same data, three fits\n")
for (o in list(list("tmb  BLOCK-DIAG", tb), list("tmb  DENSE     ", td), list("julia BLOCK-DIAG call", jb))) {
  ll <- logLik(o[[2]])
  cat(sprintf("   %-22s logLik=%.9f df=%s convergence=%s\n", o[[1]], as.numeric(ll), attr(ll, "df"),
              if (is.null(o[[2]]$opt$convergence)) "NA(bridge)" else o[[2]]$opt$convergence))
}
cat(sprintf("   |julia(blockdiag call) - tmb BLOCK-DIAG| = %.9f\n", abs(as.numeric(logLik(jb)) - as.numeric(logLik(tb)))))
cat(sprintf("   |julia(blockdiag call) - tmb DENSE     | = %.9f\n", abs(as.numeric(logLik(jb)) - as.numeric(logLik(td)))))
sj <- se_of(jb); st <- se_of(tb)
cat("   julia SEs: ", paste(sprintf("%s=%s", names(sj), sj), collapse = ", "), "\n", sep = "")
cat("   tmb   SEs: ", paste(sprintf("%s=%.6f", names(st), st), collapse = ", "), "\n", sep = "")
cat("   n non-finite julia SE: ", sum(!is.finite(sj)), " / ", length(sj), "\n", sep = "")
cat("\nDONE\n")
