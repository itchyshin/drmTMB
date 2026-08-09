# S11 — adversarial audit of the drmTMB 0.7.0 candidate `d04d0e88` freeze packet

**Auditor:** Rose (systems auditor), adversarial posture — default "the claim does not hold"
**Date:** 2026-08-09 · **Worktree:** `/private/tmp/drmTMB-07-release` · **Head:** `4c3e17202`
**Packet under attack:** `/private/tmp/drmTMB-07-release/docs/dev-log/release/0.7.0-cran-gate/FREEZE-NOTES-0.7.0.md`
**Ledger:** `/private/tmp/drmTMB-07-release/docs/dev-log/release-audits/2026-08-09-07-cran-release-ledger.json`
**Check log:** `/tmp/drm-rc3b/as-cran.log`

Everything below was measured. Commands are reproduced verbatim so the next reader can re-run them.

---

## 1. Is the rung claim honest?

**Assertions tested.** That the packet claims `tarball-clean` and nothing higher; that it names
the highest proven rung and the next unproven one; that nothing dispatched is stated as proven.

**Measurement.**

- `FREEZE-NOTES-0.7.0.md:171-179` ("What this freeze does NOT claim") explicitly disclaims
  `platform-clean`, `submission-ready`, permission to publish, and CRAN presence.
- `FREEZE-NOTES-0.7.0.md:152-156` heads the platform section "**Platform matrix — dispatched, NOT
  adjudicated**" and states "`platform-clean` is **not** claimed … their results are owner-gated."
  The three run IDs are given with commits, and the two `cancelled` runs are explained as
  concurrency cancels checked against the 75-minute ceiling rather than trusted from the
  conclusion string.
- Ledger `status_claim` is `"tarball-clean"` (line 80); `panel.grace/rose/pat` are all `"NOT_RUN"`
  (lines 74-79) with the D-43 note that the panel fires at `submission-ready`.
- I grepped the whole packet for words that would imply a higher rung outside the disclaimer
  block; there is no "ready to submit", "CRAN-ready", or "green" claim.
- The next unproven rung is named, though only implicitly through the negation
  ("Not `platform-clean`. Dispatched only").

**Two defects found inside an otherwise honest section, neither of which reverses the verdict.**

- *Dead citation on the most consequential sentence.* `FREEZE-NOTES-0.7.0.md:184` writes
  `[D-117](../../../../..)`. From the gate directory that resolves to
  `/private/tmp` — one level **above** the repo root:

  ```
  $ (cd docs/dev-log/release/0.7.0-cran-gate && cd ../../../../.. && pwd)
  /private/tmp
  ```

  The sentence "this is not permission to publish" therefore carries a link to nothing. A repo
  reader cannot verify D-117 or D-89 at all; both are brain-vault decisions with no in-repo
  resolvable target. This is a citation defect, not a false claim.
- *Ledger/packet disagreement on which R-hub run exists.* Ledger
  `evidence.compiled_diagnostics` (line 67) cites "R-hub run 31327047576". That ID appears
  **nowhere** in the freeze notes, whose platform table lists R-hub `31332770848`
  (`FREEZE-NOTES-0.7.0.md:161`). The ledger's ID is ~5.7 M lower, i.e. dispatched materially
  earlier — almost certainly a predecessor-era run carried across. One of the two is stale, and
  the ledger's is the one attached to a *rationale for not doing something*.

**Verdict: SURVIVES.** The rung claim is honest and correctly bounded. Corrections 7 and 6 below
are citation/consistency defects, not rung inflation.

---

## 2. Is the artifact identity sound?

**Assertions tested.** SHA-256, size, entry count; and the "no installed byte differs between
build source `6d1fb0562` and branch head" argument.

**Measurement.**

```
$ shasum -a 256 /tmp/drm-rc3b/drmTMB_0.7.0.tar.gz
d04d0e88d068e82eab64fbe710a01ed3302fd2d37f77901189cac8d7af84089e
$ shasum -a 256 .../scratchpad/frozen-d04d0e88d068/drmTMB_0.7.0.tar.gz
d04d0e88d068e82eab64fbe710a01ed3302fd2d37f77901189cac8d7af84089e
$ tar tzf drmTMB_0.7.0.tar.gz | wc -l
     904
$ ls -l /tmp/drm-rc3b/drmTMB_0.7.0.tar.gz   ->  4190432 bytes
```

