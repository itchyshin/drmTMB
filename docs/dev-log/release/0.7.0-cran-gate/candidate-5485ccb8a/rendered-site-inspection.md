# Rendered-site inspection — exact source `5485ccb8a`

Date: 2026-08-18

The site was built from a clean checkout of source commit
`5485ccb8aeca404412fd346a3a538d0e57808c79` before any evidence files were
added to the branch:

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true \
  Rscript --no-init-file -e 'pkgdown::build_site(new_process = TRUE, install = TRUE)'
```

The first sandboxed attempt stopped before content rendering because DNS and
the user cache were unavailable. The real rerun used an isolated temporary
cache with network access and completed with exit code 0:

```text
Checking for problems
Finished building pkgdown site for package drmTMB
```

The output contained 576 files. The homepage, introductory article, formula
guide, and NEWS page are archived beside this receipt, and the homepage has a
headless-browser screenshot.

## Reader inspection

- The navbar and version note render as `0.7.0` and `0.7.0 pre-CRAN`.
- The homepage says 0.7.0 is the first CRAN-targeted release and has not been
  submitted or accepted.
- The installation section directs readers to the current GitHub source and
  reserves `install.packages("drmTMB")` for after CRAN acceptance.
- The introductory article repeats the same version and installation boundary.
- The formula guide states that logit, probit, and complementary log-log
  binomial links are available.
- NEWS begins with `drmTMB 0.7.0`. Older 0.5.0/0.6.0 strings occur only in
  explicitly historical entries and do not masquerade as the current release.
- The homepage warning labels the software experimental and sends readers to
  the capability-and-limits guide before they treat a fit as an inference claim.

The screenshot shows a coherent desktop layout with readable navigation,
release status, installation instructions, warning text, and first-user links.
No stale 0.6.0 banner or v0.5.0 installation instruction remains.

