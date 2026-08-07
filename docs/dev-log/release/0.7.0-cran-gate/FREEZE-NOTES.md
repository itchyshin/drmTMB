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
- **Highest proven rung:** `tarball-clean`
- **Next:** `platform-clean` (owner; win-builder / R-hub / 3-OS). No upload.

Do not commit the `.tar.gz` binary (root `/*.tar.gz` is gitignored).