All three identity fields in `FREEZE-NOTES-0.7.0.md:16-18` verify exactly, and the frozen copy is
mode `-r--r--r--` inside a `dr-xr-xr-x` directory, i.e. genuinely write-protected.

**The provenance argument, tested rather than trusted.** The packet's argument
(`FREEZE-NOTES-0.7.0.md:27-34`) is that the head-vs-source delta is `_pkgdown.yml` only, which is
`.Rbuildignore`d. I did not take that on faith. I enumerated the actual delta to the **real**
head, not the head the packet names:

```
$ git diff --name-only 6d1fb0562..4c3e17202
_pkgdown.yml
docs/dev-log/release-audits/2026-08-09-07-cran-release-ledger.json
docs/dev-log/release/0.7.0-cran-gate/FREEZE-NOTES-0.7.0.md
```

All three paths are excluded by `.Rbuildignore` (`^_pkgdown\.yml$` line 13; `^docs$` line 10). And
the exclusion is proved *from the artifact*, not from the config:

```
$ tar tzf drmTMB_0.7.0.tar.gz | grep -ci pkgdown
0
```

So `_pkgdown.yml` reaches the installed package by **no** route: it is not in the tarball, it is
not sourced by any shipped `.Rmd` (the shipped vignettes carry no `pkgdown::` calls that read it),
and pkgdown itself is not a package dependency. The conclusion "no installed byte differs" holds
**by measurement**, and holds for a stronger statement than the one the packet made.

**Defect: the argument is stale on arrival.** `FREEZE-NOTES-0.7.0.md:29-30` states "The branch head
is `9fc92e9f7`, which adds exactly one commit touching exactly one file". At the moment that
sentence was committed the head was already `4c3e17202` (the commit containing the sentence), which
adds **two** commits touching **three** files. The conclusion is unaffected, but the argument is
written as a fact about a specific head rather than as a property of paths, so it decays with every
further docs commit. This is a durability-of-wording defect.

**Disclosure placement.** The delta is *not* buried: it is a named subsection immediately under the
identity table (`FREEZE-NOTES-0.7.0.md:27`), before any result, and is repeated in the ledger note
(line 5). That part of the attack fails.

**Verdict: SURVIVES.** Identity verifies to the byte; the "no installed byte differs" argument is
provable and I proved it independently for the true head. Correction 9 is a wording fix.

---

## 3. Is the size resolution real?

**Assertions tested.** That bytes genuinely left the shipped package rather than moving somewhere
that still ships; that `.Rbuildignore` really excludes `vignettes/articles`; verified against the
tarball listing, not the config.

**Measurement — from the artifact.**

```
$ tar tzf drmTMB_0.7.0.tar.gz | grep -cE "figure-gallery|function-map-cheatsheet|simulation-plot-grammar|model-workflow|distributional-outputs-and-adequacy"
0
$ tar tzf drmTMB_0.7.0.tar.gz | grep -c articles
0
$ tar tzvf drmTMB_0.7.0.tar.gz | grep "inst/doc/" | awk '{s+=$5; n++} END {print s, s/1048576, n}'
4829089  4.605 MB  97 entries
```

- The five stems and their `.png` are **absent from the tarball entirely** — not relocated inside
  it. The bytes left.
- `inst/doc` = 4,829,089 bytes = **4.605 MiB**, exactly the packet's figure
  (`FREEZE-NOTES-0.7.0.md:62`), independently recomputed from the tar listing.
- `.Rbuildignore:31` is `^vignettes/articles$` — but I did not rely on it: the tarball listing
  above is the proof.
- Top-level entries are exactly the eleven the packet lists (`FREEZE-NOTES-0.7.0.md:95-96`),
  confirmed by `sed 's|^drmTMB/||' | awk -F/ '{print $1}' | sort -u`.
- The installed side agrees: `/tmp/drm-rc3b/drmTMB.Rcheck/drmTMB/doc` is `4.8M` (`du -sh`) with 97
  entries, and `as-cran.log:30-36` reports `installed size is 24.7Mb`, `doc 4.8Mb`.
