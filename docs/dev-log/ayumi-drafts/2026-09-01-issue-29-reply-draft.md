# DRAFT — reply to LS_ecogeographical-rules #29 (engine="julia" blocked in non-interactive R)

> STATUS: DRAFT ONLY. Not posted. Posting requires Shinichi's explicit approval and a fresh
> forbidden-claim scan (docs/design/205-ayumi-reply-readiness-gate.md) immediately before.
> Verify the fix has merged to drmTMB main before posting.

---

@Ayumi-495 — you diagnosed this exactly right: the CRAN/check safety gate was classifying every
non-interactive R session as the check lane, so a documented, legitimate `Rscript` workflow hit a
gate meant for `R CMD check`.

This is fixed on the current branch: the gate now looks for real R-CMD-check markers rather than
mere non-interactivity, so an ordinary `Rscript` session with only the documented setup
(`DRM_JL_PATH`, `JULIA_NUM_THREADS`) proceeds without `DRMTMB_JULIA_TESTS` or `NOT_CRAN`. Your
minimal reproducer pattern — an unopted non-interactive script — now runs; our own validation runs
today were unopted `Rscript` sessions end to end.

Until the fix reaches a release you install, your `DRMTMB_JULIA_TESTS=true` workaround remains
correct and safe. The Julia setup docs are also being updated so that interactive and
non-interactive behaviour is stated explicitly rather than discovered.

Thank you for the precise reproducer — it made this a one-look diagnosis. Non-interactive execution
is, as you say, the normal home of the large fits, tree loops, and interval work, which is exactly
why the gate had to learn the difference between a batch job and a check lane.

---

## Evidence links to attach before posting (verify merge state first)
- The gate-condition change (branch codex/rebase-julia-optimizer-controls lineage; confirm the
  landed commit/PR before citing)
- Retained unopted `Rscript` receipts: synthetic q4 run + today's matched-control fixture runs
