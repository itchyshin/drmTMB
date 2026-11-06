test_that("probit and cloglog animal-plus-IID SD regression uses the selected link", {
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
  set.seed(202610300L)
  animal_levels <- paste0("animal_", seq_len(n_animal))
  site_levels <- paste0("site_", seq_len(n_site))
  z_levels <- sample(rep(c(-1, 1), each = n_animal / 2L))
  w_levels <- sample(rep(c(-1, 1), each = n_site / 2L))
  z <- z_levels[animal_index]
  w <- w_levels[site_index]
  x <- stats::rnorm(length(animal_index))
  A <- outer(seq_len(n_animal), seq_len(n_animal),
             function(i, j) 0.45^abs(i - j))
  dimnames(A) <- list(animal_levels, animal_levels)
  animal_alpha <- c(`(Intercept)` = -0.75, z = 0.5)
  site_alpha <- c(`(Intercept)` = -0.35, w = -0.5)
  animal_sd <- exp(animal_alpha[[1L]] + animal_alpha[[2L]] * z_levels)
  site_sd <- exp(site_alpha[[1L]] + site_alpha[[2L]] * w_levels)
  animal_cov <- tcrossprod(animal_sd) * A
  animal_effect <- drop(t(chol(animal_cov)) %*% stats::rnorm(n_animal))
  site_effect <- site_sd * stats::rnorm(n_site)
  eta <- -0.2 + 0.3 * x + animal_effect[animal_index] + site_effect[site_index]
  data <- data.frame(
    x = x,
    z = z,
    w = w,
    animal_id = factor(animal_levels[animal_index], levels = animal_levels),
    site = factor(site_levels[site_index], levels = site_levels)
  )
  formula <- bf(
    y ~ x + animal(1 | animal_id, A = A) + (1 | site),
    sd(animal_id, level = "animal") ~ z,
    sd(site) ~ w
  )
  expect_true(drm_julia_binomial_animal_iid_sd_route_admitted(formula))

  for (link in c("probit", "cloglog")) {
    expect_identical(
      drm_julia_structured_family_tag("binomial", formula, link = link),
      paste0("binomial_", link),
      info = link
    )
    set.seed(if (link == "probit") 202610301L else 202610302L)
    data$y <- stats::rbinom(
      nrow(data), size = 1L,
      prob = stats::binomial(link = link)$linkinv(eta)
    )
    fit_tmb <- drmTMB(
      formula, family = stats::binomial(link), data = data,
      engine = "tmb", control = drm_control(se = FALSE)
    )
    fit_julia <- drmTMB(
      formula, family = stats::binomial(link), data = data, engine = "julia"
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
                 tolerance = 0.1, info = link)

    animal_newdata <- data.frame(
      animal_id = factor(animal_levels, levels = animal_levels), z = z_levels
    )
    site_newdata <- data.frame(
      site = factor(site_levels, levels = site_levels), w = w_levels
    )
    animal_sd_julia <- predict(
      fit_julia, newdata = animal_newdata, dpar = animal_key
    )
    animal_sd_tmb <- predict(fit_tmb, newdata = animal_newdata, dpar = animal_key)
    site_sd_julia <- predict(fit_julia, newdata = site_newdata, dpar = site_key)
    site_sd_tmb <- predict(fit_tmb, newdata = site_newdata, dpar = site_key)
    expect_equal(
      as.numeric(animal_sd_julia),
      exp(unname(animal_julia[["(Intercept)"]] + animal_julia[["z"]] * z_levels)),
      tolerance = 1e-8, info = paste(link, "animal SD prediction")
    )
    expect_equal(
      as.numeric(site_sd_julia),
      exp(unname(site_julia[["(Intercept)"]] + site_julia[["w"]] * w_levels)),
      tolerance = 1e-8, info = paste(link, "IID SD prediction")
    )
    expect_equal(as.numeric(animal_sd_julia), as.numeric(animal_sd_tmb),
                 tolerance = 0.2, info = paste(link, "animal SD parity"))
    expect_equal(as.numeric(site_sd_julia), as.numeric(site_sd_tmb),
                 tolerance = 0.2, info = paste(link, "IID SD parity"))
  }
})

