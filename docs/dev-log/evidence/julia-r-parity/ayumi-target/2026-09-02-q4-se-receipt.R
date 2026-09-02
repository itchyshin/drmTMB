# Slice S4 -- q4 SE-axis parity receipt.
#
# Purpose: on the committed biv-q4-phylo-REML fixture, fit ONCE with
# engine = "tmb" and ONCE with engine = "julia" on the SAME draw (no
# re-simulation), then compare coef() and sqrt(diag(vcov())) between the two
# engines. This is the one measurement standing between the
# `biv_q4_phylo_reml` capability row and a later promotion; it does not
# itself promote anything (see the .md receipt for the explicit scope
# statement).
#
# DRM.jl ref is PINNED by the DRM.jl lane to feat/575-exact-reml-gradient @
# cda42b8c (PR #579 head, the exact-REML-gradient fix for #575). Obtained via
# a throwaway clone; the local DRM.jl checkout at
# "/Users/z3437171/Dropbox/Github Local/DRM.jl" is never touched or fetched.

if (!nzchar(Sys.getenv("DRM_JL_PATH"))) stop("set DRM_JL_PATH to the pinned DRM.jl checkout", call. = FALSE)
Sys.setenv(DRMTMB_JULIA_TESTS = "true")

suppressPackageStartupMessages({
  library(devtools)
  library(ape)
})

worktree <- normalizePath(Sys.getenv("DRMTMB_WORKTREE", getwd()))
load_all(worktree, quiet = TRUE)

fixture <- file.path(Sys.getenv("DRM_JL_PATH"), "test/parity/q4-reml/biv-q4-phylo-reml")  # the pinned DRM.jl checkout
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

t0 <- proc.time()[["elapsed"]]
ft <- drmTMB(form, biv_gaussian(), dat, engine = "tmb", REML = TRUE)
tmb_s <- proc.time()[["elapsed"]] - t0

# Warm the Julia engine before timing (throwaway fit on a small head, not
# timed and not compared).
dat_warm <- head(dat, 60)
dat_warm$species <- factor(dat_warm$species, levels = tree$tip.label)
form_warm <- bf(
  mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
  mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
  sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
  sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
  rho12 = ~1
)
invisible(drmTMB(form_warm, biv_gaussian(), dat_warm, engine = "julia", REML = TRUE))

t0 <- proc.time()[["elapsed"]]
fj <- drmTMB(form, biv_gaussian(), dat, engine = "julia", REML = TRUE)
julia_s <- proc.time()[["elapsed"]] - t0

# Coefficient-name separators differ by engine/method: coef() uses "." (both
# engines), vcov() rownames use ":" (tmb) vs "_" (julia). Neither encodes any
# other information, so canonicalise every name to "<dpar>:<term>" before
# matching -- this is a display-convention normalisation, not a re-derivation
# of identity (the dpar/term split itself is unchanged).
canon_name <- function(x) {
  sub("^(mu1|mu2|sigma1|sigma2|rho12)[.:_]", "\\1:", x)
}

# --- coef() ---
ct <- unlist(coef(ft), use.names = TRUE)
cj <- unlist(coef(fj), use.names = TRUE)
names(ct) <- canon_name(names(ct))
names(cj) <- canon_name(names(cj))

# --- vcov() -> SE ---
Vt <- vcov(ft)
Vj <- vcov(fj)
set_t <- stats::setNames(sqrt(diag(Vt)), canon_name(rownames(Vt)))
set_j <- stats::setNames(sqrt(diag(Vj)), canon_name(rownames(Vj)))

# Match by coefficient name across ALL FOUR of coef(tmb), coef(julia),
# names(SE_tmb), names(SE_julia). Report (not guess) any mismatch.
name_sets <- list(
  coef_tmb = names(ct),
  coef_julia = names(cj),
  se_tmb = names(set_t),
  se_julia = names(set_j)
)
common <- Reduce(intersect, name_sets)
all_names <- Reduce(union, name_sets)
missing_report <- lapply(name_sets, function(nm) setdiff(all_names, nm))

