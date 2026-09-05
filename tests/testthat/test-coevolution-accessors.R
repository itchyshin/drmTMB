# coevolution_cor() / coevolution_vc() / coevolution_summary(): the q = 4
# among-axis accessors ported from DRM.jl `src/coevo_accessors.jl` (#1118).
#
# Three tiers:
#   1. pure R on a hand-built `drmTMB_julia` fixture with a KNOWN Sigma_a
#      (exact recovery, the julia-scale conversion, field names) -- no Julia;
#   2. a small native (engine = "tmb") q = 4 phylo fit: shape/consistency
#      checks mirroring DRM.jl `test/test_coevo_accessors.jl`, agreement with
#      the C++ `phylo_q4_covariance` report, and the refusal guard on the
#      non-coevolution fits that file rejects (plus the q = 2 and univariate
#      shapes drmTMB can build);
#   3. LIVE same-target parity against DRM.jl's own accessors at the pinned
#      DRM.jl, computed natively in Julia via JuliaCall on two committed
#      fixtures (skip-gated on engine availability only; an engine error is a
#      test ERROR, never a skip -- #1127).

coevo_axes <- c("mu1", "mu2", "sigma1", "sigma2")

# DRM.jl-style log-Cholesky serialisation of a 4 x 4 Sigma_a into the bridge's
# `Sigma_a:L<row><col>` naming (column-major lower triangle, log diagonal).
coevo_log_cholesky <- function(Sigma_a) {
  Lc <- t(chol(Sigma_a))
  lc <- numeric()
  for (col in seq_len(4L)) {
    for (rw in col:4L) {
      nm <- sprintf("Sigma_a:L%d%d", rw, col)
      lc[[nm]] <- if (rw == col) log(Lc[rw, col]) else Lc[rw, col]
    }
  }
  lc
}

coevo_formula <- function(tree) {
  drmTMB::bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
    sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
    rho12 = ~1
  )
}

# Hand-built `drmTMB_julia` q = 4 fit carrying a known Sigma_a (the same
# construction test-julia-phylo-q4-corpairs.R uses for corpairs()).
coevo_synthetic_julia_fit <- function(Sigma_a, sd_scale = 1) {
  lc <- coevo_log_cholesky(Sigma_a)
  result <- list(
    coef_names = c(
      "mu1_(Intercept)", "mu1_x", "mu2_(Intercept)", "mu2_x",
      "sigma1_(Intercept)", "sigma2_(Intercept)", "rho12_(Intercept)",
      paste0("phylocov_", names(lc))
    ),
    coefficients = c(1.0, 0.5, -1.0, 0.3, -0.7, -0.8, 0.2, unname(lc)),
    vcov = diag(length(lc) + 7L),
    loglik = -100, aic = 200, bic = 220, df = 7L, nobs = 8L,
    converged = TRUE,
    fitted = list(mu1 = seq_len(8), mu2 = seq_len(8)),
    residuals = list(mu1 = rep(0, 8), mu2 = rep(0, 8)),
    sigma = list(sigma1 = rep(0.5, 8), sigma2 = rep(0.45, 8)),
    corpairs = rep(tanh(0.2), 8)
  )
  tree <- ape::rcoal(4)
  form <- coevo_formula(tree)
  dat <- data.frame(
    species = tree$tip.label[rep(1:4, 2)],
    x = stats::rnorm(8), y1 = stats::rnorm(8), y2 = stats::rnorm(8),
    stringsAsFactors = FALSE
  )
  fit <- drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(form, family = biv_gaussian(), data = dat, engine = "julia")),
    formula = form, family = drmTMB::biv_gaussian(), data = dat,
    family_type = "biv_gaussian"
  )
  fit$structured_sd_scales <- stats::setNames(
    rep(sd_scale, 4L), rep("phylo(1 | p | species)", 4L)
  )
  fit
}

# --- Tier 1: pure R, known Sigma_a --------------------------------------------

