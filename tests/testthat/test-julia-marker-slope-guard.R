# drmTMB#1146 / DRM.jl#620/#621: a structured marker (phylo/relmat/animal/
# spatial) written with a NON-INTERCEPT left side of the bar --
# `phylo(1 + x | g)`, `phylo(0 + x | g)`, and the same shapes on the other
# three markers -- must be refused before routing through `engine = "julia"`,
# not silently mis-fitted and not merely refused after Julia boots.
#
# CAPABILITY-GATED (drm_julia_marker_slope_pin_supports()), currently FALSE:
# at the pin (430ef64cc, carrying DRM.jl#621) the engine cannot fit ANY of
# these constructs, so every one is refused. When a future pin implements one
# (DRM.jl#620's S8 follow-up, Gaussian two-SD phylogenetic random slope), the
# fix is a one-row registry change to that switch, not a rewrite of this test
# file or the guard.
#
# All assertions here run with NO Julia install and NO DRM.jl checkout: the
# guard is a pure-R pre-Julia check.

test_that("phylo() with a non-intercept lhs is refused before engine = \"julia\"", {
  set.seed(1)
  tr <- ape::rcoal(6)
  dat <- data.frame(
    species = tr$tip.label,
    x = stats::rnorm(6),
    y = stats::rnorm(6)
  )

  expect_error(
    drmTMB(
      bf(y ~ x + phylo(1 + x | species, tree = tr), sigma ~ 1),
      family = stats::gaussian(),
      data = dat,
      engine = "julia"
    ),
    "cannot fit a random slope"
  )
  err <- tryCatch(
    drmTMB(
      bf(y ~ x + phylo(1 + x | species, tree = tr), sigma ~ 1),
      family = stats::gaussian(),
      data = dat,
      engine = "julia"
    ),
    error = function(e) e
  )
  msg <- conditionMessage(err)
  expect_match(msg, "phylo", fixed = TRUE)
  expect_match(msg, "1 \\+ x \\| species", perl = TRUE)
  expect_match(msg, "engine = \"tmb\"", fixed = TRUE)
  expect_match(msg, "DRM.jl#620", fixed = TRUE)
})

test_that("relmat() with a non-intercept lhs is refused before engine = \"julia\"", {
  dat <- data.frame(
    id = factor(rep(c("a", "b", "c"), each = 2)),
    x = stats::rnorm(6),
    y = stats::rnorm(6)
  )
  K <- diag(3)
  rownames(K) <- colnames(K) <- levels(dat$id)

  err <- tryCatch(
    drmTMB(
      bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1),
      data = dat,
      engine = "julia"
    ),
    error = function(e) e
  )
  expect_s3_class(err, "error")
  msg <- conditionMessage(err)
  expect_match(msg, "cannot fit a random slope")
  expect_match(msg, "relmat", fixed = TRUE)
  expect_match(msg, "engine = \"tmb\"", fixed = TRUE)
})

test_that("a zero-intercept structured slope (0 + x) is refused the same way", {
  set.seed(1)
  tr <- ape::rcoal(6)
  dat <- data.frame(
    species = tr$tip.label,
    x = stats::rnorm(6),
    y = stats::rnorm(6)
  )

  err <- tryCatch(
    drmTMB(
      bf(y ~ x + phylo(0 + x | species, tree = tr), sigma ~ 1),
      family = stats::gaussian(),
      data = dat,
      engine = "julia"
    ),
    error = function(e) e
  )
  expect_s3_class(err, "error")
  expect_match(conditionMessage(err), "cannot fit a random slope")
})

test_that("intercept-only structured markers are NOT caught by the slope guard", {
  set.seed(1)
  tr <- ape::rcoal(6)
  dat_phylo <- data.frame(
    species = tr$tip.label,
    x = stats::rnorm(6),
    y = stats::rnorm(6)
  )
  expect_false(isTRUE(
    tryCatch(
      {
        drmTMB:::drm_julia_refuse_marker_slope_unsupported(
          bf(y ~ x + phylo(1 | species, tree = tr), sigma ~ 1)
        )
        FALSE
      },
      error = function(e) TRUE
    )
  ))

  dat_relmat <- data.frame(
    id = factor(rep(c("a", "b", "c"), each = 2)),
    x = stats::rnorm(6),
    y = stats::rnorm(6)
  )
  K <- diag(3)
  rownames(K) <- colnames(K) <- levels(dat_relmat$id)
  expect_false(isTRUE(
    tryCatch(
      {
        drmTMB:::drm_julia_refuse_marker_slope_unsupported(
          bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1)
        )
        FALSE
      },
      error = function(e) TRUE
    )
  ))
})

test_that("engine = \"tmb\" keeps fitting the two-SD Gaussian phylogenetic random slope", {
  set.seed(7)
  n_tip <- 40L
  tree <- ape::rcoal(n_tip)
  sp <- tree$tip.label
  x <- stats::rnorm(n_tip)
  bm <- ape::rTraitCont(tree, model = "BM", sigma = 0.6)
  eta <- 0.4 + 0.3 * x + bm[sp]
  y <- stats::rnorm(n_tip, eta, 0.3)
  dat <- data.frame(species = sp, x = x, y = y)

  fit <- drmTMB(
    bf(y ~ x + phylo(1 + x | species, tree = tree), sigma ~ 1),
    family = stats::gaussian(),
    data = dat,
    engine = "tmb"
  )
  s <- summary(fit)
  # Two INDEPENDENT structured-slope SDs (intercept, slope) are estimated --
  # not a discarded slope and not a single collapsed intercept-only SD. This
  # is exactly the model `engine = "julia"` refuses at the current pin.
  sd_terms <- s$parameters$term[s$parameters$component == "random-effect-sd"]
  expect_true("phylo(1 | species)" %in% sd_terms)
  expect_true("phylo(0 + x | species)" %in% sd_terms)
  expect_true(is.finite(as.numeric(stats::logLik(fit))))
})

test_that("Julia marker-slope gate registry row exists and is intentional", {
  gates <- drmTMB:::drm_julia_intentional_gates()
  expect_true("structured_marker_slope" %in% gates$gate_id)
  row <- gates[match("structured_marker_slope", gates$gate_id), ]
  expect_equal(row$r_bridge_status, "intentional_error")
  expect_equal(row$action, "error")
  expect_match(row$message_pattern, "cannot fit a random slope")
})

test_that("RED CONTROL: removing the guard call lets the marker-slope formula reach further", {
  # This does not remove the guard (nothing here is allowed to edit
  # R/julia-bridge.R for real); it instead directly probes that the guard
  # function is in fact what stops the call, by calling the lower-level
  # collector the guard is built on and confirming it identifies the exact
  # term the guard would act on. If a future edit stopped populating
  # `term$coef_names`/`term$variables` for a slope term, this assertion would
  # fail, which is the point: it pins the guard's own data contract.
  set.seed(1)
  tr <- ape::rcoal(6)
  f <- bf(y ~ x + phylo(1 + x | species, tree = tr), sigma ~ 1)
  terms <- drmTMB:::drm_julia_collect_marker_slope_terms(f)
  expect_length(terms, 1L)
  expect_identical(terms[[1L]]$type, "phylo")
  expect_identical(terms[[1L]]$group, "species")
  expect_false(identical(terms[[1L]]$coef_names, "(Intercept)"))
})
