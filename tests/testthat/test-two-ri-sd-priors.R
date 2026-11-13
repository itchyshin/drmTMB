test_that("two random intercepts resolve exact named targets", {
  d <- data.frame(y = seq_len(12), x = rep(c(-1, 0, 1), 4),
                  site = factor(rep(1:3, each = 4)),
                  observer = factor(rep(c(1, 2, 3, 1), 3)))
  f <- bf(mu = y ~ x + (1 | site) + (1 | observer), sigma = ~ x)
  ps <- drm_prior_sd_gamma(group = "site", shape = 2, rate = 3)
  po <- drm_prior_sd_gamma(group = "observer", shape = 3.5, rate = 1.7)
  ans <- drm_resolve_priors(f, gaussian(), d, drm_priors(po, ps))
  expect_equal(ans$group, c("observer", "site"))
  expect_equal(ans$shape, c(3.5, 2))
  expect_error(drm_resolve_priors(f, gaussian(), d, drm_priors(ps, ps)), "duplicate|overlap|one SD prior")
  expect_error(drm_resolve_priors(f, gaussian(), d, drm_priors(drm_prior_sd_gamma(group = "none", shape = 2, rate = 3))), "target")
  expect_error(drm_resolve_priors(bf(mu = y ~ x + (1 | site) + (1 | site), sigma = ~ x), gaussian(), d, drm_priors(ps)), "prior|random|duplicate")
  expect_error(drm_resolve_priors(bf(mu = y ~ x + (1 + x | site) + (1 | observer), sigma = ~ x), gaussian(), d, drm_priors(ps)), "prior|random|intercept")
  # Fixed-only priors with two intercepts are part of this slice.
  expect_no_error(drm_resolve_priors(f, gaussian(), d, drm_priors(drm_prior_normal("mu", "x", sd = 2))))
})

test_that("two RI objective and derivatives match dense Gaussian oracle", {
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("numDeriv")
  path <- Sys.getenv("DRM_TWO_RI_ORACLE", unset = "")
  if (!nzchar(path)) path <- testthat::test_path("fixtures", "two-ri-sd-prior-oracle")
  expect_true(file.exists(file.path(path, "frozen.json")), info = paste("oracle:", path))
  x <- jsonlite::fromJSON(file.path(path, "frozen.json"), simplifyVector = FALSE)
  asym <- jsonlite::fromJSON(file.path(path, "asymmetric-frozen.json"), simplifyVector = FALSE)
  datasets <- c(x$response, asym$datasets)
  records <- c(x$records, asym$points)
  fits <- c(x$fits, asym$fits)
  ps <- drm_prior_sd_gamma(group = "site", shape = 2, rate = 3)
  po <- drm_prior_sd_gamma(group = "observer", shape = 3.5, rate = 1.7)
  pf1 <- drm_prior_normal("mu", "(Intercept)", mean = .25, sd = 1.4)
  pf2 <- drm_prior_normal("sigma", "x", mean = -.1, sd = .7)
  for (dataset in names(datasets)) for (case in c("none", "site", "observer", "both", "mixed")) {
    d <- data.frame(y = unlist(datasets[[dataset]]), x = unlist(x$x),
                    site = factor(unlist(x$site)), observer = factor(unlist(x$observer)))
    prior <- switch(case, none = NULL, site = drm_priors(ps), observer = drm_priors(po),
                    both = drm_priors(ps, po), mixed = drm_priors(ps, po, pf1, pf2))
    f <- suppressWarnings(drmTMB(bf(mu = y ~ x + (1 | site) + (1 | observer), sigma = ~ x), data = d, priors = prior))
    positions <- c(which(names(f$obj$par) == "beta_mu"), which(names(f$obj$par) == "beta_sigma"), which(names(f$obj$par) == "log_sd_mu"))
    expect_length(positions, 6L)
    target_indices <- switch(case, none = integer(), site = 1L, observer = 2L, both = 1:2, mixed = 1:2)
    if (length(target_indices)) {
      target_eta <- unname(f$opt$par[positions[4L + target_indices]])
      expect_true(all(is.finite(target_eta)) && all(is.finite(exp(2 * target_eta))) && all(exp(2 * target_eta) > 0))
    }
    refits <- Filter(function(z) identical(z$dataset, dataset) && identical(z$case, case), fits)
    if (length(refits)) {
      refit <- refits[[1L]]
      score <- max(abs(f$obj$gr(f$opt$par)))
      expect_lte(score, 1e-6)
      expect_lte(abs(f$opt$objective - refit$objective), 1e-7 * max(1, abs(refit$objective)))
      if (isTRUE(refit$success) && refit$hessian_min_eigenvalue > 1e-3 && score <= 1e-6)
        expect_lte(max(abs(unname(f$opt$par[positions]) - unlist(refit$theta))), 1e-5)
    }
    rows <- Filter(function(z) identical(z$dataset, dataset) && identical(z$case, case), records)
    for (row in rows) {
      point <- unlist(row$theta); base <- f$obj$par
      fn <- function(v) { q <- base; q[positions] <- v; f$obj$fn(q) }
      gr <- function(v) { q <- base; q[positions] <- v; f$obj$gr(q)[positions] }
      h <- numDeriv::jacobian(gr, point)
      hr <- do.call(rbind, lapply(row$hessian, function(v) as.numeric(unlist(v))))
      expect_lte(abs(fn(point) - row$objective), 1e-8 * max(1, abs(row$objective)))
      expect_lte(max(abs(gr(point) - unlist(row$gradient))), 1e-6)
      expect_lte(max(abs(h - hr) / pmax(1, abs(hr))), 1e-5)
    }
  }
})

