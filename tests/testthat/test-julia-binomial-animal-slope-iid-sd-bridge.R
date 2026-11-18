test_that("the Julia Binomial animal-slope plus IID SD route is narrowly admitted", {
  A <- outer(seq_len(4L), seq_len(4L), function(i, j) 0.4^abs(i - j))
  Ainv <- solve(A)
  dat <- data.frame(
    y = rep(c(0L, 1L), 12L),
    x = rep(c(-1, 0.5, 1), 8L),
    z = rep(c(-1, 1), each = 12L),
    w = rep(c(-1, 1), each = 12L),
    animal_id = factor(rep(letters[1:4], each = 6L)),
    site = factor(rep(LETTERS[1:6], times = 4L)),
    block = factor(rep(1:3, times = 8L))
  )
  form_A <- bf(
    y ~ x + animal(0 + x | animal_id, A = A) + (1 | site),
    sd(animal_id, level = "animal") ~ z,
    sd(site) ~ w
  )
  form_Ainv <- bf(
    y ~ x + animal(0 + x | animal_id, Ainv = Ainv) + (1 | site),
    sd(animal_id, level = "animal") ~ z,
    sd(site) ~ w
  )

  expect_true(drm_julia_binomial_animal_iid_sd_route_admitted(form_A))
  expect_true(drm_julia_binomial_animal_iid_sd_route_admitted(form_Ainv))
  for (link in c("logit", "probit", "cloglog")) {
    expected_tag <- if (link == "logit") "binomial" else paste0("binomial_", link)
    expect_identical(
      drm_julia_structured_family_tag("binomial", form_A, link = link),
      expected_tag
    )
  }
  expect_identical(
    drm_julia_structured_payload(form_A, "binomial", dat, environment())$kwarg,
    "A"
  )
  expect_identical(
    drm_julia_structured_payload(form_Ainv, "binomial", dat, environment())$kwarg,
    "Ainv"
  )

  intercept_slope <- bf(
    y ~ x + animal(1 + x | animal_id, A = A) + (1 | site),
    sd(animal_id, level = "animal") ~ z,
    sd(site) ~ w
  )
  extra_iid <- bf(
    y ~ x + animal(0 + x | animal_id, A = A) + (1 | site) + (1 | block),
    sd(animal_id, level = "animal") ~ z,
    sd(site) ~ w,
    sd(block) ~ 1
  )
  expect_false(drm_julia_binomial_animal_iid_sd_route_admitted(intercept_slope))
  expect_false(drm_julia_binomial_animal_iid_sd_route_admitted(extra_iid))
})

test_that("Julia and TMB recover Binomial animal-slope and IID SD regressions", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  n_animal <- 36L
  n_site <- 30L
  repeats <- 6L
  animal_index <- rep(seq_len(n_animal), each = n_site * repeats)
  site_index <- rep(rep(seq_len(n_site), each = repeats), times = n_animal)
  set.seed(202610270L)
  animal_levels <- paste0("animal_", seq_len(n_animal))
  site_levels <- paste0("site_", seq_len(n_site))
  z_levels <- sample(rep(c(-1, 1), each = n_animal / 2L))
  w_levels <- sample(rep(c(-1, 1), each = n_site / 2L))
  z <- z_levels[animal_index]
  w <- w_levels[site_index]
  x <- stats::rnorm(length(animal_index))
  A <- outer(seq_len(n_animal), seq_len(n_animal),
             function(i, j) 0.4^abs(i - j))
  dimnames(A) <- list(animal_levels, animal_levels)
  animal_alpha <- c(`(Intercept)` = log(0.55), z = 0.45)
  site_alpha <- c(`(Intercept)` = log(0.4), w = -0.45)
  animal_sd <- exp(animal_alpha[[1L]] + animal_alpha[[2L]] * z_levels)
  site_sd <- exp(site_alpha[[1L]] + site_alpha[[2L]] * w_levels)
  animal_effect <- drop(t(chol(tcrossprod(animal_sd) * A)) %*%
                          stats::rnorm(n_animal))
  site_effect <- site_sd * stats::rnorm(n_site)
  eta <- -0.2 + 0.3 * x + x * animal_effect[animal_index] +
    site_effect[site_index]
  data <- data.frame(
    x = x,
    z = z,
    w = w,
    animal_id = factor(animal_levels[animal_index], levels = animal_levels),
    site = factor(site_levels[site_index], levels = site_levels)
  )
  formula <- bf(
    y ~ x + animal(0 + x | animal_id, A = A) + (1 | site),
    sd(animal_id, level = "animal") ~ z,
    sd(site) ~ w
  )
  expect_true(drm_julia_binomial_animal_iid_sd_route_admitted(formula))

  for (link in c("logit", "probit", "cloglog")) {
    set.seed(if (link == "logit") 202610271L else if (link == "probit") 202610272L else 202610273L)
    data$y <- stats::rbinom(
      nrow(data), size = 1L,
      prob = stats::binomial(link = link)$linkinv(eta)
    )
    fit_tmb <- drmTMB(
      formula, family = stats::binomial(link), data = data,
      engine = "tmb", control = drm_control(se = FALSE)
    )
    fit_julia <- drmTMB(
      formula, family = stats::binomial(link), data = data,
      engine = "julia"
    )
    animal_key <- "sd_animal(animal_id)"
    site_key <- "sd(site)"
    animal_tmb <- coef(fit_tmb, dpar = animal_key)
    animal_julia <- coef(fit_julia, dpar = animal_key)
    site_tmb <- coef(fit_tmb, dpar = site_key)
    site_julia <- coef(fit_julia, dpar = site_key)

    expect_true(is_converged(fit_tmb), info = paste(link, "TMB"))
    expect_true(is_converged(fit_julia), info = paste(link, "Julia"))
    expect_equal(unname(animal_tmb[["z"]]), animal_alpha[["z"]],
                 tolerance = 0.5, info = paste(link, "TMB animal recovery"))
    expect_equal(unname(animal_julia[["z"]]), animal_alpha[["z"]],
                 tolerance = 0.5, info = paste(link, "Julia animal recovery"))
    expect_equal(unname(site_tmb[["w"]]), site_alpha[["w"]],
                 tolerance = 0.5, info = paste(link, "TMB IID recovery"))
    expect_equal(unname(site_julia[["w"]]), site_alpha[["w"]],
                 tolerance = 0.5, info = paste(link, "Julia IID recovery"))
    expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
                 tolerance = 0.15, info = paste(link, "logLik"))
    animal_newdata <- data.frame(
      animal_id = factor(animal_levels, levels = animal_levels), z = z_levels
    )
    expect_equal(
      as.numeric(predict(fit_julia, newdata = animal_newdata, dpar = animal_key)),
      exp(unname(animal_julia[["(Intercept)"]] + animal_julia[["z"]] * z_levels)),
      tolerance = 1e-8, info = paste(link, "animal SD prediction")
    )
    simulated <- simulate(fit_julia, nsim = 1L, seed = 202610274L)
    expect_true(all(simulated[[1L]] %in% c(0L, 1L)), info = paste(link, "simulation"))
    if (identical(link, "cloglog")) {
      roundtrip_path <- tempfile(fileext = ".rds")
      saveRDS(fit_julia, roundtrip_path)
      roundtrip <- readRDS(roundtrip_path)
      unlink(roundtrip_path)
      expect_equal(coef(roundtrip, dpar = animal_key), animal_julia)
      expect_equal(
        as.numeric(predict(roundtrip, newdata = animal_newdata, dpar = animal_key)),
        as.numeric(predict(fit_julia, newdata = animal_newdata, dpar = animal_key))
      )
    }
  }
})
