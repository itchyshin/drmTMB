# Deliberately non-diagonal covariance catches lost axes when removing cuts.
finite_contract_fixture <- function(kind="ordinal") {
  p <- list(schema="joint_missing_finite_v1",predictor=kind,variable="x",
    levels=c("low","middle","high"),mu_names=c("(Intercept)","z","mi(x).L","mi(x).Q"),
    sigma_names="(Intercept)",predictor_names=if(kind=="ordinal") "z" else c("(Intercept)","z"),
    original_row=c(2L,4L,8L,9L),observed_y=c(TRUE,TRUE,FALSE,FALSE),
    observed_x=c(TRUE,FALSE,TRUE,FALSE),x=c(1,0,3,0))
  blocks <- c(rep("mu",4),"sigma",if(kind=="ordinal") rep("rawcut_x",2),
    rep("mi_x",if(kind=="ordinal") 1 else 4))
  terms <- c(p$mu_names,p$sigma_names,if(kind=="ordinal") c("cut1","log_spacing2","z") else
    c("middle:(Intercept)","middle:z","high:(Intercept)","high:z"))
  theta <- seq_along(blocks)/10;names_raw <- paste0(blocks,"_",terms)
  a <- matrix(seq_len(length(theta)^2)/100,length(theta));V <- crossprod(a)+diag(length(theta))
  probs <- rbind(c(1,0,0),c(.2,.5,.3),c(0,0,1),c(.4,.4,.2))
  point <- if(kind=="ordinal") c(1,2.1,3,1.8) else c(1,2,3,1)
  sd <- if(kind=="ordinal") c(NA,sqrt(.49),NA,sqrt(.56)) else rep(NA_real_,4)
  status <- if(kind=="ordinal") rep("ok",4) else c("ok","route_conditional_se_unavailable","ok","route_conditional_se_unavailable")
  result <- list(schema="joint_missing_finite_result_v1",coefficients=theta,coef_names=names_raw,
    coefficient_blocks=blocks,coefficient_terms=terms,vcov=V,vcov_names=names_raw,
    covariance_status="observed_information_inverse",original_row=p$original_row,
    observed_y=p$observed_y,observed_x=p$observed_x,predictor_levels=p$levels,
    conditional_probabilities=probs,
    imputation=list(variable=rep("x",4),original_row=p$original_row,model_row=1:4,
      observed=p$observed_x,estimate=point,std_error=sd,se_available=is.finite(sd),
      source=ifelse(p$observed_x,"observed",if(kind=="ordinal") "conditional_expected_score" else "conditional_modal_category"),
      uncertainty_status=status))
  if(kind=="ordinal") result$ordinal <- list(theta_raw=theta[6:7],
    cutpoints=c(theta[6],theta[6]+exp(theta[7])),labels=c("low|middle","middle|high"))
  list(result=result,prepared=list(payload=p))
}

test_that("finite raw covariance and public coefficients keep distinct axes", {
  for(kind in c("ordinal","categorical")) {
    f <- finite_contract_fixture(kind)
    c <- drm_julia_finite_joint_contract(f$result,f$prepared)
    public <- drm_julia_joint_public_parameters(c)
    keep <- if(kind=="ordinal") c(1:5,8L) else 1:9
    expect_equal(unname(public$theta),f$result$coefficients[keep])
    expect_equal(unname(public$vcov),f$result$vcov[keep,keep])
    expect_identical(names(public$coefficient_blocks),c("mu","sigma","mi_x"))
    expect_identical(c$rows$original_row,c(2L,4L,8L,9L))
    expect_identical(c$imputation$estimate,f$result$imputation$estimate)
  }
})

test_that("finite contracts reject corrupted probabilities, cuts and metadata", {
  f <- finite_contract_fixture()
  damage <- list(
    function(r) {r$conditional_probabilities[2,1]<-.3;r},
    function(r) {r$conditional_probabilities[1,]<-c(0,1,0);r},
    function(r) {r$predictor_levels<-rev(r$predictor_levels);r},
    function(r) {r$ordinal$cutpoints[2]<-r$ordinal$cutpoints[2]+.1;r},
    function(r) {r$imputation$estimate[2]<-2;r},
    function(r) {r$imputation$std_error[2]<-10;r},
    function(r) {r$vcov_names<-rev(r$vcov_names);r},
    function(r) {r$original_row<-1:4;r},
    function(r) {r$imputation$se_available[2]<-FALSE;r})
  for(change in damage) expect_error(drm_julia_finite_joint_contract(change(f$result),f$prepared))
  cat <- finite_contract_fixture("categorical")
  cat$result$ordinal <- f$result$ordinal
  expect_error(drm_julia_finite_joint_contract(cat$result,cat$prepared),"Categorical")
  cat <- finite_contract_fixture("categorical")
  cat$result$imputation$uncertainty_status[2] <- "ok"
  cat$result$imputation$se_available[2] <- TRUE
  cat$result$imputation$std_error[2] <- .5
  expect_error(drm_julia_finite_joint_contract(cat$result,cat$prepared),"uncertainty statuses")
  cat <- finite_contract_fixture("categorical")
  cat$result$imputation$uncertainty_status[1] <- "route_conditional_se_unavailable"
  expect_error(drm_julia_finite_joint_contract(cat$result,cat$prepared),"uncertainty statuses")
})

test_that("finite prediction retains fitted levels and rejects unknown or missing labels", {
  d <- data.frame(x=c("high","low"))
  got <- drm_julia_finite_factor_data(d,"x",c("low","middle","high"),TRUE)
  expect_true(is.ordered(got$x))
  expect_identical(as.integer(got$x),c(3L,1L))
  expect_error(drm_julia_finite_factor_data(data.frame(x="new"),"x",levels(got$x),TRUE))
  expect_error(drm_julia_finite_factor_data(data.frame(x=NA_character_),"x",levels(got$x),TRUE))
})
