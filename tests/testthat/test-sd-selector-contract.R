# Selector contract for sd(group, level =, dpar =, coef =, block =), recorded in
# docs/design/18-random-effect-scale-models.md ("Selector and key contract").
# Contract under test: the public key is the user's spelling, so two spellings
# of the same latent coefficient are two keys (documented, not one); every key
# is reachable by predict(dpar = ) only by exact match.

sel_fixture <- function() {
  set.seed(20261104L)
  n_id <- 30L
  n_each <- 8L
  id <- factor(rep(seq_len(n_id), each = n_each))
  w <- as.numeric(scale(rnorm(n_id)))
  b <- rnorm(n_id, sd = exp(-0.5 + 0.3 * w))
  d <- data.frame(id = id, w = w[as.integer(id)])
  d$y <- 1 + b[as.integer(id)] + rnorm(nrow(d), sd = 0.5)
  d
}

sel_fit <- function(sd_formula, data = sel_fixture()) {
  drmTMB(
    bf(y ~ 1 + (1 | id), sd_formula),
    family = gaussian(),
    data = data
  )
}

test_that("parse_sd_lhs keys follow the user's spelling", {
  plain <- drmTMB:::parse_sd_lhs(quote(sd(id)))
  coefsel <- drmTMB:::parse_sd_lhs(quote(sd(id, coef = "(Intercept)")))
  both <- drmTMB:::parse_sd_lhs(
    quote(sd(id, dpar = "mu", coef = "(Intercept)"))
  )
  expect_identical(plain$dpar, "sd(id)")
  expect_identical(coefsel$dpar, "sd(id, coef = \"(Intercept)\")")
  expect_identical(both$dpar, "sd(id, dpar = \"mu\", coef = \"(Intercept)\")")
  expect_false(identical(plain$dpar, coefsel$dpar))
  expect_false(identical(coefsel$dpar, both$dpar))
  # Selector order in the call does not change the key.
  swapped <- drmTMB:::parse_sd_lhs(
    quote(sd(id, coef = "(Intercept)", dpar = "mu"))
  )
  expect_identical(swapped$dpar, both$dpar)
  # `group =` and the unnamed spelling give the same key.
  expect_identical(drmTMB:::parse_sd_lhs(quote(sd(group = id)))$dpar, plain$dpar)
})

test_that("structured keys drop selectors and level", {
  a <- drmTMB:::parse_sd_lhs(quote(sd(id, level = "animal")))
  b <- drmTMB:::parse_sd_lhs(quote(sd(id, level = "animal", coef = "x")))
  expect_identical(a$dpar, "sd_animal(id)")
  expect_identical(b$dpar, a$dpar)
  expect_identical(b$target_coef, "x")
})

test_that("level = 'group' is not a public spelling and block is only a check", {
  expect_error(
    drmTMB:::parse_sd_lhs(quote(sd(id, level = "group"))),
    "level"
  )
  d <- sel_fixture()
  expect_error(sel_fit(sd(id, block = "p") ~ w, d))
})

test_that("two spellings of one coefficient fit to the same value under two keys", {
  d <- sel_fixture()
  f1 <- sel_fit(sd(id) ~ w, d)
  f2 <- sel_fit(sd(id, coef = "(Intercept)") ~ w, d)
  k1 <- "sd(id)"
  k2 <- "sd(id, coef = \"(Intercept)\")"
  expect_true(k1 %in% names(f1$coefficients))
  expect_false(k2 %in% names(f1$coefficients))
  expect_true(k2 %in% names(f2$coefficients))
  expect_false(k1 %in% names(f2$coefficients))
  # Same model, so the same log-likelihood and predicted SDs (loose optimiser
  # tolerance; the check is that the two keys are aliases of one model).
  expect_equal(as.numeric(logLik(f1)), as.numeric(logLik(f2)), tolerance = 1e-6)
  expect_equal(
    unname(predict(f1, dpar = k1)),
    unname(predict(f2, dpar = k2)),
    tolerance = 1e-4
  )
})

test_that("predict(dpar = ) matches keys exactly, with no partial matching", {
  f <- sel_fit(sd(id) ~ w)
  ok <- predict(f, dpar = "sd(id)")
  expect_true(all(is.finite(ok)))
  # Prefixes of a real key, and of a distributional parameter, must not resolve.
  expect_error(predict(f, dpar = "sd(id"), "exactly match")
  expect_error(predict(f, dpar = "sd"), "exactly match")
  expect_error(predict(f, dpar = "sig"), "exactly match")
  expect_error(predict(f, dpar = c("mu", "sigma")), "exactly match")
  expect_error(predict(f, dpar = NA_character_), "exactly match")
  expect_error(predict(f, dpar = 1), "exactly match")
})

test_that("a prefix cannot select between two SD keys that share a prefix", {
  set.seed(20261105L)
  n_id <- 40L
  n_each <- 10L
  id <- factor(rep(seq_len(n_id), each = n_each))
  gi <- as.integer(id)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_id)
  w1 <- as.numeric(scale(sin(seq_len(n_id) * 1.7)))
  w2 <- as.numeric(scale(cos(seq_len(n_id) * 0.9 + 1)))
  b0 <- rnorm(n_id, sd = exp(-0.6 + 0.5 * w1))
  b1 <- rnorm(n_id, sd = exp(-1.2 - 0.5 * w2))
  d <- data.frame(id = id, x = x, w1 = w1[gi], w2 = w2[gi])
  d$y <- 0.3 + b0[gi] + b1[gi] * x + rnorm(nrow(d), sd = 0.4)
  f <- drmTMB(
    bf(
      y ~ 1 + (1 | id) + (0 + x | id),
      sd(id, coef = "(Intercept)") ~ w1,
      sd(id, coef = "x") ~ w2
    ),
    family = gaussian(),
    data = d
  )
  keys <- grep("^sd\\(", names(f$coefficients), value = TRUE)
  expect_length(keys, 2L)
  expect_error(predict(f, dpar = "sd(id, coef"), "exactly match")
  expect_error(predict(f, dpar = "sd(id, coef = \"x"), "exactly match")
  p <- lapply(keys, function(k) unname(predict(f, dpar = k)))
  expect_false(isTRUE(all.equal(p[[1L]], p[[2L]])))
})
