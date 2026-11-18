binomial_nonlogit_animal_iid_fixture <- function(link, seed, animal_slope = FALSE) {
  set.seed(seed)
  n_id <- 192L
  n_site <- 96L
  n_each <- 24L
  id_levels <- paste0("id", seq_len(n_id))
  site_levels <- paste0("site", seq_len(n_site))
  site_by_id <- sample(rep(site_levels, each = n_id / n_site))
  z_animal <- stats::setNames(seq(-1, 1, length.out = n_id), id_levels)
  z_iid <- stats::setNames(seq(-0.8, 0.8, length.out = n_site), site_levels)

  kernel_order <- rev(seq_len(n_id))
  A <- outer(kernel_order, kernel_order, function(i, j) 0.2^abs(i - j))
  dimnames(A) <- list(id_levels[kernel_order], id_levels[kernel_order])
  animal_sd <- exp(-0.7 + 0.75 * z_animal)
  animal_draw <- as.vector(t(chol(A)) %*% stats::rnorm(n_id))
  names(animal_draw) <- rownames(A)
  animal_draw <- animal_draw * animal_sd[names(animal_draw)]
  animal_draw <- animal_draw[id_levels]

  iid_sd <- exp(-0.8 - 0.65 * z_iid)
  iid_draw <- stats::setNames(stats::rnorm(n_site, sd = iid_sd), site_levels)
  id_index <- rep(seq_len(n_id), each = n_each)
  site_index <- match(site_by_id[id_index], site_levels)
  id <- factor(id_levels[id_index], levels = id_levels)
  site <- factor(site_levels[site_index], levels = site_levels)
  x <- stats::rnorm(length(id))
  animal_effect <- animal_draw[as.character(id)]
  if (isTRUE(animal_slope)) {
    animal_effect <- x * animal_effect
  }
  eta <- -0.2 + 0.3 * x + animal_effect +
    iid_draw[as.character(site)]
  probability <- stats::binomial(link = link)$linkinv(eta)
  y <- stats::rbinom(length(id), size = 1L, prob = probability)
  data <- data.frame(
    y = y,
    x = x,
    id = id,
    site = site,
    z_animal = unname(z_animal[as.character(id)]),
    z_iid = unname(z_iid[as.character(site)])
  )
  list(data = data, A = A, z_animal = z_animal, z_iid = z_iid)
}

test_that("Binomial probit and cloglog animal plus IID SD regressions recover both targets", {
  skip_on_cran()
  for (link in c("probit", "cloglog")) {
    fx <- binomial_nonlogit_animal_iid_fixture(
      link = link,
      seed = if (link == "probit") 20261030L else 20261031L
    )
    A <- fx$A
    fit <- drmTMB(
      bf(
        y ~ x + animal(1 | id, A = A) + (1 | site),
        sd(id, level = "animal") ~ z_animal,
        sd(site) ~ z_iid
      ),
      family = stats::binomial(link = link),
      data = fx$data,
      control = drm_control(se = FALSE)
    )

    expect_equal(fit$opt$convergence, 0L, info = link)
    expect_true(is.finite(as.numeric(logLik(fit))), info = link)
    expect_setequal(names(coef(fit)), c("mu", "sd_animal(id)", "sd(site)"))
    animal_coef <- coef(fit, "sd_animal(id)")
    iid_coef <- coef(fit, "sd(site)")
    expect_gt(animal_coef[["z_animal"]], 0)
    expect_lt(iid_coef[["z_iid"]], 0)
    expect_lt(abs(animal_coef[["z_animal"]] - 0.75), 0.5)
    expect_lt(abs(iid_coef[["z_iid"]] + 0.65), 0.5)

    animal_prediction <- predict(fit, dpar = "sd_animal(id)")
    iid_prediction <- predict(fit, dpar = "sd(site)")
    expect_length(animal_prediction, 192L)
    expect_length(iid_prediction, 96L)
    expect_true(all(is.finite(animal_prediction) & animal_prediction > 0))
    expect_true(all(is.finite(iid_prediction) & iid_prediction > 0))
    expect_equal(
      unname(animal_prediction),
      unname(fit$sdpars[["sd_animal(id)"]]),
      tolerance = 1e-10
    )
    expect_equal(
      unname(iid_prediction),
      unname(fit$sdpars[["sd(site)"]]),
      tolerance = 1e-10
    )
  }
})

test_that("Binomial probit and cloglog animal-slope plus IID SD regressions recover both targets", {
  skip_on_cran()
  for (link in c("probit", "cloglog")) {
    fx <- binomial_nonlogit_animal_iid_fixture(
      link = link,
      seed = if (link == "probit") 20261101L else 20261102L,
      animal_slope = TRUE
    )
    A <- fx$A
    fit <- drmTMB(
      bf(
        y ~ x + animal(0 + x | id, A = A) + (1 | site),
        sd(id, level = "animal") ~ z_animal,
        sd(site) ~ z_iid
      ),
      family = stats::binomial(link = link),
      data = fx$data,
      control = drm_control(se = FALSE)
    )

    expect_equal(fit$opt$convergence, 0L, info = link)
    expect_true(is.finite(as.numeric(logLik(fit))), info = link)
    animal_coef <- coef(fit, "sd_animal(id)")
    iid_coef <- coef(fit, "sd(site)")
    expect_gt(animal_coef[["z_animal"]], 0)
    expect_lt(iid_coef[["z_iid"]], 0)
    expect_lt(abs(animal_coef[["z_animal"]] - 0.75), 0.5)
    expect_lt(abs(iid_coef[["z_iid"]] + 0.65), 0.5)
    expect_length(predict(fit, dpar = "sd_animal(id)"), 192L)
    expect_length(predict(fit, dpar = "sd(site)"), 96L)
    expect_true(all(predict(fit, dpar = "sd_animal(id)") > 0))
    expect_true(all(predict(fit, dpar = "sd(site)") > 0))
  }
})