test_that("coevolution accessors recover a known Sigma_a exactly from a julia-style fit", {
  skip_if_not_installed("ape")
  set.seed(1)
  sds <- c(0.8, 0.7, 0.3, 0.3)
  Cor <- matrix(c(
    1.0, 0.5, 0.2, 0.0,
    0.5, 1.0, 0.0, -0.3,
    0.2, 0.0, 1.0, 0.4,
    0.0, -0.3, 0.4, 1.0
  ), 4L, 4L)
  Sigma_a <- diag(sds) %*% Cor %*% diag(sds)
  fit <- coevo_synthetic_julia_fit(Sigma_a)

  rc <- coevolution_cor(fit)
  expect_named(rc, c("cor", "axes"))
  expect_identical(rc$axes, coevo_axes)
  expect_identical(dimnames(rc$cor), list(coevo_axes, coevo_axes))
  expect_equal(unname(rc$cor), Cor, tolerance = 1e-12)
  expect_identical(unname(diag(rc$cor)), rep(1, 4L))
  expect_identical(rc$cor, t(rc$cor))

  vc <- coevolution_vc(fit)
  expect_named(vc, c("axes", "variance", "sd", "cov"))
  expect_equal(unname(vc$variance), sds^2, tolerance = 1e-12)
  expect_equal(unname(vc$sd), sds, tolerance = 1e-12)
  expect_named(vc$variance, coevo_axes)
  expect_equal(unname(vc$cov), Sigma_a, tolerance = 1e-12)

  s <- coevolution_summary(fit)
  expect_named(
    s,
    c("axes", "variance", "sd", "pair", "correlation", "covariance", "cor", "cov")
  )
  expect_identical(dim(s$pair), c(6L, 2L))
  expect_identical(colnames(s$pair), c("from", "to"))
  # DRM.jl's pair order: i < j row-major over the upper triangle.
  expect_identical(
    unname(s$pair[, "from"]),
    c("mu1", "mu1", "mu1", "mu2", "mu2", "sigma1")
  )
  expect_identical(
    unname(s$pair[, "to"]),
    c("mu2", "sigma1", "sigma2", "sigma1", "sigma2", "sigma2")
  )
  expect_equal(
    unname(s$correlation),
    c(0.5, 0.2, 0.0, 0.0, -0.3, 0.4),
    tolerance = 1e-12
  )
  expect_equal(unname(s$covariance), Sigma_a[upper.tri(Sigma_a)][c(1, 2, 4, 3, 5, 6)],
    tolerance = 1e-12
  )
  expect_named(s$correlation, paste(s$pair[, "from"], s$pair[, "to"], sep = ":"))
  expect_equal(s$cor, rc$cor)
  expect_equal(s$cov, vc$cov)
})

test_that("julia-engine Sigma_a is rescaled to the unit-height convention (#693)", {
  skip_if_not_installed("ape")
  set.seed(2)
  sds <- c(0.8, 0.7, 0.3, 0.3)
  Sigma_a <- diag(sds) %*% diag(4L) %*% diag(sds)
  Sigma_a[1, 2] <- Sigma_a[2, 1] <- 0.6 * 0.8 * 0.7
  sd_scale <- 1.7 # sqrt(tree height) for a non-unit-height tree
  fit <- coevo_synthetic_julia_fit(Sigma_a, sd_scale = sd_scale)

  vc <- coevolution_vc(fit)
  expect_equal(unname(vc$cov), Sigma_a * sd_scale^2, tolerance = 1e-12)
  expect_equal(unname(vc$sd), sds * sd_scale, tolerance = 1e-12)
  # correlations are scale-free
  expect_equal(coevolution_cor(fit)$cor["mu1", "mu2"], 0.6, tolerance = 1e-12)
  # and a julia fit with no phylocov block is refused
  fit$phylocov <- NULL
  fit$coefficients$phylocov <- NULL
  expect_error(coevolution_cor(fit), "4 x 4")
})

# --- Tier 2: native engine ------------------------------------------------------

