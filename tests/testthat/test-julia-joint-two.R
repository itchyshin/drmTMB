two_joint_prepare <- function() {
  d <- data.frame(y=c(0.2,NA,1,NA,0.5,NA,1.3,NA),
    x1=c(-0.5,-0.2,NA,NA,0.2,0.4,NA,NA),
    x2=c(-0.4,-0.1,0.3,0.1,NA,NA,NA,NA),z=seq(-1,1,length.out=8))
  f <- bf(y ~ mi(x1) + mi(x2) + z, sigma ~ 1)
  p <- drmTMB:::drm_julia_joint_prepare(f,gaussian(),d,
    impute=list(x2=x2~1,x1=x1~z),missing=miss_control(response="include",predictor="model"))
  list(prepared=p,data=d,formula=f)
}

test_that("two Gaussian Julia preparation preserves both native designs and all masks", {
  v<-two_joint_prepare();p<-v$prepared$payload
  expect_identical(p$schema,"joint_missing_two_gaussian_v1")
  expect_identical(p$variable,c("x1","x2"))
  expect_equal(p$mu_col,c(2L,3L))
  expect_equal(p$mu_names[p$mu_col],c("mi(x1)","mi(x2)"))
  expect_equal(vapply(p$X_predictor,ncol,integer(1)),c(2L,1L))
  expect_equal(p$observed_x,cbind(!is.na(v$data$x1),!is.na(v$data$x2)))
  expect_length(unique(paste(p$observed_y,p$observed_x[,1],p$observed_x[,2])),8L)
  pdrop<-drmTMB:::drm_julia_joint_prepare(v$formula,gaussian(),v$data,
    impute=list(x1=x1~1,x2=x2~1),missing=miss_control(predictor="model"))$payload
  expect_equal(pdrop$original_row,which(!is.na(v$data$y)))
  for (f in list(bf(y~mi(x1)+mi(x2)+x1),bf(y~mi(x1)+mi(x2),sigma~x2))) {
    expect_error(drmTMB:::drm_julia_joint_prepare(f,gaussian(),v$data,
      impute=list(x1=x1~z,x2=x2~1),missing=miss_control(response="include",predictor="model")),"modelled")
  }
  expect_error(drmTMB:::drm_julia_joint_prepare(v$formula,gaussian(),v$data,
    impute=list(x1=x1~z,x2=x2~x1),missing=miss_control(response="include",predictor="model")),"modelled")
})

two_joint_result <- function(p) {
  n<-length(p$y);blocks<-c(rep("mu",length(p$mu_names)),rep("sigma",length(p$sigma_names)))
  terms<-c(p$mu_names,p$sigma_names)
  for (j in 1:2) {
    blocks<-c(blocks,rep(paste0("mi_",p$variable[j]),length(p$predictor_names[[j]])),paste0("logsd_mi_",p$variable[j]))
    terms<-c(terms,p$predictor_names[[j]],"log_sd")
  }
  theta<-seq_along(blocks)/10;sdids<-which(startsWith(blocks,"logsd_mi_"));theta[sdids]<-log(c(1.5,2))
  V<-diag(length(theta))/10;V[sdids[1],sdids[2]]<-V[sdids[2],sdids[1]]<-0.02
  labels<-paste0(blocks,"_",terms)
  tabs<-lapply(1:2,function(j) {
    ox<-p$observed_x[,j]
    list(variable=rep(p$variable[j],n),original_row=p$original_row,model_row=seq_len(n),observed=ox,
      estimate=ifelse(ox,p$x[,j],0.2*j),std_error=ifelse(ox,NaN,0.3),
      source=ifelse(ox,"observed","conditional_mode"),uncertainty_status=rep("ok",n),se_available=!ox)
  });names(tabs)<-p$variable
  C<-array(0,c(n,2,2));C[,1,1]<-ifelse(p$observed_x[,1],0,0.1);C[,2,2]<-ifelse(p$observed_x[,2],0,0.2)
  C[,1,2]<-C[,2,1]<-ifelse(!p$observed_x[,1]&!p$observed_x[,2],-0.01,0)
  list(schema="joint_missing_two_gaussian_result_v1",coef_names=labels,coefficients=theta,vcov=V,vcov_names=labels,
    coefficient_blocks=blocks,coefficient_terms=terms,loglik=-12.3,aic=44.6,bic=45,df=length(theta),
    nobs=sum(p$observed_y),converged=TRUE,iterations=7L,fitted=seq_len(n)/3,residuals=rep(0.1,n),sigma=rep(1,n),
    corpairs=list(),dpars=list(),optimizer_status="converged",covariance_status="observed_information_inverse",
    original_row=p$original_row,observed_y=p$observed_y,observed_x=p$observed_x,imputation=tabs,conditional_covariance=C)
}

test_that("two Gaussian R result keeps both SD transforms and variable summaries", {
  v<-two_joint_prepare();p<-v$prepared$payload;r<-two_joint_result(p)
  fit<-drmTMB:::drm_julia_joint_result(r,v$prepared,quote(drmTMB()),v$formula,gaussian())
  expect_equal(unname(coef(fit,dpar="sigma_mi_x1")),1.5)
  expect_equal(unname(coef(fit,dpar="sigma_mi_x2")),2)
  expect_equal(vcov(fit)["sigma_mi_x1:x1","sigma_mi_x2:x2"],0.02*1.5*2)
  expect_identical(fit$joint$conditional_covariance,r$conditional_covariance)
  expect_error(imputed(fit),"variable.*required")
  expect_equal(imputed(fit,variable="x2",rows="all")$observed,p$observed_x[,2])
  expect_equal(imputed(fit,variable="x1")$original_row,p$original_row[!p$observed_x[,1]])
  expect_true(all(is.na(imputed(fit,variable="x2",se=FALSE)$std_error)))
  expect_equal(predict(fit),r$fitted)
  nd<-data.frame(x1=c(0.2,0.5),x2=c(-0.5,0.6),z=c(0.1,0.3))
  expect_equal(unname(predict(fit,newdata=nd)),as.numeric(cbind(1,nd$x1,nd$x2,nd$z)%*%coef(fit,dpar="mu")))
  for (kind in c("mask","table","covariance")) {
    bad<-r
    if(kind=="mask") bad$observed_x[1,2]<-FALSE
    if(kind=="table") bad$imputation$x2$variable[]<-"x1"
    if(kind=="covariance") bad$conditional_covariance[1,1,2]<-2
    expect_error(drmTMB:::drm_julia_joint_result(bad,v$prepared,quote(drmTMB()),v$formula,gaussian()))
  }
})