test_that("target order, penalties and replay are independent of formula order", {
  path <- testthat::test_path("fixtures", "two-ri-sd-prior-oracle", "frozen.json")
  skip_if_not_installed("jsonlite")
  x <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  d <- data.frame(y = unlist(x$response[["0.6"]]), x = unlist(x$x),
                  site = factor(unlist(x$site)), observer = factor(unlist(x$observer)))
  p <- drm_priors(drm_prior_sd_gamma(group = "observer", shape = 3.5, rate = 1.7),
                  drm_prior_sd_gamma(group = "site", shape = 2, rate = 3),
                  drm_prior_normal("mu", "(Intercept)", mean = .25, sd = 1.4))
  f <- suppressWarnings(drmTMB(bf(mu = y ~ x + (1 | site) + (1 | observer), sigma = ~ x), data = d, priors = p))
  g <- suppressWarnings(drmTMB(bf(mu = y ~ x + (1 | observer) + (1 | site), sigma = ~ x), data = d, priors = p))
  expect_equal(f$opt$objective, g$opt$objective, tolerance = 1e-7)
  expect_equal(f$resolved_sd_prior$group, c("observer", "site"))
  expect_equal(sum(f$sd_prior_penalties), f$sd_prior_penalty, tolerance = 1e-10)
  expect_equal(unname(f$sd_prior_penalties), unname(g$sd_prior_penalties), tolerance = 1e-5)
  expect_equal(f$penalized_objective, -f$logLik + f$fixed_prior_penalty + f$sd_prior_penalty, tolerance = 1e-8)
  expect_equal(unname(f$likelihood_gradient + f$prior_gradient), as.numeric(f$obj$gr(f$opt$par)), tolerance = 1e-9)
  expect_error(confint(f), "prior")
  expect_error(confint(f, method = "bootstrap"), "prior")
  expect_error(AIC(f), "prior")
  replay <- suppressWarnings(update(f))
  expect_equal(replay$resolved_sd_prior, f$resolved_sd_prior)
  expect_equal(replay$sd_prior_penalties, f$sd_prior_penalties, tolerance = 1e-8)
  expect_equal(replay$penalized_objective, f$penalized_objective, tolerance = 1e-8)
})

