test_that("profile endpoint controls do not inherit direct optim controls", {
  direct <- list(control = list(optimizer_method = "BFGS", optimizer = list(maxit = 40L, reltol = 1e-9)))
  expect_equal(profile_fit_nlminb_control(direct), list())
  native <- list(control = list(optimizer_method = "nlminb", optimizer = list(eval.max = 30L, rel.tol = 1e-9)))
  expect_equal(profile_fit_nlminb_control(native), native$control$optimizer)
  legacy <- list(control = list(optimizer = list(eval.max = 30L)))
  expect_equal(profile_fit_nlminb_control(legacy), legacy$control$optimizer)
  expect_equal(profile_fit_nlminb_control(list()), list())
  expect_equal(profile_endpoint_inner_control(profile_fit_nlminb_control(direct)), list(iter.max = 1000L, eval.max = 1000L))
})

test_that("convergence diagnostics name the optimiser that actually ran", {
  object <- list(opt = list(convergence = 0L, message = "ok"), optimizer_used = list(optimizer = "BFGS"))
  expect_match(check_optimizer_convergence(object)$message, "BFGS convergence code is 0", fixed = TRUE)
  object$opt$convergence <- 1L
  object$opt$message <- "iteration limit reached"
  expect_match(check_optimizer_convergence(object)$message, "BFGS convergence message", fixed = TRUE)
  expect_equal(check_optimizer_convergence(object)$status, "warning")
  object$optimizer_used <- NULL
  expect_match(check_optimizer_convergence(object)$message, "nlminb", fixed = TRUE)
})

test_that("optim budgets do not confuse function counts with iteration counts", {
  object <- list(
    opt = list(convergence = 0L, evaluations = c("function" = 90L, gradient = 35L)),
    optimizer_used = list(optimizer = "BFGS", control = list(maxit = 40L)),
    control = list(optimizer_method = "BFGS", optimizer = list(maxit = 40L))
  )
  result <- check_optimizer_budget(object)
  expect_equal(result$status, "note")
  expect_match(result$value, "iterations=NA; function=90; gradient=35", fixed = TRUE)
  expect_match(result$message, "does not report iteration counts", fixed = TRUE)
  object$opt$convergence <- 1L
  result <- check_optimizer_budget(object)
  expect_equal(result$status, "warning")
  expect_match(result$message, "maxit", fixed = TRUE)
})

test_that("native budget diagnostics use the selected retry controls", {
  object <- list(
    opt = list(convergence = 1L, iterations = 1000L, evaluations = c("function" = 800L, gradient = 400L)),
    optimizer_used = list(optimizer = "nlminb", control = list(iter.max = 1000L, eval.max = 1000L)),
    control = list(optimizer = list())
  )
  expect_equal(check_optimizer_budget(object)$status, "warning")
  expect_match(check_optimizer_budget(object)$message, "iteration limit", fixed = TRUE)
})


test_that("direct methods fit the Gaussian likelihood and retain inference", {
  dat <- data.frame(x = seq(-1, 1, length.out = 30))
  dat$y <- 0.4 + 0.7 * dat$x + rep(c(-0.15, 0.2, -0.05), 10)
  ordinary <- lm(y ~ x, data = dat)
  sigma_ml <- sqrt(mean(residuals(ordinary)^2))
  fit_native <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
  for (method in c("BFGS", "L-BFGS-B", "Nelder-Mead", "CG")) {
    ctrl <- list(maxit = 5000L)
    if (method != "L-BFGS-B") ctrl$reltol <- 1e-10
    fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat,
      control = drm_control(optimizer_method = method, optimizer = ctrl,
        newton_polish = FALSE))
    expect_equal(fit$opt$convergence, 0L, info = method)
    expect_equal(unname(fixef(fit)$mu), unname(coef(ordinary)), tolerance = 2e-4, info = method)
    expect_equal(unname(sigma(fit)), rep(sigma_ml, nrow(dat)), tolerance = 2e-4, info = method)
    expect_equal(as.numeric(logLik(fit)), as.numeric(logLik(fit_native)), tolerance = 1e-5, info = method)
    expect_true(isTRUE(fit$sdr$pdHess), info = method)
    expect_true(all(is.finite(vcov(fit))), info = method)
    expect_equal(fit$optimizer_used$optimizer, method)
    expect_true(all(fit$optimizer_attempts$optimizer == method))
    expect_null(fit$opt$iterations)
    expect_equal(check_optimizer_budget(fit)$status, "note")
  }
})

