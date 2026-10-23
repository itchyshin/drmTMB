# Independent design oracle for DRM.jl #467: compare R's model.matrix VALUES
# against the design matrix DRM.jl actually builds from the marshalled payload.
WT <- "/Users/z3437171/local-scratch/parity-joint/wt-jl-467-factors"
suppressMessages(pkgload::load_all(WT, quiet = TRUE, recompile = FALSE))
OUT <- "/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/7db7461b-e1ee-4ad0-a526-010c1c2e26a6/scratchpad/j467/design-oracle-001.tsv"

set.seed(46709L); n <- 120L
x <- runif(n, -1, 1); z <- runif(n, -1, 1)
gi <- rep(c(2L, 9L, 10L), length.out = n)
g3 <- factor(rep(c("a","b","c"), length.out = n))
g2 <- factor(rep(c("p","q"), length.out = n))
gchar <- rep(c("a","b","c"), length.out = n)
flag <- rep(c(TRUE, FALSE), length.out = n)
gmix <- factor(rep(c("a","B","c"), length.out = n))
g3rev <- factor(as.character(g3), levels = c("c","b","a"))
gcase <- factor(rep(c("A","a","b"), length.out = n))
gifac <- factor(gi)
y <- 0.3 + 0.6*x - 0.4*z + rnorm(n, sd = exp(-0.6 + 0.2*x))
dat <- data.frame(y, x, z, gi, g3, g2, gchar, flag, gmix, g3rev, gcase, gifac,
                  stringsAsFactors = FALSE)

cases <- c(
  "x", "g3", "factor(gi)", "gchar", "flag", "gmix", "g3rev", "gcase", "gifac",
  "x * g3", "x + g3 + x:g3", "g3 * g2", "x + I(x^2)", "x + z + I(x*z)",
  "I(x^2 + z)", "log(I(x + 2))", "poly(x, 2)", "poly(x, 3)",
  "poly(x, 2) * g2", "scale(x)", "scale(x) + scale(z)", "(x + z)^2",
  "(x + z + g2)^2", "(x + z + g2)^3", "x - 1", "0 + x", "x:z",
  "x + z + x:z - z", "(x + z)^2 - x:z", "log(x + 2) * g2", "x + g3 - x",
  "poly(x, 2) + z - z", "I(x^2):g2", "x + factor(gi) + x:factor(gi)",
  "sqrt(x + 2)", "I(x)", "I((x))"
)

drmTMB:::drm_julia_setup()
JuliaCall::julia_command('
function drmTMB_probe_design(formula, family, data)
    dat = DRM._bridge_data(data)
    bundle, dat2, _ = DRM._bridge_formula(formula, family, dat; labels = true)
    out = Dict{String,Any}()
    for (param, rhs) in bundle.forms
        _, X, raw = DRM._design(bundle.response, rhs, dat2)
        out[String(param)] = Dict{String,Any}("X" => X, "raw" => raw)
    end
    return out
end')

rows <- list()
for (rhs in cases) {
  f <- eval(str2lang(sprintf("bf(y ~ %s, sigma ~ 1)", rhs)), envir = globalenv())
  res <- tryCatch({
    pay <- drmTMB:::drm_julia_bridge_payload(formula = f, family_type = "gaussian",
             data = dat, env = globalenv())
    jl <- JuliaCall::julia_call("drmTMB_probe_design", pay$formula, "gaussian", pay$data)
    Xj <- jl$mu$X
    Xr <- stats::model.matrix(stats::as.formula(paste("~", rhs)), dat)
    same_dim <- identical(dim(Xj), dim(Xr))
    d <- if (same_dim) max(abs(Xj - Xr)) else NA_real_
    list(status = if (isTRUE(same_dim) && is.finite(d) && d < 1e-12) "DESIGN_IDENTICAL"
                  else if (same_dim) "VALUES_DIFFER" else "DIM_DIFFER",
         ncol_r = ncol(Xr), ncol_jl = ncol(Xj), maxdiff = d,
         r_names = paste(colnames(Xr), collapse = "|"),
         jl_raw = paste(as.character(unlist(jl$mu$raw)), collapse = "|"), msg = "")
  }, error = function(e) list(status = "REFUSED", ncol_r = NA_integer_, ncol_jl = NA_integer_,
       maxdiff = NA_real_, r_names = "", jl_raw = "",
       msg = substr(gsub("[\r\n\t]+", " ", conditionMessage(e)), 1, 200)))
  rows[[length(rows)+1L]] <- data.frame(rhs = rhs, status = res$status,
    ncol_r = res$ncol_r, ncol_jl = res$ncol_jl, max_abs_design_diff = res$maxdiff,
    r_model_matrix = res$r_names, julia_raw = res$jl_raw, msg = res$msg,
    stringsAsFactors = FALSE)
  cat(sprintf("%-32s %-18s r=%s jl=%s d=%s %s\n", rhs, res$status, res$ncol_r,
      res$ncol_jl, format(res$maxdiff), res$msg))
}
tsv <- do.call(rbind, rows)
utils::write.table(tsv, OUT, sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nSUMMARY:\n"); print(table(tsv$status))
