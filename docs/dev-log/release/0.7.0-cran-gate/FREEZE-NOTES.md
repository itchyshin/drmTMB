# drmTMB 0.7 CRAN gate — tarball-clean freeze

- **Freeze source commit:** `459bd3fa9e3267985568ac960b819a00d129f950` (merge of PR #938 onto `main`)
- **Worktree:** `/Users/z3437171/local-scratch/worktrees/drmTMB-07-tarball` on `cursor/07-tarball-clean`
- **Clean worktree at build:** yes (`git status --porcelain` empty)
- **`.Rbuildignore`:** contains `^LOOP$` (verified on tip)
- **Tarball:** `drmTMB_0.6.0.tar.gz` (DESCRIPTION remains 0.6.0; target CRAN version 0.7.0)
- **SHA-256:** `c787ee40b8895d15609e77dd8024c3520efb333c657ba5bc98bc0388aa156cbb`
- **Size:** 9817096 bytes
- **Inventory:** `tarball-inventory.txt` (917 paths; no `LOOP` entries)
- **Local CRAN lane:** `R CMD check --as-cran --no-manual` → **Status: 1 NOTE** (New submission only); 0 ERROR / 0 WARNING
- **Logs:** `local-as-cran-check.log`, `00check.log`
- **Highest proven rung:** `tarball-clean` (unchanged after 2026-08-07 platform attempt)
- **Platform attempt (2026-08-07):** see `platform/PLATFORM-NOT-READY.md`. GHA 3-OS green
  (`workflow_dispatch` run 31195187084); win-builder R-release + R-devel **1 ERROR**
  (CondExp source-path guard); R-hub sanitizers OK / rchk noise / valgrind incomplete.
  Do **not** claim `platform-clean` until win-builder is clean.
- **Path repair (2026-08-07):** CondExp `drm_src_path` fixed on
  `cursor/07-platform-clean` (PR #941) for win-builder sibling / correct
  `../00_pkg_src` layouts. **Does not yet reclaim `platform-clean`** — re-run
  win-builder on a tarball that includes the repair; finish valgrind; then
  re-evaluate. No upload.

Do not commit the `.tar.gz` binary (root `/*.tar.gz` is gitignored).
