# 0.7.0 cran-gate probe notes (2026-08-07)

## Candidate identity (post-`.Rbuildignore` rebuild)

See `tarball.sha256`, `tarball.size.txt`, `tarball-inventory.txt`, and
`local-as-cran-check.log` in this directory. The binary `.tar.gz` is kept at the
worktree root (gitignored `/*.tar.gz`) and is **not** committed.

Source commit for claim-freeze / source-clean ledger: `c2b9d6cd6`.
`.Rbuildignore` adds `^LOOP$` so the goal-loop kit is not shipped to CRAN.
That ignore line was uncommitted when probe 2 was built, so
`clean_worktree` stays **false** and the rung stays **`source-clean`**
(not `tarball-clean`).

## Probe 1 (pre-fix)

- SHA `783ce3a1107865645f3934b733f7e2b94fb7f670631129bc86111b3aaa941fbd`
- Size 9820634 bytes; inventory 922 entries
- `R CMD check --as-cran --no-manual`: **Status: 2 NOTEs**
  - New submission
  - Non-standard top-level `LOOP/`
- 0 ERROR / 0 WARNING; installed size INFO 31.1 Mb

## Probe 2 (after `^LOOP$` in `.Rbuildignore`) — DONE

- SHA `5db0111a683fd91d42ba11d66eb4ed83b2b4ba61dd7d58f5e2fb493b4f9662d3`
- Size **9817128** bytes; inventory **917** entries
- `LOOP/` absent from tarball inventory (confirmed)
- `R CMD check --as-cran --no-manual`: **Status: 1 NOTE**
  - New submission only
  - top-level files: OK (no LOOP NOTE)
- 0 ERROR / 0 WARNING; installed size INFO 31.1 Mb
- Driver finished `=== REBUILD_END 2026-08-07T12:10:17Z ===` / `REBUILD_DONE`
- Logs: `probe-driver.log`, `local-as-cran-check.log`, `00check.log`

## Rung claim

**Highest proven rung: `source-clean`.**
Do **not** claim `tarball-clean` until a clean-worktree commit includes the
`.Rbuildignore` fix, the tarball is rebuilt from that commit, and the matching
`--as-cran` log is bound in the ledger JSON. Upload remains owner-gated.
