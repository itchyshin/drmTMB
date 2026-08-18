# Ligges morning scoreboard — julia-skip overnight (Cursor)

**Lane:** prepare-only · watch/file/merge docs · **no** `submit_cran` · **no** Ligges email · **no** #1033 · **no** engine-fix duplication (sibling owns skip repair)
**As of:** 2026-08-18T00:12Z

## Scoreboard

| Item | Status |
| --- | --- |
| #1068 upload receipt | **MERGED** 2026-08-18T00:04:22Z |
| Julia-skip FTP (SHA `8764b2fe…`) | R-release + R-oldrelease @ 2026-08-17T23:21Z |
| Ligges **R-release** | **FILED** — URL `https://win-builder.r-project.org/v57uv6zakfKO` · email 2026-08-18T00:00:14Z · **no Status line in email** · `00check.log` truncates at `* checking tests ...` · `testthat.Rout` still hits `JuliaCall::julia_setup()` / Julia 1.11.3 |
| Julia hang cleared? | **NO** — #1061 filter insufficient; sibling diagnosing/fixing skip leak |
| Ligges **R-oldrelease** | **Still waiting** (Gmail + Trash through 00:12Z; only release mail post-23:21Z) |
| #1070 (file R-release hang) | OPEN — merge when CI green (docs-only) |
| `platform-clean` | **NOT** advanced |
| Tip / C14 | #1068 main push CI in flight; no C14 refresh owed by this lane |

## Pre-23:21Z noise (do not confuse)

| Email UTC | URL | Status | Belongs to 8764b2fe? |
| --- | --- | --- | --- |
| 2026-08-17T22:03:35Z | `M2mtt6hSp14k` | 1 ERROR, 1 NOTE | **NO** |
| 2026-08-17T22:05:11Z | `mtw6R6D3gKRT` | 1 ERROR, 1 NOTE | **NO** |

## This lane next

1. Merge **#1070** when ubuntu-latest green.
2. File R-oldrelease when Ligges mail arrives (bodies + `00check.log` under `candidate-julia-skip/`).
3. Leave engine fix to sibling; only pick up if sibling fails.
4. Never `submit_cran`; never email Ligges; never touch #1033.

## Artifacts

`docs/dev-log/release/0.7.0-cran-gate/candidate-julia-skip/` — see #1070 / #1068.
