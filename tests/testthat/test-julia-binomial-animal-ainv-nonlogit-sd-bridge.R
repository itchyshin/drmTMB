test_that("probit and cloglog animal-intercept SD regression accepts Ainv", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  groups <- 80L
  repeats <- 32L
  id_levels <- paste0("id", seq_len(groups))
  correlation <- outer(seq_len(groups), seq_len(groups),
                       function(i, j) 0.35^abs(i - j))
  marginal_scale <- seq(0.8, 1.25, length.out = groups)
  A <- tcrossprod(marginal_scale) * correlation
  dimnames(A) <- list(id_levels, id_levels)
  set.seed(202610280L)
  z_group <- sample(rep(c(-1, 1), each = groups / 2L))
  alpha <- c(`(Intercept)` = -0.6, z = 0.5)
  latent_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
  set.seed(202610281L)
  latent <- as.vector(t(chol(A)) %*% stats::rnorm(groups)) * latent_sd
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_levels[id_index], levels = id_levels)
  z <- z_group[id_index]
  Ainv <- solve(A)
  formula <- bf(
    y ~ animal(1 | id, Ainv = Ainv),
    sd(id, level = "animal") ~ z
  )

  for (link in c("probit", "cloglog")) {
    expect_identical(
      drm_julia_structured_family_tag("binomial", formula, link = link),
      paste0("binomial_", link),
      info = link
    )
    set.seed(if (link == "probit") 202610282L else 202610283L)
    eta <- -0.2 + latent[id_index]
    probability <- stats::binomial(link = link)$linkinv(eta)
    data <- data.frame(
      y = stats::rbinom(length(id), size = 1L, prob = probability),
      z = z,
      id = id
    )
    fit_tmb <- drmTMB(
      formula, family = stats::binomial(link), data = data, engine = "tmb",
      control = drm_control(se = FALSE)
    )
    fit_julia <- drmTMB(
      formula, family = stats::binomial(link), data = data, engine = "julia"
    )

    target <- "sd_animal(id)"
    beta_tmb <- coef(fit_tmb, dpar = target)
    beta_julia <- coef(fit_julia, dpar = target)
    expect_true(is_converged(fit_tmb), info = link)
    expect_true(is_converged(fit_julia), info = link)
    expect_named(beta_julia, names(alpha), info = link)
    expect_lt(abs(unname(beta_tmb[["z"]] - alpha[["z"]])), 0.55)
    expect_lt(abs(unname(beta_julia[["z"]] - alpha[["z"]])), 0.55)
    expect_lt(abs(unname(beta_julia[["z"]] - beta_tmb[["z"]])), 0.35)
    expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
                 tolerance = 0.02)
    expect_equal(
      unname(predict(fit_julia, dpar = target)),
      unname(predict(fit_tmb, dpar = target)),
      tolerance = 0.03
    )
  }
})
