WT <- "/Users/z3437171/local-scratch/parity-joint/wt-jl-467-factors"
suppressMessages(pkgload::load_all(WT, quiet = TRUE, recompile = FALSE))
drmTMB:::drm_julia_setup()
JuliaCall::julia_command('_probe_levels(v) = string(sort(unique(v)))')
JuliaCall::julia_command('_probe_type(v) = string(typeof(v))')
n <- 12L
cols <- list(
  fac_alpha   = factor(rep(c("a","b","c"), length.out = n)),
  fac_rev     = factor(rep(c("a","b","c"), length.out = n), levels = c("c","b","a")),
  fac_empty   = factor(rep(c("a","b","c"), length.out = n), levels = c("a","b","c","zz")),
  fac_numlab  = factor(rep(c(2L, 9L, 10L), length.out = n)),
  chr_mixed   = rep(c("a","B","c"), length.out = n),
  chr_lower   = rep(c("a","b","c"), length.out = n),
  chr_case    = rep(c("A","a","b"), length.out = n),
  lgl         = rep(c(TRUE, FALSE), length.out = n)
)
cat(sprintf("%-11s %-34s %-26s %s\n", "column", "julia_type", "julia_sort_unique", "R_levels"))
for (nm in names(cols)) {
  v <- cols[[nm]]
  JuliaCall::julia_assign("vv", v)
  ty <- JuliaCall::julia_eval("_probe_type(vv)")
  lv <- JuliaCall::julia_eval("_probe_levels(vv)")
  rl <- if (is.factor(v)) paste(levels(v), collapse=",") else paste(levels(factor(v)), collapse=",")
  cat(sprintf("%-11s %-34s %-26s %s\n", nm, substr(ty,1,34), lv, rl))
}
cat("\nR radix sort of chr_mixed:", paste(sort(unique(cols$chr_mixed), method="radix"), collapse=","), "\n")
cat("R radix sort of chr_case :", paste(sort(unique(cols$chr_case), method="radix"), collapse=","), "\n")
cat("R locale levels chr_case :", paste(levels(factor(cols$chr_case)), collapse=","), "\n")
