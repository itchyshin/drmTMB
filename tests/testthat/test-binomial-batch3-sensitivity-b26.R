# Batch 26 (lane sa) companion to test-binomial-batch3-sd-regression.R.
# Probit and cloglog phylo(1 | species, tree) + animal(1 | animal_id, <A,
# Ainv, pedigree>) with a different predictor and coefficient set per SD.
# The existing oracle builds A and the tree covariance with package helpers;
# here (the package phylo() term uses cov2cor(ape::vcv); the tree is scaled so
# raw vcv differs from it) A is a tabular (Henderson) matrix with inbreeding written in
# helper-b26sa-oracles.R, the tree covariance is ape::vcv (and the package
# helper is compared with it), and the dense Laplace is base R. logLik
# tolerance 1e-4. Emulated bugs (reversed SD vectors, swapped selector
# coefficient sets, cov2cor of K or A) must move the oracle by more than 0.1.
# Scope: likelihood agreement at the fitted parameters only.

b26sa_bin_alpha_animal <- c(`(Intercept)` = log(0.8), z_animal = 0.7)
b26sa_bin_alpha_tree <- c(`(Intercept)` = log(1.0), z_tree = -0.6)

b26sa_bin_fixture <- function(link, seed, n_animal = 30L, n_tip = 24L,
                              n_rep = 2L) {
  set.seed(seed)
  ped <- b26sa_pedigree(6L, n_animal)
  A_ped <- b26sa_henderson_A(ped)
  stopifnot(max(diag(A_ped)) > 1.05)
  animal_levels <- ped$id
  A <- A_ped[rev(animal_levels), rev(animal_levels)]   # matrix order != data
  tree <- ape::rcoal(n_tip)
  tree$edge.length <- 3 * tree$edge.length          # tree height != 1
  tree$tip.label <- sample(sprintf("sp%02d", seq_len(n_tip)))
  species_levels <- sort(tree$tip.label)
  Kt_raw <- ape::vcv(tree)[species_levels, species_levels]
  Kt <- stats::cov2cor(Kt_raw)       # phylo() uses the correlation form
  z_animal <- stats::setNames(
    seq(-1, 1, length.out = n_animal)[sample.int(n_animal)], animal_levels)
  z_tree <- stats::setNames(
    seq(-1, 1, length.out = n_tip)[sample.int(n_tip)], species_levels)
  sd_a <- exp(b26sa_bin_alpha_animal[[1L]] +
                b26sa_bin_alpha_animal[[2L]] * z_animal)
  sd_t <- exp(b26sa_bin_alpha_tree[[1L]] + b26sa_bin_alpha_tree[[2L]] * z_tree)
  f_a <- as.vector(t(chol(A_ped)) %*% stats::rnorm(n_animal)) * sd_a
  f_t <- as.vector(t(chol(Kt)) %*% stats::rnorm(n_tip)) * sd_t
  names(f_a) <- animal_levels
  names(f_t) <- species_levels
  design <- expand.grid(rep = seq_len(n_rep), a = animal_levels,
                        s = species_levels, stringsAsFactors = FALSE)
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.3 * x + f_a[design$a] + f_t[design$s]
  y <- stats::rbinom(nrow(design), 1L, stats::make.link(link)$linkinv(eta))
  list(
    data = data.frame(
      y = y, x = x,
      animal_id = factor(design$a, levels = animal_levels),
      species = factor(design$s, levels = species_levels),
      z_animal = unname(z_animal[design$a]), z_tree = unname(z_tree[design$s])
    ),
    tree = tree, pedigree = ped, A = A, Ainv = solve(A), Kt = Kt, Kt_raw = Kt_raw,
    animal_levels = animal_levels, species_levels = species_levels,
    z_animal = z_animal, z_tree = z_tree
  )
}

