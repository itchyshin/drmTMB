test_that("known_v_dense_storage_summary summarises dense meta_V storage", {
  V <- matrix(c(1, 0, 0, 0, 2, 0, 0, 0, 3), 3, 3)
  dense <- drmTMB:::known_v_dense_storage_summary(V)
  expect_equal(dense$nonzero, 3L)
  expect_equal(dense$density, 1 / 3)
  expect_true(dense$size_mb > 0)

  sparseish <- matrix(c(1, 0, 0, 0), 2, 2)
  sparse <- drmTMB:::known_v_dense_storage_summary(sparseish)
  expect_equal(sparse$nonzero, 1L)
  expect_equal(sparse$density, 0.25)

  empty <- drmTMB:::known_v_dense_storage_summary(matrix(nrow = 0, ncol = 0))
  expect_equal(empty$nonzero, 0L)
  expect_true(is.na(empty$density))
})

test_that("fixed_effect_design_summary counts nonzeros for dense and sparse X", {
  dense <- matrix(c(0, 1, 2, 0), nrow = 2)
  summary_dense <- drmTMB:::fixed_effect_design_summary(list(mu = dense))
  expect_equal(summary_dense$dpar, "mu")
  expect_equal(summary_dense$n_nonzero, 2)
  expect_equal(summary_dense$density, 0.5)

  sparse <- Matrix::Matrix(c(0, 0, 3, 0), 2, 2, sparse = TRUE)
  summary_sparse <- drmTMB:::fixed_effect_design_summary(list(sigma = sparse))
  expect_equal(summary_sparse$matrix_class, "dtCMatrix")
  expect_equal(summary_sparse$n_nonzero, 1)
  expect_equal(drmTMB:::fixed_effect_design_nonzero(sparse), 1L)
  expect_equal(drmTMB:::fixed_effect_design_nonzero(dense), 2L)

  empty <- drmTMB:::fixed_effect_design_summary(list())
  expect_equal(nrow(empty), 0L)
  bad <- drmTMB:::fixed_effect_design_summary(list(mu = 1:3))
  expect_equal(nrow(bad), 0L)
})

test_that("check_fit_input_data requires aligned data frames", {
  object <- list(
    model = list(
      keep = c(TRUE, TRUE),
      input_data = data.frame(y = 1:2)
    )
  )
  expect_equal(drmTMB:::check_fit_input_data(object), object$model$input_data)
  expect_null(drmTMB:::check_fit_input_data(list(model = list(keep = c(TRUE, TRUE, TRUE)))))
  object$model$input_data <- data.frame(y = 1:3)
  expect_null(drmTMB:::check_fit_input_data(object))
  expect_null(drmTMB:::check_fit_input_data(list(model = list())))
})

test_that("check_random_grouping_variables collects unique bar names", {
  object <- list(
    model = list(
      random = list(
        list(group_names = c("id", "site")),
        list(group_names = "id"),
        "not_a_block"
      )
    )
  )
  expect_equal(
    sort(drmTMB:::check_random_grouping_variables(object)),
    c("id", "site")
  )
  expect_equal(drmTMB:::check_random_grouping_variables(list(model = list())), character())
})

test_that("check_dropped_group_levels flags levels with no kept rows", {
  object <- list(
    model = list(
      keep = c(TRUE, FALSE, FALSE),
      input_data = data.frame(
        id = factor(c("a", "a", "b"), levels = c("a", "b", "c")),
        y = 1:3
      ),
      random = list(list(group_names = "id"))
    )
  )
  dropped <- drmTMB:::check_dropped_group_levels(object)
  expect_equal(nrow(dropped), 1L)
  expect_equal(dropped$variable, "id")
  expect_equal(dropped$example, "b")
  expect_equal(dropped$n_lost, 1L)

  object$model$keep <- c(TRUE, TRUE, TRUE)
  expect_equal(nrow(drmTMB:::check_dropped_group_levels(object)), 0L)
  object$model$keep <- NULL
  expect_equal(
    drmTMB:::check_dropped_group_levels(object),
    drmTMB:::empty_dropped_groups()
  )
})

test_that("check_dropped_rows reports row and group losses", {
  base <- list(
    model = list(
      keep = c(TRUE, FALSE, FALSE),
      input_data = data.frame(
        id = c("a", "b", "b"),
        y = 1:3
      ),
      random = list(list(group_names = "id"))
    )
  )
  row <- drmTMB:::check_dropped_rows(base)
  expect_equal(row$check, "dropped_rows")
  expect_match(row$value, "dropped=2")
  expect_match(row$message, "grouping variable")

  no_keep <- list(model = list())
  note <- drmTMB:::check_dropped_rows(no_keep)
  expect_equal(note$status, "note")
  expect_match(note$message, "not stored")
})