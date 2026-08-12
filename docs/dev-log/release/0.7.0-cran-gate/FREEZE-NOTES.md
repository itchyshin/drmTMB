> **PREDECESSOR (0.6.0) — superseded 2026-08-11.** This file records the `ad475cc39` / 0.6.0
> tarball-clean freeze. It is not the current 0.7.0 rung record; for the live candidate see
> [`RUNG-REPORT-0.7.0.md`](./RUNG-REPORT-0.7.0.md).
>
> **Two of the prohibitions in the closing paragraph have since been crossed, and this banner says so
> rather than quietly retiring them.** The paragraph was written for the 0.6.0 predecessor lane
> (`codex/07-reader-boundaries-tarball`) and closes with "in this lane", so it is arguably scoped to
> that lane — but the crossings are recorded here plainly, because a reader must not have to
> reconstruct them:
>
> - **"bump DESCRIPTION"** — crossed by `a75c3c901` (2026-08-10), the 0.7.0 candidate freeze commit.
> - **"finalize `cran-comments.md`"** — crossed by `885f260d1` (2026-08-11).
>
> **Both were authorised on 2026-08-11, by merge.** Shinichi's earlier decision that day reassigned
> *lane ownership* only; the authorisation for these two actions is his instruction to merge
> **PR #996**, landed as `a3217da93`. That is what put `Version: 0.7.0` on `main`. Recorded here
> because an earlier revision of this banner said no authorisation existed — true when written, false
> once the PR merged.
>
> **Still in force, uncrossed:** do not write `platform-clean`, do not commit the tarball binary, and
> do not upload to CRAN. Advancing to `platform-clean` requires Shinichi's explicit authorisation.

# drmTMB current-main 0.6.0 — tarball-clean freeze

- **Freeze source commit:** `ad475cc39f62f47a346c77aa17c3d20bf3fc9bae` (merge of PR #948 onto `main`)
- **Worktree:** `/private/tmp/drmTMB-07-reader-boundaries-tarball` on `codex/07-reader-boundaries-tarball`
- **Clean tracked worktree at build:** yes (`git status --porcelain` empty)
- **Tarball:** `drmTMB_0.6.0.tar.gz` (DESCRIPTION remains 0.6.0)
- **SHA-256:** `2e5234bd4bf819663e9ef95f10a1944d51c90ce64ffd5dd7a9641b69fa50c5ea`
- **Size:** 9,831,204 bytes
- **Inventory:** 922 paths; capability article and generated summary present; no root roadmap, `docs/dev-log`, tools, scratch, pkgdown-site, VCS, AGENTS, or CLAUDE paths
- **Local CRAN-shaped check:** `R CMD check --as-cran --run-donttest` → **Status: 1 NOTE** (`New submission` only); 0 ERROR / 0 WARNING
- **Installed size:** 31.2 MB; `doc` 11.3 MB, `libs` 13.6 MB, `R` 3.0 MB, `sim` 1.9 MB
- **Exact-tarball exercises:** installation, tests, examples, installed vignettes, vignette rebuild, PDF/HTML manuals, and temp cleanup all passed
- **Independent verification:** fresh Luna-medium verifier reproduced identity/check values; strict read-only extraction was blocked and preserved as FAIL, then a scratch-write-only rerun freshly extracted and rendered `capability-and-limits.Rmd` from package-contained inputs, output SHA-256 `0cff046d1211e5b0c9baf442653d88e3854573643579ba9d27b469f571d9edbc`
- **Live M1 evidence:** PR #948 merged; main R-CMD-check run `31266713858` and pkgdown/Pages run `31268615909` green; deployed capability page, redirect, search, sitemap, and mobile/desktop surfaces verified
- **Highest proven rung:** `tarball-clean`
- **Next unproven rung:** `platform-clean`, deliberately deferred to the real `0.7.0` candidate and requiring Shinichi's authorization before any ledger write

Earlier fixed win-builder and platform evidence belongs to predecessor artifacts. It does not prove this tarball. Do not commit the tarball binary, bump DESCRIPTION, finalize `cran-comments.md`, write `platform-clean`, or upload to CRAN in this lane.