test_that("native objective detects wrong target and penalty mutations", {
  skip_if_not_installed("jsonlite")
  x <- jsonlite::fromJSON(testthat::test_path("fixtures", "two-ri-sd-prior-oracle", "frozen.json"), simplifyVector = FALSE)
  d <- data.frame(y = unlist(x$response[["0.03"]]), x = unlist(x$x),
                  site = factor(unlist(x$site)), observer = factor(unlist(x$observer)))
  f <- suppressWarnings(drmTMB(bf(mu = y ~ x + (1 | site) + (1 | observer), sigma = ~ x), data = d,
                              priors = drm_priors(drm_prior_sd_gamma(group = "site", shape = 2, rate = 3))))
  pos <- c(which(names(f$obj$par) == "beta_mu"), which(names(f$obj$par) == "beta_sigma"), which(names(f$obj$par) == "log_sd_mu"))
  row <- Filter(function(z) identical(z$dataset, "0.03") && identical(z$case, "site"), x$records)[[1L]]
  theta <- unlist(row$theta); par <- f$obj$par; par[pos] <- theta
  actual <- f$obj$fn(par)
  correct <- -dgamma(exp(theta[[5]]), shape = 2, rate = 3, log = TRUE)
  wrong <- -dgamma(exp(theta[[6]]), shape = 2, rate = 3, log = TRUE)
  values <- c(wrong_target = row$objective - correct + wrong, omitted = row$objective - correct,
              doubled = row$objective + correct, per_group = row$objective + 2 * correct,
              jacobian = row$objective - theta[[5]], omitted_normalizer = row$objective + 2 * log(3),
              swapped_shape_rate = row$objective - correct - dgamma(exp(theta[[5]]), shape = 3, rate = 2, log = TRUE))
  expect_true(all(abs(values - actual) > 1e-8 * max(1, abs(actual))))
})

test_that("v3 independently validates each named SD contribution", {
  rec <- function(i, group, shape, rate) list(spec_index = as.integer(i), kind = "ranef_sd_gamma", class = "ranef_sd",
    dpar = "mu", group = group, coef = "(Intercept)", block_kind = "iid_random_intercept", shape = shape, rate = rate, measure = "natural_sd")
  expected <- list(rec(1, "observer", 3.5, 1.7), rec(2, "site", 2, 3))
  coords <- c("mu_(Intercept)", "sigma_(Intercept)", "eta_sd[mu|site|(Intercept)]", "eta_sd[mu|observer|(Intercept)]")
  p1 <- -dgamma(.8, 2, rate = 3, log = TRUE); p2 <- -dgamma(.4, 3.5, rate = 1.7, log = TRUE)
  contribution <- function(group, p) list(dpar = "mu", group = group, coef = "(Intercept)", penalty = p)
  good <- list(prior_contract = "parameter_priors_v3", resolved_priors_v3 = expected,
    working_coordinates = coords, working_values = c(0, 0, log(.8), log(.4)), coefficients = c(0, 0, log(.8), log(.4)),
    data_nll = 4, data_logLik = -4, loglik = -4, fixed_prior_penalty = 0, sd_prior_penalty = p1 + p2,
    sd_prior_contributions = list(contribution("observer", p2), contribution("site", p1)),
    penalized_objective = 4 + p1 + p2, data_gradient = c(0, 0, 1, 2), fixed_prior_gradient = c(0, 0, 0, 0),
    sd_prior_gradient = c(0, 0, 1.4, 1.7 * .4 - 2.5), penalized_gradient = c(0, 0, 2.4, 2 + 1.7 * .4 - 2.5),
    estim_method = "MAP", infocrit_basis = "unavailable")
  validate <- function(x) drmTMB:::drm_julia_validate_prior_v2_result(x, expected, coords, version = "v3")
  expect_silent(validate(good))
  bad <- good; bad$sd_prior_contributions <- rev(bad$sd_prior_contributions); expect_error(validate(bad), "contribution identity")
  bad <- good; bad$sd_prior_contributions[[1]]$penalty <- p2 + 1; expect_error(validate(bad), "contribution penalty")
  bad <- good; bad$working_coordinates <- rev(coords); expect_error(validate(bad), "coordinate identities")
  bad <- good; bad$resolved_priors_v3[[1]]$group <- "site"; expect_error(validate(bad), "prior records")
  for (field in c("dpar", "coef", "block_kind", "measure", "shape", "rate", "spec_index")) {
    bad <- good
    bad$resolved_priors_v3[[1]][[field]] <- if (field %in% c("shape", "rate", "spec_index")) 7 else "wrong"
    expect_error(validate(bad), "prior records")
  }
  bad <- good; bad$resolved_priors_v3 <- bad$resolved_priors_v3[-1L]; expect_error(validate(bad), "record count")
  bad <- good; bad$sd_prior_contributions[[1]]$penalty <- NA_real_; expect_error(validate(bad), "contribution penalty")
  bad <- good; bad$sd_prior_contributions[[1]] <- c(bad$sd_prior_contributions[[1]], list(group = "extra")); expect_error(validate(bad), "contribution fields")
  bad <- good; bad$sd_prior_penalty <- bad$sd_prior_penalty + 1; expect_error(validate(bad), "SD prior penalty")
  bad <- good; bad$sd_prior_gradient[[4]] <- 0; expect_error(validate(bad), "SD prior gradient")
  bad <- good; bad$penalized_objective <- 0; expect_error(validate(bad), "objective decomposition")
  bad <- good; bad$penalized_gradient[[1]] <- 1; expect_error(validate(bad), "gradient decomposition")
  bad <- good; bad$sd_prior_contributions <- NULL; expect_error(validate(bad), "missing")
  bad <- good; bad$working_values[[3]] <- Inf; expect_error(validate(bad), "working values")
  bad <- good; bad$working_values[[3]] <- -30; bad$coefficients[[3]] <- -30; expect_error(validate(bad), "clamp")
})

