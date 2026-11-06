student_sd_assembly_data <- function(groups = 12L, repeats = 4L) {
  group_index <- rep(seq_len(groups), each = repeats)
  group_w <- seq(-1, 1, length.out = groups)
  data.frame(
    y = sin(seq_along(group_index) / 3),
    x = cos(seq_along(group_index) / 5),
    w = group_w[group_index],
    id = factor(group_index)
  )
}

test_that("Student rejects unimplemented phylogenetic SD regressions", {
  dat <- student_sd_assembly_data()
  dat$species <- dat$id

  expect_error(
    drm_build_student_ls_spec(
      bf(
        y ~ x + (1 | species),
        sigma ~ 1,
        nu ~ 1,
        sd(species, level = "phylogenetic") ~ w
      ),
      dat
    ),
    "Student-t.*phylogenetic.*SD"
  )
})

test_that("Student ordinary intercept SD assembles the group predictor", {
  dat <- student_sd_assembly_data()
  spec <- drm_build_student_ls_spec(
    bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w),
    dat
  )

  expect_identical(spec$model_type, "student")
  expect_identical(spec$random_scale$mu$dpars, "sd(id)")
  expect_identical(spec$random_scale$mu$n_models, 1L)
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$dpar,
                   "mu")
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$coef,
                   "(Intercept)")
  expect_equal(
    unname(spec$random_scale$mu$X_list[["sd(id)"]][, "w"]),
    seq(-1, 1, length.out = 12L)
  )
  expect_identical(
    spec$random_scale$mu$re_sd_row0,
    seq_len(spec$random$mu$n_re) - 1L
  )
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_equal(spec$tmb_data$X_sd_mu, spec$random_scale$mu$X,
               ignore_attr = TRUE)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_true(all(is.na(spec$map$log_sd_mu)))
  expect_identical(spec$dpars, c("mu", "sigma", "nu", "sd(id)"))
  par_list <- spec$start
  par_list$beta_sd_mu <- c(0.1, 0.2)
  expect_equal(
    split_tmb_parameters(par_list, spec)[["sd(id)"]],
    c("(Intercept)" = 0.1, w = 0.2)
  )
})

test_that("Student independent-slope SD resolves to the slope coefficient", {
  dat <- student_sd_assembly_data()
  spec <- drm_build_student_ls_spec(
    bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
       sd(id, dpar = "mu", coef = "x") ~ w),
    dat
  )
  key <- 'sd(id, dpar = "mu", coef = "x")'

  expect_identical(spec$random_scale$mu$dpars, key)
  expect_identical(spec$random_scale$mu$target_identity[[key]]$dpar, "mu")
  expect_identical(spec$random_scale$mu$target_identity[[key]]$coef, "x")
  expect_identical(spec$random_scale$mu$re_sd_row0,
                   seq_len(spec$random$mu$n_re) - 1L)
  expect_equal(
    unname(spec$random_scale$mu$X_list[[key]][, "w"]),
    seq(-1, 1, length.out = 12L)
  )
})

test_that("Student SD regression rejects unsupported scale designs", {
  dat <- student_sd_assembly_data()
  expect_error(
    drm_build_student_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1,
         sd(id, dpar = "sigma") ~ w),
      dat
    ),
    "currently support only the.*mu.*endpoint"
  )
  expect_error(
    drm_build_student_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1,
         sd(id, dpar = "nu") ~ w),
      dat
    ),
    "currently support only the.*mu.*endpoint"
  )
  expect_error(
    drm_build_student_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1,
         sd(id) ~ w + (1 | id)),
      dat
    ),
    "unsupported model terms"
  )
  expect_error(
    drm_build_student_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ offset(w)),
      dat
    ),
    "unsupported model terms"
  )
  expect_error(
    drm_build_student_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id), nu ~ 1,
         sd(id) ~ w),
      dat
    ),
    "sigma.*random effects"
  )
  expect_error(
    drm_build_student_ls_spec(
      bf(y ~ x + (1 + x | id), sigma ~ 1, nu ~ 1,
         sd(id) ~ w),
      dat
    ),
    "Only independent.*random intercepts and slopes"
  )
})

test_that("Student SD regression resolves an explicit ordinary target", {
  dat <- student_sd_assembly_data()
  spec <- drm_build_student_ls_spec(
    bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1,
       sd(id, dpar = "mu", coef = "(Intercept)") ~ w),
    dat
  )
  key <- 'sd(id, dpar = "mu", coef = "(Intercept)")'

  expect_identical(spec$random_scale$mu$dpars, key)
  expect_identical(spec$random_scale$mu$target_identity[[key]]$dpar, "mu")
  expect_identical(spec$random_scale$mu$target_identity[[key]]$coef,
                   "(Intercept)")
})
