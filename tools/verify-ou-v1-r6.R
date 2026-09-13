#!/usr/bin/env Rscript
pre<-identical(commandArgs(trailingOnly=TRUE),"--preflight");x<-utils::read.csv(file.path("docs/dev-log/evidence/ou-v1-r6",if(pre)"preflight.csv"else"sensitivity.csv"));stopifnot(nrow(x)==if(pre)1L else 6L,all(is.finite(x$elapsed_seconds)));cat(if(pre)"OU_V1_R6_PREFLIGHT_PASS\n"else"OU_V1_R6_PASS\n")
