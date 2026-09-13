#!/usr/bin/env Rscript
x<-utils::read.csv("docs/dev-log/evidence/ou-v1-r5/sensitivity.csv");stopifnot(nrow(x)==6L,identical(x$model[[1]],"bm"),identical(x$alpha_assumed[-1],c(.1,.3,.7,1.3,2.5)),all(x$convergence==0),all(x$pdHess),all(is.finite(as.matrix(x[,c("objective","AIC","mu_intercept","sigma_intercept")]))));cat("OU_V1_R5_PASS\n")
