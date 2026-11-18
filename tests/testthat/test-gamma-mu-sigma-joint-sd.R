# Gamma joint ordinary mu + sigma random intercepts, each with its own SD
# regression:
#   bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g),
#      sd(id) ~ w, sd(g, dpar = "sigma") ~ z), family = Gamma(link = "log").
#
# Oracle: dense Laplace over the JOINT random-effect vector (all id levels and
# all g levels together), written without drmTMB internals, with exact
# per-observation score and information (digamma/trigamma) and a Newton mode
# search. Tolerance fixed before the first run: |logLik(fit) - oracle| < 1e-4
# (absolute). Every emulated bug must move the oracle by more than 1
# log-likelihood unit (1e4 times the tolerance).
# Structured providers (K, A, phylo) are not part of this slice, so the
# non-unit-diagonal K check does not apply; levels are shuffled instead.

joint_fixture <- function(seed = 20261112L, n_id = 30L, n_g = 24L,
                          n = 480L, same_group = FALSE) {
  set.seed(seed)
  id_lab <- sprintf("g%02d", seq_len(n_id))
  g_lab <- if (same_group) id_lab else sprintf("s%02d", seq_len(n_g))
  n_g <- length(g_lab)
  # Unbalanced, crossed assignment; every level observed.
  id_i <- c(seq_len(n_id), sample(n_id, n - n_id, TRUE))
  g_i <- if (same_group) id_i else c(seq_len(n_g), sample(n_g, n - n_g, TRUE))
  w <- as.numeric(scale(sin(seq_len(n_id) * 1.7)))
  z <- as.numeric(scale(cos(seq_len(n_g) * 0.9 + 1)))
  a_mu <- c(log(0.45), 0.7)
  a_sg <- c(log(0.35), -0.8)
  u <- rnorm(n_id, sd = exp(a_mu[1] + a_mu[2] * w))
  v <- rnorm(n_g, sd = exp(a_sg[1] + a_sg[2] * z))
  x <- rnorm(n)
  mu <- exp(0.3 + 0.3 * x + u[id_i])
  sg <- exp(-0.7 + v[g_i])
  y <- rgamma(n, shape = 1 / sg^2, scale = mu * sg^2)
  d <- data.frame(
    y = y, x = x,
    id = id_i, g = g_i, w = w[id_i], z = z[g_i]
  )
  # Shuffle row order and the factor level order so that levels are matched
  # by label and not by position.
  d$id <- factor(id_lab[d$id], levels = sample(id_lab))
  d$g <- factor(g_lab[d$g], levels = sample(g_lab))
  d[sample(nrow(d)), ]
}

# Per-row log density, score and information in (a = log mu, s = log sigma).
joint_row <- function(y, a, s) {
  k <- exp(-2 * s)
  r <- y * exp(-a)
  B <- log(k) + 1 - a - digamma(k) + log(y) - r
  list(
    ll = k * log(k) - k * a - lgamma(k) + (k - 1) * log(y) - k * r,
    ga = k * (r - 1),
    gs = -2 * k * B,
    haa = -k * r,
    has = -2 * k * (r - 1),
    hss = 4 * k * B + 4 * k - 4 * k^2 * trigamma(k)
  )
}

