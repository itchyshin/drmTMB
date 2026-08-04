suppressMessages(library(drmTMB))
src <- readLines("tests/testthat/test-phylo-interaction.R")
first <- grep("^test_that", src)[1]
eval(parse(text=paste(src[1:(first-1)],collapse="\n")), envir=globalenv())

# summary of the multi-seed ladder (recomputed, not hand-arithmetic)
d <- read.table("/private/tmp/mc0653_seeds.log", header=TRUE)
for (p in sort(unique(d$pairs))) {
  s <- d[d$pairs==p,]
  cat(sprintf("pairs=%-4d n=%-5d mean sd_hat=%.4f  mean rel.err=%+.2f%%  sd=%.4f  MCSE=%.4f  [%.3f, %.3f]\n",
      p, s$n[1], mean(s$sd_hat), 100*mean(s$rel_err), sd(s$sd_hat),
      sd(s$sd_hat)/sqrt(nrow(s)), min(s$sd_hat), max(s$sd_hat)))
}
cat("\n=== PROFILE at 8x8 = 64 pairs (the design under test) ===\n")
for (sd0 in 2026073001:2026073003) {
  sim <- new_zi_nbinom2_sigma_phylo_interaction_data(seed=sd0, n_plant=8L, n_pollinator=8L, n_each=18L)
  t1 <- sim$plant_tree; t2 <- sim$pollinator_tree
  fit <- drmTMB(bf(count ~ x, sigma ~ phylo_interaction(1 | plant:pollinator, tree1=t1, tree2=t2), zi ~ 1),
                family=nbinom2(), data=sim$data, control=drm_control(se=TRUE))
  parm <- "sd:sigma:phylo_interaction(1 | plant:pollinator)"
  for (ys in c(NA, 0.5)) {
    ci <- tryCatch({
      if (is.na(ys)) confint(fit, parm=parm, method="profile", trace=FALSE)
      else confint(fit, parm=parm, method="profile", trace=FALSE, ystep=ys)
    }, error=function(e) NULL)
    if (is.null(ci)) { cat(sprintf("  seed %d ystep=%-4s ERROR\n", sd0, ifelse(is.na(ys),"dflt","0.5"))); next }
    cat(sprintf("  seed %d ystep=%-4s status=%-14s [%.4f, %.4f] est=%.4f covers0.60=%s msg=%s\n",
        sd0, ifelse(is.na(ys),"dflt","0.5"), ci$conf.status, ci$lower, ci$upper,
        unname(fit$sdpars$sigma[[1]]), (ci$lower<0.60 && 0.60<ci$upper), ci$profile.message))
  }
}
