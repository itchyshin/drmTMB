# Route table shared by r_run.R, diagnose.R and compare.R.
# nmu: mean coefficients; sigma: has beta_sigma; sdz: predictor column of each SD formula (one per random coefficient);
# coefs: coefficient name of each SD formula; level: sd(level=) ("" for ordinary); rho: "chol" (q3/q4, theta_re_cov, same
# parameterisation both sides, included in coefficient comparison), "q2" (gauss_ord: R eta_cor = atanh(rho), Julia theta = rho/sqrt(1-rho^2);
# compared on the rho scale only), "none".
ROUTES <- list(
  gauss_q3 = list(mean = "y ~ x + z + (1 + x + z | id)", nmu = 3, sigma = TRUE, coefs = c("(Intercept)", "x", "z"), sdz = rep("w", 3), level = "", rho = "chol", q = 3, fam = "gaussian", grp = "id"),
  gauss_q4 = list(mean = "y ~ x + z + (1 + x + z + u | id)", nmu = 3, sigma = TRUE, coefs = c("(Intercept)", "x", "z", "u"), sdz = rep("w", 4), level = "", rho = "chol", q = 4, fam = "gaussian", grp = "id"),
  gauss_ord = list(mean = "y ~ x + (1 + x | id)", nmu = 2, sigma = TRUE, coefs = c("(Intercept)", "x"), sdz = c("z0", "z1"), level = "", rho = "q2", q = 2, fam = "gaussian", grp = "g"),
  nb2_relmat = list(mean = "y ~ x + relmat(1 + x | id, K = K)", nmu = 2, sigma = TRUE, coefs = c("(Intercept)", "x"), sdz = c("z0", "z1"), level = "relmat", rho = "none", fam = "nbinom2", grp = "g"),
  poisson_relmat = list(mean = "y ~ x + relmat(1 + x | id, K = K)", nmu = 2, sigma = FALSE, coefs = c("(Intercept)", "x"), sdz = c("z0", "z1"), level = "relmat", rho = "none", fam = "poisson", grp = "g"),
  nb2_animal = list(mean = "y ~ x + animal(1 + x | id, A = K)", nmu = 2, sigma = TRUE, coefs = c("(Intercept)", "x"), sdz = c("z0", "z1"), level = "animal", rho = "none", fam = "nbinom2", grp = "g"),
  nb2_phylo = list(mean = "y ~ x + phylo(1 + x | id, tree = tree)", nmu = 2, sigma = TRUE, coefs = c("(Intercept)", "x"), sdz = c("z0", "z1"), level = "phylogenetic", rho = "none", fam = "nbinom2", grp = "g"),
  gauss_relmat = list(mean = "y ~ x + relmat(1 + x | id, K = K)", nmu = 2, sigma = TRUE, coefs = c("(Intercept)", "x"), sdz = c("z0", "z1"), level = "relmat", rho = "none", fam = "gaussian", grp = "g"))
family_of <- function(f) switch(f, gaussian = gaussian(), nbinom2 = nbinom2(), poisson = stats::poisson())
# Build the drmTMB model for one dataset; K and tree are looked up in the formula environment.
build_model <- function(route, d, K = NULL, tree = NULL) {
  r <- ROUTES[[route]]; env <- environment()
  f <- as.formula(r$mean); environment(f) <- env
  sds <- lapply(seq_along(r$coefs), function(k) {
    s <- if (r$level == "") sprintf('sd(id, coef = "%s") ~ %s', r$coefs[k], r$sdz[k])
         else sprintf('sd(id, level = "%s", coef = "%s") ~ %s', r$level, r$coefs[k], r$sdz[k])
    s <- as.formula(s); environment(s) <- env; s })
  args <- c(list(f), if (r$sigma) list(sigma ~ 1), sds)
  list(bf = do.call(bf, args), family = family_of(r$fam))
}
read_dataset <- function(O, tag, route) {
  d <- read.csv(file.path(O, "data", paste0(tag, ".csv")))
  grp <- ROUTES[[route]]$grp
  d$id <- factor(d[[grp]], levels = unique(d[[grp]]))
  kf <- file.path(O, "data", paste0(tag, "_K.csv")); K <- NULL
  if (file.exists(kf)) { K <- as.matrix(read.csv(kf, header = FALSE)); kid <- read.csv(file.path(O, "data", paste0(tag, "_ids.csv")))$id; dimnames(K) <- list(kid, kid) }
  list(d = d, K = K)
}
