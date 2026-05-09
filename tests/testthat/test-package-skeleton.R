test_that("package metadata is available", {
  expect_equal(utils::packageDescription("drmTMB")$Package, "drmTMB")
})

test_that("drm_formula() captures distributional formulas", {
  form <- drm_formula(
    mu1 = y1 ~ x1 + (1 | p | id),
    mu2 = y2 ~ x2 + (1 | p | id),
    sigma1 = ~ x1,
    sigma2 = ~ x2,
    rho12 = ~ x1 + x2
  )

  expect_s3_class(form, "drm_formula")
  expect_equal(names(form$calls), c("mu1", "mu2", "sigma1", "sigma2", "rho12"))
  expect_equal(vapply(form$entries, `[[`, character(1), "dpar"), names(form$calls))
  expect_equal(vapply(form$entries[1:2], `[[`, character(1), "response"), c("y1", "y2"))
  expect_equal(form$entries[[5]]$dpar, "rho12")
})

test_that("drm_formula() captures mvbind shorthand as a location formula", {
  form <- drm_formula(
    mvbind(y1, y2) ~ x1 + x2,
    sigma1 = ~ x1,
    sigma2 = ~ x2,
    rho12 = ~ x1 + x2
  )

  expect_s3_class(form, "drm_formula")
  expect_equal(form$entries[[1]]$dpar, "mu")
  expect_equal(form$entries[[1]]$response, "mvbind(y1, y2)")
  expect_true(drmTMB:::is_mvbind_lhs(form$entries[[1]]$lhs))
})

test_that("bf() remains a short alias for drm_formula()", {
  form <- bf(y ~ x, sigma ~ z)

  expect_s3_class(form, "drm_formula")
  expect_length(form$calls, 2)
  expect_equal(vapply(form$entries, `[[`, character(1), "dpar"), c("mu", "sigma"))
})

test_that("internal TMB data routing rejects unknown model labels", {
  expect_error(
    drmTMB:::make_tmb_data(list(model_type = "broken")),
    "unknown .*drmTMB.* model type"
  )
})

test_that("drm_formula() captures meta-analysis and random-effect scale syntax", {
  form <- drm_formula(
    yi ~ moderator + meta_known_V(V = vi),
    sigma ~ moderator,
    sd(study) ~ moderator,
    sd(species) ~ habitat
  )

  expect_s3_class(form, "drm_formula")
  expect_length(form$calls, 4)
  expect_equal(
    vapply(form$entries, `[[`, character(1), "dpar"),
    c("mu", "sigma", "sd(study)", "sd(species)")
  )
  expect_equal(form$entries[[1]]$response, "yi")
  expect_match(deparse1(form$calls[[1]]), "meta_known_V\\(V = vi\\)")
  expect_match(deparse1(form$calls[[3]]), "sd\\(study\\)")
  expect_match(deparse1(form$calls[[4]]), "sd\\(species\\)")
})

test_that("drm_formula() captures planned structured-effect syntax", {
  form <- drm_formula(
    y ~ x + phylo(1 | species, tree = tree) +
      spatial(1 | site, coords = coords)
  )

  expect_s3_class(form, "drm_formula")
  expect_equal(form$entries[[1]]$dpar, "mu")
  expect_length(form$entries[[1]]$structured, 2)
  expect_equal(
    form$entries[[1]]$structured[[1]][c("type", "group", "tree")],
    list(type = "phylo", group = "species", tree = "tree")
  )
  expect_equal(
    form$entries[[1]]$structured[[2]][c("type", "group", "structure", "object")],
    list(type = "spatial", group = "site", structure = "coords", object = "coords")
  )

  mesh_form <- drm_formula(y ~ spatial(1 | site, mesh = mesh))
  expect_equal(
    mesh_form$entries[[1]]$structured[[1]][c("type", "group", "structure", "object")],
    list(type = "spatial", group = "site", structure = "mesh", object = "mesh")
  )

  slope_form <- drm_formula(y ~ phylo(1 + depth | species, tree = tree))
  expect_equal(slope_form$entries[[1]]$structured[[1]]$coef_names, c("(Intercept)", "depth"))
  expect_equal(slope_form$entries[[1]]$structured[[1]]$variables, "depth")
})

test_that("formula markers are no-op placeholders", {
  expect_null(meta_known_V(V = 1))
  expect_null(gr(id, cov = diag(1)))
  expect_null(phylo(1 | species, tree = tree))
  expect_null(spatial(1 | site, coords = coords))
  expect_null(spatial(1 | site, mesh = mesh))
})

test_that("planned structured-effect markers validate their grammar", {
  expect_error(
    drm_formula(y ~ x + phylo(species)),
    "random-effect syntax"
  )
  expect_error(
    drm_formula(y ~ x + phylo(1 | species)),
    "tree"
  )
  expect_error(
    drm_formula(y ~ x + phylo(1 + x + z | species, tree = tree)),
    "one-slope structured terms"
  )
  expect_error(
    drm_formula(y ~ x + spatial(1 | site)),
    "coords.*mesh"
  )
  expect_error(
    drm_formula(y ~ x + spatial(1 | site, coords = coords, mesh = mesh)),
    "coords.*mesh"
  )
  expect_error(
    drm_formula(y ~ x + log(phylo(1 | species, tree = tree))),
    "additive formula terms"
  )
})