- The arithmetic in `FREEZE-NOTES-0.7.0.md:72-78` checks out: 11.105 − (3.057+1.528+0.767+0.681) =
  5.072 ("only 5.07 MB, still over"); subtracting the fifth (0.483) gives 4.589, within rounding of
  the measured 4.605.

**Unverifiable-in-place (noted, not charged as a defect).** The predecessor decomposition —
11.105 MB / 112 files, HTML 9.92 MB, "87.9% of `figure-gallery.html` and 98.0% of
`function-map-cheatsheet.html` was embedded base64" — cannot be re-measured from this candidate,
because those files no longer exist in tree or tarball. It is predecessor evidence and should be
read as such.

**Trivial imprecision.** "97 files" (`FREEZE-NOTES-0.7.0.md:62`) is 96 files plus the `inst/doc/`
directory entry (32 shipped vignettes × 3 artifacts = 96). Matter of taste, listed last.

**Verdict: SURVIVES.** This is the strongest part of the packet: the resolution is real, measured
from the artifact, and reproduces to the byte.

---

## 4. Is "no reader loses access" true?

This is where the packet overstates, and it overstates twice.

### 4a. Offline and installed-package readers lose the five outright

I ran the test against the **installed** candidate produced by the claim-bearing check itself:

```
$ Rscript -e 'lib <- "/private/tmp/drm-rc3b/drmTMB.Rcheck"
              v <- vignette(package="drmTMB", lib.loc=lib); nrow(v$results)
              vignette("model-workflow", package="drmTMB", lib.loc=lib)'
vignettes visible to installed-package user: 32
model-workflow present: FALSE
figure-gallery present: FALSE
[1] "WARNING: vignette 'model-workflow' not found"
```

So for anyone who installs drmTMB — which is the *only* way a CRAN user gets it:

- `vignette(package = "drmTMB")` lists **32**, not 37.
- `browseVignettes("drmTMB")` shows 32.
- `vignette("model-workflow")` returns "not found". Same for `figure-gallery`,
  `function-map-cheatsheet`, `simulation-plot-grammar`,
  `distributional-outputs-and-adequacy`.
- The CRAN package page will host 32 vignettes, not 37.
- A reader on a plane, on a cluster login node with no egress, or behind an institutional proxy
  gets nothing for those five. The 15 rewritten cross-links (§5) make this worse, not better:
  inside a shipped vignette, the pointer to "Checking and using fitted models" is now an
  `https://itchyshin.github.io/...` URL that an offline reader cannot follow at all, where before
  it was a local file that opened.

`FREEZE-NOTES-0.7.0.md:74` says: "Moving those five to `vignettes/articles/` reaches 4.605 MB **and
keeps every one of them on the pkgdown website**, so no reader loses access." The clause before the
comma is true and I verified it (§4b). The conclusion after it does not follow. The honest
statement is: *no reader with a browser and network loses access; offline access and the
`vignette()` / `browseVignettes()` route are removed for those five.*

Nowhere in the packet is that cost stated. It is also absent from `NEWS.md`:

```
$ grep -niE "vignettes/articles|no longer ship|pkgdown-only|moved .*vignette" NEWS.md
(no output)
```

The 0.7.0 NEWS section (`NEWS.md:1-40`) documents boundary intervals and offsets and says nothing
about five vignettes ceasing to ship. A user upgrading loses `vignette("model-workflow")` with no
release-note trace.

### 4b. "Reader access proved, not assumed" proves discovery, not rendering

I re-ran the packet's own evidence independently and it reproduces:

```
$ Rscript -e 'p <- pkgdown::as_pkgdown("."); nrow(p$vignettes)'
n_vignettes: 37
  articles/distributional-outputs-and-adequacy -> articles/distributional-outputs-and-adequacy.html
  articles/figure-gallery                      -> articles/figure-gallery.html
  articles/function-map-cheatsheet             -> articles/function-map-cheatsheet.html
  articles/model-workflow                      -> articles/model-workflow.html
  articles/simulation-plot-grammar             -> articles/simulation-plot-grammar.html
$ Rscript -e 'pkgdown::check_pkgdown(".")'
✔ No problems found.
```

