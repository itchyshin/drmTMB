test_that("SD target resolution rejects incomplete member identity metadata", {
  member <- list(
    provider = "ordinary",
    level = "group",
    group = "site",
    dpar = "mu",
    coef = "(Intercept)",
    block = NA_character_
  )
  target <- list(group = "site", fun = "sd")
  resolve <- drmTMB:::drm_resolve_sd_target

  expect_identical(resolve(target, list(member)), member)

  for (field in c("provider", "group", "dpar", "coef", "block")) {
    malformed <- member
    malformed[[field]] <- NULL
    expect_error(
      resolve(target, list(malformed)),
      "Random-effect SD members require complete identity metadata.",
      info = paste("missing", field)
    )
  }

  for (field in c("provider", "group", "dpar", "coef")) {
    malformed <- member
    malformed[[field]] <- c("first", "second")
    expect_error(
      resolve(target, list(malformed)),
      "Random-effect SD members require complete identity metadata.",
      info = paste("non-scalar", field)
    )
  }

  for (bad_block in list("", c(NA_character_, "label"), 1)) {
    malformed <- member
    malformed$block <- bad_block
    expect_error(
      resolve(target, list(malformed)),
      "Random-effect SD members require complete identity metadata."
    )
  }
})

test_that("structured SD target resolution requires a valid provider level", {
  member <- list(
    provider = "phylogenetic",
    level = "phylogenetic",
    group = "species",
    dpar = "mu",
    coef = "(Intercept)",
    block = NA_character_
  )
  target <- list(
    group = "species", fun = "sd", level = "phylogenetic"
  )
  resolve <- drmTMB:::drm_resolve_sd_target

  expect_identical(resolve(target, list(member)), member)

  for (bad_level in list(NULL, NA_character_, "", "group", c("one", "two"))) {
    malformed <- member
    malformed$level <- bad_level
    expect_error(
      resolve(target, list(malformed)),
      "Structured random-effect SD members require explicit level metadata."
    )
  }
})
