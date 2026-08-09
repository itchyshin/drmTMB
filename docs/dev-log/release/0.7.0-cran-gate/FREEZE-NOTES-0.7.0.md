# drmTMB 0.7.0 — exact candidate freeze

**Date:** 2026-08-09 · **Lane:** Claude, release slice (fourth candidate) · **Branch:** `claude/07-release-slice`
**Draft PR:** [#959](https://github.com/itchyshin/drmTMB/pull/959) — **must not merge** without the release decision.

> **Scope note.** This file is the **current** packet. It is explicitly *excluded* from
> [`STALE-EVIDENCE-QUARANTINE.md`](STALE-EVIDENCE-QUARANTINE.md), whose scope line would otherwise
> cover it. Every *other* file in this directory — `tarball.sha256`, `tarball.size.txt`,
> `local-as-cran-check.log`, `00check.log`, `tarball-inventory.txt`, `build.log`, `platform/`,
> `RENDERED-SITE-0.7.0.md`, `FREEZE-NOTES.md` — is **predecessor** evidence from 0.6.0 or from an
> earlier 0.7.0 candidate. This candidate's own receipts are in
> [`CANDIDATE-EVIDENCE/`](CANDIDATE-EVIDENCE/).

## Artifact identity

| Property | Value |
| --- | --- |
| Package / version | `drmTMB_0.7.0.tar.gz` |
| **SHA-256** | `a8f7c47905b03a95c30c413d2ae351c589a3884a0bbf2e1d9a31ce4bc9ffcad5` |
| **Size** | 4,190,882 bytes |
| **Entries** | 904 |
| **Source commit (built at)** | `cc4f5baee` |
| Base | `origin/main@8d441a32d` (PR #956, separation disposition **DEFER**) |
| Immutable copy | see *Where the evidence physically lives* — **not** the repo's `scratchpad/` |

Built with vignettes. Any installed-byte change from here creates a **new** candidate and
invalidates every artifact-bound result below.

### Provenance delta — stated as a property of paths, not of a head

Commits made after the build touch only paths that `.Rbuildignore` excludes: `^docs$` (line 10),
`^_pkgdown\.yml$` (line 13), `^tools$`. **The test is not "how many commits" but "does any
build-included path differ"**, because a head-specific sentence decays with every later docs commit.
Proof from the artifact rather than the config:

```
$ tar tzf drmTMB_0.7.0.tar.gz | grep -ciE "pkgdown|^drmTMB/docs/|^drmTMB/tools/"
0
```

`_pkgdown.yml` also reaches the installed package by no indirect route: it is not sourced by any
shipped `.Rmd`, and pkgdown is not a dependency.

### Where the evidence physically lives — read this before relying on it

**Durable copy — use this one:**

```
~/local-scratch/drmTMB-0.7.0-candidates/drmTMB_0.7.0-a8f7c47905b0.tar.gz
~/local-scratch/drmTMB-0.7.0-candidates/inventory-a8f7c47905b0.txt
```

Write-protected, outside `/tmp` entirely, and **re-hashed from that path to
`a8f7c47905b03a95…` — matching**. This exists because the original freeze went to a *per-session*
agent scratchpad (`/private/tmp/claude-503/<session-uuid>/scratchpad/frozen-a8f7c47905b0/`) which is
**not** the repo's tracked `scratchpad/` and does **not** survive the session or a `/private/tmp`
purge. Since a rebuild produces a different SHA-256 (timestamps), the exact artifact would have been
unrecoverable once that path went away. The adversarial audit flagged this as the packet's most
consequential structural gap; the copy above closes it.

The claim-bearing check log, inventory, and SHA-256 are additionally **committed** under
[`CANDIDATE-EVIDENCE/`](CANDIDATE-EVIDENCE/), so the evidence survives even if both copies are lost.

The **durable** copies are committed: the claim-bearing check log, the tarball inventory, and the
SHA-256 are in [`CANDIDATE-EVIDENCE/`](CANDIDATE-EVIDENCE/), stamped with this candidate's hash. If
you need the artifact itself and the scratchpad is gone, rebuild from `cc4f5baee` and expect a new
hash; the packaged *content* will match the committed inventory.

## Candidate history — three predecessors, each deliberately invalidated

| Candidate | Size | Entries | Fate |
| --- | --- | --- | --- |
| `d35c0b9e` | — | — | **Invalidated (D-49)** — README pointed at the unsupported `v0.5.0` tag |
| `da9b2d76` | 9,853,648 | 924 | **Invalidated (D-49)** — boundary surfacing touches `R/` |
| `d04d0e88` | 4,190,432 | 904 | **Invalidated (D-49)** — checked clean at 1 NOTE, but an adversarial audit found `NEWS.md` never told users five vignettes stop shipping |
| **`a8f7c47905b0` (this)** | **4,190,882** | **904** | **current** |

`d04d0e88` is worth dwelling on: it passed the identical check at Status 1 NOTE and was frozen. It
was invalidated anyway, on the same principle as the first two — **a candidate is not worth keeping
if keeping it means shipping a known defect** — here a silent, user-facing documentation gap.

## The documentation-size question is RESOLVED

The `da9b2d76` packet carried this as an **open policy risk deliberately not blocking the rung**:
`inst/doc` was **11.11 MB** against CRAN's stated **5MB** documentation maximum, reported by
`R CMD check` only as an `INFO` line. Closed by measurement.

| | predecessor `da9b2d76` | **this candidate** |
| --- | --- | --- |
| `inst/doc` (uncompressed) | 11.105 MB, 111 files | **4.605 MB, 96 files** |
| installed `doc` sub-directory | 11.11 Mb | **4.8 Mb** |
| installed package size | 31.2 Mb | **24.7 Mb** |
| tarball | 9,853,648 bytes | **4,190,882 bytes** |

**What the bytes actually were.** Of the 11.105 MB, HTML was **9.92 MB**; `.Rmd` sources were only
0.920 MB and `.R` files 0.261 MB. Measured directly, **87.9%** of `figure-gallery.html` and
**98.0%** of `function-map-cheatsheet.html` was embedded base64 plot images. So the lever was never
how the vignettes are written — it was which rendered vignettes ship. *(This decomposition is
predecessor evidence: those files no longer exist in tree or tarball and cannot be re-measured here.)*

**Why moving beat dropping.** Dropping the four largest reaches only 5.07 MB — still over — so five
are required either way. Moving them to `vignettes/articles/` reaches 4.605 MB and keeps them
published. Owner decision, 2026-08-09.

Moved: `figure-gallery` (3.057 MB), `function-map-cheatsheet` (1.528 MB),
`simulation-plot-grammar` (0.767 MB), `model-workflow` (0.681 MB),
`distributional-outputs-and-adequacy` (0.483 MB). `function-map-cheatsheet.png` (1.17 MB) moved
with its vignette, because the `.Rmd` includes it by **relative** path.

### What the move costs — three costs, none of them glossed

**1. Offline and in-R readers lose these five outright.** Measured against the installed package
produced by the claim-bearing check itself:

```
vignette(package = "drmTMB")        ->  32 vignettes, not 37
vignette("model-workflow")          ->  "vignette not found"
```

So `browseVignettes("drmTMB")` shows 32, the CRAN page will host 32, and a reader on a plane or a
no-egress cluster node gets nothing for those five. The 15 rewritten cross-links make the offline
path *worse*: a pointer that used to open a local file is now an `https://` URL. **The correct
claim is "no reader loses access *on the website*", not "no reader loses access".** Recorded in
`NEWS.md` so users find out from the release notes rather than from a failed `vignette()` call.

**2. A correctness check was retired, and this is the least obvious cost.** `R CMD check` builds
`vignettes/*.Rmd` and does **not** build `vignettes/articles/*.Rmd`. The
`checking re-building of vignette outputs` line now covers **32** documents where the predecessor's
covered 37 — and the five removed are the most code-dense in the package (`figure-gallery.Rmd`
alone is ~92 KB of plotting code). **The R code in those five is now executed by nothing in the
release gate:** not `R CMD check`, not the test suite, and not any site build since the move. The
drop in vignette re-build time is the visible symptom. Re-establishing that coverage is genuine
follow-up work, not a formality.

**3. Configuration and discovery are proved; rendering is not.** What was actually run:

```
pkgdown::as_pkgdown(".")   ->  37 vignettes discovered; all five resolve to articles/<stem>.html
pkgdown::check_pkgdown()   ->  No problems found
```

That is discovery and config validity, and the `_pkgdown.yml` `articles/<stem>` fix is genuinely
load-bearing — without it `check_pkgdown()` aborts and the site build fails, dropping all five from
the website. **But no site has been rendered since the move.** The only `build_site()` receipt in
this directory, `RENDERED-SITE-0.7.0.md`, names candidate `da9b2d76` and predates the move; it is
predecessor evidence and is *not* cited as this candidate's rendered-site evidence. The pkgdown
workflow was deliberately not dispatched because its `workflow_dispatch` path deploys to Pages,
which would publish this candidate's site over the live one.

**Cross-links.** Fifteen relative links from staying vignettes to the five moved ones now use the
absolute pkgdown URL. Verified exhaustively: **30 distinct relative link targets remain in shipped
vignettes and all 30 resolve to vignettes that still ship — zero dangling.** The 15 new absolute
URLs add **no** CRAN URL-check surface (`tools:::url_db_from_package_sources(".")` contains no
vignette parents). One further reference was missed by the first sweep and then found by widening
it from "relative links to moved vignettes" to "any reference to a path that moved":
`vignettes/articles/function-map-cheatsheet.Rmd` linked to
`blob/main/vignettes/function-map-cheatsheet.png`, which would 404 once the move reaches `main`;
now corrected to `blob/main/vignettes/articles/`.

## Forbidden-path scan — 0 hits

Proved by listing the **built tarball**, not by pointing at `.Rbuildignore`. Top-level entries are
exactly `DESCRIPTION`, `NAMESPACE`, `NEWS.md`, `R`, `README.md`, `build`, `inst`, `man`, `src`,
`tests`, `vignettes`. Absent as intended: `docs/`, `tools/`, `scratchpad/`, `LOOP/`,
`pkgdown-site/`, `.git`, `.github`, `AGENTS.md`, `CLAUDE.md`, `cran-comments.md`, `_pkgdown.yml`,
`*.Rproj`.

## Local CRAN-lane check — the claim-bearing run

`R CMD check --as-cran --run-donttest` on the exact frozen tarball, CRAN incoming **enabled**,
vignettes **built**, `_R_CHECK_FORCE_SUGGESTS_` **not** disabled.

### **Status: 1 NOTE**

```
* checking CRAN incoming feasibility ... [4s/22s] NOTE
Maintainer: ‘Shinichi Nakagawa <itchyshin@gmail.com>’

New submission
```

That is the whole NOTE. **0 errors, 0 warnings.** Both predecessor incoming items stay cleared: a
case-insensitive grep for `misspelled|invalid.*URI` returns **0**.

Log (committed): [`CANDIDATE-EVIDENCE/as-cran-a8f7c47905b0.log`](CANDIDATE-EVIDENCE/as-cran-a8f7c47905b0.log).

### Installed size — quoted AND adjudicated

```
* checking installed package size ... INFO
  installed size is 24.7Mb
  sub-directories of 1Mb or more:
    R      3.1Mb
    doc    4.8Mb
    libs  13.6Mb
    sim    1.9Mb
```

The **documentation** budget is now closed. The **installed package size** is a separate,
still-open CRAN-facing item and is deliberately *not* claimed as resolved:

- On this run R reports it as `INFO`, not `NOTE`, which is why Status stays at 1 NOTE.
- The dominant term is `libs 13.6Mb` — the compiled TMB template — **not** documentation, so no
  further vignette trimming would move it materially.
- **Inference, not measurement:** CRAN's incoming checks commonly surface a large installed size as
  a NOTE and ask for justification. This local log does not establish what CRAN's machines will
  say.
- `inst/sim` (1.9 Mb) ships. Whether it belongs in a first submission is an open product question,
  raised here rather than settled.

## Supporting checks

- **Capability-ledger guard** — `tools/tests/test_capability_ledger.py`, the guard CI runs: **66
  tests OK**, `C17 current-source compatibility PASS`. Three of its assertions broke on the vignette
  move and were repaired without re-pinning anything (a hard-coded path, a nav regex that
  disallowed `/`, and a non-recursive glob). **CI caught those; the local run did not, because the
  guard was run before the move rather than after.**
- **Full repo guard suite** — `python3 -m unittest discover -s tools/tests` → **122 tests, OK**.
- **Targeted suite** — `boundary-surfacing` (16) + `offset-families` (29) = **45 pass, 0 failures**.

## Independent verification

- **Mechanical re-verify** of the predecessor `d04d0e88` (fresh context, every number re-measured
  from the artifact rather than copied): **20 claims, 20 match, 0 mismatch**.
  [`../../release-audits/2026-08-09-07-mechanical-freeze-verify.md`](../../release-audits/2026-08-09-07-mechanical-freeze-verify.md)
- **Adversarial audit** of the `d04d0e88` packet, instructed to refute: **4 sections SURVIVED
  (rung honesty, artifact identity, size resolution, check-log authenticity), 3 FAILED (reader
  access, cross-link completeness, disclosure)**, with 13 required corrections. **Every correction
  is applied in this packet**, and two of them — the missing `NEWS.md` entry and the missed PNG
  link — are why `d04d0e88` was invalidated rather than shipped.
  [`../../release-audits/2026-08-09-07-adversarial-freeze-audit.md`](../../release-audits/2026-08-09-07-adversarial-freeze-audit.md)

## Platform matrix — dispatched, NOT adjudicated

`platform-clean` is **not** claimed. Runs are recorded for the next session; adjudicating them is
owner-gated.

| Workflow | Run | At commit | Covers this candidate? |
| --- | --- | --- | --- |
| `R-CMD-check` | [31336312020](https://github.com/itchyshin/drmTMB/actions/runs/31336312020) | `604016a5d` | **yes** — see below |
| `R-hub` | [31336313176](https://github.com/itchyshin/drmTMB/actions/runs/31336313176) | `604016a5d` | **yes** — see below |
| `R-CMD-check` | [31333822332](https://github.com/itchyshin/drmTMB/actions/runs/31333822332) | `6dc48cd94` | no — **success**, but predates the candidate; proves the guard repairs |
| `R-CMD-check` | [31332769740](https://github.com/itchyshin/drmTMB/actions/runs/31332769740) | `6d1fb0562` | no — predecessor `d04d0e88` source |
| `R-hub` | [31332770848](https://github.com/itchyshin/drmTMB/actions/runs/31332770848) | `6d1fb0562` | no — predecessor `d04d0e88` source |

**Why `604016a5d` covers candidate source `cc4f5baee`.** `git diff --name-only cc4f5baee..604016a5d`
returns 14 paths, all of them `AGENTS.md` or under `docs/` — both `.Rbuildignore`d (`^docs$` line
10; `AGENTS.md` verified absent from the tarball listing). No build-included path differs, so the
package these runs build is content-identical to the frozen candidate. This is the same
property-of-paths argument used for the provenance delta above, and it is the reason a re-dispatch
was warranted here but not for the `_pkgdown.yml`-only delta earlier: `cc4f5baee` **did** change
shipped bytes (`NEWS.md`) relative to `6d1fb0562`, so the earlier runs genuinely do not cover this
candidate.

**Results are NOT adjudicated.** Dispatch is not evidence; `platform-clean` remains owner-gated and
unclaimed. Earlier runs showing `conclusion: cancelled` were each superseded by a later push —
concurrency cancels, checked against the 75-minute ceiling rather than trusted from the conclusion
string.

## What this freeze does NOT claim

- **Not `platform-clean`.** Dispatched only, and not at this candidate's commit.
- **Not `submission-ready`.** The D-43 panel has not fired; the owner deferred it.
- **Not permission to publish.** Independently of this candidate's cleanliness, **D-117** holds
  0.7.0 — the 10-group gate ran, but its D-43 panel returned 2 of 3 NOT-DONE and the **PASS is
  withheld** — and **D-89** records that CRAN submission is far away by choice. *(D-117 and D-89 are
  brain-vault decisions in `~/shinichi-brain/memory/DECISIONS.md`; they have no in-repo target, so
  no link is given rather than a broken one.)*
- **Not on CRAN.** A version number is a candidate identity, not evidence of acceptance.
- **Not vignette-code coverage.** See cost 2 above: the five relocated documents are executed by
  nothing in the release gate.
