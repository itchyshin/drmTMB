suppressPackageStartupMessages(library(glmmTMB))
library(jsonlite); library(numDeriv)
fixture <- fromJSON('../oracle/fixture.json', simplifyVector=FALSE)
reference <- list(fromJSON('../oracle/expected.json',simplifyVector=FALSE),fromJSON('../oracle/expected_noninteger.json',simplifyVector=FALSE))
fits <- fromJSON('../oracle/fitted_optima.json', simplifyVector=FALSE)$fits
priors <- list(c(shape=2,rate=3), c(shape=2.5,rate=1.7))
point_results <- list(); fit_results <- list(); k<-0L
for (j in 1:2) for (case in 0:2) {
 a<-fixture$cases[[case+1L]]
 d<-data.frame(y=unlist(a$y),x=unlist(a$x),g=factor(unlist(a$group)))
 shape<-priors[[j]][['shape']]; rate<-priors[[j]][['rate']]
 p<-data.frame(prior=sprintf('gamma(%.17g,%.17g)', shape/rate,shape),class='ranef_sd',coef='g')
 warnings<-character()
 z<-withCallingHandlers(glmmTMB(y~x+(1|g),dispformula=~x,data=d,family=gaussian(),priors=p),warning=function(w) {warnings<<-c(warnings,conditionMessage(w));invokeRestart('muffleWarning')})
 for (i in 1:5) {
  v<-as.numeric(unlist(fixture$points[[i]])); row<-reference[[j]]$results[[(case*5)+i]]
  stopifnot(row$case==case,row$point==i-1L)
  obj<-as.numeric(z$obj$fn(v)); grad<-as.numeric(z$obj$gr(v)); hess<-numDeriv::jacobian(z$obj$gr,v,method='Richardson')
  ro<-as.numeric(row$objective); rg<-as.numeric(unlist(row$gradient)); rh<-matrix(as.numeric(unlist(row$hessian)),5,5,byrow=TRUE)
  k<-k+1L; point_results[[k]]<-data.frame(case=case,shape=shape,rate=rate,point=i-1L,objective=obj,objective_reference=ro,objective_relative_error=abs(obj-ro)/max(1,abs(ro)),gradient_max_abs_error=max(abs(grad-rg)),hessian_max_scaled_error=max(abs(hess-rh)/pmax(1,abs(rh))))
 }
 ref<-Filter(function(x) x$case==case && x$shape==shape && x$rate==rate,fits)[[1]]
 start<-z$fit$par; optimized<-optim(start,z$obj$fn,z$obj$gr,method='BFGS',control=list(reltol=1e-14,maxit=1000))
 v<-optimized$par
 for (iter in 1:5) {
  g<-as.numeric(z$obj$gr(v)); if(max(abs(g))<1e-9) break
  h<-numDeriv::jacobian(z$obj$gr,v,method='Richardson'); step<-tryCatch(solve(h,g),error=function(e) rep(NA_real_,length(g)))
  if(any(!is.finite(step))) break
  old<-as.numeric(z$obj$fn(v)); lambda<-1
  while(lambda>1/1024 && as.numeric(z$obj$fn(v-lambda*step)) > old + 1e-12) lambda<-lambda/2
  if(lambda<=1/1024) break
  v<-v-lambda*step
 }
 score<-max(abs(z$obj$gr(v))); eligible<-isTRUE(ref$refinement$success) && isTRUE(ref$parameter_comparison_eligible)
 parerr<-if(eligible && z$fit$convergence==0 && optimized$convergence==0 && is.finite(score) && score<=1e-6) max(abs(v-as.numeric(unlist(ref$coordinates)))) else NA_real_
 fit_results[[length(fit_results)+1L]]<-data.frame(case=case,shape=shape,rate=rate,glmm_initial_convergence=z$fit$convergence,glmm_initial_message=z$fit$message,refinement_optim_convergence=optimized$convergence,oracle_success=isTRUE(ref$refinement$success),oracle_eligible=isTRUE(ref$parameter_comparison_eligible),objective=as.numeric(z$obj$fn(v)),oracle_objective=ref$objective,objective_abs_error=abs(as.numeric(z$obj$fn(v))-ref$objective),score_inf=score,parameter_max_abs_error=parerr,beta0=v[1],beta1=v[2],alpha=v[3],gamma=v[4],eta=v[5],warnings=paste(warnings,collapse=' | '))
}
point_results<-do.call(rbind,point_results); fit_results<-do.call(rbind,fit_results)
write.csv(point_results,'point-results.csv',row.names=FALSE,quote=TRUE);write.csv(fit_results,'fit-results.csv',row.names=FALSE,quote=TRUE)
print(point_results);print(fit_results); cat('\nProvenance\n');print(sessionInfo())
stopifnot(nrow(point_results)==30L, all(point_results$objective_relative_error<=1e-8),all(point_results$gradient_max_abs_error<=1e-6),all(point_results$hessian_max_scaled_error<=1e-5))
stopifnot(all(fit_results$glmm_initial_convergence==0), all(fit_results$refinement_optim_convergence==0),all(fit_results$score_inf<=1e-6), all(fit_results$objective_abs_error<=1e-8),sum(!is.na(fit_results$parameter_max_abs_error))==3L,all(fit_results$parameter_max_abs_error[!is.na(fit_results$parameter_max_abs_error)]<=1e-5))
cat('GLMMTMB_ORACLE_COMPARISON_PASS\n')
