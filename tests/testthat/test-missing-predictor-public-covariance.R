# Public predictor regression coefficients must point at their fitted native slot,
# including full covariance with response coefficients. Predictor natural-scale
# dispersion summaries are a separate transformation contract.
mi_covariance_check <- function(fit, blocks, raw_names) {
  targets <- drmTMB:::drm_profile_targets(fit)
  V <- vcov(fit)
  labels <- drmTMB:::coefficient_labels(fit)
  raw <- fit$sdr$cov.fixed
  expected_positions <- integer()
  public_positions <- integer()
  for (j in seq_along(blocks)) {
    block <- blocks[[j]]
    pos <- which(names(fit$opt$par) == raw_names[[j]])
    lab <- paste0(block, ":", names(coef(fit, block)))
    target <- targets[match(paste0("fixef:", lab), targets$parm), ]
    expect_equal(target$tmb_parameter, rep(raw_names[[j]], length(lab)))
    expect_equal(target$index, seq_along(lab))
    expect_true(all(target$profile_ready))
    expect_equal(target$link_estimate, unname(coef(fit, block)))
    ci <- confint(fit, parm = paste0("fixef:", lab), method = "wald")
    radius <- qnorm(.975) * sqrt(diag(raw)[pos])
    expect_equal(ci$lower, unname(coef(fit, block)) - unname(radius), tolerance = 1e-12)
    expect_equal(ci$upper, unname(coef(fit, block)) + unname(radius), tolerance = 1e-12)
    expect_true(all(ci$conf.status == "wald"))
    expected_positions <- c(expected_positions, pos)
    public_positions <- c(public_positions, match(lab, labels))
  }
  expected <- unname(raw[expected_positions, expected_positions, drop = FALSE])
  actual <- unname(V[public_positions, public_positions, drop = FALSE])
  expect_true(all(is.finite(actual)))
  expect_equal(actual, expected, tolerance = 1e-12)
  expect_true(any(abs(expected[row(expected) != col(expected)]) > 1e-8))
}

test_that("finite predictor regression covariance uses the first native slot", {
  set.seed(56381)
  n <- 120L; z <- rnorm(n)
  codes <- sample.int(3L, n, replace = TRUE)
  y <- .3 + .4*z + c(-.6,.2,.8)[codes] + rnorm(n, sd=.7)
  for (ordered in c(TRUE,FALSE)) {
    d <- data.frame(y=y,z=z,habitat=factor(codes,labels=c("low","mid","high"),ordered=ordered))
    d$habitat[seq(5L,n,by=7L)] <- NA
    fit <- drmTMB(bf(y~z+mi(habitat),sigma~1),data=d,
      impute=list(habitat=impute_model(habitat~z,
        family=if(ordered) cumulative_logit() else categorical())),
      missing=miss_control(predictor="model"))
    mi_covariance_check(fit,c("mu","sigma","mi_habitat"),c("beta_mu","beta_sigma","beta_mi"))
    expect_true(all(is.finite(summary(fit)$coefficients$std_error)))
  }
})

test_that("two predictors use independent native slots with custom variable names", {
  set.seed(56382)
  n <- 120L; z <- rnorm(n); first <- .2+.3*z+rnorm(n,sd=.6)
  second <- -.1+.4*z+rnorm(n,sd=.5)
  d <- data.frame(y=.4+.7*first-.3*second+.2*z+rnorm(n,sd=.7),z=z,
    body_mass=first,temperature=second)
  d$body_mass[seq(5L,n,by=11L)] <- NA
  d$temperature[seq(7L,n,by=13L)] <- NA
  fit <- drmTMB(bf(y~mi(body_mass)+mi(temperature)+z,sigma~1),data=d,
    impute=list(body_mass=impute_model(body_mass~z,family=gaussian()),
      temperature=impute_model(temperature~z,family=gaussian())),
    missing=miss_control(predictor="model"))
  mi_covariance_check(fit,c("mu","sigma","mi_body_mass","mi_temperature"),
    c("beta_mu","beta_sigma","beta_mi","beta_mi2"))
  raw <- fit$sdr$cov.fixed
  raw_names <- names(fit$opt$par)
  expect_gt(max(abs(raw[raw_names == "beta_mu", raw_names == "beta_mi"])), 1e-8)
  expect_gt(max(abs(raw[raw_names == "beta_mi", raw_names == "beta_mi2"])), 1e-8)
  # Positive scales are now mapped separately and use the full public Jacobian;
  # the dedicated transformed-covariance tests verify both covariance axes.
  scale_targets <- drmTMB:::drm_profile_targets(fit)
  scale_targets <- scale_targets[scale_targets$dpar %in%
    c("sigma_mi_body_mass", "sigma_mi_temperature"), ]
  expect_equal(nrow(scale_targets), 2L)
  expect_true(all(scale_targets$profile_ready))
  expect_true(all(is.finite(diag(vcov(fit))[match(
    c("sigma_mi_body_mass:body_mass", "sigma_mi_temperature:temperature"),
    rownames(vcov(fit)))])))
})

test_that("predictor target mapping is exact and does not admit transformed summaries", {
  resolver <- drmTMB:::profile_fixef_internal
  object <- list(model=list(missing_predictor=list(variable="body_mass"),
    missing_predictor2=list(variable="temperature")))
  expect_identical(resolver("mi_body_mass", object), "beta_mi")
  expect_identical(resolver("mi_temperature", object), "beta_mi2")
  expect_identical(resolver("mi_body_mass_extra", object), "beta_mi_body_mass_extra")
  expect_identical(resolver("mi_body_mass"), "beta_mi_body_mass")
  for (variable in list(NULL, NA_character_, character(), c("a", "b"), 1)) {
    malformed <- list(model=list(missing_predictor=list(variable=variable)))
    expect_identical(resolver("mi_body_mass", malformed), "beta_mi_body_mass")
  }
  punctuated <- list(model=list(missing_predictor=list(variable="body.mass")))
  expect_identical(resolver("mi_body.mass", punctuated), "beta_mi")
  expect_identical(resolver("mi_bodyXmass", punctuated), "beta_mi_bodyXmass")
  expect_identical(resolver("mu", object), "beta_mu")
  expect_identical(resolver("hu", object), "beta_zi")
  expect_identical(resolver("sigma_mi_body_mass", object), "beta_sigma_mi_body_mass")
  expect_identical(resolver("zoi_mi_body_mass", object), "beta_zoi_mi_body_mass")
})
