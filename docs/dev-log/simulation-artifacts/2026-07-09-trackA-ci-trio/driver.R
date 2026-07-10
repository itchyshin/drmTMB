# Track A: CI trio (Wald + Profile) coverage + DGP robustness for the validated
# unstructured non-Gaussian cells. Confirmed maps: beta phi = exp(-2*log_sigma),
# nbinom2 size = exp(-2*log_sigma). Profile is added for the SCALE coefficients and
# for the beta n=800 finite-rate probe (does profile rescue it?).
if (dir.exists(path.expand("~/Rlib"))) .libPaths("~/Rlib")
suppressMessages({library(drmTMB); library(parallel)})
NSIM   <- as.integer(Sys.getenv("NSIM", "400"))
NCORES <- as.integer(Sys.getenv("NCORES", "90"))
NS     <- as.integer(strsplit(Sys.getenv("NS", "60,150,400,800"), ",")[[1]])
OUT    <- Sys.getenv("OUTFILE", "~/drmTMB_work/trackA_trio_results.tsv")

# each spec: sim(n,seed) -> data; form; fam; truth (link scale);
# prof = which params to ALSO profile (scale coefs + the beta case).
specs <- list(
  binomial_mu = list(form=quote(bf(y~x)), fam=quote(binomial()),
    truth=c("fixef:mu:(Intercept)"=0.4,"fixef:mu:x"=0.7), prof=character(0),
    sim=function(n,s){set.seed(s);x<-rnorm(n);data.frame(y=rbinom(n,1,plogis(0.4+0.7*x)),x=x)}),
  poisson_mu = list(form=quote(bf(y~x)), fam=quote(poisson()),
    truth=c("fixef:mu:(Intercept)"=0.4,"fixef:mu:x"=0.5), prof=character(0),
    sim=function(n,s){set.seed(s);x<-rnorm(n);data.frame(y=rpois(n,exp(0.4+0.5*x)),x=x)}),
  beta_ls = list(form=quote(bf(y~x, sigma~x)), fam=quote(beta()),
    truth=c("fixef:mu:(Intercept)"=0.2,"fixef:mu:x"=0.7,"fixef:sigma:(Intercept)"=-0.7,"fixef:sigma:x"=0.2),
    prof=c("fixef:sigma:(Intercept)","fixef:sigma:x"),
    sim=function(n,s){set.seed(s);x<-rnorm(n);mu<-plogis(0.2+0.7*x);phi<-exp(-2*(-0.7+0.2*x))
      data.frame(y=rbeta(n,mu*phi,(1-mu)*phi),x=x)}),
  nbinom2_ls = list(form=quote(bf(y~x, sigma~x)), fam=quote(nbinom2()),
    truth=c("fixef:mu:(Intercept)"=0.6,"fixef:mu:x"=0.4,"fixef:sigma:(Intercept)"=-0.5,"fixef:sigma:x"=0.2),
    prof=c("fixef:sigma:(Intercept)","fixef:sigma:x"),
    sim=function(n,s){set.seed(s);x<-rnorm(n);mu<-exp(0.6+0.4*x);size<-exp(-2*(-0.5+0.2*x))
      data.frame(y=rnbinom(n,mu=mu,size=size),x=x)}),
  # robustness: two covariates + larger effects (Poisson)
  poisson_mu_2cov = list(form=quote(bf(y~x+z)), fam=quote(poisson()),
    truth=c("fixef:mu:(Intercept)"=0.3,"fixef:mu:x"=0.9,"fixef:mu:z"=-0.6), prof=character(0),
    sim=function(n,s){set.seed(s);x<-rnorm(n);z<-rnorm(n);data.frame(y=rpois(n,exp(0.3+0.9*x-0.6*z)),x=x,z=z)})
)

ci_get <- function(fit, parm, method) {
  a <- tryCatch(confint(fit, method=method, parm=parm), error=function(e) NULL)
  if (is.null(a) || !("parm" %in% names(a))) return(c(NA,NA))
  r <- a[a$parm==parm,,drop=FALSE]; if (nrow(r)!=1) return(c(NA,NA))
  c(r$lower, r$upper)
}
one <- function(sp, n, seed) {
  d <- sp$sim(n, seed)
  fit <- tryCatch(drmTMB(eval(sp$form), family=eval(sp$fam), data=d, control=drm_control(se=TRUE)),
                  error=function(e) NULL)
  rows <- list()
  for (p in names(sp$truth)) {
    chans <- c("wald", if (p %in% sp$prof) "profile")
    for (ch in chans) {
      lo<-NA; hi<-NA
      if (!is.null(fit)) { ci<-ci_get(fit,p,ch); lo<-ci[1]; hi<-ci[2] }
      fin <- is.finite(lo) && is.finite(hi)
      rows[[length(rows)+1]] <- data.frame(param=p, channel=ch,
        finite=fin, covered=(fin && sp$truth[p]>=lo && sp$truth[p]<=hi), width=if(fin) hi-lo else NA_real_)
    }
  }
  do.call(rbind, rows)
}

grid <- expand.grid(spec=names(specs), n=NS, stringsAsFactors=FALSE)
out <- list()
for (gi in seq_len(nrow(grid))) {
  nm<-grid$spec[gi]; n<-grid$n[gi]; sp<-specs[[nm]]
  reps <- mclapply(seq_len(NSIM), function(s) one(sp, n, 300000L*gi+s), mc.cores=NCORES)
  reps <- reps[!vapply(reps, is.null, logical(1))]
  allrows <- do.call(rbind, reps)
  for (p in names(sp$truth)) for (ch in c("wald","profile")) {
    sub <- allrows[allrows$param==p & allrows$channel==ch,,drop=FALSE]
    if (!nrow(sub)) next
    fr <- mean(sub$finite); ok <- sub$covered[sub$finite & !is.na(sub$covered)]
    cov <- if(length(ok)) mean(ok) else NA_real_
    mcse <- if(length(ok)) sqrt(cov*(1-cov)/length(ok)) else NA_real_
    out[[length(out)+1]] <- data.frame(spec=nm, n=n, param=p, channel=ch, nsim=nrow(sub),
      finite_rate=round(fr,3), coverage=round(cov,3), mcse=round(mcse,4),
      mean_width=round(mean(sub$width[sub$finite],na.rm=TRUE),3))
  }
  cat(sprintf("done %s n=%d\n", nm, n))
}
res <- do.call(rbind, out)
res$clears_094 <- with(res, finite_rate>=0.95 & (coverage+2*mcse)>=0.94)
write.table(res, OUT, sep="\t", row.names=FALSE, quote=FALSE)
cat("\n===== TRACK A: WALD vs PROFILE COVERAGE =====\n"); print(res, row.names=FALSE)
