# R/profile.R Wald SD helpers, confint table utilities, and parallel bookkeeping
# (complements existing profile-parallel.R and profile-arg-validators coverage).

test_that("wald_sd_target_is_location_axis() reads mu vs sigma dpar families", {
  f <- drmTMB:::wald_sd_target_is_location_axis
  row <- function(dpar) data.frame(dpar = I(list(dpar)))
  expect_true(f(row("mu")))
  expect_true(f(row("mu1")))
  expect_false(f(row("sigma")))
  expect_false(f(row("sigma2")))
  expect_false(f(row(NA_character_)))
  expect_false(f(row("rho12")))
})

test_that("structured_sd_term_signature() parses type and group labels", {
  f <- drmTMB:::structured_sd_term_signature
  expect_null(f("not a term"))
  expect_null(f(""))
  sig <- f("phylo(1 | species)")
  expect_equal(sig$type, "phylo")
  expect_equal(sig$group, "species")
  sig2 <- f("  animal(1 + x | site)  ")
  expect_equal(sig2$type, "animal")
  expect_match(sig2$group, "site")
  sig3 <- f("relmat(1 | id)")
  expect_equal(sig3$type, "relmat")
  expect_equal(sig3$group, "id")
})

test_that("structured_sd_term_matches_label() compares signatures and suffixes", {
  f <- drmTMB:::structured_sd_term_matches_label
  expect_false(f(NA, "phylo(1 | g)"))
  expect_false(f("x", ""))
  term <- "phylo(1 | species)"
  expect_true(f(term, term))
  expect_false(f("phylo(1 | a)", "phylo(1 | b)"))
  expect_false(f("spatial(1 | x)", "animal(1 | x)"))
})

test_that("structured_sd_group_count() needs a scalar structured phylo block", {
  f <- drmTMB:::structured_sd_group_count
  expect_true(is.na(f(list(model = list(structured = list())))))
  expect_true(is.na(f(list(model = list(structured = list(phylo_mu = list(has = FALSE)))))))
  ok <- list(
    model = list(
      structured = list(
        phylo_mu = list(has = TRUE, group_levels = c("a", "b", "c"))
      )
    )
  )
  expect_equal(f(ok), 3)
  expect_true(is.na(f(list(model = list(structured = list(phylo_mu = list(has = TRUE, group_levels = character())))))))
})

test_that("wald_target_df() resolves structured phylo mu-sd rows", {
  label <- "phylo(1 | species)"
  object <- list(
    model = list(
      structured = list(
        phylo_mu = list(
          has = TRUE,
          label = label,
          group_levels = letters[1:5]
        )
      ),
      random = list(covariance_blocks = list())
    )
  )
  targets <- data.frame(
    target_class = c("fixed-effect", "random-effect-sd", "random-effect-sd"),
    dpar = I(list("mu", "mu", "sigma")),
    tmb_parameter = I(list(NA_character_, "log_sd_phylo", NA_character_)),
    term = I(list(NA_character_, label, NA_character_)),
    stringsAsFactors = FALSE
  )
  df <- drmTMB:::wald_target_df(object, targets)
  expect_length(df, 3L)
  expect_true(is.na(df[1]))
  expect_equal(df[2], 4)
  expect_true(is.na(df[3]))
  bias <- drmTMB:::wald_target_log_bias(object, targets)
  expect_equal(bias[2], log(5 / 4))
  expect_identical(drmTMB:::wald_target_df(object, targets[0, , drop = FALSE]), numeric(0))
})

test_that("profile_wald_standard_errors() floors tiny negative variance at zero", {
  f <- drmTMB:::profile_wald_standard_errors
  v <- c(0.25, -1e-15, -1, NA, Inf, 0)
  se <- f(v)
  expect_equal(se[1], 0.5)
  expect_equal(se[6], 0)
  expect_true(all(is.na(se[c(3, 4, 5)])))
  expect_equal(se[2], 0)
  expect_identical(f(numeric()), numeric())
})

test_that("empty_confint_table() and as.matrix.drm_confint() shape drm_confint", {
  empty <- drmTMB:::empty_confint_table("wald")
  expect_s3_class(empty, "drm_confint")
  expect_equal(nrow(empty), 0L)
  mat0 <- as.matrix(empty)
  expect_equal(dim(mat0), c(0L, 2L))
  tbl <- data.frame(
    parm = c("a", "b"),
    level = c(0.95, 0.95),
    lower = c(1, 3),
    upper = c(2, 4),
    stringsAsFactors = FALSE
  )
  tbl <- drmTMB:::drm_as_confint_table(tbl)
  mat <- as.matrix(tbl)
  expect_equal(rownames(mat), c("a", "b"))
  expect_equal(unname(mat[1, ]), c(1, 2))
  expect_match(colnames(mat)[1], "2.5")
})

test_that("interval_source_levels() and interval_status_levels() are stable sets", {
  src <- drmTMB:::interval_source_levels()
  expect_identical(src, c("wald", "profile", "bootstrap", "not_available"))
  sts <- drmTMB:::interval_status_levels()
  expect_true("wald_unavailable" %in% sts)
  expect_true("not_requested" %in% sts)
  expect_gt(length(sts), 8L)
  expect_equal(anyDuplicated(sts), 0L)
})

test_that("bootstrap_seed_label() and validate_bootstrap_replicates() coerce inputs", {
  expect_identical(drmTMB:::bootstrap_seed_label(NULL), NA_character_)
  expect_identical(drmTMB:::bootstrap_seed_label(1:3), "1,2,3")
  expect_identical(drmTMB:::validate_bootstrap_replicates(10L), 10L)
  for (bad in list(0, 1.5, NA, "x", c(1, 2), Inf)) {
    expect_error(drmTMB:::validate_bootstrap_replicates(bad), "positive whole number")
  }
})

test_that("profile_precision_args() honors fast defaults and rejects duplicate maxit", {
  args <- drmTMB:::profile_precision_args("fast", list(), profile_maxit = 12L)
  expect_equal(args$maxit, 12L)
  expect_equal(args$ystep, 0.5)
  expect_equal(args$ytol, 2)
  expect_error(
    drmTMB:::profile_precision_args("default", list(maxit = 1L), profile_maxit = 2L),
    "supplied twice"
  )
  kept <- drmTMB:::profile_precision_args("default", list(foo = 1L), NULL)
  expect_equal(kept$foo, 1L)
  expect_false("ystep" %in% names(kept))
})

test_that("drm_dead_worker_indices() and drm_check_parallel_results() handle NULL slots", {
  idx <- drmTMB:::drm_dead_worker_indices(list(1, NULL, 3), 1:3)
  expect_equal(idx, 2L)
  short <- drmTMB:::drm_dead_worker_indices(list(1), 1:3)
  expect_equal(short, c(2L, 3L))
  bad <- drmTMB:::drm_dead_worker_indices("not a list", 1:2)
  expect_equal(bad, c(1L, 2L))
  kept <- drmTMB:::drm_check_parallel_results(list(1, NULL, 3), 1:3, on_dead = "record")
  expect_length(kept, 3L)
  expect_error(
    drmTMB:::drm_check_parallel_results(list(1, NULL), 1:2, on_dead = "error"),
    class = "drmTMB_parallel_worker_died"
  )
})

test_that("profile_controls_label() formats TMB profile dot arguments", {
  empty <- drmTMB:::profile_controls_label(list())
  expect_identical(empty, "TMB defaults")
  long <- drmTMB:::profile_controls_label(list(a = 1:6, b = "x"))
  expect_match(long, "a=1/2/3/4")
  expect_match(long, "b=x")
})