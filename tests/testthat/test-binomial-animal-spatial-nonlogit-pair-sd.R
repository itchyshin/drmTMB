test_that("Binomial animal and coordinate-spatial SD regressions support probit and cloglog", {
  skip_on_cran()

  for (link_index in seq_along(c("probit", "cloglog"))) {
    link <- c("probit", "cloglog")[[link_index]]
    set.seed(2026102714L + link_index)
    n_animal <- 32L
    n_site <- 72L
    n_rep <- 6L
    animal_levels <- paste0("animal_", seq_len(n_animal))
    site_levels <- paste0("site_", seq_len(n_site))
    animal_order <- rev(seq_len(n_animal))
    A <- outer(animal_order, animal_order, function(i, j) 0.35^abs(i - j))
    dimnames(A) <- list(animal_levels[animal_order], animal_levels[animal_order])
    coords <- cbind(
      east = seq(0, 1, length.out = n_site),
      north = cos(seq(0, 2 * pi, length.out = n_site))
    )
    rownames(coords) <- site_levels
    spatial_precision <- drmTMB:::drm_spatial_coords_precision(
      coords, site = site_levels, group = "site"
    )
    spatial_cov <- solve(as.matrix(spatial_precision$precision))
    z_animal <- sample(rep(c(-1, 1), length.out = n_animal))
    z_site <- sample(rep(c(-1, 1), length.out = n_site))
    alpha_animal <- c(`(Intercept)` = log(0.35), z_animal = 0.45)
    alpha_spatial <- c(`(Intercept)` = log(0.30), z_site = 0.55)
    sd_animal <- exp(alpha_animal[[1L]] + alpha_animal[[2L]] * z_animal)
    sd_site <- exp(alpha_spatial[[1L]] + alpha_spatial[[2L]] * z_site)
    animal_field_order <- as.vector(t(chol(A)) %*% stats::rnorm(n_animal)) *
      sd_animal[animal_order]
    site_field <- as.vector(t(chol(spatial_cov)) %*% stats::rnorm(n_site)) *
      sd_site
    names(animal_field_order) <- animal_levels[animal_order]
    names(site_field) <- site_levels
    animal_field <- animal_field_order[animal_levels]

    design <- expand.grid(
      replicate = seq_len(n_rep),
      animal_index = seq_len(n_animal),
      site_index = seq_len(n_site)
    )
    x <- stats::rnorm(nrow(design))
    eta <- -0.1 + 0.25 * x +
      animal_field[animal_levels[design$animal_index]] +
      site_field[site_levels[design$site_index]]
    probability <- if (link == "probit") {
      stats::pnorm(eta)
    } else {
      -expm1(-exp(eta))
    }
    dat <- data.frame(
      y = stats::rbinom(nrow(design), 1L, probability),
      x = x,
      animal_id = factor(animal_levels[design$animal_index], levels = animal_levels),
      site = factor(site_levels[design$site_index], levels = site_levels),
      z_animal = z_animal[design$animal_index],
      z_site = z_site[design$site_index]
    )

    fit <- drmTMB(
      bf(
        y ~ x + animal(1 | animal_id, A = A) +
          spatial(1 | site, coords = coords),
        sd(animal_id, level = "animal") ~ z_animal,
        sd(site, level = "spatial") ~ z_site
      ),
      family = stats::binomial(link = link),
      data = dat,
      control = drm_control(se = FALSE)
    )

    animal_coef <- coef(fit, dpar = "sd_animal(animal_id)")
    spatial_coef <- coef(fit, dpar = "sd_spatial(site)")
    expect_identical(fit$opt$convergence, 0L, info = link)
    expect_true(animal_coef[["z_animal"]] > 0, info = paste(link, "animal SD"))
    expect_lt(abs(animal_coef[["z_animal"]] - 0.45), 0.65)
    expect_true(spatial_coef[["z_site"]] > 0, info = paste(link, "spatial SD"))
    expect_lt(abs(spatial_coef[["z_site"]] - 0.55), 0.65)
    expect_setequal(names(predict(fit, dpar = "sd_animal(animal_id)")), animal_levels)
    expect_setequal(names(predict(fit, dpar = "sd_spatial(site)")), site_levels)
    simulated <- simulate(fit, nsim = 1L, seed = 2026102716L + link_index)
    expect_true(all(unlist(simulated, use.names = FALSE) %in% 0:1), info = link)
  }
})
