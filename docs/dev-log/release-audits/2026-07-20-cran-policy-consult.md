# CRAN Repository Policy — consult record for drmTMB 0.6.0

- **Access date:** 2026-07-20
- **Source:** CRAN Repository Policy — <https://cran.r-project.org/web/packages/policies.html>
- **Server `last-modified` at consult:** Sun, 31 May 2026 06:22:13 GMT (HTTP 200, `content-length` 30722)
- **Purpose:** evidence that the 0.6.0 candidate is evaluated against the *current* CRAN policy,
  discharging the `current_cran_policy` field of the release ledger at the source-clean rung.
- **Enforcement path:** the current policy requirements are applied through (a) the
  `cran-release-gate` protocol loaded 2026-07-20, which encodes them, and (b) the empirical
  `R CMD check --as-cran --run-donttest` run on the frozen tarball (see `local-as-cran-check.log`).

## Policy-relevant checks and outcomes (from the frozen-artifact `--as-cran` run)

| Policy area | Outcome for 0.6.0 | Evidence |
|---|---|---|
| First/new submission | New-submission NOTE expected; acknowledged | `cran-comments.md`; `local-as-cran-check.log` |
| DESCRIPTION spelling (`Tweedie`, `semi-continuous`) | Resolved — no spelling flag | `local-as-cran-check.log` |
| URLs | `urlchecker` clean (one DOI false-positive noted at S3; non-blocking) | S3 rc-inspection-report |
| Installed size (27.8Mb) | Size INFO/NOTE expected and explained (intrinsic to compiled TMB, cf. glmmTMB) | `cran-comments.md` |
| Compiled C++ (UBSAN) | 0 runtime errors on the six `(int)asDouble()` casts | `local-ubsan.log` (local clang-UBSAN probe) |
| Licence | GPL-3; `inst/COPYRIGHTS` re-confirmed | `inst/COPYRIGHTS` |
| Single maintainer, canonical DESCRIPTION | Confirmed | DESCRIPTION |

## Not yet discharged by this consult (declared NEXT gate, out of this lane)

The **remote platform matrix** — win-builder (R-release/R-devel), R-hub (UBSAN/valgrind/rchk),
and the 3-OS GitHub matrix — is the `platform-clean` rung and is **not** claimed here. This lane
reaches `tarball-clean` plus a *local* clang-UBSAN probe only; the remote sanitizers and Windows
timing are the next gate.

Cross-refs: `2026-07-20-0.6.0-cran-rc-ledger.json` · `2026-07-20-0.6.0-release-scope-manifest.md` ·
`cran-comments.md` · frozen evidence at `~/worktrees/drmTMB-rc-frozen/323d820f0a0ca444/` — **the current
candidate** (sha256 `323d820f…`, 6981105 bytes). The earlier `afd4600a86830451/` (r1, withheld by the D-43
panel), `e818e1651dc188f9/` (r2, incomplete cross-family fix) and `9ca4d07ca403b6c2/` (r3, gone stale vs
`main` after PR #805) each carry a `SUPERSEDED.txt` and must not be used.
