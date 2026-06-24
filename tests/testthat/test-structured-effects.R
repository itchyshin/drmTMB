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

capture_structured_effects_error <- function(expr) {
  tryCatch(
    {
      force(expr)
      NULL
    },
    error = identity
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
  correlation_level,
  matrix_slot = structure,
  matrix_source = matrix_attachment,
  matrix_role,
  input_scale,
  missing_level_policy,
  bridge_marshalling
) {
  fit <- structured_effects_fit_from_formula(formula, data, env)
  out <- structured_effects(fit)

  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 1L)
  expect_equal(out$marker, marker)
  expect_equal(out$provider, marker)
  expect_equal(out$grouping_variable, grouping_variable)
  expect_equal(out$matrix_attachment, matrix_attachment)
  expect_equal(out$matrix_slot, matrix_slot)
  expect_equal(out$matrix_source, matrix_source)
  expect_equal(out$matrix_role, matrix_role)
  expect_equal(out$input_scale, input_scale)
  expect_equal(out$missing_level_policy, missing_level_policy)
  expect_equal(out$bridge_marshalling, bridge_marshalling)
  expect_match(out$provenance_contract, "matrix_digest", fixed = TRUE)
  expect_equal(
    out$matrix_id,
    paste(
      c(marker, matrix_slot, matrix_source, grouping_variable),
      collapse = "::"
    )
  )
  expect_match(out$matrix_digest, "^precision:", perl = TRUE)
  expect_equal(out$structure, structure)
  expect_equal(out$block_label, out$block)
  expect_equal(out$covariance_layout, "scalar")
  expect_equal(out$endpoint_set, "mu")
  expect_equal(out$coefficient_set, "(Intercept)")
  expect_equal(out$random_effect_block, random_effect_block)
  expect_equal(out$correlation_level, correlation_level)
  expect_equal(out$provider_level_count, length(out$provider_levels[[1L]]))
  expect_equal(out$observed_level_count, length(out$observed_levels[[1L]]))
  expect_true(all(out$observed_levels[[1L]] %in% out$provider_levels[[1L]]))
  expect_equal(out$dpars[[1L]], "mu")
  expect_equal(out$coef_names[[1L]], "(Intercept)")
  expect_equal(out$endpoint_blocks[[1L]], marker)
  expect_equal(out$endpoint_covariance_labels[[1L]], NA_character_)
  expect_equal(out$q, 1L)
  expect_gt(out$n_re, 0L)
  expect_equal(out$member_count, length(out$member_levels[[1L]]))
  expect_gt(out$member_count, 0L)
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
      "provider",
      "grouping_variable",
      "matrix_attachment",
      "matrix_id",
      "matrix_slot",
      "matrix_source",
      "matrix_role",
      "matrix_digest",
      "input_scale",
      "level_alignment",
      "missing_level_policy",
      "bridge_marshalling",
      "provenance_contract",
      "structure",
      "group1",
      "group2",
      "label",
      "block",
      "block_label",
      "covariance_layout",
      "endpoint_set",
      "coefficient_set",
      "q",
      "n_re",
      "member_count",
      "provider_level_count",
      "observed_level_count",
      "random_effect_block",
      "correlation_level",
      "dpars",
      "coef_names",
      "member_levels",
      "provider_levels",
      "observed_levels",
      "endpoint_blocks",
      "endpoint_covariance_labels",
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
    correlation_level = "phylogenetic",
    matrix_role = "tree_precision",
    input_scale = "ultrametric_tree_branch_lengths",
    missing_level_policy = paste0(
      "error_if_observed_species_absent_from_tree;",
      "extra_tree_tips_allowed"
    ),
    bridge_marshalling = "tree_serialized_by_phylo_bridge_fixture"
  )
  expect_equal(phylo_row$args[[1L]], list(tree = "tree"))
  expect_equal(phylo_row$member_levels[[1L]], tree$tip.label)
  expect_equal(phylo_row$provider_levels[[1L]], tree$tip.label)
  expect_equal(phylo_row$observed_levels[[1L]], tree$tip.label)
  expect_equal(
    phylo_row$level_alignment,
    "observed_levels_equal_provider_levels"
  )

  spatial_row <- expect_single_structured_effect(
    y ~ x + spatial(1 | site, coords = coords),
    dat,
    env,
    marker = "spatial",
    grouping_variable = "site",
    matrix_attachment = "coords",
    structure = "coords",
    random_effect_block = "spatial_mu",
    correlation_level = "spatial",
    matrix_role = "coordinate_covariance",
    input_scale = "coordinates_to_fixed_range_covariance",
    missing_level_policy = paste0(
      "error_if_coords_missing_observed_group_or_vary_within_group;",
      "extra_coordinate_rows_not_supported"
    ),
    bridge_marshalling = paste0(
      "gaussian_bridge_converts_coords_to_fixed_covariance_K;",
      "range_estimating_spatial_not_promoted"
    )
  )
  expect_equal(spatial_row$args[[1L]], list(coords = "coords"))
  expect_equal(spatial_row$member_levels[[1L]], rownames(coords))
  expect_equal(spatial_row$provider_levels[[1L]], rownames(coords))
  expect_equal(spatial_row$observed_levels[[1L]], rownames(coords))
  expect_equal(
    spatial_row$level_alignment,
    "observed_levels_equal_provider_levels"
  )

  animal_row <- expect_single_structured_effect(
    y ~ x + animal(1 | id, Ainv = Q),
    dat,
    env,
    marker = "animal",
    grouping_variable = "id",
    matrix_attachment = "Q",
    structure = "Ainv",
    random_effect_block = "animal_mu",
    correlation_level = "animal",
    matrix_role = "precision",
    input_scale = "additive_precision",
    missing_level_policy = paste0(
      "error_if_observed_id_absent_from_matrix;",
      "extra_matrix_levels_allowed"
    ),
    bridge_marshalling = "not_marshaled_by_bridge;Ainv_precision_native_tmb_only"
  )
  expect_equal(animal_row$args[[1L]], list(Ainv = "Q"))
  expect_equal(animal_row$member_levels[[1L]], rownames(Q))
  expect_equal(animal_row$provider_levels[[1L]], rownames(Q))
  expect_equal(animal_row$observed_levels[[1L]], rownames(Q))
  expect_equal(
    animal_row$level_alignment,
    "observed_levels_equal_provider_levels"
  )

  relmat_row <- expect_single_structured_effect(
    y ~ x + relmat(1 | id, Q = Q),
    dat,
    env,
    marker = "relmat",
    grouping_variable = "id",
    matrix_attachment = "Q",
    structure = "Q",
    random_effect_block = "relmat_mu",
    correlation_level = "relmat",
    matrix_role = "precision",
    input_scale = "user_precision",
    missing_level_policy = paste0(
      "error_if_observed_id_absent_from_matrix;",
      "extra_matrix_levels_allowed"
    ),
    bridge_marshalling = "not_marshaled_by_bridge;Q_precision_native_tmb_only"
  )
  expect_equal(relmat_row$args[[1L]], list(Q = "Q"))
  expect_equal(relmat_row$member_levels[[1L]], rownames(Q))
  expect_equal(relmat_row$provider_levels[[1L]], rownames(Q))
  expect_equal(relmat_row$observed_levels[[1L]], rownames(Q))
  expect_equal(
    relmat_row$level_alignment,
    "observed_levels_equal_provider_levels"
  )

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
    correlation_level = "phylo_interaction",
    matrix_slot = "tree_pair",
    matrix_source = "plant_tree:pollinator_tree",
    matrix_role = "tree_pair_precision",
    input_scale = "two_ultrametric_tree_branch_lengths",
    missing_level_policy = paste0(
      "error_if_observed_partner_absent_from_tree;",
      "extra_tree_tips_allowed"
    ),
    bridge_marshalling = "not_marshaled_by_bridge;use_relmat_Q_escape_hatch"
  )
  expect_equal(interaction_row$group1, "plant")
  expect_equal(interaction_row$group2, "pollinator")
  expect_equal(
    interaction_row$member_count,
    length(interaction_row$member_levels[[1L]])
  )
  expect_gt(
    interaction_row$member_count,
    length(plant_tree$tip.label) * length(pollinator_tree$tip.label)
  )
  expect_equal(
    interaction_row$level_alignment,
    "observed_levels_subset_of_provider_levels"
  )
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

