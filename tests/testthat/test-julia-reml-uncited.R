# The three REML capabilities the parity scoreboard reported UNCITED on its
# bridge axis (leaf `uncited-reml`, 2026-09-05). Receipt with every number:
# docs/dev-log/evidence/julia-r-parity/reml-uncited/receipt.md.
#
# WHAT THESE TESTS PROTECT. The scoreboard's bridge axis joins
#   capability name -> matrix bridge_route -> inst/extdata/julia-capabilities.tsv
#   line -> capability_id -> a receipt row in DRM.jl's evidence tables.
# Every link is a string, and a renamed capability_id silently re-UNCITEs the
# cell without any test noticing -- the join would simply find nothing, which
# is indistinguishable from "no evidence was ever taken". The ledger tests
# below need no Julia and pin the two ids the matrix generator cites.
#
# The live tests re-take the receipt itself. They are skipped, never failed,
# when no DRM.jl engine is available.

test_that("the two REML ledger rows exist, under the ids the matrix cites", {
  caps <- drmTMB:::drm_julia_capability_comparison()
  reml_rows <- caps[caps$route == "reml", , drop = FALSE]

  expect_setequal(
    reml_rows$capability_id,
    c("gaussian_reml_location_scale", "gaussian_reml_random_intercept_mu")
  )
  # route MUST NOT be "base". tools/write-parity-matrix.R's family matcher
  # absorbs every route == "base" row whose `syntax` calls a family
  # constructor and carries no `|` term -- which is exactly the shape of the
  # fixed-effect REML row. Were it "base", the ML capability
  # `Gaussian location-scale (ML)` would silently claim this REML receipt.
  expect_false(any(reml_rows$route == "base"))
  expect_true(all(grepl("REML = TRUE", reml_rows$syntax, fixed = TRUE)))
  expect_true(all(nzchar(reml_rows$claim_boundary)))
  expect_true(all(nzchar(reml_rows$next_action)))
})

test_that("the committed capability TSV carries the two REML rows", {
  path <- system.file("extdata", "julia-capabilities.tsv", package = "drmTMB")
  skip_if(!nzchar(path) || !file.exists(path), "capability TSV not installed")
  tsv <- utils::read.delim(path, stringsAsFactors = FALSE, quote = "")
  expect_true(all(
    c("gaussian_reml_location_scale", "gaussian_reml_random_intercept_mu") %in%
      tsv$capability_id
  ))
  # The pre-existing bivariate row is the third cell's ledger anchor.
  expect_true("biv_q4_phylo_reml" %in% tsv$capability_id)
})