test_that("two SD priors transform under response-unit scaling", {
  skip_if_not_installed("jsonlite")
  x <- jsonlite::fromJSON(testthat::test_path("fixtures", "two-ri-sd-prior-oracle", "frozen.json"), simplifyVector = FALSE)
  d <- data.frame(y = unlist(x$response[["0.6"]]), x = unlist(x$x), site = factor(unlist(x$site)), observer = factor(unlist(x$observer)))
  model <- bf(mu = y ~ x + (1 | site) + (1 | observer), sigma = ~ x)
  p <- drm_priors(drm_prior_sd_gamma(group = "site", shape = 2, rate = 3), drm_prior_sd_gamma(group = "observer", shape = 3.5, rate = 1.7))
  f <- suppressWarnings(drmTMB(model, data = d, priors = p))
  factor <- 2.4; d$y <- factor * d$y
  q <- drm_priors(drm_prior_sd_gamma(group = "site", shape = 2, rate = 3 / factor), drm_prior_sd_gamma(group = "observer", shape = 3.5, rate = 1.7 / factor))
  g <- suppressWarnings(drmTMB(model, data = d, priors = q))
  point <- f$obj$par; point[which(names(point) == "beta_mu")] <- c(.6, .3)
  point[which(names(point) == "beta_sigma")] <- c(-.4, .1)
  point[which(names(point) == "log_sd_mu")] <- c(-1.2, -.3)
  scaled <- point; scaled[which(names(point) == "beta_mu")] <- factor * point[which(names(point) == "beta_mu")]
  scaled[which(names(point) == "beta_sigma")[[1]]] <- point[which(names(point) == "beta_sigma")[[1]]] + log(factor)
  scaled[which(names(point) == "log_sd_mu")] <- point[which(names(point) == "log_sd_mu")] + log(factor)
  expect_equal(as.numeric(g$obj$fn(scaled) - f$obj$fn(point)), (nrow(d) + 2) * log(factor), tolerance = 1e-8)
})

