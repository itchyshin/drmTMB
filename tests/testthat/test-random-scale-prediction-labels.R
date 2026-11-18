test_that("random-scale prediction labels use each registered group's levels", {
  id_key <- "sd(id)"
  site_key <- 'sd(site, dpar = "mu", coef = "(Intercept)")'
  object <- list(
    model = list(random_scale = list(
      mu = list(
        dpars = c(id_key, site_key),
        group_levels_list = list(
          `sd(id)` = c("zeta", "alpha", "mu"),
          `sd(site, dpar = "mu", coef = "(Intercept)")` = c("site-9", "site-2")
        )
      ),
      phylo = list(
        dpars = "sd(tree)",
        group_levels_list = list(`sd(tree)` = c("tip-c", "tip-a", "tip-b"))
      )
    ))
  )

  expect_identical(
    predict_parameters_row_labels(NULL, 3L, object, id_key),
    c("zeta", "alpha", "mu")
  )
  expect_identical(
    predict_parameters_row_labels(NULL, 2L, object, site_key),
    c("site-9", "site-2")
  )
  expect_identical(
    predict_parameters_row_labels(NULL, 3L, object, "sd(tree)"),
    c("tip-c", "tip-a", "tip-b")
  )
})

test_that("ordinary and newdata row labels retain their existing contract", {
  object <- list(model = list(random_scale = list(
    mu = list(dpars = "sd(id)", group_levels_list = list(`sd(id)` = c("g1", "g2")))
  )))
  grid <- data.frame(x = 1:2, row.names = c("low", "high"))

  expect_identical(predict_parameters_row_labels(NULL, 3L), c("1", "2", "3"))
  expect_identical(
    predict_parameters_row_labels(NULL, 3L, object, "mu"),
    c("1", "2", "3")
  )
  expect_identical(
    predict_parameters_row_labels(grid, 2L, object, "sd(id)"),
    c("low", "high")
  )
})

test_that("registered random-scale labels must match prediction length", {
  object <- list(model = list(random_scale = list(
    mu = list(dpars = "sd(id)", group_levels_list = list(`sd(id)` = c("g1", "g2")))
  )))

  expect_error(
    predict_parameters_row_labels(NULL, 3L, object, "sd(id)"),
    "registered group labels.*length"
  )
})

test_that("the public parameter table retains different observation and group grains", {
  key <- 'sd(site, dpar = "mu", coef = "(Intercept)")'
  values <- list(mu = seq_len(6L), `sd(id)` = c(0.2, 0.4, 0.8))
  values[[key]] <- c(0.5, 1)
  object <- structure(list(
    coefficients = lapply(values, function(x) c(`(Intercept)` = 0)),
    model = list(random_scale = list(mu = list(
      dpars = c("sd(id)", key),
      group_levels_list = setNames(list(c("z", "a", "m"), c("s9", "s2")),
                                  c("sd(id)", key))
    )))
  ), class = "drmTMB")
  local_mocked_bindings(
    predict = function(object, newdata, dpar, type) values[[dpar]],
    .package = "drmTMB"
  )
  out <- predict_parameters(object, include_newdata = FALSE)
  expect_equal(table(out$dpar), table(rep(names(values), lengths(values))))
  expect_identical(out$row_label[out$dpar == "sd(id)"], c("z", "a", "m"))
  expect_identical(out$row_label[out$dpar == key], c("s9", "s2"))
  expect_identical(out$row_label[out$dpar == "mu"], as.character(seq_len(6L)))
})
