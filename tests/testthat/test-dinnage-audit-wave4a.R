# Wave A2 (Dinnage audit arc 3): check.R diagnostics (#1338 A-8, #1343 Mi-5).

wave4a_simulate_biv_lognormal <- function(n, beta1, beta2, sigma1, sigma2, rho12) {
  x <- seq(-1, 1, length.out = n)
  z1 <- stats::rnorm(n)
  z2 <- rho12 * z1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  data.frame(
    x = x,
    y1 = exp(beta1[[1]] + beta1[[2]] * x + sigma1 * z1),
    y2 = exp(beta2[[1]] + beta2[[2]] * x + sigma2 * z2)
  )
}

test_that("A-8: dropped_rows reports groups that lost every row (Dinnage audit)", {
  # Pre-fix check_dropped_rows counted rows only; six of forty individuals
  # could vanish from MCAR complete-case filtering with no mention in the note.
  set.seed(1338)
  n_id <- 40L
  n_each <- 8L
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = n_each)),
    x = stats::rnorm(n_id * n_each)
  )
  dat$y <- stats::rnorm(n_id * n_each)
  drop_ids <- 1:6
  dat$y[dat$id %in% drop_ids] <- NA_real_

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  row <- chk[chk$check == "dropped_rows", ]

  expect_equal(row$status, "note")
  expect_match(row$value, "groups_lost=6")
  expect_match(row$message, "id lost 6 levels")
})

test_that("Mi-5: Wald rho12 boundary warning does not recommend profile (Dinnage audit)", {
  # At rho12 near +/-1, profile intervals match Wald; the generic boundary
  # warning wrongly told users to switch to method = "profile".
  set.seed(1343)
  dat <- wave4a_simulate_biv_lognormal(
    n = 160,
    beta1 = c(0.2, 0.1),
    beta2 = c(-0.1, -0.15),
    sigma1 = 0.35,
    sigma2 = 0.5,
    rho12 = 0.95
  )
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1),
    family = biv_lognormal(),
    data = dat
  )

  ci <- NULL
  warns <- capture_warnings(
    ci <- stats::confint(fit, parm = "rho12", method = "wald", rho_boundary = 0.8),
    "residual-correlation boundary"
  )
  warn_text <- paste(warns, collapse = "\n")
  expect_equal(ci$conf.status, "wald_at_boundary")
  expect_no_match(warn_text, "method = \"profile\"")
  expect_no_match(warn_text, "confint\\(method = \"profile\"\\)")

  chk <- check_drm(fit, rho_boundary = 0.8)
  rho_row <- chk[chk$check == "rho12_boundary", ]
  expect_equal(rho_row$status, "warning")
  expect_match(rho_row$message, "usually identical to Wald")
  expect_no_match(rho_row$message, "method = \"profile\"")
})
