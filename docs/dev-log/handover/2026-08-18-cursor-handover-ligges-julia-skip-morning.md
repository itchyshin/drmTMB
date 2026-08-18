# Ligges morning scoreboard — julia-skip overnight (Cursor)

**Lane:** prepare-only · watch/file/merge docs · **no** `submit_cran` · **no** Ligges email · **no** #1033 · engine fix owned by sibling (#1071)
**As of:** 2026-08-18T00:57Z

## Scoreboard

| Item | Status |
| --- | --- |
| #1068 upload receipt | **MERGED** 2026-08-18T00:04:22Z |
| Julia-skip FTP (SHA `8764b2fe…`) | R-release + R-oldrelease @ 2026-08-17T23:21Z |
| Ligges **R-release** | **FILED** via **#1070 MERGED** `a2d5f0c38` @ 00:56:43Z — URL `v57uv6zakfKO` · email Status **ABSENT** · hang in `JuliaCall::julia_setup()` |
| Root cause (sibling) | **Not** the `^julia` filter — binomial `engine=julia` path. Draft **#1071** hard-blocks JuliaCall setup on CRAN lane; sibling ready/merge + re-FTP |
| Julia hang cleared on filed bytes? | **NO** (pre-#1071 tarball) |
| Ligges **R-oldrelease** | **Still waiting** (Gmail+Trash through 00:57Z; only one post-23:21 mail = release) |
| #1071 fix | **DRAFT** OPEN — CI ubuntu in progress @ 00:55Z; this lane merges only if sibling stuck |
| `platform-clean` | **NOT** advanced |
| Tip / C14 | #1070 merge just landed; watch main CI |

## Pre-23:21Z noise (do not confuse)

| Email UTC | URL | Status | Belongs to 8764b2fe? |
| --- | --- | --- | --- |
| 2026-08-17T22:03:35Z | `M2mtt6hSp14k` | 1 ERROR, 1 NOTE | **NO** |
| 2026-08-17T22:05:11Z | `mtw6R6D3gKRT` | 1 ERROR, 1 NOTE | **NO** |

## This lane next

1. ~~Merge #1070~~ **DONE**.
2. File R-oldrelease when Ligges mail arrives under `candidate-julia-skip/`.
3. If sibling stuck on #1071: ready (if still draft) + merge when green — do not re-implement fix.
4. After #1071 + sibling re-FTP: watch new Ligges mails (do not invent Status).
5. Never `submit_cran`; never email Ligges; never touch #1033.

## Artifacts

`docs/dev-log/release/0.7.0-cran-gate/candidate-julia-skip/` — #1068 receipt + #1070 R-release filing.
