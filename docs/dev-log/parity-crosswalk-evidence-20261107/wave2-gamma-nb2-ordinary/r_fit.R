.libPaths(c("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib", .libPaths())); suppressMessages(library(drmTMB))
O <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-gamma/out"
args <- commandArgs(TRUE); tags <- if (length(args)) args else list.files(O)
for (tag in tags) {
  dir <- file.path(O, tag); d <- read.csv(file.path(dir, "data.csv"))
  fam <- sub("_.*", "", tag); shape <- sub("^[^_]*_", "", tag)
  F <- if (fam == "nb2") nbinom2() else Gamma(link = "log")
  if (file.exists(file.path(dir, "K.csv"))) {
    K <- as.matrix(read.csv(file.path(dir, "K.csv"), header = FALSE))
    ids <- read.csv(file.path(dir, "K_ids.csv"))$id; dimnames(K) <- list(ids, ids)
  }
  d$g <- factor(d$g); if (!is.null(d$h)) d$h <- factor(d$h)
  if (!is.null(d$p)) d$p <- factor(d$p, levels = ids)
  if (shape %in% c("relmatq2", "labanimal", "labrelmat")) d$g <- factor(d$g, levels = ids)
  fm <- switch(shape,
    samegroup = bf(y ~ x + (1|g) + (0+x|g), sigma ~ 1, sd(g, coef = "(Intercept)") ~ w1, sd(g, coef = "x") ~ w2),
    crossed = bf(y ~ x + (1|g) + (1|h), sigma ~ 1, sd(g) ~ w1, sd(h) ~ w2),
    ordrelmat = bf(y ~ x + (1|g) + relmat(1|p, K = K), sigma ~ 1, sd(g) ~ w1, sd(p, level = "relmat") ~ w2),
    ordanimal = bf(y ~ x + (1|g) + animal(1|p, A = K), sigma ~ 1, sd(g) ~ w1, sd(p, level = "animal") ~ w2),
    labanimal = bf(y ~ x + animal(1 + x | p | g, A = K), sigma ~ 1, sd(g, level = "animal", coef = "(Intercept)") ~ w1, sd(g, level = "animal", coef = "x") ~ w2),
    labrelmat = bf(y ~ x + relmat(1 + x | p | g, K = K), sigma ~ 1, sd(g, level = "relmat", coef = "(Intercept)") ~ w1, sd(g, level = "relmat", coef = "x") ~ w2),
    corr = bf(y ~ x + (1 + x | g), sigma ~ 1, sd(g, coef = "(Intercept)") ~ w1, sd(g, coef = "x") ~ w2),
    relmatq2 = bf(y ~ x + relmat(1 + x|g, K = K), sigma ~ 1, sd(g, level = "relmat", coef = "(Intercept)") ~ w1, sd(g, level = "relmat", coef = "x") ~ w2))
  t0 <- Sys.time(); fit <- drmTMB(fm, family = F, data = d)
  s <- summary(fit$sdreport, "fixed")
  cat("\n===", tag, "conv", fit$opt$convergence, "time", format(Sys.time() - t0), "ll", sprintf("%.10f", as.numeric(logLik(fit))), "\n")
  print(names(fit$sdpars)); print(s)
  saveRDS(fit, file.path(dir, "r_fit.rds"))
}
