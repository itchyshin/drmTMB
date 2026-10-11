# 2026-10-11: configure.win rewritten as a shell script

Reader: the maintainer reviewing why Windows builds broke.

**Problem.** `configure.win` (added with the D4 build-provenance work) was a
cmd batch file. R CMD INSTALL runs `configure.win` with the Rtools `sh`, so
on Windows it stopped with `./configure.win: line 1: @echo: command not
found` and `ERROR: configuration failed for package 'drmTMB'`. Every Windows
source install failed, including the `windows-latest (release)` job of
full-matrix R-CMD-check runs (observed on run 38112172161, PR #1510).
PR-triggered runs use an Ubuntu-only matrix, so this went unnoticed.

**Fix.** `configure.win` is now a short POSIX script that runs `sh
./configure || true; exit 0`, so the one shell implementation of provenance
capture serves both platforms and install stays non-fatal. The duplication
note in `tools/drmtmb_provenance.R` now says this.

**Checks (Linux `sh`).** In a git checkout, `sh ./configure.win` exits 0 and
writes the SHA and dirty flag. In a copy without `.git`, it exits 0 with
`GitReason: no .git directory found ...`. With no `git` on PATH, it exits 0
with `GitReason: git executable not found on PATH`. Windows itself is
verified by a dispatched full-matrix R-CMD-check run on this branch.
