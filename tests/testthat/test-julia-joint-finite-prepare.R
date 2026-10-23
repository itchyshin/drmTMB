finite_joint_data <- function(kind="ordinal") {
  n <- 90L;z <- seq(-1,1,length.out=n);code <- rep(1:3,length.out=n)
  levels <- c("low","middle","high")
  x <- if(kind=="ordinal") ordered(levels[code],levels=levels) else factor(levels[code],levels=levels)
  x[c(7,14,21,28)] <- NA
  y <- .2+.3*z+code/5;y[c(5,7)] <- NA_real_
  data.frame(y=y,x=x,z=z)
}
finite_joint_prepare <- function(kind="ordinal",response="include",intercept_only=FALSE) {
  d <- finite_joint_data(kind)
  im <- impute_model(if(intercept_only) x~1 else x~z,
    family=if(kind=="ordinal") cumulative_logit() else categorical())
  drm_julia_joint_prepare(bf(y~z+mi(x),sigma~1),gaussian(),d,
    impute=list(x=im),missing=miss_control(response=response,predictor="model"))
}
test_that("finite predictor preparation preserves state-expanded native design", {
  for(kind in c("ordinal","categorical")) {
    prepared <- finite_joint_prepare(kind)
    p <- prepared$payload;d <- finite_joint_data(kind);K <- 3L;n <- nrow(d)
    expect_identical(p$schema,"joint_missing_finite_v1")
    expect_identical(p$predictor,kind)
    expect_identical(p$levels,levels(d$x))
    expect_identical(p$state_layout,"row_then_state")
    expect_identical(dim(p$X_mu_state),c(n*K,4L))
    expect_identical(p$observed_x,!is.na(d$x))
    expect_identical(p$observed_y,!is.na(d$y))
    expect_identical(p$original_row,seq_len(n))
    for(k in seq_len(K)) {
      ds <- d;ds$x[] <- levels(d$x)[k]
      X <- model.matrix(~z+x,ds)
      expect_equal(p$X_mu_state[seq(k,n*K,by=K),],matrix(as.numeric(X),nrow=n),tolerance=1e-12)
    }
  }
})
test_that("ordinal predictor intercept removal and row policy are retained", {
  p <- finite_joint_prepare("ordinal",intercept_only=TRUE)$payload
  expect_identical(dim(p$X_predictor),c(90L,0L))
  expect_length(p$predictor_names,0L)
  drop <- finite_joint_prepare("categorical",response="drop")$payload
  expect_identical(drop$original_row,setdiff(seq_len(90L),c(5L,7L)))
  expect_true(all(drop$observed_y))
  expect_identical(nrow(drop$X_mu_state),3L*length(drop$y))
})