coevo_native_data <- function(seed = 20260905, n_tip = 16L, m = 4L) {
  set.seed(seed)
  tree <- ape::compute.brlen(ape::stree(n_tip, type = "balanced"), 1)
  tree$tip.label <- paste0("t", seq_len(n_tip))
  C <- ape::vcv(tree, corr = TRUE)
  sds <- c(0.8, 0.7, 0.4, 0.4)
  Cor <- diag(4L)
  Cor[1, 2] <- Cor[2, 1] <- 0.6
  Sigma_a <- diag(sds) %*% Cor %*% diag(sds)
  A <- t(chol(C)) %*% matrix(stats::rnorm(n_tip * 4), n_tip, 4) %*% chol(Sigma_a)
  rows <- rep(seq_len(n_tip), each = m)
  x <- stats::rnorm(length(rows))
  dat <- data.frame(
    species = tree$tip.label[rows],
    x = x,
    y1 = stats::rnorm(length(rows), 2 + 0.5 * x + A[rows, 1], exp(-0.7 + A[rows, 3])),
    y2 = stats::rnorm(length(rows), -1 + 0.3 * x + A[rows, 2], exp(-0.5 + A[rows, 4])),
    stringsAsFactors = FALSE
  )
  list(data = dat, tree = tree, Sigma_a = Sigma_a)
}

test_that("native q = 4 phylo fit: cor/vc/summary are consistent with the stored Sigma_a", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- coevo_native_data()
  tree <- fx$tree
  fit <- suppressWarnings(drmTMB(
    coevo_formula(tree),
    family = biv_gaussian(),
    data = fx$data,
    control = drm_control(se = FALSE, keep_tmb_object = TRUE)
  ))

  rc <- coevolution_cor(fit)
  R <- rc$cor
  expect_identical(rc$axes, coevo_axes)
  expect_identical(dim(R), c(4L, 4L))
  expect_identical(R, t(R)) # symmetric (exact after the (R + R')/2 step)
  expect_true(all(is.finite(R)))
  expect_identical(unname(diag(R)), rep(1, 4L)) # exact unit diagonal
  expect_true(all(abs(R) <= 1 + 1e-8)) # valid correlations
  expect_gt(min(eigen(R, symmetric = TRUE, only.values = TRUE)$values), 0) # PD

  vc <- coevolution_vc(fit)
  expect_true(all(is.finite(vc$variance)) && all(vc$variance > 0))
  expect_equal(unname(vc$sd), sqrt(unname(vc$variance)))
  # Sigma_a = D R D from the fit's public state ...
  sd_labels <- paste0(coevo_axes, ":phylo(1 | p | species)")
  expect_equal(unname(vc$sd), unname(fit$sdpars$mu[sd_labels]), tolerance = 1e-12)
  expect_equal(R["mu1", "mu2"], unname(fit$corpars$phylo[[1L]]), tolerance = 1e-12)
  expect_equal(R["sigma1", "sigma2"], unname(fit$corpars$phylo[[6L]]), tolerance = 1e-12)
  # ... and equals the covariance the C++ objective reports.
  reported <- fit$obj$report()$phylo_q4_covariance
  expect_equal(unname(vc$cov), reported, tolerance = 1e-10)
  expect_equal(unname(R), stats::cov2cor(reported), tolerance = 1e-10)
  # corpairs() lists the same six correlations one row each.
  pairs <- corpairs(fit, level = "phylogenetic")
  expect_equal(nrow(pairs), 6L)
  expect_equal(pairs$estimate, unname(coevolution_summary(fit)$correlation), tolerance = 1e-12)

  s <- coevolution_summary(fit)
  expect_length(s$pair[, "from"], 6L)
  expect_length(s$correlation, 6L)
  expect_length(s$covariance, 6L)
  expect_equal(unname(s$sd), sqrt(unname(s$variance)))
  for (k in seq_len(6L)) {
    a <- s$pair[k, "from"]
    b <- s$pair[k, "to"]
    expect_equal(unname(s$correlation[[k]]), s$cor[a, b])
    expect_equal(unname(s$covariance[[k]]), s$cov[a, b])
  }
  expect_equal(s$cov, vc$cov)
})