That is real and the `_pkgdown.yml` `articles/<stem>` fix (commit `9fc92e9f7`) is genuinely load-
bearing — without it `check_pkgdown()` aborts. **But discovery and config validity are not
rendering.** No site has been built since the move:

- The only `build_site()` receipt in the repo,
  `docs/dev-log/release/0.7.0-cran-gate/RENDERED-SITE-0.7.0.md`, is stamped
  **"Candidate: `da9b2d76…`"** (line 3) and reports "Articles rendered: **38**" (line 11). Its
  mtime is `Aug 9 12:11`; the vignette move is commit `6d1fb0562` at `13:47`. It predates the move
  by ~1.5 h and belongs to the **predecessor**.
- Yet ledger line 37-40 cites that exact file as `evidence.rendered_site` for candidate
  `d04d0e88`, with no staleness marker. This is precisely the D-49 trap that this repo's own
  `STALE-EVIDENCE-QUARANTINE.md:62-66` forbids ("May not: … copy a ledger and change only its
  SHA").
- The pkgdown workflow was "deliberately not dispatched" (`FREEZE-NOTES-0.7.0.md:168-170`), for a
  good reason, so there is no CI render either.

Net: the five heaviest documents have **never been rendered from their new location** by anything.
The claim "Reader access proved, not assumed" should read "discovery and configuration proved;
rendering not yet re-verified".

### 4c. The undisclosed correctness cost

`R CMD check` builds `vignettes/*.Rmd` and does not build `vignettes/articles/*.Rmd`. The log line
`as-cran.log:83` — `checking re-building of vignette outputs ... [67s/78s] OK` — now covers 32
documents, where the predecessor's covered 37. The five documents removed from that check are the
most code-dense in the package (`figure-gallery.Rmd` is 91,691 bytes of plotting code;
`simulation-plot-grammar.Rmd` 24,227). Their R code is now executed by nothing in the release gate:
not by `R CMD check`, not by the test suite, and not (see 4b) by any site build since the move. The
drop in vignette re-build time from the predecessor is the visible symptom. The packet presents the
move purely as a size win and never states that it also retired a correctness check.

**Verdict: FAILS.** "No reader loses access" is false as written for every offline and every
`vignette()`-using reader (measured: 32 vs 37, `vignette("model-workflow")` → not found), the proof
offered is of discovery rather than rendering, the only rendering receipt belongs to the
predecessor, and the loss of `R CMD check` coverage over the five is undisclosed.

---

## 5. Cross-links

### 5a. The literal 15-link claim

I enumerated every reference to the five moved stems in shipped vignettes:

```
$ grep -rn -E "figure-gallery|function-map-cheatsheet|simulation-plot-grammar|model-workflow|distributional-outputs-and-adequacy" vignettes/*.Rmd vignettes/includes/*.md
```

Exactly **15** hits — convergence 1, drmTMB 5, julia-engine 1, first-week-intervals 2,
implementation-map 1, large-data 1, model-map 2, model-selection 1, structural-dependence 1 — and
**every one is already an absolute `https://itchyshin.github.io/drmTMB/articles/<stem>.html` URL**.
None was missed. The count in `FREEZE-NOTES-0.7.0.md:87` is exact.

### 5b. Do any remaining relative `.html` links point at files that no longer ship?

I checked this exhaustively rather than by eye:

```
$ grep -rhoE "\]\([A-Za-z0-9._-]+\.html(#[^)]*)?\)" vignettes/*.Rmd | sed -E 's/^\]\(//; s/#.*//; s/\.html\)?$//; s/\)$//' | sort -u > targets
$ ls vignettes/*.Rmd | xargs -n1 basename | sed 's/\.Rmd$//' | sort -u > shipped
$ comm -23 targets shipped
(empty)
```

30 distinct relative link targets remain in shipped vignettes; **all 30 resolve to vignettes that
still ship**. Zero dangling. Clean.

### 5c. One reference WAS missed — outside the packet's stated scope, but real

```
vignettes/articles/function-map-cheatsheet.Rmd:78
[Open the full-size function map](https://github.com/itchyshin/drmTMB/blob/main/vignettes/function-map-cheatsheet.png)
```

The PNG moved to `vignettes/articles/function-map-cheatsheet.png` (commit `6d1fb0562`), so this
`blob/main/vignettes/…` URL will 404 the moment the move reaches `main`. It returns `200` today
only because `main` (`8d441a32d`) does not yet contain the move:

```
$ curl -s -o /dev/null -w "%{http_code}" https://github.com/itchyshin/drmTMB/blob/main/vignettes/function-map-cheatsheet.png
200
```

The packet's own commit message reasons carefully about the PNG's *relative* include
(`knitr::include_graphics("function-map-cheatsheet.png")`, line 75, which is fine) and misses the
*absolute* one three lines below it. This is a genuine miss of exactly the class the sweep was
supposed to catch — Rose principle: the sweep was scoped to "staying → moved relative links" and
never widened to "any reference to a path that moved".

### 5d. CRAN URL-check exposure from the new absolute URLs

Tested directly rather than assumed:

```
$ Rscript -e 'db <- tools:::url_db_from_package_sources("."); unique(db[,"Parent"])'
```

The URL database R CMD check builds contains entries whose `Parent` is `man/*.Rd`, `DESCRIPTION`,
`README.md`, `NEWS.md` — and **no vignette sources at all**. `grep("vignette", parents)` returns
nothing. So the 15 new absolute URLs inside vignettes create **zero** new CRAN URL-check surface.
The one pre-existing `articles/model-workflow.html` URL that *is* in the DB comes from
`README.md:61`, predates this change, and still resolves (`curl` → `200`), because pkgdown renders
`vignettes/articles/model-workflow.Rmd` to the same `articles/model-workflow.html` path (verified
in §4b `file_out`). Consistently, `as-cran.log` contains no URL note.

**Verdict: FAILS**, narrowly and on the question as posed ("did any get missed?"). The packet's
literal 15-link claim is exactly true and the URL-check exposure is nil — but one reference to a
moved file was missed at `vignettes/articles/function-map-cheatsheet.Rmd:78`, and it will break on
merge to `main`.

---

## 6. Does the check log actually support the packet?

**Assertions tested.** Status, error/warning counts, and that the log belongs to THIS tarball.

**Measurement.**

```
$ grep -n "Status" /tmp/drm-rc3b/as-cran.log
90:Status: 1 NOTE
$ grep -ciE "warning" /tmp/drm-rc3b/as-cran.log   -> 0
$ grep -inE "error"   /tmp/drm-rc3b/as-cran.log
46:* checking R files for syntax errors ... OK      # the only "error" substring; not a failure
$ grep -ciE "misspelled|invalid.*URI" /tmp/drm-rc3b/as-cran.log
0
```

`Status: 1 NOTE`, 0 warnings, 0 errors, and the packet's stated grep for the two predecessor
incoming items returns 0 — all four claims reproduce. The single NOTE is the incoming-feasibility
block at `as-cran.log:14-17`, whose entire content is the maintainer line and "New submission",
exactly as quoted at `FREEZE-NOTES-0.7.0.md:109-113`. Options are `--run-donttest --as-cran`
(`as-cran.log:10`), so `--as-cran` and donttest really were on.

**Binding the log to this tarball** (the part most worth attacking, since the log never names a
file):

| Evidence | Value |
| --- | --- |
| `as-cran.log:1` log directory | `/private/tmp/drm-rc3b/drmTMB.Rcheck` |
| Tarball in that directory | `shasum -a 256` → `d04d0e88…089e` ✔ |
| `as-cran.log:9` current time | `2026-08-09 19:51:40 UTC` |
| Tarball mtime | `Aug 9 13:51` local = `19:51` UTC ✔ |
| `.Rcheck/drmTMB/DESCRIPTION` | `Packaged: 2026-08-09 19:51:01 UTC`, `Built: … 19:52:13 UTC`, `Version: 0.7.0` ✔ |
| `.Rcheck/drmTMB/doc` | `4.8M`, 97 entries, **0** of the five moved stems ✔ |
| `as-cran.log:12` version | `0.7.0` (the predecessor log in the repo says `0.6.0`) ✔ |

The check began 39 s after the tarball was packaged, ran against a `.Rcheck` whose installed `doc`
contains exactly the post-move file set, and reports the post-move sizes (24.7 Mb / 4.8 Mb) rather
than the predecessor's (31.2 Mb / 11.3 Mb — see `docs/dev-log/release/0.7.0-cran-gate/local-as-cran-check.log:31-33`).
This is not a predecessor log relabelled. Timings in `FREEZE-NOTES-0.7.0.md:126-131` match
`as-cran.log:26,75,79,83` line for line.

**Verdict: SURVIVES.** The log is authentic, complete, corresponds to this tarball, and supports
every number the packet draws from it.

---

## 7. Anything the packet should have disclosed and did not

Beyond §4a/4b/4c and §5c, four further items.

### 7a. The claim-bearing evidence is not durable, and its location is described misleadingly

`FREEZE-NOTES-0.7.0.md:22` says the immutable copy lives at "`scratchpad/frozen-d04d0e88d068/`,
write-protected". A reader in this repo will read that as the repo's `scratchpad/` directory, which
exists and has 72 tracked files. It is not there:

```
$ ls -d /private/tmp/drmTMB-07-release/scratchpad/frozen*
zsh: no matches found
$ git ls-files | grep -i frozen-d04d0e88   -> (nothing)
```

The real path (ledger line 13) is
`/private/tmp/claude-503/-Users-.../76ce8c06-9aad-442c-9d2a-126e4f98f630/scratchpad/frozen-d04d0e88d068/` —
a **per-session agent scratchpad under `/private/tmp`**, keyed by a session UUID. It dies with the
session and with any `/private/tmp` purge. Likewise the claim-bearing check log lives only at
`/tmp/drm-rc3b/as-cran.log` (`FREEZE-NOTES-0.7.0.md:121`, ledger lines 43/47/51) and is **not
committed**:

```
$ git ls-files | grep -i as-cran
docs/dev-log/release/0.7.0-cran-gate/local-as-cran-check.log     # 0.6.0 PREDECESSOR
```

Since a rebuild would produce a different SHA-256 (timestamps), once these two temp locations are
purged the artifact is unrecoverable and the evidence for `tarball-clean` is unreadable by any
future session. For a release freeze whose entire value proposition is D-49 artifact binding, that
is the most consequential structural gap in the packet.

### 7b. The gate directory still contains 0.6.0 receipts sitting beside the current packet

`docs/dev-log/release/0.7.0-cran-gate/` contains, all committed and all from the **0.6.0**
predecessor:

```
tarball.sha256      -> 2e5234bd…c5ea  drmTMB_0.6.0.tar.gz
tarball.size.txt    -> 9831204
local-as-cran-check.log / 00check.log  -> version '0.6.0', installed size 31.2Mb, doc 11.3Mb
tarball-inventory.txt, build.log, platform/
```

A reader who opens `local-as-cran-check.log` in the same directory as `FREEZE-NOTES-0.7.0.md`
reads `doc 11.3Mb` — the exact risk the packet says is resolved. The packet's supersession note
(`FREEZE-NOTES-0.7.0.md:6-9`) supersedes only `FREEZE-NOTES.md` and points at
`STALE-EVIDENCE-QUARANTINE.md`; it never says that the sibling hash/size/log/inventory files are
also predecessor artifacts with no current equivalent in the directory (because the current
equivalents are in `/tmp`, per 7a).

### 7c. The quarantine note the packet cites now contradicts the packet

`STALE-EVIDENCE-QUARANTINE.md:4` declares its scope as "**every file in**
`docs/dev-log/release/0.7.0-cran-gate/`" — which now includes `FREEZE-NOTES-0.7.0.md` itself, i.e.
the current packet is, by that document's own wording, quarantined predecessor evidence. Worse, its
"Current state, stated plainly" section (lines 68-75) still asserts:

- "Release verdict: **NOT READY**"
- "`DESCRIPTION`: **`0.6.0`**" — actual: `Version: 0.7.0`
- "Highest rung proven for current `main`: **none**"; "there is currently **no 0.7.0 candidate
  tarball at all**" (line 17)
- "Blocking gate: the complete/quasi-complete separation lane must reach a reviewed finite
  disposition … **before any candidate freeze**"

The freeze notes record that disposition as DEFER (`FREEZE-NOTES-0.7.0.md:21`) and a candidate has
been frozen, so the quarantine note's status block is now stale in four places. The packet directs
readers to it as authoritative without saying which half of it still holds (the D-49 doctrine and
the two predecessor identities: yes; the "current state" block: no).

### 7d. The installed-size item is quoted but never adjudicated

`FREEZE-NOTES-0.7.0.md:133-141` reproduces the size block verbatim — `installed size is 24.7Mb`,
`libs 13.6Mb`, `R 3.1Mb`, `doc 4.8Mb`, `sim 1.9Mb` — and moves on. The documentation budget is now
closed, but the *installed package size* is a separate CRAN-facing item and the packet's own
resolution table (line 64) lists "installed package size 31.2 Mb → 24.7 Mb" without ever saying
whether 24.7 Mb is acceptable or what the residual risk is. On this local run R reported it as
`INFO` (`as-cran.log:30`), not `NOTE`, which is why the Status line stays at 1 NOTE. **Inference,
not measurement:** CRAN's incoming checks commonly surface an installed size >5 Mb as a NOTE and
ask for justification, and `libs 13.6Mb` (the TMB template) is the dominant term, not documentation.
I cannot prove from this log what CRAN's machines will say. But an item that is *quoted in the
packet and left unremarked* is exactly the kind of thing a reader will assume was adjudicated.

Also worth one line: `inst/sim` (1.9 Mb) ships inside the package. Whether that belongs in a first
CRAN submission is a product question the packet does not raise.

**Verdict: FAILS.** Four material items — evidence durability and a misleading artifact path,
predecessor receipts co-located with the current packet, a self-contradicting quarantine note the
packet itself cites, and an unadjudicated installed-size item — should have been disclosed and were
not.

---

## Overall verdict

**The headline claim SURVIVES in its first two thirds and FAILS in its last third.**

- "drmTMB 0.7.0 candidate `d04d0e88` is at the **tarball-clean** rung — and nothing higher."
  **HOLDS.** Identity verifies to the byte, the check log is authentic and bound to this tarball,
  and the packet is disciplined about not claiming `platform-clean` or `submission-ready`.
- "The documentation-size risk … is now genuinely resolved, not merely relabelled." **HOLDS.**
  Proved from the tarball listing, not the config: 0 hits for `articles`, 0 for the five stems,
  `inst/doc` = 4.605 MiB recomputed independently. This is the best-evidenced section of the packet.
- "No reader loses access to the five relocated vignettes." **DOES NOT HOLD.** Measured on the
  installed candidate: 32 vignettes instead of 37, and `vignette("model-workflow")` returns "not
  found". Offline readers lose the five outright; the 15 URL rewrites make the offline path worse.
  The supporting proof is of pkgdown *discovery*, not rendering, and the only rendering receipt in
  the repo belongs to the predecessor `da9b2d76` and predates the move.

**Section tally: 4 SURVIVES (1, 2, 3, 6) · 3 FAILS (4, 5, 7).**

The failures are concentrated in *disclosure*, not in *measurement*. Where this team measured, it
measured well and honestly — the artifact work is genuinely strong. The recurring pattern is that a
true measurement gets attached to a conclusion broader than the measurement supports
("discovery" → "rendering proved"; "still on the website" → "no reader loses access"), and that
evidence is left in ephemeral `/tmp` while predecessor receipts stay committed in the repo. That
combination is exactly what `STALE-EVIDENCE-QUARANTINE.md` was written to prevent, and it has
partially recurred inside the document that cites it.

---

## Required corrections, most severe first

1. **Retract "no reader loses access."** Replace with the measured statement: the five remain on the
   pkgdown website, and offline readers plus every user of `vignette()` / `browseVignettes()` lose
   them (32 of 37 ship; `vignette("model-workflow")` → "vignette not found", verified against
   `/private/tmp/drm-rc3b/drmTMB.Rcheck`). `FREEZE-NOTES-0.7.0.md:74`.
2. **Add a `NEWS.md` 0.7.0 bullet** recording that `figure-gallery`, `function-map-cheatsheet`,
   `simulation-plot-grammar`, `model-workflow`, and `distributional-outputs-and-adequacy` no longer
   ship with the package and are web-only, with the URL. Currently `grep -niE "vignettes/articles|no
   longer ship|pkgdown-only" NEWS.md` returns nothing.
3. **Disclose the retired correctness check.** State that `R CMD check`'s "re-building of vignette
   outputs" now covers 32 documents, not 37, so the code in the five heaviest documents is executed
   by nothing in the release gate. `FREEZE-NOTES-0.7.0.md:51-52, 83`.
4. **Downgrade "Reader access proved, not assumed" to what was actually run** (`as_pkgdown()`
   discovery = 37 and `check_pkgdown()` = no problems, both of which I reproduced), and either
   run `pkgdown::build_site()` post-move or state plainly that no site has been rendered since
   `6d1fb0562`. `FREEZE-NOTES-0.7.0.md:81-85`.
5. **Fix the ledger's `rendered_site` evidence.** It cites `RENDERED-SITE-0.7.0.md`, whose own line 3
   reads "Candidate: `da9b2d76…`" and which predates the vignette move by ~1.5 h, as evidence for
   `d04d0e88`. Either re-render or mark it `PREDECESSOR`. Ledger lines 37-40.
6. **Make the claim-bearing evidence durable.** Commit `/tmp/drm-rc3b/as-cran.log` into
   `docs/dev-log/release/0.7.0-cran-gate/` under a candidate-stamped name, and state the *true*
   absolute path of the frozen tarball — it is in a session-scoped
   `/private/tmp/claude-503/<uuid>/scratchpad/`, not the repo's `scratchpad/`, and will not survive
   the session. `FREEZE-NOTES-0.7.0.md:22, 121`; ledger lines 13, 20, 43.
7. **Quarantine or supersede the co-located 0.6.0 receipts** in the gate directory —
   `tarball.sha256` (0.6.0 hash), `tarball.size.txt` (9831204), `local-as-cran-check.log` /
   `00check.log` (doc 11.3Mb), `tarball-inventory.txt`, `build.log`, `platform/` — and update
   `STALE-EVIDENCE-QUARANTINE.md`, whose scope line now covers the current packet and whose
   "Current state" block still says `DESCRIPTION 0.6.0`, "no 0.7.0 candidate tarball at all", and
   "before any candidate freeze". `STALE-EVIDENCE-QUARANTINE.md:4, 17, 68-75`.
8. **Reconcile the R-hub run ID.** Ledger `compiled_diagnostics` cites run `31327047576`; the
   packet's platform matrix cites `31332770848`. One is stale. Ledger line 67 vs
   `FREEZE-NOTES-0.7.0.md:161`.
9. **Repair the dead D-117 citation.** `[D-117](../../../../..)` resolves to `/private/tmp`, outside
   the repo. Point it at an in-repo target or drop the link and state that D-117/D-89 are brain-vault
   decisions not resolvable from this repository. `FREEZE-NOTES-0.7.0.md:184`.
10. **Fix the missed cross-link.** `vignettes/articles/function-map-cheatsheet.Rmd:78` links to
    `https://github.com/itchyshin/drmTMB/blob/main/vignettes/function-map-cheatsheet.png`; the PNG is
    now at `vignettes/articles/`, so this 404s once the move reaches `main` (it returns 200 today
    only because `main` = `8d441a32d` lacks the move). Widen the sweep from "relative links to moved
    vignettes" to "any reference to a path that moved".
11. **Restate the provenance delta as a property of paths, not of a head.** The packet says the head
    is `9fc92e9f7` adding one file; the actual head at the time of writing is `4c3e17202` adding
    three (`_pkgdown.yml` plus two `docs/` files). All are `.Rbuildignore`d (lines 13 and 10), so the
    conclusion holds — say that instead. `FREEZE-NOTES-0.7.0.md:29-30`.
12. **Adjudicate, or explicitly defer with reasons, the residual installed size** — 24.7 Mb with
    `libs 13.6Mb` and `inst/sim 1.9Mb`. It is quoted at `FREEZE-NOTES-0.7.0.md:133-141` and left
    unremarked, which reads as adjudicated. On this run R reported it as `INFO`, not `NOTE`
    (`as-cran.log:30`); what CRAN's machines will do is not established by this log.
13. *(Taste.)* "`inst/doc` … 97 files" is 96 files plus the directory entry; 32 shipped vignettes ×
    3 artifacts. `FREEZE-NOTES-0.7.0.md:62`.
