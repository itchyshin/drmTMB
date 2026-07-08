# Authoritative q-indexed ML/REML completeness matrix.
# q = dimension of the CORRELATED random-effect covariance block (how many endpoints
# share one block). Two separate q2 blocks are NOT a q4 block.
# Reports admission (FITS / REJ) under ML and REML, empirically.
suppressPackageStartupMessages({devtools::load_all(".", quiet = TRUE); library(ape)})
Sys.setenv(OPENBLAS_NUM_THREADS = "1")

# ---- ordinary data (replicated: scale REs need within-group replication) ----
set.seed(7); n_id <- 40L; n_each <- 8L; n <- n_id * n_each
id <- rep(seq_len(n_id), each = n_each); x <- rnorm(n); x1 <- rnorm(n); x2 <- rnorm(n)
b <- rnorm(n_id, 0, .5)
do_ <- data.frame(id = factor(id), x = x, x1 = x1, x2 = x2,
  y = .3 + .5 * x + b[id] + rnorm(n, 0, .5),
  y1 = .3 + .5 * x + b[id] + rnorm(n, 0, .5), y2 = .6 + .2 * x + rnorm(n, 0, .6))

# ---- phylo data (replicated tips) ----
n_tip <- 60L; ne <- 5L; np <- n_tip * ne
tree <- rcoal(n_tip); tree$tip.label <- paste0("sp_", seq_len(n_tip))
tip <- rep(seq_len(n_tip), each = ne); u <- as.vector(t(chol(vcv(tree, corr = TRUE))) %*% rnorm(n_tip))
dp <- data.frame(sp = factor(tree$tip.label[tip], levels = tree$tip.label), x = rnorm(np),
  y = .3 + u[tip] + rnorm(np, 0, .5), y1 = .3 + u[tip] + rnorm(np, 0, .5), y2 = .6 + rnorm(np, 0, .6))

