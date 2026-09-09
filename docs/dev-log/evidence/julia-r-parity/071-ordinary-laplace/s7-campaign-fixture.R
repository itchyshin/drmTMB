# Frozen DGP contract for S7.  This intentionally leaves
# run-four-fixture-receipt.R untouched: that runner's hash identifies the G4
# receipt.  The algebra below is its scalar-RI/q=2 fixture contract with the
# campaign seed supplied explicitly.

r071_s7_fixture_targets <- function(fixture) {
  if (identical(fixture, "binomial_ri")) return(data.frame(
    parm = c("fixef:mu:(Intercept)", "fixef:mu:x", "sd:mu:(1 | group)"),
    target_class = c("fixed-effect", "fixed-effect", "random-effect-sd"),
    truth = c(-0.1, 0.55, 0.45), stringsAsFactors = FALSE
  ))
  if (identical(fixture, "poisson_ri")) return(data.frame(
    parm = c("fixef:mu:(Intercept)", "fixef:mu:x", "sd:mu:(1 | group)"),
    target_class = c("fixed-effect", "fixed-effect", "random-effect-sd"),
    truth = c(0.2, 0.35, 0.45), stringsAsFactors = FALSE
  ))
  if (identical(fixture, "nb2_ri")) return(data.frame(
    parm = c("fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)",
             "sd:mu:(1 | group)"),
    target_class = c("fixed-effect", "fixed-effect", "fixed-effect", "random-effect-sd"),
    truth = c(0.2, 0.35, 0.125, 0.45), stringsAsFactors = FALSE
  ))
  if (identical(fixture, "nb2_coupled")) return(data.frame(
    parm = c("fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)",
             "fixef:sigma:z", "cholesky:recov:L11", "cholesky:recov:L22",
             "cholesky:recov:L21"),
    target_class = c("fixed-effect", "fixed-effect", "fixed-effect", "fixed-effect",
                     "covariance-coordinate", "covariance-coordinate", "covariance-coordinate"),
    truth = c(0.2, 0.35, 0.15, -0.1, log(0.45), log(0.125), -0.10125),
    stringsAsFactors = FALSE
  ))
  stop("unknown frozen S7 fixture: ", fixture, call. = FALSE)
}

r071_s7_make_fixture <- function(fixture, seed) {
  if (!fixture %in% c("binomial_ri", "poisson_ri", "nb2_ri", "nb2_coupled")) {
    stop("unknown frozen S7 fixture: ", fixture, call. = FALSE)
  }
  if (length(seed) != 1L || is.na(seed) || seed != as.integer(seed) || seed < 1L) {
    stop("S7 DGP seed must be a positive integer", call. = FALSE)
  }
  set.seed(as.integer(seed))
  G <- 12L
  ni <- 10L
  group <- factor(rep(seq_len(G), each = ni))
  x <- rep(seq(-1, 1, length.out = ni), G)
  z <- rep(seq(1, -1, length.out = ni), G)
  b <- stats::rnorm(G, 0, 0.45)
  targets <- r071_s7_fixture_targets(fixture)
  if (identical(fixture, "binomial_ri")) return(list(
    data = data.frame(y = stats::rbinom(G * ni, 1, stats::plogis(-0.1 + 0.55 * x + b[group])), x, group),
    formula = bf(y ~ x + (1 | group)), family = binomial(), marginal = "Laplace",
    target_truths = targets
  ))
  if (identical(fixture, "poisson_ri")) return(list(
    data = data.frame(y = stats::rpois(G * ni, exp(0.2 + 0.35 * x + b[group])), x, group),
    formula = bf(y ~ x + (1 | group)), family = poisson(), marginal = "Laplace",
    target_truths = targets
  ))
  if (identical(fixture, "nb2_ri")) return(list(
    data = data.frame(count = stats::rnbinom(G * ni, mu = exp(0.2 + 0.35 * x + b[group]), size = exp(-0.25)), x, group),
    formula = bf(count ~ x + (1 | group), sigma ~ 1), family = nbinom2(), marginal = "Laplace",
    target_truths = targets
  ))
  b_sigma <- 0.45 * b + stats::rnorm(G, 0, 0.25)
  list(
    data = data.frame(
      count = stats::rnbinom(G * ni, mu = exp(0.2 + 0.35 * x + b[group]),
                             size = exp(-0.3 + 0.2 * z + b_sigma[group])),
      x, z, group
    ),
    formula = bf(count ~ x + (1 | p | group), sigma ~ z + (1 | p | group)),
    family = nbinom2(), marginal = NULL, target_truths = targets
  )
}
