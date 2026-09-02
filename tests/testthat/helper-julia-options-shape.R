# Design 258 section 7.1 (2026-09-02): every base-bridge payload carries
# options$coef_labels (the per-dpar base-R label list DRM.jl echoes). Tests
# that pin the parity-tested option SHAPE compare the wire without that field
# and assert it separately, so the baseline shape stays pinned exactly.
drm_test_options_sans_labels <- function(o) {
  o <- o[names(o) != "coef_labels"]
  if (length(o) == 0L) list() else o
}