# mode "ok"; "swap_coef" (each SD formula gets the other's coefficients);
# "misalign" (SDs shifted by one level); "wrong_dpar" (the g effect is added
# to mu instead of log sigma, the id effect stays on mu).
joint_oracle <- function(d, beta, log_sigma, a_mu, a_sg, same_group = FALSE,
                         mode = "ok") {
  il <- levels(d$id)
  gl <- levels(d$g)
  nu <- length(il)
  nv <- length(gl)
  w_l <- d$w[match(il, d$id)]
  z_l <- d$z[match(gl, d$g)]
  am <- if (mode == "swap_coef") a_sg else a_mu
  as <- if (mode == "swap_coef") a_mu else a_sg
  tm <- exp(am[1] + am[2] * w_l)
  ts <- exp(as[1] + as[2] * z_l)
  if (mode == "misalign") {
    tm <- tm[c(2:nu, 1L)]
    ts <- ts[c(2:nv, 1L)]
  }
  iu <- match(d$id, il)
  iv <- match(d$g, gl)
  a0 <- beta[1] + beta[2] * d$x
  prec <- c(1 / tm^2, 1 / ts^2)
  parts <- function(b) {
    u <- b[seq_len(nu)]
    v <- b[nu + seq_len(nv)]
    if (mode == "wrong_dpar") {
      joint_row(d$y, a0 + u[iu] + v[iv], log_sigma + 0 * v[iv])
    } else {
      joint_row(d$y, a0 + u[iu], log_sigma + v[iv])
    }
  }
  jointll <- function(b) {
    sum(parts(b)$ll) +
      sum(dnorm(b, 0, 1 / sqrt(prec), log = TRUE))
  }
  grad_hess <- function(b) {
    p <- parts(b)
    ga <- p$ga
    gs <- if (mode == "wrong_dpar") p$ga else p$gs
    gr <- numeric(nu + nv)
    H <- matrix(0, nu + nv, nu + nv)
    for (i in seq_along(iu)) {
      ju <- iu[i]
      jv <- nu + iv[i]
      gr[ju] <- gr[ju] + ga[i]
      gr[jv] <- gr[jv] + gs[i]
      H[ju, ju] <- H[ju, ju] - p$haa[i]
      if (mode == "wrong_dpar") {
        H[ju, jv] <- H[ju, jv] - p$haa[i]
        H[jv, ju] <- H[jv, ju] - p$haa[i]
        H[jv, jv] <- H[jv, jv] - p$haa[i]
      } else {
        H[jv, jv] <- H[jv, jv] - p$hss[i]
        H[ju, jv] <- H[ju, jv] - p$has[i]
        H[jv, ju] <- H[jv, ju] - p$has[i]
      }
    }
    list(grad = gr - prec * b, H = H + diag(prec))
  }
  b <- rep(0, nu + nv)
  for (it in seq_len(200L)) {
    gh <- grad_hess(b)
    # Information may be indefinite far from the mode; damp until positive.
    lam <- 0
    repeat {
      Hd <- gh$H + diag(lam, nrow(gh$H))
      if (!inherits(try(chol(Hd), silent = TRUE), "try-error")) break
      lam <- max(2 * lam, 1e-3)
    }
    step <- drop(solve(Hd, gh$grad))
    s <- 1
    while (jointll(b + s * step) < jointll(b) - 1e-12 && s > 1e-10) s <- s / 2
    b <- b + s * step
    if (max(abs(gh$grad)) < 1e-9) break
  }
  gh <- grad_hess(b)
  stopifnot(max(abs(gh$grad)) < 1e-6)
  ld <- as.numeric(determinant(gh$H, logarithm = TRUE)$modulus)
  jointll(b) + 0.5 * (nu + nv) * log(2 * pi) - 0.5 * ld
}

joint_fit <- function(d, sd_mu = "~ w", sd_sg = "~ z", same_group = FALSE) {
  gname <- if (same_group) "id" else "g"
  fm <- eval(parse(text = sprintf(
    paste0("bf(y ~ x + (1 | id), sigma ~ 1 + (1 | %s), ",
           "sd(id) %s, sd(%s, dpar = \"sigma\") %s)"),
    gname, sd_mu, gname, sd_sg
  )))
  drmTMB(fm, family = Gamma(link = "log"), data = d,
         control = drm_control(se = FALSE))
}

joint_pieces <- function(fit, gname = "g") {
  list(
    beta = unname(coef(fit, "mu")),
    ls = unname(coef(fit, "sigma")),
    a_mu = unname(coef(fit, "sd(id)")),
    a_sg = unname(coef(fit, sprintf("sd(%s, dpar = \"sigma\")", gname)))
  )
}

test_that("Gamma joint mu and sigma ordinary SD regressions match a dense Laplace oracle", {
  skip_on_cran()
  d <- joint_fixture()
  fit <- joint_fit(d)
  expect_equal(fit$opt$convergence, 0L)
  p <- joint_pieces(fit)
  expect_length(p$a_mu, 2L)
  expect_length(p$a_sg, 2L)
  ll <- as.numeric(logLik(fit))
  ref <- joint_oracle(d, p$beta, p$ls, p$a_mu, p$a_sg)
  expect_lt(abs(ll - ref), 1e-4)
  for (m in c("swap_coef", "misalign", "wrong_dpar")) {
    gap <- abs(ll - joint_oracle(d, p$beta, p$ls, p$a_mu, p$a_sg, mode = m))
    expect_gt(gap, 1)
  }
})

