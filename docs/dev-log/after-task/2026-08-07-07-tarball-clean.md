# After-task: drmTMB 0.7 tarball-clean

**Reader:** next CRAN-lane agent / Shinichi.
**Purpose:** record the clean-tip freeze that advances the release ledger from `source-clean` to `tarball-clean`.

## What landed

1. Merged PR [#938](https://github.com/itchyshin/drmTMB/pull/938) (squash) after CI green → `main` @ `459bd3fa9e3267985568ac960b819a00d129f950`.
2. Fresh clean worktree `~/local-scratch/worktrees/drmTMB-07-tarball` on `cursor/07-tarball-clean` from that tip (`git status --porcelain` empty; `.Rbuildignore` contains `^LOOP$`).
3. `R CMD build .` → `drmTMB_0.6.0.tar.gz`
   - SHA-256 `c787ee40b8895d15609e77dd8024c3520efb333c657ba5bc98bc0388aa156cbb`
   - size 9817096 bytes
   - inventory under `docs/dev-log/release/0.7.0-cran-gate/` (no `LOOP` paths)
4. `R CMD check --as-cran --no-manual` → **Status: 1 NOTE** (New submission only); 0 ERROR / 0 WARNING.
5. Ledger `docs/dev-log/release-audits/2026-08-07-07-cran-release-ledger.json` set to `status_claim: tarball-clean` with absolute artifact paths and evidence for `local_as_cran` / `incoming_feasibility` / `installed_package` / `timing`.
6. `python3 ~/shinichi-brain/tools/cran_release_gate.py <ledger.json>` → **READY FOR CLAIMED RUNG**.

## Fences held

No CRAN upload. No DESCRIPTION bump to 0.7.0. No AGHQ / missing-data / #858 / #893 / #869 work. Primary checkout untouched.

## Highest proven rung

`tarball-clean`. **Next = platform-clean** (owner): win-builder, R-hub, 3-OS matrix on this frozen SHA.
