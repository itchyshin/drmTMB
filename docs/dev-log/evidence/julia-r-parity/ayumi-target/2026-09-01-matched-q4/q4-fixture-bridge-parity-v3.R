Sys.setenv(DRM_JL_PATH = "/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-DRM-jl/afd6975e-02e8-4ecd-ae5c-478837cfc231/scratchpad/wt-exact-grad")

suppressPackageStartupMessages({library(devtools); library(ape)})
load_all('/private/tmp/drmtmb-control-audit', quiet = TRUE)
fixture <- '/private/tmp/DRMjl-bridge-route-diagnostic/test/parity/q4-reml/biv-q4-phylo-reml'
dat <- read.csv(file.path(fixture, 'data.csv'), stringsAsFactors = FALSE)
tree <- read.tree(file.path(fixture, 'tree.newick'))
dat$species <- factor(dat$species, levels = tree$tip.label)
form <- bf(mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
           mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
           sigma1 = sigma1 ~ 1 + phylo(1 | p | species, tree = tree),
           sigma2 = sigma2 ~ 1 + phylo(1 | p | species, tree = tree),
           rho12 = rho12 ~ 1)
t0 <- proc.time()[['elapsed']]
ft <- drmTMB(form, biv_gaussian(), dat, engine = 'tmb', REML = TRUE)
tmb_s <- proc.time()[['elapsed']] - t0

# Warm the Julia engine before timing (throwaway fit, not timed).
dat_warm <- head(dat, 60)
dat_warm$species <- factor(dat_warm$species, levels = tree$tip.label)
form_warm <- bf(mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
                 mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
                 sigma1 = sigma1 ~ 1 + phylo(1 | p | species, tree = tree),
                 sigma2 = sigma2 ~ 1 + phylo(1 | p | species, tree = tree),
                 rho12 = rho12 ~ 1)
invisible(drmTMB(form_warm, biv_gaussian(), dat_warm, engine = 'julia', REML = TRUE))

t0 <- proc.time()[['elapsed']]
fj <- drmTMB(form, biv_gaussian(), dat, engine = 'julia', REML = TRUE)
julia_s <- proc.time()[['elapsed']] - t0

ct <- unlist(coef(ft), use.names = TRUE); cj <- unlist(coef(fj), use.names = TRUE)
common <- intersect(names(ct), names(cj))
tmb_conv_msg <- tryCatch(ft$optimizer_message, error = function(e) NA_character_)
if (is.null(tmb_conv_msg) || length(tmb_conv_msg) == 0) tmb_conv_msg <- NA_character_

result_line <- sprintf(
  'Q4_FIXTURE_BRIDGE_PARITY_V3 conv_tmb=%s conv_julia=%s ll_delta=%.9g max_coef_delta=%.9g tmb_s=%.3f julia_s=%.3f n_common=%d tmb_conv_msg=%s',
  is_converged(ft), is_converged(fj), abs(as.numeric(logLik(ft))-as.numeric(logLik(fj))), max(abs(ct[common]-cj[common])), tmb_s, julia_s, length(common), tmb_conv_msg)
cat(result_line, '\n')
writeLines(result_line, '/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-DRM-jl/afd6975e-02e8-4ecd-ae5c-478837cfc231/scratchpad/q4-fixture-v3-result.txt')
