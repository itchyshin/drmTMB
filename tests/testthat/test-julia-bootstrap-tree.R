test_that("non-Gaussian phylo fixed-effect bootstrap forwards the stored tree", {
  skip_if_not_installed("JuliaCall")

  object <- list(
    model = list(model_type = "gamma"),
    bridge_payload = list(
      formula = list(mu = "y ~ x + phylo(1 | species)"),
      data = data.frame(y = c(1, 2), x = c(0, 1), species = c("sp1", "sp2")),
      tree = "(sp1:1,sp2:1);",
      options = list(phylo_coupled = TRUE)
    )
  )
  target <- data.frame(dpar = "mu", term = "x")
  setup_calls <- 0L

  testthat::local_mocked_bindings(
    drm_julia_setup = function(...) setup_calls <<- setup_calls + 1L,
    .package = "drmTMB"
  )
  testthat::local_mocked_bindings(
    julia_call = function(...) list(...),
    .package = "JuliaCall"
  )

  sent <- drmTMB:::drm_julia_call_fixef_inference(
    object = object,
    target = target,
    method = "bootstrap",
    level = 0.9,
    R = 2L,
    seed = 4001L,
    threads = FALSE
  )

  expect_identical(setup_calls, 1L)
  expect_identical(sent[[5L]], object$bridge_payload$tree)
})

test_that("non-Gaussian coupled phylo options exclude the Gaussian-only flag", {
  gamma_payload <- list(
    bivariate = FALSE,
    family_type = "gamma",
    locscale_mode = "phylo_locscale"
  )
  gaussian_payload <- list(
    bivariate = FALSE,
    family_type = "gaussian",
    locscale_mode = "phylo_locscale"
  )

  expect_identical(
    drmTMB:::drm_julia_bridge_options(gamma_payload, method = "ML"),
    list(g_tol = 1e-8)
  )
  expect_identical(
    drmTMB:::drm_julia_bridge_options(gaussian_payload, method = "ML"),
    list(g_tol = 1e-6, phylo_coupled = TRUE)
  )
})

test_that("Gamma shared phylo labels serialize as coupled Julia terms", {
  skip_if_not_installed("ape")

  tree <- ape::read.tree(text = "((s1:0.8,s2:0.8):0.9,(s3:0.8,s4:0.8):0.9);")
  dat <- data.frame(
    y = c(1, 2, 3, 4),
    x = c(-1, -0.5, 0.5, 1),
    species = c("s1", "s2", "s3", "s4")
  )
  form <- drmTMB::bf(
    y ~ x + phylo(1 | tree_boot | species, tree = tree),
    sigma ~ 1 + phylo(1 | tree_boot | species, tree = tree)
  )

  payload <- drmTMB:::drm_julia_bridge_payload(
    form,
    family_type = "gamma",
    data = dat,
    env = environment()
  )

  expect_identical(
    payload$formula$mu,
    "y ~ x + (1 | tree_boot | phylo(species))"
  )
  expect_identical(
    payload$formula$sigma,
    "sigma ~ 1 + (1 | tree_boot | phylo(species))"
  )
  expect_identical(drm_test_options_sans_labels(payload$options), list(g_tol = 1e-8))
  expect_true(is.list(payload$options$coef_labels))
})

test_that("Gamma coupled phylo rejects mismatched labels without coalescing them", {
  skip_if_not_installed("ape")

  tree <- ape::read.tree(text = "((s1:0.8,s2:0.8):0.9,(s3:0.8,s4:0.8):0.9);")
  dat <- data.frame(
    y = c(1, 2, 3, 4),
    x = c(-1, -0.5, 0.5, 1),
    species = c("s1", "s2", "s3", "s4")
  )
  form <- drmTMB::bf(
    y ~ x + phylo(1 | mu_tree | species, tree = tree),
    sigma ~ 1 + phylo(1 | sigma_tree | species, tree = tree)
  )

  expect_error(
    drmTMB:::drm_julia_bridge_payload(
      form,
      family_type = "gamma",
      data = dat,
      env = environment()
    ),
    "matching covariance labels"
  )
})

