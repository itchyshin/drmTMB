#!/usr/bin/env Rscript
x<-utils::read.csv("docs/dev-log/evidence/ou-v1-r31/comparison.csv");stopifnot(nrow(x)==2,identical(as.character(x$point),c("interior","ridge")),all(is.finite(x$laplace_minus_q7)),all(is.finite(x$refinement)));cat("OU_V1_R31_PASS\n")