test_that("engine = \"julia\" REML matches engine = \"tmb\" on the two univariate cells", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")

  # ---- cell 1: fixed-effect Gaussian location-scale (n = 60, seed 1) -------
  set.seed(1)
  n <- 60
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  d1 <- data.frame(
    y = 0.5 + 0.8 * x + stats::rnorm(n, sd = exp(-0.3 + 0.25 * z)),
    x = x, z = z
  )
  f1 <- drmTMB::bf(y ~ x, sigma ~ z)
  t1 <- drmTMB::drmTMB(f1, family = gaussian(), data = d1, REML = TRUE, engine = "tmb")
  j1 <- drmTMB::drmTMB(f1, family = gaussian(), data = d1, REML = TRUE, engine = "julia")
  t1_ml <- drmTMB::drmTMB(f1, family = gaussian(), data = d1, REML = FALSE, engine = "tmb")
  j1_ml <- drmTMB::drmTMB(f1, family = gaussian(), data = d1, REML = FALSE, engine = "julia")

  # ESTIMATOR HONESTY, read off both objects rather than inferred from the
  # absence of an abort. The engine's own estim_method is the authority.
  expect_identical(t1$estimator, "REML")
  expect_identical(j1$estimator, "REML")
  expect_true(isTRUE(j1$effective_REML))
  expect_identical(as.character(j1$bridge$estim_method)[[1L]], "REML")
  expect_identical(as.character(j1_ml$bridge$estim_method)[[1L]], "ML")

  ll_t <- as.numeric(stats::logLik(t1))
  ll_j <- as.numeric(stats::logLik(j1))
  expect_equal(ll_t, ll_j, tolerance = 1e-8)
  # An ML fit relabelled REML would show a gap of ZERO. Measured: 2.8179 on
  # both engines. This assertion, not the estimator label, is what makes the
  # REML claim falsifiable.
  expect_gt(as.numeric(stats::logLik(t1_ml)) - ll_t, 1)
  expect_gt(as.numeric(stats::logLik(j1_ml)) - ll_j, 1)

  ct <- drm_reml_named_coef(t1)
  cj <- drm_reml_named_coef(j1)
  expect_identical(sort(names(ct)), sort(names(cj)))
  expect_lt(max(abs(ct[names(cj)] - cj)), 1e-6)

  # ---- cell 2: Gaussian mean ordinary random intercept (n = 150, seed 11) --
  set.seed(11)
  ng <- 15L
  nper <- 10L
  gg <- factor(rep(seq_len(ng), each = nper))
  u <- stats::rnorm(ng, sd = 0.7)
  x2 <- stats::rnorm(ng * nper)
  d2 <- data.frame(
    y = 0.4 + 0.9 * x2 + u[as.integer(gg)] + stats::rnorm(ng * nper, sd = 0.5),
    x = x2, g = gg
  )
  f2 <- drmTMB::bf(y ~ x + (1 | g), sigma ~ 1)
  t2 <- drmTMB::drmTMB(f2, family = gaussian(), data = d2, REML = TRUE, engine = "tmb")
  j2 <- drmTMB::drmTMB(f2, family = gaussian(), data = d2, REML = TRUE, engine = "julia")
  t2_ml <- drmTMB::drmTMB(f2, family = gaussian(), data = d2, REML = FALSE, engine = "tmb")

  expect_identical(j2$estimator, "REML")
  expect_identical(as.character(j2$bridge$estim_method)[[1L]], "REML")
  expect_equal(
    as.numeric(stats::logLik(t2)), as.numeric(stats::logLik(j2)),
    tolerance = 1e-8
  )
  expect_gt(as.numeric(stats::logLik(t2_ml)) - as.numeric(stats::logLik(t2)), 1)

  ct2 <- drm_reml_named_coef(t2)
  cj2 <- drm_reml_named_coef(j2)
  expect_identical(sort(names(ct2)), sort(names(cj2)))
  expect_lt(max(abs(ct2[names(cj2)] - cj2)), 1e-6)

  # SEs. Cell 2 agrees; cell 1's MEAN block does not, and the split is the
  # finding, not noise -- see the receipt's CONTROL A. Both bars are set from
  # the measured values with headroom, so either side moving fails loudly.
  s2t <- drm_reml_named_se(t2)
  s2j <- drm_reml_named_se(j2)
  expect_lt(max(abs(s2t[names(s2j)] - s2j) / abs(s2t[names(s2j)])), 1e-5)

  s1t <- drm_reml_named_se(t1)
  s1j <- drm_reml_named_se(j1)
  rel1 <- abs(s1t[names(s1j)] - s1j) / abs(s1t[names(s1j)])
  mean_block <- grepl("^mu_", names(rel1))
  expect_true(any(mean_block))
  expect_gt(max(rel1[mean_block]), 1e-3)   # documented, NOT fixed
  expect_lt(max(rel1[mean_block]), 5e-3)   # and it must not grow
  expect_lt(max(rel1[!mean_block]), 1e-5)  # the scale block DOES agree
})

