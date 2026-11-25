# Fast formula-parser guards. These calls stop while reading the formula,
# before any model is fitted.

test_that("drm_formula rejects inputs that are not formulas", {
  expect_error(
    bf(1),
    "inputs must be formulas or symbols"
  )
  expect_error(
    bf(no_such_drm_formula_symbol_1124d),
    "could not evaluate input"
  )
  not_a_formula <- 1
  expect_error(
    bf(not_a_formula),
    "must be a formula"
  )
  expect_error(
    bf(~ x),
    "missing both a parameter name and a left-hand side"
  )
})

test_that("named random-effect scale formulas stay unnamed", {
  expect_error(
    bf(scale = sd(id) ~ x),
    "Random-effect scale formulas should be unnamed"
  )
  expect_error(
    bf(rho = corpair(species, level = "group", from = "mu1", to = "mu2") ~ x),
    "Correlation-pair formulas should be unnamed"
  )
})

test_that("corpair and sd left-hand sides name one target and unique options", {
  expect_error(
    bf(corpair() ~ x),
    "exactly one grouping variable"
  )
  expect_error(
    bf(corpair(species + site, level = "group") ~ x),
    "simple grouping variable"
  )
  expect_error(
    bf(corpair(species, other = "group") ~ x),
    "currently accepts only"
  )
  expect_error(
    bf(corpair(species, level = "group", level = "spatial") ~ x),
    "options cannot be repeated"
  )
  expect_error(
    bf(sd(id, other = "mu") ~ x),
    "currently accepts only"
  )
  expect_error(
    bf(sd(id, dpar = "mu", dpar = "sigma") ~ x),
    "options cannot be repeated"
  )
  expect_error(
    bf(sd(id, dpar = mu) ~ x),
    "must be a single string"
  )
})

test_that("shorthand sd targets do not take explicit selectors", {
  expect_error(
    bf(sd1(id, dpar = "mu") ~ x),
    "does not accept explicit target options"
  )
  expect_warning(
    expect_error(
      bf(sd_phylo(species, coef = "(Intercept)") ~ x),
      "sd_phylo\\(species\\)"
    ),
    "deprecated"
  )
  expect_error(
    bf(sd1(id, level = "phylogenetic_interaction") ~ x),
    "not an implemented random-effect SD target"
  )
})

test_that("structured markers reject malformed grouping and time arguments", {
  expect_error(
    bf(y ~ phylo() + x),
    "exactly one structured random-effect term"
  )
  expect_error(
    bf(y ~ phylo(1 | species + site, tree = tree)),
    "grouping terms must be simple variables"
  )
  expect_error(
    bf(y ~ temporal(1 | id, time = "occasion", structure = "ar1")),
    "must name an occasion variable"
  )
  expect_error(
    bf(y ~ phylo_interaction(1 | plant:plant, tree1 = plant_tree, tree2 = pollinator_tree)),
    "two different partner variables"
  )
  expect_error(
    bf(y ~ phylo_interaction(1 | plant:pollinator, tree1 = "plant_tree", tree2 = pollinator_tree)),
    "must name phylogeny objects"
  )
})

test_that("double-bar desugaring rejects an empty term and ignores a missing slope column", {
  expect_identical(
    drmTMB:::desugar_double_bars_in_call(quote(1), data.frame(y = 1)),
    quote(1)
  )
  expect_null(
    drmTMB:::check_double_bar_slope_is_numeric(
      "nope",
      "id",
      "nope || id",
      data.frame(y = 1)
    )
  )

  dat <- data.frame(y = stats::rnorm(6), id = gl(2, 3))
  expect_error(
    drmTMB(bf(y ~ (0 || id)), data = dat, control = drm_control(se = FALSE)),
    "requires at least one random term"
  )
})
