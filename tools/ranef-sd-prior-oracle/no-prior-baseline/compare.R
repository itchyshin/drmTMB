args<-commandArgs(trailingOnly=TRUE); stopifnot(length(args) %in% 1:2)
root<-normalizePath(args[[1]],mustWork=TRUE)
outdir<-if(length(args)==2) normalizePath(args[[2]],mustWork=TRUE) else root
a<-readRDS(file.path(root,'base-results.rds')); b<-readRDS(file.path(root,'candidate-results.rds'))
stopifnot(identical(names(a),names(b)))
rows<-list()
for(nm in names(a)) {
 x<-a[[nm]]; y<-b[[nm]]
 stopifnot(identical(x$kind,y$kind),identical(x$names,y$names),identical(x$positions,y$positions),identical(x$convergence,0L),identical(y$convergence,0L),identical(x$estimator,y$estimator))
 stopifnot(is.finite(max(abs(x$gradient))),is.finite(max(abs(y$gradient))),max(abs(x$gradient))<=1e-6,max(abs(y$gradient))<=1e-6)
 stopifnot(min(eigen((x$hessian+t(x$hessian))/2,symmetric=TRUE,only.values=TRUE)$values)>0,min(eigen((y$hessian+t(y$hessian))/2,symmetric=TRUE,only.values=TRUE)$values)>0)
 obj<-abs(x$objective-y$objective)/max(1,abs(x$objective)); ll<-abs(x$data_logLik-y$data_logLik)/max(1,abs(x$data_logLik)); theta<-max(abs(x$theta-y$theta)); grad<-max(abs(x$gradient-y$gradient)); hess<-max(abs(x$hessian-y$hessian)/pmax(1,abs(x$hessian)))
 stopifnot(obj<=1e-8,ll<=1e-8,theta<=1e-5,grad<=1e-6,hess<=1e-5,identical(x$penalty,y$penalty))
 pt_obj<-pt_grad<-pt_hess<-numeric(length(x$points))
 for(i in seq_along(x$points)) {
  p<-x$points[[i]]; q<-y$points[[i]]
  pt_obj[i]<-abs(p$objective-q$objective)/max(1,abs(p$objective)); pt_grad[i]<-max(abs(p$gradient-q$gradient)); pt_hess[i]<-max(abs(p$hessian-q$hessian)/pmax(1,abs(p$hessian)))
 }
 stopifnot(all(is.finite(c(pt_obj,pt_grad,pt_hess))),max(pt_obj)<=1e-8,max(pt_grad)<=1e-6,max(pt_hess)<=1e-5)
 rows[[nm]]<-data.frame(case=nm,relative_objective=obj,relative_logLik=ll,absolute_theta=theta,absolute_score=grad,scaled_hessian=hess,point_objective=max(pt_obj),point_gradient=max(pt_grad),point_hessian=max(pt_hess),base_score=max(abs(x$gradient)),candidate_score=max(abs(y$gradient)),base_convergence=x$convergence,candidate_convergence=y$convergence,estimator=x$estimator)
}
out<-do.call(rbind,rows); write.csv(out,file.path(outdir,'comparison.csv'),row.names=FALSE,quote=FALSE); print(out,digits=17,row.names=FALSE);cat('R_BASELINE_CANDIDATE_IDENTITY_PASS\n')