test_that("structured_effects() exposes q-series endpoint and coefficient identity", {
  sim <- structured_effects_test_data()
  dat <- sim$data
  tree <- sim$species_tree
  coords <- sim$coords
  K <- sim$K
  env <- environment()

  slope_specs <- list(
    list(
      formula = y ~ x + phylo(1 + x | species, tree = tree),
      provider = "phylo"
    ),
    list(
      formula = y ~ x + spatial(1 + x | site, coords = coords),
      provider = "spatial"
    ),
    list(
      formula = y ~ x + animal(1 + x | id, A = K),
      provider = "animal"
    ),
    list(
      formula = y ~ x + relmat(1 + x | id, K = K),
      provider = "relmat"
    )
  )
  for (spec in slope_specs) {
    slope <- structured_effects_fit_from_formula(spec$formula, dat, env)
    slope_row <- structured_effects(slope)
    expect_equal(slope_row$provider, spec$provider)
    expect_equal(slope_row$endpoint_set, "mu")
    expect_equal(slope_row$coefficient_set, "(Intercept)+x")
    expect_equal(slope_row$covariance_layout, "scalar")
    expect_equal(slope_row$coef_names[[1L]], c("(Intercept)", "x"))
    expect_equal(
      slope_row$endpoint_blocks[[1L]],
      rep(spec$provider, 2L)
    )
    expect_equal(
      slope_row$endpoint_covariance_labels[[1L]],
      rep(NA_character_, 2L)
    )
    expect_equal(slope_row$q, 2L)
    expect_equal(
      slope_row$level_alignment,
      "observed_levels_equal_provider_levels"
    )
  }

  labelled <- structured_effects_fit_from_formula(
    y ~ x + phylo(1 | p | species, tree = tree),
    dat,
    env
  )
  labelled_row <- structured_effects(labelled)
  expect_equal(labelled_row$block_label, "p")
  expect_equal(labelled_row$endpoint_blocks[[1L]], "p")
  expect_equal(labelled_row$endpoint_covariance_labels[[1L]], "p")
  expect_equal(labelled_row$matrix_id, "phylo::tree::tree::species")
})

