# 2026-10-16: `check_drm()` print fits 80 columns (#1534)

Reader: the maintainer reviewing the README's first diagnostic output, and the
next agent touching `print.drm_check()`.

## What changed

`print.drm_check()` handed the full data frame to `print.data.frame`, so the
`message` column (padded to about 380 characters) forced R to split the table
into three blocks at 80 columns. It now prints one block per check, with
`check`, `status` and `value` aligned on one line (the value wraps if needed)
and the full message wrapped underneath. The new internal
`format_drm_check_rows()` does the layout. No column is truncated and the
header lines (`<drm_check: ...>` and the `ok: ...; notes: ...` counts) are
unchanged. The object itself, `[.drm_check`, `attr(, "ok")` and every check
row are untouched; only the print layout changed.

The README has no printed `check_drm()` output block (only the call), so it
needed no edit.

## Forcing test

`tests/testthat/test-check-drm.R`: a beta-binomial fit that carries the #1509
`beta_binomial_sigma_boundary` row is printed at `width = 80` and `width = 60`;
every line must fit, and every check name and message must survive the wrap.
It fails on the base commit (no wrapping) and passes with the fix.

## Not done

Messages are shown for every row, not only for non-ok rows, because the lane
brief asks to keep all information. A `verbose = FALSE` mode that hides ok
messages, as the issue suggests as an alternative, is a possible follow-up.
