base <- "/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b"
.libPaths(c(file.path(base, "r-final899-lib"), .libPaths()))
library(drmTMB)
d <- data.frame(x = c(-2,-1,0,1,2,3), y = c(-1,0,0.2,0.8,1.1,2))
p <- drm_priors(drm_prior_normal("mu", "x", mean=0.3, sd=2),
                drm_prior_ridge("sigma", "x", lambda=4))
f <- drmTMB(bf(mu=y~x,sigma=~x), data=d, priors=p)
t <- f$obj$par*0+0.2
mi <- which(names(t)=="beta_mu"); si <- which(names(t)=="beta_sigma")
X <- model.matrix(~x,d)
pen <- -dnorm(t[mi[2]],0.3,2,log=TRUE)+0.5*4*t[si[2]]^2
expected <- -sum(dnorm(d$y,drop(X%*%t[mi]),exp(drop(X%*%t[si])),log=TRUE))+pen
pg <- numeric(length(t)); pg[mi[2]] <- (t[mi[2]]-0.3)/4; pg[si[2]] <- 4*t[si[2]]
# Central differences provide an independent derivative target.
fd <- vapply(seq_along(t),function(i) {a<-b<-t;a[i]<-a[i]+1e-5;b[i]<-b[i]-1e-5;(f$obj$fn(a)-f$obj$fn(b))/2e-5},numeric(1))
u <- update(f)
valid <- function(value,gradient,metadata) {
 stopifnot(abs(value-expected)<=1e-10,
           max(abs(gradient-fd)/(1+abs(fd)))<=1e-6,
           identical(metadata,f$resolved_priors))
 TRUE
}
value <- f$obj$fn(t); gradient <- as.numeric(f$obj$gr(t))
stopifnot(valid(value,gradient,u$resolved_priors))
dropped <- update(f,priors=NULL)
mutants <- list(
 dropped_sigma=list(value-0.5*4*t[si[2]]^2,gradient,u$resolved_priors),
 excluded_intercept_penalized=list(value+0.5*4*t[mi[1]]^2,gradient,u$resolved_priors),
 wrong_lambda_factor=list(value+0.5*4*t[si[2]]^2,gradient,u$resolved_priors),
 missing_derivative=list(value,gradient-pg,u$resolved_priors),
 duplicated_penalty=list(value+pen,gradient,u$resolved_priors),
 dropped_rebuild_metadata=list(value,gradient,dropped$resolved_priors))
rejected <- vapply(mutants,function(m) inherits(try(do.call(valid,m),silent=TRUE),"try-error"),logical(1))
print(rejected)
stopifnot(all(rejected))
write.csv(data.frame(control=names(rejected),rejected=unname(rejected)),file.path(base,"evidence/r-final899-negative-controls.csv"),row.names=FALSE)
cat("PRIOR_NEGATIVE_CONTROLS_PASS 6/6; unchanged compiled target accepted\n")