test_that("native block-diagonal q = 4 phylo fit: cross-block correlations are exactly zero", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- coevo_native_data()
  tree <- fx$tree
  # Two labelled 2 x 2 blocks (p on the means, q on the log-scales): drmTMB's
  # block-diagonal q = 4 shape, which DRM.jl does not fit. The accessors report
  # the stored covariance as is: the four cross-block cells are zero.
  fit <- suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
      sigma1 = ~ 1 + phylo(1 | q | species, tree = tree),
      sigma2 = ~ 1 + phylo(1 | q | species, tree = tree),
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = fx$data,
    control = drm_control(se = FALSE, keep_tmb_object = TRUE)
  ))
  expect_true(drmTMB:::phylo_mu_is_block_diagonal(fit$model$structured$phylo_mu))
  s <- coevolution_summary(fit)
  expect_identical(unname(s$correlation[c("mu1:sigma1", "mu1:sigma2", "mu2:sigma1", "mu2:sigma2")]), rep(0, 4L))
  expect_equal(unname(s$correlation[["mu1:mu2"]]), unname(fit$corpars$phylo[[1L]]), tolerance = 1e-12)
  expect_equal(unname(s$correlation[["sigma1:sigma2"]]), unname(fit$corpars$phylo[[2L]]), tolerance = 1e-12)
  expect_equal(unname(s$cov), fit$obj$report()$phylo_q4_covariance, tolerance = 1e-10)
})

test_that("native animal() q = 4 fit: a non-phylo structured marker reads the same Sigma_a slot", {
  skip_on_cran()
  # Known precision matrix Q = K^-1 over 12 ids (AR(1)-like relatedness), the
  # shape test-animal-relmat-gaussian.R fits; the accessors must read
  # `animal()` blocks through the same phylo_mu slot as `phylo()` blocks.
  set.seed(20260905)
  n_id <- 12L
  n_each <- 6L
  ids <- paste0("id", seq_len(n_id))
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.32^abs(i - j))
  diag(K) <- diag(K) + 0.12
  dimnames(K) <- list(ids, ids)
  Q <- solve(K)
  sds <- c(0.5, 0.4, 0.2, 0.2)
  Cor <- diag(4L)
  Cor[1, 2] <- Cor[2, 1] <- 0.4
  Cor[3, 4] <- Cor[4, 3] <- 0.3
  A <- t(chol(K)) %*% matrix(stats::rnorm(n_id * 4L), n_id, 4L) %*%
    chol(diag(sds) %*% Cor %*% diag(sds))
  id <- rep(ids, each = n_each)
  x <- stats::rnorm(n_id * n_each)
  dat <- data.frame(
    id = id, x = x,
    y1 = stats::rnorm(length(id), 0.2 + 0.3 * x + A[id, 1], exp(-1 + A[id, 3])),
    y2 = stats::rnorm(length(id), -0.1 - 0.2 * x + A[id, 2], exp(-1.1 + A[id, 4])),
    stringsAsFactors = FALSE
  )
  fit <- suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ x + animal(1 | p | id, Ainv = Q),
      mu2 = y2 ~ x + animal(1 | p | id, Ainv = Q),
      sigma1 = ~ 1 + animal(1 | p | id, Ainv = Q),
      sigma2 = ~ 1 + animal(1 | p | id, Ainv = Q),
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(se = FALSE, keep_tmb_object = TRUE)
  ))
  rc <- coevolution_cor(fit)
  vc <- coevolution_vc(fit)
  s <- coevolution_summary(fit)
  expect_identical(rc$axes, coevo_axes)
  expect_identical(dimnames(rc$cor), list(coevo_axes, coevo_axes))
  expect_identical(unname(diag(rc$cor)), rep(1, 4L))
  expect_true(all(is.finite(vc$variance)) && all(vc$variance > 0))
  sd_labels <- paste0(coevo_axes, ":animal(1 | p | id)")
  expect_equal(unname(vc$sd), unname(fit$sdpars$mu[sd_labels]), tolerance = 1e-12)
  expect_equal(unname(vc$cov), fit$obj$report()$phylo_q4_covariance, tolerance = 1e-10)
  pairs <- corpairs(fit, level = "animal")
  expect_equal(nrow(pairs), 6L)
  expect_equal(pairs$estimate, unname(s$correlation), tolerance = 1e-12)
})