test_that("structured_effects() records provider-level policy and missing-level rejection", {
  sim <- structured_effects_test_data()
  dat <- sim$data
  tree <- sim$species_tree
  K <- sim$K
  env <- environment()

  K_extra <- diag(nrow(K) + 1L)
  K_extra[seq_len(nrow(K)), seq_len(ncol(K))] <- K
  dimnames(K_extra) <- list(
    c(rownames(K), "id_extra"),
    c(colnames(K), "id_extra")
  )
  relmat_extra <- structured_effects(
    structured_effects_fit_from_formula(
      y ~ x + relmat(1 | id, K = K_extra),
      dat,
      env
    )
  )
  expect_equal(
    relmat_extra$level_alignment,
    "observed_levels_subset_of_provider_levels"
  )
  expect_equal(relmat_extra$provider_level_count, nrow(K_extra))
  expect_equal(relmat_extra$observed_level_count, length(unique(dat$id)))
  expect_true("id_extra" %in% relmat_extra$provider_levels[[1L]])
  expect_false("id_extra" %in% relmat_extra$observed_levels[[1L]])
  expect_match(
    relmat_extra$missing_level_policy,
    "extra_matrix_levels_allowed",
    fixed = TRUE
  )

  pedigree_extra <- data.frame(
    id = c(rownames(K), "id_extra"),
    dam = NA_character_,
    sire = NA_character_
  )
  animal_extra <- structured_effects(
    structured_effects_fit_from_formula(
      y ~ x + animal(1 | id, pedigree = pedigree_extra),
      dat,
      env
    )
  )
  expect_equal(
    animal_extra$level_alignment,
    "observed_levels_subset_of_provider_levels"
  )
  expect_equal(animal_extra$provider_level_count, nrow(pedigree_extra))
  expect_match(
    animal_extra$missing_level_policy,
    "extra_pedigree_ids_allowed",
    fixed = TRUE
  )
  expect_equal(
    animal_extra$bridge_marshalling,
    "not_marshaled_by_bridge;use_A_covariance_or_native_tmb"
  )

  missing_tree_dat <- dat
  missing_tree_dat$species[[1L]] <- "not_in_tree"
  phylo_error <- capture_structured_effects_error(
    structured_effects_fit_from_formula(
      y ~ x + phylo(1 | species, tree = tree),
      missing_tree_dat,
      env
    )
  )
  expect_s3_class(phylo_error, "error")
  expect_match(
    conditionMessage(phylo_error),
    "All observed species must be represented",
    fixed = TRUE
  )

  K_missing <- K[-1L, -1L, drop = FALSE]
  matrix_error <- capture_structured_effects_error(
    structured_effects_fit_from_formula(
      y ~ x + relmat(1 | id, K = K_missing),
      dat,
      env
    )
  )
  expect_s3_class(matrix_error, "error")
  expect_match(
    conditionMessage(matrix_error),
    "does not cover every observed",
    fixed = TRUE
  )
})

