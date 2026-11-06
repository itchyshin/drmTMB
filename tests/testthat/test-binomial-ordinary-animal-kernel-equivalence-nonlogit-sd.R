test_that("Binomial ordinary plus animal SDs agree across A, Ainv, and pedigree links", {
  skip_on_cran()

  set.seed(20261074L)
  n_family <- 8L
  n_offspring <- 5L
  sires <- paste0("sire_", seq_len(n_family))
  dams <- paste0("dam_", seq_len(n_family))
  offspring <- paste0("offspring_", seq_len(n_family * n_offspring))
  pedigree <- data.frame(
    id = c(sires, dams, offspring),
    dam = c(rep(NA_character_, 2L * n_family), rep(dams, each = n_offspring)),
    sire = c(rep(NA_character_, 2L * n_family), rep(sires, each = n_offspring)),
    stringsAsFactors = FALSE
  )
  A_base <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  animal_levels <- rownames(A_base)
  animal_order <- rev(seq_along(animal_levels))
  A <- A_base[animal_order, animal_order, drop = FALSE]
  Ainv <- solve(A)

  n_group <- 32L
  group_levels <- paste0("group_", seq_len(n_group))
  w_group <- setNames(sample(rep(c(-1, 1), length.out = n_group)), group_levels)
  z_animal <- setNames(
    sample(rep(c(-1, 1), length.out = length(animal_levels))), animal_levels
  )
  alpha_group <- c(`(Intercept)` = -0.9, w = 0.35)
  alpha_animal <- c(`(Intercept)` = log(0.35), z = 0.45)
  group_effect <- stats::rnorm(
    n_group, sd = exp(alpha_group[[1L]] + alpha_group[[2L]] * w_group)
  )
  names(group_effect) <- group_levels
  animal_field_order <- as.vector(
    t(chol(A)) %*% stats::rnorm(length(animal_levels))
  ) * exp(
    alpha_animal[[1L]] +
      alpha_animal[[2L]] * z_animal[animal_levels[animal_order]]
  )
  names(animal_field_order) <- animal_levels[animal_order]
  animal_field <- animal_field_order[animal_levels]

  design <- expand.grid(
    replicate = seq_len(2L),
    animal_index = seq_along(animal_levels),
    group_index = seq_len(n_group)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.25 * x +
    group_effect[group_levels[design$group_index]] +
    animal_field[animal_levels[design$animal_index]]
  dat <- data.frame(
    x = x,
    group_id = factor(group_levels[design$group_index], levels = group_levels),
    animal_id = factor(animal_levels[design$animal_index], levels = rev(animal_levels)),
    w = unname(w_group[group_levels[design$group_index]]),
    z = unname(z_animal[animal_levels[design$animal_index]])
  )

  fit_input <- function(y, link, input) {
    dat$y <- y
    formula <- switch(
      input,
      A = bf(
        y ~ x + (1 | group_id) + animal(1 | animal_id, A = A),
        sd(group_id) ~ w,
        sd(animal_id, level = "animal") ~ z
      ),
      Ainv = bf(
        y ~ x + (1 | group_id) + animal(1 | animal_id, Ainv = Ainv),
        sd(group_id) ~ w,
        sd(animal_id, level = "animal") ~ z
      ),
      pedigree = bf(
        y ~ x + (1 | group_id) + animal(1 | animal_id, pedigree = pedigree),
        sd(group_id) ~ w,
        sd(animal_id, level = "animal") ~ z
      )
    )
    drmTMB(
      formula, family = stats::binomial(link = link), data = dat,
      control = drm_control(se = FALSE)
    )
  }

  inverse_link <- list(
    probit = stats::pnorm,
    cloglog = function(eta) -expm1(-exp(eta))
  )
  for (link in names(inverse_link)) {
    y <- stats::rbinom(nrow(dat), 1L, inverse_link[[link]](eta))
    fit_a <- fit_input(y, link, "A")
    fit_ainv <- fit_input(y, link, "Ainv")
    fit_pedigree <- fit_input(y, link, "pedigree")

    expect_identical(fit_a$opt$convergence, 0L)
    expect_identical(fit_ainv$opt$convergence, 0L)
    expect_identical(fit_pedigree$opt$convergence, 0L)
    for (fit in list(fit_ainv, fit_pedigree)) {
      expect_equal(as.numeric(logLik(fit)), as.numeric(logLik(fit_a)), tolerance = 1e-5)
      expect_equal(
        coef(fit, "sd(group_id)"), coef(fit_a, "sd(group_id)"),
        tolerance = 1e-4
      )
      expect_equal(
        coef(fit, "sd_animal(animal_id)"),
        coef(fit_a, "sd_animal(animal_id)"), tolerance = 1e-4
      )
      expect_equal(
        unname(predict(fit, dpar = "sd_animal(animal_id)")[animal_levels]),
        unname(predict(fit_a, dpar = "sd_animal(animal_id)")[animal_levels]),
        tolerance = 1e-4
      )
    }
  }
})