b26sa_bin_fit <- function(fx, link, provider) {
  tree <- fx$tree
  A <- fx$A
  Ainv <- fx$Ainv
  pedigree <- fx$pedigree
  animal_term <- switch(
    provider,
    A = "animal(1 | animal_id, A = A)",
    Ainv = "animal(1 | animal_id, Ainv = Ainv)",
    pedigree = "animal(1 | animal_id, pedigree = pedigree)"
  )
  fml <- eval(parse(text = sprintf(
    paste0("bf(y ~ x + phylo(1 | species, tree = tree) + %s, ",
           "sd(species, level = \"phylogenetic\") ~ z_tree, ",
           "sd(animal_id, level = \"animal\") ~ z_animal)"),
    animal_term
  )))
  drmTMB(fml, family = stats::binomial(link = link), data = fx$data,
         control = drm_control(se = FALSE))
}

test_that("package phylo tip covariance equals cov2cor(ape::vcv) for the batch 3 tree", {
  skip_on_cran()
  skip_if_not_installed("ape")
  b26sa_check_phylo_cov(b26sa_bin_fixture("probit", 20262001L)$tree)
})

test_that("binomial probit and cloglog phylo plus animal SDs: Henderson/ape oracle and bug sensitivity", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (link in c("probit", "cloglog")) {
    fx <- b26sa_bin_fixture(link, if (link == "probit") 20262001L else 20262002L)
    fam <- b26sa_family(link)
    dat <- fx$data
    # Independent check: the data-generating A matches the Henderson A that the
    # fits receive (same pedigree), and the pedigree provider gets that pedigree.
    expect_equal(fx$A[fx$animal_levels, fx$animal_levels],
                 b26sa_henderson_A(fx$pedigree), tolerance = 1e-12)
    for (provider in c("A", "Ainv", "pedigree")) {
      info <- paste(link, provider)
      fit <- b26sa_bin_fit(fx, link, provider)
      expect_identical(fit$opt$convergence, 0L, info = info)
      ca <- coef(fit, "sd_animal(animal_id)")
      ct <- coef(fit, "sd_phylo(species)")
      expect_identical(names(ca), c("(Intercept)", "z_animal"), info = info)
      expect_identical(names(ct), c("(Intercept)", "z_tree"), info = info)
      curve <- function(co, z) unname(exp(co[[1L]] + co[[2L]] * z))
      al <- fx$animal_levels
      sp <- fx$species_levels
      A <- fx$A[al, al]
      Kt <- fx$Kt
      mu <- coef(fit, "mu")
      eta0 <- mu[[1L]] + mu[[2L]] * dat$x
      oracle <- function(sd_a = curve(ca, fx$z_animal[al]),
                         sd_t = curve(ct, fx$z_tree[sp]),
                         Ka = A, Kp = Kt) {
        as.numeric(b26sa_laplace(
          dat$y, eta0,
          list(list(index = match(as.character(dat$animal_id), al),
                    sd = sd_a, K = Ka),
               list(index = match(as.character(dat$species), sp),
                    sd = sd_t, K = Kp)),
          fam
        ))
      }
      ll <- as.numeric(logLik(fit))
      expect_lt(abs(ll - oracle()), 1e-4, label = info)
      sd_a <- curve(ca, fx$z_animal[al])
      sd_t <- curve(ct, fx$z_tree[sp])
      bugs <- c(
        reversed_animal_sd = oracle(sd_a = rev(sd_a)),
        reversed_tree_sd = oracle(sd_t = rev(sd_t)),
        swapped_selector_coefs = oracle(sd_a = curve(ct, fx$z_animal[al]),
                                        sd_t = curve(ca, fx$z_tree[sp])),
        raw_vcv_phylo_K = oracle(Kp = fx$Kt_raw),
        cov2cor_A = oracle(Ka = stats::cov2cor(A))
      )
      for (nm in names(bugs)) {
        expect_gt(abs(ll - bugs[[nm]]), 0.1, label = paste(info, nm))
      }
    }
  }
})