test_that("targeted SD floor and fixed-only two-intercept fits are checked", {
  opt <- list(par = c(log_sd_mu = -400, log_sd_mu = -1), convergence = 0L, message = "relative convergence")
  expect_identical(drmTMB:::drm_sd_prior_check_score(opt, c(0, 0), 2L)$convergence, 0L)
  expect_false(identical(drmTMB:::drm_sd_prior_check_score(opt, c(0, 0), 1L)$convergence, 0L))
  skip_if_not_installed("jsonlite")
  x <- jsonlite::fromJSON(testthat::test_path("fixtures", "two-ri-sd-prior-oracle", "frozen.json"), simplifyVector = FALSE)
  d <- data.frame(y = unlist(x$response[["0.6"]]), x = unlist(x$x), site = factor(unlist(x$site)), observer = factor(unlist(x$observer)))
  f <- suppressWarnings(drmTMB(bf(mu = y ~ x + (1 | site) + (1 | observer), sigma = ~ x), data = d,
    priors = drm_priors(drm_prior_normal("mu", "x", sd = 2))))
  expect_identical(f$estimator, "MAP")
  expect_true(is.null(f$resolved_sd_prior))
  expect_false("sd_prior_penalties" %in% names(f))
  unpenalized <- suppressWarnings(drmTMB(bf(mu = y ~ x + (1 | site) + (1 | observer), sigma = ~ x), data = d))
  expect_false("sd_prior_penalties" %in% names(unpenalized))
  expect_error(drmTMB:::drm_abort_fixed_prior_inference(f, "bootstrap"), "prior")
})

test_that("prior-enabled identical grouping partitions fail closed", {
  d <- data.frame(y = c(.2, .3, .1, .7, .5, .8), x = rep(-1:1, 2),
                  site = rep(c("a", "b", "c"), each = 2), observer = rep(c("z", "x", "y"), each = 2))
  f <- bf(mu = y ~ x + (1 | site) + (1 | observer), sigma = ~ 1)
  p <- drm_priors(drm_prior_sd_gamma(group = "site", shape = 2, rate = 3))
  expect_error(drm_resolve_priors(f, gaussian(), d, p), "identical partitions")
  expect_no_error(drmTMB:::drm_validate_fixed_prior_request(NULL, f, gaussian(), d))
})

