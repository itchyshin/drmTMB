# Recompute numerical/name oracles from a retained RDS; never refit.
args<-commandArgs(trailingOnly=TRUE);stopifnot(length(args)%in%c(1L,2L))
receipt<-readRDS(args[1])
validate<-function(out,current=TRUE) {
 required<-c('quadratic','punctuation','two_factors','no_intercept','declared_levels','transforms',
  'reversed_two_factors','unary_plus','grouped_arithmetic','decimal_power','nested_precedence','nested_parentheses','nested_scale','mixed_scalar','scalar_plain','conditional_scalar','negated_scalar')
 targets<-c('I(x^2)','gb','x:gb')
 formulas<-list(quadratic=~x+I(x^2)+g+x:g,punctuation=~x+gp+x:gp,
  two_factors=~g*factor(h),no_intercept=~0+g+x:g,declared_levels=~gn+x:gn,
  transforms=~scale(x)+poly(z,2)+I(x*z),
  reversed_two_factors=~g+factor(h)+factor(h):g,
  unary_plus=~I(+x),grouped_arithmetic=~I(x+(z+2)),decimal_power=~I(x^2.0),
  nested_precedence=~log1p((1+I(x^2))/2),nested_parentheses=~log1p((I(x^2))),
 nested_scale=~exp((1+scale(x))/2),mixed_scalar=~exp((scale(x)+I(z^2))/2),
 scalar_plain=~sin((x+z)/2),conditional_scalar=~ifelse(x>0,x,0),negated_scalar=~ifelse(!(x>0),x,0))
 stopifnot(identical(out$status,'PASS'),identical(names(out$results),required),
  identical(names(out$inference),targets),isTRUE(out$ordinary_batch),
  identical(out$source_before,out$source_after),!anyDuplicated(names(out$source_before)))
 jlroot<-normalizePath('../DRM.jl',mustWork=TRUE)
 paths<-sort(unique(normalizePath(c(list.files('R',pattern='[.]R$',full.names=TRUE),
  list.files(file.path(jlroot,'src'),pattern='[.]jl$',full.names=TRUE,recursive=TRUE),
  'tools/run-julia-coefficient-labels-public.R',file.path(jlroot,c('Project.toml','Manifest.toml'))))))
 stopifnot(identical(sort(names(out$source_before)),paths),
  identical(normalizePath(out$runtime$source,mustWork=TRUE),file.path(jlroot,'src','DRM.jl')))
 if(current)for(p in paths)stopifnot(identical(digest::digest(file=p,algo='sha256'),out$source_before[[p]]))
 scalar<-function(x)is.numeric(x)&&length(x)==1L&&!is.na(x)&&is.finite(x)
 stopifnot(scalar(out$elapsed),out$elapsed>=0,out$elapsed<180,
  scalar(out$runtime$threads),out$runtime$threads==1,scalar(out$runtime$blas),out$runtime$blas==1)
 for(nm in required) {
  r<-out$results[[nm]]
  stopifnot(identical(r$status,'returned'),isTRUE(r$converged),is.data.frame(r$data),
    is.matrix(r$X),is.numeric(r$X),nrow(r$X)==96L,nrow(r$data)==96L,
    !anyDuplicated(r$actual),setequal(r$actual,r$expected),identical(r$expected,colnames(r$X)),
    is.numeric(r$beta),length(r$beta)==ncol(r$X),identical(names(r$beta),r$actual),
    all(is.finite(r$beta)),scalar(r$loglik),qr(r$X)$rank==ncol(r$X))
  stopifnot(identical(r$X,model.matrix(formulas[[nm]],r$data)))
  beta<-drop(solve(crossprod(r$X),crossprod(r$X,r$data$y)))
  rss<-sum((r$data$y-r$X%*%beta)^2)
  stopifnot(max(abs(r$beta[r$expected]-beta))<1e-5,
    abs(r$loglik-sum(dnorm(r$data$y,drop(r$X%*%beta),sqrt(rss/96),log=TRUE)))<1e-7)
  labels<-r$labels
  stopifnot(identical(labels$contract,'bridge_formula_labels_v1'),
   !anyDuplicated(labels$public),!anyDuplicated(labels$raw),
   length(labels$public)==ncol(r$X)+1L,length(labels$raw)==length(labels$public),
   length(labels$map)==length(labels$public),!anyDuplicated(names(labels$map)),
   setequal(names(labels$map),labels$public),
   identical(labels$public,c(paste0('mu_',r$actual),'sigma_(Intercept)')),
   identical(unname(labels$map[labels$public]),labels$raw))
  keys<-c(paste0('mu_',r$expected),'sigma_(Intercept)')
  stopifnot(is.numeric(r$full_beta),all(is.finite(r$full_beta)),
   identical(names(r$full_beta),labels$public),
   identical(r$bridge_names,labels$public),
   identical(unname(r$full_beta),r$bridge_beta),
   is.matrix(r$V),is.numeric(r$V),all(is.finite(r$V)),
   identical(dimnames(r$V),list(labels$public,labels$public)),
   identical(r$V,r$bridge_V))
  b<-r$full_beta[keys];res<-r$data$y-drop(r$X%*%b[seq_len(ncol(r$X))])
  stopifnot(identical(unname(b[seq_len(ncol(r$X))]),unname(r$beta[r$expected])),
   abs(sum(dnorm(r$data$y,drop(r$X%*%b[seq_len(ncol(r$X))]),exp(tail(b,1)),log=TRUE))-r$loglik)<1e-7)
  invvar<-exp(-2*tail(b,1));cross<-2*drop(crossprod(r$X,res))*invvar
  H<-rbind(cbind(crossprod(r$X)*invvar,cross),c(cross,2*sum(res^2)*invvar))
  stopifnot(max(abs(r$V[keys,keys]-solve(H)))<1e-7)
 }
 r<-out$results$quadratic;X<-r$X;y<-r$data$y
 beta<-drop(solve(crossprod(X),crossprod(X,y)));rss<-sum((y-X%*%beta)^2)
 endpoints<-function(x) {stopifnot(scalar(x$lower),scalar(x$upper),x$lower<=x$upper);c(x$lower,x$upper)}
 for(term in targets) {
  t<-out$inference[[term]];stopifnot(identical(t$status,'returned'))
  for(op in c('public','direct','bootstrap','direct_bootstrap'))stopifnot(identical(t[[op]]$status,'returned'))
  k<-match(term,colnames(X));w<-sqrt(expm1(qchisq(.9,1)/96)*rss*solve(crossprod(X))[k,k]);oracle<-c(beta[k]-w,beta[k]+w)
  p<-t$public$value;d<-t$direct$value;b<-t$bootstrap$value;db<-t$direct_bootstrap$value
  stopifnot(identical(p$parm,paste0('fixef:mu:',term)),identical(p$conf.status,'profile'),
   max(abs(endpoints(p)-oracle))<1e-5,identical(d$coef,term),identical(d$status,'profile'),
   scalar(d$attempted),d$attempted==1,max(abs(endpoints(d)-oracle))<1e-5,
   identical(b$parm,paste0('fixef:mu:',term)),identical(b$conf.status,'bootstrap'),
   identical(db$coef,term),identical(db$status,'bootstrap'),
   scalar(b$bootstrap.n),b$bootstrap.n==6,scalar(b$bootstrap.failed),b$bootstrap.failed==0,
   scalar(db$used),db$used==6,scalar(db$failed),db$failed==0,
   max(abs(endpoints(b)-endpoints(db)))<1e-10)
 }
 TRUE
}
stopifnot(validate(receipt));cat('COEFFICIENT_LABEL_RECEIPT_PASS:17 cases and12 inference operations, current source hashes\n')
if(length(args)==2L) {
 stopifnot(args[2]=='--self-test')
 coherent_damage<-function(z,sigma=FALSE) {
  r<-z$results$quadratic;keys<-c(paste0('mu_',r$expected),'sigma_(Intercept)')
  index<-if(sigma)length(r$full_beta)else 1L
  r$full_beta[index]<-r$full_beta[index]+.1;r$bridge_beta<-unname(r$full_beta)
  b<-r$full_beta[keys];res<-r$data$y-drop(r$X%*%b[seq_len(ncol(r$X))])
  invvar<-exp(-2*tail(b,1));cross<-2*drop(crossprod(r$X,res))*invvar
  H<-rbind(cbind(crossprod(r$X)*invvar,cross),c(cross,2*sum(res^2)*invvar))
  r$V[keys,keys]<-solve(H);r$bridge_V<-r$V;z$results$quadratic<-r;z
 }
 damages<-list(
  function(z){z$results$quadratic<-NULL;z},
  function(z){z$inference[['gb']]<-NULL;z},
  function(z){z$results$quadratic$beta[1]<-z$results$quadratic$beta[1]+.1;z},
  function(z){z$inference[['gb']]$public$value$lower<-NULL;z},
  function(z){z$inference[['gb']]$direct$value$coef<-'gc';z},
  function(z){z$inference[['gb']]$direct_bootstrap$value$used<-5L;z},
  function(z){z$results$quadratic$labels$map[[1]]<-'mu_wrong';z},
  function(z){z$results$quadratic$V[1,2]<-z$results$quadratic$V[1,2]+.1;z},
  function(z){z$results$quadratic$V<-z$results$quadratic$V[rev(seq_len(nrow(z$results$quadratic$V))),,drop=FALSE];z},
  function(z){z$results$quadratic$bridge_beta[1]<-z$results$quadratic$bridge_beta[1]+.1;z},
  function(z)coherent_damage(z),
  function(z)coherent_damage(z,sigma=TRUE),
  function(z){key<-grep('/src/bridge[.]jl$',names(z$source_before),value=TRUE);z$source_before[key]<-z$source_after[key]<-NULL;z})
 for(f in damages)stopifnot(inherits(try(validate(f(receipt)),silent=TRUE),'try-error'))
 cat('COEFFICIENT_LABEL_SELFTEST_PASS:13 damaged receipts rejected\n')
}