test_that("guard: the accessors refuse fits that store no 4 x 4 Sigma_a (DRM.jl test_coevo_accessors.jl)", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- coevo_native_data()
  dat <- fx$data
  tree <- fx$tree

  # DRM.jl's own case: a plain bivariate residual-correlation fit (no phylo
  # marker) has no Sigma_a.
  rfit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  expect_error(coevolution_cor(rfit), "no 4 x 4 among-axis covariance")
  expect_error(coevolution_vc(rfit), "no 4 x 4 among-axis covariance")
  expect_error(coevolution_summary(rfit), "no 4 x 4 among-axis covariance")

  # A univariate fit.
  ufit <- drmTMB(bf(y1 ~ x, sigma ~ 1), data = dat, control = drm_control(se = FALSE))
  expect_error(coevolution_cor(ufit), "no 4 x 4 among-axis covariance")

  # A q = 2 phylo block on the two means only: structured, but not q = 4.
  q2fit <- suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
      sigma1 = ~1, sigma2 = ~1, rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  ))
  expect_error(coevolution_cor(q2fit), "q = 2 axes, not 4")

  # Not a fit at all.
  expect_error(coevolution_cor(list()), "must be a")
})

# --- Tier 3: live same-target parity vs DRM.jl's native accessors ---------------

coevo_live_path <- function() {
  drm_test_drmjl_path("DRM_JL_PATH")
}

