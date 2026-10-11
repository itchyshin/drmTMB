# After-task: Julia bridge labelled K/A matrices (#1512)

**Reader:** maintainers comparing `engine = "julia"` with `engine = "tmb"`.

**Root cause.** `drm_julia_structured_matrix()` passed `relmat()` K and
`animal()` A matrices through `drm_julia_as_matrix()`, which drops dimnames.
DRModels.jl pairs row i with the i-th group in first-appearance order, so a
labelled matrix in any other order (for example sorted ids) fitted against the
wrong rows, while the native engine matches by name.

**Fix.** `drm_julia_align_labelled_matrix()` reorders a labelled K/A to the
first-appearance order of the grouping variable before marshalling, and aborts
if any group level is missing from the dimnames. An unlabelled matrix cannot be
checked and still passes through unchanged (not warned, to avoid changing
existing fits).

**Tests.** `tests/testthat/test-julia-structured-dimnames.R` (no Julia needed).
Not verified live against Julia: the BTdata repro in #1512 was not run.

Addresses #1512.