test_that("Julia Binomial animal-plus-IID SD bridge accepts pedigree input", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(202610291L)
  n_family <- 10L
  offspring_per_family <- 6L
  n_animal <- n_family * offspring_per_family
  n_site <- 12L
  repeats <- 3L
  sires <- sprintf("sire-%02d", seq_len(n_family))
  dams <- sprintf("dam-%02d", seq_len(n_family))
  animal_levels <- sprintf("offspring-%03d", seq_len(n_animal))
  pedigree <- data.frame(
    id = c(sires, dams, animal_levels),
    dam = c(rep(NA_character_, 2L * n_family),
            rep(dams, each = offspring_per_family)),
    sire = c(rep(NA_character_, 2L * n_family),
             rep(sires, each = offspring_per_family)),
    stringsAsFactors = FALSE
  )
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  A <- A[animal_levels, animal_levels, drop = FALSE]
  grid <- expand.grid(
    animal = seq_len(n_animal), site = seq_len(n_site),
    replicate = seq_len(repeats)
  )
  animal_index <- grid$animal
  site_index <- grid$site
  z_levels <- seq(-1, 1, length.out = n_animal)
  w_levels <- seq(-1, 1, length.out = n_site)
  z <- z_levels[animal_index]
  w <- w_levels[site_index]
  x <- stats::rnorm(nrow(grid))
  animal_alpha <- c(`(Intercept)` = -0.7, z = 0.35)
  site_alpha <- c(`(Intercept)` = -0.4, w = -0.3)
  animal_sd <- exp(animal_alpha[[1L]] + animal_alpha[[2L]] * z_levels)
  site_sd <- exp(site_alpha[[1L]] + site_alpha[[2L]] * w_levels)
  animal_effect <- drop(t(chol(A)) %*% stats::rnorm(n_animal)) * animal_sd
  site_effect <- stats::rnorm(n_site) * site_sd
  eta <- -0.15 + 0.25 * x + animal_effect[animal_index] +
    site_effect[site_index]
  data <- data.frame(
    x = x,
    z = z,
    w = w,
    id = factor(animal_levels[animal_index], levels = animal_levels),
    site = factor(sprintf("site-%02d", site_index),
                  levels = sprintf("site-%02d", seq_len(n_site))),
    y = stats::rbinom(nrow(grid), size = 1L, prob = stats::plogis(eta))
  )
  formula <- bf(
    y ~ x + animal(1 | id, pedigree = pedigree) + (1 | site),
    sd(id, level = "animal") ~ z,
    sd(site) ~ w
  )
  expect_true(drm_julia_binomial_animal_iid_sd_route_admitted(formula))
  payload <- drm_julia_structured_payload(
    formula, "binomial", data, environment()
  )
  expect_identical(payload$kwarg, "A")
  expect_equal(unname(payload$matrix), unname(A), tolerance = 0)

  fit_tmb <- drmTMB(formula, family = stats::binomial(), data = data,
                    engine = "tmb", control = drm_control(se = FALSE))
  fit_julia <- drmTMB(formula, family = stats::binomial(), data = data,
                      engine = "julia")
  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(coef(fit_julia, dpar = "sd_animal(id)"),
               names(coef(fit_tmb, dpar = "sd_animal(id)")))
  expect_named(coef(fit_julia, dpar = "sd(site)"),
               names(coef(fit_tmb, dpar = "sd(site)")))
  expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
               tolerance = 0.1)
  animal_newdata <- data.frame(
    id = factor(animal_levels, levels = animal_levels), z = z_levels
  )
  site_newdata <- data.frame(
    site = factor(sprintf("site-%02d", seq_len(n_site)),
                  levels = levels(data$site)),
    w = w_levels
  )
  expect_equal(
    as.numeric(predict(fit_julia, dpar = "sd_animal(id)",
                       newdata = animal_newdata)),
    as.numeric(predict(fit_tmb, dpar = "sd_animal(id)",
                       newdata = animal_newdata)),
    tolerance = 0.2
  )
  expect_equal(
    as.numeric(predict(fit_julia, dpar = "sd(site)", newdata = site_newdata)),
    as.numeric(predict(fit_tmb, dpar = "sd(site)", newdata = site_newdata)),
    tolerance = 0.2
  )
  draws <- simulate(fit_julia, nsim = 1L, seed = 202610292L)
  expect_equal(nrow(draws), nrow(data))
  expect_true(all(draws[[1L]] %in% c(0L, 1L)))
})