test_that("engine = \"julia\" answers the DENSE q4 model for a BLOCK-DIAGONAL q4 call", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("ape")

  # THIS TEST PINS A DEFECT, deliberately. A block-diagonal q4 formula uses two
  # phylo labels (`p` on the means, `ps` on the scales) and therefore has no
  # mean-scale cross-covariance; the dense layout shares one label across all
  # four axes and does. engine = "tmb" fits what was written. The bridge fits
  # the DENSE model either way and reports the dense df.
  #
  # WHEN THIS IS FIXED, THIS TEST FAILS -- that is the point. Replace it with
  # an expect_error() on the block-diagonal call at that time.
  set.seed(3L)
  n_tip <- 100L
  n_each <- 5L
  nn <- n_tip * n_each
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  L <- t(chol(ape::vcv(tree, corr = TRUE)))
  Gl <- chol(matrix(c(.6^2, .4 * .6 * .5, .4 * .6 * .5, .5^2), 2, 2))
  Gs <- chol(matrix(c(.4^2, .3 * .4 * .3, .3 * .4 * .3, .3^2), 2, 2))
  Am <- L %*% matrix(stats::rnorm(n_tip * 2), n_tip, 2) %*% Gl
  As <- L %*% matrix(stats::rnorm(n_tip * 2), n_tip, 2) %*% Gs
  tip <- rep(seq_len(n_tip), each = n_each)
  dat <- data.frame(
    sp = factor(tree$tip.label[tip], levels = tree$tip.label),
    y1 = 0.3 + Am[tip, 1] + stats::rnorm(nn, 0, exp(log(.5) + As[tip, 1])),
    y2 = 0.7 + Am[tip, 2] + stats::rnorm(nn, 0, exp(log(.6) + As[tip, 2]))
  )
  block_diag <- drmTMB::bf(
    mu1 = y1 ~ 1 + phylo(1 | p | sp, tree = tree),
    mu2 = y2 ~ 1 + phylo(1 | p | sp, tree = tree),
    sigma1 = ~ 1 + phylo(1 | ps | sp, tree = tree),
    sigma2 = ~ 1 + phylo(1 | ps | sp, tree = tree),
    rho12 = ~ 1
  )
  dense <- drmTMB::bf(
    mu1 = y1 ~ 1 + phylo(1 | p | sp, tree = tree),
    mu2 = y2 ~ 1 + phylo(1 | p | sp, tree = tree),
    sigma1 = ~ 1 + phylo(1 | p | sp, tree = tree),
    sigma2 = ~ 1 + phylo(1 | p | sp, tree = tree),
    rho12 = ~ 1
  )
  ctrl <- drmTMB::drm_control(optimizer_preset = "robust")
  t_block <- suppressWarnings(drmTMB::drmTMB(
    block_diag, family = drmTMB::biv_gaussian(), data = dat, REML = TRUE,
    engine = "tmb", control = ctrl
  ))
  t_dense <- suppressWarnings(drmTMB::drmTMB(
    dense, family = drmTMB::biv_gaussian(), data = dat, REML = TRUE,
    engine = "tmb", control = ctrl
  ))
  j_block <- drmTMB::drmTMB(
    block_diag, family = drmTMB::biv_gaussian(), data = dat, REML = TRUE,
    engine = "julia"
  )
  j_dense <- drmTMB::drmTMB(
    dense, family = drmTMB::biv_gaussian(), data = dat, REML = TRUE,
    engine = "julia"
  )

  # Native distinguishes the two layouts: different df, different objective.
  expect_identical(attr(stats::logLik(t_block), "df"), 11L)
  expect_identical(attr(stats::logLik(t_dense), "df"), 15L)
  expect_gt(
    abs(as.numeric(stats::logLik(t_block)) - as.numeric(stats::logLik(t_dense))),
    1
  )

  # The bridge does not: the block-diagonal CALL lands on the dense answer.
  expect_identical(attr(stats::logLik(j_block), "df"), 15L)
  expect_equal(
    as.numeric(stats::logLik(j_block)), as.numeric(stats::logLik(j_dense)),
    tolerance = 1e-6
  )
  expect_gt(
    abs(as.numeric(stats::logLik(j_block)) - as.numeric(stats::logLik(t_block))),
    1
  )

  # The DENSE cell IS a receipt: same target, inside this row's own recorded
  # atol_loglik of 0.03 (DRM.jl #477), estimator REML on both sides.
  expect_identical(t_dense$estimator, "REML")
  expect_identical(j_dense$estimator, "REML")
  expect_identical(as.character(j_dense$bridge$estim_method)[[1L]], "REML")
  expect_identical(t_dense$opt$convergence, 0L)
  expect_lt(
    abs(as.numeric(stats::logLik(t_dense)) - as.numeric(stats::logLik(j_dense))),
    0.03
  )
  cd_t <- drm_reml_named_coef(t_dense)
  cd_j <- drm_reml_named_coef(j_dense)
  expect_identical(sort(names(cd_t)), sort(names(cd_j)))
  expect_lt(max(abs(cd_t[names(cd_j)] - cd_j)), 3e-3)
})
