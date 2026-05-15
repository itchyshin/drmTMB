test_that("package metadata is available", {
  expect_equal(utils::packageDescription("drmTMB")$Package, "drmTMB")
})

test_that("drm_formula() captures distributional formulas", {
  form <- drm_formula(
    mu1 = y1 ~ x1 + (1 | p | id),
    mu2 = y2 ~ x2 + (1 | p | id),
    sigma1 = ~x1,
    sigma2 = ~x2,
    rho12 = ~ x1 + x2
  )

  expect_s3_class(form, "drm_formula")
  expect_equal(names(form$calls), c("mu1", "mu2", "sigma1", "sigma2", "rho12"))
  expect_equal(
    vapply(form$entries, `[[`, character(1), "dpar"),
    names(form$calls)
  )
  expect_equal(
    vapply(form$entries[1:2], `[[`, character(1), "response"),
    c("y1", "y2")
  )
  expect_equal(form$entries[[5]]$dpar, "rho12")
})

test_that("drm_formula() captures mvbind shorthand as a location formula", {
  form <- drm_formula(
    mvbind(y1, y2) ~ x1 + x2,
    sigma1 = ~x1,
    sigma2 = ~x2,
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
  expect_equal(
    vapply(form$entries, `[[`, character(1), "dpar"),
    c("mu", "sigma")
  )
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

test_that("drm_formula() reserves explicit random-effect scale targets", {
  form <- drm_formula(
    y ~ x + (1 + x | id),
    sd(id, dpar = "mu", coef = "x", block = "p") ~ z
  )

  entry <- form$entries[[2L]]
  expect_equal(
    entry$dpar,
    'sd(id, dpar = "mu", coef = "x", block = "p")'
  )
  target <- drmTMB:::parse_sd_lhs(entry$lhs)
  expect_equal(target$group, "id")
  expect_equal(target$target_dpar, "mu")
  expect_equal(target$target_coef, "x")
  expect_equal(target$target_block, "p")
  expect_equal(target$explicit, TRUE)

  expect_error(
    drm_formula(sd(id, dpar = "sigma") ~ z),
    "reserved for location"
  )
  expect_error(
    drm_formula(sd1(id, dpar = "mu1") ~ z),
    "does not accept explicit target"
  )
})

test_that("drm_formula() captures planned corpair formula syntax", {
  form <- drm_formula(
    mu1 = y1 ~ x + (1 | p | id),
    mu2 = y2 ~ x + (1 | p | id),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1,
    corpair(id, block = "p", from = "mu1", to = "sigma2") ~ z
  )

  entry <- form$entries[[6L]]
  expect_s3_class(form, "drm_formula")
  expect_equal(
    entry$dpar,
    'corpair(id, block = "p", from = "mu1", to = "sigma2")'
  )
  expect_equal(
    entry$corpair[c("group", "block", "from", "to")],
    list(group = "id", block = "p", from = "mu1", to = "sigma2")
  )

  phylo_form <- drm_formula(
    corpair(
      species,
      level = "phylogenetic",
      block = "p",
      from = "mu1",
      to = "mu2"
    ) ~ ecology
  )
  phylo_entry <- phylo_form$entries[[1L]]
  expect_equal(
    phylo_entry$dpar,
    'corpair(species, level = "phylogenetic", block = "p", from = "mu1", to = "mu2")'
  )
  expect_equal(
    phylo_entry$corpair[c("group", "level", "block", "from", "to")],
    list(
      group = "species",
      level = "phylogenetic",
      block = "p",
      from = "mu1",
      to = "mu2"
    )
  )

  class_form <- drm_formula(
    corpair(id, block = "p", class = "location-scale") ~ z
  )
  class_entry <- class_form$entries[[1L]]
  expect_equal(
    class_entry$corpair[c("group", "block", "class")],
    list(group = "id", block = "p", class = "location-scale")
  )
})

test_that("drm_formula() captures planned structured-effect syntax", {
  form <- drm_formula(
    y ~ x + phylo(1 | species, tree = tree) + spatial(1 | site, coords = coords)
  )

  expect_s3_class(form, "drm_formula")
  expect_equal(form$entries[[1]]$dpar, "mu")
  expect_length(form$entries[[1]]$structured, 2)
  expect_equal(
    form$entries[[1]]$structured[[1]][c("type", "group", "tree")],
    list(type = "phylo", group = "species", tree = "tree")
  )
  expect_equal(
    form$entries[[1]]$structured[[2]][c(
      "type",
      "group",
      "structure",
      "object"
    )],
    list(
      type = "spatial",
      group = "site",
      structure = "coords",
      object = "coords"
    )
  )

  mesh_form <- drm_formula(y ~ spatial(1 | site, mesh = mesh))
  expect_equal(
    mesh_form$entries[[1]]$structured[[1]][c(
      "type",
      "group",
      "structure",
      "object"
    )],
    list(type = "spatial", group = "site", structure = "mesh", object = "mesh")
  )

  slope_form <- drm_formula(y ~ phylo(1 + depth | species, tree = tree))
  expect_equal(
    slope_form$entries[[1]]$structured[[1]]$coef_names,
    c("(Intercept)", "depth")
  )
  expect_equal(slope_form$entries[[1]]$structured[[1]]$variables, "depth")

  labelled_phylo <- drm_formula(
    y ~ x + phylo(1 | p | species, tree = tree)
  )
  expect_equal(
    labelled_phylo$entries[[1]]$structured[[1]][c(
      "type",
      "group",
      "tree",
      "label",
      "covariance_label"
    )],
    list(
      type = "phylo",
      group = "species",
      tree = "tree",
      label = "phylo(1 | p | species)",
      covariance_label = "p"
    )
  )
})

test_that("formula markers are no-op placeholders", {
  expect_null(meta_known_V(V = 1))
  expect_null(gr(id, cov = diag(1)))
  expect_null(phylo(1 | species, tree = tree))
  expect_null(spatial(1 | site, coords = coords))
  expect_null(spatial(1 | site, mesh = mesh))
  expect_null(corpair(id, block = "p", class = "location-scale"))
  expect_null(corpair(id, block = "p", from = "mu1", to = "sigma2"))
  expect_null(corpair(
    species,
    level = "phylogenetic",
    block = "p",
    from = "mu1",
    to = "mu2"
  ))
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
    drm_formula(y ~ x + phylo(1 | "p" | species, tree = tree)),
    "labels must be simple names"
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

test_that("corpair formulas validate grammar and unsupported fits clearly", {
  dat <- data.frame(
    y1 = c(0.1, 0.3, -0.2, 0.4),
    y2 = c(-0.1, 0.2, 0.0, 0.5),
    x = c(0, 1, 0, 1),
    z = c(1, 1, 2, 2),
    id = factor(c(1, 1, 2, 2))
  )
  form <- drm_formula(
    mu1 = y1 ~ x + (1 | p | id),
    mu2 = y2 ~ x + (1 | p | id),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1,
    corpair(id, block = "p", from = "mu1", to = "mu2") ~ z
  )

  expect_error(
    drm_formula(corpair(id, block = p) ~ z),
    "single string"
  )
  expect_error(
    drm_formula(corpair(id, class = "residual") ~ z),
    "latent random-effect correlation class"
  )
  expect_error(
    drm_formula(corpair(id, level = "residual", from = "mu1", to = "mu2") ~ z),
    "latent random-effect correlation level"
  )
  expect_error(
    drm_formula(corpair(id, from = "mu1") ~ z),
    "must be supplied together"
  )
  expect_error(
    drm_formula(
      corpair(id, class = "location-scale", from = "mu1", to = "sigma2") ~ z
    ),
    "either .*class.* or endpoint-specific"
  )
  expect_error(
    drm_formula(corpair(id, from = "rho12", to = "sigma2") ~ z),
    "distributional-parameter endpoints"
  )
  expect_error(
    drm_formula(corpair(id, from = "mu1", to = "mu1") ~ z),
    "two different endpoints"
  )
  expect_error(
    drm_formula(target = corpair(id, block = "p") ~ z),
    "should be unnamed"
  )
  bad_fit_form <- drm_formula(
    mu1 = y1 ~ x + (1 | p | id),
    mu2 = y2 ~ x + (1 | p | id),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1,
    corpair(id, block = "p", from = "mu1", to = "sigma2") ~ z
  )
  expect_error(
    drmTMB(bad_fit_form, family = biv_gaussian(), data = dat),
    "location-location only"
  )
})