cells <- list(
  # ---- univariate ORDINARY ----
  list("uni ord", "q1", "mu intercept                (1|id)",            quote(bf(y ~ x + (1|id), sigma ~ 1)), "o", gaussian()),
  list("uni ord", "q1", "sigma intercept             (1|id)",            quote(bf(y ~ x, sigma ~ 1 + (1|id))), "o", gaussian()),
  list("uni ord", "q1", "sigma indep slope       (0+x|id)",              quote(bf(y ~ x + (1|id), sigma ~ x + (0+x|id))), "o", gaussian()),
  list("uni ord", "q2", "mu int+slope block       (1+x|id)",             quote(bf(y ~ x + (1+x|id), sigma ~ 1)), "o", gaussian()),
  list("uni ord", "q2", "SIGMA int+slope block  (1+x|id)  [NEW]",        quote(bf(y ~ x, sigma ~ x + (1+x|id))), "o", gaussian()),
  list("uni ord", "q2", "mu-int <-> sigma-int    (1|p|id)",              quote(bf(y ~ x + (1|p|id), sigma ~ 1 + (1|p|id))), "o", gaussian()),
  list("uni ord", "q3", "mu 3-dim block     (1+x1+x2|id)",               quote(bf(y ~ x1 + x2 + (1+x1+x2|id), sigma ~ 1)), "o", gaussian()),
  list("uni ord", "2xq2","mu(1+x|id) + sigma(1+x|id)  [DHGLM slopes]",   quote(bf(y ~ x + (1+x|id), sigma ~ x + (1+x|id))), "o", gaussian()),
  list("uni ord", "q4", "labelled cross mu/sigma SLOPE (1+x|p|id)",      quote(bf(y ~ x + (1+x|p|id), sigma ~ x + (1+x|p|id))), "o", gaussian()),
  # ---- univariate PHYLO ----
  list("uni phylo","q1","phylo mean                phylo(1|sp)",          quote(bf(y ~ x + phylo(1|sp, tree=tree), sigma ~ 1)), "p", gaussian()),
  list("uni phylo","q1","phylo scale (pure)     sigma~phylo(1|sp)",       quote(bf(y ~ x, sigma ~ phylo(1|sp, tree=tree))), "p", gaussian()),
  list("uni phylo","q2","matched mean+scale  phylo(1|p|sp)",             quote(bf(y ~ x + phylo(1|p|sp, tree=tree), sigma ~ 1 + phylo(1|p|sp, tree=tree))), "p", gaussian()),
  # ---- bivariate ----
  list("biv ord", "q2", "mu1,mu2 location block   (1|p|id)",             quote(bf(mu1=y1~x+(1|p|id), mu2=y2~x+(1|p|id), rho12=~1)), "o", biv_gaussian()),
  list("biv ord", "q2", "sigma1,sigma2 scale block (1|s|id)",            quote(bf(mu1=y1~x, mu2=y2~x, sigma1=~1+(1|s|id), sigma2=~1+(1|s|id), rho12=~1)), "o", biv_gaussian()),
  list("biv ord", "q2", "mu1 <-> sigma1 cross      (1|p|id)",            quote(bf(mu1=y1~x+(1|p|id), mu2=y2~x, sigma1=~1+(1|p|id), sigma2=~1, rho12=~1)), "o", biv_gaussian()),
  list("biv ord", "q4", "all four ordinary         (1|p|id)",            quote(bf(mu1=y1~x+(1|p|id), mu2=y2~x+(1|p|id), sigma1=~1+(1|p|id), sigma2=~1+(1|p|id), rho12=~1)), "o", biv_gaussian()),
  list("biv phylo","q2","mu1,mu2 phylo means",                            quote(bf(mu1=y1~x+phylo(1|p|sp,tree=tree), mu2=y2~x+phylo(1|p|sp,tree=tree), rho12=~1)), "p", biv_gaussian()),
  list("biv phylo","2xq2","block-diagonal (mu p) ⊥ (sigma ps)",           quote(bf(mu1=y1~1+phylo(1|p|sp,tree=tree), mu2=y2~1+phylo(1|p|sp,tree=tree), sigma1=~1+phylo(1|ps|sp,tree=tree), sigma2=~1+phylo(1|ps|sp,tree=tree), rho12=~1)), "p", biv_gaussian()),
  list("biv phylo","q4","DENSE all four phylo   (1|p|sp)",               quote(bf(mu1=y1~1+phylo(1|p|sp,tree=tree), mu2=y2~1+phylo(1|p|sp,tree=tree), sigma1=~1+phylo(1|p|sp,tree=tree), sigma2=~1+phylo(1|p|sp,tree=tree), rho12=~1)), "p", biv_gaussian()),
  list("biv ord", "q8", "all four + slopes      (1+x|p|id)",             quote(bf(mu1=y1~x+(1+x|p|id), mu2=y2~x+(1+x|p|id), sigma1=~x+(1+x|p|id), sigma2=~x+(1+x|p|id), rho12=~1)), "o", biv_gaussian())
)

adm <- function(form, fam, dat, reml) {
  tryCatch({
    f <- suppressWarnings(drmTMB(form, fam, dat, REML = reml,
           control = drm_control(optimizer_preset = "robust")))
    "FITS"
  }, error = function(e) "REJ")
}
cat(sprintf("%-10s %-6s %-42s %-6s %-6s\n", "family", "q", "block shape", "ML", "REML"))
cat(strrep("-", 78), "\n")
for (cc in cells) {
  dat <- if (cc[[5]] == "o") do_ else dp
  form <- eval(cc[[4]])
  ml <- adm(form, cc[[6]], dat, FALSE); rl <- adm(form, cc[[6]], dat, TRUE)
  flag <- if (ml == "FITS" && rl == "REJ") "  <<< parity gap" else if (ml == "REJ" && rl == "FITS") "  <<< REML w/o ML!" else ""
  cat(sprintf("%-10s %-6s %-42s %-6s %-6s%s\n", cc[[1]], cc[[2]], cc[[3]], ml, rl, flag))
}
cat("\nQ COMPLETENESS MATRIX DONE\n")
