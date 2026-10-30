# check-log.d — per-file check evidence

As of 2026-10-30 the live check log is **per-file** so parallel slices
do not edit one shared table (Decision, Shinichi, 25 Oct, #1113). The
pattern matches HSquared.jl and DRM.jl.

Each slice adds a new file `YYYY-MM-DD-<slice>.md` here instead of
editing `docs/dev-log/check-log.md`.

- One file per slice; never edit another slice's file.
- `../check-log.md` is the frozen historical log. Do not append new
  slices to it.
- Each entry records: goal, commands run, results (tests/docs/CI), and
  the claim boundary.

This is process only. It does not change CRAN candidate bytes, bridge
behaviour, or validation-debt rows.
