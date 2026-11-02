structured_sd_member <- function(group = "id", dpar = "mu",
                                 coef = "(Intercept)", block = NA_character_,
                                 provider = "phylo",
                                 level = "phylogenetic") {
  list(
    provider = provider,
    level = level,
    group = group,
    dpar = dpar,
    coef = coef,
    block = block,
    label = paste(dpar, group, coef, sep = ":"),
    source_label = group
  )
}

structured_sd_target <- function(level = NA_character_, dpar = NA_character_,
                                 coef = NA_character_, block = NA_character_) {
  target <- parse_sd_lhs(call("sd", as.name("id")))
  target$level <- level
  target$target_dpar <- dpar
  target$target_coef <- coef
  target$target_block <- block
  target
}

test_that("structured SD selectors resolve provider and level identity", {
  ordinary <- list(
    provider = "ordinary",
    level = "group",
    group = "id",
    dpar = "mu",
    coef = "(Intercept)",
    block = NA_character_,
    label = "mu:id:(Intercept)",
    source_label = "(1 | id)"
  )
  phylogenetic <- structured_sd_member()

  selected <- drm_resolve_sd_target(
    structured_sd_target(level = "phylogenetic"),
    list(ordinary, phylogenetic)
  )

  expect_identical(selected, phylogenetic)
})

test_that("unselected ordinary and structured targets report both candidates", {
  ordinary <- list(
    provider = "ordinary",
    level = "group",
    group = "id",
    dpar = "mu",
    coef = "(Intercept)",
    block = NA_character_,
    label = "mu:id:(Intercept)",
    source_label = "(1 | id)"
  )
  phylogenetic <- structured_sd_member()

  expect_error(
    drm_resolve_sd_target(structured_sd_target(), list(ordinary, phylogenetic)),
    "Ambiguous.*provider=ordinary.*provider=phylo.*level=phylogenetic"
  )
  expect_identical(
    drm_resolve_sd_target(
      structured_sd_target(dpar = "mu", coef = "(Intercept)", level = "phylogenetic"),
      list(ordinary, phylogenetic)
    ),
    phylogenetic
  )
})

test_that("wrong structured levels fail with available target identities", {
  phylogenetic <- structured_sd_member()

  expect_error(
    drm_resolve_sd_target(structured_sd_target(level = "spatial"), list(phylogenetic)),
    "No .*target.*[Aa]vailable.*provider=phylo.*level=phylogenetic"
  )
})

test_that("two structured candidates require a level selector", {
  phylogenetic <- structured_sd_member(provider = "phylo", level = "phylogenetic")
  spatial <- structured_sd_member(provider = "spatial", level = "spatial")

  expect_error(
    drm_resolve_sd_target(structured_sd_target(), list(phylogenetic, spatial)),
    "Ambiguous.*provider=phylo.*level=phylogenetic.*provider=spatial.*level=spatial"
  )
  expect_identical(
    drm_resolve_sd_target(structured_sd_target(level = "spatial"), list(phylogenetic, spatial)),
    spatial
  )
})

test_that("structured SD selectors distinguish coefficients within a level", {
  intercept <- structured_sd_member(
    coef = "(Intercept)", block = "p"
  )
  slope <- structured_sd_member(
    coef = "x", block = "p"
  )

  expect_error(
    drm_resolve_sd_target(
      structured_sd_target(level = "phylogenetic"),
      list(intercept, slope)
    ),
    "Ambiguous.*coef=\\(Intercept\\).*coef=x"
  )
  expect_identical(
    drm_resolve_sd_target(
      structured_sd_target(level = "phylogenetic", coef = "x"),
      list(intercept, slope)
    ),
    slope
  )
})

test_that("structured SD block selectors distinguish same-coefficient blocks", {
  block_p <- structured_sd_member(block = "p")
  block_q <- structured_sd_member(block = "q")

  expect_error(
    drm_resolve_sd_target(
      structured_sd_target(level = "phylogenetic"),
      list(block_p, block_q)
    ),
    "Ambiguous.*block=p.*block=q"
  )
  expect_identical(
    drm_resolve_sd_target(
      structured_sd_target(level = "phylogenetic", block = "q"),
      list(block_p, block_q)
    ),
    block_q
  )
})

test_that("structured SD targets reject missing level metadata explicitly", {
  malformed <- structured_sd_member(level = NULL)

  expect_error(
    drm_resolve_sd_target(
      structured_sd_target(),
      list(malformed)
    ),
    "structured.*level|level.*metadata"
  )
})

test_that("structured SD targets reject incomplete identity metadata", {
  malformed_members <- list(
    missing_provider = function(member) { member$provider <- NULL; member },
    empty_group = function(member) { member$group <- ""; member },
    missing_dpar = function(member) { member$dpar <- NULL; member },
    missing_coef = function(member) { member$coef <- NULL; member },
    missing_block = function(member) { member$block <- NULL; member }
  )

  for (make_malformed in malformed_members) {
    expect_error(
      drm_resolve_sd_target(
        structured_sd_target(level = "phylogenetic"),
        list(make_malformed(structured_sd_member()))
      ),
      "complete.*identity metadata"
    )
  }
})
