# After-Task Report: Slices 459-468 Reference Example Copy-Run

## Active Perspectives

Ada ran the copy-run audit. Pat checked whether a user could paste the
reference examples without hidden setup. Grace used the generated Rd files as
the source of truth for examples. Rose watched for examples that silently rely
on stale syntax.

## Goal

Copy-run the high-risk reference examples for structural markers, latent
correlation extraction, profile targets, confidence intervals, and diagnostics.

## Evidence

The extracted examples from these Rd pages ran successfully in a
`devtools::load_all()` session:

- `man/phylo.Rd`
- `man/corpair.Rd`
- `man/corpairs.Rd`
- `man/profile_targets.Rd`
- `man/confint.drmTMB.Rd`
- `man/check_drm.Rd`

The `corpairs()` example fitted a small bivariate Gaussian residual-correlation
model and returned a residual `rho12` row. The `profile_targets()` and
`confint()` examples fitted the small Gaussian location-scale example and
returned the expected target and Wald interval tables. The `check_drm()`
example returned 10 ok checks and no notes, warnings, or errors.

## Checks Run

```sh
Rscript - <<'EOF'
devtools::load_all(quiet = TRUE)
files <- c(
  'man/phylo.Rd',
  'man/corpair.Rd',
  'man/corpairs.Rd',
  'man/profile_targets.Rd',
  'man/confint.drmTMB.Rd',
  'man/check_drm.Rd'
)
for (rd in files) {
  cat('\n## Rd example:', rd, '\n')
  ex <- tempfile(fileext = '.R')
  tools::Rd2ex(rd, out = ex)
  code <- readLines(ex, warn = FALSE)
  code <- code[!grepl('^###', code)]
  src <- tempfile(fileext = '.R')
  writeLines(code, src)
  source(src, echo = TRUE, max.deparse.length = Inf)
}
EOF
```

## Known Limitations

This did not run every package example or `devtools::check()`. It targeted the
reference pages most likely to drift after the q4 fallback, profile-target, and
pkgdown audit work.

## Next Actions

Continue with a broader stale-promise audit across design docs and after-task
reports, then decide whether to run a full `devtools::test()` or keep
validation focused until the current large worktree is staged.
