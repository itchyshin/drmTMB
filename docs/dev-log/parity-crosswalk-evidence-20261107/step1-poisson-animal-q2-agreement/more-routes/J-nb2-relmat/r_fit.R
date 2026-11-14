# usage: Rscript r_fit.R <A|B|C|D>   (fits in R, compares to julia_coef.csv)
route <- "B"
.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); library(drmTMB)
O <- file.path("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-nb2relmat")
d <- read.csv(file.path(O,"data.csv"))
K <- as.matrix(read.csv(file.path(O,"K.csv"), header=FALSE))
ids <- read.csv(file.path(O,"K_ids.csv"))$id; dimnames(K) <- list(ids, ids)
d$id <- factor(d$g, levels = ids)
term <- "relmat"
f <- if (term == "animal") y ~ x + animal(1 + x | id, A = K) else y ~ x + relmat(1 + x | id, K = K)
environment(f) <- environment()
s0 <- as.formula(sprintf('sd(id, level = "%s", dpar = "mu", coef = "(Intercept)") ~ z0', term))
s1 <- as.formula(sprintf('sd(id, level = "%s", dpar = "mu", coef = "x") ~ z1', term))
fam <- switch(route, A = stats::poisson(), B = nbinom2(), gaussian())
fm <- if (route == "A") bf(f, s0, s1) else bf(f, sigma ~ 1, s0, s1)
t0 <- Sys.time(); fit <- drmTMB(fm, family = fam, data = d); el <- Sys.time() - t0
cat("R time", format(el), "\n"); print(summary(fit))
ct <- summary(fit)$coefficients; print(ct)
fe <- fixef(fit); str(fe, max.level = 1)
rv <- unlist(unname(fe)); se_r <- ct[[grep("Std|se", names(ct), ignore.case=TRUE)[1]]]
j <- read.csv(file.path(O,"julia_coef.csv"))
stopifnot(length(rv) == nrow(j), nrow(ct) >= nrow(j))
j$r_est <- rv; j$r_se <- se_r[seq_len(nrow(j))]
j$diff <- j$est - j$r_est; j$diff_in_se <- j$diff / j$se; j$se_ratio <- j$se / j$r_se
print(j, digits = 6)
cat(sprintf("ROUTE %s max|diff| est %.3e (SE units %.3e); max |se ratio-1| %.3e\n", route,
  max(abs(j$diff)), max(abs(j$diff_in_se)), max(abs(j$se_ratio - 1))))
llj <- scan(file.path(O,"julia_ll.txt"), what="", quiet=TRUE)
cat(sprintf("ll Julia %s R %.8f diff %.2e; R conv: %s; Julia converged: %s\n", llj[1], as.numeric(logLik(fit)),
  as.numeric(llj[1]) - as.numeric(logLik(fit)), paste(tryCatch(fit$opt$convergence, error=function(e) NA)), llj[2]))
write.csv(j, file.path(O,"comparison.csv"), row.names = FALSE)
