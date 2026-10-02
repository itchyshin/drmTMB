phylo_temporal_ou_parser_data <- function() {
  set.seed(202609091L)
  tree <- ape::rcoal(4L)
  tree$tip.label <- paste0("sp", seq_len(ape::Ntip(tree)))
  dat <- expand.grid(
    species = tree$tip.label,
    elapsed = c(0, 1, 3, 6),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  dat$x <- stats::rnorm(nrow(dat))
  dat$y <- 0.2 + 0.4 * dat$x + stats::rnorm(nrow(dat), sd = 0.4)
  list(tree = tree, data = dat[sample.int(nrow(dat)), , drop = FALSE])
}

test_that("paired phylo() plus OU has a named, non-separable layout contract", {
  fixture <- phylo_temporal_ou_parser_data()
  tree <- fixture$tree
  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree) +
         temporal(1 | species, time = elapsed, structure = "ou"),
       sigma ~ 1),
    data = fixture$data,
    family = gaussian(),
    REML = FALSE
  )

  expect_s3_class(fit, "drmTMB")
  expect_true(fit$model$structured$phylo_mu$has)
  expect_true(fit$model$structured$temporal_mu$has)
  expect_true(fit$model$structured$temporal_mu$paired_phylo_stable)
  expect_identical(fit$model$structured$temporal_mu$group, "species")
  expect_equal(fit$model$structured$temporal_mu$minimum_distinct_lags, 3L)
})

test_that("paired phylo() plus OU rejects mismatched and under-supported metadata", {
  fixture <- phylo_temporal_ou_parser_data()
  tree <- fixture$tree
  dat <- transform(fixture$data, other_species = species)

  expect_error(
    drmTMB(
      bf(y ~ phylo(1 | species, tree = tree) +
           temporal(1 | other_species, time = elapsed, structure = "ou"),
         sigma ~ 1),
      data = dat, family = gaussian(), REML = FALSE
    ),
    "same grouping"
  )
  expect_error(
    drmTMB(
      bf(y ~ (1 | species) + phylo(1 | species, tree = tree) +
           temporal(1 | species, time = elapsed, structure = "ou"),
         sigma ~ 1),
      data = dat, family = gaussian(), REML = FALSE
    ),
    "does not allow an ordinary"
  )
  short <- dat[dat$species %in% unique(dat$species)[1:2], , drop = FALSE]
  expect_error(
    drmTMB(
      bf(y ~ phylo(1 | species, tree = tree) +
           temporal(1 | species, time = elapsed, structure = "ou"),
         sigma ~ 1),
      data = short, family = gaussian(), REML = FALSE
    ),
    "at least three observed species"
  )
  duplicate <- dat
  duplicate$elapsed[[2L]] <- duplicate$elapsed[[1L]]
  duplicate$y[[2L]] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ phylo(1 | species, tree = tree) +
           temporal(1 | species, time = elapsed, structure = "ou"),
         sigma ~ 1),
      data = duplicate, family = gaussian(), REML = FALSE
    ),
    "keys must be unique"
  )
})

test_that("paired phylo() plus OU rechecks retained rows after response omission", {
  fixture <- phylo_temporal_ou_parser_data()
  tree <- fixture$tree
  dat <- fixture$data
  first_species <- unique(dat$species)[[1L]]
  keep_one <- which(dat$species == first_species)[-1L]
  dat$y[keep_one] <- NA_real_
  expect_error(
    drmTMB(
      bf(y ~ phylo(1 | species, tree = tree) +
           temporal(1 | species, time = elapsed, structure = "ou"),
         sigma ~ 1),
      data = dat, family = gaussian(), REML = FALSE
    ),
    "two retained observations"
  )

  mismatched_tree <- tree
  mismatched_tree$tip.label[[1L]] <- "not_observed"
  expect_error(
    drmTMB(
      bf(y ~ phylo(1 | species, tree = mismatched_tree) +
           temporal(1 | species, time = elapsed, structure = "ou"),
         sigma ~ 1),
      data = fixture$data, family = gaussian(), REML = FALSE
    ),
    "observed species"
  )
  subset_data <- fixture$data[fixture$data$species != tree$tip.label[[4L]], , drop = FALSE]
  expect_error(
    drmTMB(
      bf(y ~ phylo(1 | species, tree = tree) +
           temporal(1 | species, time = elapsed, structure = "ou"),
         sigma ~ 1),
      data = subset_data, family = gaussian(), REML = FALSE
    ),
    "tips to match"
  )
})
