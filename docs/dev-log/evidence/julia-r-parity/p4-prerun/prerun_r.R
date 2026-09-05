# A10 pre-run: NATIVE drmTMB (engine = "tmb") on the committed biv-q4-phylo-reml fixture.
# 1 warm-up (discarded) + 3 timed reps in ONE R session (warm workflow), single core.
.libPaths(c("~/parity_joint/Rlib", .libPaths()))
suppressPackageStartupMessages({library(drmTMB); library(ape)})
out_dir <- Sys.getenv("PRERUN_OUT"); dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
fixture <- "~/parity_joint/DRM.jl/test/parity/q4-reml/biv-q4-phylo-reml"
dat <- read.csv(file.path(fixture, "data.csv"), stringsAsFactors = FALSE)
tree <- read.tree(file.path(fixture, "tree.newick"))
dat$species <- factor(dat$species, levels = tree$tip.label)
form <- bf(
  mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
  mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
  sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
  sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
  rho12 = ~1
)
desc <- packageDescription("drmTMB", lib.loc = "~/parity_joint/Rlib")
one <- function(rep) {
  gc()
  p0 <- proc.time()
  fit <- drmTMB(form, biv_gaussian(), dat, engine = "tmb", REML = TRUE,
                control = drm_control(optimizer_preset = "robust"))
  p1 <- proc.time() - p0
  list(engine = "drmTMB-native-tmb", rep = rep,
       wall_s = unname(p1[["elapsed"]]), cpu_s = unname(p1[["user.self"]] + p1[["sys.self"]]),
       converged = is_converged(fit), loglik = as.numeric(logLik(fit)),
       coef = as.list(coef(fit)))
}
warm <- one(0L)  # warm-up: DLL load + first tape; DISCARDED from the timing summary
res <- lapply(1:3, one)
for (r in c(list(warm), res)) {
  writeLines(jsonlite::toJSON(r, auto_unbox = TRUE, digits = NA, pretty = TRUE),
             file.path(out_dir, sprintf("r-rep%d.json", r$rep)))
}
env <- list(R_version = R.version.string, drmTMB_version = desc$Version,
            drmTMB_RemoteSha = desc$RemoteSha, drmTMB_RemoteRef = desc$RemoteRef,
            drmTMB_Built = desc$Built, TMB_version = as.character(packageVersion("TMB")),
            OPENBLAS_NUM_THREADS = Sys.getenv("OPENBLAS_NUM_THREADS"),
            host = Sys.info()[["nodename"]], platform = R.version$platform)
writeLines(jsonlite::toJSON(env, auto_unbox = TRUE, pretty = TRUE), file.path(out_dir, "r-env.json"))
cat(sprintf("R: warmup wall=%.3f | timed wall=%s | cpu=%s | loglik=%s | conv=%s\n",
            warm$wall_s, paste(sprintf("%.3f", sapply(res, `[[`, "wall_s")), collapse = ","),
            paste(sprintf("%.3f", sapply(res, `[[`, "cpu_s")), collapse = ","),
            paste(sprintf("%.10f", sapply(res, `[[`, "loglik")), collapse = ","),
            paste(sapply(res, `[[`, "converged"), collapse = ",")))