test_that("Gamma coupled phylo gives matching untagged terms one internal tag", {
  skip_if_not_installed("ape")

  tree <- ape::read.tree(text = "((s1:0.8,s2:0.8):0.9,(s3:0.8,s4:0.8):0.9);")
  dat <- data.frame(
    y = c(1, 2, 3, 4),
    x = c(-1, -0.5, 0.5, 1),
    species = c("s1", "s2", "s3", "s4")
  )
  form <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1 + phylo(1 | species, tree = tree)
  )

  payload <- drmTMB:::drm_julia_bridge_payload(
    form,
    family_type = "gamma",
    data = dat,
    env = environment()
  )

  expect_identical(
    payload$formula$mu,
    "y ~ x + (1 | drmTMB_phylo_locscale | phylo(species))"
  )
  expect_identical(
    payload$formula$sigma,
    "sigma ~ 1 + (1 | drmTMB_phylo_locscale | phylo(species))"
  )
})

test_that("Gamma coupled phylo rejects a tag on only one axis", {
  skip_if_not_installed("ape")

  tree <- ape::read.tree(text = "((s1:0.8,s2:0.8):0.9,(s3:0.8,s4:0.8):0.9);")
  dat <- data.frame(
    y = c(1, 2, 3, 4),
    x = c(-1, -0.5, 0.5, 1),
    species = c("s1", "s2", "s3", "s4")
  )
  form <- drmTMB::bf(
    y ~ x + phylo(1 | tree_boot | species, tree = tree),
    sigma ~ 1 + phylo(1 | species, tree = tree)
  )

  expect_error(
    drmTMB:::drm_julia_bridge_payload(
      form,
      family_type = "gamma",
      data = dat,
      env = environment()
    ),
    "matching covariance labels"
  )
})

test_that("phylo payload cache keeps Gaussian and Gamma bridge routes separate", {
  skip_if_not_installed("ape")

  cache <- get("drm_julia_phylo_payload_cache", asNamespace("drmTMB"))
  rm(list = ls(cache, all.names = TRUE), envir = cache)
  on.exit(rm(list = ls(cache, all.names = TRUE), envir = cache), add = TRUE)

  tree <- ape::read.tree(text = "((s1:0.8,s2:0.8):0.9,(s3:0.8,s4:0.8):0.9);")
  dat <- data.frame(
    y = c(1, 2, 3, 4),
    x = c(-1, -0.5, 0.5, 1),
    species = c("s1", "s2", "s3", "s4")
  )
  form <- drmTMB::bf(
    y ~ x + phylo(1 | tree_boot | species, tree = tree),
    sigma ~ 1 + phylo(1 | tree_boot | species, tree = tree)
  )

  gaussian <- drmTMB:::drm_julia_bridge_payload(
    form,
    family_type = "gaussian",
    data = dat,
    env = environment()
  )
  gamma <- drmTMB:::drm_julia_bridge_payload(
    form,
    family_type = "gamma",
    data = dat,
    env = environment()
  )
  gaussian_again <- drmTMB:::drm_julia_bridge_payload(
    form,
    family_type = "gaussian",
    data = dat,
    env = environment()
  )

  expect_identical(drm_test_options_sans_labels(gaussian$options), list(g_tol = 1e-6, phylo_coupled = TRUE))
  expect_identical(drm_test_options_sans_labels(gamma$options), list(g_tol = 1e-8))
  expect_identical(
    gamma$formula$mu,
    "y ~ x + (1 | tree_boot | phylo(species))"
  )
  expect_identical(
    drm_test_options_sans_labels(gaussian_again$options),
    list(g_tol = 1e-6, phylo_coupled = TRUE)
  )
  expect_identical(gaussian_again$formula$mu, "y ~ x + phylo(1 | species)")
})
