# ML/REML parity audit across the q-ladder (Shinichi's check: no REML-without-ML;
# ML implemented for every combination). For each model SHAPE, classify admission
# under ML (REML=FALSE) and REML (REML=TRUE): "fit" | "GATE" (validation reject) |
# "err" (other). Invariant: REML must NOT admit what ML rejects.
suppressPackageStartupMessages({devtools::load_all(".", quiet = TRUE); library(ape)})
set.seed(5); n_tip <- 40L; n_each <- 5L; n <- n_tip * n_each
tree <- rcoal(n_tip); tree$tip.label <- paste0("sp_", seq_len(n_tip))
A <- vcv(tree, corr = TRUE); L <- t(chol(A))
tip <- rep(seq_len(n_tip), each = n_each)
u1 <- (L %*% rnorm(n_tip))[tip]; u2 <- (L %*% rnorm(n_tip))[tip]
x <- rnorm(n); z <- rnorm(n_tip)[tip]
d <- data.frame(
  sp = factor(tree$tip.label[tip], levels = tree$tip.label),
  id = factor(tip), x = x, z = z,
  y  = 0.3 + 0.5 * x + 0.6 * u1 + rnorm(n, 0, exp(-0.7 + 0.3 * u2)),
  y1 = 0.3 + 0.5 * x + 0.6 * u1 + rnorm(n, 0, 0.5),
  y2 = 0.6 + 0.2 * x + 0.5 * u2 + rnorm(n, 0, 0.6)
)
gate_re <- "not implemented|not validated|supports|require|only|cannot|combine|Larger|planned"

classify <- function(form, fam, reml) {
  out <- tryCatch(
    {f <- suppressWarnings(drmTMB(form, fam, d, REML = reml,
           control = drm_control(optimizer_preset = "robust"))); "fit"},
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl(gate_re, msg, ignore.case = TRUE)) paste0("GATE") else paste0("err:", substr(sub("\n.*","",msg),1,40))
    })
  out
}

shapes <- list(
  `q1 uni phylo-mean`            = list(gaussian(), quote(bf(y ~ x + phylo(1|sp,tree=tree), sigma ~ 1))),
  `q2 uni matched mean+scale`    = list(gaussian(), quote(bf(y ~ x + phylo(1|p|sp,tree=tree), sigma ~ 1 + phylo(1|p|sp,tree=tree)))),
  `uni ordinary loc-int`         = list(gaussian(), quote(bf(y ~ x + (1|id), sigma ~ 1))),
  `uni ord loc+scale CORR (1|p|id)` = list(gaussian(), quote(bf(y ~ x + (1|p|id), sigma ~ x + (1|p|id)))),
  `uni ord loc-slope (1+x|id)`   = list(gaussian(), quote(bf(y ~ x + (1+x|id), sigma ~ 1))),
  `uni ord scale-slope indep`    = list(gaussian(), quote(bf(y ~ x + (1|id), sigma ~ x + (0+x|id)))),
  `biv rung1 phylo-means`        = list(biv_gaussian(), quote(bf(mu1=y1~x+phylo(1|p|sp,tree=tree), mu2=y2~x+phylo(1|p|sp,tree=tree), rho12=~1))),
  `biv rung2 direct-SD`          = list(biv_gaussian(), quote(bf(mu1=y1~x+phylo(1|p|sp,tree=tree), mu2=y2~x+phylo(1|p|sp,tree=tree), sigma1=~1, sigma2=~1, sd_phylo1(sp)~x, sd_phylo2(sp)~x, rho12=~1))),
  `biv q4 BLOCK-DIAGONAL`        = list(biv_gaussian(), quote(bf(mu1=y1~1+phylo(1|p|sp,tree=tree), mu2=y2~1+phylo(1|p|sp,tree=tree), sigma1=~1+phylo(1|ps|sp,tree=tree), sigma2=~1+phylo(1|ps|sp,tree=tree), rho12=~1))),
  `biv q4 DENSE (all one label)` = list(biv_gaussian(), quote(bf(mu1=y1~1+phylo(1|p|sp,tree=tree), mu2=y2~1+phylo(1|p|sp,tree=tree), sigma1=~1+phylo(1|p|sp,tree=tree), sigma2=~1+phylo(1|p|sp,tree=tree), rho12=~1)))
)

cat(sprintf("%-34s %-8s %-8s  %s\n", "shape", "ML", "REML", "parity"))
cat(strrep("-", 70), "\n")
for (nm in names(shapes)) {
  fam <- shapes[[nm]][[1]]; form <- eval(shapes[[nm]][[2]])
  ml <- classify(form, fam, FALSE); rl <- classify(form, fam, TRUE)
  # parity violation: REML admits (fit) but ML does not
  viol <- if (rl == "fit" && ml != "fit") "  <<< REML-without-ML!" else ""
  cat(sprintf("%-34s %-8s %-8s%s\n", nm, ml, rl, viol))
}
cat("\nAUDIT DONE\n")
