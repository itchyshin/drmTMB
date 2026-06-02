structured_effects_test_tree <- function(n_tip = 4L, prefix = "sp") {
  stopifnot(n_tip == 4L)
  structure(
    list(
      edge = matrix(
        c(5, 1, 5, 2, 6, 3, 6, 4, 7, 5, 7, 6),
        byrow = TRUE,
        ncol = 2L
      ),
      edge.length = rep(1, 6),
      tip.label = paste0(prefix, "_", seq_len(n_tip)),
      Nnode = 3L
    ),
    class = "phylo"
  )
}

structured_effects_test_data <- function() {
  species_tree <- structured_effects_test_tree(prefix = "sp")
  plant_tree <- structured_effects_test_tree(prefix = "plant")
  pollinator_tree <- structured_effects_test_tree(prefix = "pollinator")
  pair_grid <- expand.grid(
    plant = plant_tree$tip.label,
    pollinator = pollinator_tree$tip.label,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  id_levels <- paste0("id_", seq_len(4L))
  site_levels <- paste0("site_", seq_len(4L))
  K <- outer(seq_len(4L), seq_len(4L), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(id_levels, id_levels)
  coords <- data.frame(
    x = c(0, 1, 0, 1),
    y = c(0, 0, 1, 1)
  )
  rownames(coords) <- site_levels

  list(
    data = data.frame(
      y = seq_len(nrow(pair_grid)) / 10,
      x = rep(c(-1, -0.25, 0.25, 1), length.out = nrow(pair_grid)),
      species = rep(species_tree$tip.label, each = 4L),
      site = rep(site_levels, each = 4L),
      id = rep(id_levels, each = 4L),
      plant = pair_grid$plant,
      pollinator = pair_grid$pollinator
    ),
    species_tree = species_tree,
    plant_tree = plant_tree,
    pollinator_tree = pollinator_tree,
    coords = coords,
    K = K,
    Q = solve(K)
  )
}

structured_effects_fit_from_formula <- function(formula, data, env) {
  parsed <- do.call(drm_formula, list(formula))
  term <- parsed$entries[[1L]]$structured[[1L]]
  structured_mu <- drmTMB:::build_structured_mu_structure(term, data, env)
  structure(
    list(
      model = list(
        model_type = "gaussian",
        structured = list(phylo_mu = structured_mu)
      )
    ),
    class = "drmTMB"
  )
}

expect_single_structured_effect <- function(
  formula,
  data,
  env,
  marker,
  grouping_variable,
  matrix_attachment,
  structure,
  random_effect_block,
  correlation_level
) {
  fit <- structured_effects_fit_from_formula(formula, data, env)
  out <- structured_effects(fit)

  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 1L)
  expect_equal(out$marker, marker)
  expect_equal(out$grouping_variable, grouping_variable)
  expect_equal(out$matrix_attachment, matrix_attachment)
  expect_equal(out$structure, structure)
  expect_equal(out$random_effect_block, random_effect_block)
  expect_equal(out$correlation_level, correlation_level)
  expect_equal(out$dpars[[1L]], "mu")
  expect_equal(out$coef_names[[1L]], "(Intercept)")
  expect_equal(out$q, 1L)
  expect_gt(out$n_re, 0L)
  out
}

test_that("structured_effects() returns an empty stable table without structure", {
  fit <- structure(
    list(
      model = list(
        model_type = "gaussian",
        structured = list(phylo_mu = drmTMB:::empty_phylo_mu_structure())
      )
    ),
    class = "drmTMB"
  )

  out <- structured_effects(fit)

  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 0L)
  expect_named(
    out,
    c(
      "marker",
      "grouping_variable",
      "matrix_attachment",
      "structure",
      "group1",
      "group2",
      "label",
      "block",
      "q",
      "n_re",
      "random_effect_block",
      "correlation_level",
      "dpars",
      "coef_names",
      "args"
    )
  )
})

test_that("structured_effects() reports current parsed structured markers", {
  sim <- structured_effects_test_data()
  dat <- sim$data
  tree <- sim$species_tree
  plant_tree <- sim$plant_tree
  pollinator_tree <- sim$pollinator_tree
  coords <- sim$coords
  Q <- sim$Q
  env <- environment()

  phylo_row <- expect_single_structured_effect(
    y ~ x + phylo(1 | species, tree = tree),
    dat,
    env,
    marker = "phylo",
    grouping_variable = "species",
    matrix_attachment = "tree",
    structure = "tree",
    random_effect_block = "phylo_mu",
    correlation_level = "phylogenetic"
  )
  expect_equal(phylo_row$args[[1L]], list(tree = "tree"))

  spatial_row <- expect_single_structured_effect(
    y ~ x + spatial(1 | site, coords = coords),
    dat,
    env,
    marker = "spatial",
    grouping_variable = "site",
    matrix_attachment = "coords",
    structure = "coords",
    random_effect_block = "spatial_mu",
    correlation_level = "spatial"
  )
  expect_equal(spatial_row$args[[1L]], list(coords = "coords"))

  animal_row <- expect_single_structured_effect(
    y ~ x + animal(1 | id, Ainv = Q),
    dat,
    env,
    marker = "animal",
    grouping_variable = "id",
    matrix_attachment = "Q",
    structure = "Ainv",
    random_effect_block = "animal_mu",
    correlation_level = "animal"
  )
  expect_equal(animal_row$args[[1L]], list(Ainv = "Q"))

  relmat_row <- expect_single_structured_effect(
    y ~ x + relmat(1 | id, Q = Q),
    dat,
    env,
    marker = "relmat",
    grouping_variable = "id",
    matrix_attachment = "Q",
    structure = "Q",
    random_effect_block = "relmat_mu",
    correlation_level = "relmat"
  )
  expect_equal(relmat_row$args[[1L]], list(Q = "Q"))

  interaction_row <- expect_single_structured_effect(
    y ~ x +
      phylo_interaction(
        1 | plant:pollinator,
        tree1 = plant_tree,
        tree2 = pollinator_tree
      ),
    dat,
    env,
    marker = "phylo_interaction",
    grouping_variable = "plant:pollinator",
    matrix_attachment = "plant_tree:pollinator_tree",
    structure = "tree_pair",
    random_effect_block = "phylo_interaction_mu",
    correlation_level = "phylo_interaction"
  )
  expect_equal(interaction_row$group1, "plant")
  expect_equal(interaction_row$group2, "pollinator")
  expect_equal(
    interaction_row$args[[1L]],
    list(
      tree1 = "plant_tree",
      tree2 = "pollinator_tree",
      group1 = "plant",
      group2 = "pollinator"
    )
  )
})