test_that("BFGS supports public starts, polishing, profiles and light storage", {
  dat <- data.frame(x = seq(-1, 1, length.out = 24))
  dat$y <- 0.4 + 0.7 * dat$x + rep(c(-0.15, 0.2, -0.05), 8)
  form <- bf(y ~ x, sigma ~ 1)
  fit <- drmTMB(form, data = dat,
    control = drm_control(optimizer_method = "BFGS", multi_start = 2L,
      start = list(`fixef:mu:(Intercept)` = 0.2), optimizer = list(maxit = 300L)))
  selected <- fit$optimizer_attempts[fit$optimizer_attempts$selected, ]
  expect_equal(nrow(selected), 1L)
  expect_equal(selected$objective, fit$opt$objective)
  expect_equal(selected$convergence, fit$opt$convergence)
  expect_equal(nrow(fit$optimizer_attempts), 1L)
  expect_equal(fit$control$multi_start, 2L)
  ci <- confint(fit, parm = "fixef:mu:x", method = "profile", trace = FALSE)
  expect_equal(ci$conf.status, "profile")
  expect_true(all(is.finite(c(ci$conf.low, ci$conf.high))))
  light <- drmTMB(form, data = dat,
    control = drm_control(optimizer_method = "BFGS", keep_data = FALSE,
      keep_model_frame = FALSE, keep_tmb_object = FALSE))
  expect_null(light$obj)
  expect_equal(as.numeric(predict(light)), as.numeric(predict(fit)), tolerance = 1e-5)
  expect_true(all(is.finite(vcov(light))))
  expect_equal(light$optimizer_used$optimizer, "BFGS")
})

test_that("BFGS fits phylogenetic location and scale random effects", {
  skip_if_not_installed("ape")
  set.seed(681)
  tree <- ape::rcoal(12)
  n_each <- 6L
  dat <- data.frame(species = rep(tree$tip.label, each = n_each),
    x = rep(seq(-1, 1, length.out = n_each), 12))
  dat$y <- 0.3 + 0.5 * dat$x + rep(rnorm(12, sd = 0.5), each = n_each) +
    rnorm(nrow(dat), sd = rep(exp(rnorm(12, -1, 0.25)), each = n_each))
  form <- bf(y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1 + (1 | species))
  a <- drmTMB(form, data = dat, control = drm_control(newton_polish = FALSE))
  b <- drmTMB(form, data = dat, control = drm_control(optimizer_method = "BFGS",
    optimizer = list(maxit = 1000L, reltol = 1e-10), newton_polish = FALSE))
  expect_equal(b$optimizer_used$optimizer, "BFGS")
  expect_equal(b$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(a)), as.numeric(logLik(b)), tolerance = 1e-5)
  expect_equal(as.numeric(predict(a)), as.numeric(predict(b)), tolerance = 2e-4)
  expect_true(isTRUE(b$sdr$pdHess))
})


test_that("retained bootstrap compatibility includes the refit optimizer", {
  object <- list(estimator = "ML", formula = y ~ 1, family = "gaussian",
    nobs = 8L, opt = list(par = c(0, 1), objective = 5))
  header <- function(method) drm_bootstrap_shard_header(object,
    target_names = "fixef:mu:(Intercept)", seed = 1L, re_form = NA,
    refit_control = drm_control(optimizer_method = method))
  a <- header("nlminb")
  b <- header("BFGS")
  expect_equal(a$refit$optimizer_method, "nlminb")
  expect_equal(b$refit$optimizer_method, "BFGS")
  expect_false(identical(a$refit, b$refit))
})


test_that("legacy preset-only records do not masquerade as optimizer names", {
  object <- list(opt = list(convergence = 0L, iterations = 2L,
    evaluations = c("function" = 3L, gradient = 2L)),
    optimizer_used = list(optimizer_preset = "careful"),
    control = list(optimizer = list(iter.max = 1000L)))
  expect_equal(check_optimizer_name(object), "nlminb")
  expect_match(check_optimizer_convergence(object)$message, "nlminb", fixed = TRUE)
  expect_equal(check_optimizer_budget(object)$status, "ok")
})
