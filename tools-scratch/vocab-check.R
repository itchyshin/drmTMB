# G4: the gradient-source vocabulary is exactly DRM.jl PR #656's six symbols;
# "unknown" is an R-only value that is deliberately NOT one of them; a source
# outside the vocabulary is refused rather than echoed into a diagnostic.
suppressMessages(devtools::load_all(".", quiet = TRUE))
source("tools-scratch/mkfit.R")
vocab <- drmTMB:::drm_julia_grad_source_vocabulary()
stopifnot(identical(
  vocab,
  c("locscale", "stored", "forward", "finite", "none", "unavailable")
))
stopifnot(!"unknown" %in% vocab)
# A gradient that crossed the bridge is DRM.jl's :stored, and nothing else.
stopifnot(identical(drmTMB:::drm_julia_gradient_source(drm_redctl_fit()), "stored"))
# No gradient -> "unknown", never a guessed vocabulary term.
stopifnot(identical(
  drmTMB:::drm_julia_gradient_source(drm_redctl_fit(with_gradient = FALSE)),
  "unknown"
))
# Every vocabulary term a future bridge could send is honoured verbatim, with
# or without Julia's leading colon, and reaches the printed row.
for (src in vocab) {
  produced <- !src %in% c("none", "unavailable")
  for (spelling in c(src, paste0(":", src))) {
    fit <- drm_redctl_fit(with_gradient = produced, gradient_source = spelling)
    stopifnot(identical(drmTMB:::drm_julia_gradient_source(fit), src))
    row <- check_drm(fit)
    row <- row[row$check == "fixed_gradient", ]
    stopifnot(grepl(paste0("source=", src), row$value, fixed = TRUE))
  }
}
# Out of vocabulary: abort, do not echo.
err <- tryCatch(
  {
    check_drm(drm_redctl_fit(gradient_source = "vibes"))
    NULL
  },
  error = function(e) conditionMessage(e)
)
stopifnot(!is.null(err), grepl("unrecognised gradient source", err))
cat("refusal message: ", gsub("\n", " | ", err), "\n", sep = "")
# A source that contradicts the payload is refused too: DRM.jl spells "no
# gradient was produced" as :none / :unavailable, and the bridge omits the
# "gradient" key in exactly that case.
for (bad in list(
  list(with_gradient = TRUE, src = "none"),
  list(with_gradient = TRUE, src = "unavailable"),
  list(with_gradient = FALSE, src = "stored")
)) {
  msg <- tryCatch(
    {
      check_drm(drm_redctl_fit(
        with_gradient = bad$with_gradient, gradient_source = bad$src
      ))
      NULL
    },
    error = function(e) conditionMessage(e)
  )
  stopifnot(!is.null(msg), grepl("contradict", msg))
  cat("contradiction refused (", bad$src, ", gradient present=",
      bad$with_gradient, ")\n", sep = "")
}
cat("VOCAB_OK\n")
