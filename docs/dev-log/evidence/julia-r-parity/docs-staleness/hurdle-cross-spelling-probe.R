# Probe: is the parity matrix's `Hurdle NB2` boundary still true after A4 admitted
# truncated_nbinom2() (registry row, R/julia-family-registry.R:63)?
#
# The committed row says: "the bridge refuses truncated_nbinom2() and reaches
# DRM.jl only as nbinom2() + `hu ~`", with "NEXT: admit truncated_nbinom2 through
# the bridge so the native spelling works on both engines".
# Both halves are measured here. Pure R: every refusal below is pre-Julia.
suppressMessages(devtools::load_all(
  "/Users/z3437171/local-scratch/parity-joint/wt-docs-staleness",
  quiet = TRUE
))

set.seed(1)
n <- 40
dat <- data.frame(x = stats::rnorm(n), y = stats::rpois(n, 3) + 1L)

flat <- function(x) gsub("[[:space:]]+", " ", x)
probe <- function(label, expr) {
  out <- tryCatch(
    list(ok = TRUE, value = flat(paste(format(force(expr)), collapse = " "))),
    error = function(e) list(ok = FALSE, value = flat(conditionMessage(e)))
  )
  cat("---- ", label, "\n",
      if (out$ok) "OK -> " else "ERROR -> ", substr(out$value, 1, 300), "\n\n", sep = "")
  invisible(out)
}

cat("registry admits truncated_nbinom2 on the fixed-effect route: ",
    "truncated_nbinom2" %in% drmTMB:::drm_julia_registry_families("fe"), "\n\n", sep = "")

plain <- probe(
  'truncated_nbinom2() + bf(y ~ x, sigma ~ 1)   [the plain FE route A4 admitted]',
  drmTMB:::drm_julia_family_tag("truncated_nbinom2", has_phylo = FALSE)
)

hu_trunc <- probe(
  'truncated_nbinom2() + bf(y ~ x, sigma ~ 1, hu ~ 1)   [the NATIVE hurdle spelling]',
  drmTMB(bf(y ~ x, sigma ~ 1, hu ~ 1), family = truncated_nbinom2(),
         data = dat, engine = "julia")
)

cat("==== VERDICT ====\n")
cat("family tag for truncated_nbinom2 resolves (admitted)  : ", plain$ok,
    "  -> ", plain$value, "\n", sep = "")
cat("the NATIVE hurdle spelling errors                     : ", !hu_trunc$ok, "\n", sep = "")
cat("...and the error is a CAPABILITY refusal, not a setup",
    "\n   (no DRM.jl-checkout text in it)                    : ",
    !hu_trunc$ok && !grepl("needs a local DRM.jl checkout", hu_trunc$value, fixed = TRUE),
    "\n", sep = "")
cat("verbatim: ", hu_trunc$value, "\n", sep = "")
