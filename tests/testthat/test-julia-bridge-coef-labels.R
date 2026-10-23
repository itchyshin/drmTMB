label_fixture <- function() {
  public <- c("mu_(Intercept)","mu_I(x^2)","mu_gb: space","mu_x:gb: space","mu_x","sigma_(Intercept)")
  raw <- c("mu_(Intercept)","mu___bridge_I_7","mu_g: b: space","mu_x & g: b: space","mu_x","sigma_(Intercept)")
  list(coef_label_contract="bridge_formula_labels_v1",coef_names=public,
       raw_coef_names=raw,coef_name_map=stats::setNames(as.list(raw),public),
       vcov_names=public,coefficients=seq_along(public)/10,
       vcov=diag(seq_along(public))+outer(seq_along(public),seq_along(public))/10)
}

test_that("versioned Julia coefficient labels preserve ordered identities", {
  result <- label_fixture()
  labels <- drmTMB:::drm_julia_bridge_coef_labels(result)
  expect_identical(labels$public,result$coef_names)
  expect_identical(labels$raw,result$raw_coef_names)
  expect_identical(unname(labels$map[labels$public]),labels$raw)
  object <- list(bridge_public_coef_labels=labels)
  expect_identical(drmTMB:::drm_julia_public_inference_term(object,"mu","I(x^2)"),"__bridge_I_7")
  expect_identical(drmTMB:::drm_julia_public_inference_term(object,"mu","x:gb: space"),"x & g: b: space")
  expect_error(drmTMB:::drm_julia_public_inference_term(object,"mu","absent"),"coefficient")
  expect_null(drmTMB:::drm_julia_bridge_coef_labels(list(coef_names="mu_x")))
  expect_identical(drmTMB:::drm_julia_public_inference_term(list(),"mu","legacy: b"),"legacy: b")
})

test_that("versioned label metadata refuses incomplete or ambiguous maps", {
  damage <- list(
    function(z){z$coef_label_contract<-"unknown";z},
    function(z){z$coef_name_map<-NULL;z},
    function(z){z$raw_coef_names<-NULL;z},
    function(z){z$coef_name_map[[2]]<-"mu_wrong";z},
    function(z){z$coef_names[2]<-z$coef_names[1];z},
    function(z){z$raw_coef_names[2]<-z$raw_coef_names[1];z},
    function(z){names(z$coef_name_map)[2]<-names(z$coef_name_map)[1];z},
    function(z){z$vcov_names<-rev(z$vcov_names);z},
    function(z){z$vcov<-z$vcov[-1,-1];z},
    function(z){z$coefficients<-z$coefficients[-1];z},
    function(z){z$vcov<-matrix("x",length(z$coef_names),length(z$coef_names));z},
    function(z){z$vcov<-rep(list(rep("x",length(z$coef_names))),length(z$coef_names));z},
    function(z){z$coef_names[2]<-NA_character_;z},
    function(z){z$raw_coef_names[2]<-"sigma_x";z$coef_name_map[[2]]<-"sigma_x";z})
  for(f in damage) expect_error(drmTMB:::drm_julia_bridge_coef_labels(f(label_fixture())),"label|coefficient|covariance")
})


