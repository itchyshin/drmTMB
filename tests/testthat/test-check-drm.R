check_drm_test_tree <- function() {
  structure(
    list(
      edge = matrix(c(
        5, 6,
        5, 7,
        6, 1,
        6, 2,
        7, 3,
        7, 4
      ), ncol = 2, byrow = TRUE),
      edge.length = rep(1, 6),
      tip.label = paste0("sp_", 1:4),
      Nnode = 3L
    ),
    class = "phylo"
  )
}

test_that("check_drm() reports core diagnostics for Gaussian fits", {
  set.seed(20260508)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat
  )

  chk <- check_drm(fit)

  expect_s3_class(chk, "drm_check")
  expect_named(chk, c("check", "status", "value", "message"))
  expect_true(attr(chk, "ok"))
  expect_true(all(chk$status == "ok"))
  expect_true(all(c(
    "optimizer_convergence",
    "finite_objective",
    "fixed_gradient",
    "hessian_positive_definite",
    "dropped_rows",
    "positive_scale"
  ) %in% chk$check))
  printed <- NULL
  messages <- capture.output(
    printed <- capture.output(print(chk)),
    type = "message"
  )
  expect_match(paste(c(messages, printed), collapse = "\n"), "<drm_check")
})

test_that("check_drm() records dropped rows as notes", {
  dat <- data.frame(
    y = c(0.1, 0.3, NA, 0.5, 0.7, 0.9),
    x = c(-1, -0.5, 0, 0.5, NA, 1)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  chk <- check_drm(fit)
  dropped <- chk[chk$check == "dropped_rows", ]

  expect_true(attr(chk, "ok"))
  expect_equal(dropped$status, "note")
  expect_match(dropped$value, "dropped=2")
})

test_that("check_drm() warns when residual rho12 is near a requested boundary", {
  set.seed(20260509)
  n <- 220
  dat <- data.frame(
    x = stats::rnorm(n),
    y1 = stats::rnorm(n)
  )
  dat$y2 <- 0.7 * dat$y1 + sqrt(1 - 0.7^2) * stats::rnorm(n)

  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~ 1),
    family = c(gaussian(), gaussian()),
    data = dat
  )
  chk <- check_drm(fit, rho_boundary = 0.2)
  rho_row <- chk[chk$check == "rho12_boundary", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(rho_row$status, "warning")
  expect_false(attr(chk, "ok"))
})

test_that("check_drm() reports random-effect replication notes", {
  set.seed(20260510)
  dat <- data.frame(
    id = factor(c("a", "a", "b", "b", "c", "d", "d", "e", "e", "e")),
    x = stats::rnorm(10)
  )
  dat$y <- 0.2 + 0.4 * dat$x +
    c(a = -0.2, b = 0.1, c = 0.3, d = -0.1, e = 0.2)[dat$id] +
    stats::rnorm(10, sd = 0.15)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  replication <- chk[chk$check == "mu_random_effect_replication", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(replication$status, "note")
  expect_match(replication$message, "one fitted observation")
})

test_that("check_drm() reports weak random-slope design notes", {
  set.seed(20260511)
  id <- factor(rep(letters[1:8], each = 3))
  x <- rep(seq(-1, 1, length.out = 8), each = 3)
  dat <- data.frame(id = id, x = x)
  dat$y <- 0.3 + 0.5 * dat$x +
    rep(stats::rnorm(8, sd = 0.2), each = 3) +
    stats::rnorm(nrow(dat), sd = 0.2)

  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  design <- chk[chk$check == "mu_random_effect_design", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(design$status, "note")
  expect_match(design$message, "weak within-group design variation")
  expect_true(attr(chk, "ok"))
})

test_that("check_drm() records known sampling covariance summaries", {
  set.seed(20260512)
  n <- 24
  dat <- data.frame(x = stats::rnorm(n))
  V <- 0.015 * outer(seq_len(n), seq_len(n), function(i, j) 0.35^abs(i - j))
  dat$yi <- stats::rnorm(n)

  fit <- drmTMB(
    bf(yi ~ x + meta_known_V(V = V)),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  known_v <- chk[chk$check == "known_sampling_covariance", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(known_v$status, "ok")
  expect_match(known_v$value, "type=matrix")
  expect_match(known_v$value, "rank=24")
})

test_that("check_drm() records phylogenetic replication notes", {
  set.seed(20260513)
  tree <- check_drm_test_tree()
  dat <- data.frame(
    species = factor(c("sp_1", "sp_2", "sp_2", "sp_3", "sp_3", "sp_4", "sp_4")),
    x = c(-1, -0.5, 0.5, -0.2, 0.3, -0.1, 0.7)
  )
  dat$y <- 0.2 + 0.4 * dat$x +
    c(sp_1 = -0.1, sp_2 = 0.2, sp_3 = 0.05, sp_4 = -0.2)[dat$species] +
    stats::rnorm(nrow(dat), sd = 0.15)

  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  phylo <- chk[chk$check == "phylo_mu_replication", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(phylo$status, "note")
  expect_match(phylo$value, "min_species_n=1")
  expect_true(attr(chk, "ok"))
})

test_that("check_drm() reports mutated diagnostic failure branches", {
  dat <- data.frame(y = stats::rnorm(24), x = stats::rnorm(24))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  nonconverged <- fit
  nonconverged$opt$convergence <- 1L
  nonconverged$opt$message <- "test convergence failure"
  convergence <- check_drm(nonconverged)
  convergence <- convergence[convergence$check == "optimizer_convergence", ]
  expect_equal(convergence$status, "warning")
  expect_match(convergence$message, "test convergence failure")

  nonfinite <- fit
  nonfinite$opt$objective <- Inf
  objective <- check_drm(nonfinite)
  objective <- objective[objective$check == "finite_objective", ]
  expect_equal(objective$status, "error")

  gradient_error <- fit
  gradient_error$obj$gr <- function(par) {
    stop("test gradient failure")
  }
  gradient <- check_drm(gradient_error)
  gradient <- gradient[gradient$check == "fixed_gradient", ]
  expect_equal(gradient$status, "warning")
  expect_match(gradient$message, "test gradient failure")

  bad_gradient <- fit
  bad_gradient$obj$gr <- function(par) {
    c(NA_real_, 0)
  }
  gradient <- check_drm(bad_gradient)
  gradient <- gradient[gradient$check == "fixed_gradient", ]
  expect_equal(gradient$status, "error")

  bad_hessian <- fit
  bad_hessian$sdr$pdHess <- FALSE
  hessian <- check_drm(bad_hessian)
  hessian <- hessian[hessian$check == "hessian_positive_definite", ]
  expect_equal(hessian$status, "warning")

  bad_scale <- fit
  bad_scale$model$model_type <- "broken"
  scale <- check_drm(bad_scale)
  scale <- scale[scale$check == "positive_scale", ]
  expect_equal(scale$status, "warning")
})

test_that("check_drm() validates scalar diagnostic thresholds", {
  dat <- data.frame(y = stats::rnorm(20))
  fit <- drmTMB(bf(y ~ 1), family = gaussian(), data = dat)

  expect_error(check_drm(fit, gradient_tolerance = 0), "gradient_tolerance")
  expect_error(check_drm(fit, rho_boundary = 1), "rho_boundary")
  expect_error(check_drm(fit, unknown_option = TRUE), "reserved")
})
