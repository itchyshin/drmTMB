# Prepared candidate only. Run in a fresh supported R session after a time estimate.
# Public ML point fits; no intervals and no broad parity claim.
options(warn = 1)
root <- normalizePath(Sys.getenv("ARTICLE_R_ROOT", getwd()), mustWork = TRUE)
out <- Sys.getenv("ARTICLE_OUT", "/Users/z3437171/Documents/Codex/2026-11-04-sd-article-plan/execution/article-gamma")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
stopifnot(requireNamespace("digest", quietly = TRUE))
helper <- file.path(root, "tests/testthat/helper-b34-julia-oracles.R")
expected_helper_sha <- "39d763f004d17cd9d4a020625a730a629c0d3e165fb114597aa987964050d199"
stopifnot(identical(digest::digest(file = helper, algo = "sha256"), expected_helper_sha))
oracle_env <- new.env(parent = baseenv())
sys.source(helper, envir = oracle_env)
pkgload::load_all(root, compile = FALSE, quiet = TRUE)

# Lock the comparison tolerance before fitting. Failure does not trigger clipping,
# a seed change, a different target, or a tolerance change.
ORACLE_ABS_TOL <- 1e-5
set.seed(20261104)
G <- 40L
ids <- paste0("g", seq_len(G))
z <- setNames(seq(-1, 1, length.out = G), ids)
k_scale <- setNames(seq(0.7, 1.6, length.out = G), ids)
R <- outer(seq_len(G), seq_len(G), function(i, j) 0.35^abs(i - j))
K <- outer(k_scale, k_scale) * R
dimnames(K) <- list(ids, ids)
s <- exp(log(0.55) + 0.4 * z)
b <- setNames(s * as.vector(t(chol(K)) %*% rnorm(G)), ids)
index <- sample(rep(seq_len(G), each = 12L))
dat <- data.frame(id = factor(ids[index], levels = ids),
                  z = unname(z[index]), x = rnorm(length(index)))
mu <- exp(0.4 + 0.3 * dat$x + b[as.character(dat$id)])
dat$y <- rgamma(nrow(dat), shape = 4, rate = 4 / mu)
form <- bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1,
           sd(id, level = "relmat") ~ z)

# Independent oracle uses the named matrix order, not first-seen row order.
idx <- match(as.character(dat$id), rownames(K))
z_kernel <- unname(z[rownames(K)])
X <- stats::model.matrix(~x, dat)
stopifnot(!anyNA(idx), !anyNA(z_kernel),
          identical(rownames(K), colnames(K)), max(diag(K)) - min(diag(K)) > 0.5)
fits <- list()
results <- list()
figures <- list()
warnings_by_engine <- list()
provenance <- list(seed = 20261104L, estimator = "ML", REML = FALSE,
                   oracle = "independent dense Laplace, hand Gamma density/derivatives and Newton mode",
                   helper_path = helper, helper_sha256 = expected_helper_sha,
                   oracle_absolute_tolerance = ORACLE_ABS_TOL,
                   julia_root = Sys.getenv("DRM_JL_PATH"),
                   session = utils::sessionInfo())
save_state <- function() {
  saveRDS(list(fits = fits, data = dat, K = K, truth = list(s = s, b = b, z = z,
                  alpha = c(`(Intercept)` = log(0.55), z = 0.4), sigma = 0.5),
               results = results, plot_data = figures, warnings = warnings_by_engine,
               provenance = provenance), file.path(out, "article-gamma.rds"))
  if (length(results)) utils::write.table(do.call(rbind, results),
      file.path(out, "results.tsv"), sep = "\t", row.names = FALSE, quote = TRUE, na = "NA")
}
save_state()
for (engine in c("tmb", "julia")) {
  started <- Sys.time()
  warns <- character()
  cat("START", engine, format(started), "\n"); flush.console()
  row <- tryCatch(withCallingHandlers({
    fit <- drmTMB(form, family = stats::Gamma(link = "log"), data = dat,
                  engine = engine, REML = FALSE, control = drm_control(se = FALSE))
    fits[[engine]] <- fit
    beta <- coef(fit, dpar = "mu")
    alpha <- coef(fit, dpar = "sd_relmat(id)")
    sigma_coef <- coef(fit, dpar = "sigma")
    stopifnot(setequal(names(beta), colnames(X)),
              setequal(names(alpha), c("(Intercept)", "z")), length(sigma_coef) == 1L)
    beta <- unname(beta[colnames(X)])
    alpha <- unname(alpha[c("(Intercept)", "z")])
    disp <- exp(unname(sigma_coef))
    sdv <- exp(alpha[1] + alpha[2] * z_kernel)
    own_oracle <- oracle_env$b34_laplace(dat$y, "gamma", X, beta, disp, idx, sdv, K)
    ll <- as.numeric(stats::logLik(fit))
    gap <- ll - own_oracle
    predicted <- predict(fit, dpar = "sd_relmat(id)")
    stopifnot(!is.null(names(predicted)), setequal(names(predicted), rownames(K)))
    figures[[engine]] <- data.frame(engine = engine, id = names(predicted),
       z = unname(z[names(predicted)]), multiplier = unname(predicted),
       marginal_sd = unname(predicted * sqrt(diag(K)[names(predicted)])),
       true_multiplier = unname(s[names(predicted)]),
       true_marginal_sd = unname(s[names(predicted)] * sqrt(diag(K)[names(predicted)])))
    conv <- fit$opt$convergence
    data.frame(engine = engine, status = if (is.finite(gap) && abs(gap) <= ORACLE_ABS_TOL &&
               identical(as.integer(conv), 0L)) "pass" else "failed_check",
       convergence = paste(conv, collapse = ","), logLik = ll, own_laplace = own_oracle,
       oracle_gap = gap, alpha_intercept = alpha[1], alpha_z = alpha[2], sigma = disp,
       true_one_unit_ratio = exp(0.4), estimated_one_unit_ratio = exp(alpha[2]),
       elapsed_seconds = as.numeric(difftime(Sys.time(), started, units = "secs")),
       error = "", stringsAsFactors = FALSE)
  }, warning = function(w) {
    warns <<- c(warns, conditionMessage(w))
    # Preserve the warning in the console and saved record; do not suppress it.
  }), error = function(err) data.frame(engine = engine, status = "error", convergence = NA_character_,
       logLik = NA_real_, own_laplace = NA_real_, oracle_gap = NA_real_,
       alpha_intercept = NA_real_, alpha_z = NA_real_, sigma = NA_real_,
       true_one_unit_ratio = exp(0.4), estimated_one_unit_ratio = NA_real_,
       elapsed_seconds = as.numeric(difftime(Sys.time(), started, units = "secs")),
       error = conditionMessage(err), stringsAsFactors = FALSE))
  results[[engine]] <- row
  warnings_by_engine[[engine]] <- warns
  save_state()
  print(row); flush.console()
}
if (any(vapply(results, function(x) x$status != "pass", logical(1)))) {
  stop("ARTICLE_GAMMA_NOT_ADMITTED: retained candidate failures; inspect results.tsv and article-gamma.rds")
}
cat("ARTICLE_GAMMA_OWN_LAPLACE_PASS\n")
