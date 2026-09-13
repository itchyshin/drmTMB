# Dinnage audit — waves 1 and 2 on claude/audit-dinnage-wave1-20260913

Merged tree (wave 1 plus the wave-2a and wave-2b branches).  Per-file results
under `pkgload::load_all()`, reporter `check`:

RESULTS_PLACEHOLDER

Local `R CMD check --no-manual --as-cran` on a `git archive` export of the
merged HEAD (so the untracked `.unlazy/` ledgers are absent):

ASCRAN_PLACEHOLDER

Ledgers re-verified by `gate-check.mjs --reverify` rather than read:
leaf-A3 (wave 1), leaf-A4a (wave 2a: 2 met, 1 abandoned for M3 with the
#1130 citation), leaf-A4b (wave 2b: 4 met after the M4 follow-up).  No
campaign, no remote compute, no evidence bytes on the 071 lane.