if (length(common) == 0L) {
  stop("S4 receipt: no coefficient name is common to coef()/vcov() of both engines; see missing_report.")
}

se_tmb <- set_t[common]
se_julia <- set_j[common]
coef_tmb <- ct[common]
coef_julia <- cj[common]

se_abs_delta <- abs(se_julia - se_tmb)
se_rel_delta <- se_abs_delta / se_tmb
coef_abs_delta <- abs(coef_julia - coef_tmb)

tab <- data.frame(
  coefficient = common,
  se_tmb = unname(se_tmb),
  se_julia = unname(se_julia),
  se_abs_delta = unname(se_abs_delta),
  se_rel_delta = unname(se_rel_delta),
  coef_tmb = unname(coef_tmb),
  coef_julia = unname(coef_julia),
  coef_abs_delta = unname(coef_abs_delta),
  stringsAsFactors = FALSE
)

conv_tmb <- is_converged(ft)
conv_julia <- is_converged(fj)
ll_tmb <- as.numeric(logLik(ft))
ll_julia <- as.numeric(logLik(fj))

# vcov() diagnostics: conf.status/warnings from sdreport (tmb) and from the
# Julia bridge's own self-reported uncertainty status (julia).
sdr_pdHess <- tryCatch(ft$sdr$pdHess, error = function(e) NA)
sdr_msg <- tryCatch(ft$sdr$msg, error = function(e) NULL)
julia_uncertainty <- tryCatch(fj$uncertainty, error = function(e) NULL)

julia_version <- tryCatch(
  system2("julia", "--version", stdout = TRUE, stderr = TRUE),
  error = function(e) NA_character_
)
drmjl_ref <- tryCatch(
  system2(
    "git",
    c("-C", "/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/7db7461b-e1ee-4ad0-a526-010c1c2e26a6/scratchpad/drmjl-579",
      "rev-parse", "HEAD"),
    stdout = TRUE, stderr = TRUE
  ),
  error = function(e) NA_character_
)
drmtmb_ref <- tryCatch(
  system2("git", c("-C", worktree, "rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) NA_character_
)

out <- list(
  table = tab,
  max_se_rel_delta = max(se_rel_delta),
  logLik_tmb = ll_tmb,
  logLik_julia = ll_julia,
  tmb_converged = conv_tmb,
  julia_converged = conv_julia,
  tmb_s = tmb_s,
  julia_s = julia_s,
  sdr_pdHess = sdr_pdHess,
  sdr_msg = sdr_msg,
  julia_uncertainty = julia_uncertainty,
  missing_report = missing_report,
  julia_version = julia_version,
  drmjl_ref = drmjl_ref,
  drmtmb_ref = drmtmb_ref
)

saveRDS(out, file.path(dirname(worktree), "q4-se-receipt-out.rds"))
print(tab)
cat(sprintf(
  "\nmax_se_rel_delta=%.9g logLik_tmb=%.9g logLik_julia=%.9g tmb_converged=%s julia_converged=%s tmb_s=%.3f julia_s=%.3f\n",
  out$max_se_rel_delta, ll_tmb, ll_julia, conv_tmb, conv_julia, tmb_s, julia_s
))
if (any(lengths(missing_report) > 0)) {
  cat("NAME MISMATCH ACROSS SOURCES:\n")
  print(missing_report)
}
cat("\ntmb sdr$pdHess:", sdr_pdHess, "\n")
if (!is.null(julia_uncertainty)) {
  cat("julia $uncertainty status:", julia_uncertainty$status,
      "-- message:", julia_uncertainty$message, "\n")
}
cat("julia version:\n"); cat(julia_version, sep = "\n")
cat("drmjl_ref:", drmjl_ref, "\n")
cat("drmtmb_ref:", drmtmb_ref, "\n")