test_that("public Julia fit stores mapped labels without changing coefficient values", {
  result <- label_fixture()
  result <- c(result,list(loglik=-10,aic=30,bic=32,df=6L,nobs=12L,
    converged=TRUE,fitted=rep(0,12),residuals=rep(0,12),sigma=1,corpairs=list()))
  dat <- data.frame(y=seq_len(12),x=seq_len(12)/12,g=factor(rep(c("a","b: space"),6)))
  fit <- drmTMB:::new_drmTMB_julia(result,quote(drmTMB()),
    drmTMB::bf(y~x+I(x^2)+g+x:g,sigma~1),gaussian(),dat,"gaussian")
  expect_identical(names(fit$coef_vector),result$coef_names)
  expect_identical(unname(fit$coef_vector),result$coefficients)
  expect_identical(rownames(fit$vcov),result$coef_names)
  expect_identical(colnames(fit$vcov),result$coef_names)
  expect_equal(unname(fit$vcov),result$vcov,tolerance=0)
  expect_identical(drmTMB:::drm_julia_public_inference_term(fit,"mu","I(x^2)"),"__bridge_I_7")
  X <- model.matrix(~x+I(x^2)+g+x:g,dat)
  expected <- drop(X %*% fit$coefficients$mu[colnames(X)])
  actual <- drmTMB:::drm_julia_predict_fixed_eta(fit,"mu",dat,"training")$eta
  expect_equal(actual,unname(expected),tolerance=1e-14)
  expect_error(drmTMB:::drm_julia_public_inference_term(fit,"sigma","I(x^2)"),"coefficient")
})


test_that("public label mapping reaches raw inference and refuses before setup", {
  skip_if_not_installed("JuliaCall")
  object <- list(bridge_public_coef_labels=drmTMB:::drm_julia_bridge_coef_labels(label_fixture()),
    model=list(model_type="gaussian"),bridge_payload=list(formula="y ~ x",data=data.frame(y=1,x=1),options=list()))
  target <- data.frame(dpar="mu",term="I(x^2)")
  setup_calls <- 0L
  local_mocked_bindings(drm_julia_setup=function(...) {setup_calls<<-setup_calls+1L},.package="drmTMB")
  local_mocked_bindings(julia_call=function(...)list(...),.package="JuliaCall")
  sent <- drmTMB:::drm_julia_call_fixef_inference(object,target,"profile",.9,6L,1L,FALSE)
  expect_identical(tail(sent,1)[[1]],"__bridge_I_7")
  expect_identical(setup_calls,1L)
  object$bridge_public_coef_labels$map[["mu_I(x^2)"]] <- "mu_wrong"
  expect_error(drmTMB:::drm_julia_call_fixef_inference(object,target,"profile",.9,6L,1L,FALSE),"coefficient")
  expect_identical(setup_calls,1L)
})

test_that("versioned transformed labels preserve training bases for newdata", {
  train <- data.frame(y = sin(1:12), x = seq(-2,3,length.out=12), z = cos(1:12))
  new <- data.frame(x = c(10,12,14), z = c(-2,0,2))
  public <- c("mu_(Intercept)","mu_scale(x)","mu_poly(z, 2)1","mu_poly(z, 2)2","sigma_(Intercept)")
  raw <- c("mu_(Intercept)","mu___bridge_scale_1","mu___bridge_poly2c1_2","mu___bridge_poly2c2_3","sigma_(Intercept)")
  result <- list(coef_label_contract="bridge_formula_labels_v1",coef_names=public,
    raw_coef_names=raw,coef_name_map=stats::setNames(as.list(raw),public),
    vcov_names=public,coefficients=c(.1,.3,-.2,.4,-.6),vcov=diag(5),
    loglik=-10,aic=30,bic=32,df=5L,nobs=12L,converged=TRUE,
    fitted=rep(0,12),residuals=rep(0,12),sigma=1,corpairs=list())
  fit <- drmTMB:::new_drmTMB_julia(result,quote(drmTMB()),
    drmTMB::bf(y~scale(x)+poly(z,2),sigma~1),gaussian(),train,"gaussian")
  basis <- poly(train$z,2)
  oracle <- cbind(1,(new$x-mean(train$x))/sd(train$x),
    predict(basis,new$z)) %*% result$coefficients[1:4]
  expect_equal(predict(fit,newdata=new,dpar="mu",type="link"),drop(oracle),tolerance=1e-12)
  rebuilt <- cbind(1,drop(scale(new$x)),poly(new$z,2)) %*% result$coefficients[1:4]
  expect_gt(max(abs(oracle-rebuilt)),1)
})