test_that("Gamma joint SD regressions on one shared grouping factor match the oracle", {
  skip_on_cran()
  d <- joint_fixture(seed = 20261113L, n_id = 30L, same_group = TRUE)
  fit <- joint_fit(d, same_group = TRUE)
  expect_equal(fit$opt$convergence, 0L)
  p <- joint_pieces(fit, gname = "id")
  ll <- as.numeric(logLik(fit))
  # Oracle with g := id (same labels, same level order).
  d2 <- d
  d2$g <- d2$id
  ref <- joint_oracle(d2, p$beta, p$ls, p$a_mu, p$a_sg, same_group = TRUE)
  expect_lt(abs(ll - ref), 1e-4)
  gap <- abs(ll - joint_oracle(d2, p$beta, p$ls, p$a_mu, p$a_sg,
                               same_group = TRUE, mode = "swap_coef"))
  expect_gt(gap, 1)
})

test_that("constant joint SD formulas equal the dense Laplace oracle with constant SDs", {
  skip_on_cran()
  d <- joint_fixture(seed = 20261114L)
  fit <- joint_fit(d, sd_mu = "~ 1", sd_sg = "~ 1")
  expect_equal(fit$opt$convergence, 0L)
  p <- joint_pieces(fit)
  expect_length(p$a_mu, 1L)
  expect_length(p$a_sg, 1L)
  # Constant SD: the oracle sees w and z only through the (zero) slope.
  ll <- as.numeric(logLik(fit))
  ref <- joint_oracle(d, p$beta, p$ls, c(p$a_mu, 0), c(p$a_sg, 0))
  expect_lt(abs(ll - ref), 1e-4)
  # The slope-free model is nested in the SD-regression model: the richer fit
  # cannot have a lower maximised likelihood (tolerance 1e-6 for optimiser).
  rich <- joint_fit(d)
  expect_gte(as.numeric(logLik(rich)) - ll, -1e-6)
})

test_that("joint SD fit reports both SD regressions and predicts per-group SDs", {
  skip_on_cran()
  d <- joint_fixture()
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g),
       sd(id) ~ w, sd(g, dpar = "sigma") ~ z),
    family = Gamma(link = "log"), data = d
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_true(all(is.finite(vcov(fit, dpar = "sd(id)"))))
  expect_true(all(is.finite(vcov(fit, dpar = 'sd(g, dpar = "sigma")'))))
  a <- coef(fit, "sd(id)")
  pr <- predict(fit, dpar = "sd(id)")
  expect_equal(length(pr), nlevels(d$id))
  expect_equal(sort(unname(pr)),
               sort(unname(exp(a[[1]] + a[[2]] * unique(d$w)))),
               tolerance = 1e-8)
})

test_that("neighbouring Gamma joint routes stay refused", {
  d <- joint_fixture(seed = 20261115L)
  fam <- Gamma(link = "log")
  # Formula-free joint (no SD regressions) is still closed.
  expect_error(
    drmTMB(bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g)), family = fam, data = d),
    "combined"
  )
  # Only the mu SD formula: the sigma effect has none.
  expect_error(
    drmTMB(bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g), sd(id) ~ w),
           family = fam, data = d),
    "combined"
  )
  # Only the sigma SD formula beside an ordinary mu effect.
  expect_error(
    drmTMB(bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g),
              sd(g, dpar = "sigma") ~ z),
           family = fam, data = d),
    "combined"
  )
  # A mu random slope beside the sigma intercept.
  expect_error(
    drmTMB(bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ 1 + (1 | g),
              sd(id, coef = "(Intercept)") ~ w,
              sd(g, dpar = "sigma") ~ z),
           family = fam, data = d),
    "combined"
  )
  # A sigma random slope beside the mu intercept.
  expect_error(
    drmTMB(bf(y ~ x + (1 | id), sigma ~ 1 + (0 + x | g),
              sd(id) ~ w, sd(g, dpar = "sigma", coef = "x") ~ z),
           family = fam, data = d),
    "combined"
  )
  # Missing-response integration is not part of this slice.
  dm <- d
  dm$y[1:5] <- NA
  expect_error(
    drmTMB:::drm_build_gamma_ls_spec(
      bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g),
         sd(id) ~ w, sd(g, dpar = "sigma") ~ z),
      dm, missing = miss_control(response = "include")
    ),
    "complete responses"
  )
})