# In a fresh subprocess (one persistent Julia per R process): fit the fixture
# through engine = "julia" and engine = "tmb", then compute DRM.jl's OWN
# `coevolution_cor` / `coevolution_vc` / `coevolution_summary` natively in
# Julia on a native DRM.jl refit from the SAME bridge payload (formula, data,
# tree, options) the julia fit used -- the oracle. Returns the three readings.
coevo_live_run <- function(fixture) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- coevo_live_path()
  callr::r(
    function(pkg, jl_path, fixture) {
      julia_home <- Sys.getenv("DRM_JL_JULIA_HOME", Sys.getenv("JULIA_HOME", ""))
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      if (identical(fixture, "pinned_q4_reml")) {
        # The committed q4 fixture in the pinned DRM.jl checkout (non-unit
        # tree height 0.98229, so the julia-scale conversion is exercised).
        dir <- file.path(jl_path, "test/parity/q4-reml/biv-q4-phylo-reml")
        dat <- utils::read.csv(file.path(dir, "data.csv"), stringsAsFactors = FALSE)
        tree <- ape::read.tree(file.path(dir, "tree.newick"))
        dat$species <- factor(dat$species, levels = tree$tip.label)
        reml <- TRUE
      } else {
        # Seeded in-test fixture on a unit-height coalescent tree: 30 species
        # x 3 replicates, true mean-mean coevolution correlation 0.6.
        set.seed(42)
        N <- 30L
        m <- 3L
        tree <- ape::rcoal(N)
        tree$edge.length <- tree$edge.length / max(ape::node.depth.edgelength(tree))
        C <- ape::vcv(tree, corr = TRUE)
        Sa <- diag(c(0.8, 0.7, 0.3, 0.3))
        Cor <- diag(4)
        Cor[1, 2] <- Cor[2, 1] <- 0.6
        A <- t(chol(C)) %*% matrix(stats::rnorm(N * 4), N, 4) %*% chol(Sa %*% Cor %*% Sa)
        rows <- rep(seq_len(N), each = m)
        x <- stats::rnorm(N * m)
        dat <- data.frame(
          species = tree$tip.label[rows],
          x = x,
          y1 = stats::rnorm(N * m, 2 + 0.5 * x + A[rows, 1], exp(log(0.5) + A[rows, 3])),
          y2 = stats::rnorm(N * m, -1 + 0.3 * x + A[rows, 2], exp(log(0.6) + A[rows, 4])),
          stringsAsFactors = FALSE
        )
        reml <- FALSE
      }
      form <- drmTMB::bf(
        mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
        sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
        sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
        rho12 = ~1
      )

      fj <- drmTMB::drmTMB(form, family = drmTMB::biv_gaussian(), data = dat,
        engine = "julia", REML = reml)
      ft <- suppressWarnings(drmTMB::drmTMB(form, family = drmTMB::biv_gaussian(),
        data = dat, engine = "tmb", REML = reml,
        control = drmTMB::drm_control(se = FALSE,
          optimizer = list(eval.max = 2000, iter.max = 2000))))

      # --- the oracle: DRM.jl's native accessors on a native DRM.jl fit ------
      drmTMB:::drm_julia_setup()
      JuliaCall::julia_command(paste(sep = "\n",
        "function drmTMB_test_coevo_oracle(formula, family, data, tree, options)",
        "    dat = DRM._bridge_data(data)",
        "    bundle, dat = DRM._bridge_formula(formula, family, dat)",
        "    fam = DRM._bridge_family(family)",
        "    opts = DRM._bridge_options(options)",
        "    tree_obj = tree === nothing ? nothing : DRM._bridge_tree(tree)",
        "    fit = DRM._bridge_fit(bundle, fam, dat; tree = tree_obj, K = nothing, A = nothing, coords = nothing, options = opts)",
        "    rc = DRM.coevolution_cor(fit)",
        "    vc = DRM.coevolution_vc(fit)",
        "    s = DRM.coevolution_summary(fit)",
        "    Dict{String,Any}(",
        "        \"axes\" => String[String(a) for a in rc.axes],",
        "        \"cor\" => rc.cor,",
        "        \"cov\" => vc.cov,",
        "        \"variance\" => Float64[vc.variance[a] for a in rc.axes],",
        "        \"sd\" => Float64[vc.sd[a] for a in rc.axes],",
        "        \"pair_from\" => String[String(p[1]) for p in s.pair],",
        "        \"pair_to\" => String[String(p[2]) for p in s.pair],",
        "        \"correlation\" => s.correlation,",
        "        \"covariance\" => s.covariance,",
        "        \"summary_cor\" => s.cor,",
        "        \"summary_cov\" => s.cov,",
        "        \"estim_method\" => String(fit.estim_method),",
        "    )",
        "end"
      ))
      payload <- fj$bridge_payload
      oracle <- JuliaCall::julia_call(
        "drmTMB_test_coevo_oracle",
        payload$formula,
        "biv_gaussian",
        as.list(payload$data),
        payload$tree,
        if (length(payload$options) == 0L) NULL else payload$options
      )
      height <- max(ape::node.depth.edgelength(tree))

      r_julia <- list(cor = drmTMB::coevolution_cor(fj), vc = drmTMB::coevolution_vc(fj),
        summary = drmTMB::coevolution_summary(fj))
      r_tmb <- list(cor = drmTMB::coevolution_cor(ft), vc = drmTMB::coevolution_vc(ft),
        summary = drmTMB::coevolution_summary(ft))
      list(
        fixture = fixture,
        height = height,
        oracle = oracle,
        export_cor = fj$bridge$q4_point_export$correlation,
        export_axes = fj$bridge$q4_point_export$axes,
        r_julia = r_julia,
        r_tmb = r_tmb,
        julia_converged = drmTMB::is_converged(fj),
        tmb_convergence = ft$opt$convergence,
        tmb_max_gradient = max(abs(ft$gradient)),
        loglik_julia = as.numeric(stats::logLik(fj)),
        loglik_tmb = as.numeric(stats::logLik(ft))
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, fixture = fixture),
    error = "error"
  )
}

