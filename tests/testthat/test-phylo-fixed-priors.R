test_that("normal priors resolve for a phylogenetic SD-regression model", {
  tree <- ape::read.tree(text = "((a:0.5,b:0.5):0.5,(c:0.5,d:0.5):0.5);")
  d <- data.frame(y = c(.2,.7,.35,1.1,.8,1.25,1.4,1.1,1.9,1.5,2.15,.5),
                  x = c(-1.2,-.8,-.7,-.2,.1,.15,.4,.6,.8,1,1.2,-.3),
                  sp = factor(c('a','a','b','b','b','c','c','d','d','d','d','a')),
                  z = c(-1,-1,-.35,-.35,-.35,.4,.4,1,1,1,1,-1))
  f <- bf(y ~ x + phylo(1 | sp, tree = tree), sigma ~ x, sd(sp, level = "phylogenetic") ~ z)
  p <- drm_priors(drm_prior_normal('mu', 'x', mean = .1, sd = .7),
                  drm_prior_normal('sigma', 'x', mean = -.2, sd = .5))
  rows <- suppressWarnings(drm_resolve_priors(f, gaussian(), d, p))
  expect_equal(as.character(rows$dpar), c('mu', 'sigma'))
  expect_equal(as.character(rows$coefficient), c('x', 'x'))
  table <- data.frame(prior=c('normal(.1,.7)', 'normal(-.2,.5)'),
                      class=c('fixef', 'fixef'), coef=c('x', 'x'), dpar=c('mu', 'sigma'))
  tab_rows <- drm_resolve_priors(f, gaussian(), d, table)
  expect_equal(tab_rows$coefficient, rows$coefficient)
  expect_equal(tab_rows$dpar, rows$dpar)
  fit <- drmTMB(f, data = d, priors = p,
                control = drm_control(se = FALSE, logsigma_clamp = NULL))
  K <- ape::vcv(tree, corr = TRUE)
  group <- match(as.character(d$sp), rownames(K))
  X <- cbind(1, d$x); H <- cbind(1, c(-1, -.35, .4, 1))
  oracle <- function(q) {
    mu <- drop(X %*% q[1:2]); e <- exp(drop(X %*% q[3:4]))
    a <- exp(drop(H %*% q[5:6])); C <- K * outer(a, a)
    V <- C[group, group] + diag(e^2)
    ch <- chol(V); r <- d$y - mu
    .5 * (length(r) * log(2*pi) + 2 * sum(log(diag(ch))) +
            sum(forwardsolve(t(ch), r)^2)) -
      dnorm(q[2], .1, .7, log = TRUE) - dnorm(q[4], -.2, .5, log = TRUE)
  }
  points <- rbind(c(.8,.3,-.4,.15,-.3,.2), c(.4,.7,-.8,-.2,-.5,.35),
                  c(1,-.1,.1,.2,-.9,-.2), c(.6,.6,-.1,-.3,.2,.1),
                  c(1.2,.4,-.6,.4,-.1,-.4))
  # Independently computed public-tree oracle; see development evidence.
  reference_obj <- c(11.3440779905637, 9.14530839622453, 15.6716932003145, 14.8468076770793, 11.215463299799)
  reference_grad <- rbind(c(-0.636593951095403, -1.034862477404889, 7.415567591797730, 1.926684071596260, 2.574044520824935, -0.151920121082818),
    c(-4.134219706342567, 1.862044078261477, 4.700612008022679, -0.727287069369394, 1.027779272889617, 0.728921696344921),
    c(-0.166474366182474, -3.269045124778116, 8.764914843669930, 2.531456876508034, 0.456779539602011, -0.147143780496628),
    c(-0.655913155588067, 0.708955022388450, 7.742923841196141, -0.376278876929146, 2.919385631360480, 0.169978774196428),
    c(0.264670646768146, -0.560190140108327, 6.684085965717813, 3.909170192878195, 3.117209709057500, -0.252099105319253))
  for (i in seq_len(nrow(points))) {
    q <- points[i, ]; h <- 1e-5
    fd <- vapply(seq_along(q), function(j) {
      step <- rep(0, length(q)); step[j] <- h
      (oracle(q + step) - oracle(q - step)) / (2*h)
    }, numeric(1))
    expect_equal(as.numeric(fit$obj$fn(q)), oracle(q), tolerance = 1e-8)
    expect_equal(as.numeric(fit$obj$fn(q)), reference_obj[i], tolerance = 1e-8)
    expect_equal(unname(fit$obj$gr(q)), reference_grad[i, ], tolerance = 1e-6)
    expect_equal(unname(fit$obj$gr(q)), fd, tolerance = 1e-6)
    hess_engine <- numDeriv::jacobian(fit$obj$gr, q)
    hess_dense <- numDeriv::hessian(oracle, q)
    scaled <- abs(hess_engine - hess_dense) / pmax(1, abs(hess_dense))
    expect_lt(max(scaled), 1e-5)
  }
  tabfit <- drmTMB(f, data = d, priors = table,
                   control = drm_control(se = FALSE, logsigma_clamp = NULL))
  expect_equal(as.numeric(tabfit$obj$fn(points[1, ])), reference_obj[1], tolerance = 1e-8)
  expect_identical(fit$estimator, 'MAP')
  expect_equal(fit$penalized_objective, -fit$logLik + fit$fixed_prior_penalty, tolerance = 1e-8)
  expect_error(confint(fit), 'fixed-effect')
  expect_error(AIC(fit), 'fixed-effect')
  retained <- update(fit)
  expect_equal(retained$resolved_priors, fit$resolved_priors)
  removed <- update(fit, priors = NULL)
  expect_identical(removed$estimator, 'ML')
  plain <- drmTMB(f, data = d, control = drm_control(se = FALSE, logsigma_clamp = NULL))
  expect_equal(removed$opt$objective, plain$opt$objective, tolerance = 1e-8)
  d$g <- d$sp
  extra <- bf(y ~ x + phylo(1 | sp, tree = tree) + (1 | g),
              sigma ~ x, sd(sp, level = 'phylogenetic') ~ z)
  expect_error(drm_resolve_priors(extra, gaussian(), d, p), 'distributional-parameter|fixed-effect-only')
  sdprior <- drm_priors(drm_prior_sd_gamma(group = 'sp', shape = 2, rate = 3))
  expect_error(drm_resolve_priors(f, gaussian(), d, sdprior), 'distributional-parameter|structured')
})

