# Ligges morning scoreboard — julia-skip overnight (Cursor)

**Lane:** prepare-only · watch/file/merge docs · **no** `submit_cran` · **no** Ligges email · **no** #1033 · engine fix owned by sibling (#1071)
**As of:** 2026-08-18T11:53Z

## Scoreboard

| Item | Status |
| --- | --- |
| #1068 upload receipt | **MERGED** 2026-08-18T00:04:22Z |
| Julia-skip FTP (SHA `8764b2fe…`) | R-release + R-oldrelease @ 2026-08-17T23:21Z |
| Ligges **R-release** | **FILED** via **#1070 MERGED** `a2d5f0c38` @ 00:56:43Z — URL `v57uv6zakfKO` · email Status **ABSENT** · hang in `JuliaCall::julia_setup()` |
| Root cause (sibling) | **#1071 MERGED** as `9fb965e16` @ 11:39:28Z — binomial `engine=julia` path now hard-blocks JuliaCall setup on the CRAN lane |
| Julia hang cleared on filed bytes? | **NO** (pre-#1071 tarball) |
| Ligges results | **No new mail reported through 11:51Z**; do not infer a win-builder result from the upload receipt |
| Julia-skip-2 FTP (SHA `5153ae7e…`) | Hash verified locally (`10,098,642` bytes); R-release **226 / exit 0 / 3.259 s** @ 11:53:23–26Z; R-oldrelease **226 / exit 0 / 3.086 s** @ 11:53:26–29Z |
| #1071 fix | **MERGED** — exact merge commit `9fb965e16b34c0f94b7a671e77a65a37fd8142a2` |
| `platform-clean` | **NOT** advanced |
| Tip / C14 | `9fb965e16` main CI reached `check-r-package` and remained in progress at 11:53Z; refresh C14 only if that step fails |

## Pre-23:21Z noise (do not confuse)

| Email UTC | URL | Status | Belongs to 8764b2fe? |
| --- | --- | --- | --- |
| 2026-08-17T22:03:35Z | `M2mtt6hSp14k` | 1 ERROR, 1 NOTE | **NO** |
| 2026-08-17T22:05:11Z | `mtw6R6D3gKRT` | 1 ERROR, 1 NOTE | **NO** |

## This lane next

1. ~~Merge #1070~~ **DONE**.
2. ~~Merge #1071 and re-upload the exact repaired tarball~~ **DONE**.
3. File R-release / R-oldrelease only when new Ligges mail arrives under `candidate-julia-skip-2/`.
4. Do not invent Status from FTP `226`; it proves transfer only.
5. Never `submit_cran`; never email Ligges; never touch #1033.

## Artifacts

`docs/dev-log/release/0.7.0-cran-gate/candidate-julia-skip/` — #1068 receipt + #1070 R-release filing.
`docs/dev-log/release/0.7.0-cran-gate/candidate-julia-skip-2/` — #1071 fix evidence + exact-hash
R-release/R-oldrelease reupload receipts filed on #1072.