coevo_live_expectations <- function(res) {
  o <- res$oracle
  h <- res$height
  ax <- coevo_axes
  expect_identical(o$axes, ax)
  expect_identical(o$pair_from, c("mu1", "mu1", "mu1", "mu2", "mu2", "sigma1"))
  expect_identical(o$pair_to, c("mu2", "sigma1", "sigma2", "sigma1", "sigma2", "sigma2"))

  # (a) R port on the engine = "julia" fit vs DRM.jl's native accessors on the
  #     same payload: the ledger's 1e-6 correlation bar; covariances compare on
  #     the unit-height convention (DRM.jl raw-scale cov x tree height).
  rj <- res$r_julia
  expect_identical(rj$cor$axes, ax)
  expect_lt(max(abs(unname(rj$cor$cor) - o$cor)), 1e-6)
  expect_lt(max(abs(unname(rj$vc$cov) - o$cov * h)), 1e-6)
  expect_lt(max(abs(unname(rj$vc$variance) - o$variance * h)), 1e-6)
  expect_lt(max(abs(unname(rj$vc$sd) - o$sd * sqrt(h))), 1e-6)
  expect_identical(unname(rj$summary$pair[, "from"]), o$pair_from)
  expect_identical(unname(rj$summary$pair[, "to"]), o$pair_to)
  expect_lt(max(abs(unname(rj$summary$correlation) - o$correlation)), 1e-6)
  expect_lt(max(abs(unname(rj$summary$covariance) - o$covariance * h)), 1e-6)
  expect_lt(max(abs(unname(rj$summary$cor) - o$summary_cor)), 1e-6)
  # and vs DRM.jl's direct q4 point export carried on the bridge fit
  expect_identical(res$export_axes, ax)
  expect_lt(max(abs(unname(rj$cor$cor) - res$export_cor)), 1e-10)

  # (b) R port on the NATIVE engine fit vs the same oracle: a different
  #     optimiser on a flat q = 4 likelihood, so agreement is at optimiser
  #     tolerance, not accessor precision. MEASURED 2026-09-05 at DRM.jl
  #     430ef64cc (see the after-task report for the verbatim numbers); the
  #     bounds below carry headroom over what was observed and say only that
  #     both engines read the same among-axis structure off the same data.
  rt <- res$r_tmb
  expect_identical(rt$cor$axes, ax)
  expect_lt(max(abs(unname(rt$cor$cor) - o$cor)), 0.05)
  expect_lt(max(abs(unname(rt$vc$sd) - o$sd * sqrt(h))), 0.05)
  expect_lt(max(abs(unname(rt$cor$cor) - unname(rj$cor$cor))), 0.05)
}

test_that("live: coevolution accessors match DRM.jl's native accessors on the pinned q4 REML fixture", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(dir.exists(coevo_live_path()), "DRM.jl q4 engine not available")

  res <- coevo_live_run("pinned_q4_reml")
  expect_true(isTRUE(res$julia_converged))
  expect_identical(res$oracle$estim_method, "REML")
  expect_gt(abs(res$height - 1), 1e-3) # the scale conversion is exercised
  coevo_live_expectations(res)
})

test_that("live: coevolution accessors match DRM.jl's native accessors on the seeded unit-height fixture", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(dir.exists(coevo_live_path()), "DRM.jl q4 engine not available")

  res <- coevo_live_run("seeded_unit_height")
  expect_true(isTRUE(res$julia_converged))
  expect_identical(res$oracle$estim_method, "ML")
  expect_equal(res$height, 1, tolerance = 1e-12)
  coevo_live_expectations(res)
  # the headline coevolution-of-means correlation is in the right ballpark of
  # the true 0.6 on both engines (single-fit point estimate, generous band)
  expect_gt(res$r_julia$cor$cor["mu1", "mu2"], 0.2)
  expect_gt(res$r_tmb$cor$cor["mu1", "mu2"], 0.2)
})