test_that("phylogenetic prior fit matches the independent interior optimum", {
  d <- read.csv(testthat::test_path("fixtures", "phylo-fixed-priors", "fit-data.csv"))
  labels <- sprintf("t%02d", seq_len(16))
  quartets <- vapply(seq(1, 16, by = 4), function(k) {
    sprintf("((%s:0.5,%s:0.5):0.25,(%s:0.5,%s:0.5):0.25):0.25",
            labels[k], labels[k + 1], labels[k + 2], labels[k + 3])
  }, character(1))
  tree <- ape::read.tree(text = paste0("(", paste(quartets, collapse = ","), ");"))
  d$sp <- factor(labels[d$group], levels = labels)
  f <- bf(y ~ x + phylo(1 | sp, tree = tree), sigma ~ x,
          sd(sp, level = "phylogenetic") ~ z)
  p <- drm_priors(drm_prior_normal("mu", "x", mean = .1, sd = .7),
                  drm_prior_normal("sigma", "x", mean = -.2, sd = .5))
  fit <- drmTMB(f, data = d, priors = p,
                control = drm_control(se = FALSE, logsigma_clamp = NULL,
                                      optimizer_preset = "robust"))
  expected <- c(1.1304557328, .4343248334, -.3068621170,
                .2124665887, -.5879083171, 1.1086827482)
  expect_equal(unname(fit$opt$par), expected, tolerance = 1e-5)
  expect_equal(fit$opt$objective, 104.69371002665, tolerance = 1e-8)
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-5)
  expect_identical(fit$opt$convergence, 0L)
  reordered <- drmTMB(f, data = d[nrow(d):1, ], priors = p,
                      control = drm_control(se = FALSE, logsigma_clamp = NULL,
                                            optimizer_preset = "robust"))
  expect_equal(unname(reordered$opt$par), expected, tolerance = 1e-5)
  expect_equal(reordered$opt$objective, fit$opt$objective, tolerance = 1e-8)
})

test_that("live Julia bridge verifies phylogenetic prior targets", {
  drm_skip_live_julia()
  d <- read.csv(testthat::test_path("fixtures", "phylo-fixed-priors", "fit-data.csv"))
  labels <- sprintf("t%02d", seq_len(16))
  quartets <- vapply(seq(1, 16, by = 4), function(k) {
    sprintf("((%s:0.5,%s:0.5):0.25,(%s:0.5,%s:0.5):0.25):0.25",
            labels[k], labels[k + 1], labels[k + 2], labels[k + 3])
  }, character(1))
  tree <- ape::read.tree(text = paste0("(", paste(quartets, collapse = ","), ");"))
  d$sp <- factor(labels[d$group], levels = labels)
  f <- bf(y ~ x + phylo(1 | sp, tree = tree), sigma ~ x,
          sd(sp, level = "phylogenetic") ~ z)
  priors <- data.frame(prior = c("normal(.1,.7)", "normal(-.2,.5)"),
                       class = "fixef", coef = "x", dpar = c("mu", "sigma"))
  fit <- drmTMB(f, data = d, priors = priors, engine = "julia")
  expect_equal(fit$penalized_objective, 104.69371002665, tolerance = 1e-8)
  expect_equal(fit$logLik, -103.451343533341, tolerance = 1e-8)
  expect_identical(fit$resolved_priors$dpar, c("mu", "sigma"))
  expect_identical(fit$resolved_priors$coefficient, c("x", "x"))
  payload <- fit$bridge_payload
  payload$options$prior_expected[[1L]]$coef <- "__incorrect_target__"
  expect_error(drmTMB:::drm_julia_call_conditional_gaussian_components(
    payload$formula, "gaussian", payload$data, payload$tree, payload$options),
    "resolved prior coordinates differ")
  fq <- bf(y ~ x + I(x^2) + phylo(1 | sp, tree = tree),
           sigma ~ x + I(x^2), sd(sp, level = "phylogenetic") ~ z + I(z^2))
  qp <- data.frame(prior = c("normal(.1,.7)", "normal(-.2,.5)"),
                   class = "fixef", coef = "I(x^2)", dpar = c("mu", "sigma"))
  native_q <- drmTMB(fq, data = d, priors = qp,
                     control = drm_control(se = FALSE, logsigma_clamp = NULL,
                                           optimizer_preset = "robust"))
  bridge_q <- drmTMB(fq, data = d, priors = qp, engine = "julia")
  expect_identical(bridge_q$resolved_priors$coefficient, c("I(x^2)", "I(x^2)"))
  expect_equal(bridge_q$penalized_objective, native_q$penalized_objective, tolerance = 1e-5)
})
