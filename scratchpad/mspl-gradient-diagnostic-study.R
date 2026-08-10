suppressMessages(devtools::load_all(quiet=TRUE))
# Sweep from fully identified to fully separated by lowering the 'd' cell's
# true log-odds. At eta_d = 0 the design is ordinary; by -50 it is separated.
grid <- c(0, -1, -2, -3, -4, -6, -10, -50)
cat(sprintf("%8s %7s %9s %12s %14s %10s %9s\n",
            "eta_d","events_d","sep","max|grad|","score_dist","max SE","spd"))
for (e in grid) {
  set.seed(20260809); G <- 12
  d <- data.frame(block=factor(rep(seq_len(G), each=8)),
                  trt=factor(rep(c("a","b","c","d"), times=2*G)))
  u <- rnorm(G,0,0.8)
  eta <- c(a=0.5,b=1.2,c=-0.3,d=e)[as.character(d$trt)] + u[as.integer(d$block)]
  d$y <- rbinom(nrow(d),1,plogis(eta))
  X <- model.matrix(y ~ trt, d)
  sep <- tryCatch(isTRUE(detectseparation::detect_separation(
           x=X, y=d$y, family=binomial(), intercept=FALSE)$outcome),
         error=function(err) NA)
  f <- tryCatch(drmTMB(bf(y ~ trt + (1|block)), family=binomial(), data=d,
                       estimator="mspl"), error=function(err) err)
  if (inherits(f,"error")) { cat(sprintf("%8.0f %7s  fit error\n", e, "-")); next }
  w <- f$mspl$wald
  cat(sprintf("%8.0f %7d %9s %12.4g %14.4g %10.3g %9s\n",
              e, sum(d$y[d$trt=="d"]), sep,
              w$unpenalized_gradient_max_abs, w$unpenalized_score_distance,
              max(w$std_error, na.rm=TRUE), w$spd))
}