test_that("live Julia v3 bridge returns both named SD contributions", {
  skip_if_not(identical(Sys.getenv("DRM_TWO_RI_LIVE"), "1"))
  if (exists("drm_julia_bridge_summary_record_live", mode = "function")) drm_julia_bridge_summary_record_live()
  skip_if_not_installed("jsonlite")
  x <- jsonlite::fromJSON(testthat::test_path("fixtures", "two-ri-sd-prior-oracle", "frozen.json"), simplifyVector = FALSE)
  d <- data.frame(y = unlist(x$response[["0.6"]]), x = unlist(x$x), site = unlist(x$site), observer = unlist(x$observer))
  f <- bf(mu = y ~ x + (1 | site) + (1 | observer), sigma = ~ x)
  p <- drm_priors(drm_prior_sd_gamma(group = "site", shape = 2, rate = 3), drm_prior_sd_gamma(group = "observer", shape = 3.5, rate = 1.7))
  j <- suppressWarnings(drmTMB(f, data = d, priors = p, engine = "julia"))
  r <- suppressWarnings(drmTMB(f, data = d, priors = p, engine = "tmb"))
  expect_equal(names(j$sd_prior_penalties), c("site", "observer"))
  expect_equal(sum(j$sd_prior_penalties), j$sd_prior_penalty, tolerance = 1e-10)
  expect_equal(j$sd_prior_penalties, r$sd_prior_penalties, tolerance = 1e-5)
  expect_equal(j$penalized_objective, r$penalized_objective, tolerance = 1e-7)
  expect_error(AIC(j), "prior")
  replay <- suppressWarnings(update(j))
  expect_equal(replay$resolved_sd_prior, j$resolved_sd_prior)
  expect_equal(replay$penalized_objective, j$penalized_objective, tolerance = 1e-7)
  for (group in c("site", "observer")) {
    spec <- if (group == "site") drm_prior_sd_gamma(group = group, shape = 2, rate = 3) else
      drm_prior_sd_gamma(group = group, shape = 3.5, rate = 1.7)
    single <- drm_priors(spec)
    js <- suppressWarnings(drmTMB(f, data = d, priors = single, engine = "julia"))
    rs <- suppressWarnings(drmTMB(f, data = d, priors = single, engine = "tmb"))
    expect_equal(js$resolved_sd_prior$group, group)
    expect_equal(js$penalized_objective, rs$penalized_objective, tolerance = 1e-7)
    expect_equal(js$sd_prior_penalties, rs$sd_prior_penalties, tolerance = 1e-5)
  }
  reverse_model <- bf(mu = y ~ x + (1 | observer) + (1 | site), sigma = ~ x)
  reverse_priors <- drm_priors(drm_prior_sd_gamma(group = "observer", shape = 3.5, rate = 1.7),
                               drm_prior_sd_gamma(group = "site", shape = 2, rate = 3))
  jr <- suppressWarnings(drmTMB(reverse_model, data = d, priors = reverse_priors, engine = "julia"))
  expect_equal(jr$penalized_objective, j$penalized_objective, tolerance = 1e-7)
  expect_equal(unname(jr$sd_prior_penalties[c("site", "observer")]), unname(j$sd_prior_penalties), tolerance = 1e-5)
  mixed <- drm_priors(drm_prior_sd_gamma(group = "site", shape = 2, rate = 3),
                      drm_prior_normal("sigma", "x", mean = -.1, sd = .7),
                      drm_prior_sd_gamma(group = "observer", shape = 3.5, rate = 1.7),
                      drm_prior_normal("mu", "(Intercept)", mean = .25, sd = 1.4))
  jm <- suppressWarnings(drmTMB(reverse_model, data = d, priors = mixed, engine = "julia"))
  rm <- suppressWarnings(drmTMB(reverse_model, data = d, priors = mixed, engine = "tmb"))
  expect_equal(jm$resolved_sd_prior$group, c("site", "observer"))
  expect_equal(jm$resolved_priors[c("dpar", "coefficient")], rm$resolved_priors[c("dpar", "coefficient")])
  expect_equal(jm$penalized_objective, rm$penalized_objective, tolerance = 1e-7)
  expect_equal(jm$logLik, rm$logLik, tolerance = 1e-6)
  expect_equal(jm$fixed_prior_penalty, rm$fixed_prior_penalty, tolerance = 1e-6)
  expect_equal(jm$sd_prior_penalties, rm$sd_prior_penalties, tolerance = 1e-5)
  expect_equal(unname(jm$prior_gradient), unname(rm$prior_gradient), tolerance = 1e-5)
  expect_equal(unname(jm$likelihood_gradient), unname(rm$likelihood_gradient), tolerance = 1e-5)
  expect_lt(max(abs(jm$penalized_gradient)), 1e-6)
  replay_mixed <- suppressWarnings(update(jm))
  expect_equal(replay_mixed$resolved_sd_prior, jm$resolved_sd_prior)
  expect_equal(replay_mixed$resolved_priors[c("dpar", "coefficient")], jm$resolved_priors[c("dpar", "coefficient")])
  expect_equal(replay_mixed$penalized_objective, jm$penalized_objective, tolerance = 1e-7)
  fixed <- drm_priors(drm_prior_normal("mu", "x", sd = 2))
  jf <- suppressWarnings(drmTMB(f, data = d, priors = fixed, engine = "julia"))
  rf <- suppressWarnings(drmTMB(f, data = d, priors = fixed, engine = "tmb"))
  expect_equal(jf$penalized_objective, rf$penalized_objective, tolerance = 1e-7)
  one_model <- bf(mu = y ~ x + (1 | site), sigma = ~ x)
  one_prior <- drm_priors(drm_prior_sd_gamma(group = "site", shape = 2, rate = 3))
  j1 <- suppressWarnings(drmTMB(one_model, data = d, priors = one_prior, engine = "julia"))
  r1 <- suppressWarnings(drmTMB(one_model, data = d, priors = one_prior, engine = "tmb"))
  expect_equal(j1$sd_prior_penalty, r1$sd_prior_penalty, tolerance = 1e-5)
  expect_error(drmTMB(f, data = d, priors = drm_priors(drm_prior_sd_gamma(group = "missing", shape = 2, rate = 3)), engine = "julia"), "target")
})