test_that("structured_effects() separates covariance and precision providers", {
  sim <- structured_effects_test_data()
  dat <- sim$data
  K <- sim$K
  Q <- sim$Q
  env <- environment()

  animal_covariance <- structured_effects(
    structured_effects_fit_from_formula(
      y ~ x + animal(1 | id, A = K),
      dat,
      env
    )
  )
  animal_precision <- structured_effects(
    structured_effects_fit_from_formula(
      y ~ x + animal(1 | id, Ainv = Q),
      dat,
      env
    )
  )
  relmat_covariance <- structured_effects(
    structured_effects_fit_from_formula(
      y ~ x + relmat(1 | id, K = K),
      dat,
      env
    )
  )
  relmat_precision <- structured_effects(
    structured_effects_fit_from_formula(
      y ~ x + relmat(1 | id, Q = Q),
      dat,
      env
    )
  )

  expect_equal(animal_covariance$matrix_slot, "A")
  expect_equal(animal_covariance$matrix_role, "covariance")
  expect_equal(animal_covariance$matrix_source, "K")
  expect_equal(animal_covariance$matrix_id, "animal::A::K::id")

  expect_equal(animal_precision$matrix_slot, "Ainv")
  expect_equal(animal_precision$matrix_role, "precision")
  expect_equal(animal_precision$matrix_source, "Q")
  expect_equal(animal_precision$matrix_id, "animal::Ainv::Q::id")

  expect_equal(relmat_covariance$matrix_slot, "K")
  expect_equal(relmat_covariance$matrix_role, "covariance")
  expect_equal(relmat_covariance$matrix_source, "K")
  expect_equal(relmat_covariance$matrix_id, "relmat::K::K::id")

  expect_equal(relmat_precision$matrix_slot, "Q")
  expect_equal(relmat_precision$matrix_role, "precision")
  expect_equal(relmat_precision$matrix_source, "Q")
  expect_equal(relmat_precision$matrix_id, "relmat::Q::Q::id")

  expect_equal(
    animal_covariance$member_levels[[1L]],
    animal_precision$member_levels[[1L]]
  )
  expect_equal(
    relmat_covariance$member_levels[[1L]],
    relmat_precision$member_levels[[1L]]
  )
  expect_equal(animal_covariance$matrix_digest, animal_precision$matrix_digest)
  expect_equal(relmat_covariance$matrix_digest, relmat_precision$matrix_digest)
})
