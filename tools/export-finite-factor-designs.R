#!/usr/bin/env Rscript
# Generated native preparation arrays; no optimizer or fit is run.
a <- commandArgs(TRUE)
if(length(a)!=1L) stop("usage: export-finite-factor-designs.R NEW_JSON")
output <- a[1];if(file.exists(output)) stop("refusing stale output")
pkgload::load_all(quiet=TRUE,recompile=FALSE)
sha <- function(p) digest::digest(file=p,algo="sha256")
manifest <- function() {p<-c(sort(list.files("R",pattern="[.]R$",full.names=TRUE)),"NAMESPACE");as.list(setNames(vapply(p,sha,""),p))}
before <- manifest();levels <- c("low","medium","high");n <- 36L
da <- rep(c("a","b","c"),12);db <- rep(c("cold","warm"),18);z <- seq(-1,1,length.out=n)
labels <- levels[rep(1:3,12)];labels[c(5,12,19,29)] <- NA_character_
d <- data.frame(y=.2+.3*z+.1*(da=="b")-.15*(db=="warm"),x=labels,a=da,b=db,z=z,flag=rep(c(FALSE,TRUE),18))
formulas <- c(intercept="y ~ a + mi(x)",factor_first="y ~ 0 + a + b + mi(x)",
  marker_first="y ~ 0 + mi(x) + a + b",numeric_before="y ~ 0 + z + mi(x) + a",
  interaction="y ~ 0 + a*b + mi(x)",interaction_marker_first="y ~ 0 + mi(x) + a*b",
  interaction_only_before="y ~ 0 + a:b + mi(x)",
  bool_first="y ~ 0 + flag + mi(x)",bool_marker_first="y ~ 0 + mi(x) + flag",
  bool_interaction="y ~ 0 + flag*a + mi(x)")
out <- list(schema="finite_factor_designs_v1",source_before=before,runner_sha256=sha("tools/export-finite-factor-designs.R"),
  R_version=R.version.string,n=n,levels=levels,formulas=as.list(formulas),cases=list())
for(kind in c("ordinal","categorical")) {
  data <- d;data$x <- factor(data$x,levels=levels,ordered=kind=="ordinal")
  im <- list(x=impute_model(x~1,family=if(kind=="ordinal") cumulative_logit() else categorical()))
  cases <- list()
  for(id in names(formulas)) {
    form <- eval(as.call(list(as.name("bf"), as.formula(formulas[[id]]), quote(sigma~1))))
    prepared <- drm_julia_joint_prepare(form,gaussian(),data,impute=im,
      missing=miss_control(response="include",predictor="model"))
    p <- prepared$payload
    # Independently compare native preparation to standard R formula expansion.
    env <- new.env(parent=globalenv());env$mi <- identity
    f <- as.formula(formulas[[id]],env=env)
    oracle <- matrix(NA_real_,n*3L,ncol(p$X_mu_state))
    for(k in 1:3) {
      ds <- data;ds$x <- factor(rep(levels[k],n),levels=levels,ordered=kind=="ordinal")
      X <- model.matrix(f,ds)
      stopifnot(identical(colnames(X),p$mu_names))
      oracle[seq(k,n*3L,by=3L),] <- X
    }
    stopifnot(max(abs(oracle-p$X_mu_state))<1e-12)
    cases[[id]] <- list(formula=formulas[[id]],mu_names=p$mu_names,
      state_design=unname(p$X_mu_state),original_row=p$original_row,
      observed_x=p$observed_x,observed_y=p$observed_y,model_matrix_error=max(abs(oracle-p$X_mu_state)))
  }
  out$cases[[kind]] <- cases
}
out$source_after <- manifest();out$source_unchanged <- identical(before,out$source_after)
stopifnot(out$source_unchanged)
dir.create(dirname(output),recursive=TRUE,showWarnings=FALSE)
jsonlite::write_json(out,output,pretty=TRUE,auto_unbox=TRUE,digits=17)
cat("FINITE_FACTOR_NATIVE_DESIGNS_PASS cases=",length(formulas)*2L,"\n",sep="")
